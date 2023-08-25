class QuizParser::ClaudeInitial
  class << self
    def parse(quiz)
      parsed = parse_input_text(quiz)

      unless parsed.any?
        raise QuizParser::ParsingError, "Unable to parse questions from input_text"
      end

      # Add the opening question text
      q1_text = [opening_question_text(quiz), parsed.first[:question]].reject(&:blank?)
      parsed.first[:question] = q1_text.join(", ")

      parsed
    end

    private

    # I don't love this, line by line procedural parsing - but it works pretty well and I think it's flexible.
    def parse_input_text(quiz)
      if quiz.input_text.blank?
        raise QuizParser::ParsingError, "No input_text"
      end

      result = []
      current_key = nil
      current_text = nil

      quiz.input_text.split("\n").each do |line|
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

    def opening_question_text(quiz)
      citation = quiz.citation
      opening_text = if citation.authors.empty?
        "According to <u>#{citation.publisher.name}</u>"
      else
        "According to <em>#{citation.authors.first}</em> in <u>#{citation.publisher.name}</u>"
      end

      "#{opening_text} <span class=\"convertTime withPreposition\">#{citation.published_updated_at_with_fallback.to_i}</span>"
    end
  end
end
