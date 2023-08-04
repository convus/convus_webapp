require "rails_helper"

RSpec.describe MetadataAttributer do
  let(:subject) { described_class }
  describe "from_rating" do
    let(:rating) { FactoryBot.create(:rating, submitted_url: submitted_url, citation_metadata_str: citation_metadata_str) }
    let(:target_normalized) { metadata_attrs.merge(canonical_url: nil) }
    def expect_matching_attributes(rating_metadata, json_ld, metadata_attrs)
      expect(subject.send(:metadata_authors, rating_metadata, json_ld)).to eq(metadata_attrs[:authors])
      expect(subject.send(:metadata_published_at, rating_metadata, json_ld)&.to_i).to be_within(1).of metadata_attrs[:published_at].to_i
      expect(subject.send(:metadata_published_updated_at, rating_metadata, json_ld)&.to_i).to be_within(1).of metadata_attrs[:published_updated_at]&.to_i
      expect(subject.send(:metadata_description, rating_metadata, json_ld)).to eq metadata_attrs[:description]
      expect(subject.send(:metadata_canonical_url, rating_metadata, json_ld)).to eq metadata_attrs[:canonical_url]
      best_text = subject.text_from_json_ld_article_body(json_ld["articleBody"])
      expect(subject.send(:metadata_word_count, best_text, rating_metadata, 100)).to eq metadata_attrs[:word_count]
      expect(subject.send(:metadata_paywall, rating_metadata, json_ld)).to be_falsey

      expect_hashes_to_match(subject.from_rating(rating, skip_clean_attrs: true), metadata_attrs, match_time_within: 1)

      expect_hashes_to_match(subject.from_rating(rating), target_normalized, match_time_within: 1)
    end

    context "new yorker" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_new_yorker.json")) }
      let(:submitted_url) { "https://www.newyorker.com/news/the-political-scene/the-risky-gamble-of-kevin-mccarthys-debt-ceiling-strategy?utm_s=example" }
      let(:metadata_attrs) do
        {
          authors: ["Jonathan Blitzer"],
          published_at: 1682713348,
          published_updated_at: 1682713348,
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
      let(:target_normalized) { metadata_attrs.merge(canonical_url: nil, published_updated_at: nil) }
      it "returns target" do
        expect_matching_attributes(rating.citation_metadata_raw, rating.json_ld_parsed, metadata_attrs)
      end
      context "with topics" do
        let!(:topic1) { Topic.find_or_create_for_name("Joe Biden") }
        let!(:topic2) { Topic.find_or_create_for_name("U.S. Budget") }
        let!(:topic3) { Topic.find_or_create_for_name("U.S. President") }
        let(:topic_names) { ["Joe Biden", "U.S. Budget"] }
        let(:target_metadata) { metadata_attrs.merge(topics_string: topic_names.join(",")) }
        let(:target_normalized) { target_metadata.merge(canonical_url: nil, published_updated_at: nil) }
        it "returns target" do
          topic1.update(parents_string: "U.S. presidents")
          expect(topic3.reload.children.pluck(:id)).to eq([topic1.id])

          expect(subject.send(:keyword_or_text_topic_names, metadata_attrs)).to eq(topic_names)

          expect_matching_attributes(rating.citation_metadata_raw, rating.json_ld_parsed, target_metadata)
        end
      end
    end
    context "80000 hours" do
      let(:citation_metadata_str) { '[{"content":"en_US","property":"og:locale"},{"content":"article","property":"og:type"},{"content":"Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy","property":"og:title"},{"content":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/","property":"og:url"},{"content":"80,000 Hours","property":"og:site_name"},{"content":"https://www.facebook.com/80000Hours","property":"article:publisher"},{"content":"2022-12-14T12:13:15+00:00","property":"article:modified_time"},{"content":"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png","property":"og:image"},{"content":"2364","property":"og:image:width"},{"content":"1183","property":"og:image:height"},{"content":"image/png","property":"og:image:type"},{"name":"twitter:card","content":"summary_large_image"},{"name":"twitter:site","content":"@80000hours"},{"word_count":26686},{"json_ld":[{"@graph":[{"@id":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/","url":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/","name":"Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy - 80,000 Hours","@type":"WebPage","image":{"@id":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage"},"isPartOf":{"@id":"https://80000hours.org/#website"},"breadcrumb":{"@id":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb"},"inLanguage":"en-US","dateModified":"2022-12-14T12:13:15+00:00","thumbnailUrl":"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png","datePublished":"2022-02-02T22:43:27+00:00","potentialAction":[{"@type":"ReadAction","target":["https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/"]}],"primaryImageOfPage":{"@id":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage"}},{"@id":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage","url":"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png","@type":"ImageObject","width":2364,"height":1183,"contentUrl":"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png","inLanguage":"en-US"},{"@id":"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb","@type":"BreadcrumbList","itemListElement":[{"item":"https://80000hours.org/","name":"Home","@type":"ListItem","position":1},{"item":"https://80000hours.org/podcast/","name":"Podcast","@type":"ListItem","position":2},{"item":"https://80000hours.org/podcast/episodes/","name":"All episodes","@type":"ListItem","position":3},{"name":"Audrey Tang on what we can learn from Taiwan’s experiments with how to do&nbsp;democracy","@type":"ListItem","position":4}]},{"@id":"https://80000hours.org/#website","url":"https://80000hours.org/","name":"80,000 Hours","@type":"WebSite","publisher":{"@id":"https://80000hours.org/#organization"},"inLanguage":"en-US","description":"","potentialAction":[{"@type":"SearchAction","target":{"@type":"EntryPoint","urlTemplate":"https://80000hours.org/?s={search_term_string}"},"query-input":"required name=search_term_string"}]},{"@id":"https://80000hours.org/#organization","url":"https://80000hours.org/","logo":{"@id":"https://80000hours.org/#/schema/logo/image/","url":"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png","@type":"ImageObject","width":1500,"height":785,"caption":"80,000 Hours","contentUrl":"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png","inLanguage":"en-US"},"name":"80,000 Hours","@type":"Organization","image":{"@id":"https://80000hours.org/#/schema/logo/image/"},"sameAs":["https://www.facebook.com/80000Hours","https://twitter.com/80000hours","https://www.youtube.com/user/eightythousandhours"]}],"@context":"https://schema.org"},{"@id":"https://player.backtracks.fm/80000hours/80000-hours-podcast-with-rob-wiblin/m/audrey-tang-what-we-can-learn-from-taiwan","name":"#120 – Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy","@type":"VideoObject","@context":"http://schema.org/","duration":"PT02H05M50.944S","embedUrl":"https://player.backtracks.fm/80000hours/80000-hours-podcast-with-rob-wiblin/m/audrey-tang-what-we-can-learn-from-taiwan","uploadDate":"2022-02-02T22:45:00+00:00","description":"In 2014 Taiwan was rocked by mass protests against a proposed trade agreement with China that was about to be agreed without the usual Parliamentary hearings. Students invaded and took over the Parliament. But rather than chant slogans, instead they livestreamed their own parliamentary debate over the trade deal, allowing volunteers to speak both in favour and against.\n\n \n\nInstead of polarising the country more, this so-called \'Sunflower Student Movement\' ultimately led to a bipartisan consensus that Taiwan should open up its government. That process has gradually made it one of the most communicative and interactive administrations anywhere in the world.\n\n \n\nToday\'s guest — programming prodigy Audrey Tang — initially joined the student protests to help get their streaming infrastructure online. After the students got the official hearings they wanted and went home, she was invited to consult for the government. And when the government later changed hands, she was invited to work in the ministry herself.\n\n \n\nLinks to learn more, summary and full transcript.\n\n\n\nDuring six years as the country\'s \'Digital Minister\' she has been helping Taiwan increase the flow of information between institutions and civil society and launched original experiments trying to make democracy itself work better.\n\n \n\nThat includes developing new tools to identify points of consensus between groups that mostly disagree, building social media platforms optimised for discussing policy issues, helping volunteers fight disinformation by making their own memes, and allowing the public to build their own alternatives to government websites whenever they don\'t like how they currently work.\n\n \n\nAs part of her ministerial role Audrey also sets aside time each week to help online volunteers working on government-related tech projects get the help they need. How does she decide who to help? She doesn\'t — that decision is made by members of an online community who upvote the projects they think are best.\n\n \n\nAccording to Audrey, a more collaborative mentality among the country\'s leaders has helped increase public trust in government, and taught bureaucrats that they can (usually) trust the public in return.\n\n \n\nInnovations in Taiwan may offer useful lessons to people who want to improve humanity\'s ability to make decisions and get along in large groups anywhere in the world. We cover:\n\n \n\n• Why it makes sense to treat Facebook as a nightclub\n \n• The value of having no reply button, and of getting more specific when you disagree\n \n• Quadratic voting and funding\n \n• Audrey’s experiences with the Sunflower Student Movement\n \n• Technologies Audrey is most excited about\n \n• Conservative anarchism\n \n• What Audrey’s day-to-day work looks like\n \n• Whether it’s ethical to eat oysters\n \n• And much more\n\n \n\nCheck out two current job opportunities at 80,000 Hours: Advisor and Head of Job Board.\n\n \n\nGet this episode by subscribing to our podcast on the world’s most pressing problems and how to solve them: type 80,000 Hours into your podcasting app.\n\n\n\n\nProducer: Keiran Harris\n\nAudio mastering: Ben Cordell\n\nTranscriptions: Katy Moore","thumbnailUrl":"https://feeds.backtracks.fm/feeds/series/d8f05142-2a38-11e9-bd0b-0ebe27f14992/episodes/bc335652-8477-11ec-8a7e-12010ffac149/images/main_500.jpeg?1683149683779"}]}]' }
      let(:submitted_url) { "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/" }
      let(:metadata_attrs) do
        {
          authors: [],
          published_at: Time.at(1643841807), # 2022-02-02
          published_updated_at: Time.at(1671019995), #
          description: "In 2014 Taiwan was rocked by mass protests against a proposed trade agreement with China that was about to be agreed without the usual Parliamentary hearings. Students invaded and took over the Parliament. But rather than chant slogans, instead they livestreamed their own parliamentary debate over the trade deal, allowing volunteers to speak both in favour and against. Instead of polarising the country more, this so-called 'Sunflower Student Movement' ultimately led to a bipartisan...",
          canonical_url: "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/",
          word_count: 26586,
          paywall: false,
          title: "Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy",
          keywords: [],
          topics_string: nil,
          publisher_name: "80,000 Hours"
        }
      end
      let(:target_normalized) { metadata_attrs }
      it "returns target" do
        expect(rating.submitted_url).to eq submitted_url
        expect(rating.submitted_url_normalized).to eq submitted_url.chop

        expect(rating.json_ld_content.keys).to eq(%w[VideoObject WebPage ImageObject BreadcrumbList WebSite Organization])
        expect_matching_attributes(rating.citation_metadata_raw, rating.json_ld_parsed, metadata_attrs)
      end
      # TODO: fallback to description & title to get the topics
      # context "with topics" do
      #   let!(:topic1) { Topic.find_or_create_for_name("Taiwan") }
      #   let!(:topic2) { Topic.find_or_create_for_name("Democracy") }
      #   let(:topic_names) { ["Democracy", "Taiwan"] }
      #   it "returns target" do
      #     expect(subject.send(:keyword_or_text_topic_names, metadata_attrs)).to eq(topic_names)

      #     expect_matching_attributes(rating.citation_metadata_raw, rating.json_ld_parsed, metadata_attrs.merge(topic_names: topic_names))
      #   end
      # end
    end
    context "wikipedia" do
      let(:citation_metadata_str) { '[{"charset":"UTF-8"},{"content":"","name":"ResourceLoaderDynamicStyles"},{"content":"MediaWiki 1.41.0-wmf.6","name":"generator"},{"content":"origin","name":"referrer"},{"content":"origin-when-crossorigin","name":"referrer"},{"content":"origin-when-cross-origin","name":"referrer"},{"content":"max-image-preview:standard","name":"robots"},{"content":"telephone=no","name":"format-detection"},{"content":"https://upload.wikimedia.org/wikipedia/commons/8/8d/Tim_Federle.jpg","property":"og:image"},{"content":"1200","property":"og:image:width"},{"content":"1800","property":"og:image:height"},{"content":"https://upload.wikimedia.org/wikipedia/commons/8/8d/Tim_Federle.jpg","property":"og:image"},{"content":"800","property":"og:image:width"},{"content":"1200","property":"og:image:height"},{"content":"640","property":"og:image:width"},{"content":"960","property":"og:image:height"},{"content":"width=1000","name":"viewport"},{"content":"Tim Federle - Wikipedia","property":"og:title"},{"content":"website","property":"og:type"},{"property":"mw:PageProp/toc"},{"json_ld":["{\"@context\":\"https:\\/\\/schema.org\",\"@type\":\"Article\",\"name\":\"Tim Federle\",\"url\":\"https:\\/\\/en.wikipedia.org\\/wiki\\/Tim_Federle\",\"sameAs\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"mainEntity\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"author\":{\"@type\":\"Organization\",\"name\":\"Contributors to Wikimedia projects\"},\"publisher\":{\"@type\":\"Organization\",\"name\":\"Wikimedia Foundation, Inc.\",\"logo\":{\"@type\":\"ImageObject\",\"url\":\"https:\\/\\/www.wikimedia.org\\/static\\/images\\/wmf-hor-googpub.png\"}},\"datePublished\":\"2009-05-19T08:04:49Z\",\"dateModified\":\"2023-04-29T16:38:28Z\",\"image\":\"https:\\/\\/upload.wikimedia.org\\/wikipedia\\/commons\\/8\\/8d\\/Tim_Federle.jpg\",\"headline\":\"American actor\"}","{\"@context\":\"https:\\/\\/schema.org\",\"@type\":\"Article\",\"name\":\"Tim Federle\",\"url\":\"https:\\/\\/en.wikipedia.org\\/wiki\\/Tim_Federle\",\"sameAs\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"mainEntity\":\"http:\\/\\/www.wikidata.org\\/entity\\/Q7803484\",\"author\":{\"@type\":\"Organization\",\"name\":\"Contributors to Wikimedia projects\"},\"publisher\":{\"@type\":\"Organization\",\"name\":\"Wikimedia Foundation, Inc.\",\"logo\":{\"@type\":\"ImageObject\",\"url\":\"https:\\/\\/www.wikimedia.org\\/static\\/images\\/wmf-hor-googpub.png\"}},\"datePublished\":\"2009-05-19T08:04:49Z\",\"dateModified\":\"2023-04-29T16:38:28Z\",\"image\":\"https:\\/\\/upload.wikimedia.org\\/wikipedia\\/commons\\/8\\/8d\\/Tim_Federle.jpg\",\"headline\":\"American actor\"}"]},{"word_count":3038}]' }
      let(:submitted_url) { "https://en.wikipedia.org/wiki/Tim_Federle" }
      let(:metadata_attrs) do
        {
          authors: ["Contributors to Wikimedia projects"],
          published_at: 1242720289, # 2009-05-19
          published_updated_at: 1682786308,
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
        expect_matching_attributes(rating.citation_metadata_raw, rating.json_ld_parsed, metadata_attrs)
      end
    end
    context "pro_publica" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_propublica.json")) }
      let(:submitted_url) { "https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses" }
      let(:metadata_attrs) do
        {
          authors: ["Anjeanette Damon", "Byard Duncan", "Mollie Simon"],
          published_at: 1683799200, # 2023-05-11 03:00:00
          published_updated_at: 1683756436, # 2023-05-10 15:07
          description: "HomeVestors of America, the self-proclaimed “largest homebuyer in the U.S.,” trains its nearly 1,150 franchisees to zero in on homeowners’ desperation.",
          canonical_url: "https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses",
          word_count: 5536,
          paywall: false,
          title: "The Ugly Truth Behind “We Buy Ugly Houses”",
          keywords: [],
          topics_string: nil,
          publisher_name: "ProPublica"
        }
      end
      let(:target_normalized) { metadata_attrs.merge(canonical_url: nil, published_updated_at: nil) }
      it "returns target" do
        expect_matching_attributes(rating.citation_metadata_raw, rating.json_ld_parsed, metadata_attrs)
      end
    end
  end

  describe "clean_attrs" do
    let(:rating) { Rating.new(submitted_url: "https://example.com") }
    let(:target_empty) { MetadataAttributer::ATTR_KEYS.map { |k| [k, nil] }.to_h }

    context "published_updated_at before published_at" do
      let(:time) { Time.current - 1.day }
      let(:attrs) { target_empty.merge(published_updated_at: Time.current - 1.week, published_at: time) }
      it "removes published_updated_at" do
        expect_hashes_to_match(subject.send(:clean_attrs, rating, attrs), target_empty.merge(published_at: time))
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
      context "author last name first" do
        let(:json_ld) { {"author" => "Smith, John"} }
        let(:target) { ["Smith, John"] }
        it "returns authors name" do
          expect(subject.send(:metadata_authors, {}, json_ld)).to eq target
        end
      end
      context "creator" do
        let(:json_ld) do
          {
            "creator" => ["Anjeanette Damon", "Byard Duncan", "Mollie Simon"],
            "author" => {"@id" => "https://www.propublica.org#identity"}
          }
        end
        let(:target) { ["Anjeanette Damon", "Byard Duncan", "Mollie Simon"] }
        it "returns creator" do
          expect(subject.send(:metadata_authors, {}, json_ld)).to eq target
        end
      end
    end
    context "author prop" do
      let(:metadata) { [{"content" => "Anjeanette Damon,Byard Duncan,Mollie Simon", "property" => "author"}] }
      let(:target) { ["Anjeanette Damon", "Byard Duncan", "Mollie Simon"] }
      it "returns author prop" do
        expect(subject.send(:metadata_authors, metadata, {})).to eq target
      end
      context "parsely" do
        let(:metadata_parsely) do
          metadata + [
            {"name" => "parsely-author", "content" => "Anjeanette Damon"},
            {"name" => "parsely-author", "content" => "Byard Duncan"},
            {"name" => "parsely-author", "content" => "Parsely Overrides Author"}
          ]
        end
        let(:target) { ["Anjeanette Damon", "Byard Duncan", "Parsely Overrides Author"] }
        it "returns target" do
          # Test parsely prefix
          expect(subject.send(:prop_name_contents, metadata_parsely, "parsely-author")).to eq target
          expect(subject.send(:proprietary_property_content, metadata_parsely, "author")).to eq target
          expect(subject.send(:metadata_authors, metadata_parsely, {})).to eq target
        end
      end
      context "semicolons" do
        let(:metadata) { [{"content" => "Damon, Anjeanette;Duncan, Byard;Simon, Mollie", "property" => "author"}] }
        let(:target) { ["Damon, Anjeanette", "Duncan, Byard", "Simon, Mollie"] }
        it "returns author prop" do
          expect(subject.send(:metadata_authors, metadata, {})).to eq target
        end
      end
    end
    context "dc.Creator" do
      let(:metadata) { [{"content" => " ARTHUR L.  KLATSKY ", "name" => "dc.Creator"}, {"content" => " GARY D.  FRIEDMAN ", "name" => "dc.Creator"}, {"content" => " ABRAHAM B.  SIEGELAUB ", "name" => "dc.Creator"}] }
      let(:target) { ["ARTHUR L. KLATSKY", "GARY D. FRIEDMAN", "ABRAHAM B. SIEGELAUB"] }
      it "returns target" do
        target_content_values = metadata.map { |i| i["content"] }
        expect(subject.send(:prop_name_contents, metadata, "dc.creator")).to eq target_content_values
        # And test
        expect(subject.send(:metadata_authors, metadata, {})).to eq target
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

  describe "metadata_published_at" do
    context "parsely" do
      let(:metadata) { [{"name" => "parsely-pub-date", "content" => "2023-05-11T06:00:00-04:00"}] }
      let(:target) { 1683799200 }
      it "returns target" do
        expect(subject.send(:metadata_published_at, metadata, {})).to be_within(5).of(target)
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
