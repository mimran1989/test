import { Actor } from '../support/actor';
import { WebComponentSelector } from '../support/componentSelector';
import Click from './interactions/click';

const Select = {
	item: (itemSelector: string | Selector | WebComponentSelector) => ({
		inComboBox: (comboBoxSelector: string | Selector | WebComponentSelector) => (actor: Actor) => actor.attemptsTo(
			Click.on(comboBoxSelector),
			Click.on(itemSelector),
		),
	}),
};

export default Select;
