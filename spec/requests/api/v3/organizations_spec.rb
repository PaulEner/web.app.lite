require 'swagger_helper'

RSpec.describe 'api/v3/organizations', type: :request do
  path '/api/v3/organizations/current' do
    get 'Returns the authenticated organization informations' do
      tags 'Organizations'
      consumes 'application/json'
      security [{ bearer: [] }]

      response '200', 'returns the current organization' do
        run_test!
      end

      response '401', 'Token is invalid' do
        run_test!
      end
    end
  end
end
