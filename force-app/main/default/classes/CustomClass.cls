/**
 *  Provus Services Quoting
 *  @2021 Provus Inc. All rights reserved.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing abstract class CustomClass {
	global with sharing class ActionCallbackRequest {
		/**
		 * context sobject to work with in a callback
		 */
		global SObject contextObject;

		global ActionCallbackRequest(SObject contextObject) {
			this.contextObject = contextObject;
		}
	}

	global interface Errors {
		List<String> getErrorMessages();
	}

	global with sharing class ActionCallbackResponse {
		/**
		 * If the action succeeded
		 */
		global Boolean isSuccess;

		/**
		 * Contains and handles error messaging
		 */
		global Errors error;
	}

	global interface SObjectCallback {
		/**
		 * Callback when we are creating a new sobject record
		 */
		ActionCallbackResponse onCreate(ActionCallbackRequest request);

		/**
		 * Callback when we are updating an existing sobject record
		 */
		ActionCallbackResponse onUpdate(ActionCallbackRequest request);

		/**
		 * Callback when we are deleting an existing sobject record
		 */
		ActionCallbackResponse onDelete(ActionCallbackRequest request);
	}

	global interface ProposalCallback extends SObjectCallback {
		/**
		 * Callback to handle quote creation for a proposal
		 */
		ActionCallbackResponse createQuotes(ActionCallbackRequest request);
	}
}
