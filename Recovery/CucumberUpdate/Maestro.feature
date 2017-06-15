Feature: Maestro
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid Maestro card
	Given the card number is "5018000000000009"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "MAESTRO"

Scenario: Invalid Maestro number
	Given the card number is "5018000000000000"
	When I validate the payment
	Then the status should be "INVALID NUMBER"
	And the type should be "MAESTRO"

Scenario: Maestro number too short
	Given the card number is "501800000000000"
	When I validate the payment
	Then the status should be "NUMBER LENGTH WRONG"
	And the type should be "MAESTRO"

Scenario: Maestro number too long
	Given the card number is "50180000000000000000"
	When I validate the payment
	Then the status should be "INVALID NUMBER FORMAT"
	And the type should be blank
