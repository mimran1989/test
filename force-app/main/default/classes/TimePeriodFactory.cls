/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
public with sharing abstract class TimePeriodFactory {
	private static Map<String, Type> timePeriodTypes;
	static {
		timePeriodTypes = new Map<String, Type>();
		timePeriodTypes.put(TimePeriodDay.NAME.toLowerCase(), TimePeriodDay.class);
		timePeriodTypes.put(TimePeriodDay.NAME_PLURAL.toLowerCase(), TimePeriodDay.class);
		timePeriodTypes.put(TimePeriodWeek.NAME.toLowerCase(), TimePeriodWeek.class);
		timePeriodTypes.put(TimePeriodWeek.NAME_PLURAL.toLowerCase(), TimePeriodWeek.class);
		timePeriodTypes.put(TimePeriodMonth.NAME.toLowerCase(), TimePeriodMonth.class);
		timePeriodTypes.put(TimePeriodMonth.NAME_PLURAL.toLowerCase(), TimePeriodMonth.class);
		timePeriodTypes.put(TimePeriodQuarter.NAME.toLowerCase(), TimePeriodQuarter.class);
		timePeriodTypes.put(TimePeriodQuarter.NAME_PLURAL.toLowerCase(), TimePeriodQuarter.class);
		timePeriodTypes.put(TimePeriodYear.NAME.toLowerCase(), TimePeriodYear.class);
	}

	public static ITimePeriod newTimePeriod(String timePeriod) {
		Type timePeriodType = timePeriodTypes.get(timePeriod?.toLowerCase());
		return timePeriodType != null ? (ITimePeriod) timePeriodType.newInstance() : null;
	}
}
