import Observer from './observer';
import { ObservedElement } from '../data/element';

export default class SyncManager {
	private observers: Record<string, Observer> = {};

	commit(observerName: string, objectId: string) {
		const observer = this.observers[observerName];
		if (observer) {
			observer.commit(objectId);
		}
	}

	getChanges(observerName: string): Record<string, { fields: string[]; element: ObservedElement }> {
		return this.getOrCreateObserverFor(observerName).dirtyFields;
	}

	getOrCreateObserverFor(observerName: string): Observer {
		let observer = this.observers[observerName];
		if (!observer) {
			observer = Observer.named(observerName);
			this.observers[observerName] = observer;
		}

		return observer;
	}

	markDirty(objectId: string, propertyName: string, object: ObservedElement) {
		Object.values(this.observers).forEach((observer) => observer.markDirty(objectId, propertyName, object));
	}

	pause(observerName: string, objectId?: string) {
		this.getOrCreateObserverFor(observerName).pause(objectId);
	}

	resume(observerName: string, objectId?: string) {
		this.getOrCreateObserverFor(observerName).resume(objectId);
	}

	watch(observerName: string): Observer {
		return this.getOrCreateObserverFor(observerName);
	}
}
