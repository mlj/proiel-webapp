require 'google_chart'
require 'statistics'

module StatisticsHelper
  def google_pie_chart(data, options = {})
    data.reject! { |k, v| v == 0 }
    options[:width] ||= 250
    options[:height] ||= 100
    options[:colors] = %w(0DB2AC F5DD7E FC8D4D FC694D FABA32 704948 968144 C08FBC ADD97E)
    dt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-."
    options[:divisor] ||= 1
    
    while (data.map { |k,v| v }.max / options[:divisor] >= 4096) do
      options[:divisor] *= 10
    end
    
    opts = {
      :cht => "p",
      :chd => "e:#{data.map{|k,v|v=v/options[:divisor];dt[v/64..v/64]+dt[v%64..v%64]}}",
      :chl => "#{data.map { |k,v| CGI::escape(k)}.join('|')}",
      :chs => "#{options[:width]}x#{options[:height]}",
      :chco => options[:colors].slice(0, data.length).join(',')
    }
    
    image_tag("http://chart.apis.google.com/chart?#{opts.map{|k,v|"#{k}=#{v}"}.join('&')}", :alt => 'Annotation statistics')
  end

  def google_line_chart(data, options = {})
    options[:width] ||= 450
    options[:height] ||= 200
    options[:colors] = %w(FC8D4D 704948 968144 C08FBC ADD97E)
    dt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-."
    
    x_labels = data.map { |k, v| k }
    skips = x_labels.length / 5 
    # Now replace with empty entries except for roughly every skip'th entry
    x_labels.each_index { |i| x_labels[i] = nil unless i % skips.to_i == 0 }
 
    average = [(data.map { |k, v| v }.sum / data.length).to_i] * data.length
    alfa, beta = least_squares((0..data.length-1).to_a, data.collect { |k, v| v })
    lsq = (0..data.length - 1).to_a.collect { |x| alfa + beta * x }

    lc = GoogleChart::LineChart.new("#{options[:width]}x#{options[:height]}", nil, false) do |lc|
      lc.data "Annotations", data.map { |k, v| v }, options[:colors][0] 
      lc.data "Average", average, options[:colors][2] 
      lc.data "Trend", lsq, options[:colors][4] 
      lc.axis :y, :range => [0, data.map { |k, v| v }.max], :color => options[:colors][1], :font_size => 16, :alignment => :center
      lc.axis :x, :labels => x_labels, :color => options[:colors][1], :font_size => 16, :alignment => :center
    end

    image_tag(lc.to_url)
  end
end
