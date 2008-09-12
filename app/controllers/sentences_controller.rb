class SentencesController < ResourceController::Base
  before_filter :find_parents
  before_filter :is_reviewer?, :only => [:destroy]
  actions :all, :except => [:new, :edit, :create, :update, :destroy] # we add our own destroy later

  show.before do
    @tokens = @sentence.tokens.search(params[:query], :page => current_page)
  end

  protected

  def find_parents
    @parent = @source = Source.find(params[:source_id]) if params[:source_id]
  end

  private
  
  def collection
    @sentences = (@parent ? @parent.sentences : Sentence).search(params[:query], :page => current_page)
  end

  public

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

      Sentence.transaction do
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
