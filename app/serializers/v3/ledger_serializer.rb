class V3::LedgerSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :name, :pseudonym, :kind
end