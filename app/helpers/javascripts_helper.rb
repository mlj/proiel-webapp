module JavascriptsHelper
  def create_cascade_map(values, map)
    s = "var #{map} = new Array();"
    values.each do |e|
      case e.length
      when 5
        minor = e[1] ? "'#{e[1]}'" : 'null'
        mood = e[2] ? "'#{e[2]}'" : 'null'
        code = e[4] ? "'#{e[4]}'" : 'null'
        summary = e[3] ? "'#{e[3]}'" : 'null'
        s += "#{map}.push(new Array('#{e[0]}', #{minor}, #{mood}, #{code}, #{summary}));"
      when 4 
        minor = e[1] ? "'#{e[1]}'" : 'null'
        code = e[2] ? "'#{e[2]}'" : 'null'
        summary = e[3] ? "'#{e[3]}'" : 'null'
        s += "#{map}.push(new Array('#{e[0]}', #{minor}, #{code}, #{summary}));"
      when 3 
        code = e[1] ? "'#{e[1]}'" : 'null'
        summary = e[2] ? "'#{e[2]}'" : 'null'
        s += "#{map}.push(new Array('#{e[0]}', #{code}, #{summary}));"
      end
    end
    s
  end
end
