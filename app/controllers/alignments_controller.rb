class AlignmentsController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update, :flag_bad_alignment]

  def show
    @sentence = Sentence.find(params[:annotation_id])

    @sentence_before = @sentence.prev ? @sentence.prev.nonempty_tokens : nil
    @sentence_after = @sentence.succ ? @sentence.succ.nonempty_tokens : nil
    @sentence_x = @sentence.nonempty_tokens
  end

  def edit
    @modifications = params[:modifications] || []

    @sentence = Sentence.find(params[:annotation_id])
    @sentence_before = @sentence.prev ? @sentence.prev.nonempty_tokens : nil
    @sentence_after = @sentence.succ ? @sentence.succ.nonempty_tokens : nil

    standard_source = @sentence.source.aligned_with

    if standard_source
      @standard_sentence = Sentence.find(:first, :conditions => { :source_id => standard_source, :book_id => @sentence.book_id, :chapter => @sentence.chapter })
      @standard_sentence_before = @standard_sentence.prev ? @standard_sentence.prev.nonempty_tokens : nil
      @standard_sentence_after = @standard_sentence.succ ? @standard_sentence.succ.nonempty_tokens : nil

      #FIXME
      @standard_sentence_x = @standard_sentence.nonempty_tokens
    end

    #FIXME
    @sentence_x = @sentence.nonempty_tokens

    # Apply the requested modifications
    # FIXME: deal with clitics properly
    @modifications.each do |modification|
      case modification
      when 'shorten_first'
        @sentence_before.push(@sentence_x.shift)
        @sentence_before.push(@sentence_x.shift) if @sentence_x.first.punctuation?
      when 'expand_first'
        @sentence_x.unshift(@sentence_before.pop) if @sentence_before.last.punctuation?
        @sentence_x.unshift(@sentence_before.pop)
      when 'shorten_last'
        @sentence_after.unshift(@sentence_x.pop) if @sentence_x.last.punctuation?
        @sentence_after.unshift(@sentence_x.pop)
      when 'expand_last'
        @sentence_x.push(@sentence_after.shift)
        @sentence_x.push(@sentence_after.shift) if @sentence_after.first.punctuation?
      else
        raise "Invalid alignment modification #{modification}"
      end
    end
  end
  
  def update
    sentence = Sentence.find(params[:annotation_id])
    modifications = params[:modifications] || []

    # Compute actual difference
    # FIXME: DRY this up by using first/last in edit_sentence_alignment instead of the modifications array 
    first, last = 0, 0
    modifications.each do |modification|
      case modification
      when 'shorten_first'
        first -= 1
      when 'expand_first'
        first += 1
      when 'shorten_last'
        last -= 1
      when 'expand_last'
        last += 1
      else
        raise "Invalid alignment modification #{modification}"
      end
    end
    
    # Perform actions
    Sentence.transaction(session[:user]) do
      #FIXME: does this work within an transaction. cp. update_dependencies 
      
      first.abs.times { sentence.prev.append_nonempty_token_from_next_sentence! } if first < 0

      first.times { sentence.prepend_nonempty_token_from_previous_sentence! } if first > 0

      last.abs.times { sentence.succ.prepend_nonempty_token_from_previous_sentence! } if last < 0

      last.times { sentence.append_nonempty_token_from_next_sentence! } if last > 0

      # Now flush dependencies from affected sentences.
      unless first.zero? && last.zero?
        sentence.clear_dependencies!
        sentence.prev.clear_dependencies! unless first.zero?
        sentence.succ.clear_dependencies! unless last.zero?
      end
    end

    if params[:wizard]
      redirect_to :controller => :wizard, :action => :save_alignments, :wizard => params[:wizard]
    else
      redirect_to :action => 'show'
    end
  end

  # FIXME: eliminate this when alignment editing is re-enabled
  def flag_bad_alignment
    sentence = Sentence.find(params[:annotation_id])
    Sentence.transaction(session[:user]) do
      sentence.bad_alignment_flag = true
      sentence.save!
    end
    if params[:wizard]
      redirect_to :controller => :wizard, :action => "skip_alignments", :wizard => params[:wizard]
    else
      redirect_to :action => 'edit'
    end
  end
end
