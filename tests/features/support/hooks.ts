import {
	After, AfterAll, Before, BeforeAll, ITestCaseHookParameter, setDefaultTimeout, Status,
} from '@cucumber/cucumber';
import * as fs from 'fs';
import createTestCafe from 'testcafe';
import errorHandling from './errorHandling';
import { KeyChain } from './keychain';
import TestCafeControllerFactory from './testCafeControllerFactory';
import { World } from './world';

const TIMEOUT = 120000;
let isTestCafeError = false;
let attachScreenshotToReport: (path: string) => void | Promise<void>;
let cafeRunner: TestCafe;
const testRunsCount = 0;
let _testController;
function createTestFile() {
	fs.writeFileSync('test.js',
		'import errorHandling from "./features/support/errorHandling";\n'
        + 'import TestCafeControllerFactory from "./features/support/testCafeControllerFactory";\n\n'

        + 'fixture("fixture")\n'

        + 'test\n'
        + '("test", TestCafeControllerFactory.capture)');
}

async function runTest(iteration) {
	cafeRunner = await createTestCafe('localhost', 1338 + iteration, 1339 + iteration);

	const runner = cafeRunner.createRunner();
	let testResults;
	const defaultBrowser = process.env.TEST_CAFE_BROWSER || 'chrome';
	try {
		testResults = await runner
			.src('./test.js')
			.screenshots('reports/screenshots/', true)
			.browsers(defaultBrowser)
			.run();
	} catch (error) {
		// eslint-disable-next-line no-console
		console.error(`Error executing testcafe test: ${error}`);
		throw new Error(`${error}`);
	}

	return testResults;
}

setDefaultTimeout(TIMEOUT);

BeforeAll(() => {
	// perform some shared setup
	runTest(testRunsCount);
	createTestFile();
});

Before(async function initTestCafeControllerInstance(this: World) {
	_testController = await TestCafeControllerFactory.get();
	this.testCafeController = _testController;
});

After(() => {
	KeyChain.checkInAllKeys();
});

After(async function reportFailedTests(this: World, testCase: ITestCaseHookParameter) {
	if (testCase.result?.status === Status.FAILED) {
		isTestCafeError = true;
		attachScreenshotToReport = this.attachScreenshotToReport;
		errorHandling.addErrorToController(_testController);
		await errorHandling.ifErrorTakeScreenshot(_testController);
	}
});

AfterAll(() => {
	fs.unlinkSync('test.js');
	TestCafeControllerFactory.free(); // release the test cafe controller

	let intervalId: NodeJS.Timer;
	function waitForTestCafe() {
		intervalId = setInterval(checkLastResponse, 500);
	}

	function checkLastResponse() {
		if (_testController.testRun.lastDriverStatusResponse === 'test-done-confirmation') {
			cafeRunner.close();
			clearInterval(intervalId);
			process.exit();
		}
	}

	waitForTestCafe();
});

export default class {
	static getIsTestCafeError() {
		return isTestCafeError;
	}

	static getAttachScreenshotToReport(path: string): void | Promise<void> {
		return attachScreenshotToReport(path);
	}
}
