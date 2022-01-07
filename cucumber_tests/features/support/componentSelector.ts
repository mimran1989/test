import { Selector } from 'testcafe';

export type WebComponentSelector = Selector & { findComponent: (cssSelector: string) => WebComponentSelector }

export const Component = {
	named: (componentName: string): WebComponentSelector => attachFindWebComponent(Selector((value: string) => document
		.querySelectorAll(`psq-${value}`)[0] || document.querySelectorAll(`c-${value}`)[0])(componentName).shadowRoot()),
};

export const WebComponent = (cssSelector: string) : WebComponentSelector => attachFindWebComponent(
	Selector((value) => document.querySelectorAll(value)[0])(cssSelector).shadowRoot(),
);

export const Select = Selector;

function attachFindWebComponent(selector: Selector | WebComponentSelector): WebComponentSelector {
	const ctxSelector = selector as WebComponentSelector;
	ctxSelector.findComponent = findWebComponent(ctxSelector);
	return ctxSelector;
}

function findWebComponent(parentSelector: Selector | WebComponentSelector) {
	return (cssSelector: string): WebComponentSelector => attachFindWebComponent(parentSelector.find(cssSelector).shadowRoot());
}
