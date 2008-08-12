class AnnotationsController < ReadOnlyController
  before_filter :is_reviewer?, :only => [:flag_as_reviewed, :flag_as_not_reviewed]
  before_filter :find_parents

  protected

  def find_parents
    @parent = @source = Source.find(params[:source_id]) if params[:source_id]
  end

  private

  def object
    @sentence = Sentence.find(params[:id])
  end

  def collection
    @sentences = (@parent ? @parent.sentences : Sentence).search(params[:query], :page => current_page)
  end

  public

  def flag_as_reviewed
    @sentence = Sentence.find(params[:id])

    versioned_transaction do
      @sentence.set_reviewed!(User.find(session[:user_id]))
      flash[:notice] = 'Annotation was successfully updated.'
      redirect_to(annotation_path(@sentence))
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    render :action => "show"
  end

  def flag_as_not_reviewed
    @sentence = Sentence.find(params[:id])

    versioned_transaction do
      @sentence.unset_reviewed!(User.find(session[:user_id]))
      flash[:notice] = 'Annotation was successfully updated.'
      redirect_to(annotation_path(@sentence))
    end
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    render :action => "show"
  end
end
