require 'fileutils'
require 'open3'

# Generates downscaled WebP thumbnails for gallery items so the /gallery grid
# loads ~1.5 MB instead of ~64 MB. The full-resolution original is still used
# in the lightbox (see _includes/scripts/components/lightbox.js, which reads
# data-full-src in preference to src).
#
# Output: <dir>/thumbs/<basename>.webp next to each source image.
# Skips regeneration when the thumb is newer than both the source image and
# the gallery doc (the doc counts because thumb_frame lives in its frontmatter).
# Animated sources (GIF) yield a static thumb from a single frame — frame 0 by
# default, or the frame given by `thumb_frame:` in the item's frontmatter.
# Falls back to the original image if ImageMagick is unavailable.
module Jekyll
  module GalleryThumbs
    THUMB_WIDTH   = 1200   # 2x display size of ~400px gives a sharp retina image
    THUMB_DIR     = 'thumbs'
    THUMB_QUALITY = 85

    class Generator < Jekyll::Generator
      safe true
      priority :high

      def generate(site)
        return unless site.collections.key?('gallery')

        @magick = which('magick') || which('convert')

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
            unless @magick && generate_thumb(src_path, thumb_path, frame)
              Jekyll.logger.warn 'GalleryThumbs:', "no thumb for #{src_rel}, using original"
              doc.data['thumb'] = src_rel
              next
            end
            Jekyll.logger.info 'GalleryThumbs:', "wrote #{thumb_rel}"
          end

          doc.data['thumb'] = thumb_rel
        end
      end

      private

      def thumb_rel_for(src_rel)
        dir  = File.dirname(src_rel)
        base = File.basename(src_rel, '.*')
        "#{dir}/#{THUMB_DIR}/#{base}.webp"
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
        cmd = [@magick, "#{src}[#{frame}]", '-resize', "#{THUMB_WIDTH}x>", '-strip',
               '-quality', THUMB_QUALITY.to_s, dst]
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
