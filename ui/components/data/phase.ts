import { merge } from 'lodash';
import UIElement, { ObservedElement } from './element';
import { ProjectPhaseDO } from '../../interfaces/projectPhaseDO';

export class Phase extends UIElement {
	$type: string = 'ProjectPhase';
	startCol: number = 0;
	endCol: number = 0;
	periodGroupId: string = null;

	numberOfPeriods = () => (this.startCol > this.endCol ? 0
		: this.endCol - this.startCol + 1);

	isPersisted = () => {
		const element = this.elementDO as ProjectPhaseDO;
		return element.id !== null && element.id !== undefined;
	};

	static newDO({ ...props }): ProjectPhaseDO {
		return merge(
			{
				id: null,
				name: null,
				quoteId: null,
				sequence: null,
				description: null,
				startDate: null,
				endDate: null,
				operationType: null,
				parentProjectPhaseId: null,
				parentProjectName: null,
				quotePeriodIdList: [],
			},
			props,
		);
	}
}

export const Phases = {
	for: (projectPhaseDOs: ProjectPhaseDO[]): ObservedElement[] => projectPhaseDOs.map((projectPhaseDO) => Phase.for(projectPhaseDO)),
};
