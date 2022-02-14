import {
	AsyncPriorityQueue, AsyncResultCallback, priorityQueue, queue, QueueObject,
} from 'async';

const CONCURRENCY_LIMIT = 1;
const Deferred = require('deferred');

declare const window: any;

type ActionFn = {
	actionName: string;
	priority: number;
	queue: QueueObject<string>;
	fn: Function;
};

class Queue {
	q: AsyncPriorityQueue<string>;
	registeredActions: Record<string, ActionFn> = {};

	constructor() {
		this.q = priorityQueue(
			(actionName: string, callback: AsyncResultCallback<any, Error>) => this.invokeAction(actionName, callback),
			CONCURRENCY_LIMIT,
		);
	}

	invokeAction(actionName: string, callback: AsyncResultCallback<any, Error>) {
		const { queue: actionQueue } = this.registeredActions[actionName];
		if (actionQueue) {
			actionQueue.push(actionName, callback);
		}
	}

	registerAction({ actionName, priority, fn }: ActionFn) {
		this.registeredActions[actionName] = {
			actionName,
			priority,
			queue: queue(async() => fn()),
			fn,
		};
	}

	registerActions(actionsToRegister: ActionFn[]) {
		actionsToRegister.forEach((action) => this.registerAction(action));
	}

	async scheduleAction(actions: string[] | string) {
		let actionsToSchedule = actions;
		if (!Array.isArray(actionsToSchedule)) {
			actionsToSchedule = [actionsToSchedule];
		}

		const allActionPromises = [];
		for (let i = 0; i < actionsToSchedule.length; i++) {
			const actionName = actionsToSchedule[i];
			const { priority } = this.registeredActions[actionName];
			const deferred = new Deferred();
			allActionPromises.push(deferred.promise);

			this.q.push(actionName, priority, (error) => {
				if (error) {
					deferred.reject(error);
				} else {
					deferred.resolve();
				}
			});
		}

		return Promise.all(allActionPromises);
	}
}

if (!window.Provus) {
	window.Provus = {};
}

window.Provus.Queue = Queue;
