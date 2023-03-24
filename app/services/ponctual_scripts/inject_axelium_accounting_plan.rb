class PonctualScripts::InjectAxeliumAccontingPlan < PonctualScripts::PonctualScript
  def self.execute(file_path)
    new({file_path: file_path}).run
  end

  private

  def execute
    @file_path = @options[:file_path]

    if File.exist?(@file_path)
      organization = Organization.find_by_code 'ALM'

      customers = organization.customers.active_at(Time.now)

      customers.each_with_index do |customer, index|
        accounting_plan = customer.accounting_plan
        next if not accounting_plan

        logger_infos "[Axelium] -> Current user: #{customer.my_code} - #{accounting_plan.active_providers.size} - #{index} / #{customers.size}"
        accounting_plan.import(File.open(@file_path, 'r'), 'providers')

        logger_infos "[Axelium] -> End user: #{customer.my_code} - #{accounting_plan.reload.active_providers.size}"
      end
    else
      logger_infos "[Axelium] => File not found : #{@file_path.to_s}"
    end
  end
end