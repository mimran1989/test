/**
 *  Provus Services Quoting
 *  ObjectOverrideResult
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ObjectOverrideResult extends ValidationResult {
	@AuraEnabled
	public List<ObjectOverrideDTO> objectOverrideDtos = new List<ObjectOverrideDTO>();
}
