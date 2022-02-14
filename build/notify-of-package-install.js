/* eslint-disable import/no-extraneous-dependencies */
const yargs = require('yargs');
const { WebClient } = require('@slack/web-api');

const { argv } = yargs
	.option('latestVersionNumber', {
		alias: 'v',
		description: 'Notification message',
		type: 'string',
	})
	.option('channel', {
		alias: 'c',
		description: 'Channel',
		type: 'string',
	})
	.option('notes', {
		alias: 'n',
		description: 'Release Notes',
		type: 'string',
	})
	.help()
	.alias('help', 'h');

const { channel, latestVersionNumber, notes } = argv;
const slackToken = process.env.SLACK_BOT_TOKEN;
const message = `A new version of \`Provus Services Quoting\` has been released!\nCurrent version is *v${latestVersionNumber}*.`;

const messagePayload = {
	channel,
	text: message,
	blocks: [
		{
			type: 'section',
			text: {
				type: 'mrkdwn',
				text: message,
			},
		},
		{
			type: 'divider',
		},
		{
			type: 'header',
			text: {
				type: 'plain_text',
				text: "What's in this release?",
				emoji: true,
			},
		},
		{
			type: 'section',
			text: {
				type: 'mrkdwn',
				text: notes,
			},
		},
	],
};

const slackWebClient = new WebClient(slackToken);
slackWebClient.chat.postMessage(messagePayload);
