class PonctualScripts::IdoNanoExtentis < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    extents_exception = %w[FBC%HABHAB FBC%CLESENMAIN FIDC%LAHOUAR EG%DEGAULEJAC EG%LEGALL EXT%COSICH]
    organization      = Organization.find_by_code 'EXT'
    customers         = organization.customers.active_at(Time.now)
    period            = CustomUtils.period_of(Time.now)

    customers.each do |customer|
      package = customer.my_package

      next if not ['ido_micro', 'ido_micro_plus', 'ido_classic'].include?(package.name)

      logger_infos "[IdoNanoExtentis] - customers code : #{customer.code.to_s} - Start"

      if ["ido_micro", "ido_micro_plus"].include?(package.name)
        package.bank_active = extents_exception.include?(customer.code) ? true : false 
      end

      package.name                    = 'ido_nano'
      package.upload_active           = true
      package.scan_active             = true
      package.preassignment_active    = true
      package.commitment_start_period = period
      package.commitment_end_period   = CustomUtils.period_of(12.month.after)

      if package.save
        logger_infos "[IdoNanoExtentis] - customers code : #{customer.code.to_s} - Finished"
      else
        logger_infos "[IdoNanoExtentis] - customers code : #{customer.code.to_s} - Failed - message : #{package.errors.messages.to_s}"
      end
    end
  end

  def backup
    organization      = Organization.find_by_code 'EXT'
    customers         = organization.customers.active_at(Time.now)
    period            = CustomUtils.period_of(Time.now) - 1

    customers.each do |customer|
      last_package    = customer.packages.of_period(period).first
      current_package = customer.my_package

      current_package.destroy

      new_package        = last_package.dup
      new_package.period = period + 1

      new_packages.save

      logger_infos "[IdoNanoExtentis] - customers code : #{customer.code.to_s} - Rollback"
    end
  end
end