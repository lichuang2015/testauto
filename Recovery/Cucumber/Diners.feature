Feature: Diners
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid Diners card
	Given the card number is "30000000000004"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "DINERS"

Scenario: Invalid Diners number
	Given the card number is "30000000000005"
	When I validate the payment
	Then the status should be "INVALID_NUMBER"
	And the type should be "DINERS"

Scenario: Diners number too short
	Given the card number is "3000000000000"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "DINERS"

Scenario: Diners number too long
	Given the card number is "300000000000000"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "DINERS"
