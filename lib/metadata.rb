# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
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

module Proiel
  module Metadata
    ADDITIONAL_METADATA_FIELDS = %w(
      principal funder distributor distributor_address date
      license license_url
      reference_system
      editor editorial_note
      annotator reviewer

      electronic_text_editor electronic_text_title
      electronic_text_version
      electronic_text_publisher electronic_text_place electronic_text_date
      electronic_text_original_url
      electronic_text_license electronic_text_license_url

      printed_text_editor printed_text_title
      printed_text_edition
      printed_text_publisher printed_text_place printed_text_date
    )

    # Returns the names of metadata fields.
    def self.fields
      ADDITIONAL_METADATA_FIELDS
    end

    # Returns the names of read-only metadata fields, i.e. those whose values
    # are to be inferred from other information in the treebank.
    def self.readonly_fields
      %w(annotator reviewer)
    end

    # Returns the names of writeable metadata fields, i.e. those whose values
    # cannot be inferred from other information in the treebank.
    def self.writeable_fields
      fields - readonly_fields
    end

    # Returns the names of metadata fields that pertain to the treebank.
    def self.treebank_fields
      ADDITIONAL_METADATA_FIELDS.select { |s| /^(printed|electronic)_text/ !~ s }
    end

    # Returns the names of metadata fields that pertain to the electronic text.
    def self.electronic_text_fields
      ADDITIONAL_METADATA_FIELDS.grep(/^electronic_text/)
    end

    # Returns the names of metadata fields that pertain to the printed text.
    def self.printed_text_fields
      ADDITIONAL_METADATA_FIELDS.grep(/^printed_text/)
    end

    # Returns the names of metadata fields that pertain to the treebank
    # along with human-readable field names.
    def self.treebank_fields_and_labels
      treebank_fields.map do |field|
        [field, field.humanize.sub('url', 'URL')]
      end
    end

    # Returns the names of metadata fields that pertain to the electronic text
    # along with human-readable field names.
    def self.electronic_text_fields_and_labels
      electronic_text_fields.map do |field|
        [field, field.sub(/^electronic_text_/, '').humanize.sub('url', 'URL')]
      end
    end

    # Returns the names of metadata fields that pertain to the printed text
    # along with human-readable field names.
    def self.printed_text_fields_and_labels
      printed_text_fields.map do |field|
        [field, field.sub(/^printed_text_/, '').humanize.sub('url', 'URL')]
      end
    end
  end
end
