require "rails_helper"

RSpec.describe TopicRelation, type: :model do
  let(:topic_relation) { FactoryBot.create(:topic_relation) }
  let(:topic_child) { topic_relation.child }
  let(:topic_parent) { topic_relation.parent }
  it "creates them" do
    expect(topic_relation).to be_valid
    expect(topic_relation.distant?).to be_truthy
    expect(topic_child.reload.parent_relations.pluck(:id)).to eq([topic_relation.id])
    expect(topic_child.parents.pluck(:id)).to eq([topic_parent.id])
    expect(topic_child.child_relations.pluck(:id)).to eq([])
    expect(topic_parent.reload.child_relations.pluck(:id)).to eq([topic_relation.id])
    expect(topic_parent.children.pluck(:id)).to eq([topic_child.id])
    expect(topic_parent.parent_relations.pluck(:id)).to eq([])
    # And direct
    expect(topic_child.parents_string).to be_blank
    expect(topic_child.direct_parents.pluck(:id)).to eq([])
    expect(topic_parent.direct_child_relations.pluck(:id)).to eq([])
  end
  context "direct" do
    let(:topic_relation) { FactoryBot.create(:topic_relation_direct) }
    it "creates" do
      expect(topic_relation.direct?).to be_truthy
      expect(topic_relation).to be_valid
      expect(topic_child.reload.parent_relations.pluck(:id)).to eq([topic_relation.id])
      expect(topic_child.parents.pluck(:id)).to eq([topic_parent.id])
      expect(topic_child.child_relations.pluck(:id)).to eq([])
      expect(topic_parent.reload.child_relations.pluck(:id)).to eq([topic_relation.id])
      expect(topic_parent.children.pluck(:id)).to eq([topic_child.id])
      expect(topic_parent.parent_relations.pluck(:id)).to eq([])
      # And direct
      expect(topic_child.parents_string).to eq topic_parent.name
      expect(topic_child.direct_parent_relations.pluck(:id)).to eq([topic_relation.id])
      expect(topic_child.direct_parents.pluck(:id)).to eq([topic_parent.id])
      expect(topic_child.direct_child_relations.pluck(:id)).to eq([])
      expect(topic_parent.direct_child_relations.pluck(:id)).to eq([topic_relation.id])
      expect(topic_parent.direct_children.pluck(:id)).to eq([topic_child.id])
      expect(topic_parent.direct_parent_relations.pluck(:id)).to eq([])
    end
  end

  describe "not_self_relation" do
    let(:topic) { FactoryBot.create(:topic) }
    let(:topic_relation) { TopicRelation.new(parent_id: topic.id, child_id: topic.id) }
    it "isn't valid" do
      expect(topic_relation).to_not be_valid
    end
  end
end
