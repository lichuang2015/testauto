@API
Feature: API integration tests
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Scenario: Valid number and expiry
	Given I use the API at "http://localhost:8883/ValidateCard"
	And the parameter Number is "4222222222222"
	And the parameter Expiry is "1220"
	When I call the ValidateCard API
	Then the returned status should be "APPROVED" 
	And the returned message should be "Approved."
	And the returned type should be "VISA"

Scenario: Invalid amount
	Given I use the API at "http://localhost:8883/ValidateCard"
	And the parameter Number is "4222222222222"
	And the parameter Expiry is "1220"
	And the parameter Amount is $-1.23
	When I call the ValidateCard API
	Then the returned status should be "INVALID AMOUNT" 
	And the returned type should be ""
