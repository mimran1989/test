import {
	LightningElement,
	api,
} from 'lwc';
import LABEL_ADD_TO_QUOTE from '@salesforce/label/c.AddToQuote';
import LABEL_CANCEL from '@salesforce/label/c.CancelButton';
import RENAME_ADDON from '@salesforce/label/c.RenameAddon';

export default class RenameAddOn extends LightningElement {
	@api quote;
	LABEL_RENAME_ADDON = RENAME_ADDON;
	LABEL_ADD_TO_QUOTE = LABEL_ADD_TO_QUOTE;
	LABEL_CANCEL = LABEL_CANCEL;
	_messageService;
	disableRename = true;

	renderedCallback() {
		this._messageService = this.template.querySelector('c-message-service');
		this._messageService.publish({
			key: 'deselect',
		});
	}

	handleRenameAddon() {
		const renametext = this.template.querySelector('lightning-input').value;
		this._messageService.publish({
			key: 'renameaddon',
			value: renametext,
		});
		this._messageService.notifyClose();
	}

	validateAddonLabel(event) {
		const renametext = event.detail.value.trim();
		this.disableRename = renametext.length === 0;
	}

	handleCancel() {
		this._messageService.notifyClose();
	}
}
