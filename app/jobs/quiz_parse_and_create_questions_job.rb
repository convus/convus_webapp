class QuizParseAndCreateQuestionsJob < ApplicationJob
  sidekiq_options retry: 2

  def perform(id)
    quiz = Quiz.find(id)
    return if quiz.status != "pending"
    quiz_questions = parse_quiz_questions(quiz)
  rescue QuizParserErrorBlocking, QuizParserErrorWarning => e
    # TODO: handle Warning vs Blocking
    pp e
  end

  def parse_quiz_questions(quiz)
    if quiz.input_text.blank?
      raise BlockingQuizParsingError, "No input text"
    end

    input_text_cleaned = quiz.input_text.gsub(/\nStep 1:/, "\n").strip

    input_text_cleaned.split(/\nStep \d+:\n/).each_with_index.map do |question, i|
      incorrect, correct = question.split(/\nfalse:/i)
      if incorrect.blank? || correct.blank?
        raise  BlockingQuizParsingError, "Question #{i} doesn't have both a true and false response"
      end
      {correct: [correct.gsub(/\Atrue:/i, "").strip], incorrect: [incorrect.strip]}
    end
  end

  def parse_question_answers(quiz_question)
  end
end
