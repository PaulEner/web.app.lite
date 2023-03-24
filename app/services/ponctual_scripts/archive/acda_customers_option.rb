class PonctualScripts::AcdaCustomersOption < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    current_period = CustomUtils.period_of(Time.now)
    next_period    = CustomUtils.period_of(1.month.after)

    organization = Organization.find_by_code 'ACDA'
    user_code = []

    organization.customers.active_at(Time.now).each do |customer|
      next if ['ACDA%OPOMBAL', 'ACDA%WTDC', 'ACDA%MIAMS'].include?(customer.code)

      current_package = customer.package_of(current_period)
      next_package    = customer.package_of(next_period)

      user_code << customer.code if current_package.try(:mail_active) || next_package.try(:mail_active)

      current_package.update(mail_active: false) if current_package.try(:mail_active)
      next_package.update(mail_active: false)    if next_package.try(:mail_active)
    end

    p user_code
  end

  def backup
  end
end