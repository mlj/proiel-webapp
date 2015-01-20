#--
#
# Copyright 2009, 2010, 2011, 2012, 2015 University of Oslo
# Copyright 2009, 2010, 2011, 2012, 2015 Marius L. Jøhndal
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

class SentencesController < ApplicationController
  respond_to :html
  before_filter :is_reviewer?, :only => [:edit, :update, :flag_as_reviewed, :flag_as_not_reviewed]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @sentence = Sentence.includes(:source_division => [:source],
                                  :tokens => [:lemma, :audits, :notes],
                                  :notes => [],
                                  :audits => [:auditable]).find(params[:id])
    @source_division = @sentence.source_division
    @source = @source_division.try(:source)

    @sentence_window = @sentence.sentence_window.includes(:tokens)
    @semantic_tags = @sentence.semantic_tags

    @notes = @sentence.notes
    @audits = @sentence.audits

    respond_with @sentence
  end

  def edit
    @sentence = Sentence.includes(:source_division => [:source]).find(params[:id])
    @source_division = @sentence.try(:source_division)
    @source = @source_division.try(:source)

    respond_with @sentence
  end

  def update
    normalize_unicode_params! params[:sentence], :presentation_before, :presentation_after

    @sentence = Sentence.find(params[:id])
    @sentence.update_attributes(params[:sentence])

    flash[:notice] = 'Sentence was successfully updated.'

    respond_with @sentence
  end

  def flag_as_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.set_reviewed!(current_user)
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.map { |m| "#{invalid.record.class} #{invalid.record.id}: #{m}" }.join('<br>')
    redirect_to @sentence
  end

  def flag_as_not_reviewed
    @sentence = Sentence.find(params[:id])

    @sentence.unset_reviewed!(current_user)
    flash[:notice] = 'Sentence was successfully updated.'
    redirect_to @sentence
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to @sentence
  end

  def export
    @sentence = Sentence.find(params[:id])

    result = LatexGlossingExporter.instance.generate(@sentence)

    respond_to do |format|
      format.html { send_data result, disposition: 'inline', type: :html }
    end
  end
end
