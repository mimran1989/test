@resource-role-dialog
Feature: Resource Role Dialog
  As a quote manager
  I should be able add and edit resources
  to build build a quote
  
  Scenario: The Resource Role Dialog should open for an empty quote
    Given I have created a quote
    When I visit the quote
    Then I can see the resource role dialog
  Scenario: Closing the dialog should be allowed when there are no roles selected and no roles available for selection
    Given I have created a rate card with 0 roles
    And I have created an empty quote with this rate card
    When I visit the quote
    Then I can see that I can close the resource role dialog
  # Scenario: Closing the dialog should be disallowed when there are no roles selected and roles available for selection
  #   Given I have created a rate card with 1 role
  #   And I have created an empty quote with this rate card
  #   When I visit the quote
  #   Then I can see that I cannot close the resource role dialog
  Scenario: The role dialog should alert the user if there are no available roles for selection
    Given I have created a rate card with 0 roles
    And I have created an empty quote with this rate card
    When I visit the quote
    Then I can can see the no available roles info message

  # Scenario: The role dialog should show multiple roles for Project Manager
  #   Given Ian has created a rate card with roles
  #     | Name               | Skill Level |
  #     | Project Manager    | L1          |
  #     | Project Manager    | L2          |
  #     | Software Architect | L1          |
  #     | QA Tester          | L2          |
  #   And He has created an empty quote with this rate card
  #   When He visits the quote
  #   And Selects the "Project Manager" resource role
  #   Then He will see a rate with the "Skill Level", "L1"
  #   And He will see a rate with the "Skill Level", "L2"


