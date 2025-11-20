feature "Failing end to end tests", type: :feature do
  scenario "it fails when FAIL is set" do
    expect(ENV["FAIL"]).to be_nil.or be_empty.or eq("0")
  end
end
