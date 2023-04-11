require "rails_helper"

RSpec.describe UrlCleaner do
  let(:subject) { described_class }

  describe "base_domains" do
    it "returns array of domain with www and without" do
      expect(subject.base_domains("https://www.nationalrating.com/2020/09/the-cdcs-power-grab/")).to eq(["www.nationalrating.com", "nationalrating.com"])
    end
    context "non-www subdomain" do
      it "returns just one domain" do
        # Doing wikipedia domains here, because I ran into this problem with wikipedia, but we're handling wikipedia specially
        expect(subject.base_domains("https://en.coolpedia.org/wiki/John_von_Neumann")).to eq(["en.coolpedia.org"])
        expect(subject.base_domains("https://en.m.coolpedia.org/wiki/John_von_Neumann")).to eq(["en.m.coolpedia.org"])
      end
    end
    context "wikipedia" do
      it "returns wikipedia" do
        expect(subject.base_domains("https://en.wikipedia.org/wiki/John_von_Neumann")).to eq(["wikipedia.org"])
      end
    end
  end

  describe "base_domain_without_www" do
    it "gets the domain without www" do
      expect(subject.base_domain_without_www("https://www.nationalrating.com/2020/09/the-cdcs-power-grab/")).to eq("nationalrating.com")
    end
    it "includes non-www subdomain" do
      expect(subject.base_domain_without_www("https://en.coolpedia.org/wiki/John_von_Neumann")).to eq "en.coolpedia.org"
    end
    it "handles without http" do
      expect(subject.base_domain_without_www("coolpedia.org/wiki/John_von_Neumann")).to eq "coolpedia.org"
    end
    context "wikipedia" do
      it "returns wikipedia" do
        expect(subject.base_domain_without_www("https://en.wikipedia.org/wiki/John_von_Neumann")).to eq "wikipedia.org"
        expect(subject.base_domain_without_www("https://en.m.wikipedia.org/wiki/John_von_Neumann")).to eq "wikipedia.org"
        expect(subject.base_domains("https://en.m.wikipedia.org")).to eq(["wikipedia.org"])
      end
      it "doesn't shit the bed on non-percent encoded URLs" do
        expect(subject.base_domain_without_www("https://en.m.wikipedia.org/wiki/Glass–Steagall_legislation")).to eq "wikipedia.org"
      end
    end
  end

  describe "without_base_domain" do
    it "returns the string if it doesn't seem like a url" do
      expect(subject.without_base_domain("This isn't a URL")).to eq "This isn't a URL"
    end
    it "returns without the base domain" do
      expect(subject.without_base_domain("https://www.nationalrating.com/2020/09/the-cdcs-power-grab/")).to eq "2020/09/the-cdcs-power-grab"
    end
    it "returns the domain if there is no query" do
      expect(subject.without_base_domain("https://bikeindex.org")).to eq "bikeindex.org"
      expect(subject.without_base_domain("http://example.com")).to eq "example.com"
    end
  end

  describe "pretty_url" do
    it "returns without the protocol and trailing stuff" do
      expect(subject.pretty_url("https://en.wikipedia.org/wiki/John_von_Neumann/")).to eq "en.wikipedia.org/wiki/John_von_Neumann"
      expect(subject.pretty_url("http://en.wikipedia.org/wiki/John_von_Neumann?")).to eq "en.wikipedia.org/wiki/John_von_Neumann"
      expect(subject.pretty_url("http://en.wikipedia.org/wiki/John_von_Neumann/?")).to eq "en.wikipedia.org/wiki/John_von_Neumann"
    end
    it "returns without UTM parameters" do
      target = "nationalrating.com/2020/09/bring-back-the-bison/?somethingimportant=33333utm"
      expect(subject.pretty_url(" www.nationalrating.com/2020/09/bring-back-the-bison/?utm_source=recirc-desktop&utm_medium=article&UTM_CAMPAIGN=river&somethingimportant=33333utm&utm_content=top-bar-latest&utm_term=second")).to eq target
    end
  end

  describe "without_utm_or_ignored_queries" do
    it "returns nil" do
      expect(subject.without_utm_or_ignored_queries("   \n")).to eq(nil)
    end
    it "returns without UTM parameters" do
      target = "https://www.nationalrating.com/2020/09/bring-back-the-bison/?somethingimportant=33333utm"
      expect(subject.without_utm_or_ignored_queries("https://www.nationalrating.com/2020/09/bring-back-the-bison/?utm_source=recirc-desktop&utm_medium=article&UTM_CAMPAIGN=river&somethingimportant=33333utm&utm_content=top-bar-latest&utm_term=second")).to eq target
    end
    it "returns without anchor" do
      target = "https://en.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true"
      expect(subject.without_utm_or_ignored_queries("https://en.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true#cite_note-10")).to eq target + "#cite_note-10"
      expect(subject.normalized_url("https://en.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true#cite_note-10")).to eq target
    end
    it "skips the ignored queries" do
      url = "https://www.nytimes.com/interactive/2023/03/10/climate/buildings-carbon-dioxide-emissions-climate.html?action=click&algo=bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1&alpha=0.05&block=more_in_recirc&fellback=false&imp_id=375080313&impression_id=fe98acf1-c480-11ed-a679-93706db9db3a&index=1&pgtype=Article&pool=more_in_pools%2Fclimate&region=footer&req_id=201785425&surface=eos-more-in&variant=0_bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1&leadSource=fffff&REF=cccc"
      target = "https://www.nytimes.com/interactive/2023/03/10/climate/buildings-carbon-dioxide-emissions-climate.html?action=click&algo=bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1&alpha=0.05&block=more_in_recirc&fellback=false&imp_id=375080313&index=1&pgtype=Article&pool=more_in_pools%2Fclimate&region=footer&surface=eos-more-in&variant=0_bandit-all-surfaces-time-cutoff-30_impression_cut_3_filter_new_arm_5_1"
      expect(subject.without_utm_or_ignored_queries(url)).to eq target
      expect(subject.normalized_url(url)).to eq target
    end
  end

  describe "normalized_url" do
    it "returns without anchor, utm and mobile" do
      og = "https://en.m.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true#cite_note-10"
      target = "https://en.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true"
      expect(subject.without_anchor(og)).to eq "https://en.m.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true"
      expect(subject.normalized_url(og.gsub("https://en.", ""))).to eq "http://en.wikipedia.org/wiki/Rationale_for_the_Iraq_War?somethingimportant=true"
      expect(subject.normalized_url(og)).to eq target
    end
    it "doesn't remove non mobile m subdomains" do
      expect(subject.normalized_url("https://mm.wikipedia.org/wiki/Illegal_number")).to eq "https://mm.wikipedia.org/wiki/Illegal_number"
      expect(subject.normalized_url("https://mm.m.wikipedia.org/wiki/Illegal_number")).to eq "https://mm.wikipedia.org/wiki/Illegal_number"
      expect(subject.normalized_url("mm.wikipedia.org/wiki/Illegal_number")).to eq "http://mm.wikipedia.org/wiki/Illegal_number"
    end
    it "works on spanish wikipedia too" do
      og = "https://es.m.wikipedia.org/wiki/Illegal_number?somethingimportant=true#cite_note-10&utm_source=recirc-desktop&utm_medium=article"
      expect(subject.normalized_url(og)).to eq "https://es.wikipedia.org/wiki/Illegal_number?somethingimportant=true"
      expect(subject.normalized_url(og.gsub("https://", "").upcase)).to eq "http://ES.wikipedia.org/WIKI/ILLEGAL_NUMBER?SOMETHINGIMPORTANT=TRUE"
    end
  end

  describe "with_http" do
    it "returns with http" do
      expect(subject.with_http("example.com")).to eq "http://example.com"
      expect(subject.with_http("http://example.com")).to eq "http://example.com"
      expect(subject.with_http(subject.without_utm_or_ignored_queries("example.com"))).to eq "http://example.com"
    end
    it "doesn't modify https" do
      expect(subject.with_http("https://www.nationalrating.com/2020/09/?")).to eq "https://www.nationalrating.com/2020/09/?"
    end
    it "non-urls returns without http" do
      expect(subject.with_http("whatever")).to eq "whatever"
    end
  end

  describe "looks_like_url?" do
    it "is true for url" do
      expect(subject.looks_like_url?("https://www.nationalrating.com/2020/09/?")).to be_truthy
    end
    it "is true for url without protocol" do
      expect(subject.looks_like_url?("www.nationalrating.com/2020/09/?")).to be_truthy
      expect(subject.looks_like_url?("www.nationalrating.com")).to be_truthy
    end
    it "is false for sentence" do
      expect(subject.looks_like_url?("quick brown fox")).to be_falsey
    end
    it "is false for blank" do
      expect(subject.looks_like_url?(" ")).to be_falsey
    end
  end
end
