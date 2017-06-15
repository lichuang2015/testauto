Feature: Amount
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment
	
Background:
	Given the expiry is "1220"
	
Scenario: Not a number
	Given the card number is "4111111111111111"
	And the amount is $ABC
	When I validate the payment
	Then the status should be "INVALID_AMOUNT"

Scenario: Too many decimal places
	Given the card number is "4111111111111111"
	And the amount is $0.123
	When I validate the payment
	Then the status should be "INVALID_AMOUNT"

Scenario: Under the limit
	Given the card number is "4444444444444463"
	And the amount is $1000
	When I validate the payment
	Then the status should be "APPROVED"

Scenario: Over the limit
	Given the card number is "4444444444444463"
	And the amount is $1000.01
	When I validate the payment
	Then the status should be "OVER_LIMIT"
