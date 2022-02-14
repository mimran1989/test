/**
 * Created by iangallagher on 10/12/21.
 */

@IsTest
private class QuotePeriodServiceTest {
	@IsTest
	static void serviceDateStartCannotBeGreaterThanEnd() {
		Date serviceStartDate = Date.newInstance(2022, 2, 17);
		Date serviceEndDate = Date.newInstance(2021, 2, 17);

		List<Quote__c> quoteList = new List<Quote__c>();
		quoteList.add(
			new Quote__c(
				Name = 'Service Date Range Test Quote',
				ServiceStartDate__c = serviceStartDate,
				ServiceEndDate__c = serviceEndDate
			)
		);

		Test.startTest();
		QuotePeriodService.createPeriodsAndPeriodGroupsFor(quoteList);

		// check quote object for the existence of errors
		System.assert(quoteList[0].hasErrors(), 'there should be errors');
		List<Database.Error> errors = quoteList[0].getErrors();

		// assert we have 3 errors
		System.assert(errors.size() == 3, 'there should be 3 errors');
		// one error for the quote, one for ServiceStartDate__c field and one for ServiceEndDate__c field
		System.assert(
			errors[0].message == Label.QuoteServiceDateRangeError,
			'first error message should equal ' + 'the custom label QuoteServiceDateRangeError'
		);
		System.assert(errors[1].message == '', 'second error should be blank');
		System.assertEquals(
			errors[1].fields.size(),
			1,
			'second error field list should have one field'
		);
		System.assertEquals(
			Schema.Quote__c.ServiceEndDate__c + '',
			errors[1].fields[0],
			'second error should contain service end date' + 'field'
		);
		System.assert(errors[2].message == '', 'third error should be blank');
		System.assertEquals(errors[2].fields.size(), 1, 'third error field list should have one field');
		System.assertEquals(
			Schema.Quote__c.ServiceStartDate__c + '',
			errors[2].fields[0],
			'third error should contain service start date' + 'field'
		);
		Test.stopTest();
	}

	@IsTest
	static void serviceDateStartCannotBeGreaterThanEndUserDefined() {
		Date serviceStartDate = Date.newInstance(2022, 2, 17);
		Date serviceEndDate = Date.newInstance(2021, 2, 17);

		List<Quote__c> quoteList = new List<Quote__c>();
		quoteList.add(
			new Quote__c(
				Name = 'Service Date Range Test Quote',
				ServiceStartDate__c = serviceStartDate,
				ServiceEndDate__c = serviceEndDate,
				TimePeriodsAlignment__c = QuotePeriodService.TIME_PERIODS_ALIGNMENT_USER_DEFINED_CALENDAR,
				TimePeriodsGroupMethod__c = QuotePeriodService.TIME_PERIODS_GROUP_YEAR,
				TimePeriod__c = QuotePeriodService.TIME_PERIODS_MONTHS
			)
		);

		Test.startTest();
		QuotePeriodService.createPeriodsAndPeriodGroupsFor(quoteList);

		// check quote object for the existence of errors
		System.assert(quoteList[0].hasErrors(), 'there should be errors');
		List<Database.Error> errors = quoteList[0].getErrors();

		// assert we have 3 errors
		System.assert(errors.size() == 3, 'there should be 3 errors');
		// one error for the quote, one for ServiceStartDate__c field and one for ServiceEndDate__c field
		System.assert(
			errors[0].message == Label.QuoteServiceDateRangeError,
			'first error message should equal ' + 'the custom label QuoteServiceDateRangeError'
		);
		System.assert(errors[1].message == '', 'second error should be blank');
		System.assertEquals(
			errors[1].fields.size(),
			1,
			'second error field list should have one field'
		);
		System.assertEquals(
			Schema.Quote__c.ServiceEndDate__c + '',
			errors[1].fields[0],
			'second error should contain service end date' + 'field'
		);
		System.assert(errors[2].message == '', 'third error should be blank');
		System.assertEquals(errors[2].fields.size(), 1, 'third error field list should have one field');
		System.assertEquals(
			Schema.Quote__c.ServiceStartDate__c + '',
			errors[2].fields[0],
			'third error should contain service start date' + 'field'
		);
		Test.stopTest();
	}
}
