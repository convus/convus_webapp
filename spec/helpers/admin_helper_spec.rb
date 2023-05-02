# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  describe "missing_meta_count" do
    let(:citation) { Citation.new }
    it "is 6" do
      expect(missing_meta_count(citation)).to eq("<span class=\"text-error\">6</span>")
    end
  end
end
