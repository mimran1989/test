/*
 * Provus Services Quoting
 * Copyright (c) 2022 Provus Inc. All rights reserved.
 */
const roundDecimals = (value) => value.toFixed(2);
const findPercentage = (value1, value2) => {
	if (value1 !== 0) {
		return ((value1 - value2) / value1) * 100;
	}

	return 0;
};

export { roundDecimals, findPercentage };
