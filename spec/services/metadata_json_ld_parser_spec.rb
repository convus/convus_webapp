require "rails_helper"

RSpec.describe MetadataJsonLdParser do
  let(:subject) { described_class }
  describe "parse" do
    let(:citation_metadata_raw) { MetadataParser.parse_string(citation_metadata_str) }
    context "Just JSON-LD passed" do
      let(:citation_metadata_str) { '[{"json_ld":["{\"@context\":\"https://schema.org\",\"@graph\":[{\"@type\":\"WebPage\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\",\"url\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\",\"name\":\"Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy - 80,000 Hours\",\"isPartOf\":{\"@id\":\"https://80000hours.org/#website\"},\"primaryImageOfPage\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\"},\"image\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\"},\"thumbnailUrl\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"datePublished\":\"2022-02-02T22:43:27+00:00\",\"dateModified\":\"2022-12-14T12:13:15+00:00\",\"breadcrumb\":{\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb\"},\"inLanguage\":\"en-US\",\"potentialAction\":[{\"@type\":\"ReadAction\",\"target\":[\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/\"]}]},{\"@type\":\"ImageObject\",\"inLanguage\":\"en-US\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage\",\"url\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"contentUrl\":\"https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png\",\"width\":2364,\"height\":1183},{\"@type\":\"BreadcrumbList\",\"@id\":\"https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb\",\"itemListElement\":[{\"@type\":\"ListItem\",\"position\":1,\"name\":\"Home\",\"item\":\"https://80000hours.org/\"},{\"@type\":\"ListItem\",\"position\":2,\"name\":\"Podcast\",\"item\":\"https://80000hours.org/podcast/\"},{\"@type\":\"ListItem\",\"position\":3,\"name\":\"All episodes\",\"item\":\"https://80000hours.org/podcast/episodes/\"},{\"@type\":\"ListItem\",\"position\":4,\"name\":\"Audrey Tang on what we can learn from Taiwan’s experiments with how to do&nbsp;democracy\"}]},{\"@type\":\"WebSite\",\"@id\":\"https://80000hours.org/#website\",\"url\":\"https://80000hours.org/\",\"name\":\"80,000 Hours\",\"description\":\"\",\"publisher\":{\"@id\":\"https://80000hours.org/#organization\"},\"potentialAction\":[{\"@type\":\"SearchAction\",\"target\":{\"@type\":\"EntryPoint\",\"urlTemplate\":\"https://80000hours.org/?s={search_term_string}\"},\"query-input\":\"required name=search_term_string\"}],\"inLanguage\":\"en-US\"},{\"@type\":\"Organization\",\"@id\":\"https://80000hours.org/#organization\",\"name\":\"80,000 Hours\",\"url\":\"https://80000hours.org/\",\"logo\":{\"@type\":\"ImageObject\",\"inLanguage\":\"en-US\",\"@id\":\"https://80000hours.org/#/schema/logo/image/\",\"url\":\"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png\",\"contentUrl\":\"https://80000hours.org/wp-content/uploads/2018/07/og-logo_0.png\",\"width\":1500,\"height\":785,\"caption\":\"80,000 Hours\"},\"image\":{\"@id\":\"https://80000hours.org/#/schema/logo/image/\"},\"sameAs\":[\"https://www.facebook.com/80000Hours\",\"https://twitter.com/80000hours\",\"https://www.youtube.com/user/eightythousandhours\"]}]}"]}]' }
      let(:target) do
        {
          "@type" => "WebPage",
          "@id" => "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/",
          "url" => "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/",
          "name" => "Audrey Tang on what we can learn from Taiwan’s experiments with how to do democracy - 80,000 Hours",
          "isPartOf" => {"@id" => "https://80000hours.org/#website"},
          "primaryImageOfPage" => {"@id" => "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage"},
          "image" => {"@id" => "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#primaryimage"},
          "thumbnailUrl" => "https://80000hours.org/wp-content/uploads/2022/02/audrey-banner-2.png",
          "datePublished" => "2022-02-02T22:43:27+00:00",
          "dateModified" => "2022-12-14T12:13:15+00:00",
          "breadcrumb" => {"@id" => "https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/#breadcrumb"},
          "inLanguage" => "en-US",
          "potentialAction" => [{"@type" => "ReadAction", "target" => ["https://80000hours.org/podcast/episodes/audrey-tang-what-we-can-learn-from-taiwan/"]}],
          "publisher" => "80,000 Hours"
        }
      end
      it "returns target" do
        content_hash = subject.content_hash(citation_metadata_raw)
        expect(content_hash.keys).to eq(%w[WebPage ImageObject BreadcrumbList WebSite Organization])

        expect(subject.parse(citation_metadata_raw, content_hash)).to eq target
      end
    end
    context "pro_publica" do
      let(:citation_metadata_str) { File.read(Rails.root.join("spec", "fixtures", "metadata_propublica.json")) }
      let(:target) do
        {"url" => "https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses",
         "name" => "The Ugly Truth Behind “We Buy Ugly Houses”",
         "@type" => "NewsArticle",
         "image" => {"url" => "https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87", "@type" => "ImageObject"},
         "author" => {"@id" => "https://www.propublica.org#identity"},
         "creator" => ["Anjeanette Damon", "Byard Duncan", "Mollie Simon"],
         "headline" => "The Ugly Truth Behind “We Buy Ugly Houses”",
         "publisher" => "ProPublica",
         "inLanguage" => "en-us",
         "description" => "HomeVestors of America, the self-proclaimed “largest homebuyer in the U.S.,” trains its nearly 1,150 franchisees to zero in on homeowners’ desperation.",
         "dateModified" => "2023-05-10T18:07:16-04:00",
         "thumbnailUrl" => "https://img.assets-d.propublica.org/v5/images/20230511-homevesters-main-1_2023-05-10-215352_turq.jpg?crop=focalpoint\\u0026fit=crop\\u0026fp-x=0.5\\u0026fp-y=0.5\\u0026h=630\\u0026imgixProfile=propublicaAssetsV5\\u0026q=90\\u0026w=1200\\u0026s=2343fad4117e06075ece744da123cb87",
         "copyrightYear" => "2023",
         "datePublished" => "2023-05-11T06:00:00-04:00",
         "copyrightHolder" => {"@id" => "https://www.propublica.org#identity"},
         "mainEntityOfPage" => "https://www.propublica.org/article/ugly-truth-behind-we-buy-ugly-houses"}
      end
      it "returns target" do
        content_hash = subject.content_hash(citation_metadata_raw)
        expect(content_hash.keys).to eq(%w[NewsArticle NewsMediaOrganization Organization BreadcrumbList])

        expect(subject.parse(citation_metadata_raw, content_hash)).to eq target
      end
    end
    context "grist" do
      let(:citation_metadata_str) { '[{"name":"p:domain_verify","content":"c293daabda398bd8ceee45abea0b3201"},{"name":"description","content":"The US offers farm subsidies pretty heavily for some crops, but what began as a temporary measure gradually became more permanent."},{"content":"en_US","property":"og:locale"},{"content":"article","property":"og:type"},{"content":"Our crazy farm subsidies, explained","property":"og:title"},{"content":"The US offers farm subsidies pretty heavily for some crops, but what began as a temporary measure gradually became more permanent.","property":"og:description"},{"content":"https://grist.org/food/our-crazy-farm-subsidies-explained/","property":"og:url"},{"content":"Grist","property":"og:site_name"},{"content":"2015-04-20T09:00:23+00:00","property":"article:published_time"},{"content":"2021-09-21T16:51:12+00:00","property":"article:modified_time"},{"content":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg","property":"og:image"},{"content":"3200","property":"og:image:width"},{"content":"1600","property":"og:image:height"},{"content":"image/jpeg","property":"og:image:type"},{"name":"author","content":"Amelia Urry"},{"name":"twitter:card","content":"summary_large_image"},{"name":"twitter:title","content":"Our crazy farm subsidies, explained"},{"name":"twitter:label1","content":"Written by"},{"name":"twitter:data1","content":"Amelia Urry"},{"name":"twitter:label2","content":"Est. reading time"},{"name":"twitter:data2","content":"6 minutes"},{"content":"https://grist.org/food/our-crazy-farm-subsidies-explained/?ia_markup=1","property":"ia:markup_url"},{"name":"generator","content":"Site Kit by Google 1.99.0"},{"word_count":1685},{"json_ld":[{"@graph":[{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/#article","@type":"Article","image":{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/#primaryimage"},"author":[{"@id":"https://grist.org/#/schema/person/image/e78967fd0836f51884894d81e39d891a"}],"headline":"Our crazy farm subsidies, explained","isPartOf":{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/"},"publisher":{"@id":"https://grist.org/#organization"},"wordCount":1191,"inLanguage":"en-US","dateModified":"2021-09-21T16:51:12+00:00","thumbnailUrl":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg","datePublished":"2015-04-20T09:00:23+00:00","articleSection":["Technology"],"mainEntityOfPage":{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/"}},{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/","url":"https://grist.org/food/our-crazy-farm-subsidies-explained/","name":"Here\'s how the crazy way the US provides farm subsidies works","@type":"WebPage","image":{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/#primaryimage"},"author":[{"@id":"https://grist.org/#/schema/person/245b363c73aa4d1759144c46e2ecd3eb"}],"isPartOf":{"@id":"https://grist.org/#website"},"inLanguage":"en-US","description":"The US offers farm subsidies pretty heavily for some crops, but what began as a temporary measure gradually became more permanent.","dateModified":"2021-09-21T16:51:12+00:00","thumbnailUrl":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg","datePublished":"2015-04-20T09:00:23+00:00","potentialAction":[{"@type":"ReadAction","target":["https://grist.org/food/our-crazy-farm-subsidies-explained/"]}],"primaryImageOfPage":{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/#primaryimage"}},{"@id":"https://grist.org/food/our-crazy-farm-subsidies-explained/#primaryimage","url":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg","@type":"ImageObject","width":3200,"height":1600,"contentUrl":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg","inLanguage":"en-US"},{"@id":"https://grist.org/#website","url":"https://grist.org/","name":"Grist","@type":"WebSite","publisher":{"@id":"https://grist.org/#organization"},"inLanguage":"en-US","description":"Climate. Justice. Solutions.","potentialAction":[{"@type":"SearchAction","target":{"@type":"EntryPoint","urlTemplate":"https://grist.org/?s={search_term_string}"},"query-input":"required name=search_term_string"}]},{"@id":"https://grist.org/#organization","url":"https://grist.org/","logo":{"@id":"https://grist.org/#/schema/logo/image/","url":"https://grist.org/wp-content/uploads/2021/03/Grist-Favicon.png","@type":"ImageObject","width":512,"height":512,"caption":"Grist","contentUrl":"https://grist.org/wp-content/uploads/2021/03/Grist-Favicon.png","inLanguage":"en-US"},"name":"Grist","@type":"Organization","image":{"@id":"https://grist.org/#/schema/logo/image/"}},[{"@id":"https://grist.org/#/schema/person/245b363c73aa4d1759144c46e2ecd3eb","name":"Amelia Urry","@type":"Person"}],{"@id":"https://grist.org/#/schema/person/image/e78967fd0836f51884894d81e39d891a","url":"https://grist.org/author/amelia-urry/","name":"Amelia Urry","@type":"Person","description":"Amelia Urry is Grist\'s associate editor of science and technology, and self-appointed poet-in-residence. Follow her on Twitter."}],"@context":"https://schema.org"},{"url":"http://grist.org/food/our-crazy-farm-subsidies-explained/","@type":"NewsArticle","image":{"url":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg","@type":"ImageObject"},"author":[{"name":"Amelia Urry","@type":"Person"}],"creator":["Amelia Urry"],"@context":"https://schema.org","headline":"Our crazy farm subsidies, explained","keywords":["technology","farm size matters"],"publisher":{"logo":"https://grist.org/wp-content/uploads/2022/05/grist-logo.png","name":"Grist","@type":"Organization"},"dateCreated":"2015-04-20T09:00:23Z","dateModified":"2021-09-21T16:51:12Z","thumbnailUrl":"https://grist.org/wp-content/uploads/2015/04/header3merged.jpg?w=1200","datePublished":"2015-04-20T09:00:23Z","articleSection":"Technology","mainEntityOfPage":{"@id":"http://grist.org/food/our-crazy-farm-subsidies-explained/","@type":"WebPage"}}]}]' }
      let(:target) do
        {"@id" => "https://grist.org/food/our-crazy-farm-subsidies-explained/",
         "url" => "http://grist.org/food/our-crazy-farm-subsidies-explained/",
         "name" => "Here's how the crazy way the US provides farm subsidies works",
         "@type" => ["NewsArticle", "WebPage"],
         "image" => {"url" => "https://grist.org/wp-content/uploads/2015/04/header3merged.jpg", "@type" => "ImageObject"},
         "author" => [{"name" => "Amelia Urry", "@type" => "Person"}],
         "isPartOf" => {"@id" => "https://grist.org/#website"},
         "inLanguage" => "en-US",
         "description" => "The US offers farm subsidies pretty heavily for some crops, but what began as a temporary measure gradually became more permanent.",
         "dateModified" => "2021-09-21T16:51:12Z",
         "thumbnailUrl" => "https://grist.org/wp-content/uploads/2015/04/header3merged.jpg?w=1200",
         "datePublished" => "2015-04-20T09:00:23Z",
         "potentialAction" => [{"@type" => "ReadAction", "target" => ["https://grist.org/food/our-crazy-farm-subsidies-explained/"]}],
         "primaryImageOfPage" => {"@id" => "https://grist.org/food/our-crazy-farm-subsidies-explained/#primaryimage"},
         "creator" => ["Amelia Urry"],
         "@context" => "https://schema.org",
         "headline" => "Our crazy farm subsidies, explained",
         "keywords" => ["technology", "farm size matters"],
         "publisher" => {"logo" => "https://grist.org/wp-content/uploads/2022/05/grist-logo.png", "name" => "Grist", "@type" => "Organization"},
         "dateCreated" => "2015-04-20T09:00:23Z",
         "articleSection" => "Technology",
         "mainEntityOfPage" => {"@id" => "http://grist.org/food/our-crazy-farm-subsidies-explained/", "@type" => "WebPage"}}
      end
      it "returns target" do
        content_hash = subject.content_hash(citation_metadata_raw)
        expect(content_hash.keys).to eq(%w[NewsArticle Article WebPage ImageObject WebSite Organization Person])

        expect(subject.parse(citation_metadata_raw, content_hash)).to eq target
      end
    end
    context "blank" do
      let(:citation_metadata_str) { '[{"content":"Some Title","property":"og:title"}]' }
      it "returns nil" do
        expect(subject.parse(citation_metadata_raw)).to be_nil
      end
    end
  end

  describe "content_hash" do
    let(:rating_metadata) { [{"json_ld" => values}] }
    let(:values) { [{"@type" => "WebSite", "url" => "https://www.example.com"}] }
    it "returns json_ld" do
      expect(subject.send(:content, rating_metadata)).to eq(values)
      expect(subject.content_hash(rating_metadata)).to eq({"WebSite" => values.first})

      expect(subject.parse(rating_metadata)).to eq(values.first.merge("publisher" => nil))
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
          if MetadataJsonLdParser::RAISE_ON_DUPE
            expect { subject.content_hash(rating_metadata) }.to raise_error(/different/i)
          else
            expect(subject.content_hash(rating_metadata)).to eq({"WebSite" => values.first})
          end
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

        expect(subject.parse(rating_metadata)).to eq target["NewsArticle"].merge("publisher" => nil)
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

        expect(subject.parse(rating_metadata)).to eq graph.first.merge("publisher" => "EXAMPLE")
      end
    end
  end

  describe "publisher_name" do
    let(:content_hash) { {"WebPage" => {"@type" => "WebPage", "name" => "EXAMPLE"}} }
    it "returns nil" do
      expect(subject.send(:publisher_name, nil, content_hash)).to be_nil
    end
    context "organization" do
      let(:content_hash) do
        {
          "WebSite" => {"@type" => "WebSite", "url" => "https://example.org/", :name => "Maybe this"},
          "Organization" => {"@type" => "Organization", "name" => "EXAMPLE"}
        }
      end
      it "returns organization name, " do
        expect(subject.send(:publisher_name, nil, content_hash)).to eq("EXAMPLE")
      end
    end
  end
end
