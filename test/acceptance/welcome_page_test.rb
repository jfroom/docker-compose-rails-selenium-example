require 'test_helper'

describe "Can Access Home", :capybara do
  it "has content", js: true do
    visit root_path
    page.must_have_content "Hello World!"
  end
end
