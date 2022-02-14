/**
 * Deploy Test data from CSV.
 */
const _ = require('lodash');
const csv = require('csv-parser');
const fs = require('fs');
const promise = require('promise');
const sf = require('node-salesforce');

const loginUrl = 'https://login.salesforce.com/';
const username = '';
const password = '';

const dataFolder = '/Users/aozomaro/Documents/Provus/Deploy Data to SFDC/PSQ';

const csvFilesForSObjects = {};
const insertedRecords = {};
const isSelfReferencing = {};
const insertOrder = [];
const sfdcConnector = new sf.Connection({ loginUrl });
const sObjectDescribeDetails = {};

// insert the csv files
insertCSVs(dataFolder);

function createNewRecords({ sobjectName, records }) {
	console.log(`Inserting new records for sObject: ${sobjectName}`);

	const recordsToInsert = [];
	const recordMOs = [];
	const selfReferingColumns = {};
	const fieldMetdata = {};

	let externalIDColumn;
	_.forEach(sObjectDescribeDetails[sobjectName].fields, (fieldData) => {
		fieldMetdata[fieldData.name.toLowerCase()] = fieldData;
	});

	_.forEach(records, (record) => {
		const newSObjectToInsert = {};
		_.forOwn(_.keys(record), (columnName) => {
			const columnNameLower = columnName.toLowerCase();
			const fieldData = fieldMetdata[columnNameLower];
			if (columnNameLower === 'id') {
				externalIDColumn = columnName;
			} else {
				if (typeof fieldData === 'undefined') { // TODO: create an error report
					return true;
				}

				let rowData = record[columnName];
				if (fieldData.updateable || ((fieldData.createable && !fieldData.nillable) && fieldData.type === 'reference')) {
					if (fieldData.type === 'boolean') {
						if (!rowData) {
							rowData = null;
						} else if (rowData.toLowerCase() === 'false'
							|| rowData === '0'
							|| rowData === 0) {
							rowData = false;
						} else {
							rowData = true;
						}
					} else if (fieldData.type === 'reference') {
						if (fieldData.referenceTo[0] === sobjectName) {
							selfReferingColumns[columnName] = true;
							return true;
						}
						const parentSObject = insertedRecords[rowData];
						if (parentSObject) {
							rowData = parentSObject.contextRecord.Id;							
						} else {							
							rowData = null;
						}
					} else if (fieldData.type === 'currency'
						|| fieldData.type === 'double'
						|| fieldData.type === 'integer'
						|| fieldData.type === 'percent') {
						if (!rowData) {
							return true;
						}

						rowData = parseFloat(rowData);
					} else if (fieldData.type === 'date'
						|| fieldData.type === 'datetime') {
						if (!rowData) {
							return true;
						}
					}

					if (rowData !== null) {
						newSObjectToInsert[fieldData.name] = rowData;

					}
				}
			}

			return undefined;
		});

		const newXRefMO = {};
		if (typeof externalIDColumn !== 'undefined') {
			const externalID = record[externalIDColumn];

			newXRefMO.externalID = externalID;
			insertedRecords[newXRefMO.externalID] = newXRefMO;
		} else {
			console.log(`Unable to locate the external id column for sObject: ${sobjectName}`);
		}

		newXRefMO.contextRecord = newSObjectToInsert;
		recordsToInsert.push(newSObjectToInsert);
		recordMOs.push(newXRefMO);
	});

	return new Promise((resolve) => {		
		const insertPromises = [];
		const updatePromises = [];
		let insertBatchNumber = 0;		
		while (insertBatchNumber < recordsToInsert.length) {
			const insertingNow = [];
			const insertingMOs = [];

			for (let i = 0; i < 10000
						&& (insertBatchNumber + i) < recordsToInsert.length; i++) {
				insertingMOs.push(recordMOs[insertBatchNumber + i]);
				insertingNow.push(recordsToInsert[insertBatchNumber + i]);
			}

			insertPromises.push(insertRecords({ sobjectName, recordMOs: insertingMOs, recordsToInsert: insertingNow }));
			insertBatchNumber +=insertingMOs.length;
		}

		Promise.all(insertPromises).then(() => {
			console.log(`Created ${records.length} records.`);
			const recordsToUpdate = [];
			if (_.keys(selfReferingColumns).length > 0) {
				_.forEach(records, (record) => {					
					const externalID = record[externalIDColumn];
					const objectToUpdate = insertedRecords[externalID];
					const recordToUpdate = {Id: objectToUpdate.contextRecord.Id };
					_.forOwn(_.keys(selfReferingColumns), (columnName) => {
						const fieldData = fieldMetdata[columnName.toLowerCase()];
						const parentExternalID = record[columnName];
						const parentSObject = insertedRecords[parentExternalID];
						// console.log('looking for parent object by id: ' + parentExternalID);
						// console.log('looking for parent object for field: ' + columnName);
						if (parentSObject) {
							// console.log('found parent');
							// console.log(parentSObject);
							recordToUpdate[fieldData.name] = parentSObject.contextRecord.Id;
						} else {
							recordToUpdate[fieldData.name] = null;
						}
					});

					recordsToUpdate.push(recordToUpdate);
				});
			}

			if (recordsToUpdate.length > 0) {
				console.log(`Queueing update for self-referncing sObject: ${sobjectName}`);				
				let updateBatchNumber = 0;	
				while (updateBatchNumber < recordsToUpdate.length) {				
					const recordsForBatch = [];
					for (let i = 0; i < 10000
						&& (updateBatchNumber + i) < recordsToUpdate.length; i++) {					
						recordsForBatch.push(recordsToUpdate[updateBatchNumber + i]);
					console.log(recordsForBatch);
					}

					updatePromises.push(updateRecords({ sobjectName, recordsToUpdate: recordsForBatch }));
					updateBatchNumber +=recordsForBatch.length;
				}

				Promise.all(updatePromises).then(resolve);
			} else {
				resolve();
			}
		});
	});
}

function describeContextSObjects(sObjectNames) {
	const describeObjectsPromise = [];
	_.forEach(sObjectNames, (sObjectName) => {
		describeObjectsPromise.push(describeSObject(sObjectName));
	});

	return Promise.all(describeObjectsPromise);
}

function describeSObject(sObjectName) {
	console.log(`Fetching sObject metdata for sObject: ${sObjectName}`);
	return new Promise((resolve, reject) => {
		sfdcConnector.sobject(sObjectName).describe$((error, metadata) => {
			if (error) {
				console.log(`Error fecthing metadata for sObject: ${sObjectName}`);
				console.log(error);
				reject(error);
			} else {
				sObjectDescribeDetails[metadata.name] = metadata;
				resolve();
			}
		});
	});
}

function getContextObjects() {
	console.log('Searching data directory for CSVs to import.');
	return new Promise((resolve) => {
		fs.readdir(dataFolder, (err, files) => {
			_.forEach(files, (file) => {
				const sObjectName = file.substr(0, file.indexOf('.csv'));
				if (sObjectName) {
					csvFilesForSObjects[sObjectName] = file;
				}
			});
			resolve(_.keys(csvFilesForSObjects));
		});
	});
}

async function insertCSVs(csvDirectory) {
	console.log('*****')
	console.log(insertOrder);
	
	await login().then(getContextObjects)
				 .then(describeContextSObjects)
				 .then(sortSObjectsByDependency);
	
	const readCSVPromises = [];				 
	_.forEach(insertOrder, (sobjectName) => {
		const csvFileName = `${csvDirectory}/${sobjectName}.csv`;
		readCSVPromises.push(loadCSVRows({ sobjectName, csvFileName }));
	});

	return Promise.all(readCSVPromises).then((sObjectDetails) => {
		let insertPromises = new Promise((resolve) => { resolve(); });
		_.forEach(sObjectDetails, (sObjectData) => {
			const { sobjectName, records } = sObjectData;
			insertPromises = insertPromises.then(() => createNewRecords({ sobjectName, records }));
		});

		return insertPromises;
	});
}

function insertRecords({ sobjectName, recordMOs, recordsToInsert }) {
	return new Promise((resolve) => {
		const insertJob = sfdcConnector.bulk.createJob(sobjectName, 'insert');
		const insertBatchJob = insertJob.createBatch();
		insertBatchJob.execute(recordsToInsert);
		insertBatchJob.on('queue', function(batchInfo) {
			const batchId = batchInfo.id;
			const { jobId } = batchInfo;
			const job = sfdcConnector.bulk.job(jobId);
			const pendingJob = job.batch(batchId);

			console.log(`Queued: BatchId=${batchId} JobId=${jobId}`);

			pendingJob.poll(30000); // poll for 60 seconds
			pendingJob.on('response',
				function(rets) {
					console.log('Queue repsonse... sObject: ' + sobjectName + ' Size:' + rets.length);
					for (let i = 0; i < rets.length; i++) {						
						if (rets[i].success) {
							recordMOs[i].contextRecord.Id = rets[i].id;
						} else {
							console.log(`Import failed for sObject: ${sobjectName}`);
							console.log('Failed record:');
							console.log(recordMOs[i].contextRecord);
							console.log('Repsonse:');
							console.log(rets[i]);
						}
					}

					resolve();
				});
		});
	});
}

function loadCSVRows({ sobjectName, csvFileName }) {
	return new Promise((resolve) => {
		const records = [];
		console.log(`Reading CSV file for sObject: ${sobjectName}`);
		fs.createReadStream(csvFileName)
			.pipe(csv())
			.on('data', (row) => {
				records.push(row);
			})
			.on('end', () => {
				console.log('Done...');
				resolve({ records, sobjectName });
			});
	});
}

function login() {
	console.log('Logging into target org.');
	return sfdcConnector.login(username, password, function(err, userInfo) {
		if (err) { return console.error(err); }

		const { accessToken, instanceUrl } = userInfo;
		sfdcConnector.serverUrl = instanceUrl;
		sfdcConnector.sessionId = accessToken;
		return undefined;
	});
}

function isIndirectlyDependent(contextSObjectName, referenceSObjectName, dependsOn, mainCtx) {
	let result = false;
	if (!dependsOn[contextSObjectName]) {
		return result;
	}

	const deps = Object.keys(dependsOn[contextSObjectName]);
	for (let i = 0; i < deps.length; i++) {
		const dep = deps[i];
		if (dep === (mainCtx || referenceSObjectName)) {
			result = true;
			break;
		} else {
			result = isIndirectlyDependent(referenceSObjectName, null, dependsOn, mainCtx || referenceSObjectName);
		}

		if (result) {
			break;
		}
	}
	return result;
}

function sortSObjectsByDependency() {	
	const sObjectsForImport = _.keys(csvFilesForSObjects);
	const dependsOn = {};
	let failSafe = 0;
	let dependencies = [];


	while (sObjectsForImport.length !== 0 && failSafe < 500) {
		failSafe += 1;// failsafe
		let hasLookup = false;
		const [contextSObjectName] = sObjectsForImport.splice(0, 1);
		console.log(contextSObjectName)
		const contextSOFields = sObjectDescribeDetails[contextSObjectName].fields;
		const fieldLength = contextSOFields.length;
		for (let i = 0; i < fieldLength; i++) {
			const fieldInfo = contextSOFields[i];

			if (fieldInfo.type === 'reference') {
				const referenceSObject = sObjectDescribeDetails[fieldInfo.referenceTo[0]];
				const referenceSObjectName = referenceSObject && referenceSObject.name;
				if (!referenceSObjectName) {
					continue;
				}

				if (typeof referenceSObjectName !== 'undefined'
					&& insertOrder.indexOf(referenceSObjectName) < 0
					&& referenceSObjectName !== contextSObjectName) {
					const isCircularReference = dependsOn[referenceSObjectName]
						&& dependsOn[referenceSObjectName][contextSObjectName];
					const isIndirectCircularReference = isIndirectlyDependent(contextSObjectName, referenceSObjectName, dependsOn);					
					if (!isCircularReference && !isIndirectCircularReference) {
						hasLookup = true;
						let contextDependsOn = dependsOn[contextSObjectName];
						if (!contextDependsOn) {
							contextDependsOn = {};
							dependsOn[contextSObjectName] = contextDependsOn;					
						}
						contextDependsOn[referenceSObjectName] = true;
						
						dependencies.push(`For sObject: ${contextSObjectName} .. Depends on: ${referenceSObjectName}`);				
						break;
					}
				} else if (referenceSObjectName === contextSObjectName) {
					isSelfReferencing[referenceSObjectName] = true;
				}
			}
		}

		if (hasLookup) {
			sObjectsForImport.push(contextSObjectName);			
		} else {
			insertOrder.push(contextSObjectName);
		}

		if (failSafe === 500) {
			let unableToSortSObjectNames = '';
			_.forEach(sObjectsForImport, (sObjectName) => {
				unableToSortSObjectNames += `${sObjectName}\n`;
			});

			console.log(dependencies);
			throw new Error(`Unable to resolve sObject references:\n${unableToSortSObjectNames}`);
		}

	}
}

function updateRecords({ sobjectName, recordsToUpdate }) {
	return new Promise((resolve) => {
		const updateJob = sfdcConnector.bulk.createJob(sobjectName, 'update');
		const updateBatchJob = updateJob.createBatch();
		updateBatchJob.execute(recordsToUpdate);
		updateBatchJob.on('queue', function(batchInfo) {
			const batchId = batchInfo.id;
			const { jobId } = batchInfo;

			console.log(`Queued: BatchId=${batchId} JobId=${jobId}`);
			const job = sfdcConnector.bulk.job(jobId);
			const pendingJob = job.batch(batchId);
			pendingJob.poll(30000); // poll for 60 seconds
			pendingJob.on('response', () => resolve());
		});
	});
}