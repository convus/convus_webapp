# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewCreatedEventJob, type: :job do
  let(:instance) { described_class.new }
  let(:user) { FactoryBot.create(:user) }
  let(:review) { FactoryBot.create(:review, user: user) }

  describe "#perform" do
    before { Sidekiq::Worker.clear_all }

    it "creates an event" do
      expect(review.events.count).to eq 0
      expect(instance.perform(review.id))
      expect(review.reload.events.count).to eq 1
      event = review.events.last
      expect(event.user_id).to eq user.id
      expect(event.kind).to eq "review_created"
      expect(event.target).to eq review
    end
  end

  describe "review creation" do
    it "enqueus the job" do
      expect(described_class.jobs.count).to eq 0
      review = FactoryBot.build(:review)
      expect {
        review.save
      }.to change(described_class.jobs, :count).by(1)
      expect(described_class.jobs.map { |j| j["args"] }.last).to eq([review.id])
    end
  end
end
