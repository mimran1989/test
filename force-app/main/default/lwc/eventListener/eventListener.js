/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import { LightningElement, api } from 'lwc';
import log from 'c/log';
import {
	subscribe, unsubscribe, onError,
} from 'lightning/empApi';

const subscriptions = {};
const handlersByChannel = new Map();
export default class Notifier extends LightningElement {
	@api
	get handler() {
		return this._handler;
	}
	set handler(value) {
		if (this._handler === undefined && this.channel !== undefined) {
			this._handler = value;
			this.registerListener();
		} else if (this.channel === undefined) {
			this._handler = value;
		}
	}

	@api
	get channel() {
		return this._channel;
	}
	set channel(value) {
		if (this._channel !== value) {
			if (this._channel) {
				this.deregisterListener();
			}

			this._channel = value;

			if (value && this.handler) {
				this.registerListener();
			}
		}
	}

	connectedCallback() {
		this.registerErrorListener();
	}

	disconnectedCallback() {
		this.deregisterListener();
	}

	async registerListener() {
		const channelURI = `/event/${this.channel}`;
		let handlersForChannel = handlersByChannel.get(this.channel);
		if (!handlersForChannel) {
			handlersForChannel = [];
			handlersByChannel.set(this.channel, handlersForChannel);

			const callback = (() => (eventResponse) => {
				handlersForChannel.forEach((nextHandler) => nextHandler(eventResponse));
			})();

			const response = await subscribe(channelURI, -1, callback);
			// Response contains the subscription information on subscribe call
			log('Subscription request sent to: ', JSON.stringify(channelURI));
			subscriptions[this.channel] = response;
		}

		handlersForChannel.push(this.handler);
	}

	deregisterListener() {
		const handlersForChannel = handlersByChannel.get(this.channel) || [];
		const messageIndex = handlersForChannel.indexOf(this.handler);
		if (messageIndex >= 0) {
			handlersForChannel.splice(messageIndex, 1);
		}

		if (handlersForChannel.length === 0) {
			const subscription = subscriptions[this.channel];
			if (subscription) {
				unsubscribe(subscription, (response) => {
					log('unsubscribe() response: ', JSON.stringify(response));
				});
			}
		}
	}

	registerErrorListener() {
		onError((error) => {
			log('Received error from server: ', JSON.stringify(error));
		});

		return this;
	}
}
