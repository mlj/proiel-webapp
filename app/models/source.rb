#--
#
# Copyright 2007, 2008, 2009, 2010, 2011 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011 Marius L. Jøhndal
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
  validates_presence_of :citation_part

  acts_as_audited :except => [:citation_part]

  composed_of :language, :converter => Proc.new { |value| value.is_a?(String) ? Language.new(value) : value }

  has_many :source_divisions, :order => [:position]
  has_many :bookmarks

  composed_of :metadata, :class_name => 'Metadata', :mapping => %w(tei_header)

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

  # Returns a citation for the source.
  def citation
    citation_part
  end

  def to_s
    title
  end

  protected

  def self.search(query, options)
    options[:conditions] ||= ["title LIKE ?", "%#{query}%"] unless query.blank?

    paginate options
  end
end
