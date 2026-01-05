# rubocop:todo RSpec/NoExpectationExample
feature "Full lifecycle of a form", type: :feature do
  let(:test_email_address) { "govuk-forms-automation-tests@digital.cabinet-office.gov.uk" }
  let(:form_name) { "capybara test form #{Time.now.strftime('%Y-%m-%d %H:%M.%S')}" }

  let(:file_question_text) { "Upload a file" }
  let(:test_file) { file_fixture("file_upload_test_image.jpg") }
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
    unless bypass_end_to_end_tests("forms-admin", "/")
      logger.info
      logger.info "Scenario: Form is created, made live by form admin user"

      start_tracing

      logger.info
      logger.info "As an editor user"

      sign_in_to_admin
      visit_end_to_end_tests_group

      logger.info "When I create a new form"
      delete_form(form_name)
      create_form_with_name(form_name)

      next_form_creation_step "Add and edit your questions"

      # Add question to test file upload
      add_a_file_upload_question unless skip_file_upload?

      # Add question to test describing none of the above
      unless skip_describe_none_of_the_above?
        add_a_selection_question_with_different_answer_for_none_of_the_above(
          "What is your favourite colour?",
          options: %w[Red Green],
          none_of_the_above_label_text: "Enter your favourite colour",
        )
      end

      # Add questions to test routes
      add_a_selection_question(selection_question, options: %w[Yes No])
      add_a_single_line_of_text_question(question_text)
      add_a_single_line_of_text_question(alternate_question_text)

      first(:link, "your questions").click

      add_a_route selection_question, if_the_answer_selected_is: "Yes", skip_the_person_to: alternate_question_text
      add_a_secondary_skip last_question_before_skip: question_text, question_to_skip_to: "Check your answers before submitting"

      finish_form_creation

      logger.info "And make it live"
      make_form_live_and_return_to_form_details

      logger.info "Then I can share the live form"
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
      delete_form(form_name)
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
