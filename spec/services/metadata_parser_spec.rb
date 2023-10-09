require "rails_helper"

RSpec.describe MetadataParser do
  let(:subject) { described_class }
  describe "parse_string" do
    context "basic" do
      let(:input_str) { "[{\"content\":\"https://example.com/stuff/things\",\"property\":\"og:url\"}, {}]" }
      let(:target) { [{"content" => "https://example.com/stuff/things", "property" => "og:url"}] }
      it "returns" do
        expect(subject.parse_string(input_str)).to eq target
      end
    end
    context "stack overflow" do
      let(:input_str) { "[{\"content\":\"width=device-width, height=device-height, initial-scale=1.0, minimum-scale=1.0\",\"name\":\"viewport\"},{\"content\":\"website\",\"property\":\"og:type\"},{\"content\":\"https://stackoverflow.com/questions/86653/how-to-pretty-format-json-output-in-ruby-on-rails\",\"property\":\"og:url\"},{\"content\":\"Stack Overflow\",\"property\":\"og:site_name\"},{\"content\":\"https://cdn.sstatic.net/Sites/stackoverflow/Img/apple-touch-icon@2.png?v=73d79a89bded\",\"itemprop\":\"image primaryImageOfPage\",\"property\":\"og:image\"},{\"content\":\"summary\",\"name\":\"twitter:card\"},{\"content\":\"stackoverflow.com\",\"name\":\"twitter:domain\"},{\"content\":\"How to \\\"pretty\\\" format JSON output in Ruby on Rails\",\"itemprop\":\"name\",\"name\":\"twitter:title\",\"property\":\"og:title\"},{\"content\":\"I would like my JSON output in Ruby on Rails to be \\\"pretty\\\" or nicely formatted. \\n\\nRight now, I call to_json and my JSON is all on one line.  At times this can be difficult to see if there is a pro...\",\"itemprop\":\"description\",\"name\":\"twitter:description\",\"property\":\"og:description\"},{\"content\":\"A0VQgOQvA+kwCj319NCwgf8+syUgEQ8/LLpB8RxxlRC3AkJ9xx8IAvVuQ/dcwy0ok7sGKufLLu6WhsXbQR9/UwwAAACFeyJvcmlnaW4iOiJodHRwczovL2RvdWJsZWNsaWNrLm5ldDo0NDMiLCJmZWF0dXJlIjoiUHJpdmFjeVNhbmRib3hBZHNBUElzIiwiZXhwaXJ5IjoxNjg4MDgzMTk5LCJpc1N1YmRvbWFpbiI6dHJ1ZSwiaXNUaGlyZFBhcnR5Ijp0cnVlfQ==\",\"http-equiv\":\"origin-trial\"},{\"content\":\"A6kRo9zXJhOvsR4D/VeZ9CiApPAxnOGzBkW88d8eIt9ex2oOzlX+AoUk/BS50Y9Ysy2jwyHR49Mb7XwP+l9yygIAAACLeyJvcmlnaW4iOiJodHRwczovL2dvb2dsZXN5bmRpY2F0aW9uLmNvbTo0NDMiLCJmZWF0dXJlIjoiUHJpdmFjeVNhbmRib3hBZHNBUElzIiwiZXhwaXJ5IjoxNjg4MDgzMTk5LCJpc1N1YmRvbWFpbiI6dHJ1ZSwiaXNUaGlyZFBhcnR5Ijp0cnVlfQ==\",\"http-equiv\":\"origin-trial\"},{\"content\":\"A3mbHZoS4VJtJ8j1aE8+Z9vaGf/oMV1eTNIWMrvGqWgNnOmvaxnRGliqKIZU2eiTzCj5Qpz8B1/UTTLuony5bAAAAACLeyJvcmlnaW4iOiJodHRwczovL2dvb2dsZXRhZ3NlcnZpY2VzLmNvbTo0NDMiLCJmZWF0dXJlIjoiUHJpdmFjeVNhbmRib3hBZHNBUElzIiwiZXhwaXJ5IjoxNjg4MDgzMTk5LCJpc1N1YmRvbWFpbiI6dHJ1ZSwiaXNUaGlyZFBhcnR5Ijp0cnVlfQ==\",\"http-equiv\":\"origin-trial\"},{\"content\":\"As0hBNJ8h++fNYlkq8cTye2qDLyom8NddByiVytXGGD0YVE+2CEuTCpqXMDxdhOMILKoaiaYifwEvCRlJ/9GcQ8AAAB8eyJvcmlnaW4iOiJodHRwczovL2RvdWJsZWNsaWNrLm5ldDo0NDMiLCJmZWF0dXJlIjoiV2ViVmlld1hSZXF1ZXN0ZWRXaXRoRGVwcmVjYXRpb24iLCJleHBpcnkiOjE3MTk1MzI3OTksImlzU3ViZG9tYWluIjp0cnVlfQ==\",\"http-equiv\":\"origin-trial\"},{\"content\":\"AgRYsXo24ypxC89CJanC+JgEmraCCBebKl8ZmG7Tj5oJNx0cmH0NtNRZs3NB5ubhpbX/bIt7l2zJOSyO64NGmwMAAACCeyJvcmlnaW4iOiJodHRwczovL2dvb2dsZXN5bmRpY2F0aW9uLmNvbTo0NDMiLCJmZWF0dXJlIjoiV2ViVmlld1hSZXF1ZXN0ZWRXaXRoRGVwcmVjYXRpb24iLCJleHBpcnkiOjE3MTk1MzI3OTksImlzU3ViZG9tYWluIjp0cnVlfQ==\",\"http-equiv\":\"origin-trial\"}]" }
      let(:target) do
        [{"content" => "website", "property" => "og:type"},
          {"content" => "https://stackoverflow.com/questions/86653/how-to-pretty-format-json-output-in-ruby-on-rails", "property" => "og:url"},
          {"content" => "Stack Overflow", "property" => "og:site_name"},
          {"content" => "https://cdn.sstatic.net/Sites/stackoverflow/Img/apple-touch-icon@2.png?v=73d79a89bded", "itemprop" => "image primaryImageOfPage", "property" => "og:image"},
          {"content" => "summary", "name" => "twitter:card"},
          {"content" => "stackoverflow.com", "name" => "twitter:domain"},
          {"content" => "How to \"pretty\" format JSON output in Ruby on Rails", "itemprop" => "name", "name" => "twitter:title", "property" => "og:title"},
          {"content" => "I would like my JSON output in Ruby on Rails to be \"pretty\" or nicely formatted. \n\nRight now, I call to_json and my JSON is all on one line.  At times this can be difficult to see if there is a pro...", "itemprop" => "description", "name" => "twitter:description", "property" => "og:description"}]
      end
      it "is invalid" do
        result = subject.parse_string(input_str)
        expect(result).to eq target
      end
    end
    context "null" do
      it "returns nil" do
        expect(subject.parse_string("null")).to eq([])
        expect(subject.parse_string("[null]")).to eq([])
      end
    end
    context "2023-10 - frameId hash wrapper in Safari" do
      let(:input_str) { "{\"frameId\": 0,\"result\": [{\"name\": \"description\",\"content\": \"A description\"}]}" }
      let(:target) { [{"name" => "description", "content" => "A description"}] }
      it "returns result" do
        result = subject.parse_string(input_str)
        expect(result).to eq target
      end
    end
  end

  describe "parse_array" do
    context "json_ld" do
      let(:json_ld_str) { "[{\"@context\":\"https://schema.org\",\"@type\":\"NewsArticle\",\"mainEntityOfPage\":\"https://www.vox.com/today-explained-podcast/2023/3/11/23634087/dc-crime-bill-congress-overrule-biden-no-veto\",\"url\":\"https://www.vox.com/today-explained-podcast/2023/3/11/23634087/dc-crime-bill-congress-overrule-biden-no-veto\",\"headline\":\"Why Congress — and Biden — killed DC’s crime bill\",\"description\":\"Washington just owned DC.\",\"speakable\":{\"@type\":\"SpeakableSpecification\",\"xpath\":[\"/html/head/title\",\"/html/head/meta[@name='description']/@content\"]},\"datePublished\":\"2023-03-11T07:00:00-05:00\",\"dateModified\":\"2023-03-11T07:00:00-05:00\",\"author\":[{\"@type\":\"Person\",\"name\":\"Miles Bryan\"}],\"publisher\":{\"@type\":\"Organization\",\"name\":\"Vox\",\"logo\":{\"@type\":\"ImageObject\",\"url\":\"https://cdn.vox-cdn.com/uploads/chorus_asset/file/13668548/google_amp.0.png\",\"width\":600,\"height\":60}},\"articleSection\":\"Today, Explained\",\"keywords\":[\"Front Page\",\"Politics\",\"Podcasts\",\"Policy\",\"Today, Explained\"],\"image\":[{\"@type\":\"ImageObject\",\"url\":\"https://cdn.vox-cdn.com/thumbor/0ro0ofBU37xkLZfqou79peurSiQ=/1400x1400/filters:format(jpeg)/cdn.vox-cdn.com/uploads/chorus_asset/file/24494606/GettyImages_1472152372.jpg\",\"width\":1400,\"height\":1400},{\"@type\":\"ImageObject\",\"url\":\"https://cdn.vox-cdn.com/thumbor/1ONgy2FkjPtL-xJKWrGhih6BBMQ=/1400x1050/filters:format(jpeg)/cdn.vox-cdn.com/uploads/chorus_asset/file/24494606/GettyImages_1472152372.jpg\",\"width\":1400,\"height\":1050},{\"@type\":\"ImageObject\",\"url\":\"https://cdn.vox-cdn.com/thumbor/akI2NtWTRzfiYlZ3ie7_U3DKx7Y=/1400x788/filters:format(jpeg)/cdn.vox-cdn.com/uploads/chorus_asset/file/24494606/GettyImages_1472152372.jpg\",\"width\":1400,\"height\":788}],\"thumbnailUrl\":\"https://cdn.vox-cdn.com/thumbor/0ro0ofBU37xkLZfqou79peurSiQ=/1400x1400/filters:format(jpeg)/cdn.vox-cdn.com/uploads/chorus_asset/file/24494606/GettyImages_1472152372.jpg\"}]" }
      # NOTE: metadata is a method name in rspec, so avoid using it
      let(:m_data) { {"json_ld" => [json_ld_str]} }
      let(:target_keys) { %w[@context @type articleSection author dateModified datePublished description headline image keywords mainEntityOfPage publisher speakable thumbnailUrl url] }
      it "parses json_ld" do
        result = subject.parse_array([m_data])
        expect(result.count).to eq 1
        json_ld = result.first["json_ld"]
        expect(json_ld.count).to eq 1
        expect(json_ld.first.keys.sort).to eq target_keys
      end
      context "json_ld not wrapped" do
        let(:m_data) { {"json_ld" => json_ld_str} }
        it "parses if json_ld isn't wrapped" do
          result = subject.parse_array([m_data])
          expect(result.count).to eq 1
          json_ld = result.first["json_ld"]
          expect(json_ld.count).to eq 1
          expect(json_ld.first.keys.sort).to eq target_keys
        end
      end
      context "json_ld invalid" do
        let(:m_data) { {"json_ld" => [{stuff: "fff"}]} }
        it "doesn't error if json_ld is invalid" do
          result = subject.parse_array([m_data])
          expect(result.count).to eq 1
          expect(result.first).to eq m_data
        end
      end
    end
  end

  describe "ignored_tag?" do
    it "ignores nonce" do
      expect(subject.ignored_tag?({"name" => "html-safe-nonce"})).to be_truthy
      expect(subject.ignored_tag?({"name" => "nonce-html-safe"})).to be_truthy
      expect(subject.ignored_tag?({"name" => "nonced-html-safe"})).to be_falsey
    end
    it "ignores hash" do
      expect(subject.ignored_tag?({"name" => "html-safe-hash"})).to be_truthy
      expect(subject.ignored_tag?({"name" => "hashparty"})).to be_falsey
    end
    it "ignores hmac" do
      expect(subject.ignored_tag?({"name" => "visitor-HMAC"})).to be_truthy
      expect(subject.ignored_tag?({"name" => "hMaC"})).to be_truthy
      expect(subject.ignored_tag?({"name" => "hmacing"})).to be_falsey
    end
  end

  describe "hash_to_array" do
    let(:input) { {"some" => "thing", "content" => [{"name" => "description", "content" => "A description"}]} }
    let(:target) { [{"some" => "thing"}, {"content" => input["content"]}] }
    it "returns the hash" do
      expect(subject.send(:hash_to_array, input)).to eq target
    end
  end
end
