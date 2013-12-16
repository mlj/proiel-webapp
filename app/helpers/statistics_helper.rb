# encoding: UTF-8
#--
#
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 University of Oslo
# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014 Marius L. Jøhndal
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

module StatisticsHelper
  def statistics(title, unit, data)
    data = data.sort_by { |k, v| v }.reverse
    pie_chart(title, data)
  end

  # Veerle's top colour scheme from http://beta.dailycolorscheme.com/archive/2006/09/20
  COLORS = %w(820F00 FF4A12 94B3C5 74C6F1 586B7A 3E4F4F ABC507)

  def pie_chart(title, data)
    image_tag(GoogleChart::PieChart.new('450x200', title, false) do |pc|
      if data.length > COLORS.length # this assumes that the data is sorted
        data = data.first(COLORS.length - 1) + [[:others, data.from(COLORS.length - 1).sum { |k, v| v }]]
      end
      data.each_with_index do |(k, v), i|
        pc.data k.is_a?(Symbol) ? k.to_s.humanize : k, v, COLORS[i]
      end
    end.to_url)
  end

  def line_chart(title, data)
    raise ArgumentError, "No data" if data.length.zero?

    x_labels = data.keys.sort

    # If many labels, reduce the number to be more manageable.
    if x_labels.length > 6
      skips = (x_labels.length / 6).to_i
      # Now replace with empty entries except for roughly every skip'th entry
      x_labels.each_index { |i| x_labels[i] = nil unless i % skips == 0 }
    end

    average = data.length > 0 ? (data.values.sum / data.length).to_i : 0
    alfa, beta = least_squares((0..data.length-1).to_a, data.values)
    lsq = (0..data.length - 1).to_a.map { |x| alfa + beta * x }

    image_tag(GoogleChart::LineChart.new("740x200", title, false) do |lc|
      lc.data "Annotations", data.values, COLORS[0]
      lc.data "Average", [average] * data.length, COLORS[1]
      lc.data "Trend", lsq, COLORS[2]
      lc.axis :x, :labels => x_labels, :color => "000000"
      lc.axis :y, :range => [data.values.min, data.values.max], :color => "000000"
    end.to_url)
  end
end
