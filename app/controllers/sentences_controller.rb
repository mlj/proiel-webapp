#--
#
# Copyright 2009, 2010, 2011 University of Oslo
# Copyright 2009, 2010, 2011 Marius L. Jøhndal
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

class SentencesController < InheritedResources::Base
  actions :all, :except => [:new, :create, :edit, :update]

  before_filter :find_parents
  before_filter :is_reviewer?, :only => [:edit, :update, :flag_as_reviewed, :flag_as_not_reviewed]

  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found

  def show
    @sentence = Sentence.find(params[:id])

    @tokens = @sentence.tokens.search(params[:query], :page => current_page)
    @semantic_tags = @sentence.semantic_tags

    show!
  end

  protected

  def find_parents
    @parent = @source = Source.find(params[:source_id]) if params[:source_id]
  end

  private

  def collection
    @sentences = (@parent ? Sentence.by_source(@parent) : Sentence).search(params[:query], :page => current_page)
  end

  public

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
end
