require 'rotp'
require_relative '../../services/notify_service'
require_relative '../../services/gmail_service'

module FeatureHelpers
  def forms_admin_url
    ENV.fetch("FORMS_ADMIN_URL") { raise "You must set $FORMS_ADMIN_URL"}
  end

  def build_a_new_form
    sign_in unless ENV.fetch("SKIP_SIGNON", false)
    visit '/'

    expect(page).to have_content 'GOV.UK Forms'

    delete_form

    create_form_with_name(form_name)

    next_form_creation_step 'Add and edit your questions'

    create_a_selection_question

    create_a_single_line_of_text_question

    click_link 'Go to your questions'

    add_a_route

    mark_pages_task_complete

    next_form_creation_step 'Add a declaration for people to agree to'

    mark_declaration_task_complete

    next_form_creation_step 'Add information about what happens next'

    expect(page.find("h1")).to have_content 'Add information about what happens next'
    fill_in "Enter some information to tell people what will happen next", with: "We'll send you an email to let you know the outcome. You'll usually get a response within 10 working days."
    click_button "Save and continue"

    add_form_submission_email

    next_form_creation_step 'Provide a link to privacy information for this form'

    expect(page.find("h1")).to have_content 'Provide a link to privacy information for this form'
    fill_in "Enter a link to privacy information for this form", with: "https://www.gov.uk/help/privacy-notice"
    click_button "Save and continue"

    next_form_creation_step 'Provide contact details for support'

    expect(page.find("h1")).to have_content "Provide contact details for support"
    check "Email", visible: false
    fill_in "Enter the email address", with: test_email_address
    click_button "Save and continue"

    next_form_creation_step 'Make your form live'

    expect(page.find("h1")).to have_content "Make your form live"
    choose "Yes", visible: false
    click_button "Save and continue"
    expect(page.find("h1")).to have_content "Your form is live"

    click_link "Continue to form details"

    expect(page.find("h1")).to have_content form_name
  end

  def next_form_creation_step(task)
    expect(page.find("h1")).to have_content 'Create a form'
    click_link task
  end

  def create_form_with_name(form_name)
    click_link "Create a form"
    expect(page.find("h1")).to have_content 'What’s the name of your form?'
    fill_in "What’s the name of your form?", :with => form_name
    click_button "Save and continue"
  end

  def create_a_selection_question
    expect(page.find("h1")).to have_content 'What kind of answer do you need to this question?'
    choose "Selection from a list of options", visible: false
    click_button "Continue"

    expect(page.find("h1")).to have_content 'What’s your question?'
    fill_in "What’s your question?", with: selection_question
    click_button "Continue"

    expect(page.find("h1")).to have_content 'Create a list of options'
    check "People can only select one option", visible: false
    fill_in "Option 1", :with => "Yes"
    fill_in "Option 2", :with => "No"
    click_button "Continue"

    click_button "Save and add next question"
  end

  def create_a_single_line_of_text_question
    expect(page.find("h1")).to have_content 'What kind of answer do you need to this question?'
    choose "Text", visible: false
    click_button "Continue"
    expect(page.find("h1")).to have_content 'How much text will people need to provide?'
    choose "Single line of text", visible: false
    click_button "Continue"
    expect(page.find("h1")).to have_content 'Edit question'
    fill_in "Question text", :with => question_text
    click_button "Save question"

  end

  def add_a_route
    expect(page.find("h1")).to have_content 'Add and edit your questions'
    click_link "Add a question route"

    expect(page.find("h1")).to have_content 'Add a question route'
    choose "1. #{selection_question}", visible: false
    click_button "Continue"

    expect(page.find("h1")).to have_content 'Add a question route'
    select "Yes", from: "is answered as"
    select "Check your answers before submitting", from: "take the person to"
    click_button "Save and continue"
  end

  def mark_pages_task_complete
    expect(page.find("h1")).to have_content 'Add and edit your questions'
    choose "Yes", visible: false
    click_button "Save and continue"
  end

  def mark_declaration_task_complete
    expect(page.find("h1")).to have_content 'Add a declaration'
    choose "Yes", visible: false
    click_button "Save and continue"
  end

  def add_form_submission_email
    # If the confirmation loop has been rolled out
    if page.has_content? "Enter the email address confirmation code"
      next_form_creation_step 'Set the email address completed forms will be sent to'

      expect(page.find("h1")).to have_content 'Set the email address for completed forms'

      expected_mail_reference = page.find('#notification-id', visible: false).value

      fill_in "What email address should completed forms be sent to?", with: test_email_address, fill_options: { clear: :backspace }
      click_button "Save and continue"

      expect(page.find("h1")).to have_content 'Confirmation code sent'
      expect(page.find("main")).to have_content test_email_address

      click_link "Enter the email address confirmation code"

      expect(page.find("h1")).to have_content "Enter the confirmation code"

      confirmation_code = get_confirmation_from_notify(expected_mail_reference, confirmation_code: true)

      abort("ABORT!!! #{expected_mail_reference} could not be found in Notify!!!") unless confirmation_code

      fill_in "Enter the confirmation code", with: confirmation_code

      click_button "Save and continue"

      expect(page.find("h1")).to have_content 'Email address confirmed'

      click_link "Continue creating a form"

    else
      next_form_creation_step 'Set the email address completed forms will be sent to'

      expect(page.find("h1")).to have_content 'What email address should completed forms be sent to?'
      fill_in "What email address should completed forms be sent to?", with: test_email_address
      click_button "Save and continue"
    end
  end

  def delete_form
    visit forms_admin_url

    if page.has_link?(form_name)
      click_link(form_name, match: :one)
      live_form_url = page.current_url
      delete_path = live_form_url.gsub("live", "delete")

      visit delete_path
      expect(page.find("h1")).to have_content 'Are you sure you want to delete this draft?'
      choose "Yes", visible: false
      click_button "Continue"
      expect(page.find("h1")).to have_content 'GOV.UK Forms'
      expect(page.find(".govuk-notification-banner")).to have_content "Successfully deleted ‘#{form_name}’"
      if page.has_css?('.govuk-table')
        expect(page.find('.govuk-table')).not_to have_content form_name
      end
    end
  end

  def form_is_filled_in_by_form_filler(live_form_link, skip_question: false, confirmation_email: nil)
    visit live_form_link

    if skip_question
      answer_selection_question("Yes")
    else
      answer_selection_question("No")

      expect(page).to have_content question_text
      answer_single_line(answer_text)
    end

    expect(page).to have_content 'Check your answers before submitting your form'

    if skip_question
      expect(page).to have_content selection_question
      expect(page).to have_content "Yes"
    else
      expect(page).to have_content selection_question
      expect(page).to have_content "No"

      expect(page).to have_content answer_text
    end

    expected_mail_reference = page.find('#notification-id', visible: false).value
    expected_confirmation_mail_reference = nil

    if page.has_content? "Do you want to get an email confirming your form has been submitted?"
      if confirmation_email
        choose "Yes", visible: false
        fill_in "email_confirmation_form[confirmation_email_address]", with: confirmation_email
        expected_confirmation_mail_reference = page.find("#confirmation-email-reference", visible: false).value
      else
        choose "No", visible: false
      end
    end

    click_button 'Submit'

    expect(page).to have_content 'Your form has been submitted'

    form_submission_email = get_confirmation_from_notify(expected_mail_reference)

    abort("ABORT!!! #{expected_mail_reference} could not be found in Notify!!!") unless form_submission_email

    if expected_confirmation_mail_reference
      confirmation_email_notification = get_confirmation_from_notify(expected_confirmation_mail_reference)

      abort("ABORT!!! #{expected_confirmation_mail_reference} could not be found in Notify!!!") unless confirmation_email_notification
    end

    if skip_question
      expect(form_submission_email.body).to have_content selection_question
      expect(form_submission_email.body).to have_content "Yes"
    else
      expect(form_submission_email.body).to have_content selection_question
      expect(form_submission_email.body).to have_content "No"

      expect(form_submission_email.body).to have_content question_text
      expect(form_submission_email.body).to have_content answer_text
    end
  end

  def answer_single_line(text)
    fill_in 'question[text]', with: text
    click_button 'Continue'
  end

  def answer_selection_question(text)
    choose text, visible: false
    click_button "Continue"
  end

  def sign_in
    index=''
    using_auth0_passwordless_connection = ENV.fetch("USE_AUTH0_PASSWORDLESS_CONNECTION", false)
    if using_auth0_passwordless_connection
      index = '/'
    else
      index = '/?auth=e2e'
    end
    visit index

    if is_auth0_login_page?
      sign_in_to_auth0(using_auth0_passwordless_connection)
    else
      sign_in_to_gds_sso
    end

    expect(page.current_host).to eq forms_admin_url
    expect(page.current_path).to eq "/"
    expect(page.find("h1")).to have_content "GOV.UK Forms"

    info "Sign in successful"
  end

  def sign_in_to_gds_sso
    info "Logging in using Signon"

    username = ENV.fetch("SIGNON_USERNAME") { raise "You must set SIGNON_USERNAME" }
    password = ENV.fetch("SIGNON_PASSWORD") { raise "You must set SIGNON_PASSWORD" }
    otp_token = ENV.fetch("SIGNON_OTP") { raise "You must set $SIGNON_OTP with the TOTP code for signon" }

    expect(page).to have_content 'Sign in to GOV.UK'

    fill_in "Email", :with => username
    fill_in "Password", :with => password
    click_button "Sign in"
    fill_in "code", :with => totp(otp_token)
    click_button "Sign in"
  end

  def sign_in_to_auth0(using_auth0_passwordless_connection)
    # Username is the value entered into the Auth0 email input - it might be a google group
    auth0_email_username = ENV.fetch("AUTH0_EMAIL_USERNAME") { raise "You must set AUTH0_EMAIL_USERNAME to use Auth0" }

    fill_in "Email address", :with => auth0_email_username
    click_button "Continue"

    if using_auth0_passwordless_connection
      info "Logging in using Auth0 passwordless connection"

      # Gmail address and password are the values used to access the gmail account via POP3
      auth0_gmail_address = ENV.fetch("AUTH0_GMAIL_ADDRESS") { raise "You must set AUTH0_GMAIL_ADDRESS to use Auth0" }
      auth0_gmail_password  = ENV.fetch("AUTH0_GOOGLE_APP_PASSWORD") { raise "You must set AUTH0_GOOGLE_APP_PASSWORD to use Auth0" }

      code = get_auth0_code(auth0_email_username, auth0_gmail_address, auth0_gmail_password)
      fill_in "Enter the code", :with => code
      click_button "Continue"
    else
      info "Logging in using Auth0 database connection"

      auth0_user_password  = ENV.fetch("AUTH0_USER_PASSWORD") { raise "You must set AUTH0_USER_PASSWORD to use Auth0" }

      fill_in "Password", :with => auth0_user_password
      click_button "Continue"
    end
  end

  def is_auth0_login_page?
    page.current_url.match?(/auth0.com/)
  end

  def get_auth0_code(email_username, gmail_address, google_app_password)
    info "Checking for email code"
    sleep 3
    gmail_account = GmailService.new(gmail_address, google_app_password)
    verification_mail = gmail_account.check_for_email(email_username, /Welcome to forms-admin-dev/)
    verification_mail.body.to_s[/(?<=Your verification code is: )\d{6}/]
  end

  def get_confirmation_from_notify(expected_mail_reference, confirmation_code: false)
    email = NotifyService.new.get_email(expected_mail_reference)

    start_time = Time.now
    info "Waiting 3sec for mail delivery to do its thing."
    sleep 3
    try = 0
    while(Time.now - start_time < 5000) do
      try += 1

      if confirmation_code
        unless email.collection.first.body.nil?
          code = email.collection.first.body.match(/\d{6}/).to_s
          puts "Received the following code from Notify: “#{code}“"
          return code
        end
      else
        unless email.collection.first.status.nil?
          status = email.collection.first.status
          puts "Received the following status from Notify: “#{status}“"
          return email.collection.first
        end
      end

      wait_time = try + ((Time.now - start_time) ** 0.5)
      info 'failed. Sleeping %0.2fs.' % wait_time
      sleep wait_time
    end
    return false
  end

  def totp(token)
    totp = ROTP::TOTP.new(token)
    totp.now
  end

  def info(message)
    puts message
  end

  def bypass_end_to_end_tests(service_name, link)
    visit link

    alert_message = if service_name == "forms-admin"
                      "forms-admin is running in maintenance mode...aborting any further e2e tests"
                    elsif service_name == "forms-runner"
                      "forms-runner is running in maintenance mode...aborting any further e2e tests forms-runner"
                    end

    return false unless current_path.end_with?("/maintenance")

    info("-🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨-")
    info("")
    info("🏥 - #{alert_message} - 🏥")
    info("")
    info("-🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨-")

    true
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
