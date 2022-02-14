trigger QuoteItemTrigger on QuoteItem__c(before insert, before update, before delete) {
	if (Trigger.isBefore) {
		if (Trigger.isInsert && MultiCurrencyService.isMultiCurrencyEnabled()) {
			MultiCurrencyService.syncQuoteCurrency(Trigger.new);
		}

		if (Trigger.isUpdate && MultiCurrencyService.isMultiCurrencyEnabled()) {
			MultiCurrencyService.updateCurrencyFields(Trigger.new, Trigger.oldMap);
		}

		if (Trigger.isDelete) {
			QuoteItemService.deleteQuoteItemNamedRange(Trigger.old);
		}
	}
}
