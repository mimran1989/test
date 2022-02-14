import UIElement from './element';

describe('UIElement', () => {
	describe('constructor', () => {
		it('should tie the proxy to the element', () => {
			const newElement = UIElement.for({}) as UIElement;
			expect(newElement.$proxied).toEqual(newElement);
		});
	});
});
