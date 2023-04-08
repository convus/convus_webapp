class TopicCsvImporter
  class << self
    require "csv"

    def import_url(url)
      import_csv(URI.parse(url).open)
    end

    def import_csv(open_file)
      # Grab the first line of the csv (which is the header line) and transform it
      headers = convert_headers(open_file.readline)
      csv = CSV.new(open_file, headers: headers)
      # Stream process the rest of the csv, cribbed from:
      # github.com/bikeindex/bike_index/blob/main/app/workers/bulk_import_worker.rb
      # We want lines to start at 1, not 0
      row_index = 1
      csv = CSV.new(open_file, headers: headers)
      while (row = csv.shift)
        row_index += 1 # row_index is current line number
        import_topic(row[:name])
      end
    end

    def import_topic(name)
      Topic.find_or_create_for_name(name, update_attrs: true)
    end

    def convert_headers(str)
      str.split(",").map { |h| Slugifyer.slugify(h).to_sym }
    end
  end
end
