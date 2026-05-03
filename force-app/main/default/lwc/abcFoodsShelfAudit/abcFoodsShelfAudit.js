import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AbcFoodsShelfAudit extends LightningElement {
    displayMessage;
    visitId;
    storeId;
    storeName;
    lastComplianceScore;
    lastAuditDate;
    recordUpdated = false;
    performAnotherAudit = null;

    stringifyForLog(value) {
        try {
            return JSON.stringify(value);
        } catch (e) {
            return String(value);
        }
    }

    @api
    get value() {
        console.log('abcFoodsShelfAudit.get value ->', this.stringifyForLog(this._value));
        return this._value;
    }
    set value(val) {
        console.log('abcFoodsShelfAudit.set value <-', this.stringifyForLog(val));
        this._value = val;
        if (val) {
            const r            = val.results || val;
            console.log('abcFoodsShelfAudit.set value parsed results <-', this.stringifyForLog(r));
            this.visitId       = r.visitId;
            this.storeId       = r.storeId;
            this.storeName     = r.storeName;
            this.displayMessage       = r.displayMessage;
            this.lastComplianceScore  = r.lastComplianceScore != null
                ? Math.round(r.lastComplianceScore) : null;
            this.lastAuditDate = r.lastAuditDate;

            // If prior audit exists, ask user before showing capture UI.
            this.performAnotherAudit = this.hasLastAudit ? null : true;

            // Update Visit record status when visitId is available
            if (this.visitId && !this.recordUpdated) {
                this.updateVisitStatus();
            }
        }
    }

    connectedCallback() {
        // Update Visit record status if visitId is already available
        if (this.visitId && !this.recordUpdated) {
            this.updateVisitStatus();
        }
    }

    updateVisitStatus() {
        const fields = {
            Id: this.visitId,
            Status: 'InProgress'
        };

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.recordUpdated = true;
                console.log('Visit record status updated to In Progress');
            })
            .catch((error) => {
                console.error('Error updating Visit record status:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to update Visit status. ' + error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    get hasLastAudit() {
        return this.lastComplianceScore != null && this.lastAuditDate;
    }

    get showDisplayMessage() {
        return !!this.displayMessage && !this.hasLastAudit;
    }

    get showAuditPrompt() {
        return this.hasLastAudit && this.performAnotherAudit === null;
    }

    get showShelfAuditCapture() {
        return !this.hasLastAudit || this.performAnotherAudit === true;
    }

    get showAuditSkippedMessage() {
        return this.hasLastAudit && this.performAnotherAudit === false;
    }

    handlePerformAuditYes() {
        this.performAnotherAudit = true;
    }

    handlePerformAuditNo() {
        this.performAnotherAudit = false;
    }
}