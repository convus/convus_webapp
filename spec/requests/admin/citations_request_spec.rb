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

    describe "show" do
      it "redirects" do
        get "#{base_url}/#{citation.id}"
        expect(response).to redirect_to edit_admin_citation_path(citation)
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
        expect(citation.manually_updated_attributes).to eq(["title", "topics"])
        patch "#{base_url}/#{citation.id}", params: {
          citation: {title: "Whoop", topics_string: "Other"}
        }
        expect(flash[:success]).to be_present
        expect(citation.reload.title).to eq "Whoop"
        expect(citation.topics.pluck(:id)).to eq([])
        expect(citation.manually_updated_attributes).to eq(["title"])
      end
      context "topics updating" do
        let!(:topic2) { FactoryBot.create(:topic, name: "Another Thing") }
        let(:metadata) { {topics_string: topic2.name} }
        let(:rating) do
          FactoryBot.create(:rating, :with_topic,
            submitted_url: citation.url,
            topics_text: "SOMETHING",
            metadata_at: Time.now,
            citation_metadata: {"raw" => [metadata], "attrs" => metadata})
        end
        it "actually updates the topics" do
          expect(rating.reload.topics.pluck(:id)).to eq([topic.id])
          expect(rating.metadata_attributes).to eq metadata
          ReconcileRatingTopicsJob.new.perform(rating.id)
          UpdateCitationMetadataFromRatingsJob.drain # enqueued from ReconileRatingTopicsJob
          # It's Assigned from the metadata
          expect(citation.reload.topics.pluck(:id)).to eq([topic2.id])
          Sidekiq::Worker.clear_all
          Sidekiq::Testing.inline! do
            patch "#{base_url}/#{citation.id}", params: {
              citation: {topics_string: "something, Another thiNG   "}
            }
            expect(flash[:success]).to be_present
            # We want to reconcile the topics, so that all the ratings have the same topics.
            # THIS IS NOT THE OPTIMAL SOLUTION
            expect(rating.reload.topics.pluck(:id)).to eq([topic.id, topic2.id])
            citation.reload
            expect(citation.manually_updated_attributes).to eq(["topics"])
            expect(citation.manually_updated_at).to be_within(1).of Time.now
            expect(citation.topics.pluck(:id)).to eq([topic.id, topic2.id])
            # Remove the topics string, make sure the topics are set from rating metada
            patch "#{base_url}/#{citation.id}", params: {
              citation: {topics_string: "\n   "}
            }
            expect(flash[:success]).to be_present
            # Rating topics aren't currently updated
            # expect(rating.reload.topics.pluck(:id)).to eq([topic2.id])
            citation.reload
            expect(citation.manually_updated_attributes).to eq([])
            expect(citation.manually_updated_at).to be_blank
            expect(citation.topics.pluck(:id)).to eq([topic2.id])
          end
        end
      end
      context "metadata" do
        let(:published_at) { Time.current - 1.week }
        let(:updated_at) { Time.current - 1.day }
        let(:metadata_params) do
          {
            title: "something",
            # topics_string: "",
            authors_str: "george\nSally, Post\n\nAlix",
            timezone: "Europe/Kyiv",
            published_at_in_zone: form_formatted_time(published_at),
            published_updated_at_in_zone: form_formatted_time(updated_at),
            description: "new description",
            canonical_url: "https://something.com",
            word_count: "2222",
            paywall: "1",
            citation_text: "some text here"
          }
        end
        let!(:rating) { FactoryBot.create(:rating, submitted_url: citation.url, citation_title: "Titled Here") }
        it "updates" do
          expect(citation.reload.title).to eq "Titled Here"
          expect(rating.reload.display_name).to eq "Titled Here"
          patch "#{base_url}/#{citation.id}", params: {citation: metadata_params}
          expect(flash[:success]).to be_present
          citation.reload
          matching_params = metadata_params.except(:authors_str, :published_at_in_zone, :published_updated_at_in_zone)
          expect_attrs_to_match_hash(citation, metadata_params.except(:authors_str, :published_at_in_zone, :published_updated_at_in_zone))
          expect(citation.authors).to eq(["george", "Sally, Post", "Alix"])
          expect(citation.published_at).to be_within(60).of published_at
          expect(citation.published_updated_at).to be_within(60).of updated_at
          # Make sure rating is updated!
          expect(rating.reload.display_name).to eq "something"
          target_keys = matching_params.keys.map(&:to_s) + %w[published_at published_updated_at authors]
          expect(citation.manually_updated_attributes).to eq(target_keys.sort - ["timezone"])
        end
      end
      context "update_citation_metadata_from_ratings" do
        it "enqueues the job" do
          Sidekiq::Worker.clear_all
          expect_any_instance_of(UpdateCitationMetadataFromRatingsJob).to receive(:perform) { true }
          patch "#{base_url}/#{citation.id}", params: {
            update_citation_metadata_from_ratings: true
          }
          expect(flash[:success]).to be_present
        end
      end
      context "rating present" do
        let!(:rating) { FactoryBot.create(:rating, submitted_url: citation.url) }
        it "updates and enqueues reconciliation" do
          expect(rating.reload.topics.pluck(:id)).to eq([])
          expect(citation.reload.topics.pluck(:id)).to eq([])
          Sidekiq::Worker.clear_all
          patch "#{base_url}/#{citation.id}", params: {citation: valid_params}
          expect(flash[:success]).to be_present
          expect(citation.reload.title).to eq "new title"
          expect(citation.topics.pluck(:id)).to eq([topic.id])
          expect(UpdateCitationMetadataFromRatingsJob.jobs.count).to eq 0
          expect(ReconcileRatingTopicsJob.jobs.count).to eq 1
          ReconcileRatingTopicsJob.drain
          expect(rating.reload.topics.pluck(:id)).to eq([topic.id])
        end
      end
    end
  end
end
