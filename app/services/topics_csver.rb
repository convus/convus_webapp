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
      DistantChildCreatorJob.perform_async
    end

    def import_topic(name, parents = nil)
      Topic.find_or_create_for_name(name,
        update_attrs: true,
        skip_distant_children: true,
        parents_string: parents)
    end

    def convert_headers(str)
      str.split(",").map { |h| Slugifyer.slugify(h).to_sym }
    end

    def write_csv
      tmpfile = Tempfile.new("topics.csv")
      tmpfile.write(comma_wrapped_string(["Name", "Parents"]))
      Topic.find_each { |t| tmpfile.write(comma_wrapped_string(topic_csv_row(t))) }
      puts tmpfile.path
      tmpfile.rewind
      tmpfile
    end

    def topic_csv_row(topic)
      [topic.name, topic.parents_string]
    end

    def comma_wrapped_string(array)
      array.map do |val|
        '"' + val.to_s.tr("\\", "").gsub(/(\\)?"/, '\"') + '"'
      end.join(",") + "\n"
    end
  end
end
