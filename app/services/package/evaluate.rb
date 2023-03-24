class Package::Evaluate
  def initialize(package)
    @package = package
  end

  def execute(params)
    period_index = @package.period - 1
    period_index = @package.period - 89 if period_index.to_s.last == '0'

    prev_package = @package.user.package_of(period_index)

    options.each do |opt, val|
      if val == 'none'
        value = false
      elsif val == 'strict'
        value = true
      else
        value = (params[opt.to_sym].to_i > 0)? true : false
      end

      case opt.to_s
        when 'upload'
          @package.upload_active = value
        when 'bank'
          @package.bank_active = value
        when 'scan'
          @package.scan_active = value
        when 'preassignment'
          @package.preassignment_active = value
        when 'mail'
          @package.mail_active = value
      end
    end

    if @package.name != prev_package.name
      @package.version = prev_package.version + 1

      if @package.commitment_duration > 0
        @package.commitment_start_period = CustomUtils.period_of(Time.now)
        @package.commitment_end_period   = CustomUtils.period_of( @package.commitment_duration.month.after )
      else
        @package.commitment_start_period = nil
        @package.commitment_end_period   = nil
      end
    end

    @package.save
  end
end