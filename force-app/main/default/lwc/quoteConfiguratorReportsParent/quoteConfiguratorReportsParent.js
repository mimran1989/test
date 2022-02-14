import { LightningElement, api, track } from 'lwc';

export default class QuoteConfiguratorReportsParent extends LightningElement {
	@api recordId;
	@track chartConfiguration;
	@track chartConfigurationRevenue;
	@track isVisible = false;

	ComponentId = 'quoteMetrics';
	_stateService;

	static createChartLabel(label, data, backgroundColor) {
		return { label, data, backgroundColor };
	}

	renderedCallback() {
		this._stateService = this.template.querySelector('.component-state');
	}

	createChartConfig() {
		return {
			type: 'pie',
			data: {
				labels: this.chartCountryLabels,
				datasets: [
					{
						data: this.chartCountryHeadCounts,
						backgroundColor: [
							'rgba(13, 112, 165, 1)',
							'rgba(65, 148, 249, 1)',
							'rgba(35, 118, 204, 1)',
							'rgba(1, 118, 211, 1)',
							'rgba(53, 93, 150, 1)',
						],
					},
				],
			},
			options: {
				responsive: true,
				plugins: {
					legend: {
						position: 'top',
					},
				},
				title: {
					display: true,
					text: 'Head Count By Location',
					color: '#0d70a5',
				},
			},
		};
	}

	createRevenueVsCostConfig() {
		return {
			type: 'bar',
			data: {
				labels: this.chartCountryLabels,
				datasets: [
					QuoteConfiguratorReportsParent.createChartLabel('Revenue,', this.chartCountryRevenue, 'rgba(13, 112, 165, 1)'),
					QuoteConfiguratorReportsParent.createChartLabel('Cost', this.chartCountryCost, 'rgba(65, 148, 249, 1)'),
				],
			},
			options: {
				responsive: true,
				base: 0,
				plugins: {
					legend: {
						position: 'right',
					},
				},
				title: {
					display: true,
					text: 'Revenue/Cost By Location',
					color: '#0d70a5',
				},
				scales: {
					yAxes: [
						{
							ticks: {
								beginAtZero: true,
							},
						},
					],
				},
			},
		};
	}

	handleNameRangeUpdates(event) {
		const totals = event.detail.value;
		this.chartCountryLabels = [];
		this.chartCountryHeadCounts = [];
		this.chartCountryRevenue = [];
		this.chartCountryCost = [];

		if (totals.length > 0) {
			for (let i = 0; i < totals.length; i++) {
				const totalKeys = Object.keys(totals[i].totalQuantity);
				for (let j = 0; j < totalKeys.length; j++) {
					const key = totalKeys[j];
					if (key !== 'undefined') {
						this.chartCountryLabels.push(key);
						this.chartCountryHeadCounts.push(totals[i].totalQuantity[key]);
						this.chartCountryRevenue.push(totals[i].totalAmount[key]);
						this.chartCountryCost.push(totals[i].totalCost[key]);
					}
				}
			}
		}

		this.chartConfiguration = this.createChartConfig();
		this.chartConfigurationRevenueVsCost = this.createRevenueVsCostConfig();
		this.error = undefined;
	}

	handleStatusRequest(event) {
		const { receiver } = event.detail.value;
		if (receiver === null || receiver === this.ComponentId) {
			const payload = {
				reporter: this.ComponentId,
				status: {
					visible: this.isVisible,
				},
			};

			this._stateService.publish({
				key: 'report',
				value: payload,
			});
		}
	}

	handleHide(event) {
		const { receiver } = event.detail.value;
		if (receiver === this.ComponentId) {
			this.isVisible = false;
		}
	}

	handleShow(event) {
		const { receiver } = event.detail.value;
		if (receiver === this.ComponentId) {
			this.isVisible = true;
		}
	}
}
