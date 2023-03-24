# frozen_string_literal: true
class RetrievedDatasV2::MainController < RetrieverController
  before_action :verif_account
  prepend_view_path('app/templates/front/retrieved_datas_v2/views')

  def index;  end
end