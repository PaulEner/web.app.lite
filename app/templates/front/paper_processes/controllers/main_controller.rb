# frozen_string_literal: true
class PaperProcesses::MainController < FrontController
  before_action :verify_rights

  prepend_view_path('app/templates/front/paper_processes/views')

  # GET /account/paper_processes
  def index
    @paper_processes = PaperProcess.where(user_id: accounts)
                                   .search(search_terms(params[:paper_process_contains]))
                                   .includes(:user)
                                   .order(sort_column => sort_direction)
                                   .page(params[:page])
                                   .per(params[:per_page])
  end

  private

  def verify_rights
    unless accounts.detect { |e| e.my_package.try(:upload_active) }
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end

  def sort_column
    params[:sort] || 'created_at'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end