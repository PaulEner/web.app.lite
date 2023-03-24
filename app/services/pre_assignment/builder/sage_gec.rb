class PreAssignment::Builder::SageGec < PreAssignment::Builder::DataService
  def self.execute(delivery)
    new(delivery).run
  end

  def initialize(delivery)
    super

    @software = @delivery.user.sage_gec
  end

  private

  def execute
    @delivery.building_data

    response = SageGecLib::DataBuilder.new(@preseizures).execute

    if response[:data_built]
      save_data_to_storage(response[:data], 'txt')

      building_success response[:data_count]
    else
      building_failed response[:error_messages]
    end
  end
end