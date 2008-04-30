require 'mlj/form_helper'

ActionView::Base.send                 :include, MLJ::FormHelper
ActionView::Helpers::InstanceTag.send :include, MLJ::InstanceTag
ActionView::Helpers::FormBuilder.send :include, MLJ::FormBuilderMethods

ActionView::Base.default_form_builder = MLJ::FormBuilder
