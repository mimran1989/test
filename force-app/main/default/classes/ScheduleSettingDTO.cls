/**
 *  Provus Services Quoting
 *  ProjectPhaseTest
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ScheduleSettingDTO {
	public ScheduleSetting__mdt sO;
	public Decimal standardDayHours;
	public Decimal standardWeekHours;
	public Decimal standardMonthHours;
	public Decimal standardYearHours;

	public ScheduleSettingDTO() {
	}

	public ScheduleSettingDTO(ScheduleSetting__mdt scheduleSetting) {
		this.sO = scheduleSetting;

		this.standardDayHours = scheduleSetting.StandardDayHours__c;
		this.standardWeekHours = scheduleSetting.StandardWeekHours__c;
		this.standardMonthHours = scheduleSetting.StandardMonthHours__c;
		this.standardYearHours = scheduleSetting.StandardYearHours__c;
	}
}
