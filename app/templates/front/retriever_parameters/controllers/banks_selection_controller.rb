# frozen_string_literal: true
class RetrieverParameters::BanksSelectionController < RetrieverController
  before_action :verif_account
  prepend_view_path('app/templates/front/retriever_parameters/views')

  def index
    render partial: 'banks_selection'
  end
end