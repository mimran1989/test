/**
 *  Provus Services Quoting
 *  ProjectPhaseTest
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing class ProvusSetupDTO extends BaseDTO {
	private static final String SCHEDULE_SETTING_NAME = 'StandardSchedule';
	public ProvusSetup__mdt sO;
	public ScheduleSettingDTO scheduleSettingDTO;

	public ProvusSetupDTO(ProvusSetup__mdt so) {
		// get Standard schedule setting record and pass
		ScheduleSetting__mdt scheduleSetting = ScheduleSetting__mdt.getInstance(SCHEDULE_SETTING_NAME);
		this.sO = so;
		this.scheduleSettingDTO = new ScheduleSettingDTO(scheduleSetting);
	}
}
