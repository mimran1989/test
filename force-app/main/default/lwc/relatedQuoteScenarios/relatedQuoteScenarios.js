import { LightningElement, api } from 'lwc';

import getScenarios from '@salesforce/apex/RelatedQuoteScenariosController.getScenarios';
import log from 'c/log';

import QUOTE_TOTAL_AMOUNT_FIELD from '@salesforce/schema/Quote__c.TotalAmount__c';
import QUOTE_MARGIN_PERCENT_FIELD from '@salesforce/schema/QuoteItem__c.MarginPercent__c';
import QUOTE_TOTAL_COST_FIELD from '@salesforce/schema/Quote__c.TotalCost__c';
import QUOTE_TOTAL_TYPE_FIELD from '@salesforce/schema/Quote__c.Type__c';

export default class RelatedQuoteScenarios extends LightningElement {
	@api recordId;

	scenarioRecords = [];
	quoteRecord;

	connectedCallback() {
		this.getQuoteScenarios();
	}

	getQuoteScenarios() {
		getScenarios({ quoteId: this.recordId })
			.then((result) => {
				const scenarios = [];
				result.forEach((element) => {
					const quoteData = {};
					quoteData.Id = element.Id;
					quoteData.IdURL = `/${element.Id}`;
					quoteData.Name = element.Name;
					quoteData.marginPercent = element[QUOTE_MARGIN_PERCENT_FIELD.fieldApiName] / 100;
					quoteData.totalAmount = element[QUOTE_TOTAL_AMOUNT_FIELD.fieldApiName];
					quoteData.AccountName = element.AccountId__r?.Name;
					quoteData.RecordType = element[QUOTE_TOTAL_TYPE_FIELD.fieldApiName];
					quoteData.CreatedDate = element.CreatedDate;

					if (element[QUOTE_TOTAL_COST_FIELD.fieldApiName]) {
						quoteData.totalCost = element[QUOTE_TOTAL_COST_FIELD.fieldApiName];
					} else {
						quoteData.totalCost = 0;
					}

					scenarios.push(quoteData);
				});

				this.scenarioRecords = scenarios;
			})
			.catch((error) => {
				log('Error:');
				log(error);
			});
	}
}
