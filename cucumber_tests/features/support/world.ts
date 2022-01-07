// eslint-disable-next-line max-classes-per-file
import * as Cucumber from '@cucumber/cucumber';
import base64Img from 'base64-img';
import { t } from 'testcafe';
import { Actor } from './actor';
import ActorLookup from './actorLookup';
import ActorParameterType from './actorParameterType';

// Define an {actor} parameter type that creates Actor objects
Cucumber.defineParameterType(ActorParameterType);

export abstract class IWorld extends Cucumber.World {
    tc: typeof t;
    readonly actorLookup: ActorLookup
    abstract get namespacePrefix(): string;
    abstract get isDeployedInPackage(): boolean;
    abstract get browser(): string;
    abstract set testCafeController(value: typeof t);
	abstract attachScreenshotToReport(pathToScreenshot: string): void | Promise<void>;
}
export class World extends IWorld {
	tc: typeof t;
	public readonly actorLookup = new ActorLookup();

	get browser(): string {
		let defaultBrowser: string = this.parameters.browser;
		if (!defaultBrowser) {
			defaultBrowser = 'chrome';
		}

		return defaultBrowser;
	}

	get namespacePrefix() {
		return this.parameters.namespacePrefix ? `${this.parameters.namespacePrefix}__` : '';
	}

	get isDeployedInPackage(): boolean {
		return !!this.namespacePrefix;
	}

	set testCafeController(value: typeof t) {
		this.tc = value;
	}

	attachScreenshotToReport(pathToScreenshot: string): void | Promise<void> {
		const imgInBase64 = base64Img.base64Sync(pathToScreenshot);
		const imageConvertForCuc = imgInBase64.substring(imgInBase64.indexOf(',') + 1);
		return this.attach(imageConvertForCuc, 'image/png');
	}

	findOrCreateActor(actorName: string): Actor {
		return this.actorLookup.findOrCreateActor(this, actorName);
	}
}

Cucumber.setWorldConstructor(World);
