require 'open-uri'
require 'json'

module Jekyll
  class ScholarStats < Generator
    safe true
    priority :low

    SCHOLAR_ID = 'FSwTh_gAAAAJ'.freeze
    SERPAPI_API_KEY = ENV['SERPAPI_API_KEY'] # Use the GitHub Actions secret
    SERPAPI_URL = "https://serpapi.com/search.json?engine=google_scholar_author&author_id=#{SCHOLAR_ID}&api_key=#{SERPAPI_API_KEY}"

    def generate(site)
      if SERPAPI_API_KEY.nil? || SERPAPI_API_KEY.empty?
        Jekyll.logger.warn "ScholarStats:", "Missing SerpAPI API Key!"
        return
      end

      begin
        response = URI.open(SERPAPI_URL).read
        data = JSON.parse(response)

        scholar_data = {
          'id' => SCHOLAR_ID,
          'name' => data.dig('author', 'name'),
          'affiliation' => data.dig('author', 'affiliations'),
          'total_citations' => data.dig('cited_by', 'table', 0, 'citations', 'all'),
          'h_index' => data.dig('cited_by', 'table', 1, 'h_index', 'all'),
          'i10_index' => data.dig('cited_by', 'table', 2, 'i10_index', 'all')
        }

        site.data['scholar'] = scholar_data
        Jekyll.logger.info "ScholarStats:", "Successfully loaded scholar data via SerpAPI"
      rescue => e
        Jekyll.logger.warn "ScholarStats:", "Error fetching data: #{e.class} - #{e.message}"
      end
    end
  end
end
