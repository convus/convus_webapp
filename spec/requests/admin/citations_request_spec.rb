require "rails_helper"

base_url = "/admin/citations"
RSpec.describe base_url, type: :request do
  let(:citation) { FactoryBot.create(:citation) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/citations"
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
        expect(citation).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/citations/index")
        expect(assigns(:citations).pluck(:id)).to eq([citation.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/citations/index")
        expect(assigns(:citations).pluck(:id)).to eq([citation.id])
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{citation.id}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/citations/edit")
      end
    end

    describe "update" do
      let!(:topic) { FactoryBot.create(:topic, name: "Something") }
      let(:valid_params) { {title: "new title", topics_string: "something"} }
      it "updates" do
        expect(citation.reload.topics.pluck(:id)).to eq([])
        patch "#{base_url}/#{citation.id}", params: {citation: valid_params}
        expect(flash[:success]).to be_present
        expect(citation.reload.title).to eq "new title"
        expect(citation.topics.pluck(:id)).to eq([topic.id])
      end
    end
  end
end
