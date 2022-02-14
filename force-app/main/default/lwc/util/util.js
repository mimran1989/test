export function IFrameCallback(fn) {
	return {
		type: 'IFrameCallback',
		functionString: fn.toString(),
	};
}

export function isEmpty(obj) {
	let result = true;
	if (typeof obj !== 'undefined' && obj !== null) {
		if (
			(Array.isArray(obj) && obj.length !== 0)
			|| (typeof obj === 'string' && obj.trim() !== '')
		) {
			result = false;
		}
	}

	return result;
}

export function isNullOrUndefined(object) {
	return typeof object === 'undefined' || object === null;
}

export function get(prop, object) {
	let result = object;
	const propSplit = prop.split('.');
	for (let i = 0; i < prop.length; i++) {
		result = result[propSplit[i]];

		if (!result) {
			break;
		}
	}

	return result;
}

export function put(prop, object, value) {
	let contextObject = object;
	const propSplit = prop.split('.');
	for (let i = 0; i < prop.length - 1; i++) {
		if (!contextObject[propSplit[i]]) {
			contextObject[propSplit[i]] = {};
		}

		contextObject = contextObject[propSplit[i]];
	}

	contextObject[propSplit[propSplit.length - 1]] = value;
}

export function refreshView() {
	// eslint-disable-next-line no-eval
	eval("$A.get('e.force:refreshView').fire();");
}

export function componentNamespace(cmp) {
	const namespaceObjString = cmp.template.host.toString().match(/{"namespace":.*?}/);
	return namespaceObjString && JSON.parse(namespaceObjString[0]).namespace;
}

const formatLabel = (stringToFormat, stringArguments) => {
	if (typeof stringToFormat !== 'string') {
		throw new Error('input label must be a String');
	}

	return stringToFormat.replace(/{(\d+)}/gm, (match, index) => (stringArguments[index] === undefined ? '' : `${stringArguments[index]}`));
};

export { formatLabel };
