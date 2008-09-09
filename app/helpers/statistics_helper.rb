module StatisticsHelper
  def statistics(title, unit, data)
    data = data.sort_by { |k, v| v }.reverse
    content_tag(:div, pie_chart(title, data) + statistics_table(title, unit, data) + "<br/>", :class => "statistics")
  end

  def statistics_table(title, unit, data)
    content_tag(:table, data.map { |k, v| content_tag(:tr, content_tag(:td, k.is_a?(Symbol) ? k.humanize : k) + content_tag(:td, pluralize(v, unit)), :class => cycle('even', 'odd')) }.join)
  end

  # Veerle's top colour scheme from http://beta.dailycolorscheme.com/archive/2006/09/20
  COLORS = %w(820F00 FF4A12 94B3C5 74C6F1 586B7A 3E4F4F ABC507)

  def pie_chart(title, data)
    image_tag(GoogleChart::PieChart.new('450x200', title, false) do |pc|
      if data.length > COLORS.length # this assumes that the data is sorted
        data = data.first(COLORS.length - 1) + [[:others, data.from(COLORS.length - 1).sum { |k, v| v }]]
      end
      data.each_with_index do |data, i|
        k, v = *data
        pc.data k.is_a?(Symbol) ? k.humanize : k, v, COLORS[i]
      end
    end.to_url)
  end

  def line_chart(title, data)
    x_labels = data.keys
    skips = (x_labels.length / 6).to_i
    # Now replace with empty entries except for roughly every skip'th entry
    x_labels.each_index { |i| x_labels[i] = nil unless i % skips == 0 }
 
    average = (data.values.sum / data.length).to_i
    alfa, beta = least_squares((0..data.length-1).to_a, data.values)
    lsq = (0..data.length - 1).to_a.map { |x| alfa + beta * x }

    image_tag(GoogleChart::LineChart.new("630x200", title, false) do |lc|
      lc.data "Annotations", data.values, COLORS[0] 
      lc.data "Average", [average] * data.length, COLORS[1] 
      lc.data "Trend", lsq, COLORS[2] 
      lc.axis :x, :labels => x_labels, :color => "000000"
      lc.axis :y, :range => [data.values.min, data.values.max], :color => "000000"
    end.to_url)
  end
end
