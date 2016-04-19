class SchemasController < ApplicationController
  def show
    language_tag = params[:id]
    respond_to do |format|
      format.json do
        render json: {
          explanations: {
            part_of_speech_tags: PartOfSpeechTag.to_hash.sort_by(&:first).map { |tag, explanation| [tag, { long: explanation['summary'], short: explanation['abbreviated_summary'] } ] }.to_h,
            msd_tags: MorphFeatures::MORPHOLOGY_ALL_SUMMARIES.map { |tag, v| [tag, v.map { |field, explanation| [field, { long: explanation['summary'], short: explanation['abbreviated_summary'] } ] }.to_h] }.to_h,
          },
          tag_space: MorphFeatures::pos_and_morphology_tag_space(language_tag),
          field_sequence: [:pos] + MorphFeatures::MORPHOLOGY_PRESENTATION_SEQUENCE,
          positions: MorphFeatures::MORPHOLOGY_POSITIONAL_TAG_SEQUENCE.zip((0..MorphFeatures::MORPHOLOGY_LENGTH).to_a).to_h,
          relation_inferences: Proiel::INFERENCES,
          relations: RelationTag,
        }
      end
    end
  end
end
