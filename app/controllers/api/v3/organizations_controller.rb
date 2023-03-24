class Api::V3::OrganizationsController< Api::V3::MainController
  def current
    render(json: serializer.new(authenticated_organization, serializer_options).serializable_hash, status: :created)
  end

  private

  def serializer
    ::V3::OrganizationSerializer
  end

  def serializer_options
    { }
  end
end