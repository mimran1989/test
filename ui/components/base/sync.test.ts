import Sync from './sync';

describe('forType', () => {
	it('should return a new sync manager', () => {
		const syncManager = Sync.forType('type1');
		expect(syncManager).not.toBeNull();
		expect(syncManager).toBeDefined();
	});

	it('should return one sync manager per type', () => {
		const syncManager1 = Sync.forType('type1');
		const syncManager2 = Sync.forType('type2');

		expect(syncManager1).not.toBe(syncManager2);
	});
});
