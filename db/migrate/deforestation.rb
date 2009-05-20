Token.class

class Token < ActiveRecord::Base
  def max_token_number
    subgraph_set.reject(&:is_empty?).map(&:token_number).sort.last
  end

  def min_token_number
    subgraph_set.reject(&:is_empty?).map(&:token_number).sort.first
  end
end

Sentence.class

class Sentence < ActiveRecord::Base
  def partition!(roots = [])
    # Sort the roots by token number
    reload
    roots.sort! { |x, y| x.min_token_number <=> y.min_token_number }

    Sentence.transaction do 
      # Make room for the new sentence numbers
      ses = source_division.sentences.find(:all, :conditions => [ "sentence_number > ?", sentence_number ])
      ses.sort { |x, y| y.sentence_number <=> x.sentence_number }.each do |s|
        s.sentence_number += roots.size - 1
        s.save_without_validation!
      end
      
      # Make the new sentences, assign their tokens and delete the old
      # one. There is no uniqueness constraint on sentence_numbers so
      # this simple approach works
      roots.each_with_index do |pred, i|
        new_s = source_division.sentences.create
        new_s.sentence_number = self.sentence_number + i

        # Move the subgraphs of the new sentence root
        pred.subgraph_set.each do |t| 
          t.sentence_id = new_s.id 
          t.save_without_validation!
          new_s.dependency_tokens.reload
        end

        # The first sentence takes all preceding material
        if i == 0
          tokens.select { |t| t.token_number < pred.min_token_number}.each do |tt|
            tt.sentence_id = new_s.id
            tt.save_without_validation!
            new_s.dependency_tokens.reload
          end
        end
        # The last sentence takes all subsequent material unless they
        # are empty nodes which belongs to the subgraph of a root
        if i == roots.size - 1
          tokens.select { |t| !roots.map(&:subgraph_set).flatten.include?(t) and t.token_number > pred.max_token_number}.each do |tt|
            tt.sentence_id = new_s.id
            tt.save_without_validation!
            new_s.dependency_tokens.reload
          end
        end

        # Next move any preceding vocatives and their subgraphs unless we are in the first sentence
        if i > 0
          tokens.select { |t| t.relation and t.relation.tag == "voc" and t.token_number < pred.min_token_number and t.token_number > roots[i-1].max_token_number }.each do |tt|
            tt.subgraph_set.each do |ttt|
              ttt.sentence_id = new_s.id
              ttt.save_without_validation!
              new_s.dependency_tokens.reload
            end
          end
        end

        # Now move any intercalated tokens (punctuation, vocatives, parpreds) and their subgraphs
        range = (new_s.dependency_tokens.reject(&:is_empty?).map(&:token_number).first)..(new_s.dependency_tokens.reject(&:is_empty?).map(&:token_number).last)
        tokens.select { |t| range.include?(t.token_number) or (t.is_empty? and range.include?(t.max_token_number)) }.each do |tt|
          tt.subgraph_set.each do |ttt|
            ttt.sentence_id = new_s.id
            ttt.save_without_validation!
            new_s.dependency_tokens.reload
          end
        end

        
        # Then we take in any following punctuation unless we are in the last sentence
        if i < (roots.size - 1)
          tokens.select { |t| t.token_number > pred.max_token_number and t.token_number < roots[i+1].min_token_number }.each do |tt|
            if tt.sort == :punctuation
              tt.sentence_id = new_s.id
              tt.save_without_validation!
            else
              break
            end
          end
        end
        new_s.tokens.reload
        new_s.dependency_tokens.reload
        new_s.save_without_validation!

        # Reload the tokens and relinearize them
        new_s.tokens.reload
        new_s.tokens.each_with_index { |t, i| t.token_number = i; t.save_without_validation! }


        # Inherit annotator and reviewer information
        new_s.annotated_by = self.annotated_by
        new_s.annotated_at = self.annotated_at
        new_s.reviewed_by = self.reviewed_by
        new_s.reviewed_at = self.reviewed_at

        new_s.save_without_validation!
      end

      raise "Orphaned tokens #{tokens.select {|t| Token.find(t.id).sentence_id == self.id}.map(&:form).join(",")} in sentence #{self.id} " unless tokens.select {|t| Token.find(t.id).sentence_id == self.id}.empty?

      self.destroy
    end
  end  
end
