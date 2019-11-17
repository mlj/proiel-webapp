module Proiel
  class SentenceAnnotationValidator < ::ActiveModel::Validator
    def validate(record)
      # FIXME? This breaks creation of new sentences
      # # Constraint: sentence must have at least one token.
      # if tokens.length < 1
      #   errors.add_to_base("Sentence must have at least one token")
      # end

      #   has_dependency_annotation       sentence is dependency annotated
#      has_dependency_annotation = record.has_dependency_annotation?

      # Invariant: sentence is annotated => sentence is dependency annotated
#      if record.is_annotated? and not has_dependency_annotation
#        record.errors[:base] << "Annotated sentence must have dependency annotation"
#      end

      # Invariant: sentence is dependency annotated <=>
      # all dependency tokens have non-nil relation attributes <=> there exists one
      # dependency token with non-nil relation.
#     relation_tags = record.tokens.takes_syntax.pluck(:relation_tag)
#     if relation_tags.any? and !relation_tags.all?
#       record.errors[:base] << "Dependency annotation must be complete"
#     end
#
#     record.tokens.takes_syntax.each do |t|
#       t.slash_out_edges.each do |se|
#         add_dependency_error("Unconnected slash edge", [t]) if se.slashee.nil?
#         add_dependency_error("Unlabeled slash edge", [t]) if se.relation.nil?
#       end
#     end

      # Check each token for validity (this could of course also be done with validates_associated),
      # but that leads to confusing error messages for users.
      #record.tokens.each do |t|
      #  unless t.valid?
      #    t.errors.to_a.each { |msg| add_dependency_error(record, msg, [t]) }
      #  end
      #end

      # Invariant: sentence is dependency annotated => dependency graph is valid
#      if record.is_annotated? and has_dependency_annotation
#        begin
#          record.dependency_graph.valid?(lambda { |token_ids, msg| add_dependency_error(record, msg, Token.find(token_ids)) })
#        rescue
#          record.errors[:base] << "An inconsistency in the dependency graph prevented validation"
#        end
#      end
    end

    def add_dependency_error(record, msg, tokens)
      ids = tokens.map(&:token_number)
      record.errors[:base] << "Token #{'number'.pluralize(ids)} #{ids.to_sentence}: #{msg}"
    end
  end
end
