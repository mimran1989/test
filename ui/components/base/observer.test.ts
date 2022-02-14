import Observer from './observer';
import { ObservedElement } from '../data/element';

describe('Observer', () => {
	it('should create a new observer', () => {
		const observer = Observer.named('test');
		expect(observer.name).toEqual('test');
	});

	describe('commit', () => {
		it('should remove the provided objectId from the dirty fields map', () => {
			const observer = Observer.named('test');
			observer.markDirty('testId', 'testProperty', null);

			observer.commit('testId');
			expect(observer.$dirty).toEqual({});
		});
	});

	describe('dirtyFields', () => {
		it('should get the dirty fields', () => {
			const observer = Observer.named('test');
			const testObservedElem = { $id: 'testId' } as ObservedElement;
			const testObservedElem2 = { $id: 'testId2' } as ObservedElement;

			observer.markDirty('testId', 'testProperty', testObservedElem);
			observer.markDirty('testId', 'testProperty2', testObservedElem);
			observer.markDirty('testId2', 'testProperty', testObservedElem2);

			expect(observer.dirtyFields).toEqual({
				testId: { fields: ['testProperty', 'testProperty2'], element: testObservedElem },
				testId2: { fields: ['testProperty'], element: testObservedElem2 },
			});
		});
	});

	describe('markDirty', () => {
		it('should mark the field as dirty if the observer is not paused', () => {
			const observer = Observer.named('test');

			observer.markDirty('testId', 'testProperty', null);
			expect(observer.$dirty).toEqual({
				testId: { fields: { testProperty: true }, element: null },
			});
		});

		it('should NOT mark the field as dirty if the objectId is paused', () => {
			const observer = Observer.named('test');
			observer.pause('testId');

			observer.markDirty('testId', 'testProperty', null);
			expect(observer.$dirty).toEqual({});
		});

		it('should NOT mark the field as dirty if all objects are paused', () => {
			const observer = Observer.named('test');
			observer.pause();

			observer.markDirty('testId', 'testProperty', null);
			expect(observer.$dirty).toEqual({});
		});
	});

	describe('pause', () => {
		it('should pause all items', () => {
			const observer = Observer.named('test');
			observer.pause();

			expect(observer.paused.All).toEqual(true);
		});

		it('should pause the provided objectId', () => {
			const observer = Observer.named('test');
			observer.pause('testId');

			expect(observer.paused.testId).toEqual(true);
		});
	});

	describe('resume', () => {
		it('should unpause all items', () => {
			const observer = Observer.named('test');
			observer.pause();

			observer.resume();
			expect(observer.paused.All).toEqual(false);
		});

		it('should unpause the provided objectId', () => {
			const observer = Observer.named('test');
			observer.pause('testId');

			observer.resume('testId');
			expect(observer.paused.testId).toEqual(undefined);
		});
	});
});
