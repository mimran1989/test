import Ability from './ability';
import { World } from './world';

export type Action<Answer = void, World = unknown> = (actor: Actor, previousValue?: Answer) => Answer;
export type PromiseAction<Answer = void, World = unknown> = (actor: Actor, previousValue?: Answer) => Promise<Answer>;
export type DefaultFunction<T> = () => T;

export class Actor {
	readonly world: World;
	readonly name: string;
	private readonly memory;

	constructor(world: World, name: string) {
		this.world = world;
		this.name = name;
		this.memory = new Map();
	}

	remember<T>(key: string, value: T) {
		this.memory.set(key, value);
	}

	recall<T>(key: string, defaultFunction?: DefaultFunction<T>): T {
		if (!this.memory.has(key) && defaultFunction) {
			this.memory.set(key, defaultFunction());
		}

		return this.memory.get(key);
	}

	async attemptsTo<Answer>(...activities: PromiseAction<Answer, World>[]): Promise<Answer> {
		const reducer = (chain: Promise<Answer>, activity: PromiseAction<Answer, World>):
			Promise<Answer> => chain.then((previousValue: Answer): Promise<Answer> => activity(this, previousValue));

		return activities.reduce(reducer, Promise.resolve(null as unknown as Answer));
	}

	whoCan(ability: Ability) {
		this.remember(ability.type, ability);
	}

	hasAbility(ability: Ability) {
		return !!this.getAbility(ability);
	}

	getAbility(ability: Ability): Ability {
		return this.recall(ability.type);
	}

	revokeAbility(ability: Ability) {
		this.memory.set(ability.type, null);
	}

	asks<Answer>(action: Action<Answer, World>): Answer {
		return action(this);
	}
}
