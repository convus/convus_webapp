class QuizParser::ClaudeInitial
  class << self
    def parse(quiz)
      parsed = parse_input_text(quiz)

      # Add the opening question text
      q1_text = [opening_question_text(quiz), parsed.first[:question]].reject(&:blank?)
      parsed.first[:question] = q1_text.join(", ")

      parsed
    end

    private

    # I don't love this, line by line parsing - but it works pretty well and I think it's flexible.
    def parse_input_text(quiz)
      if quiz.input_text.blank?
        raise QuizParser::ParsingError, "No input_text"
      end

      result = []
      current_key = nil
      current_text = nil

      quiz.input_text.split("\n").each do |line|
        if line.match?(/\Astep \d+:/i)
          update_result(result, current_key, current_text)
          current_key = nil
          result << {question: nil, correct: [], incorrect: []}
        elsif result.any?
          # ignore everything before the 'Step 1:', since there isn't a result yet
          if line.match?(/\Aquestion:/i)
            update_result(result, current_key, current_text)
            current_key = :question
            current_text = line.gsub(/\Aquestion:/i, "").strip
          elsif line.match?(/\A((true)|(false))\s?(option)?:/i)
            update_result(result, current_key, current_text)
            current_key = line.match?(/\Atrue/i) ? :correct : :incorrect
            current_text = line.gsub(/\A((true)|(false))\s?(option)?:/i, "").strip
          elsif current_key.present?
            update_result(result, current_key, line)
          end
        end
      end
      update_result(result, current_key, current_text)
      result
    end

    def update_result(result, current_key, current_text)
      return if current_key.blank? || current_text.blank?
      if current_key == :question
        result.last[current_key] = current_text
      elsif current_key.present?
        result.last[current_key] << current_text
      end
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
