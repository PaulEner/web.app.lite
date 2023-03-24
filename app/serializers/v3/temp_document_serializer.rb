class V3::TempDocumentSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :user_id
end