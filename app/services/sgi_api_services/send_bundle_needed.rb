# -*- encoding : UTF-8 -*-
class SgiApiServices::SendBundleNeeded
  def self.execute
    new().execute
  end

  def execute
    deliver_types.each do |delivery_type|
       data = process_bundle_needed_of delivery_type

       send_with_typhoeus(delivery_type, { datas: { bundling_documents: data } }) if data.any?
    end
  end

  private

  def deliver_types
    ["upload", "dematbox_scan", "scan"]
  end

  def process_bundle_needed_of(delivery_type)
    temp_documents = []

    TempPack.bundle_processable.each do |temp_pack|
      temp_pack.temp_documents.by_source(delivery_type).bundle_needed.by_position.each do |temp_document|
        if temp_document.bundle_needed?
          temp_documents <<  {
            id: temp_document.id,
            temp_pack_name: temp_document.temp_pack.name,
            temp_document_url: Domains::BASE_URL + temp_document.try(:get_access_url),
            delivery_type: temp_document.delivery_type,
            base_file_name: temp_document.name_with_position
          }.with_indifferent_access
        end
      end
    end

    temp_documents
  end

  def send_with_typhoeus(delivery_type, body)
    request = Typhoeus::Request.new(
      "https://production.idocus.com/api/pieces/grouping/#{delivery_type.to_s}",
      method:  :post,
      headers:  {
                  'Accept' => 'application/json',
                  'Authorization' => "#{token}",
                  'Content-Type' => "application/json"
                },
      body: body.to_json
    )

    @response = request.run

    p "#{@response.code}"
    p result = JSON.parse(@response.body) if @response.body.present?
  end

  def token
    'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjQ4MDAwNjQzNDgsImlzcyI6IldhYllSamZkNjRQTnA3SmRLYkFRTWstR2RPVWJpSGtNS0pxdlhvb1ctNm1NN2w0LWlKMkY3VW1YYzVkaldlaUJnMzR6YXh5V0FuWmNEbG5RZEhwbFhVVTZPMmxvWXprdUhqWWxSeEM0ZHZjN05fZWpRcFJrYmMwRVBaeGFHbk9kXzRpZW5BIiwiaWF0IjoxNjQ0MzkwNzQ4fQ.GYmy9Xzh8q4hO1GZSd101I16YAIxyjnLXEKTKseIWpc'
  end
end