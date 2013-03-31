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

# Abstract source importer.
class SourceImporter
  def initialize
  end

  # Reads data to be imported from a file.
  def read(file_name)
    # Validate first so that we can assume that required elements/attributes are present.
    validate!(file_name)

    File.open(file_name, 'r') do |file|
      parse(file)
    end
  end

  def validate!(file_name)
  end

  def parse(file)
  end
end
