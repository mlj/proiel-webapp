# encoding: UTF-8
#--
#
# Copyright 2007-2016 University of Oslo
# Copyright 2007-2016 Marius L. Jøhndal
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
    class DatabaseChecker < Job
      def run_once!
        Source.transaction do
          destroy_orphaned_lemmata!
        end

        check_orphaned_tokens
        check_lemmata
      end

      private

      def destroy_orphaned_lemmata!
        Lemma.joins(:tokens).where('lemmata.foreign_ids IS NULL AND tokens.id IS NULL').each do |o|
          @logger.warn { "#{self.class}: Destroying orphaned lemma #{o.id}" }
          o.destroy
        end
      end

      def check_orphaned_tokens
        Token.joins(:sentence).where("sentences.id IS NULL").each do |t|
          @logger.error { "#{self.class}: Token #{t.id} (#{t.to_s}) is orphaned" }
        end
      end

      def check_lemmata
        Lemma.joins("left join lemmata as b on lemmata.lemma = b.lemma and lemmata.part_of_speech_tag = b.part_of_speech_tag and lemmata.language_tag = b.language_tag").where(:variant => nil).where("b.variant IS NOT NULL").each do |l|
          @logger.error { "#{self.class}: Lemma #{l.lemma} of language #{l.language_tag} occurs both with and without variant numbers" }
        end
      end
    end
  end
end
