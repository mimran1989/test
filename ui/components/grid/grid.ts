// eslint-disable-next-line max-classes-per-file
import Handsontable from 'handsontable';

// CSS imports
import 'handsontable/dist/handsontable.full.css';
import '@salesforce-ux/design-system/assets/styles/salesforce-lightning-design-system.css';
import './styles/grid.css';
import './styles/dropdownMenu.css';

import { v4 as uuidv4 } from 'uuid';
import { merge, cloneDeep } from 'lodash';

const Deferred = require('deferred');

declare const window: any;

/**
 *  IFrameCallback
 *
 * This class, IFrameCallback, is used for defining functions
 * which need to be executed within the IFrames contentDocument
 *
 * The function will be converted to a function string and executed
 * in the local context of the IFrame. Expect the globalThis context will
 * be of the frames contextDocument and not of the parent.*
 */
class IFrameCallback {
	type: 'IFrameCallback';
	public functionString: string;

	constructor(fn: Function) {
		this.functionString = fn.toString();
	}
}

export default class ProvusGrid {
	frame: any;
	container: any;
	origin: any;
	callbacks: Record<string, Function> = {};
	table: any;
	pendingResponse: Record<string, any> = {};
	initDeferred: typeof Deferred;
	_connectionId: string;

	constructor(bypas = false, connectionId?: string) {
		Handsontable.renderers.registerRenderer('sectionName', this.sectionNameRenderer);
	}

	sectionNameRenderer(instance: any, td: any, row: any, column: any, prop: any, value: any) {
		Handsontable.renderers.TextRenderer.apply(this, arguments);
		if (value) {
			td.innerHTML = `${'&emsp;'.repeat(instance.getSourceDataAtRow(row).$treeLevel)}${value}`;

			// TODO: conditionally check the row type before adding the sectionHeader class in case we lose the section column
			td.classList.add('sectionHeader');
		}
		return td;
	};

	static async forFrame(frame: any, origin: any): Promise<ProvusGrid> {
		const gridMessenger = new ProvusGrid();
		gridMessenger.table = new Proxy(gridMessenger, tableHandler());
		await gridMessenger.connectParentToFrame(frame);

		return new Proxy(gridMessenger, gridHandler());
	}

	async connectParentToFrame(frame: any) {
		this.frame = frame;
		if (this.frame) {
			this._connectionId = uuidv4();

			const deferred = new Deferred();
			function resolveConnection({data}: any) {
				if (data === 'host-connection-acknowledged') {
					deferred.resolve();
					window.removeEventListener('message', resolveConnection);
				}
			};

			window.addEventListener('message', resolveConnection);
			this.frame.contentWindow.postMessage({action: 'host-connection-request', connectionId: this._connectionId}, '*');
			await deferred.promise;
			this.listenForAndHandleResponses();
		}
	}

	listenForAndHandleResponses() {
		window.addEventListener('message', ({data}: any) => {
			let detail: Record<string, any> = {};
			try {
				({ detail} = JSON.parse(data));
			} finally {
				if (detail?.channel === 'gridresponse') {
					this.processMessage(detail);
				}
			}
		});
	}

	listenForAndHandleMessages(connectionId: string) {
		this._connectionId = connectionId;
		window.addEventListener('message', ({data }: any) => {
			let detail: Record<string, any> = {};
			try {
				({ detail} = JSON.parse(data));
			} finally {
				if (detail?.channel === 'gridmessage') {
					this.processMessage(detail);
				}
			}
		});
	}

	executeCallback(callbackName: string, args: any[]): ProvusGrid {
		const callback = this.callbacks[callbackName];
		if (callback) {
			callback(...args);
		}

		return this;
	}

	async init(options: any, optionKeys: string[]) {
		let deProxiedOptions = cloneDeep(options);

		if (this.frame) {
			const { resolver, messageId } = this.createMessageHeader();

			this.initDeferred = this.pendingResponse[messageId];
			this.frame.contentWindow.postMessage(JSON.stringify({ detail: {
				channel: 'gridmessage',
				connectionId: this._connectionId, detail: {
				action: 'init-grid',
				options: this.sanitizeOptions(deProxiedOptions),
				messageId,
			}}}), '*');
			await resolver;
		} else {
			this.table = new Handsontable(this.container, deProxiedOptions);
		}
	}

	afterInit() {
		this.messageTop({
			action: 'init-complete',
		});
	}

	messageTop(message: any) {
		window.parent.postMessage(JSON.stringify({ detail: { channel: 'gridresponse', connectionId: this._connectionId, detail:{...message }}}), '*');
		return this;
	}

	onMovePeriods(fn: Function) {
		this.callbacks.movePeriods = fn;
		return this;
	}

	post(action: string, data: any): ProvusGrid {
		this.messageTop({
			action,
			data: JSON.stringify(data),
		});

		return this;
	}

	initializeGridComponent(options: any): ProvusGrid {
		document.body.innerHTML = '<div id="gridContainer"/>';

		const container = document.getElementById('gridContainer');
		this.table = new Handsontable(
			container,
			merge(
				{
					afterInit: () => this.afterInit(),
				},
				this.deSanitize(options),
			),
		);

		/*	{
			...options,
			afterChange: (...data: any) => this.post('row-change', data),
			beforeRemoveRow: (...data: any) => this.post('row-delete', data),
		});
*/
		return this;
	}

	deSanitize(options: Record<any, any>): Record<any, any> {
		const deSanitized: Record<any, any> = {};
		Object.keys(options).forEach((key) => {
			const contextObject = options[key];
			if (!Array.isArray(contextObject) && typeof contextObject === 'object') {
				if (contextObject.functionString) {
					// eslint-disable-next-line no-new-func
					deSanitized[key] = Function(`"use strict";return (${contextObject.functionString})`)();
				} else {
					deSanitized[key] = this.deSanitize(contextObject);
				}
			} else if (typeof contextObject === 'string' && contextObject.indexOf('fn-') === 0) {
				deSanitized[key] = (...data: any) => this.post(contextObject, data);
			} else {
				deSanitized[key] = contextObject;
			}
		});

		return deSanitized;
	}

	sanitizeOptions(options: Record<any, any>): Record<any, any> {
		const sanitizedOptions: Record<any, any> = {};
		Object.keys(options).forEach((key) => {
			const contextObject = options[key];
			if (!Array.isArray(contextObject) && typeof contextObject === 'object') {
				sanitizedOptions[key] = this.sanitizeOptions(contextObject);
			} else if (typeof contextObject === 'function' && contextObject.type === 'IFrameCallback') {
				sanitizedOptions[key] = {
					functionString: contextObject.functionString,
				};
			} else if (typeof contextObject === 'function') {
				const fnToken = `fn-${uuidv4()}`;
				this.callbacks[fnToken] = contextObject;
				sanitizedOptions[key] = fnToken;
			} else {
				sanitizedOptions[key] = contextObject;
			}
		});

		return sanitizedOptions;
	}

	// eslint-disable-next-line max-lines-per-function

	processMessage({ connectionId, detail }: any): ProvusGrid {
		if (connectionId !== this._connectionId) {
			return;
		}

		const { action, data, messageId } = detail;
		if (action === 'init-grid') {
			const { options } = detail;
			this.initializeGridComponent(options);
		} else if (action === 'init-complete') {
			this.initDeferred.resolve();
		} else if (`${action}`.indexOf('fn-') === 0) {
			this.executeCallback(action, JSON.parse(data));
		} else if (action === 'move-periods') {
			this.executeCallback('movePeriods', JSON.parse(data));
		} else if (action === 'call') {
			const { methodName } = detail;
			const [args] = JSON.parse(data);
			const response = this.table[methodName](...args);
			if (response && !Array.isArray(response) && typeof response === 'object') {
				delete response.instance;
			}

			this.messageTop({
				action: 'call-response',
				messageId,
				data: JSON.stringify(response),
			});
		} else if (action === 'call-response') {
			const resolver = this.pendingResponse[messageId];
			delete this.pendingResponse[messageId];
			resolver.resolve(data ? JSON.parse(data) : data);
		} else if (action === 'invokeMethods') {
			const [args] = JSON.parse(data);
			let [invocationTree] = args;
			let response = this.table;
			do {
				const { methodName, args: invocationArgs } = invocationTree;
				response = response[methodName](...invocationArgs);
				invocationTree = invocationTree.then;
			} while (invocationTree);

			if (response && !Array.isArray(response) && typeof response === 'object') {
				delete response.sanitized;
			}

			this.messageTop({
				action: 'call-response',
				messageId,
				data: JSON.stringify(response),
			});
		}

		return this;
	}

	createMessageHeader() {
		const deferred = new Deferred();
		const messageId = uuidv4();

		this.pendingResponse[messageId] = deferred;

		return {
			resolver: deferred.promise,
			messageId,
		};
	}

	invoke(methodName: string, ...args: any[]): any {
		let result;
		if (this.frame) {
			const { resolver, messageId } = this.createMessageHeader();
			result = resolver;
			this.frame.contentWindow.postMessage(JSON.stringify({ detail: {
				channel: 'gridmessage', connectionId: this._connectionId, detail: {
				action: methodName === 'invokeMethods' ? methodName : 'call',
				data: JSON.stringify(args),
				messageId,
				methodName,
			}}}),'*');
		} else if (this.table) {
			result = this.table[methodName](...args);
		}

		return result;
	}

	// a function that will be executed in the context of Iframe
	// eslint-disable-next-line class-methods-use-this
	static IFrameFnFor(fn: Function): IFrameCallback {
		return new IFrameCallback(fn);
	}
}

function gridHandler(): ProxyHandler<any> {
	return {
		get(target: any, propertyName: string) {
			let targetValue = target[propertyName];
			if (!targetValue) {
				targetValue = target.table[propertyName];
			}

			return targetValue;
		},
	};
}

function tableHandler(): ProxyHandler<any> {
	return {
		get(grid: any, propertyName: any): any {
			if (propertyName !== 'then') {
				return (...args: any[]) => grid.invoke(propertyName, args);
			}
		},
	};
}

if (!window.Provus) {
	window.Provus = {};
}

window.Provus.Grid = ProvusGrid;

window.onmessage = function({ data }: any) {
	const { action, connectionId } = data;
	if (action === 'host-connection-request') {
		const connector = new Proxy(new ProvusGrid(), gridHandler());
		connector.listenForAndHandleMessages(connectionId);
		window.parent.postMessage('host-connection-acknowledged', '*');
	}
}