/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */

public with sharing class Estimate {
	public static Estimate__c newSO(EstimateTemplate__c templateSO) {
		Estimate__c estimateSO = new Estimate__c();
		estimateSO.Name = templateSO.Name;
		estimateSO.IsActive__c = true;
		estimateSO.RateCardId__c = templateSO.RateCardId__c;
		estimateSO.ProductId__c = templateSO.ProductId__c;
		estimateSO.ServiceId__c = templateSO.ServiceId__c;
		estimateSO.Description__c = templateSO.Description__c;
		estimateSO.Guidance__c = templateSO.Guidance__c;

		return estimateSO;
	}
}
