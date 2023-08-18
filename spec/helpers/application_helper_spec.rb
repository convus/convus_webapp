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
      let(:target) { "<span title=\"Agree\"><img class=\"w-4 inline-block\" src=\"/images/icons/agree_icon.svg\" /></span>" }
      it "returns -" do
        expect(agreement_display(:agree)).to eq target
      end
      context "link" do
        let(:target) { "<a title=\"Agree\" href=\"/ratings?search_agree=true&amp;search_disagree=false\"><img class=\"w-4 inline-block\" src=\"/images/icons/agree_icon.svg\" /></a>" }
        let(:bp) { {controller: "ratings", action: "index"} }
        it "returns with link" do
          expect(agreement_display("agree", link: bp)).to eq target
          expect(agreement_display(:agree, link: bp.merge(search_agree: false, search_disagree: true))).to eq target
          expect(agreement_display("agree", link: bp.merge(search_disagree: false))).to eq target
          expect(agreement_display(:agree, link: bp.merge(search_disagree: true, search_agree: false))).to eq target
          # Sam result if search_agreement == disagree
          @search_agreement = :disagree
          expect(agreement_display("agree", link: bp)).to eq target
        end
        context "matching search_agreement" do
          let(:target) { "<a title=\"Agree\" href=\"/ratings\"><img class=\"w-4 inline-block\" src=\"/images/icons/agree_icon.svg\" /></a>" }
          before { @search_agreement = :agree }
          it "returns with link with no agreement params" do
            expect(agreement_display("agree", link: bp)).to eq target_no_agreement
            expect(agreement_display(:agree, link: bp.merge(search_agree: true))).to eq target_no_agreement
          end
        end
        # context "link: true" do
        #   # TODO: need to stub current route I think? Not sure exactly what to do to make
        #   # url_for() correctly pull the current controller_name and action_name in tests
        #   it "returns with link" do
        #     expect(agreement_display(:agree, link: true)).to eq target
        #   end
        # end
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
      let(:target) { "<span title=\"High Quality\"><img class=\"w-4 inline-block\" src=\"/images/icons/quality_high_icon.svg\" /></span>" }
      it "returns -" do
        expect(quality_display(:quality_high)).to eq target
      end
    end
  end

  describe "rating_display" do
    let(:target) { "<span class=\" less-strong\">missing url</span>" }
    it "returns target" do
      rating = Rating.new
      rating.display_name = rating.calculated_display_name
      expect(rating_display(rating)).to eq target
    end
    context "with rating" do
      let(:target) { "<a class=\" break-words\" title=\"#{citation.pretty_url}\" href=\"#{rating.submitted_url}\">texasattorneygeneral.gov/sites/default/files/images/admin/2021/Press/DC%20Statehood%20letter%20as%20sent%20(02539672x...</a>" }
      let(:citation) { rating.citation }
      let(:rating) { FactoryBot.create(:rating, submitted_url: "https://www.texasattorneygeneral.gov/sites/default/files/images/admin/2021/Press/DC%20Statehood%20letter%20as%20sent%20(02539672xD2C78)%20(002).pdf") }
      it "returns target" do
        expect(citation).to be_valid
        expect(citation.title).to be_blank
        expect(rating_display(rating)).to eq target
      end
    end
    context "with rating with title" do
      let(:target) { "<a class=\" break-words\" title=\"Somewhere\" href=\"https://example.com\">Somewhere</a>" }
      let(:rating) { Rating.new(submitted_url: "https://example.com", citation_title: "Somewhere") }
      it "returns target" do
        rating.display_name = rating.calculated_display_name
        expect(rating_display(rating)).to eq target
      end
    end
  end

  describe "citation_display" do
    let(:target) { "<a class=\" break-words\" title=\"Somewhere\" href=\"https://example.com\">Somewhere</a>" }
    let(:citation) { Citation.new(url: "https://example.com", title: "Somewhere") }
    it "renders" do
      expect(citation_display(citation)).to eq target
    end
    context "passed class" do
      let(:target) { "<a class=\"otherClass break-words\" title=\"Somewhere\" href=\"https://example.com\">Somewhere</a>" }
      it "renders" do
        expect(citation_display(citation, {class: "otherClass"})).to eq target
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

  describe "active_link" do
    context "match_controller" do
      let(:request) { double("request", url: root_path) }
      before { allow(helper).to receive(:request).and_return(request) }
      it "returns the link active with match_controller if on the controller" do
        expect(active_link("Home", root_path, class: "home_header", id: "something", match_controller: true)).to eq '<a class="home_header active" id="something" href="' + root_path + '">Home</a>'
      end
    end
  end

  describe "sortable_params" do
    let(:params) { ActionController::Parameters.new(passed_params) }
    let(:passed_params) { {user: "something", per_page: 12, other: "Thing"} }
    it "returns as expected" do
      expect_hashes_to_match(sortable_params, passed_params.except(:other))
      # Verify indifferent access
      expect(sortable_params[:user]).to eq "something"
    end
    context "with array parameters" do
      let(:passed_params) { {search_topics: ["one", "another topic"], search_other: "example", render_chart: ""} }
      it "returns as expected" do
        expect_hashes_to_match(sortable_params, passed_params.except(:render_chart))
      end
    end
    context "default sort and direction" do
      let(:default_direction) { "desc" }
      let(:default_column) { "created_at" }
      let(:passed_params) { {sort: "created_at", sort_direction: "desc", search_other: "example", user: "other", render_chart: "", period: ""} }
      it "returns with default sort and direction" do
        expect_hashes_to_match(sortable_params, {search_other: "example", user: "other"})
      end
    end
  end

  describe "topic_links" do
    let(:topic1) { FactoryBot.create(:topic) }
    let(:topic2) { FactoryBot.create(:topic) }
    let(:topic3) { FactoryBot.create(:topic) }
    it "returns nil" do
      expect(topic_links(nil)).to be_nil
      expect(topic_links(Topic.none)).to be_nil
    end
    context "topics" do
      def topic_links_spanned(str)
        "<span class=\"topic-links\">#{str}</span>"
      end
      let(:target1) { "<a class=\"\" href=\"/?&search_topics[]=#{topic1.slug}\">##{topic1.name}</a>" }
      let(:target2) { target1 + " <a class=\"\" href=\"/?&search_topics[]=#{topic2.slug}\">##{topic2.name}</a>" }
      it "returns link" do
        expect(topic_links(Topic.where(id: [topic1.id]), url: root_path)).to eq target1
        expect(topic_links(Topic.where(id: [topic1.id, topic2.id]), url: root_path)).to eq target2
      end
    end
  end
end
