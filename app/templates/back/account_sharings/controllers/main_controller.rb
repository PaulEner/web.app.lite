# frozen_string_literal: true
class Admin::AccountSharings::MainController < BackController
  prepend_view_path('app/templates/back/account_sharings/views')

  def index
    @account_sharings = AccountSharing.unscoped
                                      .search(search_terms(params[:account_sharing_contains]))
                                      .order(sort_column => sort_direction)
                                      .page(params[:page])
                                      .per(params[:per_page])
  end

  private

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end