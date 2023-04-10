# frozen_string_literal: true

require "rails_helper"

RSpec.describe DistantChildCreatorJob, type: :job do
  let(:instance) { described_class.new }
  let!(:united_states) { FactoryBot.create(:topic, name: "United States") }
  let!(:us_state) { FactoryBot.create(:topic, name: "U.S. State", parents_string: "United States") }
  let!(:illinois) { FactoryBot.create(:topic, name: "Illinois", parents_string: "U.S. State") }
  let!(:chicago) { FactoryBot.create(:topic, name: "Chicago", parents_string: "Illinois") }
  let!(:springfield) { FactoryBot.create(:topic, name: "Springfield", parents_string: "Illinois") }
  let!(:california) { FactoryBot.create(:topic, name: "California", parents_string: "U.S. State") }

  before { Sidekiq::Worker.clear_all }

  describe "#perform id" do
    it "creates the full children" do
      expect(chicago.reload.parents.count).to eq 1
      expect(united_states.reload.children.count).to eq 1
      instance.perform(united_states.id)
      expect(chicago.reload.parents.count).to eq 3
      expect(united_states.reload.children.count).to eq 5
      expect(united_states.children.pluck(:id)).to match_array([us_state.id, illinois.id, california.id, chicago.id, springfield.id])
      expect(united_states.direct_children.pluck(:id)).to match_array([us_state.id])
      expect(illinois.reload.direct_children.pluck(:id)).to match_array([chicago.id, springfield.id])
    end

    context "illiois id" do
      it "creates the children" do
        expect(chicago.reload.parents.count).to eq 1
        expect(united_states.reload.children.count).to eq 1
        instance.perform(illinois.id)
        expect(chicago.reload.parents.count).to eq 3
        expect(united_states.reload.children.count).to eq 4
        expect(united_states.children.pluck(:id)).to match_array([us_state.id, illinois.id, chicago.id, springfield.id])
        expect(united_states.direct_children.pluck(:id)).to match_array([us_state.id])
        expect(illinois.reload.direct_children.pluck(:id)).to match_array([chicago.id, springfield.id])
      end
    end
  end

  describe "enqueue_jobs" do
    it "only enqueues one job" do
      expect(DistantChildCreatorJob.jobs.count).to eq 0
      instance.perform
      expect(DistantChildCreatorJob.jobs.count).to eq 1
    end
  end
end
