module Refunds
  class ApplicantPage < BasePage
    section :form_error_message, '[aria-describedby=error-message]' do |section|

    end
    section :has_name_changed, AppTest::FormBoolean, :simple_form_boolean, 'Has your name changed since you made your employment tribunal claim ?'

    section :about_the_claimant, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("About you")]] }) do
      section :title, AppTest::FormSelect, :simple_form_field, 'Title'
      section :first_name, AppTest::FormInput, :simple_form_field, 'First name'
      section :last_name, AppTest::FormInput, :simple_form_field, 'Last name'
      section :date_of_birth, AppTest::FormDate, :simple_form_date, 'Date of birth'
    end

    section :claimants_contact_details, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("Your contact details")]] }) do
      section :building, AppTest::FormInput, :simple_form_field, 'Building number or name'
      section :street, AppTest::FormInput, :simple_form_field, 'Street'
      section :locality, AppTest::FormInput, :simple_form_field, 'Town/city'
      section :county, AppTest::FormInput, :simple_form_field, 'County'
      section :post_code, AppTest::FormInput, :simple_form_field, 'UK Postcode'
      section :telephone_number, AppTest::FormInput, :simple_form_field, 'Phone or mobile number'
      section :email_address, AppTest::FormInput, :simple_form_field, 'Email address'
    end
    element :save_and_continue, 'form.edit_refunds_applicant input[value="Continue"]'
  end
end
