import { v4 as uuidv4 } from 'uuid';
import { isPlainObject, mergeWith } from 'lodash';
import { ObserverCallback } from '../base/observer';
import Sync from '../base/sync';
import { UIElementDO } from '../../interfaces/elementDO';

export interface ObservedElement {
	$id: string;
	$type: string;
	commit: Function;
	elementDO: UIElementDO;
	insert: Function;
	merge: Function;
}

export default class UIElement implements ObservedElement {
	$id: string;
	dirtyFields: Record<string, number> = {};
	elementDO: UIElementDO;
	$type: string;
	$proxied: any;

	static for(elementDO: UIElementDO): ObservedElement {
		const newElement = new this();
		newElement.$id = uuidv4();
		newElement.elementDO = elementDO;

		const {
			$id, commit, data, merge, insert, $type, ...ownProps
		} = newElement;

		delete ownProps.dirtyFields;
		delete ownProps.elementDO;

		newElement.$proxied = new Proxy(
			{
				$id,
				$type,
				commit,
				elementDO: data(),
				insert,
				merge,
			},
			this.observeElement(newElement),
		);

		return newElement.$proxied;
	}

	static newDO({ ...props }): UIElementDO {
		return {
			operationType: null,
			quoteId: props.quoteId,
		};
	}

	insert = (): void => {
		// signal insert by marking the first element key as dirty
		const elementDOKeys = Object.keys(this.elementDO);
		Sync.forType(this.$type).markDirty(this.$id, elementDOKeys[0], this);
	}

	commit = (observerName: string) => {
		const { fields: modifiedFields } = Sync.forType(this.$type).getChanges(observerName)[this.$id];
		if (modifiedFields) {
			modifiedFields.forEach((modifiedField: string) => {
				const dirtyFieldCount = (this.dirtyFields[modifiedField] || 0) - 1;
				if (dirtyFieldCount <= 0) {
					delete this.dirtyFields[modifiedField];
				} else {
					this.dirtyFields[modifiedField] = dirtyFieldCount;
				}
			});
		}

		Sync.forType(this.$type).commit(observerName, this.$id);
	};

	data = (): UIElementDO => {
		const observerCallback = {
			onEvent: (path: string[]) => {
				const objPath = path.join('.');

				Sync.forType(this.$type).markDirty(this.$id, objPath, this);
				this.markDirty(objPath);
			},
		};

		return new Proxy(this.elementDO, UIElement.observeChanges([observerCallback]));
	};

	static observeChanges(observerCallbacks: ObserverCallback[]): ProxyHandler<UIElementDO> {
		const observeChange = {
			get(target: Record<string, any>, prop: string): any {
				const targetObj = target;
				const value = targetObj[prop];
				if (value && typeof value === 'object' && !Array.isArray(value)) {
					const newHandler = { ...this };
					newHandler.path = [].concat(this.path, prop);
					return new Proxy(targetObj[prop], newHandler);
				}

				return value;
			},
			set(target: any, prop: string, value: any): boolean {
				const targetObj = target;
				const isModified = targetObj[prop] !== value;

				targetObj[prop] = value;

				if (isModified) {
					const finalPath = [].concat(...this.path, prop);
					observerCallbacks.forEach((observer: ObserverCallback) => observer.onEvent(finalPath, value));
				}

				return true;
			},
			path: [] as string[],
		};

		return observeChange;
	}

	static observeElement(element: any): ProxyHandler<ObservedElement> {
		return {
			get(target: Record<string, any>, prop: string): any {
				let result;
				if (!Object.prototype.hasOwnProperty.call(target, prop)
				&& !Object.prototype.hasOwnProperty.call(element, prop)) {
					result = target.elementDO[prop];
				} else if (!Object.prototype.hasOwnProperty.call(target, prop)) {
					result = element[prop];
				} else {
					result = target[prop];
				}

				return result;
			},
			set(target: any, prop: string, value: any): boolean {
				const targetObj = target;
				const elementObj = element;
				if (!Object.prototype.hasOwnProperty.call(target, prop)
					&& !Object.prototype.hasOwnProperty.call(elementObj, prop)) {
					targetObj.elementDO[prop] = value;
				} else if (!Object.prototype.hasOwnProperty.call(targetObj, prop)) {
					elementObj[prop] = value;
				} else {
					targetObj[prop] = value;
				}

				return true;
			},
		};
	}

	markDirty = (propertyName: string) => {
		const dirtyFieldCount = this.dirtyFields[propertyName] || 0;
		this.dirtyFields[propertyName] = dirtyFieldCount + 1;
	};

	mergeProperties = (
		destinationDO: UIElementDO,
		sourceDO: UIElementDO,
		path: string[] = [],
	): UIElementDO => mergeWith(destinationDO, sourceDO, (destinationValue, sourceValue, propertyName) => {
		const extendedPath = [...path, propertyName];
		let mergedValue = sourceValue;
		if (isPlainObject(destinationValue) || isPlainObject(sourceValue)) {
			mergedValue = this.mergeProperties(destinationValue, sourceValue, extendedPath);
		}

		const fieldName = extendedPath.join('.');
		const dirtyPropCount = this.dirtyFields[fieldName] || 0;
		if (dirtyPropCount > 0) {
			mergedValue = destinationValue;
		}

		return mergedValue;
	});

	merge = (sourceDO: UIElementDO, observerName: string) => {
		Sync.forType(this.$type).pause(observerName, this.$id);
		this.mergeProperties(this.elementDO, sourceDO);
		Sync.forType(this.$type).resume(observerName, this.$id);
	};
}
