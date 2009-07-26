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
class Source < ActiveRecord::Base
  validates_presence_of :code
  validates_presence_of :title
  validates_uniqueness_of :title
  validates_presence_of :language
  validates_each :metadata do |record, attr, value|
    record.errors.add :tei_header, "invalid: #{value.error_message}" unless value.valid?
  end
  validates_presence_of :tracked_references

  belongs_to :language
  has_many :source_divisions, :order => [:position]
  has_many :bookmarks

  composed_of :metadata, :class_name => 'Metadata', :mapping => %w(tei_header)
  serialize :tracked_references
  serialize :reference_format

  has_many :dependency_alignment_terminations

  # Returns the completion state of the source division.
  def completion
    c = source_divisions.map(&:completion).uniq
    if c.include?(:unannotated)
      :unannotated
    elsif c.include?(:annotated)
      :annotated
    else
      :reviewed
    end
  end

  include References

  protected

  # Returns the reference-format for this source division.
  def citation_format
    reference_format[:source] || ""
  end

  def reference_fields
    { :title => title }
  end

  public

  include References

  # Re-indexes the references.
  def reindex!
    Source.transaction { source_divisions.find_each(&:reindex!) }
  end

  protected

  def self.search(query, options)
    options[:conditions] ||= ["title LIKE ?", "%#{query}%"] unless query.blank?

    paginate options
  end
end
