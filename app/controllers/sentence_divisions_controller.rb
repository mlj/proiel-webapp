class SentenceDivisionsController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  # GET /sentences/1/sentence_division
  def show
    @sentence = Sentence.find(params[:sentence_id])
  end

  EDIT_LIMIT = 3

  def _edit_cover_length(tokens, function, limit = EDIT_LIMIT)
    # We can get at most n tokens if we want to leave at least one behind
    # so that the sentence isn't orphaned.
    n = tokens.length - 1

    # We only want to grab up to a certain number of tokens.
    n = limit if n > limit

    # Now grab'em
    n > 0 ? tokens.send(function, n) : []
  end


  # GET /sentences/1/sentence_division/edit
  def edit
    @sentence = Sentence.find(params[:sentence_id])

    @shorten = _edit_cover_length(@sentence.tokens.word, :last)
    @expand = _edit_cover_length(@sentence.has_next_sentence? ? @sentence.next_sentence.tokens.word : [], :first)
    @fixed = @sentence.tokens.word.first(@sentence.tokens.word.length - @shorten.length)
  end
  
  # PUT /sentences/1/sentence_division
  def update
    sentence = Sentence.find(params[:sentence_id])

    if sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :sentence_id => params[:sentence_id]
      return
    end

    change = params[:change] || 0 
    change = change.to_i

    Sentence.transaction do
      # First flush dependencies from affected sentences so that we don't have to bother with them.
      # They won't make sense after this anyway.
      unless change.zero?
        sentence.clear_dependencies!
        sentence.next_sentence.clear_dependencies!

        sentence.next_sentence.prepend_last_tokens_from_previous_sentence!(change.abs) if change < 0
        sentence.append_first_tokens_from_next_sentence!(change) if change > 0
      end
    end

    redirect_to :action => 'show'
  rescue ActiveRecord::RecordInvalid => invalid 
    flash[:error] = invalid.record.errors.full_messages
    redirect_to :action => 'edit'
  end
end
