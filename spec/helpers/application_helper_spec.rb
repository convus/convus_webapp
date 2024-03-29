# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
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
      let(:target1) { "<a class=\"\" href=\"/?search_topics[]=#{topic1.slug}\">##{topic1.name}</a>" }
      let(:target2) { target1 + " <a class=\"\" href=\"/?search_topics[]=#{topic2.slug}\">##{topic2.name}</a>" }
      let(:target3) { "<a class=\"\" href=\"/admin/topics/#{topic1.slug}\">##{topic1.name}</a>" }
      let(:target4) { "<a class=\"\" href=\"/admin/citations?search_topics[]=#{topic1.slug}\">##{topic1.name}</a>" }
      let(:target5) { "<a class=\"\" href=\"/admin?user=test&search_topics[]=#{topic1.slug}\">##{topic1.name}</a>" }
      it "returns link" do
        expect(topic_links(Topic.where(id: [topic1.id]), url: root_path)).to eq target1
        expect(topic_links(Topic.where(id: [topic1.id, topic2.id]), url: root_path)).to eq target2
        expect(topic_links(Topic.where(id: [topic1.id]), url: "/admin/topics/")).to eq target3
        expect(topic_links(Topic.where(id: [topic1.id]), url: {controller: "admin/citations", action: "index"})).to eq target4
        # NOTE: Drops the /ratings, because root_to
        expect(topic_links(Topic.where(id: [topic1.id]), url: {controller: "admin/ratings", action: "index", user: "test"})).to eq target5
      end
    end
  end
end
