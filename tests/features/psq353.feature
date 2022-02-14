 @PSQ-353
    Feature: PSQ-353
      As a Quote Manager
      I want to select a global rate card which is effective on the quotes service start date
      So that I can get the pricing for the expected Service Start date for when the resources will be actually used

      Scenario: To check user is able to see field to capture Effective Date on Rate Card
        Given I have browsed to Rate card menu
        When I click on New button
        Then I can see the new Rate card form
        and Effective date field should be vissible