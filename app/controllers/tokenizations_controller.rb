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
class TokenizationsController < ApplicationController
  before_filter :is_annotator?, :only => [:edit, :update]

  def edit
    @sentence = Sentence.find(params[:sentence_id])
  end

  def update
    @sentence = Sentence.find(params[:sentence_id])

    parser = XML::Parser.string('<presentation>' + params[:new_presentation] + '</presentation>')
    xml = parser.parse

    s = APPLICATION_CONFIG.presentation_from_editable_html_stylesheet.apply(xml, {}).to_s

    # FIXME: libxslt-ruby bug #21615: XML decl. shows up in the output
    # even when omit-xml-declaration is set
    s.gsub!(/<\?xml version="1\.0" encoding="UTF-8"\?>\s+/, '')

    # FIXME: The xslt processor ignores all instructions and inserts
    # non-sense "\n" characters all over the place. That seriously
    # messes with out code. Try to mend it by removing all "\n"
    # characters.
    s.gsub!("\n", '')

    # Check the invariant: the content-level text must remain constant
    t1 = @sentence.presentation_as_text
    t2 = @sentence.presentation_as_text
    raise "Presentation invariant failed:\n#{t1} !=\n#{t2}" unless t1 == t2

    Sentence.transaction do
      @sentence.presentation = s
      @sentence.save!
      @sentence.tokenize!
    end

    flash[:notice] = 'Tokenization updated.'
    redirect_to @sentence
  rescue LibXML::XML::Parser::ParseError => p
    flash[:error] = "Error parsing XML"
    redirect_to :action => 'edit'
  rescue ActiveRecord::RecordInvalid => invalid
    flash[:error] = invalid.record.errors.full_messages.join('<br>')
    redirect_to :action => 'edit'
  end
end
