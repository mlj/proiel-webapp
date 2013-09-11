# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 Marius L. Jøhndal
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
  module Jobs
    class AnnotationValidator
      def initialize(logger = Rails.logger)
        @logger = logger
      end

      def run!
        check_changesets_and_changes
        check_orphaned_tokens
        check_lemmata
      end

      private

      def check_changesets_and_changes
        # Check Audit first so that any fixes that lead to empty audits
        # can be handled by validation of Changeset
        changes = Audit.find(:all)
        changes.each do |change|
          change.errors.to_a.each { |msg| @logger.error { "Audit #{change.id}: #{msg}" } } unless change.valid?

          # Remove changes from "X" to "X"
          if change.action != 'destroy'
            change.changes.each_pair do |key, values|
              old_value, new_value = values
              if old_value == new_value
                @logger.warn { "Audit #{change.id}: Removing redundant diff element #{key}: #{old_value} -> #{new_value}" }
                change.changes.delete(key)
                change.save!
              end
            end
          end

          # Remove empty changes
          if change.action != 'destroy' and change.changes.empty?
            others = Audit.where("auditable_type = ? and auditable_id = ? and version > ?", change.auditable_type, change.auditable_id, change.version)

            if others.count == 0
              @logger.warn { "Audit #{change.id}: Removing empty diff" }
              change.destroy
            else
              @logger.warn { "Audit #{change.id}: Removing empty diff and rearranging version numbers" }
              change.destroy
              others.each { |v| v.decrement!(:version) }
            end
          end
        end
      end

      def check_orphaned_tokens
        Token.includes(:sentence).where("sentences.id is null").each do |t|
          @logger.warn { "Token #{t.id} (#{t.to_s}) is orphaned" }
        end
      end

      def check_lemmata
        Lemma.joins("left join lemmata as b on lemmata.lemma = b.lemma and lemmata.part_of_speech_tag = b.part_of_speech_tag and lemmata.language_tag = b.language_tag").where(:variant => nil).where("b.variant IS NOT NULL").each do |l|
          @logger.error { "Lemma #{l.lemma} of language #{l.language_tag} occurs both with and without variant numbers" }
        end
      end
    end
  end
end
