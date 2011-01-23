def dump_presentation!
  Source.all.each do |source|
    filename = "#{source.id}.xml"

    File.open(filename, 'w') do |f|
      f.puts '<?xml version="1.0" encoding="UTF-8"?>'
      f.puts '<?xml-stylesheet type="text/css" href="tv-xml.css"?>'
      f.puts '<text>'
      f.puts '  <license>Creative Commons Attribution-ShareAlike</license>'
      f.puts '  <provenance>PROIEL</provenance>'
      f.puts "  <author></author>"
      f.puts "  <title>#{title}</title>"
      f.puts "  <edition></edition>"
      f.puts "  <citation-prefix>#{source.citation_part}</citation-prefix>"
      source.source_divisions.each do |sd|
        f.puts "  <div>"
        f.puts "    <p>"
        f.puts sd.presentation
        f.puts "    </p>"
        f.puts "  </div>"
      end
    end
  end
end
