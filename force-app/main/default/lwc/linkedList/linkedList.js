/*
 * Provus Services Quoting
 * Copyright (c) 2021 Provus Inc. All rights reserved.
 */

/* eslint-disable max-classes-per-file */

class Node {
	data;
	prev;
	next;

	constructor(data, prev, next) {
		this.data = data;
		this.prev = prev;
		this.next = next;
	}
}

export default class LinkedList {
	head = new Node();
	tail = new Node();
	size = 0;

	constructor() {
		this.head.next = this.tail;
		this.tail.prev = this.head;
	}

	/**
	 * Adds the element to the end of the list.
	 * @param data {*} An element to add
	 * @returns {boolean} True if element was added, false otherwise
	 */
	add(data) {
		if (data === undefined) {
			return false;
		}

		const node = new Node(data, this.tail.prev, this.tail);
		this.tail.prev.next = node;
		this.tail.prev = node;
		this.size += 1;
		return true;
	}

	insert(index, data) {
		if (data === undefined || index + 1 > this.size || index < 0) {
			return false;
		}

		let i = 0;
		let node = this.head.next;
		while (i < index) {
			node = node.next;
			i += 1;
		}

		const newNode = new Node(data, node.prev, node);
		node.prev.next = newNode;
		node.prev = newNode;
		this.size += 1;

		return true;
	}

	/**
	 * Adds all of the elements in the given array to the list.
	 * @param dataArr {*[]} An array of elements
	 */
	addAll(dataArr = []) {
		dataArr.forEach((data) => this.add(data));
	}

	/**
	 * Remove the first occurrence of the given element.
	 * @param data {*} Any element
	 * @returns {undefined|*} The removed data, or undefined if not found
	 */
	remove(data) {
		if (this.size === 0) {
			return undefined;
		}

		for (let node = this.head; node; node = node.next) {
			if (node.data === data) {
				[node.next.prev, node.prev.next] = [node.prev, node.next];
				this.size -= 1;
				return node.data;
			}
		}

		return undefined;
	}

	/**
	 * Returns the first element in the list.
	 * @returns {undefined|*} The first element, or undefined if the list is empty
	 */
	first() {
		if (this.size === 0) {
			return undefined;
		}

		return this.head.next.data;
	}

	/**
	 * Returns the last element in the list.
	 * @returns {undefined|*} The last element, or undefined if the list is empty
	 */
	last() {
		if (this.size === 0) {
			return undefined;
		}

		return this.tail.prev.data;
	}

	/**
	 * Returns an array of the elements in the list.
	 * @returns {*[]} Array of elements
	 */
	toArray() {
		const elems = [];
		if (this.size === 0) {
			return elems;
		}

		for (let node = this.head.next; node.next; node = node.next) {
			if (node !== this.tail) {
				elems.push(node.data);
			}
		}

		return elems;
	}
}
