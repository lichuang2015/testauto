@UI
Feature: UI tests
	As a vendor
	I want to validate the credit card payment
	So that I don't supply goods with no payment

Scenario: UI calls web service
	Given I open "http://localhost:8883" in Firefox
	And I enter "4222222222222" as the number
	And I enter "1220" as the expiry
	When I click the test button
	Then the status "APPROVED" should be displayed
	And the message "Approved." should be displayed
	And the type "VISA" should be displayed
	
	Given I enter $-1.23 as the amount
	When I click the test button
	Then the status "INVALID AMOUNT" should be displayed
	And the type "" should be displayed
