/* eslint-disable import/no-extraneous-dependencies */
const fs = require('fs-extra');
const sfdx = require('sfdx-node');
const yargs = require('yargs');
const jsforce = require('jsforce');
const util = require('util');
const exec = util.promisify(require('child_process').exec);

// eslint-disable-next-line padding-line-between-statements
const DEFAULT_PERMISSION_SETS = JSON.parse(fs.readFileSync('../sfdx-project.json', 'utf8'))
	.packageDirectories[0]
	.apexTestAccess
	.permissionSets;

const { argv } = yargs
	.option('devhubtoken', {
		alias: 'u',
		description: 'Path to the dev hubs access token',
		type: 'string',
	})
	.help()
	.alias('help', 'h');

//	deployMetadataForTest();
createAndPrepareOrgForFunctionalTests();

async function createAndPrepareOrgForFunctionalTests() {
	await exec(`npx sfdx force:auth:sfdxurl:store -f ${argv.devhubtoken} -d -a dev-hub`);

	console.log('Creating test org...');
	await createTestOrg();

	try {
		console.log('Deploying metadata to test org...');
		await deployMetadataForTest();

		console.log('Granting user access to test org...');
		const accessKey = await grantUserAccessForTest();

		// add this user to the keychain (including default permissions)
		fs.writeFileSync('../tests/keys.json', JSON.stringify([accessKey], null, 4));

		console.log('Executing functional tests...');
		await exec('npm --prefix ../ run test:functional:managed:live');
	} catch (exception) {
		if (exception.stdout) {
			console.error(exception.stdout);
		}

		if (exception.stderr) {
			console.error(exception.stderr);
		} else {
			console.error(exception);
		}

		console.log('Deleting test-org...');
		await exec('npx sfdx force:org:delete -u test-org -v dev-hub -p');
		process.exit(1);
	}

	console.log('Deleting test-org...');
	await exec('npx sfdx force:org:delete -u test-org -v dev-hub -p');
}

async function createTestOrg() {
	return exec('npx sfdx force:org:create -f ../config/project-scratch-def.json -a test-org -v dev-hub adminEmail=me@provusinc.com');
}

async function deployMetadataForTest() {
	// Whitelist all IP addresses to disable multi factor authentication during test execution
	await fs.copy('./forceIpAllowedList', '../force-app/main/default/settings');
	return exec('npx sfdx force:source:deploy -p ../force-app -u test-org');
}

async function grantUserAccessForTest() {
	await sfdx.force.user.passwordGenerate({
		targetusername: 'test-org',
		targetdevhubusername: 'dev-hub',
		json: true,
	});

	const { instanceUrl, username, password } = await sfdx.force.org.display({
		targetusername: 'test-org',
	});

	setDefaultMobileNumberForUser(instanceUrl, username, password);

	const userAccessInfo = {
		loginUrl: instanceUrl,
		username,
		password,
		permissionSets: DEFAULT_PERMISSION_SETS, // copy default permissions from the sfdx-project.json build file
		role: 'admin',
	};

	return userAccessInfo;
}

async function setDefaultMobileNumberForUser(instanceUrl, username, password) {
	const connection = new jsforce.Connection({
		loginUrl: instanceUrl,
	});

	await connection.login(username, password);
	const users = await connection.query(`SELECT Id, MobilePhone FROM User WHERE Username = '${username}'`);
	for (let i = 0; i < users.records.length; i++) {
		const user = users.records[i];
		user.MobilePhone = '+1 9165551212';
	}

	await connection.sobject('User').update(users.records);
}
