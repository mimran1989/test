import { LightningElement, api } from 'lwc';

export default class PercentFormatter extends LightningElement {
	displayValue;

	@api
	get percentValue() {
		return this.displayValue;
	}
	set percentValue(value) {
		this.displayValue = value / 100;
	}
}
