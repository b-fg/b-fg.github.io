require 'open-uri'
require 'nokogiri'
require 'json'
require 'net/http'

module Jekyll
  class ScholarStats < Generator
    safe true
    priority :low

    SCHOLAR_ID = 'FSwTh_gAAAAJ'.freeze
    SCHOLAR_URL = 'http://scholar.google.com/citations?hl=en&user='.freeze
    SERPAPI_API_KEY = ENV['SERPAPI_API_KEY']
    SERPAPI_URL = "https://serpapi.com/search.json?engine=google_scholar_author&author_id=#{SCHOLAR_ID}&api_key=#{SERPAPI_API_KEY}"
    CACHE_DIR = './.scholar_cache'.freeze
    CACHE_FILE = "#{CACHE_DIR}/scholar_data.json".freeze

    def generate(site)
      begin
        # Check if we're running in CI (or if not, we assume local environment)
        if ENV['CI']
          # In CI, use SerpAPI and fallback to cache if needed
          fetch_scholar_data_from_serpapi(site)
        else
          # In local environment, use HTTP request and overwrite cache
          fetch_scholar_data_locally(site)
        end
      rescue => e
        Jekyll.logger.warn "ScholarStats:", "Error: #{e.message}"
      end
    end

    def fetch_scholar_data_from_serpapi(site)
      response = URI.open(SERPAPI_URL).read
      data = JSON.parse(response)
      Jekyll.logger.info data
      site.data['scholar'] = {
        'id' => SCHOLAR_ID,
        'citations' => data.dig('cited_by', 'table', 0, 'citations', 'all'),
        'h_index' => data.dig('cited_by', 'table', 1, 'h_index', 'all'),
        'i10_index' => data.dig('cited_by', 'table', 2, 'i10_index', 'all')
      }
      Jekyll.logger.info "ScholarStats:", "Loaded data for #{SCHOLAR_ID} from SerpAPI"

      # Save the data into cache file
      save_to_cache(site.data['scholar'])

    rescue => e
      Jekyll.logger.warn "ScholarStats:", "Failed to fetch from SerpAPI: #{e.message}"
      Jekyll.logger.info "ScholarStats:", "Loading from cached file instead."
      # First check if cached data exists
      if File.exist?(CACHE_FILE)
        # If cache exists, load and use it
        cached_data = load_from_cache
        if cached_data
          site.data['scholar'] = cached_data
          Jekyll.logger.info "ScholarStats:", "Using cached data for #{SCHOLAR_ID}."
          return
        else
          Jekyll.logger.warn "ScholarStats:", "Cache data is invalid."
        end
      end
    end

    def fetch_scholar_data_locally(site)
      # Always fetch the data and overwrite the cache file locally
      begin
        url = SCHOLAR_URL + SCHOLAR_ID
        Jekyll.logger.info "ScholarStats:", "Fetching data from Google Scholar..."

        # Open the URL with a custom User-Agent
        doc = Nokogiri::HTML(URI.open(url, "User-Agent" => "Mozilla/5.0"))

        # Extract the stats table
        tbl = doc.css('table').first
        unless tbl
          Jekyll.logger.warn "ScholarStats:", "No stats table found at #{url}"
          return
        end

        tbl_data = { 'id' => SCHOLAR_ID }
        tbl.css('tr')[1..].each do |tr|
          cell_data = tr.css('td').map(&:text)
          tbl_data[cell_data[0].downcase.sub('-', '_')] = cell_data[1].to_i
        end
        site.data['scholar'] = tbl_data
        Jekyll.logger.info "ScholarStats:", "Loaded data for #{SCHOLAR_ID} from HTTP request"

        # Save data to cache for future builds (overwrite cache file)
        save_to_cache(tbl_data)
      rescue => e
        Jekyll.logger.warn "ScholarStats:", "Error fetching data locally: #{e.message}"
        if File.exist?(CACHE_FILE)
          # If cache exists, load and use it
          cached_data = load_from_cache
          if cached_data
            site.data['scholar'] = cached_data
            Jekyll.logger.info "ScholarStats:", "Using cached data for #{SCHOLAR_ID}"
            return
          else
            Jekyll.logger.warn "ScholarStats:", "Cache data is invalid."
          end
        end
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
