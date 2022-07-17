# frozen_string_literal: true

class CraqValidator
  attr_reader :errors

  WAS_NOT_ANSWERED = 'was not answered'
  NOT_VALID_ANSWER = 'has an answer that is not on the list of valid answers'
  ANSWER_FOR_COMPLETED_QUESTION = 'was answered even though a previous response indicated that the questions were complete'
  INDEX_OFFSET = 1
  LOWEST_POSSIBLE_ANSWER = 0

  def initialize(questions, answers)
    @questions = questions
    @answers = answers
    @errors = {}
  end

  def valid?
    validate_at_least_one_answer_present
    validate_each_answer if _valid?
    _valid?
  end

  private

  # validators
  def validate_at_least_one_answer_present
    invalid_all_answers unless answers_object_valid?
  end

  def validate_each_answer
    has_terminal_answer = false
    @questions.each_with_index do |question, index|
      answer_key = create_key(index)
      question_options = question[:options]
      answer_after_terminal_answer = has_terminal_answer && has_answer?(answer_key)
      answer_before_terminal_answer = !has_terminal_answer && has_answer?(answer_key)
      if answer_after_terminal_answer
        add_error(answer_key, ANSWER_FOR_COMPLETED_QUESTION)
      elsif answer_before_terminal_answer && valid_answer?(question_options, answer_key)
        has_terminal_answer = question_options[answer(answer_key)][:complete_if_selected]
      elsif answer_before_terminal_answer && !valid_answer?(question_options, answer_key)
        add_error(answer_key, NOT_VALID_ANSWER)
      elsif !has_terminal_answer
        add_error(answer_key, WAS_NOT_ANSWERED)
      end
    end
  end

  # validation checkers
  def answers_object_valid?
    valid = !(@answers.nil? || @answers.empty?)
    invalid_all_answers unless valid
    valid
  end

  def valid_answer?(question_options, answer_key)
    current_answer = answer(answer_key)
    highest_possible_answer = question_options.count - INDEX_OFFSET
    current_answer >= LOWEST_POSSIBLE_ANSWER && current_answer <= highest_possible_answer
  end

  def has_answer?(answer_key)
    @answers.key?(answer_key)
  end

  # helpers
  def _valid?
    @errors.empty?
  end

  def invalid_all_answers
    @questions.each_index { |index| add_error(create_key(index), WAS_NOT_ANSWERED) }
  end

  def answer(answer_key)
    @answers[answer_key]
  end

  def add_error(key, error)
    @errors[key] = error
  end

  def create_key(key)
    "q#{key}".to_sym
  end

end
