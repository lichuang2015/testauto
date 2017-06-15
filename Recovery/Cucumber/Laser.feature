Feature: Laser
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid Laser card
	Given the card number is "6709000000000001"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "LASER"

Scenario: Invalid Laser number
	Given the card number is "6709000000000000"
	When I validate the payment
	Then the status should be "INVALID_NUMBER"
	And the type should be "LASER"

Scenario: Laser number too short
	Given the card number is "670900000000000"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "LASER"

Scenario: Laser number too long
	Given the card number is "67090000000000000000"
	When I validate the payment
	Then the status should be "INVALID_NUMBER_FORMAT"
	And the type should be blank
