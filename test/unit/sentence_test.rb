require File.dirname(__FILE__) + '/../test_helper'

class SentenceTest < ActiveSupport::TestCase
  def setup
    @sd = Source.first.source_divisions.create!

    @sentence_first_in_sd = @sd.sentences.create! :sentence_number => 0, :status_tag => 'unannotated'

    @sentence_middle_of_sd = @sd.sentences.create! :sentence_number => 1, :status_tag => 'unannotated'
    @t0 = @sentence_middle_of_sd.tokens.create! :token_number => 0, :form => 'foo', :presentation_after => ', '
    @t1 = @sentence_middle_of_sd.tokens.create! :token_number => 1, :form => 'foo', :presentation_after => '. '
    @sentence_middle_of_sd.tokens.reload

    @sentence_last_in_sd = @sd.sentences.create! :sentence_number => 2, :presentation_after => 'Some text', :status_tag => 'unannotated'
    @t2 = @sentence_last_in_sd.tokens.create! :token_number => 0, :form => 'foo', :presentation_after => ', '
    @t3 = @sentence_last_in_sd.tokens.create! :token_number => 1, :form => 'foo', :presentation_after => '. '
    @sentence_last_in_sd.tokens.reload

    @sentence_extra_last_in_sd = @sd.sentences.create! :sentence_number => 3, :status_tag => 'unannotated'
  end

  def test_next_previous
    assert @sentence_first_in_sd.has_next?
    assert @sentence_middle_of_sd.has_next?
    assert @sentence_last_in_sd.has_next?
    assert !@sentence_extra_last_in_sd.has_next?

    assert_equal @sentence_middle_of_sd, @sentence_first_in_sd.next_object
    assert_equal @sentence_last_in_sd, @sentence_middle_of_sd.next_object
    assert_equal @sentence_extra_last_in_sd, @sentence_last_in_sd.next_object
    assert_equal nil, @sentence_extra_last_in_sd.next_object

    assert !@sentence_first_in_sd.has_previous?
    assert @sentence_middle_of_sd.has_previous?
    assert @sentence_last_in_sd.has_previous?
    assert @sentence_extra_last_in_sd.has_previous?

    assert_equal nil, @sentence_first_in_sd.previous_object
    assert_equal @sentence_first_in_sd, @sentence_middle_of_sd.previous_object
    assert_equal @sentence_middle_of_sd, @sentence_last_in_sd.previous_object
    assert_equal @sentence_last_in_sd, @sentence_extra_last_in_sd.previous_object
  end

  def test_append_sentence
    assert_equal 0, @sentence_first_in_sd.tokens.count
    assert_equal 2, @sentence_middle_of_sd.tokens.count
    assert_equal 2, @sentence_last_in_sd.tokens.count
    assert_equal 0, @sentence_extra_last_in_sd.tokens.count

    assert @sentence_first_in_sd.is_next_sentence_appendable?
    assert @sentence_middle_of_sd.is_next_sentence_appendable?
    assert !@sentence_last_in_sd.is_next_sentence_appendable? # intervening presetation text
    assert !@sentence_extra_last_in_sd.is_next_sentence_appendable? # lacks next_sentence

    assert_raise ArgumentError do
      @sentence_extra_last_in_sd.append_next_sentence!
    end

    assert_raise ArgumentError do
      @sentence_last_in_sd.append_next_sentence!
    end

    @sentence_middle_of_sd.append_next_sentence!
    @sentence_middle_of_sd.tokens.reload

    assert @sentence_middle_of_sd.presentation_before.blank?
    assert_equal 'Some text', @sentence_middle_of_sd.presentation_after

    assert_equal 4, @sentence_middle_of_sd.tokens.count

    t0, t1, t2, t3 = @sentence_middle_of_sd.tokens

    assert_equal @t0, t0
    assert_equal @t1, t1
    assert_equal @t2, t2
    assert_equal @t3, t3

    assert_equal 0, t0.token_number
    assert_equal 1, t1.token_number
    assert_equal 2, t2.token_number
    assert_equal 3, t3.token_number

    assert_equal ', ', t0.presentation_after
    assert_equal '. ', t1.presentation_after
    assert_equal ', ', t2.presentation_after
    assert_equal '. ', t3.presentation_after

    @sentence_first_in_sd.append_next_sentence!
    @sentence_first_in_sd.tokens.reload

    assert @sentence_first_in_sd.presentation_before.blank?
    assert_equal 'Some text', @sentence_first_in_sd.presentation_after

    assert_equal 4, @sentence_first_in_sd.tokens.count

    t0, t1, t2, t3 = @sentence_first_in_sd.tokens

    assert_equal @t0, t0
    assert_equal @t1, t1
    assert_equal @t2, t2
    assert_equal @t3, t3

    assert_equal 0, t0.token_number
    assert_equal 1, t1.token_number
    assert_equal 2, t2.token_number
    assert_equal 3, t3.token_number

    assert_equal ', ', t0.presentation_after
    assert_equal '. ', t1.presentation_after
    assert_equal ', ', t2.presentation_after
    assert_equal '. ', t3.presentation_after
  end
end
