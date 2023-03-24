require 'swagger_helper'

RSpec.describe 'api/v3/users', type: :request do
  path '/api/v3/users' do
    get 'Returns the list of users for the authenticated organization' do
      tags 'Users'
      consumes 'application/json'
      security [{ bearer: [] }]

      response '200', 'returns the list of users' do
        run_test!
      end

      response '401', 'Token is invalid' do
        run_test!
      end
    end
  end
end
