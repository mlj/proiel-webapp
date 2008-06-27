require 'class_morphology/xml_reader'
require 'class_morphology/morphology_description'
require 'class_morphology/sfst_generator'

input, output = ARGV

@evaluations = {}
puts "* Reading definition..."
definition = Logos::ClassMorphology::ProgramDefinition.new(input)
definition.each_pair do |class_name, d|
  puts "* Evaluating #{class_name}..."
  @evaluations[class_name] = ClassBasedMorphology::ClassExpression.new(d)
  puts "  Optimised expression: " + @evaluations[class_name].to_s
end

produce_output("cu", definition, @evaluations)
