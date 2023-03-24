# frozen_string_literal: true

class Front::IndexController < ApplicationController
  before_action :load_user_and_role
  before_action :verify_suspension
  before_action :verify_if_active

  def index
    render 'layouts/front/layout'
  end

  def notifications
    @notifications = []

    4.times do |i|
      test_notif = FakeObject.new()
      test_notif.id = i + 1
      test_notif.title = '1 erreur détéctée'
      test_notif.date = i.days.ago
      test_notif.content = "IDOC%001 : blabla bla notification N°#{i}"

      @notifications << test_notif
    end

    render 'layouts/front/notifications'
  end
end
