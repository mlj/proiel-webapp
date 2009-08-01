#--
#
# Copyright 2007, 2008, 2009 University of Oslo
# Copyright 2007, 2008, 2009 Marius L. Jøhndal
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
class SourceDivision < ActiveRecord::Base
  belongs_to :source
  has_many :sentences, :order => 'sentence_number ASC'
  has_many :tokens, :through => :sentences, :order => 'sentences.sentence_number ASC, token_number ASC'
  belongs_to :aligned_source_division, :class_name => "SourceDivision"

  # Returns the previous source division in a source.
  def previous
    source.source_divisions.find(:first, :conditions =>  ["position < ?", position], :order => "position DESC")
  end

  # Returns the next source division in a source.
  def next
    source.source_divisions.find(:first, :conditions =>  ["position > ?", position], :order => "position ASC")
  end

  include Ordering

  def ordering_attribute
    :position
  end

  def ordering_collection
    source.source_divisions
  end

  # Returns the parent object for the source division, which will be its
  # source.
  def parent
    source
  end

  # Returns the completion state of the source division.
  def completion
    if sentences.exists?(["reviewed_by IS NULL and annotated_by IS NULL"])
      :unannotated
    elsif sentences.exists?(["reviewed_by IS NULL"])
      :annotated
    else
      :reviewed
    end
  end

  include References

  def reference_parent
    parent
  end

  # Re-indexes the references.
  def reindex!
    SourceDivision.transaction { sentences.find_each(&:reindex!) }
  end

  # Returns the presentation level as UTF-8 HTML.
  #
  # === Options
  #
  # <tt>:section_numbers</tt> -- If true, output will include section
  # numbers.
  #
  # <tt>:length_limit</tt> -- If set, will limit the length of
  # the formatted sentence to the given number of words and append an
  # ellipsis if the sentence exceeds that limit. If a negative number
  # is given, the ellipis is prepended to the sentence. The conversion
  # will also use a less rich form of HTML.
  def presentation_as_html(options = {})
    xsl_params = {
      :language_code => "'#{language.iso_code.to_s}'",
      :default_language_code => "'en'"
    }
    xsl_params[:sectionNumbers] = "'1'" if options[:section_numbers]

    presentation_as(APPLICATION_CONFIG.presentation_as_html_stylesheet, xsl_params)
  end

  private

  def presentation_as(stylesheet_method, xsl_params = {})
    parser = XML::Parser.string('<presentation>' + presentation + '</presentation>')

    begin
      xml = parser.parse
    rescue LibXML::XML::Parser::ParseError => p
      raise "Invalid presentation string for sentence #{id}: #{p}"
    end

    s = stylesheet_method.apply(xml, xsl_params).to_s

    # FIXME: libxslt-ruby bug #21615: XML decl. shows up in the output
    # even when omit-xml-declaration is set
    s.gsub!(/<\?xml version="1\.0" encoding="UTF-8"\?>\s+/, '')

    # FIXME: Why is there an additional CR at the end of the string?
    s.chomp!

    s
  end

  public
  # Returns sentence alignments for the source division.
  #
  # ==== Options
  # <tt>:automatic</tt> -- If true, will automatically align sentences
  # whose sentence alignment has not been set.
  def sentence_alignments(options = {})
    if aligned_source_division
      base_sentences = sentences
      aligned_sentences = aligned_source_division.sentences

      align_sentences(aligned_sentences, base_sentences, options[:automatic])
    else
      []
    end
  end

  # Returns the language for the source division. This is a
  # convenience method for +source_division.source.language+.
  def language
    source.language
  end

  protected

  def self.search(query, options = {})
    options[:conditions] ||= ['title LIKE ?', "%#{query}%"] unless query.blank?

    paginate options
  end
end
