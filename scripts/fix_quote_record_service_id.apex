// set estimate service id onto the quote record
List<Quote__c> quotes = [SELECT Id, Name, EstimateId__c, ServiceId__c, EstimateId__r.ServiceId__c FROM Quote__c WHERE EstimateId__c <> null];
for (Quote__c quoteSO: quotes) {
    quoteSO.ServiceId__c = quoteSO.EstimateId__r.ServiceId__c;
}