require "rails_helper"

RSpec.describe ClaudeParser::SecondPrompt do
  let(:subject) { described_class }
  let(:publisher) { FactoryBot.create(:publisher, name: "a Publisher") }
  let(:citation) { FactoryBot.create(:citation, publisher: publisher) }
  let(:quiz) { FactoryBot.create(:quiz, input_text: input_text, citation: citation) }
  let(:input_text) { nil }

  describe "parse_quiz" do
    let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nQuestion: Question One\nTrue option: Something True\nFalse option: Something false\nStep 2:  \nQuestion: Question two\nTrue option: Something 2 True\nFalse option: Something 2 false\n\n" }
    let(:target) do
      [
        {
          question: "Question One",
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
      expect(subject.send(:claude_responses, quiz)).to eq({quiz: input_text.strip})
      result = subject.parse_quiz(quiz)
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
        result = subject.parse_quiz(quiz)
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
            question: "",
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
        result = subject.parse_quiz(quiz)
        expect(result.count).to eq 2
        result.count.times do |i|
          expect_hashes_to_match(result[i], target[i])
        end
      end
    end
  end

  describe "claude_responses" do
    it "blank input_text raises parser error" do
      expect(quiz.input_text).to be_nil
      expect {
        subject.send(:claude_responses, quiz)
      }.to raise_error(/No input_text/)
    end
  end

  describe "parse_subject" do
    let(:input_text) { "\n\n---\n\n#{subject_text}" }
    let(:subject_text) { "Here is a 5 word summary of the article:\n\nClimate bill spurs clean tech" }
    it "returns the parsed text" do
      expect(subject.send(:claude_responses, quiz)).to eq({quiz: "", subject: subject_text})
      expect(subject.send(:parse_subject_response, subject_text)).to eq "Climate bill spurs clean tech"
    end
    context "on the same line" do
      let(:subject_text) { "The subject of the article is: Climate bill spurs clean tech" }
      it "returns the parsed text" do
        expect(subject.send(:claude_responses, quiz)).to eq({quiz: "", subject: subject_text.strip})
        expect(subject.send(:parse_subject_response, subject_text)).to eq "Climate bill spurs clean tech"
      end
    end
  end

  describe "parse_quiz_response" do
    context "valid single question claude_initial response" do
      let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nQuestion: The Question Step 1\nTrue option: The Step 1 True\nFalse option: The Step 1 false\n\n" }
      let(:target) { {question: "The Question Step 1", correct: ["The Step 1 True"], incorrect: ["The Step 1 false"]} }
      it "returns the parsed text" do
        result = subject.send(:parse_quiz_response, quiz.input_text)
        expect(result.count).to eq 1
        expect_hashes_to_match(result.first, target)
      end
      context "reversed order, extra white space" do
        let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nFalse option:\n\nThe Step 1 false\nTrue option: The Step 1 True\nQuestion:\n\nThe Question Step 1\n\n" }
        it "returns the parsed text" do
          result = subject.send(:parse_quiz_response, quiz.input_text)
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
        result = subject.send(:parse_quiz_response, quiz.input_text)
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
        result = subject.send(:parse_quiz_response, quiz.input_text)
        expect(result.count).to eq 3
        result.count.times do |i|
          expect_hashes_to_match(result[i], target[i])
        end
      end
      context "with blank question text" do
        let(:input_text) do
          "Here is a 3-step chronological summary of the key events in the article, with one true and one false option at each step:\n" \
          "Step 1: Question\n" \
          "True: Step 1 true\n" \
          "False: Step 1 false\n" \
          "Step 2: Question\n" \
          "True: Step 2 true\n" \
          "False: Step 2 false\n" \
          "Step 3: Question\n" \
          "True: Step 3 true\n" \
          "False: Step 3 false"
        end
        it "returns the parsed text" do
          result = subject.send(:parse_quiz_response, quiz.input_text)
          expect(result.count).to eq 3
          result.count.times do |i|
            expect_hashes_to_match(result[i], target[i])
          end
        end
      end
    end
  end

  describe "clean_subject" do
    let(:subject_str) { "The article is about Libraries strained as social services decline." }
    let(:target) { "Libraries strained as social services decline" }
    it "responds with the target" do
      expect(subject.send(:clean_subject, subject_str)).to eq target
    end
    context "The article discusses" do
      let(:subject_str) { "The article discusses Libraries strained as social services decline." }
      it "responds with the target" do
        expect(subject.send(:clean_subject, subject_str)).to eq target
      end
    end
    context "count" do
      let(:subject_str) { "In 10 words or less: Libraries strained as social services decline" }
      it "responds with the target" do
        expect(subject.send(:clean_subject, subject_str)).to eq target
      end
    end
    context "another leading words description" do
      let(:subject_str) { "In 8 words or less, the subject of this article is libraries strained as social services decline." }
      it "responds with the target" do
        expect(subject.send(:clean_subject, subject_str)).to eq target
      end
    end

    context "In 10 words or less, this article is about" do
      let(:subject_str) { "In 10 words or less, this article is about Libraries strained as social services decline." }
      it "responds with the target" do
        expect(subject.send(:clean_subject, subject_str)).to eq target
      end
    end
  end
end
