import { Selector } from 'testcafe';

const WebComponentSearchMethods = [
	'find',
	'parent',
	'child',
	'sibling',
	'nextSibling',
	'prevSibling',
];

interface IWebComponentSelector extends Selector {
	find: (...params) => WebComponentSelector;
	parent: (...params) => WebComponentSelector;
	child: (...params) => WebComponentSelector;
	sibling: (...params) => WebComponentSelector;
	nextSibling: (...params) => WebComponentSelector;
	prevSibling: (...params) => WebComponentSelector;
	findWebComponent: (componentName: string) => WebComponentSelector;
	findComponent: (componentName: string) => WebComponentSelector;
	shadowRoot: () => WebComponentSelector;

}

export type WebComponentSelector = Omit<Selector, keyof IWebComponentSelector> & IWebComponentSelector;

export const Component = {
	named: (componentName: string): WebComponentSelector => attachWebComponentSelectorMethods(Selector((value: string) => document
		.querySelectorAll(`psq-${value}`)[0] || document.querySelectorAll(`c-${value}`)[0])(componentName).shadowRoot()),
	for: (selector: Selector) => attachWebComponentSelectorMethods(selector.shadowRoot()),
};

export const WebComponent = (cssSelector: string) : WebComponentSelector => attachWebComponentSelectorMethods(
	Selector((value) => document.querySelectorAll(value)[0])(cssSelector).shadowRoot(),
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
	const shadowRootFn = ctxSelector.shadowRoot;
	ctxSelector.shadowRoot = () => attachWebComponentSelectorMethods(shadowRootFn.call(ctxSelector));

	return ctxSelector as WebComponentSelector;
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
