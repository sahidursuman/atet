And(/^I answer (Yes|No) to the has your name changed question for refunds$/) do |value|
  refund_applicant_page.has_name_changed.set(value)
end

And(/^I fill in my refund claimant details with:$/) do |table|
  # table is a table.hashes.keys # => [:field, :value]
  table.hashes.each do |hash|
    refund_applicant_page.about_the_claimant do |section|
      node = section.send(hash['field'].to_sym)
      case node.try(:tag_name)
      when "select" then node.select(hash['value'])
      else node.set(hash['value'])
      end
    end
  end

end

And(/^I fill in my refund claimant contact details with:$/) do |table|
  # table is a table.hashes.keys # => [:field, :value]
  table.hashes.each do |hash|
    refund_applicant_page.claimants_contact_details do |section|
      node = section.send(hash['field'].to_sym)
      case node.try(:tag_name)
      when "select" then node.select(hash['value'])
      else node.set(hash['value'])
      end
    end
  end
end

And(/^I save the refund applicant details$/) do
  refund_applicant_page.save_and_continue.click
end

Then(/^the user should be informed that there are errors on the refund applicant page$/) do
  expect(refund_applicant_page.form_error_message).to be_visible
end

And(/^all mandatory fields in the refund applicant page should be marked with an error$/) do
  aggregate_failures do
    expect(refund_applicant_page.about_the_claimant.title.error.text).to eql "Select a title from the list"
    expect(refund_applicant_page.about_the_claimant.first_name.error.text).to eql "Enter your first name"
    expect(refund_applicant_page.about_the_claimant.last_name.error.text).to eql "Enter your last name"
    expect(refund_applicant_page.about_the_claimant.date_of_birth.error.text).to eql "Enter your date of birth"
    expect(refund_applicant_page.claimants_contact_details.building.error.text).to eql "Enter the building number or name from your address"
    expect(refund_applicant_page.claimants_contact_details.street.error.text).to eql "Enter the street from your address"
    expect(refund_applicant_page.claimants_contact_details.locality.error.text).to eql "Enter the town or city from the claimant’s address"
    expect(refund_applicant_page.claimants_contact_details.post_code.error.text).to eql "Enter your post code"
    expect(refund_applicant_page.claimants_contact_details.telephone_number.error.text).to eql "Enter your preferred number"

    expect(refund_applicant_page.claimants_contact_details.county).to have_no_error, 'Expected county not to have an error'
    expect(refund_applicant_page.claimants_contact_details.email_address).to have_no_error, 'Expected email address not to have an error'
  end
end

And(/^I fill in my refund applicant details$/) do
  refund_applicant_page.has_name_changed.set(test_user.has_name_changed) unless test_user.has_name_changed.nil?
  step("I take a screenshot named \"Page 2 - Applicant Details 1 \"")
  refund_applicant_page.about_the_claimant do |section|
    section.title.set(test_user.title)
    section.first_name.set(test_user.first_name)
    section.last_name.set(test_user.last_name)
    section.date_of_birth.set(test_user.date_of_birth)
  end
  step("I take a screenshot named \"Page 2 - Applicant Details 2 \"")
  refund_applicant_page.claimants_contact_details do |section|
    section.building.set(test_user.address.building) unless test_user.address.building.nil?
    section.street.set(test_user.address.street) unless test_user.address.street.nil?
    section.locality.set(test_user.address.locality) unless test_user.address.locality.nil?
    section.county.set(test_user.address.county) unless test_user.address.county.nil?
    section.post_code.set(test_user.address.post_code) unless test_user.address.post_code.nil?
    section.telephone_number.set(test_user.telephone_number) unless test_user.telephone_number.nil?
    section.email_address.set(test_user.email_address) unless test_user.email_address.nil?
  end
  step("I take a screenshot named \"Page 2 - Applicant Details 3 \"")
  step("I save the refund applicant details")

end

Then(/^the continue button should be disabled on the refund applicant page$/) do
  expect(refund_applicant_page.save_and_continue).to be_disabled
end

And(/^the email address in the refund applicant page should be marked with an invalid error$/) do
  expect(refund_applicant_page.claimants_contact_details.email_address.error.text).to eql 'is invalid'
end

And(/^the date of birth in the refund applicant page should be marked with an invalid error$/) do
  expect(refund_applicant_page.about_the_claimant.date_of_birth.error.text).to eql 'is invalid'
end

Then(/^the title field in the applicant page should have the correct default option selected$/) do
  expect(refund_applicant_page.about_the_claimant.title.get).to eql 'Please select'
end
