# frozen_string_literal: true

require "rails_helper"

RSpec.describe RatingCreatedEventJob, type: :job do
  let(:instance) { described_class.new }
  let(:user) { FactoryBot.create(:user) }
  let(:rating) { FactoryBot.create(:rating, user: user) }

  describe "#perform" do
    before { Sidekiq::Worker.clear_all }

    it "creates an event" do
      expect(user.reload.total_kudos).to eq 0
      expect(rating.events.count).to eq 0
      expect(instance.perform(rating.id))
      expect(rating.reload.events.count).to eq 1
      event = rating.events.last
      expect(event.user_id).to eq user.id
      expect(event.kind).to eq "rating_created"
      expect(event.target).to eq rating
      expect(event.kudos_events.count).to eq 1
      kudos_event = event.kudos_events.first
      expect(kudos_event.kudos_event_kind.name).to eq "Rating added"
      expect(kudos_event.total_kudos).to eq 10
      expect(user.reload.total_kudos).to eq 10
    end
  end

  describe "rating perform_rating_created_event_job" do
    it "enqueues the job" do
      expect(described_class.jobs.count).to eq 0
      rating = FactoryBot.build(:rating)
      expect {
        rating.save
        expect(rating).to be_valid
      }.to change(described_class.jobs, :count).by(1)
      expect(described_class.jobs.map { |j| j["args"] }.last).to eq([rating.id])
    end
    context "skip_rating_created_event" do
      it "doesn't enqueue" do
        expect(described_class.jobs.count).to eq 0
        rating = FactoryBot.build(:rating, skip_rating_created_event: true)
        expect {
          rating.save
          expect(rating).to be_valid
        }.to change(described_class.jobs, :count).by(0)
      end
    end
  end

  describe "duplicate" do
    let(:event1) { FactoryBot.create(:event, target: rating) }
    let(:event2) { FactoryBot.create(:event, target: rating) }
    it "deletes itself" do
      expect(event1.user_id).to eq event2.user_id
      expect(Event.pluck(:kind)).to eq(%w[rating_created rating_created])
      instance.perform(rating.id)
      expect(Event.pluck(:id)).to eq([event1.id])
    end
  end
end
