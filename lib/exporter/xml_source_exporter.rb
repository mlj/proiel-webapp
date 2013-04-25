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

class XMLSourceExporter < SourceExporter
  def validate!(file_name)
    if self.class.respond_to?(:schema_file_name)
      unless system("xmllint --path #{Proiel::Application.config.schema_file_path} --nonet --schema #{File.join(Proiel::Application.config.schema_file_path, self.class.schema_file_name)} --noout #{file_name}.tmp")
        raise "exported XML does not validate"
      end
    else
      raise "no schema file name defined"
    end
  end
end
