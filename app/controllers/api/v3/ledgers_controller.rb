class Api::V3::LedgersController< Api::V3::MainController
  def index
    ledgers = authenticated_organization.users.find(params[:id]).account_book_types

    render(json: serializer.new(ledgers, serializer_options).serializable_hash, status: :created)
  end

  private

  def serializer
    ::V3::LedgerSerializer
  end

  def serializer_options
    { }
  end
end