class Organization::Create
  def initialize(params)
    @params = params
  end

  def execute
    organization = Organization.new @params
    ActiveRecord::Base.transaction do
      if organization.save
        organization.find_or_create_subscription
        DebitMandate.create!(organization: organization)
      end
    end
    organization
  end
end
