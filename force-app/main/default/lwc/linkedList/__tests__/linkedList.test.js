/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */
import LinkedList from 'c/linkedList';

describe('linkedList', () => {
	let linkedList;

	beforeEach(() => {
		linkedList = new LinkedList();
	});

	describe('add', () => {
		it('should not add an empty element', () => {
			linkedList.add();
			expect(linkedList.size).toBe(0);
			expect(linkedList.toArray()).toEqual([]);
		});
		it('should add an element', () => {
			linkedList.add(1);
			expect(linkedList.size).toEqual(1);
			expect(linkedList.toArray()).toEqual([1]);
		});
		it('should add multiple elements', () => {
			linkedList.add(1);
			linkedList.add(2);
			linkedList.add(3);
			expect(linkedList.size).toEqual(3);
			expect(linkedList.toArray()).toEqual([1, 2, 3]);
		});
	});

	describe('addAll', () => {
		it('should add all elements from the passed array', () => {
			linkedList.addAll([1, 2, 3, 4]);
			expect(linkedList.size).toBe(4);
			expect(linkedList.toArray()).toEqual([1, 2, 3, 4]);
		});
	});

	describe('insert', () => {
		it('should return false when the list is empty', () => {
			expect(linkedList.insert(0, 1)).toBe(false);
		});
		it('should return false when the index is invalid', () => {
			linkedList.addAll([1, 2, 4, 5]);
			expect(linkedList.insert(-1, 1)).toBe(false);
			expect(linkedList.insert(5, 1)).toBe(false);
		});
		it('should insert the element at the index', () => {
			linkedList.addAll([1, 2, 4, 5]);
			linkedList.insert(2, 3);
			expect(linkedList.toArray()).toEqual([1, 2, 3, 4, 5]);
		});
		it('should insert at the front of the list', () => {
			linkedList.addAll([2, 3]);
			linkedList.insert(0, 1);
			expect(linkedList.toArray()).toEqual([1, 2, 3]);
		});
	});

	describe('remove', () => {
		it('should do nothing when the list is empty', () => {
			linkedList.remove();
			expect(linkedList.size).toBe(0);
			expect(linkedList.toArray()).toEqual([]);
		});
		it('should return undefined, when the element is not found', () => {
			linkedList.addAll([1, 2, 3]);
			expect(linkedList.remove(4)).toEqual(undefined);
		});
		it('should remove from a list with one element', () => {
			linkedList.add(1);
			linkedList.remove(1);
			expect(linkedList.size).toEqual(0);
			expect(linkedList.toArray()).toEqual([]);
		});
		it('should remove from a list with multiple elements', () => {
			linkedList.addAll([1, 2, 3]);
			linkedList.remove(2);
			expect(linkedList.size).toEqual(2);
			expect(linkedList.toArray()).toEqual([1, 3]);
		});
		it('should remove from the front of the list', () => {
			linkedList.addAll([1, 2, 3]);
			linkedList.remove(1);
			expect(linkedList.size).toEqual(2);
			expect(linkedList.toArray()).toEqual([2, 3]);
		});
		it('should remove from the back of the list', () => {
			linkedList.addAll([1, 2, 3]);
			linkedList.remove(3);
			expect(linkedList.size).toEqual(2);
			expect(linkedList.toArray()).toEqual([1, 2]);
		});
	});

	describe('first', () => {
		it('should return undefined when the list is empty', () => {
			expect(linkedList.first()).toEqual();
		});
		it('should return the first element', () => {
			linkedList.addAll([1, 2, 3]);
			expect(linkedList.first()).toEqual(1);
		});
	});

	describe('last', () => {
		it('should return undefined when the list is empty', () => {
			expect(linkedList.last()).toEqual();
		});
		it('should return the last element', () => {
			linkedList.addAll([1, 2, 3]);
			expect(linkedList.last()).toEqual(3);
		});
	});
});
