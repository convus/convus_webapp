class QuizParseAndCreateQuestionsJob < ApplicationJob
  sidekiq_options retry: 2

  def self.parsed_quiz_text(quiz)
    ClaudeParser::InitialPrompt.parse_quiz(quiz)
  end

  def self.parsed_subject_text(quiz)
    ClaudeParser::InitialPrompt.parse_subject(quiz)
  end

  def perform(id)
    quiz = Quiz.find(id)
    return unless %w[pending disabled].include?(quiz.status)

    quiz.subject ||= self.class.parsed_subject_text(quiz)

    self.class.parsed_quiz_text(quiz).each_with_index do |parsed_question, i|
      create_question_and_answers(quiz, parsed_question, i + 1)
    end

    quiz.update(status: "active") if quiz.status == "pending"
    # Mark all previous current quizzes as replaced
    quiz.associated_quizzes_previous.current.update_all(status: :replaced)
    if quiz.assigns_citation_subject?
      quiz.citation.update(manually_updating: true, subject: quiz.subject)
    end
  rescue ClaudeParser::ParsingError => e
    quiz.update(input_text_parse_error: e, status: :parse_errored)
  end

  def create_question_and_answers(quiz, parsed_question, list_order)
    # Don't create questions unless there are correct and false answers
    return if parsed_question[:correct].none? || parsed_question[:incorrect].none?

    quiz_question = quiz.quiz_questions.create(text: parsed_question[:question], list_order: list_order)
    question_hashes(parsed_question).each do |attrs|
      quiz_question.quiz_question_answers.create(attrs)
    end
  end

  def question_hashes(parsed_question)
    hashes = parsed_question[:correct].map { |q| {text: q, correct: true} } +
      parsed_question[:incorrect].map { |q| {text: q, correct: false} }

    hashes.shuffle.each_with_index.map { |q_h, i| q_h.merge(list_order: i + 1) }
  end
end
