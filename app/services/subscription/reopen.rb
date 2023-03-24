# -*- encoding : UTF-8 -*-
# Re-activate a user who has previously been disabled
class Subscription::Reopen
  def initialize(user, requester=nil, request = nil)
    @user = user
  end

  def execute
    @user.inactive_at = nil
    @user.save

    my_package = @user.my_package
    my_package.update(is_active: true)

    @user.find_or_create_external_file_storage

    @user.save
  end
end
