class QuizParseAndCreateQuestionsJob < ApplicationJob
  sidekiq_options retry: 2

  def perform(id)
    quiz = Quiz.find(id)
    return if quiz.status != "pending"

    quiz_questions = parsed_quiz_questions(quiz)

    # Mark all previous current quizzes as replaced
    quiz.associated_quizzes_previous.current.update_all(status: :replaced)
  rescue QuizParser::ParsingError => e
    quiz.update(input_text_parse_error: e, status: :parse_errored)
  end

  def parsed_quiz_questions(quiz)
    QuizParser::ClaudeInitial.parse(quiz)
  end

  def parse_question_answers(quiz_question)
  end
end
