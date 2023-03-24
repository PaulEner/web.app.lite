# -*- encoding : UTF-8 -*-
# FIXME : whole check

module LayoutsHelper
  #
  # Usage: For example, suppose "child" layout extends "parent" layout.
  # Use <%= yield %> as you would with non-nested layouts, as usual. Then on
  # the very last line of front/layouts/child.html.haml, include this:
  #
  # <% parent_layout "parent" %>
  #

  def parent_layout(layout)
    @view_flow.set(:layout, output_buffer)
    output = render(:file => "front/layouts/#{layout}")
    self.output_buffer = ActionView::OutputBuffer.new(output)
  end
end