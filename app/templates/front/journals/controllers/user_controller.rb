# frozen_string_literal: true

class Journals::UserController < CustomerController

  before_action :load_customer
  before_action :verify_rights

  prepend_view_path('app/templates/front/journals/views')

  def index
    @journals         = @customer.account_book_types.order('FIELD(entry_type, 0, 5, 1, 4, 3, 2) DESC', description: :asc)
    @pending_journals = @customer.retrievers.where(journal_id: nil).where.not(journal_name: [nil]).distinct.pluck(:journal_name)
    
    build_softwares
  end

  private

  def load_customer
    @customer = customers.find(params[:customer_id])
  end

  def is_max_number_of_journals_reached?
    return false if @customer.organization.specific_mission

    @customer.account_book_types.count >= @customer.my_package.try(:journal_size).to_i
  end
  helper_method :is_max_number_of_journals_reached?
end