# frozen_string_literal: true

feature "Runner Smoke Test", type: :feature do
  let(:smoke_test_form_url) do
    # TODO: Update this once we're confident no one is setting $SMOKE_TEST_FORM_URL
    if Settings.form_ids.smoke_test
      "#{Settings.forms_runner.url}/form/#{Settings.form_ids.smoke_test}"
    else
      ENV["SMOKE_TEST_FORM_URL"] { raise "Settings.form_ids.smoke_test is not set" }
    end
  end

  before do
    Capybara.app_host = smoke_test_form_url
  end

  scenario "Complete and submit an existing form" do
    logger.info "Visiting #{smoke_test_form_url}"
    visit smoke_test_form_url

    expect(question_to_be_answered?).to be true

    question_number = 1
    while question_to_be_answered?
      current_page = page.current_url
      logger.info "#{current_page} answering question: #{question_number}"

      question_type = page.first("input")[:name]
      fill_in(class: "govuk-input", with: answer_for(question_type))
      click_button "Continue"

      expect(page).to have_no_content("There is a problem")
      expect(page.current_url).not_to eq(current_page), "On the same page after clicking 'Continue'"

      question_number += 1
    end

    logger.info "Confirming answers"
    expect(page).to have_content("Check your answers before submitting your form")

    choose "No", visible: false
    click_button "Submit"
    logger.info "Submitted answers"
    expect(page).to have_content("Your form has been submitted")
    logger.info "Test complete"
  end
end
