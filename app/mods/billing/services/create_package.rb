class BillingMod::CreatePackage
  def initialize(user, package_name, options, apply_now = false, requester=nil)
    @user         = user
    @package_name = package_name
    @options      = options
    @requester    = requester

    @my_package   = @user.my_package
    @apply_now    = (@my_package.present?)? apply_now : true

    @period      = CustomUtils.period_of(Time.now)
    @next_period = CustomUtils.period_of(1.month.after)
  end

  def execute
    return false if not @package_name

    @package_conf = BillingMod::Configuration::LISTS[@package_name.to_sym]

    if @apply_now
      _period = @period
      @user.package_of(@next_period).try(:destroy)
    else
      _period = @period

      if @my_package.present? && ( has_options_to_disable || @package_name != @my_package.name )
        _period = @next_period
      end
    end

    package        = @user.package_of(_period) || BillingMod::Package.new
    package.user   = @user
    package.period = _period
    package.name   = @package_name

    package.preassignment_active = activate?(:preassignment)
    package.upload_active        = activate?(:upload)
    package.mail_active          = activate?(:mail)
    package.bank_active          = activate?(:bank)
    package.scan_active          = activate?(:scan)

    package.commitment_start_period = @my_package.try(:commitment_start_period).to_i
    package.commitment_end_period   = @my_package.try(:commitment_end_period).to_i

    if @package_conf[:commitment].to_i > 0 && (package.commitment_start_period.to_i == 0 || package.name != @my_package.try(:name))
      package.commitment_start_period = @period
      package.commitment_end_period   = CustomUtils.period_of(@package_conf[:commitment].to_i.month.after)
    elsif @package_conf[:commitment].to_i == 0
      package.commitment_start_period = 0
      package.commitment_end_period   = 0
    end

    package.save

    update_journal_size

    Journal::AssignDefault.new(@user, @requester).execute if @requester
  end

  private

  def _params(name)
   return @options[name.to_sym].present?
  end

  def activate?(option)
    @package_conf = BillingMod::Configuration::LISTS[@package_name.to_sym]
    options       = @package_conf[:options]

    if option.to_s == 'scan' && CustomUtils.is_manual_paper_set_order?(@user.organization) && options[:digitize] == 'optional'
      return _params(option.to_sym)
    elsif options[option.to_sym] == 'strict'
      return true
    elsif options[option.to_sym] == 'optional' && _params(option.to_sym)
      return true
    else
      return false
    end
  end

  def has_options_to_disable
    opts                = ['scan', 'preassignment', 'mail', 'bank']
    to_deactivate_count = 0

    if @package_name == @my_package.try(:name)
      opts.each do |opt|
        to_deactivate_count += 1 if @my_package.send("#{opt}_active".to_sym) == true && activate?(opt.to_sym) == false
      end
    end

    return (to_deactivate_count > 0)? true : false
  end

  def update_journal_size
    return false if @options['number_of_journals'].to_i < 5

    current_package = @user.package_of(@period)
    next_package    = @user.package_of(@next_period)
    journal_size    = 5
    user_journal_size = @user.account_book_types.size

    if user_journal_size < @options['number_of_journals'].to_i
      journal_size = @options['number_of_journals'].to_i
    else
      journal_size = user_journal_size
    end
    journal_size = 5 if journal_size < 5

    current_package.update(journal_size: journal_size) if current_package
    next_package.update(journal_size: journal_size)    if next_package
  end
end