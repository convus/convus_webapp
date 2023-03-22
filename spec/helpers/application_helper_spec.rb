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

  describe "stylesheet_link_tag_url" do
    let(:target) { "<link rel=\"stylesheet\" href=\"http://localhost:3009/stylesheets/application.css\" />" }
    it "includes the full path" do
      expect(stylesheet_link_tag_url("application")).to eq target
    end
  end

  describe "review_display_name" do
    let(:target) { "<span class=\"less-strong\">missing url</span>" }
    it "returns target" do
      expect(review_display_name(Review.new)).to eq target
    end
    context "with review" do
      let(:target) { "<a title=\"#{citation.pretty_url}\" class=\"break-words\" href=\"#{review.submitted_url}\">texasattorneygeneral.gov/sites/default/files/images/admin/2021/Press/DC%20Statehood%20letter%20as...</a>" }
      let(:citation) { review.citation }
      let(:review) { FactoryBot.create(:review, submitted_url: "https://www.texasattorneygeneral.gov/sites/default/files/images/admin/2021/Press/DC%20Statehood%20letter%20as%20sent%20(02539672xD2C78)%20(002).pdf") }
      it "returns target" do
        expect(citation).to be_valid
        expect(citation.title).to be_blank
        expect(review_display_name(review)).to eq target
      end
    end
    context "with review with title" do
      let(:target) { "<a class=\"break-words\" href=\"https://example.com\">Somewhere</a>" }
      let(:review) { Review.new(submitted_url: "https://example.com", citation_title: "Somewhere") }
      it "returns target" do
        expect(review_display_name(review)).to eq target
      end
    end
  end

  describe "page_description" do
    it "returns nil" do
      expect(page_description).to be_nil
    end
    context "render_user_page_description?" do
      let(:user) { FactoryBot.create(:user) }
      let(:target) { "0 reviews and 0 kudos today (0 reviews and 0 kudos yesterday)" }
      it "returns target" do
        @user = user
        allow_any_instance_of(ApplicationHelper).to receive(:render_user_page_description?) { true }
        expect(page_description).to eq target
      end
    end
  end
end
