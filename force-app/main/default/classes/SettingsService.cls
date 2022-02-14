/**
 *  Provus Services Quoting
 *  ProjectPhaseTest
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class SettingsService {
	public static final String FIELDNAME_SDAY_HOURS = 'StandardDayHours__c';
	public static final String FIELDNAME_SWEEK_HOURS = 'StandardWeekHours__c';
	public static final String FIELDNAME_SMONTH_HOURS = 'StandardMonthHours__c';
	public static final String FIELDNAME_SYEAR_HOURS = 'StandardYearHours__c';

	/**
	 * @return returns Provus Setup DTO object for consumption by client
	 */
	public static ProvusSetupDTO getProvusSetup() {
		ProvusSetup__mdt setupRecord = ProvusSetup__mdt.getInstance('Standard');
		return new ProvusSetupDTO(setupRecord);
	}

	/**
	 * @return returns Schedule Settings DTO object for consumption by client
	 */
	public static ScheduleSettingDTO getScheduleSettings() {
		ScheduleSetting__mdt scheduleSetting = ScheduleSetting__mdt.getInstance('StandardSchedule');
		return new ScheduleSettingDTO(scheduleSetting);
	}

	public static ScheduleSettingDTO getScheduleSettingsForQuote(Id quoteId) {
		ScheduleSettingDTO scheduleSetting = new ScheduleSettingDTO();
		String objectApiName = SystemUtility.getNamespacePrefix() + 'ScheduleSetting__mdt';
		ObjectOverrideDTO objectOverrideDto = ObjectOverrideController.getObjectOverride(
			quoteId,
			objectApiName
		);
		for (ValueOverrideDTO valueOverrideDto : objectOverrideDto.valueOverrides) {
			// has override value different from default value
			if (valueOverrideDto.fieldApiName.contains(FIELDNAME_SDAY_HOURS)) {
				scheduleSetting.standardDayHours = getFieldValue(valueOverrideDto);
			} else if (valueOverrideDto.fieldApiName.contains(FIELDNAME_SWEEK_HOURS)) {
				scheduleSetting.standardWeekHours = getFieldValue(valueOverrideDto);
			} else if (valueOverrideDto.fieldApiName.contains(FIELDNAME_SMONTH_HOURS)) {
				scheduleSetting.standardMonthHours = getFieldValue(valueOverrideDto);
			} else if (valueOverrideDto.fieldApiName.contains(FIELDNAME_SYEAR_HOURS)) {
				scheduleSetting.standardYearHours = getFieldValue(valueOverrideDto);
			}
		}
		return scheduleSetting;
	}

	private static Decimal getFieldValue(ValueOverrideDTO valueOverrideDto) {
		String hoursValue = '0';

		// if an override value exists use it instead
		if (
			valueOverrideDto.defaultFieldValue != null &&
			valueOverrideDto.fieldValue != null &&
			valueOverrideDto.fieldValue != valueOverrideDto.defaultFieldValue
		) {
			hoursValue = valueOverrideDto.fieldValue;
		} else if (valueOverrideDto.defaultFieldValue != null) {
			hoursValue = valueOverrideDto.defaultFieldValue;
		}

		return Decimal.valueOf(hoursValue);
	}
}
