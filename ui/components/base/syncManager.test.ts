import { mocked } from 'ts-jest/utils';
import { ObservedElement } from '../data/element';
import Observer from './observer';
import SyncManager from './syncManager';

jest.mock('./observer', () => jest.fn().mockImplementation(() => ({
	commit: jest.fn(),
	markDirty: jest.fn(),
	pause: jest.fn(),
	resume: jest.fn(),
})));

Observer.named = jest.fn().mockImplementation((name) => new Observer(name));

describe('SyncManager', () => {
	describe('getOrCreateObserverFor', () => {
		it('should create a new observer if one does not exist', () => {
			const manager = new SyncManager();

			manager.getOrCreateObserverFor('test');
			expect(Observer.named).toBeCalledWith('test');
		});

		it('should NOT create a new observer if one exists', () => {
			const manager = new SyncManager();

			manager.getOrCreateObserverFor('test');
			manager.getOrCreateObserverFor('test');

			expect(mocked(Observer).named).toBeCalledTimes(1);
		});
	});

	describe('commit', () => {
		it('it should delegate commit to the observer', () => {
			const manager = new SyncManager();
			const observer = manager.getOrCreateObserverFor('test');

			manager.commit('test', 'testId1');
			expect(observer.commit).toBeCalledWith('testId1');
		});
	});

	describe('markDirty', () => {
		it('it should delegate mark dirty to the observer', () => {
			const manager = new SyncManager();
			const observer1 = manager.getOrCreateObserverFor('testObserver1');
			const observer2 = manager.getOrCreateObserverFor('testObserver2');

			manager.markDirty('id1', 'prop1', {} as ObservedElement);
			expect(observer1.markDirty).toBeCalledWith('id1', 'prop1', {});
			expect(observer2.markDirty).toBeCalledWith('id1', 'prop1', {});
		});
	});

	describe('markDirty', () => {
		it('it should delegate pause to the observer', () => {
			const manager = new SyncManager();
			const observer = manager.getOrCreateObserverFor('testObserver');

			manager.pause('testObserver', 'testId1');
			expect(observer.pause).toBeCalledWith('testId1');
		});
	});

	describe('markDirty', () => {
		it('it should delegate resume to the observer', () => {
			const manager = new SyncManager();
			const observer = manager.getOrCreateObserverFor('testObserver');

			manager.resume('testObserver', 'testId1');
			expect(observer.resume).toBeCalledWith('testId1');
		});
	});

	describe('watch', () => {
		it('it should return a new observer if it is not already watched', () => {
			const manager = new SyncManager();
			const observer1 = manager.getOrCreateObserverFor('testObserver1');
			const observer2 = manager.watch('testObserver2');
			expect(observer1).not.toBe(observer2);
		});

		it('it should return the same observer if it is already watched', () => {
			const manager = new SyncManager();
			const observer1 = manager.getOrCreateObserverFor('testObserver1');
			const observer2 = manager.watch('testObserver1');
			expect(observer1).toBe(observer2);
		});
	});
});
