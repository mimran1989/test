public with sharing class CollaborationRequest {
	public static final String STATUS_ACCEPTED = 'Accepted';
	public static final String STATUS_ASSIGNED = 'Assigned';
	public static final String STATUS_READY_TO_MERGE = 'Ready to Merge';
	public static final String STATUS_MERGED = 'Merged';
	public static final String STATUS_REVOKED = 'Revoked';

	public static final List<String> NOTIFICATION_STATUSES = new List<String>{
		STATUS_READY_TO_MERGE,
		STATUS_ACCEPTED
	};

	public static final List<String> REVOCABLE_STATUSES = new List<String>{
		STATUS_ACCEPTED,
		STATUS_ASSIGNED
	};
}
