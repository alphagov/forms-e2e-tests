require 'rotp'
require_relative '../../services/notify_service'

feature "Full lifecyle of a form", type: :feature do
  let(:form_name) { "capybara test form" }
  let(:username)  { ENV.fetch("SIGNON_USERNAME") { raise "You must set SIGNON_USERNAME" } }
  let(:password) { ENV.fetch("SIGNON_PASSWORD") { raise "You must set SIGNON_PASSWORD" } }
  let(:token)   { ENV.fetch("SIGNON_OTP") { raise "You must set $SIGNON_OTP with the TOTP code for signon"} }
  let(:forms_admin_url) { ENV.fetch("FORMS_ADMIN_URL") { raise "You must set $FORMS_ADMIN_URL"} }

  before do
    Capybara.app_host = forms_admin_url
  end

  scenario "Form is created, made live by form admin user and completed by a member of the public" do
    sign_on(username, password, token) unless ENV.fetch("SKIP_SIGNON", false)
    visit '/'
    expect(page).to have_content 'GOV.UK Forms'

    delete_form

    create_form_with_name(form_name)

    next_form_creation_step 'Add and edit your questions'

    create_a_single_line_of_text_question

    click_link "Go to your questions"

    mark_pages_task_complete

    next_form_creation_step 'Add a declaration for people to agree to'

    mark_declaration_task_complete

    next_form_creation_step 'Add information about what happens next'

    expect(page.find("h1")).to have_content 'Form submitted page'
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
    fill_in "Enter the email address", with: "govuk-forms-automation-tests@digital.cabinet-office.gov.uk"
    click_button "Save and continue"

    next_form_creation_step 'Make your form live'

    expect(page.find("h1")).to have_content "Make your form live"
    choose "Yes", visible: false
    click_button "Save and continue"
    expect(page.find("h1")).to have_content "Your form is live"

    click_link "Continue to form details"

    expect(page.find("h1")).to have_content "Your form"

    live_form_link = page.find('[data-copy-target]').text

    form_is_filled_in_by_form_filler live_form_link

    delete_form
  end

  def next_form_creation_step(task)
    expect(page.find("h1")).to have_content 'Create a form'
    click_link task
  end

  def create_form_with_name(form_name)
    click_link "Create a form"
    expect(page.find("h1")).to have_content 'What is the name of your form?'
    fill_in "What is the name of your form?", :with => form_name
    click_button "Save and continue"
  end

  def create_a_single_line_of_text_question
    expect(page.find("h1")).to have_content 'Edit question'
    fill_in "Question text", :with => "What is your name?"
    choose "Single line of text", visible: false
    click_button "Save and add next question"
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
    if page.has_link? "Enter the email address confirmation code"
      next_form_creation_step 'Set the email address completed forms will be sent to'

      expect(page.find("h1")).to have_content 'Set the email address for completed forms'

      expected_mail_reference = page.find('#notification-id', visible: false).value

      fill_in "What email address should completed forms be sent to?", with: "govuk-forms-automation-tests@digital.cabinet-office.gov.uk"
      click_button "Save and continue"

      expect(page.find("h1")).to have_content 'Confirmation code sent'
      expect(page.find("main")).to have_content "govuk-forms-automation-tests@digital.cabinet-office.gov.uk"

      click_link "Enter the email address confirmation code"

      expect(page.find("h1")).to have_content "Enter the confirmation code"

      confirmation_code = get_confirmation_code_from_notify(expected_mail_reference)

      abort("ABORT!!! #{expected_mail_reference} could not be found in Notify!!!") unless confirmation_code

      fill_in "Enter the confirmation code", with: confirmation_code

      click_button "Save and continue"

      expect(page.find("h1")).to have_content 'Email address confirmed'

      click_link "Continue creating a form"

    else
      next_form_creation_step 'Set the email address completed forms will be sent to'

      expect(page.find("h1")).to have_content 'What email address should completed forms be sent to?'
      fill_in "What email address should completed forms be sent to?", with: "govuk-forms-automation-tests@digital.cabinet-office.gov.uk"
      click_button "Save and continue"
    end
  end

  def delete_form
    visit forms_admin_url

    if page.has_link?(form_name)
      click_link(form_name, match: :one)
      click_link "Delete form"
      expect(page.find("h1")).to have_content "Are you sure you want to delete this form?"
      choose "Yes", visible: false
      click_button "Continue"
      expect(page.find("h1")).to have_content 'GOV.UK Forms'
      expect(page.find(".govuk-table")).not_to have_content form_name
    end
  end

  def form_is_filled_in_by_form_filler live_form_link
    visit live_form_link

    expect(page).to have_content 'What is your name?'
    answer_single_line('test name')

    expect(page).to have_content 'Check your answers before submitting your form'
    expect(page).to have_content 'test name'
    click_button 'Submit'

    expect(page).to have_content 'Your form has been submitted'
  end

  def answer_single_line(text)
    fill_in 'question[text]', with: text
    click_button 'Continue'
  end

  def sign_on(username, email, otp_token)
    visit '/'
    expect(page).to have_content 'Sign in to GOV.UK'

    fill_in "Email", :with => username
    fill_in "Password", :with => password
    click_button "Sign in"
    fill_in "Your verification code", :with => totp(otp_token)
    click_button "Sign in"
  end

  def get_confirmation_code_from_notify(expected_mail_reference)
    email_body = NotifyService.new.get_confirmation_code_email(expected_mail_reference)

    start_time = Time.now
    info "Waiting 3sec for mail delivery to do it's thing."
    sleep 3
    try = 0
    while(Time.now - start_time < 5000) do
      try += 1

      unless email_body.collection.first.body.nil?
        code = email_body.collection.first.body.match(/\d+/).to_s
        puts "Received the following code from Notify #{code}"
        return code
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
end
