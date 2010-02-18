class WizardController < ApplicationController
  before_filter :is_annotator?
  before_filter :find_sentence

  def index
    redirect_to :action => :edit_morphtags
  end

  def edit_morphtags
    if @sentence
      if @sentence.is_annotated?
        render :show_dependencies
      end
    else
      render :text => 'End of assigned text reached', :layout => true
    end
  end

  # FIXME: duplicated from MorphtagsController
  def auto_complete_for_morphtags_lemma
    @transliterations, c = Language.find_lemma_completions(params[:morphtags][:language], params[:morphtags][:lemma])
    @completions = c.map(&:export_form).sort.uniq

    render :partial => "transliterations/input"
  end

  def edit_dependencies
  end

  def save_dependencies
    begin
      render :show_dependencies
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = invalid.record.errors.full_messages.join('<br>')
      edit_dependencies
    end
  end

  def verify
    @sentence.set_annotated!(current_user)

    next_sentence
  end

  def next_sentence
    current_user.shift_assigned_sentence!
    redirect_to :action => :edit_morphtags
  end

  protected

  def find_sentence
    @sentence = current_user.first_assigned_sentence
  end
end
