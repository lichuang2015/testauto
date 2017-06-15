Feature: InstaPayment
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid InstaPayment card
	Given the card number is "6373936375413581"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "INSTAPAYMENT"

Scenario: Invalid InstaPayment number
	Given the card number is "6373936375413580"
	When I validate the payment
	Then the status should be "INVALID_NUMBER"
	And the type should be "INSTAPAYMENT"

Scenario: InstaPayment number too short
	Given the card number is "637393637541358"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "INSTAPAYMENT"

Scenario: InstaPayment number too long
	Given the card number is "63739363754135810"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "INSTAPAYMENT"
