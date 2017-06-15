Feature: Discover
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid Discover card
	Given the card number is "6500000000000002"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "DISCOVER"

Scenario: Invalid Discover number
	Given the card number is "6500000000000003"
	When I validate the payment
	Then the status should be "INVALID_NUMBER"
	And the type should be "DISCOVER"

Scenario: Discover number too short
	Given the card number is "650000000000000"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "DISCOVER"

Scenario: Discover number too long
	Given the card number is "65000000000000000"
	When I validate the payment
	Then the status should be "NUMBER_LENGTH_WRONG"
	And the type should be "DISCOVER"
