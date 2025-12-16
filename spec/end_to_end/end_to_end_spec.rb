# rubocop:todo RSpec/NoExpectationExample
feature "Full lifecycle of a form", type: :feature do
  let(:test_email_address) { "govuk-forms-automation-tests@digital.cabinet-office.gov.uk" }
  let(:form_name) { "capybara test form #{Time.now.strftime('%Y-%m-%d %H:%M.%S')}" }

  let(:file_question_text) { "Upload a file" }
  let(:test_file) { file_fixture("hello.txt") }
  let(:selection_question) { "Do you want to remain anonymous?" }
  let(:question_text) { "What is your name?" }
  let(:answer_text) { "test name" }
  let(:alternate_question_text) { "What is your favourite colour?" }

  let(:start_url) do
    if skip_product_pages?
      forms_admin_url
    else
      product_pages_url
    end
  end

  before do
    Capybara.app_host = start_url
  end

  scenario "Form is created, made live by form admin user and completed by a member of the public" do
    logger.info
    logger.info "Scenario: Form is created, made live by form admin user"

    unless bypass_end_to_end_tests("forms-admin", "/")
      start_tracing

      build_a_new_form

      logger.info("Then I can share the live form")
      live_form_link = page.find("[data-copy-target]").text

      unless bypass_end_to_end_tests("forms-runner", live_form_link)
        # Testing alternate branches (branch routing with different questions)
        logger.info "Scenario: Form is completed by a member of the public, and they use the 'yes' branch"
        form_is_filled_in_by_form_filler(live_form_link, yes_branch: true)

        logger.info "Scenario: Form is completed by a member of the public, and they use the 'no' branch"
        form_is_filled_in_by_form_filler(live_form_link, yes_branch: false)

        # Testing confirmation email
        logger.info
        logger.info "Scenario: Form is completed by a member of the public, and they request a confirmation email"
        form_is_filled_in_by_form_filler(live_form_link, confirmation_email: test_email_address)
      end

      visit_admin
      visit_end_to_end_tests_group
      delete_form
    end
  end

  unless ENV.fetch("SKIP_S3", false)
    # Testing s3 submission
    scenario "Form is completed by a member of the public, and answers are sent to s3" do
      logger.info
      logger.info "Scenario: Form is completed by a member of the public, and answers are sent to s3"

      start_tracing

      s3_form_is_filled_in_by_form_filler
    end
  end
end
# rubocop:enable RSpec/NoExpectationExample
