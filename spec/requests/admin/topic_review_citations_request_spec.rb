require "rails_helper"

base_url = "/admin/topic_review_citations"
RSpec.describe base_url, type: :request do
  let(:topic_review) { FactoryBot.create(:topic_review) }
  let(:topic_review_citation) { FactoryBot.create(:topic_review_citation, topic_review: topic_review) }
  let(:edit_path) { "#{base_url}/#{topic_review_citation.to_param}/edit" }

  describe "edit" do
    it "sets return to" do
      get edit_path
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq edit_path
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get edit_path
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin

    describe "edit" do
      it "renders" do
        get edit_path
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_review_citations/edit")
      end
      context "with topic review votes" do
        let!(:topic_review_vote) { FactoryBot.create(:topic_review_vote, topic_review: topic_review, citation: topic_review_citation.citation) }
        it "renders them" do
          expect(topic_review_citation.reload.topic_review_votes.pluck(:id)).to eq([topic_review_vote.id])
          get edit_path
          expect(response.code).to eq "200"
          expect(response).to render_template("admin/topic_review_citations/edit")
          expect(assigns(:topic_review_votes).pluck(:id)).to eq([topic_review_vote.id])
        end
      end
    end

    describe "update" do
      # it "updates" do
      #   expect(topic_review).to be_valid
      #   expect(topic_review.status).to eq "pending"
      #   patch "#{base_url}/#{topic_review.id}", params: {topic_review: valid_params}
      #   expect(flash[:success]).to be_present
      #   expect(topic_review.reload.topic_name).to eq "Example topic"
      #   expect(topic_review.status).to eq "active"
      # end
    end
  end
end
