# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "agreement_display" do
    it "returns nil" do
      expect(agreement_display("")).to be_nil
    end
    context "neutral" do
      it "returns -" do
        expect(agreement_display(:neutral)).to be_blank
      end
    end
    context "agree" do
      let(:target) { "<span title=\"Agree\"><img class=\"w-4 inline-block\" src=\"/images/agree_icon.svg\" /></span>" }
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
      it "returns -" do
        expect(quality_display("quality_med")).to be_nil
      end
    end
    context "agree" do
      let(:target) { "<span title=\"High Quality\"><img class=\"w-4 inline-block\" src=\"/images/quality_high_icon.svg\" /></span>" }
      it "returns -" do
        expect(quality_display(:quality_high)).to eq target
      end
    end
  end

  describe "rating_display_name" do
    let(:target) { "<span class=\"less-strong\">missing url</span>" }
    it "returns target" do
      rating = Rating.new
      rating.display_name = rating.calculated_display_name
      expect(rating_display_name(rating)).to eq target
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
        rating.display_name = rating.calculated_display_name
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
    end
    let(:controller_namespace) { nil }
    context "landing#about" do
      let(:controller_name) { "landing" }
      let(:action_name) { "about" }
      it "is about" do
        expect(page_title).to eq "About — Convus"
      end
      context "assigned: page_title" do
        it "uses" do
          @page_title = "Special page"
          expect(page_title).to eq "Special page"
        end
      end
      context "assigned: page_title_prefix" do
        it "uses" do
          @page_title_prefix = "Special page"
          expect(page_title).to eq "Special page — Convus"
        end
      end
      context "assigned: action_display_name" do
        it "uses" do
          @action_display_name = "Special page"
          expect(page_title).to eq "Special page — Convus"
        end
      end
      context "assigned: controller_display_name" do
        it "uses" do
          @controller_display_name = "Special page"
          expect(page_title).to eq "About - Special page — Convus"
        end
      end
    end
    context "u" do
      let(:controller_name) { "u" }
      let(:action_name) { "edit" }
      it "is users" do
        expect(page_title).to eq "Edit - Account — Convus"
      end
      context "following" do
        let(:action_name) { "following" }
        it "is following" do
          expect(page_title).to eq "Following - Account — Convus"
        end
      end
    end
    context "admin#topics#index" do
      let(:controller_namespace) { "admin" }
      let(:controller_name) { "topics" }
      let(:action_name) { "index" }
      it "is about" do
        expect(page_title).to eq "🧰 Topics"
      end
    end
  end
end
