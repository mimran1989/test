import { t } from 'testcafe';
import { Actor } from '../support/actor';
import { WebComponentSelector } from '../support/componentSelector';

export const Assert = (selector: Selector | WebComponentSelector, message?: string, timeout?: number) => ({
	doesNotExist: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).exists).notOk(message, { timeout }),
	exists: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).exists).ok(message, { timeout }),
	isVisible: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).visible).ok(message, { timeout }),
	isNotVisible: async(actor: Actor) => actor.world.tc.expect(selector.with({ boundTestRun: actor.world.tc }).visible).notOk(message, { timeout }),
	isDisabled: async(actor: Actor) => {
		const selectedElement = await selector.with({ boundTestRun: actor.world.tc }).attributes;
		return actor.world.tc.expect(selectedElement.disabled).ok(message, { timeout });
	},
	isNotDisabled: async(actor: Actor) => {
		const selectedElement = await selector.with({ boundTestRun: actor.world.tc }).attributes;
		return actor.world.tc.expect(selectedElement.disabled).notOk(message, { timeout });
	},
});

const Ensure = {
	that: t.expect,
	the: (selector: Selector | WebComponentSelector, message?: string) => Assert(selector, message),
};

export default Ensure;
