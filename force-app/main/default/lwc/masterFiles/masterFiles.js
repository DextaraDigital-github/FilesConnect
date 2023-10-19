import { LightningElement, api } from 'lwc';
export default class MasterFileCmp extends LightningElement {
    @api integrationType;
    @api recordId;
    @api objectApiName;
    sharepointFlag = false;
    awsFlag = false;
    driveFlag = false;

    connectedCallback() {
        if (this.integrationType != null && this.integrationType.toLowerCase() === 'sharepoint') {
            this.sharepointFlag = true;
        }
        else  if (this.integrationType != null && this.integrationType.toLowerCase() === 'drive') {
            this.driveFlag = true;
        }
        else{
            this.awsFlag = true;
        }
    }
}