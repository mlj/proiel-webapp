# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Dag Haug
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

class JSONImporter < SourceImporter
  protected

  def parse(file, options = {})
    # A mapping from old (= export/import file) ID to new (= database) ID for each type of object
    id_map = {}

    # First pass: make objects without associations and no validations
    parse_lines(file) do |klass, old_id, attrs|
      attrs.delete_if { |k, v| k[/_(id|by|to)$/] }
      attrs["status_tag"] = "unannotated" if klass == Sentence

      obj = klass.new attrs
      obj.save(:validate => false)

      id_map[klass] ||= {}
      raise "#{klass} object with ID #{id} already defined" if id_map[klass].has_key?(old_id)
      id_map[klass][old_id] = obj.id
    end

    file.rewind

    # Second pass: update objects with associations and perform validations
    parse_lines(file) do |klass, old_id, attrs|
      new_id = id_map[klass][old_id]

      attrs.delete_if { |k, v| !k[/_(id|by|to)$/] }
      attrs.each { |k, v| attrs[k] = id_map[klass][v] }

      obj = klass.find(new_id)
      obj.update_attributes!
    end
  end

  private

  def parse_lines(file)
    file.each_line do |l|
      o = ActiveSupport::JSON.decode(l)

      raise "unexpected JSON object: #{l}" unless o.keys.length == 1 and o.values.length == 1
      klass = o.keys.first.constantize
      attrs = o.values.first

      raise "JSON object lacks ID: #{l}" unless attrs.has_key?("id")

      old_id = attrs["id"].to_i
      attrs.delete("id")

      yield klass, old_id, attrs
    end
  end
end
