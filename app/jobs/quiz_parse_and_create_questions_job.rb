class QuizParseAndCreateQuestionsJob < ApplicationJob
  sidekiq_options retry: 2

  def perform(id)
    quiz = Quiz.find(id)
    return if quiz.status != "pending"
    quiz_questions = parse_quiz_questions(quiz)
  rescue QuizParserError => e
    # TODO: handle Warning vs Blocking
    pp e
  end

  def parse_quiz_questions(quiz)
    QuizParser::ClaudeInitial.new
  end

  def parse_question_answers(quiz_question)
  end
end
