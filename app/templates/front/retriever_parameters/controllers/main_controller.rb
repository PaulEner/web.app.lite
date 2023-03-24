# frozen_string_literal: true
class RetrieverParameters::MainController < RetrieverController
  before_action :verif_account
  prepend_view_path('app/templates/front/retriever_parameters/views')

  def index;  end
end