/* eslint-disable import/no-extraneous-dependencies */
const fs = require('fs-extra');
const yargs = require('yargs');
const util = require('util');
const exec = util.promisify(require('child_process').exec);

const { argv } = yargs
	.option('type', {
		alias: 't',
		description: 'semvar release type',
		type: 'string',
	})
	.option('nextVersion', {
		alias: 'v',
		description: 'next release version',
		type: 'string',
	})
	.option('channel', {
		alias: 'c',
		description: 'release channel',
		type: 'string',
	})
	.help()
	.alias('help', 'h');

releaseNewVersion();

async function releaseNewVersion() {
	const { type, nextVersion, channel } = argv;
	const projectDetails = JSON.parse(fs.readFileSync('../sfdx-project.json', 'utf8'));
	const { versionNumber } = projectDetails.packageDirectories[0];
	const calculatedNextVersion = calculateNextVersion(type, versionNumber);
	let requestedReleaseVersion = nextVersion;
	if (channel === 'next') {
		requestedReleaseVersion = calculatedNextVersion;
	}

	if (calculatedNextVersion !== requestedReleaseVersion) {
		console.warn('The calculated next version does not match the semantic version');
		console.warn('Calculated: ', calculatedNextVersion, ' semantic-next: ', requestedReleaseVersion);
		throw new Error(
			`The calculated next version does not match the semantic version.
			Calculated: : ${calculatedNextVersion}, semantic-next: ${requestedReleaseVersion}`,
		);
	}

	projectDetails.packageDirectories[0].ancestorVersion = getAncestorVersion(versionNumber);
	projectDetails.packageDirectories[0].versionNumber = `${requestedReleaseVersion}.NEXT`;
	fs.writeFileSync('../sfdx-project.json', JSON.stringify(projectDetails, null, 4));

	// write sfdx package
	try {
		await generateAndPromoteNewVersion();
	} catch (exception) {
		if (exception.stderr) {
			console.error(exception.stderr);
		} else {
			console.error(exception);
		}

		process.exit(1);
	}
}

function calculateNextVersion(type, currentVersion) {
	const [major, minor, patch] = currentVersion.split('.');
	let calculatedNextVersion;
	if (type === 'minor') {
		calculatedNextVersion = `${major}.${parseInt(minor, 10) + 1}.0`;
	} else if (type === 'patch') {
		calculatedNextVersion = `${major}.${minor}.${parseInt(patch, 10) + 1}`;
	} else {
		throw new Error('Updating the major release requires manual approval.');
	}

	return calculatedNextVersion;
}

function getAncestorVersion(currentVersion) {
	const [major, minor] = currentVersion.split('.');
	return `${major}.${minor}.0`;
}

async function generateAndPromoteNewVersion() {
	try {
		await exec('npx sfdx force:auth:sfdxurl:store -f token.txt -d -a package-hub --json');

		console.log('Generating new package version...');

		await exec('cd ..;npx sfdx force:package:version:create -p "Provus Services Quoting" -k installprovus -v package-hub -c -w 60 ');

		console.log('Promoting new package version...');
		await exec('cd ..; latestVersion=$(npx sfdx force:package:version:list -v package-hub -p \'Provus Services Quoting\' -o '
			+ 'CreatedDate --concise | tail -1 | awk \'{print $3}\'); npx sfdx force:package:version:promote -p $latestVersion -n -v package-hub --json');
	} catch (e) {
		console.warn(e.stdout);
		console.warn(e.stderr);
		process.exit(1);
	}
}
