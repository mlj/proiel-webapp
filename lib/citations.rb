# encoding: UTF-8
#--
#
# Copyright 2011, 2012 University of Oslo
# Copyright 2011, 2012 Marius L. Jøhndal
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

def citation_make_range(cit1, cit2)
  raise ArgumentError unless cit1.is_a?(String)
  raise ArgumentError unless cit2.is_a?(String)

  if cit1 == cit2
    cit1
  else
    [cit1, citation_strip_prefix(cit1, cit2)].join(Unicode::U2013)
  end
end

def citation_strip_prefix(cit1, cit2, dividers = /([\s\.]+)/u)
  raise ArgumentError unless cit1.is_a?(String)
  raise ArgumentError unless cit2.is_a?(String)

  # Strip off the longest common prefix from cit2 using the charaters in
  # dividers to chunk the strings.
  cit1.split(dividers).zip(cit2.split(dividers)).inject('') do |d, (a, b)|
    if not d.empty? or a != b
      d + (b || '')
    else
      ''
    end
  end
end
