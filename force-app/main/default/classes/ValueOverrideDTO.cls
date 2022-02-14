/**
 *  Provus Services Quoting
 *  QuoteItem
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ValueOverrideDTO extends BaseDTO {
	public transient ValueOverride__c sO;
	@AuraEnabled
	public Id id { get; set; }
	@AuraEnabled
	public String fieldApiName { get; set; }
	@AuraEnabled
	public String fieldValue { get; set; }
	@AuraEnabled
	public String fieldLabel { get; set; }
	@AuraEnabled
	public String defaultFieldValue { get; set; }
	@AuraEnabled
	public Id objectValueOverrideId { get; set; }

	public ValueOverrideDTO() {
		sO = new ValueOverride__c();
	}

	public ValueOverrideDTO(String fieldApiName, String defaultFieldValue) {
		this.fieldApiName = fieldApiName;
		this.defaultFieldValue = defaultFieldValue;
	}

	public ValueOverrideDTO(ValueOverride__c valueOverrideSO) {
		this.id = valueOverrideSO.Id;
		this.fieldApiName = valueOverrideSO.FieldApiName__c;
		this.fieldValue = valueOverrideSO.FieldValue__c;
		this.objectValueOverrideId = valueOverrideSO.ObjectOverrideId__c;
		this.sO = valueOverrideSO;
	}

	public void refreshDO() {
		id = sO.Id;
		fieldApiName = sO.FieldApiName__c;
		fieldValue = sO.FieldValue__c;
		objectValueOverrideId = sO.ObjectOverrideId__c;
	}

	public void refreshSO() {
		sO.Id = id;
		sO.FieldApiName__c = fieldApiName;
		sO.FieldValue__c = fieldValue;
	}
}
