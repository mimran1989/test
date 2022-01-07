import testcafe from 'testcafe';
import hooks from './hooks';

export default class {
	static addErrorToController(testCafeController: any) {
		testCafeController.executionChain
			.catch((result) => {
				const tc = testcafe as any;

				const errAdapter = new tc.embeddingUtils.TestRunErrorFormattableAdapter(result, {
					testRunPhase: testCafeController.testRun.phase,
					userAgent: testCafeController.testRun.browserConnection.browserInfo.userAgent,
				});

				return testCafeController.testRun.errs.push(errAdapter);
			});
	}

	static ifErrorTakeScreenshot(resolvedTestController: any) {
		let results;
		const testController = resolvedTestController;
		if (hooks.getIsTestCafeError() === true && testController.testRun.opts.takeScreenshotsOnFails === true) {
			if (process.argv.includes('--format') || process.argv.includes('-f') || process.argv.includes('--format-options')) {
				testController.executionChain._state = 'fulfilled';
				results = resolvedTestController.takeScreenshot().then((path) => hooks.getAttachScreenshotToReport(path));
			} else {
				results = resolvedTestController.takeScreenshot();
			}
		}

		return results;
	}
}
