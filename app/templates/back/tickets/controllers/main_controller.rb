# frozen_string_literal: true
class Admin::Tickets::MainController < BackController
  prepend_view_path('app/templates/back/tickets/views')

  # GET /admin/events
  def index
    @tickets = Ticket.search(search_terms(params[:ticket_contains])).order(sort_column => sort_direction).page(params[:page]).per(params[:per_page])
  end

  def new
    @ticket = Ticket.new 

    render partial: 'form'
  end

  def create
    ticket                  = Ticket.new
    ticket.user             = current_user
    params[:ticket][:content] += "\n---------------" + "\n" + "Fait le " + Time.now.strftime('%Y-%m-%d %H:%M').to_s
    ticket.assigned_to_name = params[:ticket][:assigned_to].present? ? User.find(params[:ticket][:assigned_to]).name : ""
    ticket.update_attributes(ticket_params)

    render json: { success: true, url: admin_tickets_path }, status: 200 
  end

  def edit
    @ticket = Ticket.find(params[:id]) 

    render partial: 'form' 
  end

  def update
    ticket = Ticket.find(params[:id])
    ticket.content = ticket.content.to_s + "\n\n--------------------------------------------------------\n" + params[:content_add] + "\n---------------" + "\n" + "Echange ajoutée le " + Time.now.strftime('%Y-%m-%d %H:%M').to_s
    ticket.assigned_to_name = params[:ticket][:assigned_to].present? ? User.find(params[:ticket][:assigned_to]).name : ""
    ticket.update_attributes(ticket_params)
    
    render json: { success: true, url: admin_tickets_path }, status: 200 
  end

  def waiting
    ticket = Ticket.find(params[:id])
    ticket.waiting
    
    redirect_to admin_tickets_path
  end

  def processing
    ticket = Ticket.find(params[:id])
    ticket.processing
    
    redirect_to admin_tickets_path    
  end

  def destroy
    ticket = Ticket.find(params[:id])
    ticket.destroy

    redirect_to admin_tickets_path
  end

  def close
    ticket = Ticket.find(params[:id])
    ticket.closed_by = current_user.name
    ticket.closed_date = Time.now

    ticket.closed
    
    redirect_to admin_tickets_path
  end

  private

  def ticket_params    
    params.require(:ticket).permit!
  end

  def sort_column
    params[:sort] || 'id'
  end
  helper_method :sort_column

  def sort_direction
    params[:direction] || 'desc'
  end
  helper_method :sort_direction
  helper_method :sort_direction
end