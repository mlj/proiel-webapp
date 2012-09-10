# coding: utf-8
#--
#
# Copyright 2012 University of Oslo
# Copyright 2012 Dag Haug
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

require 'plugin.rb'
require 'yaml'

class LatexGlossingExporter < PROIEL::Exporter
  def initialize
    super :latex_glossing, 'LaTeX export'

    @glosses = YAML::load(File.read(__FILE__).sub(/\A.*\n__END__\n/m, ''))
  end

  def applies?(object)
    object.is_a?(Sentence)
  end

  def mime_type(object)
    :html
  end

  def generate(object, options = {})
    if applies?(object)
      tokens = object.tokens.visible

      transcribed_tokens = tokens.map { |t| transcribe(t) }.join(' ')
      glosses = tokens.map { |t| gloss(t) }.join(' ')

      "\\exg." + [transcribed_tokens, glosses, "(#{object.citation}) %#{object.id}"].join("\\\\<br/>")
    else
      super
    end
  end

  private

  def transcribe(token)
    ex_form = case token.language.tag
              when 'grc'
                t = TransliteratorFactory.get_transliterator('grc-simple')
                # FIXME: getting the rough breathing on the right side
                # of the vowel(s) and escaping the circumflex character
                # should really be done in the transducer itself
                t.generate_string(token.form).first.gsub(/^(([\^]?[aeiou])+)h/,'h\1').sub(/^([\^]?[AEIOU][aeiou]?)h(.*)$/) { |x| x.sub(/([\^]?[AEIOU][aeiou]?)h/, 'H\1').capitalize }.gsub('^', '\^')
              when 'lat'
                token.form
              else
                t = TransliteratorFactory.get_transliterator("#{language.tag}-ascii")
                t.generate_string(token.form)
              end
    "{#{ex_form}}"
  end

  def gloss(token)
    res = "{"
    if token.lemma
      res += (token.lemma.short_gloss ? token.lemma.short_gloss.split(/[.,;\/]/).first : 'NOGLOSS')
    end
    g = morphology_gloss(token)
    res += ".{\\sc #{g}}" if g != ""
    res + "}"
  end

  def morphology_gloss(token)
    if token.morph_features
      token.morph_features.morphology.map do |field, value|
        @glosses[field.to_s][value.to_s]
      end.reject(&:nil?).join('.')
    else
      ''
    end
  end
end

PROIEL::register_plugin LatexGlossingExporter

if __FILE__ == $0
  require 'config/environment'

  SourceDivision.find(112).sentences.each do |s|
    g = Gloss.new(s)
    puts s.tokens.reject(&:is_empty?).map(&:form).join(' ')
    puts s.tokens.reject(&:is_empty?).map { |tk| g.send(:transcribe, tk) }.join(' ')
  end

  errors = 0
  failures = 0
  t = TransliteratorFactory.get_transliterator('grc-simple')
  [
   ['Αἵμου', 'Haimou'],
   ['ἄλλοι', 'alloi'],
   ['Ἄθρυς', 'Athrus'],
   ['Ἀρτάνης', 'Artan\^es'],
   ['Ῥοδόπης', 'Rhodop\^es'],
   ['Ὀμβρικῶν', 'Ombrik\^on'],
   ['οὗτοι', 'houtoi'],
   ['ῥέων', 'rhe\^on'],
   ['εἶ', 'ei'],
   ['Ὦπις', '\^Opis'],
   ['ᾠδή', '\^oid\^e'],
   ['ᾧ', 'h\^oi'],
   ['Ἢ', '\^E'],
   ['ᾗ', 'h\^ei'],
   ["προϊέναι", 'proienai'],
   ["ἐν", 'en'],
   ["οἱ", 'hoi'],
   ["Οἱ", 'Hoi'],
   ["Ὡς", 'H\^os'],
   ["ὡς", 'h\^os'],
   ["Ὅτε", 'Hote'],
   ["Ἆρ'", "Ar'"],
  ].each do |test|
    begin
      res = t.generate_string(test[0]).first.gsub(/^(([\^]?[aeiou])+)h/,'h\1').sub(/^([\^]?[AEIOU][aeiou]?)h(.*)$/) { |x| x.sub(/([\^]?[AEIOU][aeiou]?)h/, 'H\1').capitalize }.gsub('^', '\^')

      unless  res == test[1]
        STDERR.puts "Test failed: #{test[0]} was transcribed as #{res} instead of #{test[1]}"# (transducer yielded #{trans}, substitutions yielded #{res2})"
        failures += 1
      else
        STDERR.puts "Test succeeded: #{test[0]} was transcribed as #{test[1]}"
      end
    rescue => e
      STDERR.puts "Tagger broke down on #{test[0]}: #{e}"
      errors += 1
    end
  end
  STDERR.puts "Tagger finished with #{errors} errors and #{failures} failures"
end

__END__
mood:
  m: imp
  x:
  n: inf
  o: opt
  d: gnd
  p: ptcp
  g: gndv
  s: sbjv
  i:
  u:
inflection:
  n:
  i:
number:
  x:
  d: du
  p: pl
  s: sg
voice:
  a: act
  m: mid
  e: mid/pas
  p: pas
case:
  v: voc
  a: acc
  l: loc
  b: abl
  x:
  n: nom
  c: gen/dat
  d: dat
  g: gen
  i: inst
degree:
  x:
  c: comp
  p:
  s: sup
gender:
  m: m
  x:
  n: n
  o: m/n
  p: m/f
  q: m/f/n
  f: f
  r: f/n
strength:
  w: weak
  s: strong
  t:
person:
  x:
  "1": "1"
  "2": "2"
  "3": "3"
tense:
  l: plupf
  a: pfv.pst
  x:
  p: pres
  f: fut
  r: prf
  s: result
  t: fut.prf
  u: pst
  i: ipfv.pst
