import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import baseJS from '@salesforce/resourceUrl/Provus';

export default class ProvusGrid extends LightningElement {
	_rendered = false;
	_initialized = false;
	_timeoutId;
	@api grid;

	// eslint-disable-next-line class-methods-use-this
	get iframeURL() {
		return `${baseJS}/grid/index.html`;
	}

	async renderedCallback() {
		if (!this._rendered) {
			this._rendered = true;
			await loadScript(this, `${baseJS}/grid/index.js`);
			this._initialized = true;
		}
	}

	async initializeFrame() {
		clearInterval(this._timeoutId);

		if (!this._initialized) {
			this._timeoutId = setInterval(() => this.initializeFrame(), 0);
		} else {
			this._timeoutId = null;

			const container = this.template.querySelector('iframe');
			this.grid = await Provus.Grid.forFrame(container, this.origin);
			this.dispatchEvent(new CustomEvent('load'));
		}
	}
}
