class V3::UserSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :code, :company, :first_name, :last_name, :email, :registration_number, :address_street, :address_zip_code, :address_city
end