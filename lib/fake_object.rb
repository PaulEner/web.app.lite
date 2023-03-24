class FakeObject
  def initialize(options=nil)
    @object = OpenStruct.new(options)
  end

  def method_missing(name, *args, &block)
    begin
      @object.send(name, args)
    rescue
      begin
        value = @object.send(name)
        value.is_a?(Array) ? value.first : value
      rescue
        nil
      end
    end
  end
end