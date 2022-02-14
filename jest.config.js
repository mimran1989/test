const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
	...jestConfig,
	clearMocks: true,
	modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
};
