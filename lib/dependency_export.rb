#--
#
# Copyright 2009 University of Oslo
# Copyright 2009 Marius L. Jøhndal
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

module DependencyExport
  # Returns dependency annotation on a condensed UTF-8 text only
  # format.
  #
  # Requires the model to have the association +tokens+ with
  # an array of tokens.
  def dependency_export
    heads = tokens.select { |t| t.head_id.nil? }.select { |t| t.relation }

    raise "No head dependency node." if heads.length == 0
    raise "Multiple head dependency nodes." if heads.length > 1

    desc(heads.first, repeated_forms)
  end

  private

  def desc(t, r)
    form = desc_form(t, r)
    relation = t.relation ? ("_" + t.relation.to_s) : ''

    hd = form + relation
    dp = t.dependents.length > 0 ? (' ' + t.dependents.map { |d| desc(d, r) }.join(' ')) : ''
    sl = t.slashees.map { |s| desc_form(s, r) }.map { |f| "→#{f}" }.join('')

    "(#{hd}#{sl}#{dp})"
  end

  def repeated_forms
    s = []
    r = []
    tokens.reject(&:is_empty?).map(&:form).each do |form|
      if s.include?(form)
        r << form
      else
        s << form
      end
    end
    r
  end

  def desc_form(t, r)
    if t.form
      if r.include?(t.form)
        t.form + t.token_number.to_s
      else
        t.form
      end
    else
      t.empty_token_sort
    end
  end
end
