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
end
