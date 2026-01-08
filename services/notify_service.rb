require "notifications/client"

class NotifyService
  def initialize
    @notify_api_key = Settings.govuk_notify.api_key
  end

  def get_email(notification_id)
    if @notify_api_key.nil? || @notify_api_key.empty?
      raise "Settings.govuk_notify.api_key is not set"
    end

    client = Notifications::Client.new(@notify_api_key)
    client.get_notifications({ reference: notification_id })
  end
end
