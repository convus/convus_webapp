require "rails_helper"

RSpec.describe MetadataJsonLdParser do
  let(:subject) { described_class }
  describe "parse" do
    let(:citation_metadata_raw) { MetadataParser.parse_string(citation_metadata_str) }
    context "Just JSON-LD passed" do
      let(:citation_metadata_str) { '[{"json_ld":["{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"WebPage\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\",\"url\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\",\"name\":\"Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy - 80,000 Hours\",\"isPartOf\":{\"@id\":\"https://80000hours.org/#website\"},\"primaryImageOfPage\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\"},\"image\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\"},\"thumbnailUrl\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"datePublished\":\"2022-02-02T22:43:27+00:00\",\"dateModified\":\"2022-12-14T12:13:15+00:00\",\"breadcrumb\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb\"},\"inLanguage\":\"en-US\",\"potentialAction\":[{\"@type\":\"ReadAction\",\"target\":[\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\"]}]},{\"@type\":\"ImageObject\",\"inLanguage\":\"en-US\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\",\"url\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"contentUrl\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"width\":2364,\"height\":1183},{\"@type\":\"BreadcrumbList\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb\",\"itemListElement\":[{\"@type\":\"ListItem\",\"position\":1,\"name\":\"Home\",\"item\":\"https://80000hours.org/\"},{\"@type\":\"ListItem\",\"position\":2,\"name\":\"Podcast\",\"item\":\"https://80000hours.org/podcast/\"},{\"@type\":\"ListItem\",\"position\":3,\"name\":\"All episodes\",\"item\":\"https://80000hours.org/podcast/episodes/\"},{\"@type\":\"ListItem\",\"position\":4,\"name\":\"Audrey Tang on what we can learn from Taiwan’s experiments with how to do&nbsp;democracy\"}]},{\"@type\":\"WebSite\",\"@id\":\"https://80000hours.org/#website\",\"url\":\"https://80000hours.org/\",\"name\":\"80,000 Hours\",\"description\":\"\",\"publisher\":{\"@id\":\"https://80000hours.org/#organization\"},\"potentialAction\":[{\"@type\":\"SearchAction\",\"target\":{\"@type\":\"EntryPoint\",\"urlTemplate\":\"https://80000hours.org/?s={search_term_string}\"},\"query-input\":\"required name=search_term_string\"}],\"inLanguage\":\"en-US\"},{\"@type\":\"Organization\",\"@id\":\"https://80000hours.org/#organization\",\"name\":\"80,000 Hours\",\"url\":\"https://80000hours.org/\",\"logo\":{\"@type\":\"ImageObject\",\"inLanguage\":\"en-US\",\"@id\":\"https://80000hours.org/#/schema/logo/image/\",\"url\":\"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png\",\"contentUrl\":\"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png\",\"width\":1500,\"height\":785,\"caption\":\"80,000 Hours\"},\"image\":{\"@id\":\"https://80000hours.org/#/schema/logo/image/\"},\"sameAs\":[\"https://www.facebook.com/80000Hours\",\"https://twitter.com/80000hours\",\"https://www.youtube.com/user/eightythousandhours\"]}]}"]}]' }
      it "returns target" do
        content_hash = subject.content_hash(citation_metadata_raw)
        # pp content_hash
        expect(content_hash.keys).to eq(%w[WebPage ImageObject BreadcrumbList WebSite Organization])

        # expect(metadata_attrs).to eq target_content_hash
      end
    end
    # context "pro_publica" do
    #   let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_propublica.json")) }
    #   it "returns target" do
    #   end
    # end
  end

  describe "content_hash" do
    let(:rating_metadata) { [{"json_ld" => values}] }
    let(:values) { [{"@type" => "WebSite", "url" => "https://www.example.com"}] }
    it "returns json_ld" do
      expect(subject.send(:content, rating_metadata)).to eq(values)
      expect(subject.content_hash(rating_metadata)).to eq({"WebSite" => values.first})

      expect(subject.parse(rating_metadata)).to eq(values.first)
    end
    # There are lots of times where there are multiple. Not erroring until this becomes a problem
    context "multiple json_ld items" do
      it "returns" do
        expect(subject.send(:content, rating_metadata + rating_metadata)).to eq(values + values)
        expect(subject.content_hash(rating_metadata + rating_metadata)).to eq({"WebSite" => values.first})
      end
      context "different values" do
        let(:values) { [{"@type" => "WebSite", "url" => "https://www.example.com"}, {"@type" => "WebSite", "url" => "DIFFERENT"}] }
        it "raises" do
          expect(subject.send(:content, rating_metadata)).to eq values
          expect {
            subject.content_hash(rating_metadata)
          }.to raise_error(/different/i)
        end
      end
      context "more values" do
        let(:values) do
          [
            {"url" => "https://www.example.com", "@type" => "WebSite"},
            {"name" => "The Atlantic", "@type" => "Organization"},
            {"@type" => "NewsArticle", "mainEntityOfPage" => {"@id" => "https://www.example.com", "@type" => "WebPage"}}
          ]
        end
        let(:target) { %w[WebSite Organization NewsArticle].zip(values).to_h }
        it "returns hash" do
          expect(subject.send(:content, rating_metadata)).to eq(values)
          expect(subject.content_hash(rating_metadata)).to eq target
        end
      end
    end
    context "more dataexample" do
      let(:values) { [{"url" => "https://example.com", "@type" => "NewsArticle", "image" => {"url" => "https://example.com/image.png", "@type" => "ImageObject", "width" => 2057, "height" => 1200}, "author" => ["John Doe"], "creator" => ["John Doe"], "hasPart" => [], "@context" => "http://schema.org", "headline" => "example title", "keywords" => ["topic: Cool Matters"]}, {"@type" => "BreadcrumbList", "@context" => "https://schema.org/"}] }
      let(:target) do
        {"NewsArticle" => {
           "@type" => "NewsArticle",
           "url" => "https://example.com",
           "image" => {"url" => "https://example.com/image.png", "@type" => "ImageObject", "width" => 2057, "height" => 1200},
           "author" => ["John Doe"],
           "creator" => ["John Doe"],
           "hasPart" => [],
           "@context" => "http://schema.org",
           "headline" => "example title",
           "keywords" => ["topic: Cool Matters"]
         },
         "BreadcrumbList" => {
           "@type" => "BreadcrumbList",
           "@context" => "https://schema.org/"
         }}
      end
      it "returns" do
        expect(subject.send(:content, rating_metadata)).to eq target.values
        expect(subject.content_hash(rating_metadata)).to eq target

        expect(subject.parse(rating_metadata)).to eq target["NewsArticle"]
      end
    end
    context "@graph" do
      let(:values) { {"@context" => "https://schema.org", "@graph" => graph} }
      let(:graph) do
        [
          {"@type" => "ImageObject", "inLanguage" => "en-US"},
          {"@type" => "BreadcrumbList"},
          {"@type" => "WebSite", "url" => "https://example.org/"},
          {"@type" => "Organization", "name" => "EXAMPLE"}
        ]
      end
      let(:target) { %w[ImageObject BreadcrumbList WebSite Organization].zip(graph).to_h }
      it "returns the graph" do
        expect(subject.send(:content, rating_metadata)).to eq([values])
        expect(subject.content_hash(rating_metadata)).to eq target

        expect(subject.parse(rating_metadata)).to eq graph.first
      end
    end
  end
end
