/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { LightningElement, api, wire } from 'lwc';
import NamespacePrefix from '@salesforce/apex/SystemUtility.getNamespacePrefix';

import LABEL_CONFIGURATION_CHANGED from '@salesforce/label/c.ConfigurationChanged';
import LABEL_IGNORE from '@salesforce/label/c.Ignore';
import LABEL_IGNORE_ALL from '@salesforce/label/c.IgnoreAll';
import LABEL_REVIEW from '@salesforce/label/c.Review';

export default class Notifier extends LightningElement {
	static TRANSITION_TIME = 200; // transition animation time
	static PESTER_TIME = 5000; // time until toast disappears

	toastMessage;

	LABEL_IGNORE = LABEL_IGNORE;
	LABEL_IGNORE_ALL = LABEL_IGNORE_ALL;
	LABEL_REVIEW = LABEL_REVIEW;

	@api quote;

	@wire(NamespacePrefix)
	nsPrefix;
	onMessage;
	isIgnored = false;
	isVisible = false;
	loaded = false;

	connectedCallback() {
		const component = this;
		this.onMessage = (() => (response) => {
			let eventUser;
			let affectedQuotes;
			Object.entries(response.data.payload).forEach(([field, value]) => {
				if (field.endsWith('User__c')) {
					eventUser = value;
				}

				if (field.endsWith('AffectedQuotes__c')) {
					affectedQuotes = value.split(',');
				}
			});

			if (affectedQuotes.includes(component.quote) && !component.isIgnored) {
				component.toastMessage = component.toastMessage || LABEL_CONFIGURATION_CHANGED.replace('{0}', eventUser);
				component.isVisible = true;
				component.show();
			}
		})();
	}

	get channel() {
		let channel;
		if (this.nsPrefix.data !== undefined) {
			channel = `${this.nsPrefix.data}QuoteUpdate__e`;
		}

		return channel;
	}

	handleIgnore() {
		this.hide();
	}

	handleIgnoreAll() {
		this.handleIgnore();
		this.isIgnored = true;
	}

	show() {
		setTimeout(() => {
			this.template.querySelector('.slds-notify').classList.remove('slds-transition-hide');
			this.template.querySelector('.slds-notify').classList.add('slds-transition-show');
		}, 0);
		setTimeout(() => this.hide(), Notifier.PESTER_TIME);
	}

	hide() {
		const removeElement = () => {
			this.isVisible = false;
		};

		this.template.querySelector('.slds-notify').classList.add('slds-transition-hide');
		this.template.querySelector('.slds-notify').classList.remove('slds-transition-show');
		setTimeout(removeElement, Notifier.TRANSITION_TIME);
	}
}
