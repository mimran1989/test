/**
 *  Provus Services Quoting
 *  EndDateArgs
 *  @2022 Provus Inc. All rights reserved.
 */
public with sharing class EndDateArgs {
	@AuraEnabled
	public String timePeriods { get; set; }
	@AuraEnabled
	public String calendarAlignment { get; set; }
	@AuraEnabled
	public Date serviceStartDate { get; set; }
}
