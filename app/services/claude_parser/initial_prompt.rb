class ClaudeParser::InitialPrompt
  class << self
    def parse_quiz(quiz)
      parsed = parse_input_text(claude_responses(quiz)[:quiz])

      unless parsed.any?
        raise ClaudeParser::ParsingError, "Unable to parse questions from input_text"
      end
      parsed
    end

    def quiz_prompt_full_texts(quiz_prompt_text, citation)
      (quiz_prompt_text || "").gsub("${ARTICLE_TEXT}", citation&.citation_text)
        .split("\n---\n").map(&:strip)
    end

    private

    def claude_responses(quiz)
      if quiz.input_text.blank?
        raise ClaudeParser::ParsingError, "No input_text"
      end

      # zip then reverse, to skip the subject key if there is no subject
      quiz.input_text.split("\n---\n").zip([:quiz, :subject])
        .map(&:reverse).to_h
    end

    # I don't love this, line by line procedural parsing - but it works pretty well and I think it's flexible.
    def parse_input_text(quiz_text)
      result = []
      current_key = nil
      current_text = nil

      quiz_text.split("\n").each do |line|
        current_text = line
        if line.match?(/\Astep \d+:/i)
          # Since there isn't a result initially, everything before the 'Step 1:' is ignored
          result << {question: "", correct: [], incorrect: []}
          current_key = :question
          current_text.gsub!(/\Astep \d+:/i, "")
        elsif result.any?
          if line.match?(/\Aquestion:/i)
            current_key = :question
            current_text.gsub!(/\Aquestion:/i, "")
          elsif line.match?(/\A((true)|(false))\s?(option)?:/i)
            current_key = line.match?(/\Atrue/i) ? :correct : :incorrect
            current_text.gsub!(/\A((true)|(false))\s?(option)?:/i, "")
          end
        end
        update_result(result, current_key, clean_text(current_text))
      end

      # Remove questions that are just 'question'
      result.each { |r| r[:question] = "" if r[:question]&.downcase == "question" }

      result
    end

    def update_result(result, current_key, current_text)
      return if result.blank? || current_key.blank? || current_text.blank?
      if current_key == :question
        result.last[current_key] += current_text
      elsif current_key.present?
        result.last[current_key] << current_text
      end
    end

    def clean_text(text = nil)
      return nil if text.blank?
      text.strip.gsub(/"\z/, "").gsub(/\A"/, "")
    end
  end
end
