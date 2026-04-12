# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_12_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "citation_topics", force: :cascade do |t|
    t.bigint "citation_id"
    t.datetime "created_at", null: false
    t.boolean "orphaned", default: false
    t.bigint "topic_id"
    t.datetime "updated_at", null: false
    t.index ["citation_id"], name: "index_citation_topics_on_citation_id"
    t.index ["topic_id"], name: "index_citation_topics_on_topic_id"
  end

  create_table "citations", force: :cascade do |t|
    t.jsonb "authors"
    t.text "canonical_url"
    t.text "citation_text"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "manually_updated_at"
    t.jsonb "manually_updated_attributes"
    t.boolean "paywall", default: false
    t.datetime "published_at"
    t.datetime "published_updated_at"
    t.datetime "published_updated_at_with_fallback"
    t.bigint "publisher_id"
    t.string "subject"
    t.text "title"
    t.datetime "updated_at", null: false
    t.text "url"
    t.jsonb "url_components_json"
    t.integer "word_count"
    t.index ["published_updated_at_with_fallback"], name: "index_citations_on_published_updated_at_with_fallback"
    t.index ["publisher_id"], name: "index_citations_on_publisher_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "created_date"
    t.integer "kind"
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["target_type", "target_id"], name: "index_events_on_target"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "kudos_event_kinds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "max_per_period"
    t.string "name"
    t.integer "period"
    t.integer "total_kudos"
    t.datetime "updated_at", null: false
  end

  create_table "kudos_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "created_date"
    t.bigint "event_id"
    t.bigint "kudos_event_kind_id"
    t.integer "potential_kudos"
    t.integer "total_kudos"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["event_id"], name: "index_kudos_events_on_event_id"
    t.index ["kudos_event_kind_id"], name: "index_kudos_events_on_kudos_event_kind_id"
    t.index ["user_id"], name: "index_kudos_events_on_user_id"
  end

  create_table "publishers", force: :cascade do |t|
    t.integer "base_word_count"
    t.datetime "created_at", null: false
    t.string "domain"
    t.string "name"
    t.boolean "remove_query", default: false
    t.string "slug"
<<<<<<< HEAD
    t.datetime "updated_at", null: false
=======
    t.datetime "updated_at", null: false
  end

  create_table "quiz_question_answers", force: :cascade do |t|
    t.boolean "correct", default: false
    t.datetime "created_at", null: false
    t.integer "list_order", default: 0
    t.bigint "quiz_question_id"
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["quiz_question_id"], name: "index_quiz_question_answers_on_quiz_question_id"
  end

  create_table "quiz_question_responses", force: :cascade do |t|
    t.boolean "correct"
    t.datetime "created_at", null: false
    t.integer "quality", default: 0
    t.bigint "quiz_question_answer_id"
    t.bigint "quiz_question_id"
    t.bigint "quiz_response_id"
    t.datetime "updated_at", null: false
    t.index ["quiz_question_answer_id"], name: "index_quiz_question_responses_on_quiz_question_answer_id"
    t.index ["quiz_question_id"], name: "index_quiz_question_responses_on_quiz_question_id"
    t.index ["quiz_response_id"], name: "index_quiz_question_responses_on_quiz_response_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "list_order", default: 0
    t.bigint "quiz_id"
    t.text "text"
    t.datetime "updated_at", null: false
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quiz_responses", force: :cascade do |t|
    t.bigint "citation_id"
    t.integer "correct_count"
    t.datetime "created_at", null: false
    t.integer "incorrect_count"
    t.integer "question_count"
    t.bigint "quiz_id"
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["citation_id"], name: "index_quiz_responses_on_citation_id"
    t.index ["quiz_id"], name: "index_quiz_responses_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_responses_on_user_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.bigint "citation_id"
    t.datetime "created_at", null: false
    t.text "input_text"
    t.integer "input_text_format"
    t.text "input_text_parse_error"
    t.integer "kind"
    t.jsonb "prompt_params", default: {}
    t.text "prompt_text"
    t.integer "source"
    t.integer "status", default: 0
    t.string "subject"
    t.integer "subject_source"
    t.datetime "updated_at", null: false
    t.integer "version"
    t.index ["citation_id"], name: "index_quizzes_on_citation_id"
>>>>>>> origin/main
  end

  create_table "rating_topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "rating_id"
    t.bigint "topic_id"
    t.datetime "updated_at", null: false
    t.index ["rating_id"], name: "index_rating_topics_on_rating_id"
    t.index ["topic_id"], name: "index_rating_topics_on_topic_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.boolean "account_public", default: false
    t.integer "agreement", default: 0
    t.boolean "changed_opinion", default: false, null: false
    t.bigint "citation_id"
    t.jsonb "citation_metadata"
    t.text "citation_text"
    t.text "citation_title"
    t.datetime "created_at", null: false
    t.date "created_date"
    t.text "display_name"
    t.text "error_quotes"
    t.boolean "learned_something", default: false
    t.datetime "metadata_at"
    t.boolean "not_finished", default: false
    t.boolean "not_understood", default: false
    t.integer "quality", default: 0
    t.boolean "significant_factual_error"
    t.string "source"
    t.text "submitted_url"
    t.string "timezone"
    t.text "topics_text"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "version_integer"
    t.index ["citation_id"], name: "index_ratings_on_citation_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "agreement", default: 0
    t.boolean "changed_my_opinion", default: false, null: false
    t.bigint "citation_id"
    t.text "citation_title"
    t.datetime "created_at", null: false
    t.text "error_quotes"
    t.integer "quality", default: 0
    t.boolean "significant_factual_error"
    t.string "source"
    t.text "submitted_url"
    t.text "topics_text"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["citation_id"], name: "index_reviews_on_citation_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "topic_relations", force: :cascade do |t|
    t.bigint "child_id"
    t.datetime "created_at", null: false
    t.boolean "direct", default: false
    t.bigint "parent_id"
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_topic_relations_on_child_id"
    t.index ["parent_id"], name: "index_topic_relations_on_parent_id"
  end

  create_table "topic_review_citations", force: :cascade do |t|
    t.bigint "citation_id"
    t.bigint "citation_topic_id"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.integer "rank"
    t.bigint "topic_review_id"
    t.datetime "updated_at", null: false
    t.integer "vote_score"
    t.integer "vote_score_manual"
    t.index ["citation_id"], name: "index_topic_review_citations_on_citation_id"
    t.index ["citation_topic_id"], name: "index_topic_review_citations_on_citation_topic_id"
    t.index ["topic_review_id"], name: "index_topic_review_citations_on_topic_review_id"
  end

  create_table "topic_review_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "manual_score", default: false
    t.integer "rank"
    t.datetime "rating_at"
    t.bigint "rating_id"
    t.bigint "topic_review_citation_id"
    t.bigint "topic_review_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.integer "vote_score"
    t.index ["rating_id"], name: "index_topic_review_votes_on_rating_id"
    t.index ["topic_review_citation_id"], name: "index_topic_review_votes_on_topic_review_citation_id"
    t.index ["topic_review_id"], name: "index_topic_review_votes_on_topic_review_id"
    t.index ["user_id"], name: "index_topic_review_votes_on_user_id"
  end

  create_table "topic_reviews", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "display_name"
    t.datetime "end_at"
    t.string "slug"
    t.datetime "start_at"
    t.integer "status"
    t.bigint "topic_id"
    t.string "topic_name"
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_reviews_on_topic_id"
  end

  create_table "topics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.boolean "orphaned", default: false
    t.string "previous_slug"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "user_followings", force: :cascade do |t|
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.bigint "following_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["following_id"], name: "index_user_followings_on_following_id"
    t.index ["user_id"], name: "index_user_followings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "about"
    t.boolean "account_private", default: false
    t.text "api_token"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.integer "sign_in_count", default: 0, null: false
    t.integer "total_kudos"
    t.datetime "updated_at", null: false
    t.string "username"
    t.string "username_slug"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
