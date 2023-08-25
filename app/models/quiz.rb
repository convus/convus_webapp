class Quiz < ApplicationRecord
  STATUS_ENUM = {
    pending: 0,
    active: 1,
    replaced: 2,
    disabled: 3,
    parse_errored: 4
  }.freeze

  SOURCE_ENUM = {
    admin_entry: 0,
    claude_integration: 1
  }.freeze

  KIND_ENUM = {citation_quiz: 0}.freeze

  INPUT_TEXT_FORMAT = {claude_initial: 0}.freeze

  enum status: STATUS_ENUM
  enum source: SOURCE_ENUM
  enum kind: KIND_ENUM
  enum input_text_format: INPUT_TEXT_FORMAT

  self.implicit_order_column = :id

  belongs_to :citation

  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_question_answers, through: :quiz_questions
  has_many :quiz_responses

  validates_presence_of :citation_id

  before_validation :set_calculated_attributes
  after_commit :mark_quizzes_replaced_and_enqueue_parsing, on: :create

  scope :current, -> { where(status: current_statuses) }

  def self.current_statuses
    %i[pending active disabled].freeze
  end

  def self.integer_str?(str)
    str.is_a?(Integer) || str.strip.match?(/\A\d+\z/)
  end

  def current?
    self.class.current_statuses.include?(status&.to_sym)
  end

  def set_calculated_attributes
    self.status ||= :pending
    self.kind ||= :citation_quiz if citation_id.present?
    self.version ||= calculated_version
    self.input_text = nil if input_text.blank?
    self.input_text_format ||= :claude_initial
  end

  def associated_quizzes
    self.class.where(citation_id: citation_id).where.not(id: id)
  end

  def associated_quizzes_previous
    id.present? ? associated_quizzes.where("id < ?", id) : associated_quizzes
  end

  def associated_quizzes_current
    associated_current = associated_quizzes.current.last
    if current?
      return self if associated_current.blank? || associated_current.id < id
    end
    associated_current
  end

  def mark_quizzes_replaced_and_enqueue_parsing
    return true if associated_quizzes.where("id > ?", id).any?
    QuizParseAndCreateQuestionsJob.perform_async(id)
  end

  private

  def calculated_version
    associated_quizzes_previous.count + 1
  end
end
