type ColIdx = {
	colProp?: undefined;
	col: number;
};

type ColProperty = {
	colProp: string;
	col?: undefined;
};

type ColCoords = ColIdx | ColProperty;

export type CellCoords = ColCoords & {
	row: number;
};

export type SelectedRange = {
	from: CellCoords;
	to: CellCoords;
};
