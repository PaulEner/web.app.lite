# frozen_string_literal: true
class RetrievedDatas::MainController < RetrieverController
  before_action :verif_account
  prepend_view_path('app/templates/front/retrieved_datas/views')

  def index
    redirect_to retrievers_historics_v2_path if !@user.pre_assignement_displayed? && CustomUtils.use_final_documents?(@user)
  end
end