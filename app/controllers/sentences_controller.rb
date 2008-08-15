class SentencesController < ApplicationController
  before_filter :is_reviewer?, :only => [:destroy]

  # GET /sentences
  # GET /sentences.xml
  def index
    @sentences = Sentence.search(params.slice(:source, :book, :chapter, :sentence_number), params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @sentences }
    end
  end

  # GET /sentence/1
  # GET /sentence/1.xml
  def show
    @sentence = Sentence.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @sentence }
    end
  end

  # DELETE /sentence/1
  # DELETE /sentence/1.xml
  #
  # Destroys the sentence. This works by moving all tokens in the sentence to the
  # previous sentence in the linear order before actually removing the sentence.
  # If there is no previous sentence, then destruction will fail.
  def destroy
    @sentence = Sentence.find(params[:id])

    if @sentence.has_previous_sentence?
      previous_sentence = @sentence.previous_sentence

      versioned_transaction do
        previous_sentence.append_first_tokens_from_next_sentence!(@sentence.tokens.length)
        @sentence.destroy
        previous_sentence.clear_dependencies!
      end

      respond_to do |format|
        flash[:notice] = 'Successfully destroyed.'
        format.html { redirect_to(previous_sentence) }
        format.xml  { head :ok }
      end
    else
      respond_to do |format|
        flash[:error] = 'Sentence cannot be destroyed.'
        format.html { redirect_to(@sentence) }
        format.xml  { render :status => :unprocessable_entity }
      end
    end
  end
end
