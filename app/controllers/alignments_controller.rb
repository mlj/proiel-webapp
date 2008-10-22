class AlignmentsController < ApplicationController
  def edit
    @source_division = SourceDivision.find(params[:id])
    @alignments = @source_division.sentence_alignments
  end

  def set_anchor
    sentence = Sentence.find(params[:id])
    sentence.sentence_alignment = Sentence.find(params[:anchor_id])
    sentence.automatic_alignment = false
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def set_unanchored
    sentence = Sentence.find(params[:id])
    sentence.sentence_alignment = nil
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def set_unalignable
    sentence = Sentence.find(params[:id])
    sentence.unalignable = true
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def set_alignable
    sentence = Sentence.find(params[:id])
    sentence.unalignable = false
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end
end
