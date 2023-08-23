require "rails_helper"

RSpec.describe QuizParser::ClaudeInitial do
  let(:subject) { described_class }
  let(:time) { Time.at(1657071309) } # 2022-07-05 18:35:09
  let(:time_el) { "<span class=\"convertTime withPreposition\">#{time.to_i}</span>" }
  let(:publisher) { FactoryBot.create(:publisher, name: "a Publisher") }
  let(:citation) { FactoryBot.create(:citation, publisher: publisher, created_at: time) }
  let(:quiz) { FactoryBot.create(:quiz, input_text: input_text, citation: citation) }
  let(:input_text) { nil }

  describe "parse" do
    let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nQuestion: Question One\nTrue option: Something True\nFalse option: Something false\nStep 2:  \nQuestion: Question two\nTrue option: Something 2 True\nFalse option: Something 2 false\n\n" }
    let(:target) do
      [
        {
          question: "According to <u>a Publisher</u> #{time_el}, Question One",
          correct: ["Something True"],
          incorrect: ["Something false"]
        }, {
          question: "Question two",
          correct: ["Something 2 True"],
          incorrect: ["Something 2 false"]
        }
      ]
    end
    it "responds with target" do
      result = subject.parse(quiz)
      expect(result.count).to eq 2
      result.count.times do |i|
        expect_hashes_to_match(result[i], target[i])
      end
    end

    context "question on same line as step" do
      let(:input_text) do
        "Here is a summary of the key events from the article in a chronological true/false format with questions:\n" \
        "Step 1: Question One\n" \
        "True option: Something True\n" \
        "False option: Something false\n" \
        "Step 2:\n" \
        "Question two\n" \
        "True option: \"Something 2 True\"\n" \
        "False option: \"Something 2 false\"\n\n"
      end
      it "responds with target" do
        result = subject.parse(quiz)
        expect(result.count).to eq 2
        result.count.times do |i|
          expect_hashes_to_match(result[i], target[i])
        end
      end
    end

    context "without questions" do
      let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nTrue option: Something True\nFalse option: Something false\nStep 2:  \nTrue option: Something 2 True\nFalse option: Something 2 false\n\n" }
      let(:target) do
        [
          {
            question: "According to <u>a Publisher</u> #{time_el}",
            correct: ["Something True"],
            incorrect: ["Something false"]
          }, {
            question: nil,
            correct: ["Something 2 True"],
            incorrect: ["Something 2 false"]
          }
        ]
      end
      it "responds with target" do
        result = subject.parse(quiz)
        expect(result.count).to eq 2
        result.count.times do |i|
          expect_hashes_to_match(result[i], target[i])
        end
      end
    end
  end

  describe "opening_question_text" do
    context "with no author" do
      let(:target) { "According to <u>a Publisher</u> #{time_el}" }
      it "responds with text" do
        expect(citation.reload.published_updated_at_with_fallback).to be_within(1).of time
        expect(citation.authors).to be_empty
        expect(subject.send(:opening_question_text, quiz)).to eq target
      end
    end

    context "with one author" do
      let(:citation) { FactoryBot.create(:citation, publisher: publisher, authors: ["Sally"], published_updated_at: time) }
      let(:target) { "According to <em>Sally</em> in <u>a Publisher</u> #{time_el}" }
      it "responds with text" do
        expect(subject.send(:opening_question_text, quiz)).to eq target
      end
    end
  end

  describe "parse_input_text" do
    it "blank input_text raises parser error" do
      expect(quiz.input_text).to be_nil
      expect {
        subject.send(:parse_input_text, quiz)
      }.to raise_error(/No input_text/)
    end

    context "valid single question claude_initial response" do
      let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nQuestion: The Question Step 1\nTrue option: The Step 1 True\nFalse option: The Step 1 false\n\n" }
      let(:target) { {question: "The Question Step 1", correct: ["The Step 1 True"], incorrect: ["The Step 1 false"]} }
      it "returns the parsed text" do
        result = subject.send(:parse_input_text, quiz)
        expect(result.count).to eq 1
        expect_hashes_to_match(result.first, target)
      end
      context "reversed order, extra white space" do
        let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nFalse option:\n\nThe Step 1 false\nTrue option: The Step 1 True\nQuestion:\n\nThe Question Step 1\n\n" }
        it "returns the parsed text" do
          result = subject.send(:parse_input_text, quiz)
          expect(result.count).to eq 1
          expect_hashes_to_match(result.first, target)
        end
      end
    end

    context "valid multiple question claude_initial response" do
      let(:input_text) do
        "Here is a summary of the key events from the article in a chronological true/false " \
        "format with questions:\nStep 1:\nQuestion: Question Step 1\nTrue option: Step 1 True\n" \
        "False option: Step 1 false\nStep 2:  \nQuestion: Question Step 2\nTrue option: " \
        "Step 2 True\nFalse option: Step 2 false\nStep 3:  \nQuestion: Question Step 3\nTrue " \
        "option: Step 3 True\nFalse option: Step 3 false\nStep 4:\nQuestion: Question Step 4" \
        "\nTrue option: Step 4 True\nFalse option: Step 4 false\nStep 5:  \nQuestion: Question " \
        "Step 5\nTrue option: Step 5 True\nFalse option: Step 5 false"
      end
      let(:target) do
        [{question: "Question Step 1", correct: ["Step 1 True"], incorrect: ["Step 1 false"]},
          {question: "Question Step 2", correct: ["Step 2 True"], incorrect: ["Step 2 false"]},
          {question: "Question Step 3", correct: ["Step 3 True"], incorrect: ["Step 3 false"]},
          {question: "Question Step 4", correct: ["Step 4 True"], incorrect: ["Step 4 false"]},
          {question: "Question Step 5", correct: ["Step 5 True"], incorrect: ["Step 5 false"]}]
      end
      it "returns the parsed text" do
        result = subject.send(:parse_input_text, quiz)
        expect(result.count).to eq 5
        result.count.times do |i|
          expect_hashes_to_match(result[i], target[i])
        end
      end
    end

    context "valid claude_initial response without questions" do
      let(:input_text) do
        "Here is a 3-step chronological summary of the key events in the article, with one true and one false option at each step:\n" \
        "Step 1:\n" \
        "True: Step 1 true\n" \
        "False: Step 1 false\n" \
        "Step 2: \n" \
        "True: Step 2 true\n" \
        "False: Step 2 false\n" \
        "Step 3: \n" \
        "True: Step 3 true\n" \
        "False: Step 3 false"
      end
      let(:target) do
        [{question: "", correct: ["Step 1 true"], incorrect: ["Step 1 false"]},
          {question: "", correct: ["Step 2 true"], incorrect: ["Step 2 false"]},
          {question: "", correct: ["Step 3 true"], incorrect: ["Step 3 false"]}]
      end
      it "returns the parsed text" do
        result = subject.send(:parse_input_text, quiz)
        expect(result.count).to eq 3
        result.count.times do |i|
          expect_hashes_to_match(result[i], target[i])
        end
      end
    end
  end
end
