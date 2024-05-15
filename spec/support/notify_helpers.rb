# frozen_string_literal: true

require_relative '../../services/notify_service'

module NotifyHelpers
  def find_notification_reference(id)
    page.find("##{id}", visible: false).value
  end

  def wait_for_notification(notification_reference)
    email = NotifyService.new.get_email(notification_reference)

    logger.debug "Waiting 3sec for mail delivery to do its thing."

    if email.collection && email.collection.first && email.collection.first.status
      status = email.collection.first.status
      logger.debug "Received the following status from Notify: #{status}"
      return email.collection.first
    end

    raise "ABORT!!! #{notification_reference} could not be found in Notify!!!"
  end

  def wait_for_confirmation_code(notification_reference)
    confirmation_email = wait_for_notification(notification_reference)
    code = confirmation_email.body.match(/\d{6}/).to_s
    logger.debug "Received the following code from Notify: “#{code}“"
    return code
  end
end
