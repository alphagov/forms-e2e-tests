feature "Full lifecycle of a form", type: :feature do
  let(:test_email_address) { "govuk-forms-automation-tests@digital.cabinet-office.gov.uk" }

  let(:form_name) { "capybara test form #{Time.now().strftime("%Y-%m-%d %H:%M.%S")}" }
  let(:selection_question) { "Do you want to remain anonymous?" }
  let(:question_text) { "What is your name?" }
  let(:answer_text) { "test name" }

  before do
    Capybara.app_host = forms_admin_url
  end

  scenario "Form is created, made live by form admin user and completed by a member of the public" do
    unless bypass_end_to_end_tests('forms-admin', '/')
      build_a_new_form

      live_form_link = page.find('[data-copy-target]').text

      unless bypass_end_to_end_tests('forms-runner', live_form_link)
        # Testing alternate routes (basic routing with a skip question)
        form_is_filled_in_by_form_filler(live_form_link, skip_question: false)
        form_is_filled_in_by_form_filler(live_form_link, skip_question: true)
        # Testing confirmation email
        form_is_filled_in_by_form_filler(live_form_link, confirmation_email: test_email_address)
      end

      delete_form
    end
  end
end
