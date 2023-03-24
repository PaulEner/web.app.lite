class AccountingPlan::SageGecUpdateWorker
  include Sidekiq::Worker

  def perform(user_id=nil)
    if user_id.present?
      customer = User.find user_id
      AccountingPlan::SageGecUpdateWorker::Launcher.delay.update_sage_gec_for(customer.id)
    else
      UniqueJobs.for "AccountingPlanSageGecUpdateOrganization", 1.day do
        Organization.all.each do |organization|          
          organization.customers.order(code: :asc).active.each do |customer|
            AccountingPlan::SageGecUpdateWorker::Launcher.delay.update_sage_gec_for(customer.id)

            sleep(5)
          end
        end
      end
    end
  end

  class Launcher
   def self.update_sage_gec_for(customer_id)
      UniqueJobs.for "AccountingPlanSageGecUpdate-#{customer_id}", 1.day do
        customer = User.find(customer_id)

        AccountingPlan::SageGecUpdate.new(customer).run
      end
    end
  end
end