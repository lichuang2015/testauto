Feature: Failures
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment
	
Background:
	Given the expiry is "1220"
	
Scenario: Declined
	Given the card number is "4444444444444448"
	When I validate the payment
	Then the status should be "DECLINED"

Scenario: Over the limit
	Given the card number is "4444444444444455"
	When I validate the payment
	Then the status should be "OVER LIMIT"
