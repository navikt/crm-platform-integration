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
                    inputField.value = '';
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
                    let errorMessage = 'An error occurred while merging person.';
                    if (error.body && error.body.message) {
                        errorMessage = error.body.message;
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: errorMessage
                        })
                    );
                })
                .finally(() => {
                    this.runningMerge = false;
                });
        }
    }
}
