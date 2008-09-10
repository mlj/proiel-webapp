class JavascriptsController < ApplicationController
  layout nil

  # Generates javascript suitable to control a sequence of dynamic
  # morphology drop-downs.
  def dynamic_pos
    @language = params[:id].to_sym
  end

  def morphtag_presentation
    @summaries = {}
    @abbreviations = {}

    PROIEL::MORPHOLOGY.each_pair do |field, tags|
      s = {}
      a = {}
      tags.values.each do |tag| 
        a[tag.code] = tag.description(:style => :abbreviation)
        s[tag.code] = tag.description
      end
      @summaries[field] = s 
      @abbreviations[field] = a 
    end
  end

  # Returns a Javascript representation of valid dependency relations
  def relations
    @relations = PROIEL::RELATIONS
    @inferences = PROIEL::INFERENCES
  end

  # Hides the currently active announcement messages in this session.
  def hide_announcement
    session[:announcement_hide_time] = Time.now
  end
end
