class SentencesController < ResourceController::Base
  before_filter :find_parents
  before_filter :is_annotator?, :only => [:merge, :tokenize, :resegment_edit, :resegment_update]
  before_filter :is_reviewer?, :only => [:edit, :update, :flag_as_reviewed, :flag_as_not_reviewed]
  actions :all, :except => [:new, :create]

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

  # Merges this sentence with the next sentence.
  def merge
    @sentence = Sentence.find(params[:id])

    if @sentence.has_next?
      @sentence.append_next_sentence!
      flash[:notice] = 'Sentences successfully merged.'
    else
      flash[:error] = 'Sentence cannot be merged.'
    end

    respond_to do |format|
      format.html { redirect_to @sentence }
    end
  end

  def flag_as_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.set_reviewed!(User.find(session[:user_id]))
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to @sentence
  end

  def flag_as_not_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.unset_reviewed!(User.find(session[:user_id]))
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to @sentence
  end

  def tokenize
    @sentence = Sentence.find(params[:id])
    @sentence.tokenize!

    respond_to do |format|
      flash[:notice] = 'Sentence was successfully tokenized.'
      format.html { redirect_to @sentence }
    end
  end

  def resegment_edit
    @sentence = Sentence.find(params[:id])
  end

  def resegment_update
    @sentence = Sentence.find(params[:id])

    l = params[:sentence][:presentation]

    Sentence.transaction do
      @sentence.split_sentence!(l)
      @sentence.save!
    end

    redirect_to @sentence
  end
end
