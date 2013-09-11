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
    class DatabaseValidator
      def initialize(logger = Rails.logger)
        @logger = logger
      end

      def run!
        Dir.glob(Rails.root.join('app', 'models', '**', '*.rb')).each do |file_name|
          klass = File.basename(file_name, '.rb').camelize.constantize
          next unless klass.ancestors.include?(ActiveRecord::Base)

          total = klass.count
          chunk_size = 500
          (total / chunk_size + 1).times do |i|
            chunk = klass.find(:all, :offset => (i * chunk_size), :limit => chunk_size)
            chunk.reject(&:valid?).each do |record|
              if record.class == Sentence
                @logger.error { "#{record.class} in database fails validation: id=#{record.id} (#{record.is_reviewed? ? 'Reviewed' : 'Not reviewed'})" }
              else
                @logger.error { "#{record.class} in database fails validation: id=#{record.id}" }
              end
              @logger.error record.errors.full_messages
            end
          end
        end
      end
    end
  end
end
