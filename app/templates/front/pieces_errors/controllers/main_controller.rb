# frozen_string_literal: true

class PiecesErrors::MainController < FrontController
  skip_before_action :verify_if_active, only: %w[index]
  prepend_view_path('app/templates/front/pieces_errors/views')

  def index
    @_params = params[:_ext].present? ? JSON.parse(Base64.decode64(params[:k])).with_indifferent_access : params
  end
end