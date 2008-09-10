class WizardController < ApplicationController
  before_filter :is_annotator?

  def index
    level = params[:wizard] ? params[:wizard][:level].to_sym : nil 
    set_state(level, 1)
  end

  def verify_sentence_divisions
    change_state(:review => 2)
  end

  def verify_morphtags
    change_state(:review => 3)
  end

  def verify_dependencies
    change_state(:annotation => 5, :review => 4)
  end

  def save_sentence_divisions
    change_state(:annotation => 2, :review => 1)
  end

  def save_morphtags
    change_state(:annotation => 3, :review => 2)
  end

  def save_dependencies
    change_state(:annotation => 4, :review => 3)
  end

  def modify_sentence_divisions
    change_state(:review => 5)
  end

  def modify_morphtags
    change_state(:review => 6)
  end

  def modify_dependencies
    change_state(:annotation => 3, :review => 7)
  end

  def skip_sentence_divisions
    change_state(:annotation => 5, :review => 8)
  end

  def skip_morphtags
    change_state(:annotation => 5, :review => 8)
  end

  def skip_dependencies
    change_state(:annotation => 5, :review => 8)
  end

  private

  def next_sentence(bm, level)
    if bm.step_bookmark!
      set_state(level, 1)
    else
      bm.destroy
      render :text => 'End of assigned text reached', :layout => true
    end
  end

  def set_state(level, state)
    # Grab bookmark, if any
    bm = Bookmark.find_flow_bookmark(User.find(session[:user_id]), level)

    if bm
      case level
      when :annotation
        case state
        when 1:
          render_state(bm, :annotation, :alignments, :edit)
        when 2:
          render_state(bm, :annotation, :morphtags, :edit)
        when 3:
          render_state(bm, :annotation, :dependencies, :edit)
        when 4:
          begin
            bm.sentence.set_annotated!(User.find(session[:user_id]))
            render_state(bm, :annotation, :dependencies, :verify_or_modify)
          rescue ActiveRecord::RecordInvalid => invalid
            flash[:error] = invalid.record.errors.full_messages.join('<br>')
            set_state(level, 3)
          end
        when 5:
          next_sentence(bm, :annotation)
        else
          raise "Invalid wizard state"
        end
      when :review
        case state
        when 1:
          render_state(bm, :review, :alignments, :verify_or_modify)
        when 2:
          render_state(bm, :review, :morphtags, :verify_or_modify)
        when 3:
          render_state(bm, :review, :dependencies, :verify_or_modify)
        when 4:
          begin
            bm.sentence.set_reviewed!(User.find(session[:user_id]))
            next_sentence(bm, :review)
          rescue ActiveRecord::RecordInvalid => invalid
            flash[:error] = invalid.record.errors.full_messages.join('<br>')
            set_state(level, 7)
          end
        when 5:
          render_state(bm, :review, :alignments, :edit)
        when 6:
          render_state(bm, :review, :morphtags, :edit)
        when 7:
          render_state(bm, :review, :dependencies, :edit)
        when 8:
          next_sentence(bm, :review)
        else
          raise "Invalid wizard state"
        end
      else
        raise "Invalid wizard level"
      end
    else
      render :text => 'No assigned text', :layout => true
    end
  end

  def render_state(bm, level, step, mode)
    controller = (step == :alignment || step == :alignments ? 'sentence_divisions' : step.to_s)

    case mode
    when :verify
      action = 'show'
      buttons = { :skip => true, :verify => true }
    when :verify_or_modify
      action = 'show'
      buttons = { :skip => true, :verify => true, :edit => true }
    when :edit
      action = 'edit'
      buttons = { :skip => true }
    else
      raise "Invalid mode"
    end
    redirect_to :controller => controller, :action => action, :annotation_id => bm.sentence, 
      :wizard => buttons.merge({ :level => level })
  end

  def change_state(levels)
    level = params[:wizard] ? params[:wizard][:level].to_sym : nil
    if levels.has_key?(level)
      set_state(level, levels[level])
    else
      raise "Invalid wizard state #{level}"
    end
  end
end
