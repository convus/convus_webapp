require "rails_helper"

RSpec.describe TopicsCsver do
  describe "import_url" do
    let(:file_url) { "https://raw.githubusercontent.com/convus/convus_reviews/main/spec/fixtures/example_topics.csv" }
    it "imports" do
      VCR.use_cassette("topics_csver_import") do
        expect(Topic.count).to eq 0
        described_class.import_url(file_url)
        expect(Topic.count).to eq 2
        expect(Topic.pluck(:name)).to match_array(["San Francisco", "California"])
      end
    end
  end

  describe "import_csv" do
    let(:csv_lines) do
      [["name, Parents"],
       ["A topic",nil],
       ["Party ", "a topic"]]
    end
    let(:csv_string) { csv_lines.map { |r| r.join(",") }.join("\n") }
    let!(:tempfile) do
      file = Tempfile.new
      file.write(csv_string)
      file.rewind
      file
    end
    after { tempfile.close && tempfile.unlink }
    it "imports" do
      expect(Topic.count).to eq 0
      expect(described_class.import_csv(tempfile))
      expect(Topic.count).to eq 2
      expect(Topic.pluck(:name)).to match_array(["A topic", "Party"])
      tempfile.rewind
      expect(described_class.import_csv(tempfile))
      expect(Topic.count).to eq 2
      topic = Topic.friendly_find "Party"
      expect(topic.direct_parents.pluck(:name)).to eq(["A topic"])
    end
    context "amps and dupes" do
      let(:csv_lines) do
        [["name", "parents"],
         ["Netflix", nil],
         ["Netflix and chill", nil],
         ["Netflix & chill ", ""],
         ["Netflix &Amp; chill ", nil],
         [nil, nil]]
      end
      it "imports" do
        expect(Topic.count).to eq 0
        expect(described_class.import_csv(tempfile))
        expect(Topic.pluck(:name)).to match_array(["Netflix", "Netflix and chill"])
        tempfile.rewind
        expect(described_class.import_csv(tempfile))
        expect(Topic.count).to eq 2
      end
    end
  end

  describe "import_topic" do
    let(:name) { "Something" }
    it "creates topic, updates otherwise" do
      topic = described_class.import_topic("something")
      expect(topic.name).to eq "something"
      described_class.import_topic("Something ")
      expect(topic.reload.name).to eq "Something"
    end
    context "slug match" do
      let(:name) { "Cool Topic Thing" }
      let(:update_name) { "cool-topic-thing" }
      it "updates the topic" do
        topic = described_class.import_topic(name)
        expect(described_class.import_topic(update_name)&.id).to eq topic.id
        expect(topic.reload.name).to eq update_name
      end
    end
  end

  describe "convert_headers" do
    it "converts" do
      expect(described_class.convert_headers("name")).to eq([:name])
      expect(described_class.convert_headers("name, Parents")).to eq([:name, :parents])
    end
  end
end
