require 'proiel'

class JavascriptsController < ApplicationController
  layout nil

  # Generates javascript suitable to control a sequence of dynamic
  # morphology drop-downs.
  def dynamic_pos
    language = params[:id].to_sym

    @major_values = MorphTag.pos_values(language).collect { |e| [e[0], e[1]] }.uniq
    @minor_values = MorphTag.pos_values(language).collect { |e| [e[0], e[3], e[2]] }
    @mood_values = MorphTag.field_values(:mood, language).collect { |e| [e[0], e[1], e[4], e[3]] }.uniq
    @person_values = MorphTag.field_values(:person, language)
    @number_values = MorphTag.field_values(:number, language)
    @tense_values = MorphTag.field_values(:tense, language)
    @voice_values = MorphTag.field_values(:voice, language)
    @gender_values = MorphTag.field_values(:gender, language)
    @case_values = MorphTag.field_values(:case, language)
    @degree_values = MorphTag.field_values(:degree, language)
  end

  def morphtag_presentation
    @summaries = {}
    @abbreviations = {}

    MORPHOLOGY.each_pair do |field, tags|
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
    @relations = RELATIONS
    @inferences = INFERENCES
  end
end
