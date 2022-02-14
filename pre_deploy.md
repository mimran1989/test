Pre Deployment Steps:

11-30-2021 (@justintieu):
The Quote record types have been removed and have been migrated to the new Type custom field.

Step 1:

- Run in the following script in the Salesforce anonymous console: fix_quote_record_type.apex
- Update `recordTypeName` variable for the various quote types

Step 2:

- From the Object Manager, in the Quick Find box, enter `Quote`
- Click Quote
- Click on `Record Types` in the left pane
- Disable all the record types that show up
- Delete the record types

11-29-2021 (@aozomaro):

The Margin Percent Field has been changed to a formula field as apart of PSQ-1292.
To correct deployment errors, follow the following steps below:

Step 1:

- From Setup, in the Quick Find box, enter `Lightning App Builder'
- Click Lightning App Builder.
- Click the `Edit` button on the left hand side of the `Proposal Record Page`
- Remove the `Margin % Field` from the Details tab

Step 2:

- From the Object Manager, in the Quick Find box, enter `Proposal`
- Click Proposal
- Click on `Fields and Relationships` in the left pane
- Select the drop down toggle next to the `Margin %` field
- Click Delete
