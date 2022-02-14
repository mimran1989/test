import { merge } from 'lodash';
import { NamedRangeDO } from '../../interfaces/namedRangeDO';
import UIElement, { ObservedElement } from './element';
import { CellCoords, SelectedRange } from '../grid/cell';

type NamedRangeSpecification = {
	range: SelectedRange;
	totalCoords: Record<string, CellCoords>;
};

export class NamedRange extends UIElement {
	$type: string = 'NamedRange';

	static newDO({ ...props }): NamedRangeDO {
		return merge(
			{
				name: null,
				namedRangeId: null,
				quoteItemId: null,
				quotePeriodId: null,
				quotePeriodGroupId: null,
				quoteSectionId: null,
				projectPhaseId: null,
				type: null,
				rangeSpec: null,
				relatedTotal: {
					namedRangeTotalId: null,
					marginPercent: 0,
					quantityUOM: null,
					totalAmount: 0,
					totalCost: 0,
					totalQuantity: 0,
				},
				adjustmentList: [],
			},
			props,
		);
	}

	range = (from: CellCoords, to: CellCoords, totalCoords: Record<string, CellCoords>): string => {
		const data = this.data() as NamedRangeDO;

		const rangeSpec: NamedRangeSpecification = {
			range: {
				from,
				to,
			},
			totalCoords,
		};

		data.rangeSpec = JSON.stringify(rangeSpec);

		return data.rangeSpec;
	};
}

export const NamedRanges = {
	for: (namedRangeDOs: NamedRangeDO[]): ObservedElement[] => namedRangeDOs.map((namedRangeDO) => NamedRange.for(namedRangeDO)),
};
