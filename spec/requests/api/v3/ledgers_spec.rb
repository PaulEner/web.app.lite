require 'swagger_helper'

RSpec.describe 'api/v3/users', type: :request do
  path '/api/v3/users/{user_id}/ledgers' do
    get 'Returns the list of ledgers for a user' do
      tags 'Ledgers'
      consumes 'application/json'
      security [{ bearer: [] }]
      parameter name: :user_id, in: :path, type: :string

      response '200', 'returns the list of ledgers for the given user' do
        run_test!
      end

      response '403', 'This organization does not own this user' do
        run_test!
      end

      response '401', 'Token is invalid' do
        run_test!
      end
    end
  end
end
