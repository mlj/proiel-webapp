class WizardController < ApplicationController
  before_action :is_annotator?
  before_action :find_sentence

  def index
    redirect_to :action => :edit_morphtags
  end

  def edit_morphtags
    unless @sentence
      render :text => 'End of assigned text reached', :layout => true
    end
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
    begin
      @sentence.set_annotated!(current_user)

      next_sentence
    rescue ActiveRecord::RecordInvalid => invalid
      flash[:error] = invalid.record.errors.full_messages.join('<br>')
      save_dependencies
    end
  end

  def next_sentence
    current_user.shift_assigned_sentence!
    redirect_to :action => :edit_morphtags
  end

  protected

  def find_sentence
    @sentence = current_user.first_assigned_sentence
    if @sentence
      @sentence_window = @sentence.sentence_window.includes(:tokens).all
      @source_division = @sentence.source_division
      @source = @source_division.source
    end
  end
end
