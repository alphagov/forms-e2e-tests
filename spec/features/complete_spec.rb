feature "Full lifecycle of a form", type: :feature do
  let(:test_email_address) { "govuk-forms-automation-tests@digital.cabinet-office.gov.uk" }

  let(:form_name) { "capybara test form #{Time.now().strftime("%Y-%m-%d %H:%M.%S")}" }
  let(:selection_question) { "Do you want to remain anonymous?" }
  let(:question_text) { "What is your name?" }
  let(:answer_text) { "test name" }

  before do
    Capybara.app_host = product_pages_url
  end

  scenario "Form is created, made live by form admin user and completed by a member of the public" do
    logger.info
    logger.info "Scenario: Form is created, made live by form admin user"

    unless bypass_end_to_end_tests('forms-admin', '/')
      start_tracing

      build_a_new_form

      logger.info("Then I can share the live form")
      live_form_link = page.find('[data-copy-target]').text

      unless bypass_end_to_end_tests('forms-runner', live_form_link)
        # Testing alternate routes (basic routing with a skip question)
        logger.info "Scenario: Form is completed by a member of the public, and they answer all questions"
        form_is_filled_in_by_form_filler(live_form_link, skip_question: false)

        logger.info
        logger.info "Scenario: Form is completed by a member of the public, and they use a route that skips questions"
        form_is_filled_in_by_form_filler(live_form_link, skip_question: true)

        # Testing confirmation email
        logger.info
        logger.info "Scenario: Form is completed by a member of the public, and they request a confirmation email"
        form_is_filled_in_by_form_filler(live_form_link, confirmation_email: test_email_address)
      end

      delete_form
    end
  end
end
