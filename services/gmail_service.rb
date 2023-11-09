# frozen_string_literal: true

require 'mail'
require 'timeout'

class GmailService < Mail::POP3
  def initialize(user_name, app_password)
    super({
      address: 'pop.gmail.com',
      port: 995,
      user_name:,
      password: app_password,
      enable_ssl: true
    })
  end

  def check_for_email(to, subject_regex)
    timeout = 60 # seconds to wait for an email
    Timeout.timeout(timeout) do
      loop do
        # We fetch the first ten emails here - if we don't and the e2e tests
        # 'get behind' - more codes are sent than have been requested, we can
        # end up using an old code and manual intervention would be required.
        new_mail = find(what: :first, count: 10, order: :desc).find do |mail|
          mail.to.first == to && mail.subject.match?(subject_regex)
        end
        return new_mail unless new_mail.nil?

        sleep 10 # check every 10 seconds
      end
    end
  rescue Timeout::Error
    raise EmailNotFound, "No email found matching #{subject_regex} sent to #{to} within #{timeout} seconds."
  end
end
