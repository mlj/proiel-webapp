require File.dirname(__FILE__) + '/../test_helper'

class DependencyGraphTestCase < ActiveSupport::TestCase
  def test_each_node
    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil)
    g.add_node(11, :bar, 1)
    g.add_node(111, :bar, 11)
    g.add_node(12, :bar, 1)
    g.add_node(121, :bax, 12)
    g.add_node(122, :bay, 12)
    g.add_node(123, :baz, 12)
    assert_equal [g[1], g[11], g[111], g[12], g[121], g[122], g[123]], g.nodes
  end

  def test_select
    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil)
    g.add_node(11, :bar, 1)
    g.add_node(111, :bar, 11)
    g.add_node(12, :bar, 1)
    g.add_node(121, :bax, 12)
    g.add_node(122, :bay, 12)
    g.add_node(123, :baz, 12)
    assert_equal [g[11], g[111], g[12]], g.select { |n| n.relation == :bar }
  end

  def test_siblings
    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil)
    g.add_node(11, :bar, 1)
    g.add_node(111, :bar, 11)
    g.add_node(12, :bar, 1)
    g.add_node(121, :bax, 12)
    g.add_node(122, :bay, 12)
    g.add_node(123, :baz, 12)

    assert_equal [], g[1].siblings
    assert_equal [g[12]], g[11].siblings
    assert_equal [], g[111].siblings
    assert_equal [g[11]], g[12].siblings
    assert_equal [g[122], g[123]], g[121].siblings

    assert_equal false, g[1].has_siblings?
    assert_equal true, g[11].has_siblings?
    assert_equal false, g[111].has_siblings?
    assert_equal true, g[12].has_siblings?
    assert_equal true, g[121].has_siblings?

    assert_equal true, g[121].has_siblings?(:bay)
    assert_equal true, g[121].has_siblings?(:baz)
    assert_equal false, g[121].has_siblings?(:bax)
  end
end

class DependencyGraphTestCase < ActiveSupport::TestCase
  EMITTER = lambda { |t, m| STDERR.puts "Validation error for node #{t.join(',')}: #{m}" }

  def setup_ok_graph
    g = Proiel::DependencyGraph.new
    g.add_node(250414, "pred", nil, {}, {:empty=>false, :token_number => 17, :morph_features => MorphFeatures.new(',V-,lat', nil) })
    g.add_node(250398, "adv", 250414, {}, {:empty=>false, :token_number => 1, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g.add_node(250399, "aux", 250414, {}, {:empty=>false, :token_number => 2, :morph_features => MorphFeatures.new(',Df,lat', nil)})
    g.add_node(250400, "adv", 250398, {}, {:empty=>false, :token_number => 3, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g.add_node(250401, "aux", 250400, {}, {:empty=>false, :token_number => 4, :morph_features => MorphFeatures.new(',Df,lat', nil)})
    g.add_node(250402, "sub", 250400, {}, {:empty=>false, :token_number => 5, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
    g.add_node(250403, "adv", 250400, {}, {:empty=>false, :token_number => 6, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g.add_node(250404, "obl", 250403, {}, {:empty=>false, :token_number => 7, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
    g.add_node(250405, "atr", 250404, {}, {:empty=>false, :token_number => 8, :morph_features => MorphFeatures.new(',A-,lat', nil)})
    g.add_node(250406, "adv", 250414, {}, {:empty=>false, :token_number => 9, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g.add_node(250407, "obl", 250406, {}, {:empty=>false, :token_number => 10, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
    g.add_node(250408, "atr", 250407, {}, {:empty=>false, :token_number => 11, :morph_features => MorphFeatures.new(',A-,lat', nil)})
    g.add_node(250409, "apos", 250408, {}, {:empty=>false, :token_number => 12, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
    g.add_node(250410, "aux", 250414, {}, {:empty=>false, :token_number => 13, :morph_features => MorphFeatures.new(',Df,lat', nil)})
    g.add_node(250411, "sub", 250414, {}, {:empty=>false, :token_number => 14, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
    g.add_node(250412, "obl", 250414, {}, {:empty=>false, :token_number => 15, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g.add_node(250413, "obl", 250412, {}, {:empty=>false, :token_number => 16, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g.add_node(250415, "obl", 250414, {}, {:empty=>false, :token_number => 18, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
    g.add_node(250416, "xadv", 250414, { 250411 => :sub }, {:empty=>false, :token_number => 19, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    g
  end

  def test_graph_loading
    setup_ok_graph
  end

  def test_is_daughter_of_root
    g = setup_ok_graph
    assert_equal true, g[250414].is_daughter_of_root?
    assert_equal false,  g[250399].is_daughter_of_root?
  end

  def test_batch_setup
    k = Proiel::DependencyGraph.new do |g|
      # These are out of sequence and should be refused outside
      # the block. 
      g.badd_node(250398, "adv", 250414, {}, {:empty=>false, :token_number => 1, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250399, "aux", 250414, {}, {:empty=>false, :token_number => 2, :morph_features => MorphFeatures.new(',Df,lat', nil)})
      g.badd_node(250400, "adv", 250398, {}, {:empty=>false, :token_number => 3, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250401, "aux", 250400, {}, {:empty=>false, :token_number => 4, :morph_features => MorphFeatures.new(',Df,lat', nil)})
      g.badd_node(250402, "sub", 250400, {}, {:empty=>false, :token_number => 5, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
      g.badd_node(250403, "adv", 250400, {}, {:empty=>false, :token_number => 6, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250404, "obl", 250403, {}, {:empty=>false, :token_number => 7, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
      g.badd_node(250405, "atr", 250404, {}, {:empty=>false, :token_number => 8, :morph_features => MorphFeatures.new(',A-,lat', nil)})
      g.badd_node(250406, "adv", 250414, {}, {:empty=>false, :token_number => 9, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250407, "obl", 250406, {}, {:empty=>false, :token_number => 10, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
      g.badd_node(250408, "atr", 250407, {}, {:empty=>false, :token_number => 11, :morph_features => MorphFeatures.new(',A-,lat', nil)})
      g.badd_node(250409, "apos", 250408, {}, {:empty=>false, :token_number => 12, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
      g.badd_node(250410, "aux", 250414, {}, {:empty=>false, :token_number => 13, :morph_features => MorphFeatures.new(',Df,lat', nil)})
      g.badd_node(250411, "sub", 250414, {}, {:empty=>false, :token_number => 14, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
      g.badd_node(250412, "obl", 250414, {}, {:empty=>false, :token_number => 15, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250413, "obl", 250412, {}, {:empty=>false, :token_number => 16, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250414, "pred", nil, {}, {:empty=>false, :token_number => 17, :morph_features => MorphFeatures.new(',V-,lat', nil)})
      g.badd_node(250415, "obl", 250414, {}, {:empty=>false, :token_number => 18, :morph_features => MorphFeatures.new(',Nb,lat', nil)})
      g.badd_node(250416, "xadv", 250414, {250411 => "sub" }, {:empty=>false, :token_number => 19, :morph_features => MorphFeatures.new(',V-,lat', nil)})
    end
    l = setup_ok_graph
    assert_equal l.inspect, k.inspect
  end

  def test_slash_storage
    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil, {})
    g.add_node(2, :bar, nil, { 1 => :foo })
    assert_equal [], g[1].slashes
    assert_equal [g[1]], g[2].slashes
  end

  def test_slash_storage_out_of_sequence
    Proiel::DependencyGraph.new do |g|
      g.badd_node(2, :bar, nil, { 1 => :foo })
      g.badd_node(1, :foo, nil, {})
    end
  end

  def test_subgraph
    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil)
    g.add_node(11, :bar, 1)
    g.add_node(111, :bar, 11, { 11 => :bar })
    g.add_node(12, :bar, 1)
    g.add_node(121, :bar, 12, { 11 => :bar })
    g.add_node(1211, :bar, 121, { 121 => :bar })

    assert_equal [1, 11, 12, 111, 121, 1211], g[1].subgraph.collect(&:identifier).sort
    assert_equal [11, 111], g[11].subgraph.collect(&:identifier).sort
    assert_equal [111], g[111].subgraph.collect(&:identifier).sort
    assert_equal [12, 121, 1211], g[12].subgraph.collect(&:identifier).sort
    assert_equal [121, 1211], g[121].subgraph.collect(&:identifier).sort
    assert_equal [1211], g[1211].subgraph.collect(&:identifier).sort
  end

  def test_all_slashes_contained
    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil)
    g.add_node(11, :bar, 1)
    g.add_node(111, :bar, 11, { 11 => :bar })
    g.add_node(12, :bar, 1)
    g.add_node(121, :bar, 12, { 11 => :bar })

    assert_equal true, g[1].all_slashes_contained?
    assert_equal true, g[11].all_slashes_contained?
    assert_equal false, g[111].all_slashes_contained?
    assert_equal false, g[12].all_slashes_contained?
    assert_equal false, g[121].all_slashes_contained?
  end

  def test_min_max_token_number
    g = setup_ok_graph
    assert_equal 1, g[250398].min_token_number
    assert_equal 8, g[250398].max_token_number

    assert_equal 1, g[250414].min_token_number
    assert_equal 19, g[250414].max_token_number

    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil, {}, { :empty => true, :token_number => 600 })
    g.add_node(2, :foo, 1, {}, { :empty => false, :token_number => 10 })
    assert_equal 10, g[1].max_token_number
    assert_equal 10, g[2].max_token_number

    g = Proiel::DependencyGraph.new
    g.add_node(1, :foo, nil, {}, { :empty => true, :token_number => 600 })
    g.add_node(2, :foo, 1, {}, { :empty => true, :token_number => 10 })
    assert_equal nil, g[1].max_token_number
    assert_equal nil, g[2].max_token_number
  end

  def test_linearly_precedes
    g = setup_ok_graph
    assert_equal true, g[250398].linearly_precedes?(g[250406])
    assert_equal false, g[250406].linearly_precedes?(g[250398])

    # 250399 occurs second within 250398's subgraph
    assert_equal false, g[250399].linearly_precedes?(g[250398])
    assert_equal false, g[250398].linearly_precedes?(g[250399])

    # 250414's subgraph contains 250398
    assert_equal false, g[250414].linearly_precedes?(g[250398])
    assert_equal false, g[250398].linearly_precedes?(g[250414])
  end

  def test_proiel_validation
    g = setup_ok_graph
    assert_equal true, g.valid?(EMITTER)
  end

  def test_proiel_validation_root_daughters
    # Break the graph by adding an ADV directly under the root
    g = Proiel::DependencyGraph.new
    g.add_node(250414, "adv", nil, {}, { :empty => false, :morph_features => MorphFeatures.new(',Df,lat', nil) })
    g.add_node(250398, "adv", 250414, {}, { :empty => false, :morph_features => MorphFeatures.new(',Df,lat', nil) })
    assert_equal false, g.valid?
  end

  def test_all_slashes
    # Simple, ordinary case: a non-empty xobj with a slash
    g = Proiel::DependencyGraph.new
    g.add_node(1, :pred, nil, {}, { :empty => false, :token_number => 1})
    g.add_node(11, :adv, 1, {}, { :empty => false, :token_number => 2})
    g.add_node(12, :xobj, 1, { 1 => :pred }, { :empty => false, :token_number => 3})
    assert_equal g[1].all_slashes.length, 0
    assert_equal g[11].all_slashes.length, 0
    assert_equal g[12].all_slashes.length, 1

    # A pair of coordinated non-empty xobjs sharing a slash
    g = Proiel::DependencyGraph.new
    g.add_node(1, :pred, nil, {}, { :empty => false, :token_number => 1})
    g.add_node(11, :adv, 1, {}, { :empty => false, :token_number => 2})
    g.add_node(12, :xobj, 1, { 1 => :pred }, { :empty => false, :token_number => 3, :morph_features => MorphFeatures.new(',C-,lat', nil)})
    g.add_node(121, :xobj, 12, {}, { :empty => false, :token_number => 5})
    g.add_node(122, :xobj, 12, {}, { :empty => false, :token_number => 6})
    assert_equal g[1].all_slashes.length, 0
    assert_equal g[11].all_slashes.length, 0
    assert_equal g[12].all_slashes.length, 1
    assert_equal g[121].slashes.length, 0
    assert_equal g[122].slashes.length, 0 
    assert_equal g[121].all_slashes.length, 1
    assert_equal g[122].all_slashes.length, 1

    # A pair of coordinated non-empty xobjs sharing a slash but with an empty coordinator
    g = Proiel::DependencyGraph.new
    g.add_node(1, :pred, nil, {}, { :empty => false, :token_number => 1})
    g.add_node(11, :adv, 1, {}, { :empty => false, :token_number => 2})
    g.add_node(12, :xobj, 1, { 1 => :pred }, { :empty => 'C', :token_number => 3})
    g.add_node(121, :xobj, 12, {}, { :empty => false, :token_number => 5})
    g.add_node(122, :xobj, 12, {}, { :empty => false, :token_number => 6})
    assert_equal g[1].all_slashes.length, 0
    assert_equal g[11].all_slashes.length, 0
    assert_equal g[12].all_slashes.length, 1
    assert_equal g[121].slashes.length, 0
    assert_equal g[122].slashes.length, 0 
    assert_equal g[121].all_slashes.length, 1
    assert_equal g[122].all_slashes.length, 1

    # Full-fledged multi-level inheritance with empty coordinator
    g = Proiel::DependencyGraph.new
    g.add_node(1, :pred, nil, {}, { :empty => false, :token_number => 1})
    g.add_node(11, :adv, 1, {}, { :empty => false, :token_number => 2})
    g.add_node(12, :xobj, 1, { 1 => :pred }, { :empty => 'C', :token_number => 3})
    g.add_node(121, :xobj, 12, {}, { :empty => false, :token_number => 4, :morph_features => MorphFeatures.new(',C-,lat', nil)})
    g.add_node(1211, :xobj, 121, {}, { :empty => false, :token_number => 5})
    g.add_node(1212, :xobj, 121, {}, { :empty => false, :token_number => 6})
    g.add_node(122, :xobj, 12, {}, { :empty => false, :token_number => 7, :morph_features => MorphFeatures.new(',C-,lat', nil)})
    g.add_node(1221, :xobj, 122, {}, { :empty => false, :token_number => 8})
    g.add_node(1222, :xobj, 122, {}, { :empty => false, :token_number => 9})
    assert_equal g[1].all_slashes.length, 0
    assert_equal g[11].all_slashes.length, 0
    assert_equal g[12].all_slashes.length, 1
    assert_equal g[121].slashes.length, 0
    assert_equal g[1211].slashes.length, 0
    assert_equal g[1212].slashes.length, 0 
    assert_equal g[122].slashes.length, 0
    assert_equal g[1221].slashes.length, 0
    assert_equal g[1222].slashes.length, 0 
    assert_equal g[121].all_slashes.length, 1
    assert_equal g[1211].all_slashes.length, 1
    assert_equal g[1212].all_slashes.length, 1 
    assert_equal g[122].all_slashes.length, 1
    assert_equal g[1221].all_slashes.length, 1
    assert_equal g[1222].all_slashes.length, 1 
  end

  def test_editor_to_dg_conversion
    output = {"287650"=>{"empty"=>true, "relation"=>"pred", "dependents"=>{"266690"=>{"slashes"=>["287650"], "empty"=>false, "relation"=>"piv", "dependents"=>{"266691"=>{"empty"=>false, "relation"=>"atr", "dependents"=>{"266692"=>{"empty"=>false, "relation"=>"atr", "dependents"=>{"266693"=>{"empty"=>false, "relation"=>"apos"}, "266694"=>{"empty"=>false, "relation"=>"apos", "dependents"=>{"266695"=>{"empty"=>false, "relation"=>"atr", "dependents"=>{"266696"=>{"empty"=>false, "relation"=>"apos", "dependents"=>{"266697"=>{"empty"=>false, "relation"=>"atr"}}}}}}}}}}}}}}}}
    g = Proiel::DependencyGraph.new_from_editor(output)
    assert_equal 1, g[266690].slashes.length
    assert_equal [287650], g[266690].slashes.map(&:identifier)
  end
end
