const PACKAGE_NAMESPACE = 'PSQ';
function getRandomString(length) {
	const randomChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
	let result = '';
	for (let i = 0; i < length; i++) {
		result += randomChars.charAt(Math.floor(Math.random() * randomChars.length));
	}

	return result;
}

function nameQualifier(isDeployedInPackage: boolean) {
	const nsPrefix = isDeployedInPackage ? `${PACKAGE_NAMESPACE}__` : '';
	return function qualifiedName(apiName: string) {
		return `${nsPrefix}${apiName}`;
	};
}

function getRandomNumber(min, max) {
	return Math.random() * (max - min) + min;
}

const Util = {
	getRandomNumber,
	getRandomString,
	namespace: PACKAGE_NAMESPACE,
	nameQualifier,
};

export default Util;
