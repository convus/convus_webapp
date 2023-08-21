class QuizParser::ClaudeInitial
  class << self
    def parse(quiz)
    end

    private

    def opening_question_text(quiz)
      citation = quiz.citation
      opening_text = if citation.authors.empty?
        "According to <u>#{citation.publisher.name}</u>"
      else
        "According to <em>#{citation.authors.first}</em> in <u>#{citation.publisher.name}</u>"
      end

      "#{opening_text} <span class=\"convertTime withPreposition\">#{citation.published_updated_at_with_fallback.to_i}</span>"
    end

    def parse_input_text(quiz)
      if quiz.input_text.blank?
        raise QuizParserErrorBlocking, "No input text"
      end

      input_text_cleaned = quiz.input_text.gsub(/\nStep 1:/, "\n").strip

      input_text_cleaned.split(/\nStep \d+:\n/).each_with_index.map do |question, i|
        incorrect, correct = question.split(/\nfalse:/i)
        if incorrect.blank? || correct.blank?
          raise  QuizParserErrorBlocking, "Question #{i} doesn't have both a true and false response"
        end
        {correct: [correct.gsub(/\Atrue:/i, "").strip], incorrect: [incorrect.strip]}
      end
    end
  end
end
