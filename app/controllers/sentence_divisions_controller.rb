class SentenceDivisionsController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update, :flag_bad_alignment]

  # GET /annotations/1/sentence_division
  def show
    @sentence = Sentence.find(params[:annotation_id])
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


  # GET /annotations/1/sentence_division/edit
  def edit
    @sentence = Sentence.find(params[:annotation_id])

    @shorten = _edit_cover_length(@sentence.nonempty_tokens, :last)
    @expand = _edit_cover_length(@sentence.has_next_sentence? ? @sentence.next_sentence.nonempty_tokens : [], :first)
    @fixed = @sentence.nonempty_tokens.first(@sentence.nonempty_tokens.length - @shorten.length)
  end
  
  # PUT /annotations/1/sentence_division
  def update
    sentence = Sentence.find(params[:annotation_id])

    if sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :annotation_id => params[:annotation_id]
      return
    end

    change = params[:change] || 0 
    change = change.to_i

    versioned_transaction do
      # First flush dependencies from affected sentences so that we don't have to bother with them.
      # They won't make sense after this anyway.
      unless change.zero?
        sentence.clear_dependencies!
        sentence.next_sentence.clear_dependencies!

        sentence.next_sentence.prepend_last_tokens_from_previous_sentence!(change.abs) if change < 0
        sentence.append_first_tokens_from_next_sentence!(change) if change > 0
      end
    end

    if params[:wizard]
      redirect_to :controller => :wizard, :action => :save_sentence_divisions, :wizard => params[:wizard]
    else
      redirect_to :action => 'show'
    end
  rescue ActiveRecord::RecordInvalid => invalid 
    flash[:error] = invalid.record.errors.full_messages
    redirect_to :action => 'edit', :wizard => params[:wizard]
  end

  # FIXME: eliminate this when alignment editing is re-enabled
  def flag_bad_alignment
    sentence = Sentence.find(params[:annotation_id])

    if sentence.is_reviewed? and not user_is_reviewer?
      flash[:error] = 'You do not have permission to update reviewed sentences'
      redirect_to :action => 'edit', :wizard => params[:wizard], :annotation_id => params[:annotation_id]
      return
    end

    versioned_transaction do
      sentence.bad_alignment_flag = true
      sentence.save!
    end

    if params[:wizard]
      redirect_to :controller => :wizard, :action => "skip_sentence_divisions", :wizard => params[:wizard]
    else
      redirect_to :action => 'show', :annotation_id => sentence
    end
  rescue ActiveRecord::RecordInvalid => invalid 
    flash[:error] = invalid.record.errors.full_messages
    redirect_to :action => 'edit', :wizard => params[:wizard]
  end
end
