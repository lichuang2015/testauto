Feature: MasterCard
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid MasterCard card
	Given the card number is "5555555555555557"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "MASTERCARD"

Scenario: Invalid MasterCard number
	Given the card number is "5555555555555558"
	When I validate the payment
	Then the status should be "INVALID NUMBER"
	And the type should be "MASTERCARD"

Scenario: MasterCard number too short
	Given the card number is "555555555555555"
	When I validate the payment
	Then the status should be "NUMBER LENGTH WRONG"
	And the type should be "MASTERCARD"

Scenario: MasterCard number too long
	Given the card number is "55555555555555555555"
	When I validate the payment
	Then the status should be "INVALID NUMBER FORMAT"
	And the type should be blank
