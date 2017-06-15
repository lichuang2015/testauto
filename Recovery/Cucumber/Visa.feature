Feature: Visa
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid Visa card
	Given the card number is "4222222222222"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "VISA"

Scenario: Invalid Visa number
	Given the card number is "4222222222223"
	When I validate the payment
	Then the status should be "INVALID_NUMBER"
	And the type should be "VISA"

Scenario: Visa number too short
	Given the card number is "422222222222"
	When I validate the payment
	Then the status should be "INVALID_NUMBER_FORMAT"
	And the type should be blank

Scenario: Visa number too long
	Given the card number is "42222222222222222"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "VISA"
