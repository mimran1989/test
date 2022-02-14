import QuoteGrid from './quoteGrid';

abstract class QuoteGridTable extends QuoteGrid {
	static frameContent = QuoteGrid.component
		.find('iframe')
		.iframe();

	static fixedLeftPanel = QuoteGridTable
		.frameContent
		.find('div.ht_clone_left');

	static roleColumn = QuoteGridTable.fixedLeftPanel
		.nthDescendant(4) // table htCore
		.find('tbody');

	static roleColumnCellForName = (roleName: string) => QuoteGridTable.roleColumn.find('td').withExactText(roleName);

	static roleColumnCellForRow = (rowNumber: number) => QuoteGridTable.roleColumn
		.child('tr')
		.nth(rowNumber - 1);
}

export default QuoteGridTable;
