require 'open-uri'
require 'nokogiri'
require 'json'
require 'net/http'

module Jekyll
  class ScholarStats < Generator
    safe true
    priority :low

    SCHOLAR_URL = 'http://scholar.google.com/citations?hl=en&user='.freeze
    CACHE_DIR = './.scholar_cache'.freeze
    CACHE_FILE = "#{CACHE_DIR}/scholar_data.json".freeze

    def generate(site)
      @scholar_id = site.config.dig('author', 'scholar') || site.config.dig('author', 'googlescholar')
      unless @scholar_id
        Jekyll.logger.warn "ScholarStats:", "No author.scholar / author.googlescholar set in _config.yml"
        return
      end

      begin
        if ENV['CI']
          fetch_scholar_data_from_serpapi(site)
        else
          fetch_scholar_data_locally(site)
        end
      rescue => e
        Jekyll.logger.warn "ScholarStats:", "Error: #{e.message}"
      end
    end

    def fetch_scholar_data_from_serpapi(site)
      api_key = ENV['SERPAPI_API_KEY']
      unless api_key
        Jekyll.logger.warn "ScholarStats:", "SERPAPI_API_KEY not set in CI; falling back to cache"
        load_cache_into(site)
        return
      end
      url = "https://serpapi.com/search.json?engine=google_scholar_author&author_id=#{@scholar_id}&api_key=#{api_key}"
      data = JSON.parse(URI.open(url).read)
      site.data['scholar'] = {
        'id' => @scholar_id,
        'citations' => data.dig('cited_by', 'table', 0, 'citations', 'all'),
        'h_index' => data.dig('cited_by', 'table', 1, 'h_index', 'all'),
        'i10_index' => data.dig('cited_by', 'table', 2, 'i10_index', 'all')
      }
      Jekyll.logger.info "ScholarStats:", "Loaded data for #{@scholar_id} from SerpAPI"
      save_to_cache(site.data['scholar'])
    rescue => e
      Jekyll.logger.warn "ScholarStats:", "Failed to fetch from SerpAPI: #{e.message}"
      load_cache_into(site)
    end

    def fetch_scholar_data_locally(site)
      url = SCHOLAR_URL + @scholar_id
      Jekyll.logger.info "ScholarStats:", "Fetching data from Google Scholar..."
      doc = Nokogiri::HTML(URI.open(url, "User-Agent" => "Mozilla/5.0"))

      tbl = doc.css('table').first
      unless tbl
        Jekyll.logger.warn "ScholarStats:", "No stats table found at #{url}; falling back to cache"
        load_cache_into(site)
        return
      end

      tbl_data = { 'id' => @scholar_id }
      tbl.css('tr')[1..].each do |tr|
        cell_data = tr.css('td').map(&:text)
        tbl_data[cell_data[0].downcase.sub('-', '_')] = cell_data[1].to_i
      end
      site.data['scholar'] = tbl_data
      Jekyll.logger.info "ScholarStats:", "Loaded data for #{@scholar_id} from HTTP request"
      save_to_cache(tbl_data)
    rescue => e
      Jekyll.logger.warn "ScholarStats:", "Error fetching data locally: #{e.message}"
      load_cache_into(site)
    end

    def load_cache_into(site)
      cached = load_from_cache
      if cached
        site.data['scholar'] = cached
        Jekyll.logger.info "ScholarStats:", "Using cached data for #{@scholar_id}"
      else
        Jekyll.logger.warn "ScholarStats:", "No usable cache available"
      end
    end

    def save_to_cache(data)
      # Ensure cache directory exists
      Dir.mkdir(CACHE_DIR) unless File.exist?(CACHE_DIR)

      # Write the data to a cache file (overwrite cache if exists)
      File.open(CACHE_FILE, 'w') do |f|
        f.write(JSON.pretty_generate(data))
      end
      Jekyll.logger.info "ScholarStats:", "Data saved to cache."
    end

    def load_from_cache
      if File.exist?(CACHE_FILE)
        # Read from the cache file
        file_content = File.read(CACHE_FILE)
        JSON.parse(file_content) rescue nil # If parsing fails, return nil
      else
        nil
      end
    end
  end
end
