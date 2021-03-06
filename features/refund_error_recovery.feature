Feature: Refund form with error recovery
  Assuming Anakin Skywalker's profile does not have any
  of the optional field values such as town/city, county, respondent post code etc..
  and he has a claim with case number 1234567/2015 which has all optional data missing also
  Background:
    Given I am "Anakin Skywalker"
    And I want a refund for my previous ET claim with case number "1234567/2015"

  Scenario: Refund for a sole party who paid directly, used a representative and whos name or address has changed
    And I have a bank account
    And my name has not changed since the original claim that I want a refund for
    And my address has changed (minimal details) since the original claim that I want a refund for
    And I had a representative with minimal details

    When I start a new refund for a sole party who paid the tribunal fees directly and has not been reimbursed
    And my session dissapears from a timeout
    And I fill in my refund applicant details
    Then I should see the profile selection page with a session reloaded message
    And I take a screenshot named "Page 1 - Profile selection after session timeout"
