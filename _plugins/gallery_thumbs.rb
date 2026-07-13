require 'fileutils'
require 'open3'
require 'tmpdir'

# Generates two derivatives for each gallery item so the /gallery grid loads
# ~1.5 MB instead of ~64 MB and the lightbox shows a watermarked copy:
#
# - <dir>/thumbs/<basename>.webp — clean 1200px grid thumbnail. Animated
#   sources (GIF) yield a static thumb from a single frame — frame 0 by
#   default, or the frame given by `thumb_frame:` in the item's frontmatter.
# - <dir>/full/<basename>.webp (.gif for animated sources) — watermarked
#   full-view copy, generated ONLY for media that plays: video posters
#   (items with `video:` frontmatter) and animated GIFs. The group logo is
#   burned into a corner (lower right by default, `wm_gravity: southwest`
#   etc. in the item's frontmatter to move it away from colorbars). The
#   lightbox opens this via data-full-src; plain still images keep pointing
#   at their clean originals. SVGs are rasterized; stills capped at 2400px.
#
# Skips regeneration when the derivative is newer than the source image, the
# gallery doc (frontmatter holds thumb_frame/wm_gravity) and the logo.
# Falls back to the original image if ImageMagick is unavailable.
module Jekyll
  module GalleryThumbs
    THUMB_WIDTH   = 1200   # 2x display size of ~400px gives a sharp retina image
    THUMB_DIR     = 'thumbs'
    THUMB_QUALITY = 85

    FULL_DIR      = 'full'
    FULL_MAX_W    = 2400   # plenty for fullscreen; keeps webp/gif sizes sane
    FULL_QUALITY  = 92
    WM_LOGO       = 'assets/images/logo/font.svg'
    WM_WIDTH_FRAC  = 0.06  # logo width relative to image width
    WM_MARGIN_FRAC = 0.02
    WM_OPACITY     = '0.6'

    class Generator < Jekyll::Generator
      safe true
      priority :high

      def generate(site)
        return unless site.collections.key?('gallery')

        @magick = which('magick') || which('convert')
        @rsvg   = which('rsvg-convert')
        @logo   = File.join(site.source, WM_LOGO)

        site.collections['gallery'].docs.each do |doc|
          src_rel = doc.data['image']
          next if src_rel.nil? || src_rel.empty?

          src_path = File.join(site.source, src_rel.sub(%r{^/}, ''))
          unless File.exist?(src_path)
            Jekyll.logger.warn 'GalleryThumbs:', "source missing: #{src_rel}"
            next
          end

          thumb_rel  = thumb_rel_for(src_rel)
          thumb_path = File.join(site.source, thumb_rel.sub(%r{^/}, ''))
          frame      = doc.data['thumb_frame'].to_i

          if needs_generation?([src_path, doc.path], thumb_path)
            existed = File.exist?(thumb_path)
            unless @magick && generate_thumb(src_path, thumb_path, frame)
              Jekyll.logger.warn 'GalleryThumbs:', "no thumb for #{src_rel}, using original"
              doc.data['thumb'] = src_rel
              next
            end
            register_static(site, thumb_rel) unless existed
            Jekyll.logger.info 'GalleryThumbs:', "wrote #{thumb_rel}"
          end

          doc.data['thumb'] = thumb_rel

          # Watermark only media that plays; plain stills stay clean.
          unless doc.data['video'] || File.extname(src_rel).casecmp('.gif').zero?
            doc.data['full'] = src_rel
            next
          end

          full_rel  = full_rel_for(src_rel)
          full_path = File.join(site.source, full_rel.sub(%r{^/}, ''))
          gravity   = doc.data['wm_gravity'] || 'southeast'

          if needs_generation?([src_path, doc.path, @logo], full_path)
            existed = File.exist?(full_path)
            unless @magick && generate_full(src_path, full_path, gravity)
              Jekyll.logger.warn 'GalleryThumbs:', "no watermarked full for #{src_rel}, using original"
              doc.data['full'] = src_rel
              next
            end
            register_static(site, full_rel) unless existed
            Jekyll.logger.info 'GalleryThumbs:', "wrote #{full_rel}"
          end

          doc.data['full'] = full_rel
        end
      end

      private

      def thumb_rel_for(src_rel)
        dir  = File.dirname(src_rel)
        base = File.basename(src_rel, '.*')
        "#{dir}/#{THUMB_DIR}/#{base}.webp"
      end

      def full_rel_for(src_rel)
        dir  = File.dirname(src_rel)
        base = File.basename(src_rel, '.*')
        ext  = File.extname(src_rel).casecmp('.gif').zero? ? 'gif' : 'webp'
        "#{dir}/#{FULL_DIR}/#{base}.#{ext}"
      end

      # Files created mid-build aren't in site.static_files (Jekyll enumerates
      # them before generators run), so a brand-new derivative must be added
      # explicitly or it won't be copied to _site until the next build.
      def register_static(site, rel)
        rel = rel.sub(%r{^/}, '')
        site.static_files << Jekyll::StaticFile.new(
          site, site.source, File.dirname(rel), File.basename(rel)
        )
      end

      def which(cmd)
        path = `command -v #{cmd} 2>/dev/null`.strip
        path.empty? ? nil : path
      end

      def needs_generation?(srcs, dst)
        return true unless File.exist?(dst)
        srcs.any? { |src| File.exist?(src) && File.mtime(src) > File.mtime(dst) }
      end

      def generate_thumb(src, dst, frame = 0)
        FileUtils.mkdir_p(File.dirname(dst))
        # [frame] keeps the thumb static for animated sources; no-op otherwise.
        # Optimized GIFs store frames as delta regions, so compose the frame
        # from all frames up to it (-coalesce) instead of reading it raw.
        input = if frame.zero?
                  ["#{src}[0]"]
                else
                  ["#{src}[0-#{frame}]", '-coalesce', '-delete', "0-#{frame - 1}"]
                end
        cmd = [@magick, *input, '-resize', "#{THUMB_WIDTH}x>", '-strip',
               '-quality', THUMB_QUALITY.to_s, dst]
        run(cmd, dst)
      end

      def generate_full(src, dst, gravity)
        FileUtils.mkdir_p(File.dirname(dst))
        ext = File.extname(src).downcase

        if ext == '.svg'
          input   = rasterize_svg(src)
          return false unless input
          width = FULL_MAX_W
        else
          input = src
          out, _, status = Open3.capture3(@magick, 'identify', '-format', '%w', "#{input}[0]")
          return false unless status.success?
          width = [out.to_i, FULL_MAX_W].min
        end

        logo_w = (width * WM_WIDTH_FRAC).round
        margin = (width * WM_MARGIN_FRAC).round
        wm     = ['(', @logo, '-background', 'none', '-resize', "#{logo_w}x",
                  '-channel', 'A', '-evaluate', 'multiply', WM_OPACITY, '+channel', ')',
                  '-gravity', gravity, '-geometry', "+#{margin}+#{margin}"]

        cmd = if ext == '.gif'
                # animated: watermark every frame, keeping timing/loop intact
                [@magick, input, '-coalesce', 'null:', *wm,
                 '-layers', 'composite', '-layers', 'optimize', dst]
              else
                [@magick, input, '-resize', "#{FULL_MAX_W}x>", *wm,
                 '-composite', '-strip', '-quality', FULL_QUALITY.to_s, dst]
              end
        run(cmd, dst)
      end

      # IM's own SVG rendering can be flaky; prefer rsvg-convert when present.
      def rasterize_svg(src)
        return src unless @rsvg
        tmp = File.join(Dir.tmpdir, "gallery_full_#{File.basename(src, '.*')}.png")
        _, stderr, status = Open3.capture3(@rsvg, '-w', FULL_MAX_W.to_s, src, '-o', tmp)
        unless status.success?
          Jekyll.logger.warn 'GalleryThumbs:', stderr.strip[0..200]
          return nil
        end
        tmp
      end

      def run(cmd, dst)
        _, stderr, status = Open3.capture3(*cmd)
        unless status.success?
          Jekyll.logger.warn 'GalleryThumbs:', stderr.strip[0..200]
          File.delete(dst) if File.exist?(dst)
        end
        status.success?
      end
    end
  end
end
