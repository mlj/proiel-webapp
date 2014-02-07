# coding:utf-8
#--
#
# Copyright 2012 Marius L. Jøhndal
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
require 'foma'

class LatinFomaTagger < PROIEL::MorphologyTagger
  def initialize
    super :latin_foma_tagger, 'LatinFomaTagger'

    @fsm = FOMA::FSM.new(File.join(File.dirname(__FILE__), 'latin_foma_tagger.bin'))
  end

  def applies?(language_tag)
    language_tag == 'lat'
  end

  POS_MAP = {
    'NOUN' => 'Nb', # TODO: what about proper names? capitalisation test?
    'VERB' => 'V-',
    'ADJ' => 'A-',
    'ORDNUM' => 'Mo',
    'CARDNUM' => 'Ma',
    'ADV' => 'Df',
    'RELADV' => 'Dq',
    'INTERADV' => 'Du',
    'INTERJ' => 'I-',
    'CONJ' => 'C-',
    'COMPL' => 'G-',
    'PREP' => 'R-',
    'POSSPERSPRON' => 'Ps',
    'POSSREFLPRON' => 'Pt',
    'RELPRON' => 'Pr',
    'INTERPRON' => 'Pi',
    'INDEFPRON' => 'Px',
    'RECIPPRON' => 'Pc',
    'REFLPRON' => 'Pk',
    'DEMPRON' => 'Pd',
    'PERSPRON' => 'Pp',
    'QUANT' => 'Py',
  }

  MORPHOLOGY_MAP = {
    'masc' => { :gender => :m },
    'fem' => { :gender => :f },
    'neut' => { :gender => :n },
    'sg' => { :number => :s },
    'pl' => { :number => :p },
    'nom' => { :case => :n },
    'voc' => { :case => :v },
    'acc' => { :case => :a },
    'gen' => { :case => :g },
    'dat' => { :case => :d },
    'abl' => { :case => :b },
    'ind' => { :mood => :i },
    'subj' => { :mood => :s },
    'inf' => { :mood => :n },
    'sup' => { :mood => :u },
    'ger' => { :mood => :d },
    'gdv' => { :mood => :g },
    'part' => { :mood => :p },
    'imp' => { :mood => :m },
    'act' => { :voice => :a },
    'pass' => { :voice => :p },
    'pos' => { :degree => :p },
    'comp' => { :degree => :c },
    'super' => { :degree => :s },
    'p1' => { :person => :"1" },
    'p2' => { :person => :"2" },
    'p3' => { :person => :"3" },
    'pluperf' => { :tense => :l },
    'perf' => { :tense => :r },
    'pres' => { :tense => :p },
    'fut' => { :tense => :f },
    'futperf' => { :tense => :t },
    'imperf' => { :tense => :i },
  }

  def analyse(word_form)
    # DEBUG: reload all the time
    @fsm = FOMA::FSM.new(File.join(File.dirname(__FILE__), 'latin_foma_tagger.bin'))

    analyses = []

    @fsm.apply_up(word_form) do |s|
      Rails.logger.error "#{__FILE__}: #{s} → #{analyse_string(s)}"
      analyses << analyse_string(s)
    end

    analyses
  end

  private

  def analyse_string(s)
    lemma, pos, *morphology_tags = s.split('+')
    lemma.tr! 'JĀĒĪŌŪjāēīōū', 'IAEIOUiaeiou'

    if morphology_tags.last == 'EARLY'
      morphology_tags.pop
    end

    pos = POS_MAP[pos]
    Rails.logger.error "#{__FILE__}: unknown part of speech tag #{pos}" if pos.nil?

    mf = Morphology.new
    mf[:inflection] = :n

    morphology_tags.each do |morphology_tag|
      m = MORPHOLOGY_MAP[morphology_tag]

      if m.nil?
        Rails.logger.error "#{__FILE__}: unknown morphology tag #{morphology_tag}"
      else
        m.each { |k, v| mf[k] = v }
        mf[:inflection] = :i
      end
    end

    MorphFeatures.new("#{lemma},#{pos},lat", mf)
  end
end

PROIEL::register_plugin LatinFomaTagger
