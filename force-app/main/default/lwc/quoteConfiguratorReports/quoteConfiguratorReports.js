import { LightningElement, api } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QuoteConfiguratorReports extends LightningElement {
	@api set chartConfig(value) {
		this._chartConfig = value;

		if (this.isChartJsInitialized) {
			const canvas = document.createElement('canvas');
			this.template.querySelector('.chart-container').appendChild(canvas);
			const ctx = canvas.getContext('2d');
			if (this.chart) {
				this.chart.destroy();
			}

			this.chart = new window.Chart(ctx, JSON.parse(JSON.stringify(value)));
		}
	}

	get chartConfig() {
		return this._chartConfig;
	}
	_chartConfig;

	isChartJsInitialized;
	renderedCallback() {
		if (this.isChartJsInitialized) {
			return;
		}

		Promise.all([loadScript(this, chartjs)])
			.then(() => {
				this.isChartJsInitialized = true;
				const canvas = document.createElement('canvas');
				this.template.querySelector('.chart-container').appendChild(canvas);
				const ctx = canvas.getContext('2d');
				this.chart = new window.Chart(ctx, JSON.parse(JSON.stringify(this.chartConfig)));
			})
			.catch((error) => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error loading Chart',
						message: error.message,
						variant: 'error',
					}),
				);
			});
	}
}
