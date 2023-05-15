require "rails_helper"

RSpec.describe MetadataAttributer do
  let(:subject) { described_class }
  describe "from_rating" do
    let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
    def expect_matching_attributes(rating_metadata, json_ld, metadata_attrs)
      expect(subject.send(:metadata_authors, rating_metadata, json_ld)).to eq(metadata_attrs[:authors])
      expect(subject.send(:metadata_published_at, rating_metadata, json_ld)&.to_i).to be_within(1).of metadata_attrs[:published_at].to_i
      expect(subject.send(:metadata_published_updated_at, rating_metadata, json_ld)&.to_i).to be_within(1).of metadata_attrs[:published_updated_at]&.to_i
      expect(subject.send(:metadata_description, rating_metadata, json_ld)).to eq metadata_attrs[:description]
      expect(subject.send(:metadata_canonical_url, rating_metadata, json_ld)).to eq metadata_attrs[:canonical_url]
      expect(subject.send(:metadata_word_count, rating_metadata, json_ld, 100)).to eq metadata_attrs[:word_count]
      expect(subject.send(:metadata_paywall, rating_metadata, json_ld)).to be_falsey

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
          topics_string: nil,
          keywords: ["debt ceiling", "joe biden", "kevin mccarthy", "textaboveleftsmallwithrule", "the political scene", "u.s. budget", "u.s. congress", "u.s. presidents", "web"],
          publisher_name: "The New Yorker"
        }
      end
      it "returns target" do
        json_ld = subject.send(:json_ld_hash, rating.citation_metadata_raw)

        expect_matching_attributes(rating.citation_metadata_raw, json_ld, metadata_attrs)
      end
      context "with topics" do
        let!(:topic1) { Topic.find_or_create_for_name("Joe Biden") }
        let!(:topic2) { Topic.find_or_create_for_name("U.S. Budget") }
        let!(:topic3) { Topic.find_or_create_for_name("U.S. President") }
        let(:topic_names) { ["Joe Biden", "U.S. Budget"] }
        it "returns target" do
          topic1.update(parents_string: "U.S. presidents")
          expect(topic3.reload.children.pluck(:id)).to eq([topic1.id])
          json_ld = subject.send(:json_ld_hash, rating.citation_metadata_raw)

          expect(subject.send(:keyword_or_text_topic_names, metadata_attrs)).to eq(topic_names)

          expect_matching_attributes(rating.citation_metadata_raw, json_ld, metadata_attrs.merge(topics_string: topic_names.join(",")))
        end
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
          keywords: [],
          topics_string: nil,
          publisher_name: "80,000 Hours"
        }
      end
      it "returns target" do
        json_ld = subject.send(:json_ld_hash, rating.citation_metadata_raw)

        expect(subject.send(:json_ld_graph, json_ld, "WebPage", "datePublished")).to eq "2022-02-02T22:43:27+00:00"

        expect_matching_attributes(rating.citation_metadata_raw, json_ld, metadata_attrs)
      end
      # TODO: fallback to description & title to get the topics
      # context "with topics" do
      #   let!(:topic1) { Topic.find_or_create_for_name("Taiwan") }
      #   let!(:topic2) { Topic.find_or_create_for_name("Democracy") }
      #   let(:topic_names) { ["Democracy", "Taiwan"] }
      #   it "returns target" do
      #     json_ld = subject.send(:json_ld_hash, rating.citation_metadata_raw)

      #     expect(subject.send(:keyword_or_text_topic_names, metadata_attrs)).to eq(topic_names)

      #     expect_matching_attributes(rating.citation_metadata_raw, json_ld, metadata_attrs.merge(topic_names: topic_names))
      #   end
      # end
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
          keywords: [],
          topics_string: nil,
          publisher_name: "Wikimedia Foundation, Inc."
        }
      end
      it "returns target" do
        json_ld = subject.send(:json_ld_hash, rating.citation_metadata_raw)

        expect_matching_attributes(rating.citation_metadata_raw, json_ld, metadata_attrs)
      end
    end
    context "pro_publica" do
      let(:citation_metadata_str) { '[{"content":"text/html; charset=utf-8","http-equiv":"Content-Type"},{"name":"parsely-title","content":"The Ugly Truth Behind “We Buy Ugly Houses”"},{"name":"parsely-link","content":"https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses"},{"name":"parsely-type","content":"post"},{"name":"parsely-image-url","content":"https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87"},{"name":"parsely-pub-date","content":"2023-05-11T06:00:00-04:00"},{"name":"parsely-section","content":"National"},{"name":"parsely-author","content":"Anjeanette Damon"},{"name":"parsely-author","content":"Byard Duncan"},{"name":"parsely-author","content":"Mollie Simon"},{"name":"parsely-tags","content":"lang:en,storytype:enterprise"},{"name":"description","content":"HomeVestors of America, the self-proclaimed “largest homebuyer in the U.S.,” trains its nearly 1,150 franchisees to zero in on homeowners’ desperation."},{"name":"referrer","content":"no-referrer-when-downgrade"},{"content":"Anjeanette Damon,Byard Duncan,Mollie Simon","property":"author"},{"content":"The Ugly Truth Behind “We Buy Ugly Houses”","property":"headline"},{"content":"13320939444","property":"fb:profile_id"},{"content":"en_US","property":"og:locale"},{"content":"ProPublica","property":"og:site_name"},{"content":"article","property":"og:type"},{"content":"https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses","property":"og:url"},{"content":"The Ugly Truth Behind “We Buy Ugly Houses”","property":"og:title"},{"content":"HomeVestors of America, the self-proclaimed “largest homebuyer in the U.S.,” trains its nearly 1,150 franchisees to zero in on homeowners’ desperation.","property":"og:description"},{"content":"https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87","property":"og:image"},{"content":"https://vimeo.com/propublica","property":"og:see_also"},{"content":"https://www.pinterest.com/propublica","property":"og:see_also"},{"content":"https://www.instagram.com/propublica","property":"og:see_also"},{"content":"https://www.linkedin.com/company/propublica/","property":"og:see_also"},{"content":"https://github.com/propublica","property":"og:see_also"},{"content":"https://www.youtube.com/user/propublica","property":"og:see_also"},{"content":"https://en.wikipedia.org/wiki/ProPublica","property":"og:see_also"},{"content":"https://www.facebook.com/propublica/","property":"og:see_also"},{"content":"https://twitter.com/propublica","property":"og:see_also"},{"name":"twitter:card","content":"summary_large_image"},{"name":"twitter:site","content":"@propublica"},{"name":"twitter:creator","content":"@propublica"},{"name":"twitter:title","content":"The Ugly Truth Behind “We Buy Ugly Houses”"},{"name":"twitter:description","content":"HomeVestors of America, the self-proclaimed “largest homebuyer in the U.S.,” trains its nearly 1,150 franchisees to zero in on homeowners’ desperation."},{"name":"twitter:image","content":"https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87"},{"word_count":5636},{"json_ld":[{"@graph":[{"url":"https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses","name":"The Ugly Truth Behind “We Buy Ugly Houses”","@type":"NewsArticle","image":{"url":"https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87","@type":"ImageObject"},"author":{"@id":"https://www.propublica.org#identity"},"creator":["Anjeanette Damon","Byard Duncan","Mollie Simon"],"headline":"The Ugly Truth Behind “We Buy Ugly Houses”","publisher":{"@id":"https://www.propublica.org#creator"},"inLanguage":"en-us","description":"HomeVestors of America, the self-proclaimed “largest homebuyer in the U.S.,” trains its nearly 1,150 franchisees to zero in on homeowners’ desperation.","dateModified":"2023-05-10T18:07:16-04:00","thumbnailUrl":"https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87","copyrightYear":"2023","datePublished":"2023-05-11T06:00:00-04:00","copyrightHolder":{"@id":"https://www.propublica.org#identity"},"mainEntityOfPage":"https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses"},{"@id":"https://www.propublica.org#identity","url":"https://www.propublica.org","name":"ProPublica","@type":"NewsMediaOrganization","email":"info@propublica.org","sameAs":["https://twitter.com/propublica","https://www.facebook.com/propublica/","https://en.wikipedia.org/wiki/ProPublica","https://www.youtube.com/user/propublica","https://github.com/propublica","https://www.linkedin.com/company/propublica/","https://www.instagram.com/propublica","https://www.pinterest.com/propublica","https://vimeo.com/propublica"],"address":{"@type":"PostalAddress","postalCode":"10013","addressRegion":"NY","streetAddress":"155 Avenue of the Americas, 13th Floor","addressCountry":"US","addressLocality":"New York"},"telephone":"1-212-514-5250","description":"ProPublica is an independent, non-profit newsroom that produces investigative journalism in the public interest."},{"@id":"#creator","@type":"Organization"},{"name":"Breadcrumbs","@type":"BreadcrumbList","description":"Breadcrumbs list","itemListElement":[{"item":"https://www.propublica.org","name":"Homepage","@type":"ListItem","position":1},{"item":"https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses","name":"The Ugly Truth Behind “We Buy Ugly Houses”","@type":"ListItem","position":2}]}],"@context":"http://schema.org"}]}]' }
      let(:submitted_url) { "https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses" }
      let(:metadata_attrs) do
        {
          authors: ["Anjeanette Damon", "Byard Duncan", "Mollie Simon"],
          published_at: Time.at(1242720289), # 2009-05-19
          published_updated_at: Time.at(1682786308),
          description: nil,
          canonical_url: "https://en.wikipedia.org/wiki/Tim_Federle",
          word_count: 2938,
          paywall: false,
          title: "Tim Federle - Wikipedia",
          keywords: [],
          topics_string: nil,
          publisher_name: "Wikimedia Foundation, Inc."
        }
      end
      it "returns target" do
        json_ld = subject.send(:json_ld_hash, rating.citation_metadata_raw)
        pp json_ld
        expect_matching_attributes(rating.citation_metadata_raw, json_ld, metadata_attrs)
      end
    end
  end

  describe "json_ld" do
    let(:rating_metadata) { [{"json_ld" => values}] }
    let(:values) { [{"url" => "https://www.example.com"}] }
    it "returns json_ld" do
      expect(subject.send(:json_ld_hash, rating_metadata)).to eq(values.first)
    end
    # There are lots of times where there are multiple. Not erroring until this becomes a problem
    # context "multiple json_ld items" do
    #   it "raises" do
    #     expect {
    #       subject.send(:json_ld_hash, rating_metadata + rating_metadata)
    #     }.to raise_error(/multiple/i)
    #   end
    # end
    # context "multiple matching values" do
    #   let(:values) { [{"url" => "https://www.example.com"}, {"url" => "https://www.example.com"}] }
    #   it "raises" do
    #     expect {
    #       subject.send(:json_ld_hash, rating_metadata + rating_metadata)
    #     }.to raise_error(/multiple/i)
    #   end
    # end
    context "multiple json_ld values" do
      let(:values) { [{"url" => "https://www.example.com"}, {"@type" => "OtherThing"}] }
      it "reduces" do
        expect(subject.send(:json_ld_hash, rating_metadata)).to eq({"url" => "https://www.example.com", "@type" => "OtherThing"})
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
        expect(subject.send(:json_ld_hash, rating_metadata)).to eq target
      end
    end
  end

  describe "metadata_authors" do
    context "json_ld authors" do
      let(:json_ld) { {"author" => {"name" => ["Jennifer Ludden", "Marisa Peñaloza"], "@type" => "Person"}} }
      let(:target) { ["Jennifer Ludden", "Marisa Peñaloza"] }
      it "returns authors names" do
        expect(subject.send(:text_or_name_prop, json_ld["author"])).to eq target
        # Full author parsing
        expect(subject.send(:metadata_authors, {}, json_ld)).to eq target
      end
    end
  end

  describe "metadata_description" do
    context "description truncation" do
      let(:metadata) { [{"property" => "description", "content" => "I'm baby copper mug wolf fingerstache, echo park try-hard 8-bit freegan chartreuse sus deep v gastropub offal. Man braid iceland DSA, adaptogen air plant mustache next level. DSA twee 8-bit crucifix tumblr venmo. Street art four loko brunch iceland lumbersexual gatekeep, flexitarian single-origin coffee pickled everyday carry pabst. Trust fund 3 wolf moon mumblecore, man braid letterpress keytar cardigan praxis craft beer roof party whatever twee taxidermy. Gatekeep normcore meditation distillery, jianbing shaman viral."}] }
      let(:target) { "I'm baby copper mug wolf fingerstache, echo park try-hard 8-bit freegan chartreuse sus deep v gastropub offal. Man braid iceland DSA, adaptogen air plant mustache next level. DSA twee 8-bit crucifix tumblr venmo. Street art four loko brunch iceland lumbersexual gatekeep, flexitarian single-origin coffee pickled everyday carry pabst. Trust fund 3 wolf moon mumblecore, man braid letterpress keytar cardigan praxis craft beer roof party whatever twee taxidermy. Gatekeep normcore meditation..." }
      it "returns authors names" do
        expect(subject.send(:metadata_description, metadata, {})).to eq target
      end
    end
    context "description entity encoding" do
      let(:metadata) { [{"property" => "description", "content" => "Cool String&nbsp;here [&hellip;]"}] }
      let(:target) { "Cool String here ..." }
      it "returns authors names" do
        expect(subject.send(:metadata_description, metadata, {})).to eq target
      end
    end
  end

  describe "metadata_keywords" do
    let(:metadata_keywords) { [{"name" => "keywords", "itemid" => "#keywords", "content" => "Donald Trump,  Chris Christie, Republican primary"}] }
    let(:target) { ["Chris Christie", "Donald Trump", "Republican primary"] }
    it "returns topics" do
      expect(subject.send(:metadata_keywords, metadata_keywords, {})).to eq target
    end
    context "news keywords" do
      let(:metadata_news) { [{"name" => "news_keywords", "content" => "Donald Trump, Chris Christie, Republican primary"}] }
      it "returns topics" do
        expect(subject.send(:metadata_keywords, metadata_news, {})).to eq target
        expect(subject.send(:metadata_keywords, metadata_news + metadata_keywords, {})).to eq target
      end
    end
  end

  describe "remove publisher from title" do
    context "national review" do
      let(:title) { "How the Private Sector Is Shaping the Future of Nuclear Energy | National Review" }
      it "removes publisher" do
        expect(subject.send(:title_without_publisher, title, "National Review")).to eq "How the Private Sector Is Shaping the Future of Nuclear Energy"
      end
    end
  end

  describe "html_decode" do
    it "removes entities" do
      expect(subject.send(:html_decode, "Cool String&nbsp;here [&hellip;]")).to eq "Cool String here ..."
      expect(subject.send(:html_decode, "Cool String&amp;here ")).to eq "Cool String&here"
      expect(subject.send(:html_decode, "Cool String&amp;here ")).to eq "Cool String&here"
    end
    it "returns nil for nbsp" do
      expect(subject.send(:html_decode, " &nbsp;")).to be_nil
    end
    it "strips tags" do
      expect(subject.send(:html_decode, "<p>Stuff  </p>")).to eq "Stuff"
    end
  end
end
