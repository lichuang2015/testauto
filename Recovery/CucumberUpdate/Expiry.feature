Feature: Expiry
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the card number is "4111111111111111"
	
Scenario: No expiry
	When I validate the payment
	Then the status should be "NO EXPIRY"

Scenario: Expired card
	Given the expiry is "0115"
	When I validate the payment
	Then the status should be "EXPIRED CARD"

Scenario: Expires too far in the future
	Given the expiry is "0125"
	When I validate the payment
	Then the status should be "EXPIRY INVALID"

Scenario: Invalid format
	Given the expiry is "1320"
	When I validate the payment
	Then the status should be "INVALID EXPIRY FORMAT"
