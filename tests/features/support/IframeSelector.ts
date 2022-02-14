import { ClientFunction, Selector } from 'testcafe';
import { WebComponentSelector } from './componentSelector';

const Deferred = require('deferred');

interface IFrameSelectorFactory {
	(selector: string | WebComponentSelector | Selector): IFrameSelector;
}

interface APIChainFN {
	action: string | ((node: Element | NodeListOf<any>, ...args: any[]) => Element | NodeListOf<any>),
	params: any[],
	canPerformOnList?: boolean;
}

export interface SelectorOptions {
	boundTestRun?: TestController;
}

export type DOMNodeState = {
	exists: boolean;
	innerText: string;
}

type DOMNodeStateResolver = {
	exists: Promise<boolean>;
	innerText: Promise<string>;
}

const DOMNodeStateMethods = [
	'exists',
	'innerText',
];

export interface IFrameSelector extends DOMNodeStateResolver {
	(): Promise<DOMNodeState>;
	element: Document | HTMLElement | NodeListOf<HTMLElement>;
	child(selectorOrIdx: number | string): IFrameSelector;
	find(cssSelector: string): IFrameSelector;
	nth(idx: number): IFrameSelector;
	nthDescendant(levels: number): IFrameSelector;
	with(options: SelectorOptions): IFrameSelector;
	withExactText(textString: string): IFrameSelector;
}

export class IFrameSelector extends Function {
	private fnChain: APIChainFN[] = [];
	private _iframeSelector: WebComponentSelector | Selector;
	private _stateResolvers: Map<string, typeof Deferred> = new Map<string, typeof Deferred>();
	private selectorOptions: SelectorOptions;
	private _bound: IFrameSelector;

	constructor(selector: string | WebComponentSelector | Selector, selectorOptions?: SelectorOptions) {
		super();

		if (typeof selector === 'string') {
			this._iframeSelector = Selector(selector);
		} else {
			this._iframeSelector = selector;
		}

		this.selectorOptions = selectorOptions;
		this._initializeStateResolvers();
		return new Proxy(this, {
			apply: (target) => target._call(),
		});
	}

	_call(): Promise<DOMNodeState> {
		let nodeStateFN = this._queryDOMElement();
		if (this.selectorOptions?.boundTestRun) {
			nodeStateFN = nodeStateFN.with({ boundTestRun: this.selectorOptions.boundTestRun });
		}

		// intentionally using thenable to return control back to callee
		// before resolving state promises
		const nodeState = nodeStateFN();
		nodeState.then((state) => this._resolveStatePromises(state));

		return nodeState;
	}

	_initializeStateResolvers() {
		for (let i = 0; i < DOMNodeStateMethods.length; i++) {
			const stateMethodName = DOMNodeStateMethods[i];
			const deferred = new Deferred();
			this._stateResolvers.set(stateMethodName, deferred);
			this[stateMethodName] = deferred.promise;
		}
	}

	_resolveStatePromises(nodeState: DOMNodeState) {
		for (let i = 0; i < DOMNodeStateMethods.length; i++) {
			const stateMethodName = DOMNodeStateMethods[i];
			const resolver = this._stateResolvers.get(stateMethodName);
			resolver.resolve(nodeState[stateMethodName]);
		}
	}

	with(options: SelectorOptions): IFrameSelector {
		const newSelector = new IFrameSelector(this._iframeSelector, options);
		newSelector.fnChain = this.fnChain;
		return newSelector;
	}

	// eslint-disable-next-line max-lines-per-function
	_queryDOMElement(): ClientFunction<DOMNodeState> {
		const iframe = this._iframeSelector;
		const apiChain: APIChainFN[] = this.fnChain;
		return ClientFunction(() => {
			let i = 0;
			let selectedElement: Document | NodeListOf<HTMLElement> | HTMLElement = (iframe() as unknown as HTMLIFrameElement)?.contentDocument;
			// select the element
			while (i < apiChain.length && selectedElement) {
				let ctxElement = selectedElement;
				const isArray = typeof ctxElement[Symbol.iterator] === 'function';
				const { action, canPerformOnList, params } = apiChain[i];
				if (isArray && canPerformOnList !== true) {
					[ctxElement] = ctxElement as unknown as Iterable<Element>;
				}

				if (typeof action === 'function') {
					selectedElement = (action as Function)(ctxElement, ...params);
				} else {
					selectedElement = ctxElement[action](...params);
				}

				i += 1;
			}

			const isArray = selectedElement && typeof selectedElement[Symbol.iterator] === 'function';
			if (isArray) {
				[selectedElement] = selectedElement as unknown as Iterable<HTMLElement>;
			}

			// return the DOMState of the selected element
			const resultElement = selectedElement as HTMLElement;

			const result: DOMNodeState = {
				innerText: resultElement?.innerText,
				exists: !!resultElement,
			};

			return result;
		}, { dependencies: { apiChain, iframe } });
	}

	nthDescendant(levels: number): IFrameSelector {
		let rootInstance: IFrameSelector = this;
		for (let i = 1; i < levels + 1; i++) {
			rootInstance = rootInstance.child(0);
		}

		return rootInstance;
	}

	nth(idx: number): IFrameSelector {
		return this.newInstance({
			action: (nodes: NodeListOf<Element>, selectIdx: number): Element => nodes[selectIdx],
			params: [idx],
			canPerformOnList: true,
		});
	}

	child(selectorOrIdx: number | string): IFrameSelector {
		return this.newInstance({
			action: (node: Element, cssOrIdx: number | string): Element | NodeListOf<Element> => {
				let queriedElements: Element | NodeListOf<Element>;
				if (typeof cssOrIdx === 'string') {
					queriedElements = node.querySelectorAll(`:scope > ${cssOrIdx}`);
				} else {
					queriedElements = node.children[cssOrIdx];
				}

				return queriedElements;
			},
			params: [selectorOrIdx],
		});
	}

	find(cssSelector: string) {
		return this.newInstance({
			action: 'querySelectorAll',
			params: [cssSelector],
		});
	}

	newInstance(nextSelector: APIChainFN) {
		const nextSelectorInstance = new IFrameSelector(this._iframeSelector);
		nextSelectorInstance.fnChain = this.fnChain.concat([nextSelector]);
		return nextSelectorInstance;
	}

	withExactText(testString: string): IFrameSelector {
		return this.newInstance({
			action: (nodes: HTMLElement | NodeListOf<HTMLElement>, checkString: string): NodeListOf<HTMLElement> => {
				const resultList: HTMLElement[] = [];
				const isArray = typeof nodes[Symbol.iterator] === 'function';
				if (isArray) {
					for (let i = 0; i < (nodes as NodeListOf<HTMLElement>).length; i++) {
						const node: HTMLElement = (nodes as NodeListOf<HTMLElement>)[i];
						if (node.innerText === checkString) {
							resultList.push(node);
						}
					}
				}

				const resultNodeList: NodeListOf<HTMLElement> = Object.create(document.createDocumentFragment().childNodes, {
					length: {
						value: resultList.length, enumerable: false,
					},
					item: {
						value(idx: number) {
							return this[+idx || 0];
						},
						enumerable: false,
					},
				});

				resultList.forEach((element: HTMLElement, idx: number) => {
					resultNodeList[idx] = element;
				});

				return resultNodeList;
			},
			params: [testString],
			canPerformOnList: true,
		});
	}
}

const newIFrameSelector = (selector: string | WebComponentSelector | Selector) => new IFrameSelector(selector);
export const SelectFrame: IFrameSelectorFactory = newIFrameSelector;
