# frozen_string_literal: true
class Admin::PreAssignmentDeliveries::MainController < BackController
  prepend_view_path('app/templates/back/pre_assignment_deliveries/views')

 # GET /admin/pre_assignment_deliveries
  def index
    case params[:software]
    when 'ibiza'
      ibiza_deliveries
    when 'exact_online'
      exact_online_deliveries
    when 'my_unisoft'
      my_unisoft_deliveries
    when 'sage_gec'
      sage_gec_deliveries
    when 'acd'
      acd_deliveries
    else
      ibiza_deliveries
    end

    @pre_assignment_deliveries_count = @pre_assignment_deliveries.count

    @pre_assignment_deliveries = @pre_assignment_deliveries.page(params[:page]).per(params[:per_page])
  end

  # GET /admin/pre_assignment_deliveries/:id
  def show
    @delivery = PreAssignmentDelivery.find params[:id]
  end

  private

  def ibiza_deliveries
    @pre_assignment_deliveries_software = 'Ibiza'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).ibiza.order(sort_column => sort_direction)
  end

  def exact_online_deliveries
    @pre_assignment_deliveries_software = 'Exact Online'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).exact_online.order(sort_column => sort_direction)
  end

  def my_unisoft_deliveries
    @pre_assignment_deliveries_software = 'My Unisoft'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).my_unisoft.order(sort_column => sort_direction)
  end

  def sage_gec_deliveries
    @pre_assignment_deliveries_software = 'Sage GEC'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).sage_gec.order(sort_column => sort_direction)
  end

  def acd_deliveries
    @pre_assignment_deliveries_software = 'ACD'
    @pre_assignment_deliveries = PreAssignmentDelivery.search(search_terms(params[:pre_assignment_delivery_contains])).acd.order(sort_column => sort_direction)
  end

  def sort_column
    params[:sort] || 'id'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
end