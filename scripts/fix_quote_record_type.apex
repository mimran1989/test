String recordTypeName = 'Quote';
Id recordTypeId = Schema.SObjectType.Quote__c.getRecordTypeInfosByDeveloperName()
			.get(recordTypeName)
			.getRecordTypeId();
List<Quote__c> quotes = [select id, RecordTypeId, Type__c from Quote__c where RecordTypeId =: recordTypeId];
for (Quote__c quote: quotes) {
    quote.Type__c = recordTypeName;
}

update quotes;