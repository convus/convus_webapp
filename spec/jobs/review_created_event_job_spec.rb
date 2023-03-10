# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReviewCreatedEventJob, type: :job do
  let(:instance) { described_class.new }
  let(:user) { FactoryBot.create(:user) }
  let(:review) { FactoryBot.create(:review, user: user) }

  describe "#perform" do
    before { Sidekiq::Worker.clear_all }

    it "creates an event" do
      expect(user.reload.total_kudos).to eq nil
      expect(review.events.count).to eq 0
      expect(instance.perform(review.id))
      expect(review.reload.events.count).to eq 1
      event = review.events.last
      expect(event.user_id).to eq user.id
      expect(event.kind).to eq "review_created"
      expect(event.target).to eq review
      expect(event.kudos_events.count).to eq 1
      kudos_event = event.kudos_events.first
      expect(kudos_event.kudos_event_kind.name).to eq "Review added"
      expect(kudos_event.total_kudos).to eq 10
      expect(user.reload.total_kudos).to eq 10
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

  describe "duplicate" do
    let(:event1) { FactoryBot.create(:event, target: review) }
    let(:event2) { FactoryBot.create(:event, target: review) }
    it "deletes itself" do
      expect(event1.user_id).to eq event2.user_id
      expect(Event.pluck(:kind)).to eq(%w[review_created review_created])
      instance.perform(review.id)
      expect(Event.pluck(:id)).to eq([event1.id])
    end
  end
end
