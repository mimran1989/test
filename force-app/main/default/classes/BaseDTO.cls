/**
 *  Provus Services Quoting
 *  ManagedDO
 *  @2021 Provus Inc. All rights reserved.
 */
public with sharing virtual class BaseDTO {
	protected Boolean soUpdated = false;

	public static final String OPERATION_TYPE_INSERT = 'insert';
	public static final String OPERATION_TYPE_UPDATE = 'update';
	public static final String OPERATION_TYPE_DELETE = 'delete';

	public String operationType;

	public Boolean isInsert() {
		return operationType == OPERATION_TYPE_INSERT;
	}

	public Boolean isUpdate() {
		return operationType == OPERATION_TYPE_UPDATE;
	}

	public Boolean isDelete() {
		return operationType == OPERATION_TYPE_DELETE;
	}
}
