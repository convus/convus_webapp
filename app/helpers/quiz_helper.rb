module QuizHelper
  def quiz_question_responded_display(quiz_question_response, quiz_question_answer)
    border_class = if quiz_question_response.quiz_question_answer_id == quiz_question_answer.id
      quiz_question_answer.correct ? "border-success border" : "border-error border"
    else
      ""
    end
    content_tag(:span, quiz_question_answer.text, class: "block py-2 px-4 #{border_class}")
  end
end
