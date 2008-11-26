#--
#
# Copyright 2007, 2008 University of Oslo
# Copyright 2007, 2008 Marius L. Jøhndal
#
# This file is part of the PROIEL web application.
#
# The PROIEL web application is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# The PROIEL web application is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the PROIEL web application.  If not, see
# <http://www.gnu.org/licenses/>.
#
#++
class AlignmentsController < ApplicationController
  def show
    @source_division = SourceDivision.find(params[:id])
    @alignments = @source_division.sentence_alignments(:automatic => false)
  end

  def edit
    @source_division = SourceDivision.find(params[:id])
    @alignments = @source_division.sentence_alignments(:automatic => true)
  end

  def set_anchor
    sentence = Sentence.find(params[:id])
    sentence.sentence_alignment = Sentence.find(params[:anchor_id])
    sentence.automatic_alignment = false
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments(:automatic => true)

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def set_unanchored
    sentence = Sentence.find(params[:id])
    sentence.sentence_alignment = nil
    sentence.automatic_alignment = false
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments(:automatic => true)

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def set_unalignable
    sentence = Sentence.find(params[:id])
    sentence.unalignable = true
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments(:automatic => true)

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def set_alignable
    sentence = Sentence.find(params[:id])
    sentence.unalignable = false
    sentence.save!

    @alignments = sentence.source_division.sentence_alignments(:automatic => true)

    render :update do |page|
      page.replace('alignment-view', :partial => 'alignment')
    end
  end

  def commit
    @source_division = SourceDivision.find(params[:id])
    @alignments = @source_division.sentence_alignments(:automatic => true)

    Sentence.transaction do
      @alignments.each do |a|
        if a.left.first and a.right.first
          secondary_sentence = a.right.first.first
          primary_sentence = a.left.first.first

          unless secondary_sentence.sentence_alignment
            secondary_sentence.sentence_alignment = primary_sentence
            secondary_sentence.automatic_alignment = true
            secondary_sentence.save!
          end
        end
      end
    end

    redirect_to :action => "show"
  end

  def uncommit
    @source_division = SourceDivision.find(params[:id])
    Sentence.transaction do
      @source_division.sentences.find(:all, :conditions => { :automatic_alignment => true }).each do |s|
        s.sentence_alignment = nil
        s.automatic_alignment = false
        s.save!
      end
    end

    redirect_to :action => "show"
  end
end
