/**
 *  Provus Services Quoting
 *  ManagedObject
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing virtual class ManagedObject {
	public static final String OPERATION_TYPE_DELETE = 'delete';

	// managed sobject
	protected transient SObject pSObject = null;
	private static String nsPrefix;

	static {
		// set nsPrefix once per initializtion
		nsPrefix = SystemUtility.getNamespacePrefix();
	}

	public ManagedObject(BaseDTO baseDto) {
		this.baseDTO = baseDto;
	}

	public ManagedObject(SObject theSObject) {
		this.pSObject = theSObject;
	}

	public SObject getSObject() {
		return this.pSObject;
	}

	public String getNS() {
		return nsPrefix;
	}

	public Boolean isDelete() {
		return baseDTO.operationType == OPERATION_TYPE_DELETE;
	}

	public transient BaseDTO baseDTO { get; protected set; }
}
