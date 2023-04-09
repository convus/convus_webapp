require "rails_helper"

base_url = "/admin/topics"
RSpec.describe base_url, type: :request do
  let(:topic) { FactoryBot.create(:topic) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/topics"
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get base_url
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin
    describe "index" do
      it "renders" do
        expect(topic).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topics/index")
        expect(assigns(:topics).pluck(:id)).to eq([topic.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topics/index")
        expect(assigns(:topics).pluck(:id)).to eq([topic.id])
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{topic.id}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topics/edit")
      end
    end

    describe "update" do
      let(:valid_params) { {name: "new name", previous_slug: ""} }
      let!(:og_slug) { topic.slug }
      it "updates" do
        patch "#{base_url}/#{topic.id}", params: {topic: valid_params}
        expect(flash[:success]).to be_present
        expect(topic.reload.name).to eq "new name"
        expect(topic.previous_slug).to eq og_slug
      end
      context "update with previous_slug" do
        let!(:parent) { FactoryBot.create(:topic, name: "another topic") }
        let!(:parent2) { FactoryBot.create(:topic, name: "Another") }
        let(:valid_params) { {name: topic.name, parents_string: "Another topic, one more", previous_slug: "RRRrrrrRRR"} }
        it "updates" do
          topic.update(parents_string: "Another")
          expect(topic.reload.parents_string).to eq "Another"
          patch "#{base_url}/#{topic.id}", params: {topic: valid_params}
          expect(flash[:success]).to be_present
          expect(topic.reload.slug).to eq og_slug
          expect(topic.previous_slug).to eq "rrrrrrrrrr"
          expect(topic.parents_string).to eq "another topic"
          patch "#{base_url}/#{topic.id}", params: {topic: {
            name: "Cool thing", previous_slug: "RRRrrrRRR",
            parents_string: "Another, Another TOPIC"
          }}
          expect(flash[:success]).to be_present
          expect(topic.reload.slug).to eq "cool-thing"
          expect(topic.previous_slug).to eq og_slug
          expect(topic.parents_string).to eq "Another, another topic"
        end
      end
    end
  end
end
