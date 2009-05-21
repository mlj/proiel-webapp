class JavascriptsController < ApplicationController
  layout nil

  # Generates JavaScript suitable to control a sequence of dynamic
  # morphology drop-downs.
  def dynamic_pos
    @language = params[:id].to_sym
    @pos_summaries = Hash[*PartOfSpeech.all.map { |pos| [pos.tag, pos.summary] }.flatten]
    @pos_abbreviated_summaries = Hash[*PartOfSpeech.all.map { |pos| [pos.tag, pos.abbreviated_summary] }.flatten]
    @pos_values = PartOfSpeech.all.map(&:tag)
  end

  # Returns a Javascript representation of valid dependency relations
  def relations
    @relations = Relation.primary.map(&:tag)
    @inferences = PROIEL::INFERENCES
  end

  # Hides the currently active announcement messages in this session.
  def hide_announcement
    session[:announcement_hide_time] = Time.now
  end
end
