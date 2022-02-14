
Feature: Ratecard Functionality

    Verify RateCard Functionality 

    Scenario: Display the Effective Date and Expiration Date field in New Rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        Then Actor see the Results "RateCardName" and "EffectiveDate","ExpirationDate"
    Scenario: Effective date should be less than expiration date in New Rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor Select the "EffectiveDate"
        And Actor Select the "ExpirationDate"
        Then Actor see the Results "EffectiveDate" should be less than "ExpirationDate"
    Scenario: Error message should be display in absensence of effective date and expiration dates value in New Rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor click on Save button without Entering effective date and expiration dates value in New Rate Card
        Then Actor see the Error Message "We hit a snag"
    Scenario: Error message should be display in absensence of expiration dates value missing in New Rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "EffectiveDate"
        And Actor click on Save Button without Entering expiration date in New Rate Card
        Then Actor see the Error Message "We hit a snag"
    Scenario: Error message should be display in absensence of effective dates value missing in New Rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor click on Save button without Entering effective date in New Rate Card
        Then Actor see the Error Message "We hit a snag"
    Scenario: Verify effective and expiration dates are displaying for existing rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor select the "ExpirationDate"
        Then Actor see the effective date date and expiration dates in in New Rate Card
        Then Actor click on Save button
    Scenario: Verify when user entered incorrect effective date in Rate card error message should be displayed
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the incorrect "ExpirationDate"
        And Actor select the incorrect "ExpirationDate"
        And Actor click on Save button
        Then Actor see the Error Message "Your entry does not match the allowed format M/d/yyyy."
    Scenario: Verify to check if quote service start date is within the range of rate card effective dates, Actor should be able to add the rate card in quote
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the New Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor select the "ExpirationDate"
        And Actor click on Save button
        And Actor click on Quote button
        When New Quote page displayed on screen
        And Actor enter the New Quote Name "String"
        And Actor select the "ServiceStartDate"
        And Actor select the "ServiceEndDate"
        When Quote service start date is within the range of rate card effective dates
        Then Actor should be able to add the rate card in quote
    Scenario: Verify if No service start date is selected while creating quote, user should not be able to add any rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the New Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor select the "ExpirationDate"
        And Actor click on Save button
        And Actor click on Quote button
        When New Quote page displayed on screen
        And Actor enter the New Quote Name "String"
        And Actor try to select the "RateCard"
        Then Actor see the error messege "Actor should not be able to add any rate card without selecting correct service start date to create the quote"
    Scenario: Verify if service start date in quote is less than the effective date on rate card, the rate card should not be allowed to be used in quote
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the New Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor select the "ExpirationDate"
        And Actor click on Save button
        And Actor click on Quote button
        When New Quote page displayed on screen
        And Actor enter the New Quote Name "String"
        And Actor select the "ServiceStartDate"
        And Actor select the "ServiceEndDate"
        When service start date in quote is less than the effective date on rate card
        Then Actor see the error messege " the rate card should not be allowed to be used in quote"
    Scenario: Verify if service start date in quote is greater than the expiration date on rate card, the rate card should not be allowed to be used in quote
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the New Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor select the "ExpirationDate"
        And Actor click on Save button
        And Actor click on Quote button
        When New Quote page displayed on screen
        And Actor enter the New Quote Name "String"
        And Actor select the "ServiceStartDate"
        And Actor select the "ServiceEndDate"
        When if service start date in quote is greater than the expiration date on rate card
        Then Actor see the error messege " The rate card should not be allowed to be used in quote"
    Scenario: Verify if rate card expiration date is same as service start date in quote, user should be able to add the rate card
        Given Actor navigate the Rate Cards page
        And Actor click on New Rate Card button
        When New Rate Card page displayed on screen
        And Actor enter the New Rate Card Name "String"
        And Actor enable the "Active" button
        And Actor select the "ExpirationDate"
        And Actor select the "ExpirationDate"
        And Actor click on Save button
        And Actor click on Quote button
        When New Quote page displayed on screen
        And Actor enter the New Quote Name "String"
        And Actor select the "ServiceStartDate"
        And Actor select the "ServiceEndDate"
        When  if rate card expiration date is same as service start date in quote
        Then Actor see the error messege " Actor should be able to add the rate card"



