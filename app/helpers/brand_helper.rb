module BrandHelper
  def brand_name_from_request(request)
    if request.env["SERVER_NAME"].include?("axelium")
      'Axelium'
    elsif request.env["SERVER_NAME"].include?('dkpartners')
      'DK Partners'
    elsif request.env["SERVER_NAME"].include?('censial')
      'Censial Online'
    elsif request.env["SERVER_NAME"].include?('orial')
      'My Orial'
    else
      'iDocus'
    end
  end
end