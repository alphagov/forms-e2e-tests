# frozen_string_literal: true

require_relative "./notify_helpers"

module FeatureHelpers
  include NotifyHelpers

  def forms_admin_url
    ENV.fetch("FORMS_ADMIN_URL") { raise "You must set $FORMS_ADMIN_URL"}
  end

  def product_pages_url
    ENV.fetch('PRODUCT_PAGES_URL') { raise 'You must set $PRODUCT_PAGES_URL' }
  end

  def build_a_new_form
    logger.info
    logger.info 'As an editor user'

    visit_admin

    sign_in unless ENV.fetch('SKIP_AUTH', false)

    expect(page).to have_content 'GOV.UK Forms'

    delete_form

    logger.info "When I create a new form"
    create_form_with_name(form_name)

    next_form_creation_step 'Add and edit your questions'

    create_a_selection_question

    create_a_single_line_of_text_question

    first(:link, "your questions").click

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

    expect(page.find("h1")).to have_content 'Create a list of options'
    check "People can only select one option", visible: false
    fill_in "Option 1", :with => "Yes"
    fill_in "Option 2", :with => "No"
    click_button "Continue"

    expect(page.find("h1")).to have_content 'Edit question'
    click_button "Save question"
  end

  def create_a_single_line_of_text_question
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
    visit_admin

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
    logger.info
    logger.info "As a form filler"

    logger.info "When I fill out the new form"
    visit live_form_link

    if skip_question
      logger.info "And I answer all of the questions"
      answer_selection_question("Yes")
    else
      logger.info "And I choose the answer that skips questions"
      answer_selection_question("No")

      expect(page).to have_content question_text
      answer_single_line(answer_text)
    end

    logger.info "Then I can check my answers before I submit them"
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
        logger.info "And I can request a confirmation email"
        choose "Yes", visible: false
        fill_in "email_confirmation_form[confirmation_email_address]", with: confirmation_email
        expected_confirmation_mail_reference = page.find("#confirmation-email-reference", visible: false).value
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
    form_submission_email = wait_for_notification(expected_mail_reference)

    logger.info "And I can see their answers"
    if skip_question
      expect(form_submission_email.body).to have_content selection_question
      expect(form_submission_email.body).to have_content "Yes"
    else
      expect(form_submission_email.body).to have_content selection_question
      expect(form_submission_email.body).to have_content "No"

      expect(form_submission_email.body).to have_content question_text
      expect(form_submission_email.body).to have_content answer_text
    end

    if expected_confirmation_mail_reference
      logger.info
      logger.info "As a form filler"
      logger.info "When I have filled out a form and requested a confirmation email"
      logger.info "Then I can see the confirmation in my email inbox"

      confirmation_email_notification = wait_for_notification(expected_confirmation_mail_reference)
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
    sign_in_to_auth0

    expect(page.current_path).to eq "/"
    expect(page.find('h1')).to have_content "GOV.UK Forms"

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
    if skip_product_pages?
      logger.info "Visiting admin at #{forms_admin_url}"
      visit admin_url_with_e2e_auth(forms_admin_url)
    else
      logger.info "Visiting product pages at #{product_pages_url}"
      visit_product_page
      expect(page.find('h1')).to have_content 'Create online forms for GOV.UK'

      visit_link_to_forms_admin
    end
  end
end

RSpec.configure do |config|
  config.include FeatureHelpers, type: :feature
end
