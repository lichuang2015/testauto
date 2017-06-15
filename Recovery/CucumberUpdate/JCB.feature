Feature: JCB
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Background:
	Given the expiry is "1220"
	
Scenario: Valid JCB card
	Given the card number is "3530111333300000"
	When I validate the payment
	Then the status should be "APPROVED"
	And the type should be "JCB"

Scenario: Invalid JCB number
	Given the card number is "3530111333300001"
	When I validate the payment
	Then the status should be "INVALID NUMBER"
	And the type should be "JCB"

Scenario: JCB number too short
	Given the card number is "353011133330000"
	When I validate the payment
	Then the status should be "NUMBER LENGTH WRONG"
	And the type should be "JCB"

Scenario: JCB number too long
	Given the card number is "35301113333000000"
	When I validate the payment
	Then the status should be "NUMBER LENGTH WRONG"
	And the type should be "JCB"
