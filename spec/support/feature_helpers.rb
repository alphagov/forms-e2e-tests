# frozen_string_literal: true

require_relative "./notify_helpers"
require_relative "./aws_helpers"

module FeatureHelpers
  include NotifyHelpers
  include AwsHelpers

  def question_to_be_answered?
    page.has_css?('button', text: 'Continue')
  end

  def answer_for(question_type)
    case question_type
    when 'question[number]'
      '123'
    when 'question[email]'
      'smoke_test@example.com'
    when 'question[full_name]'
      'smoke_test'
    when 'question[text]'
      'smoke_test'
    else
      raise "Unsupported question type: #{question_type}. Only number, email,
      full_name and text are supported. Restrict the test form to these
      question types or extend the end-to-end tests to support it."
    end
  end

  def forms_admin_url
    ENV.fetch("FORMS_ADMIN_URL") { raise "You must set $FORMS_ADMIN_URL"}
  end

  def product_pages_url
    ENV.fetch('PRODUCT_PAGES_URL') { raise 'You must set $PRODUCT_PAGES_URL' }
  end

  def forms_runner_url
    ENV.fetch('FORMS_RUNNER_URL') { raise 'You must set $FORMS_RUNNER_URL' }
  end

  def submission_status_url
    "#{forms_runner_url}/submission"
  end

  def build_a_new_form
    logger.info
    logger.info 'As an editor user'

    sign_in_to_admin_and_create_form

    next_form_creation_step 'Add and edit your questions'

    create_a_selection_question

    create_a_single_line_of_text_question(question_text)

    create_a_single_line_of_text_question(alternate_question_text) # Adding a second question to test branching

    first(:link, "your questions").click

    add_a_route

    add_a_secondary_skip

    finish_form_creation

    make_form_live_and_return_to_form_details
  end

  def build_a_new_form_with_file_upload
    sign_in_to_admin_and_create_form

    next_form_creation_step 'Add and edit your questions'

    create_a_file_upload_question

    finish_form_creation

    make_form_live_and_return_to_form_details
  end

  def sign_in_to_admin_and_create_form
    sign_in_to_admin

    visit_end_to_end_tests_group

    delete_form

    logger.info "When I create a new form"
    create_form_with_name(form_name)
  end

  def finish_form_creation
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
    fill_in 'Enter a link to privacy information for this form', with: 'https://www.gov.uk/forms-made-up-example-privacy-notice'
    click_button "Save and continue"

    next_form_creation_step 'Provide contact details for support'

    expect(page.find("h1")).to have_content "Provide contact details for support"
    check "Email", visible: false
    fill_in "Enter the email address", with: test_email_address
    click_button "Save and continue"

    next_form_creation_step 'Share a preview of your draft form'

    expect(page.find("h1")).to have_content "Share a preview of your draft form"
    choose "Yes", visible: false
    click_button "Save and continue"
  end

  def make_form_live_and_return_to_form_details
    logger.info "And make it live"
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

    expect(page.find("h1")).to have_content 'How many options should people be able to select?'
    choose "One option only", visible: false
    click_button "Continue"

    expect(page.find("h1")).to have_content 'Create a list of options'
    fill_in "Option 1", :with => "Yes"
    fill_in "Option 2", :with => "No"

    within(page.find('fieldset', text: 'Should the list include an option for ‘None of the above’?')) do
      choose "No", visible: false
    end

    click_button "Continue"

    expect(page.find("h1")).to have_content 'Edit question'

    if page.has_field?("pages_question_input[is_repeatable]", type: :radio, visible: :all)
      choose("No", name: "pages_question_input[is_repeatable]", visible: :all)
    end

    click_button "Save question"
  end

  def create_a_single_line_of_text_question(question)
    within(page.find(".govuk-notification-banner__content")) do
      click_on "Add a question"
    end

    expect(page.find("h1")).to have_content 'What kind of answer do you need to this question?'
    choose "Text", visible: false
    click_button "Continue"
    expect(page.find("h1")).to have_content 'How much text will people need to provide?'
    choose "Single line of text", visible: false
    click_button "Continue"
    expect(page.find("h1")).to have_content 'Edit question'
    fill_in "Question text", :with => question
    choose "Mandatory", visible: false

    if page.has_field?("pages_question_input[is_repeatable]", type: :radio, visible: :all)
      choose("No", name: "pages_question_input[is_repeatable]", visible: :all)
    end

    click_button "Save question"
  end

  def create_a_file_upload_question
    expect(page.find("h1")).to have_content 'What kind of answer do you need to this question?'
    choose "File upload", visible: false
    click_button "Continue"
    expect(page.find("h1")).to have_content 'Edit question'
    fill_in "Ask for a file", :with => "Upload a file"
    choose "Mandatory", visible: false

    click_button "Save question"
    click_link("Back to your questions", match: :first)
  end

  def add_a_route
    expect(page.find("h1")).to have_content 'Add and edit your questions'
    click_link "Add a question route"

    expect(page.find("h1")).to have_content "Add a route from a question"
    choose "1. #{selection_question}", visible: false
    click_button "Continue"

    expect(page.find("h1")).to have_content "Add route"

    select "Yes", from: "If the answer selected is"

    select "3. #{alternate_question_text}", from: "to"
    click_button "Save and continue"
  end

  def add_a_secondary_skip
    click_on "Set questions to skip"

    expect(page.find("h1")).to have_content 'Route for any other answer: set questions to skip'

    select "2. #{question_text}", from: "Select the last question you want them to answer before they skip"
    select "Check your answers before submitting", from: "Select the question to skip them to"

    click_button "Save and continue"

    if page.find("h1").has_content? /Question \d+’s routes/
      click_link("Back to your questions", match: :first)
    end
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

      expected_mail_reference = find_notification_reference("notification-id")

      fill_in "What email address should completed forms be sent to?", with: test_email_address
      click_button "Save and continue"

      expect(page.find("h1")).to have_content 'Confirmation code sent'
      expect(page.find("main")).to have_content test_email_address

      click_link "Enter the email address confirmation code"

      expect(page.find("h1")).to have_content "Enter the confirmation code"

      confirmation_code = wait_for_confirmation_code(expected_mail_reference)

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
    if page.has_link?(form_name)
      click_link(form_name, match: :one, exact: true)
      live_form_url = page.current_url
      delete_path = live_form_url.gsub("live", "delete")

      visit delete_path
      expect(page.find("h1")).to have_content 'Are you sure you want to delete this draft?'
      choose "Yes", visible: false
      click_button "Continue"

      expect(page.find(".govuk-notification-banner")).to have_content "The draft form, ‘#{form_name}’, has been deleted"
      if page.has_css?('.govuk-table')
        expect(page.find('.govuk-table')).not_to have_content form_name
      end
    end
  end

  def form_is_filled_in_by_form_filler(live_form_link, yes_branch: false, confirmation_email: nil)
    logger.info
    logger.info "As a form filler"

    logger.info "When I fill out the new form"
    visit live_form_link

    if yes_branch
      logger.info "And I choose the 'yes' branch"
      answer_selection_question("Yes")

      expect(page).to have_content alternate_question_text
      answer_single_line(answer_text)
    else
      logger.info "And I choose the 'no' branch"
      answer_selection_question("No")

      expect(page).to have_content question_text
      answer_single_line(answer_text)
    end

    logger.info "Then I can check my answers before I submit them"
    expect(page).to have_content 'Check your answers before submitting your form'

    if yes_branch
      expect(page).to have_content selection_question
      expect(page).to have_content "Yes"
      expect(page).to have_content alternate_question_text
    else
      expect(page).to have_content selection_question
      expect(page).to have_content "No"
      expect(page).to have_content question_text

      expect(page).to have_content answer_text
    end

    confirmation_email_reference = nil

    if page.has_content? "Do you want to get an email confirming your form has been submitted?"
      if confirmation_email
        logger.info "And I can request a confirmation email"
        choose "Yes", visible: false
        fill_in "What email address do you want us to send your confirmation to?", with: confirmation_email
        confirmation_email_reference = find_notification_reference("confirmation-email-reference")
      else
        choose "No", visible: false
      end
    end

    click_button 'Submit'

    expect(page).to have_content 'Your form has been submitted'

    logger.info
    logger.info "As a form processor"
    logger.info "When a form filler has submitted their answers"
    logger.info "Then I can see their submission in my email inbox"

    check_submission

    if confirmation_email_reference
      logger.info
      logger.info "As a form filler"
      logger.info "When I have filled out a form and requested a confirmation email"
      logger.info "Then I can see the confirmation in my email inbox"

      confirmation_email_notification = wait_for_notification(confirmation_email_reference)
    end
  end

  def upload_file_and_submit(live_form_link)
    visit live_form_link

    logger.info "And I can upload a file"
    expect(page).to have_content "Upload a file"
    logger.info "When I upload a file"
    when_i_upload_a_file
    click_button "Continue"
    expect(page).to have_content "Your file has been uploaded"
    click_button "Continue"

    expect(page).to have_content "Check your answers before submitting your form"
    choose "No"
    click_button "Submit"

    expect(page).to have_content "Your form has been submitted"
  end

  def check_submission
    submission_reference = page.find('#submission-reference').text

    uri = URI(submission_status_url)
    uri.query = URI.encode_www_form(reference: submission_reference)

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{ENV['SETTINGS__SUBMISSION_STATUS_API__SECRET']}"

    start_time = Time.now
    try = 0
    while(Time.now - start_time < 60) do
      try += 1

      status_api_response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      raise "Could not query submission status API: #{status_api_response}" unless ["204", "404"].include?(status_api_response.code)

      return true if status_api_response.code == "204"

      wait_time = try + ((Time.now - start_time) ** 0.5)
      logger.debug 'failed. Sleeping %0.2fs.' % wait_time
      sleep wait_time
    end

    raise "Could not find submission after retrying #{try} times"
  end

  def s3_form_is_filled_in_by_form_filler()
    form_id =  ENV.fetch('S3_FORM_ID') { raise 'You must set $S3_FORM_ID' }
    s3_form_live_link = forms_runner_url + '/form/' + form_id

    logger.info
    logger.info "As a form filler"

    logger.info "When I fill out the new form"
    visit s3_form_live_link

    logger.info "And I answer all of the questions"
    answer_single_line(answer_text)

    logger.info "Then I can check my answers before I submit them"
    expect(page).to have_content 'Check your answers before submitting your form'
    expect(page).to have_content answer_text

    choose "No", visible: false
    click_button 'Submit'

    expect(page).to have_content 'Your form has been submitted'
    reference_number = page.find('#submission-reference').text

    logger.info
    logger.info "As a form processor"
    logger.info "When a form filler has submitted their answers"
    logger.info "Then I can see their submission in my s3 bucket"

    file_in_s3 = get_file_from_s3(reference_number, form_id)

    expect(file_in_s3).to have_content reference_number
    expect(file_in_s3).to have_content "test name"
  end

  def answer_single_line(text)
    fill_in 'question[text]', with: text
    click_button 'Continue'
  end

  def answer_selection_question(text)
    choose text, visible: false
    click_button "Continue"
  end

  def when_i_upload_a_file
    attach_file file_question_text, test_file
  end

  def sign_in_to_admin
    if skip_product_pages?
      logger.info "Visiting admin at #{forms_admin_url}"
      visit admin_url_with_e2e_auth(forms_admin_url)
    else
      logger.info "Visiting product pages at #{product_pages_url}"
      visit_product_page
      expect(page.find('h1')).to have_content 'Create online forms for GOV.UK'

      visit_link_to_forms_admin
    end

    sign_in if page.find('h1').has_content? 'Sign in'
  end

  def sign_in
    return if ENV.fetch('SKIP_AUTH', false)

    sign_in_to_auth0
    logger.debug "Sign in successful"
  end

  def sign_in_to_auth0
    # Username is the value entered into the Auth0 email input - it might be a google group
    auth0_email_username = ENV.fetch("AUTH0_EMAIL_USERNAME") { raise "You must set AUTH0_EMAIL_USERNAME to use Auth0" }

    fill_in "Email address", :with => auth0_email_username
    click_button "Continue"

    logger.debug "Logging in using Auth0 database connection"

    auth0_user_password  = ENV.fetch("AUTH0_USER_PASSWORD") { raise "You must set AUTH0_USER_PASSWORD to use Auth0" }

    fill_in "Password", :with => auth0_user_password
    click_button "Continue"
  end

  def bypass_end_to_end_tests(service_name, link)
    visit link

    alert_message = if service_name == "forms-admin"
                      "forms-admin is running in maintenance mode...aborting any further e2e tests"
                    elsif service_name == "forms-runner"
                      "forms-runner is running in maintenance mode...aborting any further e2e tests forms-runner"
                    end

    return false unless current_path.end_with?("/maintenance")

    logger.error <<~MSG
      -🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨-

      🏥 - #{alert_message} - 🏥

      -🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨---🚨-
    MSG

    true
  end

  def skip_product_pages?
    ENV.fetch('SKIP_PRODUCT_PAGES', false)
  end

  def visit_product_page
    logger.info "Visiting product pages at #{product_pages_url}"
    visit product_pages_url
  end

  def admin_url_with_e2e_auth(admin_url)
    URI.parse(admin_url).tap { |uri| uri.query = 'auth=e2e' }.to_s
  end

  def visit_link_to_forms_admin
    admin_link_href = page.find('nav a', text: 'Sign in')['href']
    admin_url = admin_url_with_e2e_auth(admin_link_href)
    logger.info "Visiting admin at #{admin_url}"
    visit admin_url
  end

  def visit_admin
    visit forms_admin_url
  end

  def visit_end_to_end_tests_group
    visit_group ENV.fetch('GROUP_NAME', 'End to end tests')
    expect(page).to have_content 'Active group'
  end

  def visit_group(group_name)
    logger.info "Visiting group #{group_name}"
    click_group group_name
  end

  def click_group(group_name)
    click_link group_name
    expect(page.find('h1')).to have_content group_name
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
