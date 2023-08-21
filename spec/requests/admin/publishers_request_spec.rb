require "rails_helper"

base_url = "/admin/publishers"
RSpec.describe base_url, type: :request do
  let(:publisher) { Publisher.find_or_create_for_domain("99percentinvisible.org") }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/publishers"
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
        expect(publisher).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/publishers/index")
        expect(assigns(:publishers).pluck(:id)).to eq([publisher.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/publishers/index")
        expect(assigns(:publishers).pluck(:id)).to eq([publisher.id])
      end
    end

    describe "show" do
      it "redirects" do
        get "#{base_url}/#{publisher.id}"
        expect(response).to redirect_to edit_admin_publisher_path(publisher)
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{publisher.id}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/publishers/edit")
      end
    end

    describe "update" do
      let(:valid_params) { {name: "99 Percent Invisible", remove_query: true, base_word_count: "30"} }
      it "updates" do
        expect(publisher.reload.name).to eq "99percentinvisible.org"
        expect(publisher.remove_query).to be_falsey
        expect(publisher.base_word_count).to eq 100
        patch "#{base_url}/#{publisher.id}", params: {publisher: valid_params}
        expect(flash[:success]).to be_present
        expect(publisher.reload.name).to eq valid_params[:name]
        expect(publisher.remove_query).to be_truthy
        expect(publisher.base_word_count).to eq 30
        # And again
        patch "#{base_url}/#{publisher.id}", params: {
          publisher: {name: "Whoop", remove_query: "0"}
        }
        expect(flash[:success]).to be_present
        expect(publisher.reload.name).to eq "Whoop"
        expect(publisher.remove_query).to be_falsey
        expect(publisher.base_word_count).to eq 30
      end
      context "rating present" do
        let(:url) { "http://99percentinvisible.org/episode/a-whale-oiled-machine?f=z&c=d&b=3" }
        let(:rating) { FactoryBot.create(:rating, submitted_url: url.gsub("https://", "")) }
        let(:citation) { rating.citation }
        let(:publisher) { citation.publisher }
        it "updates and enqueues reconciliation" do
          expect(citation.reload.url).to eq url
          expect(rating.reload.publisher&.id).to eq publisher.id
          patch "#{base_url}/#{publisher.id}", params: {publisher: valid_params}
          expect(flash[:success]).to be_present
          expect(publisher.reload.name).to eq "99 Percent Invisible"
          expect(publisher.remove_query).to be_truthy
          expect(citation.reload.url).to eq "http://99percentinvisible.org/episode/a-whale-oiled-machine"
        end
      end
    end
  end
end
