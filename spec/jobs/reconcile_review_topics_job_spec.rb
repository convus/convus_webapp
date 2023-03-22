# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReconcileReviewTopicsJob, type: :job do
  let(:instance) { described_class.new }
  let(:review) { FactoryBot.create(:review, topics_text: topics_text) }
  let(:topics_text) { " Some cool topic\n\n" }
  let(:citation) { review.citation }

  describe "#perform" do
    before { Sidekiq::Worker.clear_all  }
    it "creates the topics" do
      expect(Topic.count).to eq 0
      expect {
        expect(review).to be_valid
      }.to change(described_class.jobs, :count).by(1)
      expect {
        instance.perform(review.id)
      }.to change(described_class.jobs, :count).by(0)
      expect(Topic.count).to eq 1
      topic = Topic.last
      expect(topic.name).to eq "Some cool topic"
      expect(review.reload.topics_text).to eq topic.name
      expect(review.topics.pluck(:id)).to eq([topic.id])

      # And delete it!
      expect {
        review.update(topics_text: "\n")
      }.to change(described_class.jobs, :count).by(1)
      expect {
        instance.perform(review.id)
      }.to change(described_class.jobs, :count).by(0)
      expect(review.reload.topics_text).to be_nil
      expect(review.topics.pluck(:id)).to eq([])
    end
  end
end
