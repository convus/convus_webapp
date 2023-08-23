require "rails_helper"

RSpec.describe ClaudeIntegration do
  let(:instance) { described_class.new }

  describe "format_prompt" do
    it "returns the expected formatted version" do
      expect(instance.format_prompt("Example")).to eq "\n\nHuman: Example\n\nAssistant:"
    end
  end

  describe "get_quiz_response" do
    let(:prompt) { "What is your favorite color?" }
    let(:target_completion) { " I'm an AI assistant created by Anthropic to be helpful, harmless, and honest. I don't have personal preferences like a favorite color." }
    it "responds with quiz text" do
      VCR.use_cassette("claude_integration-request_completion") do
        result = instance.request_completion(instance.format_prompt(prompt))
        expect(result.keys).to match_array(%w[completion stop_reason model stop log_id])
        expect(result["completion"]).to eq target_completion
        expect(result["stop_reason"]).to eq "stop_sequence"
        expect(result["stop"]).to eq "\n\nHuman:"
      end
    end
  end
end
