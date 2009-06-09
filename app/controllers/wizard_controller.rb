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
    @sentence.set_annotated!(User.find(session[:user_id]))

    next_sentence
  end

  def next_sentence
    User.find(session[:user_id]).shift_assigned_sentence!
    redirect_to :action => :edit_morphtags
  end

  protected

  def find_sentence
    @sentence = User.find(session[:user_id]).first_assigned_sentence
  end
end
