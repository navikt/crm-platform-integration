import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import mergeIdent from '@salesforce/apex/CRM_PersonMerge.mergeIdentAura';

export default class CrmMergePerson extends LightningElement {
    runningMerge = false;

    runMergeIdent() {
        const inputField = this.template.querySelector("[data-id='personIdent']");
        const ident = inputField?.value;
        inputField.reportValidity();

        if (inputField.checkValidity()) {
            this.runningMerge = true;
            mergeIdent({ ident: ident })
                .then(() => {
                    this.template.querySelector('personIdent').value = '';
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            variant: 'success',
                            message: 'Person is merged'
                        })
                    );
                })
                .catch((error) => {
                    console.error(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: `MERGE PERSON: ${error.body?.exceptionType ? error.body.exceptionType : ''}`,
                            variant: 'error',
                            message: error.body.message
                        })
                    );
                })
                .finally(() => {
                    this.runningMerge = false;
                });
        }
    }
}
