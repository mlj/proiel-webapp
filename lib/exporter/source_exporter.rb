# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
# Copyright 2010, 2011, 2012 Dag Haug
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

require 'builder'
require 'metadata'

# Abstract source exporter.
class SourceExporter
  self.cattr_accessor :exportable_sentence_statuses
  self.exportable_sentence_statuses = %w(unannotated annotated reviewed)

  # Creates a new exporter that exports the source +source+.
  #
  # ==== Options
  # reviewed_only:: Only include reviewed sentences. Default: +false+.
  # sem_tags:: Include semantic tags. Default: +false+.
  def initialize(source, options = {})
    options.assert_valid_keys(:reviewed_only, :sem_tags, :source_division, :cycles, :ignore_nils)
    options.reverse_merge! :reviewed_only => false

    @source = source
    @options = options
  end

  # Writes exported data to a file.
  def write(file_name)
    if Sentence.where(:status_tag => self.exportable_sentence_statuses).joins(:source_division => [:source]).where(:source_divisions => {:source_id => @source.id}).exists?
      File.open("#{file_name}.tmp", 'w') do |file|
        write_toplevel!(file) do |context|
          write_source!(context, @source) do |context|
            sds = @source.source_divisions.order(:position)
            sds = sds.where(:id => @options[:source_division]) if @options[:source_division]

            sds.each do |sd|
              write_source_division!(context, sd) do |context|
                ss = sd.sentences.order(:sentence_number)
                ss = ss.where(:status_tag => self.exportable_sentence_statuses)
                ss = ss.reviewed if @options[:reviewed_only]

                ss.each do |s|
                  write_sentence!(context, s) do |context|
                    s.tokens.order(:token_number).includes(:lemma, :slash_out_edges).each do |t|
                      write_token!(context, t)
                    end
                  end
                end
              end
            end
          end
        end
      end

      validate!(file_name)

      File.rename("#{file_name}.tmp", file_name)
    else
      STDERR.puts "Source #{@source.human_readable_id} has no data available for export on this format"
    end
  end

  protected

  def write_toplevel!(file)
    yield file
  end

  def write_source!(context, s)
    yield context
  end

  def write_source_division!(context, sd)
    yield context
  end

  def write_sentence!(context, s)
    yield context
  end

  def write_token!(context, t)
  end

  def validate!(file_name)
  end

  def self.exportable_sentence
    if self.responds?(:exportable_sentence_statuses)
      Sentence.where(:status_tag => self.exportable_sentence_statuses)
    else
      Sentence
    end
  end

  def self.only_exports(status_tag)
    case status_tag.to_s
    when 'reviewed'
      self.exportable_sentence_statuses = %w(reviewed)
    when 'annotated'
      self.exportable_sentence_statuses = %w(reviewed annotated)
    else
      raise ArgumentError, 'invalid status tag'
    end
  end
end
