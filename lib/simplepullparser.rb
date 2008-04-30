#
# simplepullparser - Simplified pull REXML based pull parser
#
# $Id: $
#
require 'rexml/parsers/pullparser'
require 'extensions'

class SimplePullParser
  def initialize(f)
    @parser = REXML::Parsers::PullParser.new(f)

    @stack = [] 
    @queued = nil 
    @attributes = nil 
  end

  def parse 
    while @parser.has_next?
      pull_event = @parser.pull

      case pull_event.event_type
      when :start_element
        yield @stack.dup, @attributes, nil if @queued

        @stack.push(pull_event[0].to_sym)
        @queued = pull_event[0].to_sym
        @attributes = pull_event[1].rekey { |k| k.to_sym }
      when :end_element
        if @queued
          yield @stack.dup, @attributes, nil

          @queued = nil
          @attributes = nil
        end

        @stack.pop
      when :text
        if @queued
          yield @stack.dup, @attributes, pull_event[0]

          @queued = nil
          @attributes = nil
        end
      end
    end
  end
end
