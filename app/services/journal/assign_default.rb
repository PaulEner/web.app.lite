class Journal::AssignDefault
  def initialize(user, collaborator, request = nil)
    @user         = user
    @package      = @user.my_package
    @request      = request
    @collaborator = collaborator
    @organization = @user.organization
  end

  def execute
    journals.map do |journal|
      next if journal.try(:entry_type) == 4 && !@package.try(:bank_active)
      next if journal.try(:entry_type) == 1 && !@package.try(:preassignment_active)

      new_journal = copy_journal(journal)
      create_event(new_journal)
      new_journal
    end
  end

  private

  def copy_journal(journal)
    new_journal = journal.dup
    new_journal.user         = nil
    new_journal.is_default   = nil
    new_journal.organization = nil

    @user.account_book_types << new_journal

    new_journal.save
    new_journal
  end

  def create_event(journal)
    params = [journal, @user, (@collaborator.try(:user) || @collaborator)]
    params << { path: @request.path, ip_address: @request.remote_ip } if @request

    CreateEvent.add_journal(*params)
  end

  def current_journal_names
    @current_journal_names ||= @user.account_book_types.map(&:name)
  end

  def journals
    result = @organization.account_book_types.default
    result = result.where.not(name: current_journal_names) if current_journal_names.present?

    js = result.where("entry_type > ?", 0).order(entry_type: :asc, name: :asc)
    js += result.where(entry_type: 0).order(name: :asc)

    js.take available_slot
  end

  def available_slot
    # @user.options.max_number_of_journals - @user.account_book_types.size
    return 15 if @user.organization.specific_mission

    (@user.my_package.try(:journal_size).to_i || 5) - @user.account_book_types.size
  end

  def is_preassignment_authorized?
    @user.my_package.try(:preassignment_active)
  end
end
