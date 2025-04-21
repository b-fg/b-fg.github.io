require 'open-uri'
require 'nokogiri'

module Jekyll
  class ScholarStats < Generator
    safe true
    priority :low

    SCHOLAR_ID = 'FSwTh_gAAAAJ'.freeze
    SCHOLAR_URL = 'http://scholar.google.com/citations?hl=en&user='.freeze

    def generate(site)
      begin
        url = SCHOLAR_URL + SCHOLAR_ID
        doc = Nokogiri::HTML(URI.open(url, "User-Agent" => "Mozilla/5.0"))

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
        Jekyll.logger.info "ScholarStats:", "Loaded data for #{SCHOLAR_ID}"
      rescue OpenURI::HTTPError => e
        Jekyll.logger.warn "ScholarStats:", "HTTP error: #{e.message}"
      rescue => e
        Jekyll.logger.warn "ScholarStats:", "Unexpected error: #{e.class} - #{e.message}"
      end
    end
  end
end

