class JavascriptsController < ApplicationController
  layout nil

  # Generates JavaScript suitable to control a sequence of dynamic
  # morphology drop-downs.
  def dynamic_pos
    @language = params[:id].to_sym
    poses = MorphtagConstraints.instance.tag_space(@language).map { |tag| tag[0..1] }.uniq.map { |tag| PartOfSpeech.new(tag) }
    @pos_summaries = Hash[*poses.map { |pos| [pos.tag, pos.summary] }.flatten]
    @pos_abbreviated_summaries = Hash[*poses.map { |pos| [pos.tag, pos.abbreviated_summary] }.flatten]
    @pos_values = poses.map(&:tag)
  end

  # Returns a Javascript representation of valid dependency relations
  def relations
    @relations = Relation.primary.map(&:tag)
    @inferences = PROIEL::INFERENCES
  end
end
