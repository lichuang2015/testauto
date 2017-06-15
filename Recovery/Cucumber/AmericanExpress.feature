Feature: American Express
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid American Express card
	Given the card number is "341111111111111"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "AMEX"

Scenario: Invalid American Express number
	Given the card number is "341111111111112"
	When I validate the payment
	Then the status should be "INVALID_NUMBER"
	And the type should be "AMEX"

Scenario: American Express number too short
	Given the card number is "34111111111111"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "AMEX"

Scenario: American Express number too long
	Given the card number is "3411111111111111"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "AMEX"
