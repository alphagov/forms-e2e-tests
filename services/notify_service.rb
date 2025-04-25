require "notifications/client"

class NotifyService
  def initialize
    @notify_api_key = ENV["SETTINGS__GOVUK_NOTIFY__API_KEY"]
  end

  def get_email(notification_id)
    if @notify_api_key.blank?
      raise "You must set SETTINGS__GOVUK_NOTIFY__API_KEY"
    end

    client = Notifications::Client.new(@notify_api_key)
    client.get_notifications({ reference: notification_id })
  end
end
