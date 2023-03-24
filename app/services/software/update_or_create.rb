class Software::UpdateOrCreate

  class << self
    def assign_or_new(attributes)      
      software = attributes[:owner].send(attributes[:software].to_sym).presence || Interfaces::Software::Configuration.softwares[attributes[:software].to_sym].new

      begin
        software.assign_attributes(attributes[:columns])
      rescue
        software.assign_attributes(attributes[:columns].to_unsafe_hash)
      end

      software.owner = attributes[:owner]      
      software.save
    end
  end
end