# frozen_string_literal: true

require_relative '../../services/notify_service'

module NotifyHelpers
  def get_confirmation_from_notify(expected_mail_reference, confirmation_code: false)
    email = NotifyService.new.get_email(expected_mail_reference)

    start_time = Time.now
    logger.debug "Waiting 3sec for mail delivery to do its thing."
    sleep 3
    try = 0
    while(Time.now - start_time < 5000) do
      try += 1

      if confirmation_code
        unless email.collection.first.body.nil?
          code = email.collection.first.body.match(/\d{6}/).to_s
          logger.debug "Received the following code from Notify: “#{code}“"
          return code
        end
      else
        unless email.collection.first.status.nil?
          status = email.collection.first.status
          logger.debug "Received the following status from Notify: “#{status}“"
          return email.collection.first
        end
      end

      wait_time = try + ((Time.now - start_time) ** 0.5)
      logger.debug 'failed. Sleeping %0.2fs.' % wait_time
      sleep wait_time
    end
    return false
  end
end
