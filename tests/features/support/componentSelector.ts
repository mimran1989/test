import { Selector } from 'testcafe';
import { IFrameSelector, SelectFrame } from './iframeSelector';

const WebComponentSearchMethods = [
	'addCustomMethods',
	'find',
	'filter',
	'nth',
	'parent',
	'child',
	'sibling',
	'nextSibling',
	'prevSibling',
];

interface IWebComponentSelector extends Selector {
	find: (...params) => WebComponentSelector;
	filter: (...params) => WebComponentSelector;
	nth: (...params) => WebComponentSelector;
	parent: (...params) => WebComponentSelector;
	child: (...params) => WebComponentSelector;
	nthDescendant: (...params) => WebComponentSelector;
	sibling: (...params) => WebComponentSelector;
	nextSibling: (...params) => WebComponentSelector;
	prevSibling: (...params) => WebComponentSelector;
	findWebComponent: (componentName: string) => WebComponentSelector;
	findComponent: (componentName: string) => WebComponentSelector;
	shadowRoot: () => WebComponentSelector;
	iframe: () => IFrameSelector;

}

export type WebComponentSelector = Omit<Selector, keyof IWebComponentSelector> & IWebComponentSelector;

export const Component = {
	named: (componentName: string): WebComponentSelector => attachWebComponentSelectorMethods(Selector((value: string) => document
		.querySelectorAll(`psq-${value}`)[0] || document.querySelectorAll(`c-${value}`)[0])(componentName).shadowRoot()),
	for: (selector: Selector) => attachWebComponentSelectorMethods(selector.shadowRoot()),
};

export const WebComponent = (cssSelector: string, index: number = 0) : WebComponentSelector => attachWebComponentSelectorMethods(
	Selector((value) => document.querySelectorAll(value))(cssSelector).nth(index).shadowRoot(),
);

export const Select = Selector;

function attachWebComponentSelectorMethods(selector: Selector): WebComponentSelector {
	const ctxSelector = selector;// as WebComponentSelector;
	for (let i = 0; i < WebComponentSearchMethods.length; i++) {
		const methodName = WebComponentSearchMethods[i];
		const originalMethod = ctxSelector[methodName];
		ctxSelector[methodName] = (...params) => attachWebComponentSelectorMethods(originalMethod(...params));
	}

	(ctxSelector as WebComponentSelector).findComponent = (componentName: string) => attachWebComponentSelectorMethods(findComponent.call(ctxSelector, componentName));
	(ctxSelector as WebComponentSelector).findWebComponent = (cssSelector: string) => attachWebComponentSelectorMethods(findWebComponent.call(ctxSelector, cssSelector));
	(ctxSelector as WebComponentSelector).nthDescendant = (levels: number) => attachWebComponentSelectorMethods(nthDescendant.call(ctxSelector, levels));
	const shadowRootFn = ctxSelector.shadowRoot;
	ctxSelector.shadowRoot = () => attachWebComponentSelectorMethods(shadowRootFn.call(ctxSelector));
	(ctxSelector as WebComponentSelector).iframe = () => SelectFrame(ctxSelector);

	return ctxSelector as WebComponentSelector;
}

function nthDescendant(this: Selector, levels: number) : Selector {
	let ancestor = this;
	for (let i = 1; i < levels + 1; i++) {
		ancestor = ancestor.child(0);
	}

	return ancestor;
}

function findComponent(this: Selector, componentName: string) : Selector {
	const devComponentName = `c-${componentName.toLowerCase()}`;
	const namespaceQualifiedComponent = `psq-${componentName.toLowerCase()}`;

	return this
		.find((descendant) => {
			const tagName = descendant?.tagName.toLowerCase();
			return tagName === devComponentName || tagName === namespaceQualifiedComponent;
		},
		{ devComponentName, namespaceQualifiedComponent })
		.shadowRoot();
}

function findWebComponent(this: Selector, cssSelector: string) : Selector {
	return this.find(cssSelector).shadowRoot();
}
