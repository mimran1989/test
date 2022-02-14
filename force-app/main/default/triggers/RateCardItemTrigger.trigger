trigger RateCardItemTrigger on RateCardItem__c(before insert, before update) {
	for (RateCardItem__c rci : Trigger.new) {
		if (String.isNotBlank(rci.LocationCountry__c)) {
			rci.LocationDisplayName__c = rci.LocationCountry__c;
		}

		if (
			String.isNotBlank(rci.LocationDisplayName__c) &&
			String.isNotBlank(rci.LocationStateProvince__c)
		) {
			rci.LocationDisplayName__c += '/' + rci.LocationStateProvince__c;
		} else if (String.isNotBlank(rci.LocationStateProvince__c)) {
			rci.LocationDisplayName__c += rci.LocationStateProvince__c;
		}

		if (String.isNotBlank(rci.LocationDisplayName__c) && String.isNotBlank(rci.LocationCity__c)) {
			rci.LocationDisplayName__c += '/' + rci.LocationCity__c;
		} else if (String.isNotBlank(rci.LocationCity__c)) {
			rci.LocationDisplayName__c += rci.LocationCity__c;
		}
	}
}
