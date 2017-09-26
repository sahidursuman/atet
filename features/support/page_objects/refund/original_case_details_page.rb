module Refunds
  class OriginalCaseDetailsPage < BasePage
    section :original_case_details, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("Your case details")]] }) do
      section :et_country_of_claim, AppTest::FormSelect, :simple_form_field, 'Where was your claim issued?'
      element :et_case_number, 'input[name="refunds_original_case_details[et_case_number]"]'
      section :et_tribunal_office, AppTest::FormSelect, :simple_form_field, 'Employment tribunal office'
      element :additional_information, 'textarea[name="refunds_original_case_details[additional_information]"]'
    end
    section :original_claimant_details, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("Your address at the time of your claim")]] }) do
      section :building, AppTest::FormInput, :simple_form_field, 'Building number or name'
      section :street, AppTest::FormInput, :simple_form_field, 'Street'
      section :locality, AppTest::FormInput, :simple_form_field, 'Town/city'
      section :county, AppTest::FormInput, :simple_form_field, 'County'
      section :post_code, AppTest::FormInput, :simple_form_field, 'UK Postcode'
      section :telephone_number, AppTest::FormInput, :simple_form_field, 'Phone or mobile number'
      section :email_address, AppTest::FormInput, :simple_form_field, 'Email address'
    end
    section :original_respondent_details, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("Respondent")]] }) do
      section :name, AppTest::FormInput, :simple_form_field, 'Respondent name'
      section :building, AppTest::FormInput, :simple_form_field, 'Building number or name'
      section :street, AppTest::FormInput, :simple_form_field, 'Street'
      section :locality, AppTest::FormInput, :simple_form_field, 'Town/city'
      section :county, AppTest::FormInput, :simple_form_field, 'County'
      section :post_code, AppTest::FormInput, :simple_form_field, 'UK Postcode'
    end
    section :claim_had_representative, AppTest::FormBoolean, :simple_form_boolean, 'Did you have a representative at the time of your original claim ?'
    section :original_representative_details, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("Representative")]] }) do
      section :name, AppTest::FormInput, :simple_form_field, 'Representative name'
      section :building, AppTest::FormInput, :simple_form_field, 'Building number or name'
      section :street, AppTest::FormInput, :simple_form_field, 'Street'
      section :locality, AppTest::FormInput, :simple_form_field, 'Town/city'
      section :county, AppTest::FormInput, :simple_form_field, 'County'
      section :post_code, AppTest::FormInput, :simple_form_field, 'UK Postcode'
    end
    section :address_changed, :xpath, (XPath.generate { |x| x.descendant(:fieldset)[x.descendant(:legend)[x.string.n.is("Has your address changed since you made your employment tribunal claim ?")]] }) do
      def set(value)
        choose(value)
      end
    end
    element :save_and_continue, 'form.edit_refunds_original_case_details input[value="Continue"]'
  end
end
