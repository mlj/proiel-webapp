class DependencyAlignmentsController < ApplicationController
  def show
    @sentence = Sentence.find(params[:annotation_id])
    @aligned_sentence = @sentence.sentence_alignment

    unless @aligned_sentence
      flash[:error] = 'Sentence is unaligned'
      redirect_to(annotation_path(@sentence))
    end
  end
end
