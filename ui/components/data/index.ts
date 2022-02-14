import { QuoteItem, QuoteItems } from './quoteItem';
import { NamedRange, NamedRanges } from './namedRange';
import { Section, Sections } from './section';
import { Phase, Phases } from './phase';

declare const window: any;

if (!window.Provus) {
	window.Provus = {};
}

window.Provus = {
	...window.Provus,
	NamedRange,
	NamedRanges,
	Phase,
	Phases,
	QuoteItem,
	QuoteItems,
	Section,
	Sections,
};
