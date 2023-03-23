require "rails_helper"

base_url = "/admin/topics"
RSpec.describe base_url, type: :request do
  let(:topic) { FactoryBot.create(:topic) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_registration_path
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
      let(:valid_params) { {name: "new name"} }
      it "updates" do
        og_name = topic.name
        patch "#{base_url}/#{topic.id}", params: {topic: valid_params}
        expect(flash[:success]).to be_present
        expect(topic.reload.name).to eq "new name"
        expect(topic.previous_name).to eq og_name
      end
    end
  end
end
