class TopicsCsver
  class << self
    require "csv"

    def import_url(url)
      open_file = URI.parse(url).open
      import_csv(open_file)
      # HACK! reimport, to fix any missing parents.
      open_file.rewind
      import_csv(open_file)
    end

    def import_csv(open_file)
      # Grab the first line of the csv (which is the header line) and transform it
      headers = convert_headers(open_file.readline)
      # Stream process the rest of the csv, cribbed from:
      # github.com/bikeindex/bike_index/blob/main/app/workers/bulk_import_worker.rb
      # We want lines to start at 1, not 0
      row_index = 1
      csv = CSV.new(open_file, headers: headers)
      while (row = csv.shift)
        row_index += 1 # row_index is current line number
        import_topic(row[:name], row[:parents])
      end
    end

    def import_topic(name, parents = nil)
      Topic.find_or_create_for_name(name, update_attrs: true, parents_string: parents)
    end

    def convert_headers(str)
      str.split(",").map { |h| Slugifyer.slugify(h).to_sym }
    end
  end
end
