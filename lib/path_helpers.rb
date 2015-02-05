# encoding: UTF-8
#--
#
# Copyright 2013 University of Oslo
# Copyright 2013 Marius L. Jøhndal
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
  # Module with convenience helpers for working with the paths specified by the
  # application configuration in config/environment*.
  module PathHelpers
    def export_file_name(source_tag)
      "#{source_tag}.xml.gz"
    end

    def export_file_name_with_path(source_tag)
      file_name = export_file_name(source_tag)
      File.join(Proiel::Application.config.export_directory_path, file_name)
    end

    def export_file_url(source_tag)
      file_name = export_file_name(source_tag)
      "/exports/#{file_name}"
    end

    def export_file_available?(source_tag)
      File.exists?(export_file_name_with_path(source_tag))
    end
  end
end
