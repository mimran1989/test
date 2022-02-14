import { WebComponent, WebComponentSelector } from '../../support/componentSelector';

const CONTAINER = WebComponent('one-record-home-flexipage2', -1);
abstract class RecordHomePage {
	static CONTAINER = CONTAINER;
	highlightsPanelActionButton = (buttonApiName: string): WebComponentSelector => CONTAINER
		.child(0)
		.shadowRoot()
		.child(0)
		.shadowRoot()
		.findWebComponent('records-lwc-highlights-panel')
		.findWebComponent('records-lwc-record-layout')
		.child(0)
		.shadowRoot()
		.child(0) // force-highlights2
		.shadowRoot()
		.findWebComponent('runtime_platform_actions-actions-ribbon')
		.find('runtime_platform_actions-action-renderer')
		.filter((node) => node.getAttribute('apiname')?.toLowerCase() === buttonApiName.toLowerCase(), { buttonApiName })
		.shadowRoot()
		.findWebComponent('lightning-button')
		.child('button');
}

export default RecordHomePage;
