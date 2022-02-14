import SyncManager from './syncManager';

declare const window: any;

export default class Sync {
	private static syncMgrByType: Record<string, SyncManager> = {};
	static forType(type: string): SyncManager {
		let manager: SyncManager = this.syncMgrByType[type];
		if (!manager) {
			manager = new SyncManager();
			this.syncMgrByType[type] = manager;
		}

		return manager;
	}
}

if (!window.Provus) {
	window.Provus = {};
}

window.Provus.Sync = Sync;
