module StatisticsManager::Subscription

  def self.generate_current_statistics
    generate_statistics_of 1.month.ago 
    generate_statistics_of Date.today
  end

  def self.generate_statistics_of(date)
    start_date   = date.to_date.beginning_of_month
    end_date     = date.to_date.end_of_month
    period_date  = CustomUtils.period_of(start_date)

    Organization.billed.where("created_at <= ?", end_date).order(created_at: :asc).each do |organization|
      options     = { micro_package: 0, nano_package: 0, basic_package: 0, mail_package: 0, scan_box_package: 0, retriever_package: 0, mini_package: 0, idox_package: 0, digitize_package: 0, premium_package: 0 }
      consumption = { upload: 0, scan: 0, dematbox_scan: 0, retriever: 0 }

      user_ids = []
      organization.customers.active.each do |customer|
        package = customer.package_of(period_date)
        next if not package

        case package.name
          when 'ido_classic'
            options[:basic_package] += 1
          when 'ido_nano'
            options[:nano_package] += 1
          when 'ido_x'
            options[:idox_package] += 1
          when 'ido_micro' || 'ido_micro_plus'
            options[:micro_package] += 1
          when 'ido_retriever'
            options[:retriever_package] += 1
          when 'ido_digitize'
            options[:digitize_package] += 1
          when 'ido_premium'
            options[:premium_package] += 1
          end

          options[:mail_package] += 1       if package.mail_active
          options[:retriever_package] += 1  if package.bank_active && package.name != 'ido_retriever'
          options[:digitize_package] += 1   if package.digitize_active && package.name != 'ido_digitize'

        user_ids << package.user_id if package.user_id
      end

      #consumption counter
      customers = User.where(id: user_ids)
      delivery_types  = customers.joins(:temp_documents).where("temp_documents.state = 'processed' and temp_documents.created_at >= ? and temp_documents.created_at <= ?",start_date, end_date).group("delivery_type").select("temp_documents.delivery_type as delivery_type, count(distinct users.code) as count")

      delivery_types.each { |delivery| consumption[delivery.delivery_type.to_sym] = delivery.count }

      StatisticsManager.create_subscription_statistics({organization: organization, date: start_date, options: options, consumption: consumption, customers: customers.map(&:code)})
    end
  end

  def self.compare_statistics_between(first_date, second_date)
    first_date = first_date.to_date.beginning_of_month
    second_date = second_date.to_date.beginning_of_month
    compared_statistics = []
    SubscriptionStatistic.where(month: [first_date, second_date]).order(:month).group_by(&:organization_id).each_pair do |organization_id, stats|
      next unless Organization.billed.where(id: organization_id).first
      statistic = if stats.length == 2
        options = {}
        stats[1].options.keys.each do |key|
          options[key] = stats[1].options[key]
          options["#{key}_diff".to_sym] = stats[1].options[key].to_i - stats[0].options[key].to_i
        end
        SubscriptionStatistic.new(
          month: stats[1].month,
          organization_id: stats[1].organization_id,
          organization_name: stats[1].organization_name,
          organization_code: stats[1].organization_code,
          options: options,
          consumption: stats[1].consumption,
          customers: stats[1].customers,
          new_customers: stats[1].customers - stats[0].customers,
          closed_customers: stats[0].customers - stats[1].customers
        )
      else
        stats[0].dup
      end
      compared_statistics << statistic
    end
    compared_statistics
  end
end