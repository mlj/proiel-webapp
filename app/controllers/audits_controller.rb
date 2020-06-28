#--
#
# Copyright 2007-2016 University of Oslo
# Copyright 2007-2017 Marius L. Jøhndal
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

class AuditsController < ApplicationController
  respond_to :html, :xml
  before_action :is_annotator?

  def index
    if params[:sentence_id]
      # Grab changes related to this sentence, i.e. the object itself and
      # its tokens.
      sentence = Sentence.find(params[:sentence_id])
      tokens = @sentence.tokens

      objs = []
      objs << [Sentence, [sentence.id]]
      objs << [Token, tokens.pluck(:id)]
      s = objs.map { |k, v| "(auditable_type = '#{k}' AND auditable_id IN (?))" }.join(' OR ')
      v = objs.map { |_, v2| v2 }

      audits = Audited::Audit.where(s, *v)
    elsif params[:user_id]
      # Grab changes by this user.
      @user = User.find(params[:user_id])
      audits = @user.audits
    else
      audits = Audited::Audit
    end

    # Conceptually we want to order by created_at but ordering by ID is
    # *much* faster and produces the same result. The gem imposes ordering by
    # `version` so it too needs to be overriden using `reorder`.
    @audits = audits.reorder(id: :desc).page(current_page)

    respond_with @audits
  end

  def show
    @audit = Audited::Audit.find(params[:id])

    respond_with @audit
  end
end
