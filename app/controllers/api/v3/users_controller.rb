class Api::V3::UsersController< Api::V3::MainController
  def index
    users = authenticated_organization.users.includes(:account_book_types)

    render(json: serializer.new(users, serializer_options).serializable_hash, status: :created)
  end

  private

  def serializer
    ::V3::UserSerializer
  end

  def serializer_options
    { }
  end
end