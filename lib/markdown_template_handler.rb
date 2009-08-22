#--
#
# Copyright 2009 Marius L. Jøhndal
#
# The program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# The program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the program. If not, see <http://www.gnu.org/licenses/>.
#
#++

module ActionView
  module TemplateHandlers
    class Markdown < TemplateHandler
      include ActionView::Helpers::TextHelper

      def initialize(view)
        @view = view
      end

      def render(template, local_assigns = {})
        '<div class="markdown">' + markdown(template.source) + '</div>'
      end
    end
  end
end
 
ActionView::Template.register_template_handler 'markdown', ActionView::TemplateHandlers::Markdown
