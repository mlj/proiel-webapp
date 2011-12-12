# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Marius L. Jøhndal
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

class StatArray < Array
  def sum
    x = inject { |sum, x| sum + x }
  end

  def mean
    self.sum.to_f / self.length
  end

  def variance
    m = self.mean
    s = inject(0.0) { |sum, x| sum += (v - m)**2 }
    s/self.length
  end

  def stddev
    Math.sqrt(self.variance)
  end
end

def least_squares(a, b)
  # FIXME: what a mess
  x = StatArray.new
  y = StatArray.new
  raise "Arrays must be of same length (#{a.length} != #{b.length})" unless a.length == b.length
  a.each { |n| x.push n }
  b.each { |n| y.push n }

  x_mean = x.mean
  y_mean = y.mean

  x_sqsum = x.collect { |n| n**2 }.sum
  y_sqsum = y.collect { |n| n**2 }.sum

  sx2 = x_sqsum - x.length * (x_mean ** 2)
  sy2 = y_sqsum - y.length * (y_mean ** 2)

  xy_sum = x.zip(y).collect { |m, n| m * n }.sum
  sxy = xy_sum - x.length * x_mean * y_mean

  beta = sxy / sx2
  alfa = y_mean - beta * x_mean

  [alfa, beta]
end

if $0 == __FILE__
  #FIXME: convert to test
  # approx 2 and 0.387
  puts least_squares([1, 1, 2, 3, 4, 4, 5, 6, 6, 7],
                     [2.1, 2.5, 3.1, 3.0, 3.8, 3.2, 4.3, 3.9, 4.4, 4.8])
end
