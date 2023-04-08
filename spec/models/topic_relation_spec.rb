require 'rails_helper'

RSpec.describe TopicRelation, type: :model do
  let(:topic_relation) { FactoryBot.create(:topic_relation) }
  let(:topic_child) { topic_relation.child }
  let(:topic_parent) { topic_relation.parent }
  it "creates them" do
    expect(topic_relation).to be_valid
    expect(topic_child.reload.parent_relations.pluck(:id)).to eq([topic_relation.id])
    expect(topic_child.parents.pluck(:id)).to eq([topic_parent.id])
    expect(topic_child.child_relations.pluck(:id)).to eq([])
    expect(topic_parent.reload.child_relations.pluck(:id)).to eq([topic_relation.id])
    expect(topic_parent.children.pluck(:id)).to eq([topic_child.id])
    expect(topic_parent.parent_relations.pluck(:id)).to eq([])
  end
end
