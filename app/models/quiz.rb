class Quiz < ApplicationRecord
  include TopicMatchable

  STATUS_ENUM = {
    pending: 0,
    active: 1,
    replaced: 2,
    disabled: 3,
    parse_errored: 4
  }.freeze

  SOURCE_ENUM = {
    admin_entry: 0,
    claude_integration: 1,
    claude_admin_submission: 2
  }.freeze

  SUBJECT_SOURCE = {
    subject_inherited: 0,
    subject_claude_integration: 1,
    subject_admin_entry: 2,
    subject_admin_citation_entry: 3
  }.freeze

  KIND_ENUM = {citation_quiz: 0}.freeze

  INPUT_TEXT_FORMAT = {claude_initial: 0, claude_second: 1}.freeze

  enum status: STATUS_ENUM
  enum source: SOURCE_ENUM
  enum kind: KIND_ENUM
  enum input_text_format: INPUT_TEXT_FORMAT
  enum subject_source: SUBJECT_SOURCE

  self.implicit_order_column = :id

  belongs_to :citation

  has_many :quiz_questions, dependent: :destroy
  has_many :quiz_question_answers, through: :quiz_questions
  has_many :quiz_responses
  has_many :citation_topics, foreign_key: :citation_id, primary_key: :citation_id
  has_many :topics, through: :citation_topics

  validates_presence_of :citation_id
  validate :prompt_params_text_valid_json

  before_validation :set_calculated_attributes
  after_commit :enqueue_prompting_if_admin_submission, on: :create

  scope :current, -> { where(status: current_statuses) }
  scope :citation_ordered, -> { includes(:citation).order('citations.published_updated_at_with_fallback DESC')}

  attr_writer :prompt_params_text

  def self.current_statuses
    %i[pending active disabled].freeze
  end

  def self.disableable_statuses
    %i[pending active].freeze
  end

  def self.prompt_sources
    %i[claude_integration claude_admin_submission].freeze
  end

  def self.subject_set_manually_sources
    %i[subject_admin_entry subject_admin_citation_entry].freeze
  end

  def self.kind_humanized(str)
    str.present? ? str.to_s.humanize : nil
  end

  def self.source_humanized(str)
    str.present? ? str.to_s.humanize : nil
  end

  def subject_set_manually?
    self.class.subject_set_manually_sources.include?(subject_source.to_sym)
  end

  def prompt_source?
    self.class.prompt_sources.include?(source&.to_sym)
  end

  def current?
    self.class.current_statuses.include?(status&.to_sym)
  end

  def disableable?
    self.class.disableable_statuses.include?(status&.to_sym)
  end

  def kind_humanized
    self.class.kind_humanized(kind)
  end

  def source_humanized
    self.class.source_humanized(source)
  end

  def title
    subject.present? ? subject : "an article"
  end

  def prompt_params_text
    @prompt_params_text ||= (prompt_params || {}).to_json
  end

  def prompt_params_text_valid_json
    self.prompt_params = JSON.parse(prompt_params_text) if prompt_params_text.present?
  rescue => e
    errors.add(:prompt_params, "Unable to parse: #{e.message}")
  end

  def set_calculated_attributes
    self.status ||= :pending
    self.kind ||= :citation_quiz if citation_id.present?
    self.version ||= calculated_version
    self.input_text = nil if input_text.blank?
    self.prompt_text = nil if prompt_text.blank?
    self.input_text_format ||= :claude_second
    self.subject_source ||= calculated_initial_subject_source
    self.subject = citation&.subject if subject.blank? || subject_admin_citation_entry?
  end

  def associated_quizzes
    self.class.where(citation_id: citation_id).where.not(id: id).order(:id)
  end

  def associated_quizzes_following
    associated_quizzes.where("id > ?", id)
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

  def enqueue_prompting_if_admin_submission
    return true if associated_quizzes.where("id > ?", id).any?
    # QuizParseAndCreateQuestionsJob is enqueued from the PromptClaude job
    return true unless claude_admin_submission?
    PromptClaudeForCitationQuizJob.perform_async({citation_id: citation_id, quiz_id: id}.as_json)
  end

  private

  def calculated_initial_subject_source
    if admin_entry? && subject.present?
      :subject_admin_entry
    elsif citation&.manually_updated_subject?
      :subject_admin_citation_entry
    else
      :subject_inherited
    end
  end

  def calculated_version
    associated_quizzes_previous.count + 1
  end
end
