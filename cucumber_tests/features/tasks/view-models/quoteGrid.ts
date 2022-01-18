import { WebComponent } from '../../support/componentSelector';

const COMPONENT = WebComponent('one-record-home-flexipage2')
	.child(0)
	.shadowRoot()
	.child(0)
	.shadowRoot()
	.findComponent('quote-configurator');

const QuoteGrid = {
	component: COMPONENT,
};

export default QuoteGrid;
