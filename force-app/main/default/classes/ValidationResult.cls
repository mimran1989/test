/**
 *  Provus Services Quoting
 *  ValidationResult
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing virtual class ValidationResult {
	@AuraEnabled
	public List<String> errorMsgs = new List<String>();

	@AuraEnabled
	public Boolean valid {
		get {
			return isValid();
		}
	}
	public Boolean isValid() {
		return errorMsgs.size() == 0;
	}
}
