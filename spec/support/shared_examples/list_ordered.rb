require "rails_helper"

RSpec.shared_examples "list_ordered" do
  let(:model_sym) { subject.class.name.underscore.to_sym }
  let(:instance) { FactoryBot.create model_sym }

  describe "list_order" do
    let!(:instance1) { FactoryBot.create(model_sym, list_order: 2) }
    let!(:instance2) { FactoryBot.create(model_sym, list_order: 1) }

    it "orders" do
      expect(instance1.reload.list_order).to eq 2
      expect(instance2.reload.list_order).to eq 1

      expect(subject.class.list_order.pluck(:id)).to eq([instance2.id, instance1.id])
    end
  end
end
