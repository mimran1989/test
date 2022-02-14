import RecordHomePage from './recordHomePage';

abstract class QuoteGrid extends RecordHomePage {
	static component = RecordHomePage.CONTAINER.child(0)
		.shadowRoot()
		.child(0)
		.shadowRoot()
		.findComponent('quote-configurator');
}

export default QuoteGrid;
