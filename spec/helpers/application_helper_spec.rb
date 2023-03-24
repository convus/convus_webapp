# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "agreement_display" do
    it "returns nil" do
      expect(agreement_display("")).to be_nil
    end
    context "neutral" do
      let(:target) { "<span class=\"less-strong\">-</span>" }
      it "returns -" do
        expect(agreement_display(:neutral)).to eq target
      end
    end
    context "agree" do
      let(:target) { "<span title=\"agree\">a<span class=\"hidden sm:inline\">gree</span></span>" }
      it "returns -" do
        expect(agreement_display(:agree)).to eq target
      end
    end
  end

  describe "quality_display" do
    it "returns nil" do
      expect(quality_display("")).to be_nil
    end
    context "neutral" do
      let(:target) { "<span class=\"less-strong\">-</span>" }
      it "returns -" do
        expect(quality_display("quality_med")).to eq target
      end
    end
    context "agree" do
      let(:target) { "<span title=\"high\">h<span class=\"hidden sm:inline\">igh</span></span>" }
      it "returns -" do
        expect(quality_display(:quality_high)).to eq target
      end
    end
  end

  describe "rating_display_name" do
    let(:target) { "<span class=\"less-strong\">missing url</span>" }
    it "returns target" do
      expect(rating_display_name(Rating.new)).to eq target
    end
    context "with rating" do
      let(:target) { "<a title=\"#{citation.pretty_url}\" class=\"break-words\" href=\"#{rating.submitted_url}\">texasattorneygeneral.gov/sites/default/files/images/admin/2021/Press/DC%20Statehood%20letter%20as...</a>" }
      let(:citation) { rating.citation }
      let(:rating) { FactoryBot.create(:rating, submitted_url: "https://www.texasattorneygeneral.gov/sites/default/files/images/admin/2021/Press/DC%20Statehood%20letter%20as%20sent%20(02539672xD2C78)%20(002).pdf") }
      it "returns target" do
        expect(citation).to be_valid
        expect(citation.title).to be_blank
        expect(rating_display_name(rating)).to eq target
      end
    end
    context "with rating with title" do
      let(:target) { "<a class=\"break-words\" href=\"https://example.com\">Somewhere</a>" }
      let(:rating) { Rating.new(submitted_url: "https://example.com", citation_title: "Somewhere") }
      it "returns target" do
        expect(rating_display_name(rating)).to eq target
      end
    end
  end

  describe "page_description" do
    it "returns nil" do
      expect(page_description).to be_nil
    end
    context "render_user_page_description?" do
      let(:user) { FactoryBot.create(:user) }
      let(:target) { "0 ratings and 0 kudos today (0 ratings and 0 kudos yesterday)" }
      it "returns target" do
        @user = user
        allow_any_instance_of(ApplicationHelper).to receive(:render_user_page_description?) { true }
        expect(page_description).to eq target
      end
    end
  end

  describe "page_title" do
    before do
      allow(view).to receive(:controller_name) { controller_name }
      allow(view).to receive(:action_name) { action_name }
      # This method is defined in application controller, not sure how to stub right now
      # allow(view).to receive(:controller_namespace) { controller_namespace }
    end
    let(:controller_namespace) { nil }
    context "landing#about" do
      let(:controller_name) { "landing" }
      let(:action_name) { "about" }
      it "is about" do
        expect(page_title).to eq "Convus About"
      end
    end
  end
end
