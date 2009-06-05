class SentencesController < ResourceController::Base
  before_filter :find_parents
  before_filter :is_reviewer?, :only => [:destroy]
  actions :all, :except => [:new, :edit, :create, :update, :destroy] # we add our own destroy later

  show.before do
    @tokens = @sentence.tokens.search(params[:query], :page => current_page)
  end

  update.before do
    if params[:sentence]
      if params[:sentence][:presentation].blank?
        params[:sentence][:presentation] = nil
      else
        params[:sentence][:presentation] = params[:sentence][:presentation].mb_chars.normalize(UNICODE_NORMALIZATION_FORM)
      end
    end
  end

  protected

  def find_parents
    @parent = @source = Source.find(params[:source_id]) if params[:source_id]
  end

  private
  
  def collection
    @sentences = (@parent ? Sentence.by_source(@parent) : Sentence).search(params[:query], :page => current_page)
  end

  public

  # Destroys the sentence. This works by moving all tokens in the sentence to the
  # previous sentence in the linear order before actually removing the sentence.
  # If there is no previous sentence, then destruction will fail.
  def destroy
    @sentence = Sentence.find(params[:id])

    if @sentence.has_previous_sentence?
      previous_sentence = @sentence.previous_sentence
      previous_sentence.append_next_sentence!

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
