class V3::OrganizationSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name
end