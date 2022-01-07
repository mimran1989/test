let _testCafeController: TestController | PromiseLike<TestController> | null;
let _testCompleteResolver: (values?: unknown) => void;
let _testCafeResolver: (testController: TestController | PromiseLike<TestController>) => void;

export default class TestCafeControllerFactory {
	static async capture(testCafeController: TestController): Promise<void> {
		_testCafeController = testCafeController;

		if (_testCafeResolver) {
			await _testCafeController.maximizeWindow();
			_testCafeResolver(_testCafeController as TestController | PromiseLike<TestController>);
		}

		return new Promise((resolve) => {
			_testCompleteResolver = resolve;
		});
	}

	static free() {
		_testCafeController = null;

		if (_testCompleteResolver) {
			_testCompleteResolver();
		}
	}

	static async get(): Promise<TestController> {
		return new Promise((resolve) => {
			if (_testCafeController) {
				resolve(_testCafeController);
			} else {
				_testCafeResolver = resolve;
			}
		});
	}
}
