require "rails_helper"

RSpec.describe MetadataAttributer do
  let(:subject) { described_class }
  describe "from_rating" do
    let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
    def expect_matching_attributes(rating_metadata, json_ld, metadata_attrs)
      expect(subject.metadata_authors(rating_metadata, json_ld)).to eq(metadata_attrs[:authors])
      expect(subject.metadata_published_at(rating_metadata, json_ld)&.to_i).to be_within(1).of metadata_attrs[:published_at].to_i
      expect(subject.metadata_published_updated_at(rating_metadata, json_ld)&.to_i).to be_within(1).of metadata_attrs[:published_updated_at]&.to_i
      expect(subject.metadata_description(rating_metadata, json_ld)).to eq metadata_attrs[:description]
      expect(subject.metadata_canonical_url(rating_metadata, json_ld)).to eq metadata_attrs[:canonical_url]
      expect(subject.metadata_word_count(rating_metadata, json_ld, 100)).to eq metadata_attrs[:word_count]
      expect(subject.metadata_paywall(rating_metadata, json_ld)).to be_falsey

      expect_hashes_to_match(subject.from_rating(rating), metadata_attrs, match_time_within: 1)
    end

    context "new yorker" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_new_yorker.json")) }
      let(:submitted_url) { "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy?utm_s=example" }
      let(:metadata_attrs) do
        {
          authors: ["Jonathan Blitzer"],
          published_at: Time.at(1682713348),
          published_updated_at: Time.at(1682713348),
          description: "Jonathan Blitzer writes about the House Republican’s budget proposal that was bundled with its vote to raise the debt ceiling, and about Kevin McCarthy’s weakened position as Speaker.",
          canonical_url: "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy",
          word_count: 2_040,
          paywall: false,
          title: "The Risky Gamble of Kevin McCarthy’s Debt-Ceiling Strategy",
          publisher_name: "The New Yorker"
        }
      end
      it "returns target" do
        json_ld = subject.json_ld_hash(rating.citation_metadata)

        expect_matching_attributes(rating.citation_metadata, json_ld, metadata_attrs)
      end
    end
    context "80000 hours" do
      let(:citation_metadata_str) { '[{"charset":"utf-8"},{"content":"width=device-width, initial-scale=1","name":"viewport"},{"content":"index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1","name":"robots"},{"content":"en_US","property":"og:locale"},{"content":"article","property":"og:type"},{"content":"Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy","property":"og:title"},{"content":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/","property":"og:url"},{"content":"80,000 Hours","property":"og:site_name"},{"content":"https://www.facebook.com/80000Hours","property":"article:publisher"},{"content":"2022-12-14T12:13:15+00:00","property":"article:modified_time"},{"content":"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png","property":"og:image"},{"content":"2364","property":"og:image:width"},{"content":"1183","property":"og:image:height"},{"content":"image/png","property":"og:image:type"},{"content":"summary_large_image","name":"twitter:card"},{"content":"@80000hours","name":"twitter:site"},{"content":"524811344265777","property":"fb:app_id"},{"content":"#FFFFFF","name":"msapplication-TileColor"},{"content":"/favicon-144.png","name":"msapplication-TileImage"},{"json_ld":["{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"WebPage\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\",\"url\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\",\"name\":\"Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy - 80,000 Hours\",\"isPartOf\":{\"@id\":\"https://80000hours.org/#website\"},\"primaryImageOfPage\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\"},\"image\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\"},\"thumbnailUrl\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"datePublished\":\"2022-02-02T22:43:27+00:00\",\"dateModified\":\"2022-12-14T12:13:15+00:00\",\"breadcrumb\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb\"},\"inLanguage\":\"en-US\",\"potentialAction\":[{\"@type\":\"ReadAction\",\"target\":[\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\"]}]},{\"@type\":\"ImageObject\",\"inLanguage\":\"en-US\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\",\"url\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"contentUrl\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"width\":2364,\"height\":1183},{\"@type\":\"BreadcrumbList\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb\",\"itemListElement\":[{\"@type\":\"ListItem\",\"position\":1,\"name\":\"Home\",\"item\":\"https://80000hours.org/\"},{\"@type\":\"ListItem\",\"position\":2,\"name\":\"Podcast\",\"item\":\"https://80000hours.org/podcast/\"},{\"@type\":\"ListItem\",\"position\":3,\"name\":\"All episodes\",\"item\":\"https://80000hours.org/podcast/episodes/\"},{\"@type\":\"ListItem\",\"position\":4,\"name\":\"Audrey Tang on what we can learn from Taiwan’s experiments with how to do&nbsp;democracy\"}]},{\"@type\":\"WebSite\",\"@id\":\"https://80000hours.org/#website\",\"url\":\"https://80000hours.org/\",\"name\":\"80,000 Hours\",\"description\":\"\",\"publisher\":{\"@id\":\"https://80000hours.org/#organization\"},\"potentialAction\":[{\"@type\":\"SearchAction\",\"target\":{\"@type\":\"EntryPoint\",\"urlTemplate\":\"https://80000hours.org/?s={search_term_string}\"},\"query-input\":\"required name=search_term_string\"}],\"inLanguage\":\"en-US\"},{\"@type\":\"Organization\",\"@id\":\"https://80000hours.org/#organization\",\"name\":\"80,000 Hours\",\"url\":\"https://80000hours.org/\",\"logo\":{\"@type\":\"ImageObject\",\"inLanguage\":\"en-US\",\"@id\":\"https://80000hours.org/#/schema/logo/image/\",\"url\":\"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png\",\"contentUrl\":\"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png\",\"width\":1500,\"height\":785,\"caption\":\"80,000 Hours\"},\"image\":{\"@id\":\"https://80000hours.org/#/schema/logo/image/\"},\"sameAs\":[\"https://www.facebook.com/80000Hours\",\"https://twitter.com/80000hours\",\"https://www.youtube.com/user/eightythousandhours\"]}]}"]},{"word_count":26678}]' }
      let(:submitted_url) { "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/" }
      let(:metadata_attrs) do
        {
          authors: [],
          published_at: Time.at(1643841807), # 2022-02-02
          published_updated_at: Time.at(1671019995), #
          description: nil,
          canonical_url: "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/",
          word_count: 26578,
          paywall: false,
          title: "Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy",
          publisher_name: "80,000 Hours"
        }
      end
      it "returns target" do
        json_ld = subject.json_ld_hash(rating.citation_metadata)

        expect(described_class.json_ld_graph(json_ld, "WebPage", "datePublished")).to eq "2022-02-02T22:43:27+00:00"

        expect_matching_attributes(rating.citation_metadata, json_ld, metadata_attrs)
      end
    end
    context "wikipedia" do
      let(:citation_metadata_str) { '[{"charset":"UTF-8"},{"content":"","name":"ResourceLoaderDynamicStyles"},{"content":"MediaWiki 1.41.0-wmf.6","name":"generator"},{"content":"origin","name":"referrer"},{"content":"origin-when-crossorigin","name":"referrer"},{"content":"origin-when-cross-origin","name":"referrer"},{"content":"max-image-preview:standard","name":"robots"},{"content":"telephone=no","name":"format-detection"},{"content":"https://upload.wikimedia.org/wikipedia/commons/8/8d/Tim_Federle.jpg","property":"og:image"},{"content":"1200","property":"og:image:width"},{"content":"1800","property":"og:image:height"},{"content":"https://upload.wikimedia.org/wikipedia/commons/8/8d/Tim_Federle.jpg","property":"og:image"},{"content":"800","property":"og:image:width"},{"content":"1200","property":"og:image:height"},{"content":"640","property":"og:image:width"},{"content":"960","property":"og:image:height"},{"content":"width=1000","name":"viewport"},{"content":"Tim Federle - Wikipedia","property":"og:title"},{"content":"website","property":"og:type"},{"property":"mw:PageProp/toc"},{"json_ld":["{\"@context\":\"https:\\/\\/schema.org\",\"@type\":\"Article\",\"name\":\"Tim Federle\",\"url\":\"https:\\/\\/en.wikipedia.org\\/wiki\\/Tim_Federle\",\"sameAs\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"mainEntity\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"author\":{\"@type\":\"Organization\",\"name\":\"Contributors to Wikimedia projects\"},\"publisher\":{\"@type\":\"Organization\",\"name\":\"Wikimedia Foundation, Inc.\",\"logo\":{\"@type\":\"ImageObject\",\"url\":\"https:\\/\\/www.wikimedia.org\\/static\\/images\\/wmf-hor-googpub.png\"}},\"datePublished\":\"2009-05-19T08:04:49Z\",\"dateModified\":\"2023-04-29T16:38:28Z\",\"image\":\"https:\\/\\/upload.wikimedia.org\\/wikipedia\\/commons\\/8\\/8d\\/Tim_Federle.jpg\",\"headline\":\"American actor\"}","{\"@context\":\"https:\\/\\/schema.org\",\"@type\":\"Article\",\"name\":\"Tim Federle\",\"url\":\"https:\\/\\/en.wikipedia.org\\/wiki\\/Tim_Federle\",\"sameAs\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"mainEntity\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"author\":{\"@type\":\"Organization\",\"name\":\"Contributors to Wikimedia projects\"},\"publisher\":{\"@type\":\"Organization\",\"name\":\"Wikimedia Foundation, Inc.\",\"logo\":{\"@type\":\"ImageObject\",\"url\":\"https:\\/\\/www.wikimedia.org\\/static\\/images\\/wmf-hor-googpub.png\"}},\"datePublished\":\"2009-05-19T08:04:49Z\",\"dateModified\":\"2023-04-29T16:38:28Z\",\"image\":\"https:\\/\\/upload.wikimedia.org\\/wikipedia\\/commons\\/8\\/8d\\/Tim_Federle.jpg\",\"headline\":\"American actor\"}"]},{"word_count":3038}]' }
      let(:submitted_url) { "https://en.wikipedia.org/wiki/Tim_Federle" }
      let(:metadata_attrs) do
        {
          authors: ["Contributors to Wikimedia projects"],
          published_at: Time.at(1242720289), # 2009-05-19
          published_updated_at: Time.at(1682786308),
          description: nil,
          canonical_url: "https://en.wikipedia.org/wiki/Tim_Federle",
          word_count: 2938,
          paywall: false,
          title: "Tim Federle - Wikipedia",
          publisher_name: "Wikimedia Foundation, Inc."
        }
      end
      it "returns target" do
        json_ld = subject.json_ld_hash(rating.citation_metadata)

        expect_matching_attributes(rating.citation_metadata, json_ld, metadata_attrs)
      end
    end
  end

  describe "json_ld" do
    let(:rating_metadata) { [{"json_ld" => values}] }
    let(:values) { [{"url" => "https://www.example.com"}] }
    it "returns json_ld" do
      expect(subject.json_ld_hash(rating_metadata)).to eq(values.first)
    end
    # There are lots of times where there are multiple. Not erroring until this becomes a problem
    # context "multiple json_ld items" do
    #   it "raises" do
    #     expect {
    #       subject.json_ld_hash(rating_metadata + rating_metadata)
    #     }.to raise_error(/multiple/i)
    #   end
    # end
    # context "multiple matching values" do
    #   let(:values) { [{"url" => "https://www.example.com"}, {"url" => "https://www.example.com"}] }
    #   it "raises" do
    #     expect {
    #       subject.json_ld_hash(rating_metadata + rating_metadata)
    #     }.to raise_error(/multiple/i)
    #   end
    # end
    context "multiple json_ld values" do
      let(:values) { [{"url" => "https://www.example.com"}, {"@type" => "OtherThing"}] }
      it "reduces" do
        expect(subject.json_ld_hash(rating_metadata)).to eq({"url" => "https://www.example.com", "@type" => "OtherThing"})
      end
    end
    context "more dataexample" do
      let(:values) { [{"url" => "https://example.com", "@type" => "NewsArticle", "image" => {"url" => "https://example.com/image.png", "@type" => "ImageObject", "width" => 2057, "height" => 1200}, "author" => ["John Doe"], "creator" => ["John Doe"], "hasPart" => [], "@context" => "http://schema.org", "headline" => "example title", "keywords" => ["topic: Cool Matters"]}, {"@type" => "BreadcrumbList", "@context" => "https://schema.org/"}] }
      let(:target) do
        {
          "url" => "https://example.com",
          "@type" => "NewsArticle",
          "image" => {"url" => "https://example.com/image.png", "@type" => "ImageObject", "width" => 2057, "height" => 1200},
          "author" => ["John Doe"],
          "creator" => ["John Doe"],
          "hasPart" => [],
          "@context" => "http://schema.org",
          "headline" => "example title",
          "keywords" => ["topic: Cool Matters"]
        }
      end
      it "raises" do
        expect(subject.json_ld_hash(rating_metadata)).to eq target
      end
    end
  end

  describe "metadata_authors" do
    context "json_ld authors" do
      let(:json_ld) { {"author" => {"name" => ["Jennifer Ludden", "Marisa Peñaloza"], "@type" => "Person"}} }
      let(:target) { ["Jennifer Ludden", "Marisa Peñaloza"] }
      it "returns authors names" do
        expect(described_class.text_or_name_prop(json_ld["author"])).to eq target
        # Full author parsing
        expect(described_class.metadata_authors({}, json_ld)).to eq target
      end
    end
  end

  describe "metadata_description" do
    context "description truncation" do
      let(:metadata) { [{"property" => "description", "content" => "I'm baby copper mug wolf fingerstache, echo park try-hard 8-bit freegan chartreuse sus deep v gastropub offal. Man braid iceland DSA, adaptogen air plant mustache next level. DSA twee 8-bit crucifix tumblr venmo. Street art four loko brunch iceland lumbersexual gatekeep, flexitarian single-origin coffee pickled everyday carry pabst. Trust fund 3 wolf moon mumblecore, man braid letterpress keytar cardigan praxis craft beer roof party whatever twee taxidermy. Gatekeep normcore meditation distillery, jianbing shaman viral."}] }
      let(:target) { "I'm baby copper mug wolf fingerstache, echo park try-hard 8-bit freegan chartreuse sus deep v gastropub offal. Man braid iceland DSA, adaptogen air plant mustache next level. DSA twee 8-bit crucifix tumblr venmo. Street art four loko brunch iceland lumbersexual gatekeep, flexitarian single-origin coffee pickled everyday carry pabst. Trust fund 3 wolf moon mumblecore, man braid letterpress keytar cardigan praxis craft beer roof party whatever twee taxidermy. Gatekeep normcore meditation..." }
      it "returns authors names" do
        expect(described_class.metadata_description(metadata, {})).to eq target
      end
    end
    context "description entity encoding" do
      let(:metadata) { [{"property" => "description", "content" => "Cool String&nbsp;here [&hellip;]"}] }
      let(:target) { "Cool String here ..." }
      it "returns authors names" do
        expect(described_class.metadata_description(metadata, {})).to eq target
      end
    end
  end

  describe "html_decode" do
    it "removes entities" do
      expect(described_class.html_decode("Cool String&nbsp;here [&hellip;]")).to eq "Cool String here ..."
      expect(described_class.html_decode("Cool String&amp;here ")).to eq "Cool String&here"
      expect(described_class.html_decode("Cool String&amp;here ")).to eq "Cool String&here"
    end
    it "returns nil for nbsp" do
      expect(described_class.html_decode(" &nbsp;")).to be_nil
    end
    it "strips tags" do
      expect(described_class.html_decode("<p>Stuff  </p>")).to eq "Stuff"
    end
  end
end
