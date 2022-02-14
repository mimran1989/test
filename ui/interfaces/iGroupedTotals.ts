export interface IGroupedTotals {
	marginPercent: Record<string, number>;
	totalAmount: Record<string, number>;
	totalCost: Record<string, number>;
	totalQuantity: Record<string, number>;
	field: string;
	label: string;
}
