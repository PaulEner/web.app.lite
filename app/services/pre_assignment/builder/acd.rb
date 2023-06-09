class PreAssignment::Builder::Acd < PreAssignment::Builder::DataService
  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super

    @software = @delivery.user.acd
  end

  private

  def execute
    @delivery.building_data

    response = AcdLib::DataBuilder.new(@preseizures).execute

    if response[:data_built]
      save_data_to_storage(response[:data], 'txt')

      building_success response[:data_count]
    else
      building_failed response[:error_messages]
    end
  end
end