class SentencesController < InheritedResources::Base
  actions :all, :except => [:new, :create]

  before_filter :find_parents
  before_filter :is_annotator?, :only => [:merge, :tokenize, :resegment_edit, :resegment_update]
  before_filter :is_reviewer?, :only => [:edit, :update, :flag_as_reviewed, :flag_as_not_reviewed]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @sentence = Sentence.find(params[:id])

    @tokens = @sentence.tokens.search(params[:query], :page => current_page)
    @semantic_tags = @sentence.semantic_tags

    show!
  end

  def update
    if params[:sentence]
      if params[:sentence][:presentation].blank?
        params[:sentence][:presentation] = nil
      else
        params[:sentence][:presentation] = params[:sentence][:presentation].mb_chars.normalize(UNICODE_NORMALIZATION_FORM)
      end
    end

    update!
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
      if @sentence.valid? and @sentence.next.valid?
        @sentence.append_next_sentence!
        flash[:notice] = 'Sentences successfully merged.'
      else
        flash[:error] = 'One of the sentences is invalid.'
      end
    else
      flash[:error] = 'Next sentence not found.'
    end

    respond_to do |format|
      format.html { redirect_to @sentence }
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')

    redirect_to :action => 'show'
  end

  def flag_as_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.set_reviewed!(current_user)
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')
    redirect_to @sentence
  end

  def flag_as_not_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.unset_reviewed!(current_user)
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
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')
    redirect_to @sentence
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
  rescue ActiveRecord::RecordInvalid => invalid
    if invalid.record.id.nil?
      flash[:error] = invalid.record.errors.full_messages.map { |m| "New #{invalid.record.class}: #{m}" }.join('<br>')
    else
      flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')
    end

    redirect_to :action => 'resegment_edit'
  end
end
