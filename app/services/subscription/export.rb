class Subscription::Export
  def initialize(period)
    @period = period
    @date   = CustomUtils.period_to_date(period)
  end

  def execute
    datas  = []
    header = ['Période', 'Code', 'Organisation', 'Basique', 'Micro', 'Nano', 'iDocX', 'Automate U.', 'Numérisation U.', 'Premium', 'O. Courrier', 'O. Numérisation', 'O. Banque', 'Actifs', 'Nouveaux', 'Cloturés']

    datas << header.join(';')

    concerned_organization.each do |organization|
      accounts_ids = organization.customers.active_at(@date.end_of_month).pluck(:id)
      packages     = BillingMod::Package.where(user_id: accounts_ids, period: @period)

      line = []

      line << "#{@period.to_s[0..3]} - #{@period.to_s[4..5]}"
      line << organization.code
      line << organization.name

      packages_list.each do |package|
        if package == 'ido_micro'
          line << packages.where(name: ['ido_micro', 'ido_micro_plus']).count
        else
          line << packages.where(name: package).count
        end
      end

      options_list.each do |option|
        line << packages.where("#{option} = true").count
      end

      line << packages.size
      line << organization.customers.active_at(@date.end_of_month).where("DATE_FORMAT(created_at, '%Y%m') = #{@period}").count
      line << organization.customers.closed.where('created_at < ?', @date.end_of_month).count

      datas << line.join(';')
    end

    datas.join("\n")
  end

  private

  def concerned_organization
    Organization.billed.order(code: :asc)
  end

  def packages_list
    #IMPORTANT : must be arrange accourding to the header
    ['ido_classic', 'ido_micro', 'ido_nano', 'ido_x', 'ido_retriever', 'ido_digitize', 'ido_premium']
  end

  def options_list
    #IMORTANT : must be arrange accourding to the header
    ['mail_active', 'scan_active', 'bank_active']
  end
end
