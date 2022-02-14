import { ObservedElement } from '../data/element';

export type ObserverCallback = {
	onEvent: Function;
};

export default class Observer {
	readonly name: string;
	$dirty: Record<string, { element: ObservedElement; fields: Record<string, boolean> }> = {};
	paused: Record<string, boolean> = { All: false };

	static named(observerName: string): Observer {
		return new Observer(observerName);
	}
	constructor(name: string) {
		this.name = name;
	}

	commit(objectId: string) {
		delete this.$dirty[objectId];
	}

	get dirtyFields(): Record<string, { fields: string[]; element: ObservedElement }> {
		const dirtyFields: Record<string, { fields: string[]; element: ObservedElement }> = {};
		Object.keys(this.$dirty).forEach((objectId) => {
			dirtyFields[objectId] = {
				fields: Object.keys(this.$dirty[objectId].fields),
				element: this.$dirty[objectId].element,
			};
		});

		return dirtyFields;
	}

	markDirty(objectId: string, property: string, element: ObservedElement) {
		const isPaused = this.paused[objectId] === true || this.paused.All === true;
		if (!isPaused) {
			let dirtyFieldsForObject = this.$dirty[objectId];
			if (!dirtyFieldsForObject) {
				dirtyFieldsForObject = {
					element,
					fields: {},
				};
				this.$dirty[objectId] = dirtyFieldsForObject;
			}

			dirtyFieldsForObject.fields[property] = true;
		}
	}

	pause(objectId?: string) {
		if (!objectId) {
			this.paused.All = true;
		} else {
			this.paused[objectId] = true;
		}
	}

	resume(objectId?: string) {
		if (!objectId) {
			this.paused.All = false;
		} else {
			delete this.paused[objectId];
		}
	}
}
