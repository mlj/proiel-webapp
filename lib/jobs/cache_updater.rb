# encoding: UTF-8
#--
#
# Copyright 2016 Marius L. Jøhndal
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
    class CacheUpdater < Job
      def run_once!
        Source.transaction do
          update_field!(SourceDivision, :cached_status_tag, 'aggregate_status')
          update_field!(SourceDivision, :cached_citation, 'citation')
          update_field!(SourceDivision, :cached_has_discourse_annotation, 'has_discourse_annotation?')
        end
      end

      private

      def update_field!(model, cache_attribute, method)
        model.where("#{cache_attribute} IS NOT NULL").each do |obj|
          v = obj.send(method)

          if obj.read_attribute(cache_attribute) != v
            @logger.warn { "Updating #{cache_attribute} on #{obj.class} #{obj.id}" }
            obj.update_attribute(cache_attribute, v)
          end
        end
      end
    end
  end
end
