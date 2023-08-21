class Quiz < ApplicationRecord
  STATUS_ENUM = {
    pending: 0,
    active: 1,
    replaced: 2,
    disabled: 3
  }.freeze

  SOURCE_ENUM = {admin_entry: 0}.freeze

  KIND_ENUM = {citation_quiz: 0}.freeze

  INPUT_TEXT_FORMAT = {claude_initial: 0}.freeze

  enum status: STATUS_ENUM
  enum source: SOURCE_ENUM
  enum kind: KIND_ENUM
  enum input_text_format: INPUT_TEXT_FORMAT

  belongs_to :citation

  has_many :quiz_questions

  before_validation :set_calculated_attributes
  after_commit :mark_quizzes_replaced_and_enqueue_parsing, on: :create

  scope :current, -> { where(status: current_statuses) }

  def self.current_statuses
    %i[pending active disabled].freeze
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
      .order(:id)
  end

  def associated_quizzes_previous
    id.present? ? associated_quizzes.where("id < ?", id) : associated_quizzes
  end

  def associated_quizzes_current
    current? ? self : associated_quizzes.current.first
  end

  def mark_quizzes_replaced_and_enqueue_parsing
    return true if associated_quizzes.where("id > ?", id).any?
    associated_quizzes_previous.update_all(status: :replaced)
    QuizParseAndCreateQuestionsJob.perform_async(id)
  end

  private

  def calculated_version
    associated_quizzes_previous.count + 1
  end
end
