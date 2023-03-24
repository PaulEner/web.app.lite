require 'swagger_helper'

RSpec.describe 'api/v3/inbound_documents', type: :request do
  path '/api/v3/inbound_documents' do
    post 'Creates document. Identify user by user_id OR idocus code OR legal_identifier (SIREN). Identify ledger by name (ex: AC) OR ledger_id' do
      tags 'Inbound Documents'
      consumes 'application/json'
      security [{ bearer: [] }]
      parameter name: :inbound_document, in: :body, schema: {
        type: :object,
        properties: {
          filename: { type: :string },
          content_base64: { type: :string },
          user_id: { type: :integer },
          user_code: { type: :string },
          user_legal_identifier: { type: :string },
          ledger_name: { type: :string },
          ledger_id: { type: :integer },
        }
      }

      response '201', 'Successfully saved the document' do
        run_test!
      end

      response '422', 'Unable to store document' do
        run_test!
      end

      response '404', 'User and/or ledger have not been found' do
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
