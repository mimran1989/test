/**
 *  Provus Services Quoting
 *  QuoteItem
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ObjectOverrideDTO extends BaseDTO {
	private transient List<ValueOverrideDTO> pValueOverrides = new List<ValueOverrideDTO>();
	public transient ObjectOverride__c sO;

	@AuraEnabled
	public Id id { get; set; }
	@AuraEnabled
	public String overrideObjectApiName { get; set; }
	@AuraEnabled
	public List<ValueOverrideDTO> valueOverrides {
		get {
			return pValueOverrides;
		}
		set {
			pValueOverrides = value;
		}
	}
	@AuraEnabled
	public Id junctionRecordId { get; set; }

	public ObjectOverrideDTO() {
		sO = new ObjectOverride__c();
	}

	public ObjectOverrideDTO(String overrideObjectApiName) {
		this.sO = new ObjectOverride__c();
		sO.OverrideObjectApiName__c = overrideObjectApiName;
		this.overrideObjectApiName = overrideObjectApiName;
	}

	public ObjectOverrideDTO(ObjectOverride__c objectValueOverrideSO) {
		this.id = objectValueOverrideSO.Id;
		this.overrideObjectApiName = objectValueOverrideSO.OverrideObjectApiName__c;
		this.sO = objectValueOverrideSO;
	}

	public void refreshDO() {
		id = sO.Id;
		overrideObjectApiName = sO.OverrideObjectApiName__c;
		for (ValueOverrideDTO valueOverride : valueOverrides) {
			valueOverride.refreshDO();
		}
	}

	public void refreshSO() {
		sO.Id = id;
		sO.OverrideObjectApiName__c = overrideObjectApiName;
		for (ValueOverrideDTO valueOverride : valueOverrides) {
			valueOverride.refreshSO();
		}
	}
}
