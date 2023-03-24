class PonctualScripts::CalculateCommitment < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    User.all.each do |user|
      next if user.is_prescriber

      ['ido_nano', 'ido_micro'].each do |package_name|
        __package_name = 'ido_nano'                      if package_name == 'ido_nano'
        __package_name = ['ido_micro', 'ido_micro_plus'] if package_name == 'ido_micro'

        packages = user.packages.where(name: __package_name).order(period: :asc)
        if packages.present?
          start_period = packages.first.period
          end_period   = CustomUtils.period_operation(start_period, 12)

          p "======== Updating : #{user.code} : #{packages.count} => #{start_period} / #{end_period}"
          packages.update_all(commitment_start_period: start_period, commitment_end_period: end_period)
        end
      end
    end; nil
  end

  def backup
  end
end