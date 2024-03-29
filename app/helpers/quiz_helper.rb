module QuizHelper
  def quiz_title_display(quiz)
    citation = quiz.citation
    content_tag(:span) do
      concat(quiz.title)
      concat(", from")
      if citation.authors.any? && citation.authors.first != citation.publisher.name
        concat(" ")
        concat(content_tag(:em, citation.authors.first))
        concat(" in")
      end
      concat(content_tag(:span, " ", class: "no-underline"))
      concat(content_tag(:span, citation.publisher.name, class: "decoration-publisher"))
      concat(content_tag(:span, " ", class: "no-underline"))
      concat(content_tag(:span,
        citation.published_updated_at_with_fallback.to_i,
        class: "convertTime withPreposition"))
    end
  end

  def quiz_question_responded_display(quiz_question_response, quiz_question_answer)
    border_class = if quiz_question_response.quiz_question_answer_id == quiz_question_answer.id
      quiz_question_answer.correct ? "border-success border" : "border-error border"
    else
      ""
    end
    content_tag(:span, quiz_question_answer.text, class: "block py-2 px-4 #{border_class}")
  end
end
