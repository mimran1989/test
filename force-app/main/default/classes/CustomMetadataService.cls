/**
 *  Provus Services Quoting
 *  CustomMetadataService
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class CustomMetadataService {
	public static final String DEFAULT_CUSTOM_METADATA = 'ProvusDefault';

	public static ProvusConfiguratorSetting__mdt defaultCustomMetadata {
		public get {
			if (defaultCustomMetadata == null) {
				defaultCustomMetadata = [
					SELECT
						DisableAutomaticOpportunitySync__c,
						ProductDefaultFields__c,
						QuoteItemDefaultFields__c,
						HiddenFields__c,
						RequiredFields__c,
						UneditableFields__c
					FROM ProvusConfiguratorSetting__mdt
					WHERE DeveloperName = :DEFAULT_CUSTOM_METADATA
					WITH SECURITY_ENFORCED
					LIMIT 1
				];
			}
			return defaultCustomMetadata;
		}
		public set;
	}

	public Set<String> getProductDefaultFields() {
		return fullyQualifiedFieldName(
			SystemUtility.csvToSet(defaultCustomMetadata.ProductDefaultFields__c)
		);
	}

	public Set<String> getQuoteItemDefaultFields() {
		return fullyQualifiedFieldName(
			SystemUtility.csvToSet(defaultCustomMetadata.QuoteItemDefaultFields__c)
		);
	}

	public Set<String> getHiddenFields() {
		return fullyQualifiedFieldName(SystemUtility.csvToSet(defaultCustomMetadata.HiddenFields__c));
	}

	public Set<String> getRequiredFields() {
		return fullyQualifiedFieldName(SystemUtility.csvToSet(defaultCustomMetadata.RequiredFields__c));
	}

	public Set<String> getUneditableFields() {
		return fullyQualifiedFieldName(
			SystemUtility.csvToSet(defaultCustomMetadata.UneditableFields__c)
		);
	}

	private Set<String> fullyQualifiedFieldName(Set<String> fieldNames) {
		Set<String> systemFields = new Set<String>{ 'name', 'id' };
		Set<String> qualifiedFieldNames = new Set<String>();
		String nsPrefix = SystemUtility.getNamespacePrefix();
		for (String fieldName : fieldNames) {
			String qualifiedFieldName = fieldName;
			if (
				!systemFields.contains(fieldName.toLowerCase()) && !fieldName.startsWithIgnoreCase(nsPrefix)
			) {
				qualifiedFieldName = nsPrefix + fieldName;
			}

			qualifiedFieldNames.add(qualifiedFieldName);
		}

		return qualifiedFieldNames;
	}
}
