import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent }       from 'lightning/actions';
import conductShelfAudit                from '@salesforce/apex/ShelfAuditService.conductShelfAuditAura';
import uploadShelfImage                 from '@salesforce/apex/ShelfAuditService.uploadShelfImage';
import getFormattedReport               from '@salesforce/apex/WhatsAppNotificationService.getFormattedReport';

const STEP_DELAY = 1200;

export default class ShelfAuditCapture extends LightningElement {
    @api recordId;
    @api visitId;
    @api storeId;
    @api storeName;

    get effectiveVisitId() { return this.visitId || this.recordId; }

    @track capturedImageUrl    = null;
    @track capturedImageBase64 = null;
    @track aisleSection        = '';
    @track showCapture         = true;
    @track showAnalyzing       = false;
    @track showResults         = false;
    @track showError           = false;
    @track auditResult         = null;
    @track errorMessage        = '';
    @track step1Done = false;
    @track step2Done = false;
    @track step3Done = false;
    @track step4Done = false;

    // ── Rescan state ──────────────────────────────────────────────────────────
    @track parentAuditId = null;

    // ── WhatsApp modal state ──────────────────────────────────────────────────
    @track showWhatsAppModal = false;
    @track whatsAppPreview   = '';
    @track whatsAppLoading   = false;
    @track whatsAppPhone     = '';
    @track whatsAppSending   = false;
    @track whatsAppSent      = false;
    @track whatsAppError     = '';

    // ── Accordion open/close state ────────────────────────────────────────────
    @track abcFoundOpen    = true;
    @track missingOpen     = true;
    @track shelfShareOpen  = true;
    @track placementOpen   = false;
    @track competitorOpen  = false;
    @track otherOpen       = false;

    // ── Accordion toggles ─────────────────────────────────────────────────────
    toggleAbcFound()   { this.abcFoundOpen   = !this.abcFoundOpen;   }
    toggleMissing()    { this.missingOpen     = !this.missingOpen;    }
    toggleShelfShare() { this.shelfShareOpen  = !this.shelfShareOpen; }
    togglePlacement()  { this.placementOpen   = !this.placementOpen;  }
    toggleCompetitor() { this.competitorOpen  = !this.competitorOpen; }
    toggleOther()      { this.otherOpen       = !this.otherOpen;      }

    // ── Chevron classes ───────────────────────────────────────────────────────
    get abcFoundChevronClass()   { return `chevron${this.abcFoundOpen   ? ' chevron--open' : ''}`; }
    get missingChevronClass()    { return `chevron${this.missingOpen    ? ' chevron--open' : ''}`; }
    get shelfShareChevronClass() { return `chevron${this.shelfShareOpen ? ' chevron--open' : ''}`; }
    get placementChevronClass()  { return `chevron${this.placementOpen  ? ' chevron--open' : ''}`; }
    get competitorChevronClass() { return `chevron${this.competitorOpen ? ' chevron--open' : ''}`; }
    get otherChevronClass()      { return `chevron${this.otherOpen      ? ' chevron--open' : ''}`; }

    // ── Score strip class ─────────────────────────────────────────────────────
    get scoreStripClass() {
        const s = this.auditResult?.complianceScore ?? 0;
        return `score-strip ${s >= 80 ? 'score-strip--green' : s >= 60 ? 'score-strip--amber' : 'score-strip--red'}`;
    }

    // ── Compliance state ──────────────────────────────────────────────────────
    get isComplianceExcellent() { return (this.auditResult?.complianceScore ?? 0) >= 80; }
    get isComplianceGood()      { return (this.auditResult?.complianceScore ?? 0) >= 60 && (this.auditResult?.complianceScore ?? 0) < 80; }
    get isComplianceLow()       { return (this.auditResult?.complianceScore ?? 0) < 60; }

    // ── Rescan / delta getters ────────────────────────────────────────────────
    get hasDelta()         { return this.auditResult?.improvementDelta != null; }
    get showReScanButton() { return this.showResults && !this.hasDelta; }

    get deltaCardClass() {
        const d = this.auditResult?.improvementDelta ?? 0;
        return `delta-card ${d > 0 ? 'delta-card--improved' : d < 0 ? 'delta-card--regressed' : 'delta-card--neutral'}`;
    }
    get deltaLabel() {
        const d = this.auditResult?.improvementDelta ?? 0;
        const sign = d > 0 ? '+' : '';
        const arrow = d > 0 ? '↑' : d < 0 ? '↓' : '→';
        return `${sign}${Math.round(d)} pts ${arrow}`;
    }
    get parentScoreDisplay() {
        if (!this.hasDelta) return '--';
        const current = this.auditResult.complianceScore ?? 0;
        const delta   = this.auditResult.improvementDelta ?? 0;
        return Math.round(current - delta) + '%';
    }
    get deltaImproved()  { return (this.auditResult?.improvementDelta ?? 0) > 0; }
    get deltaRegressed() { return (this.auditResult?.improvementDelta ?? 0) < 0; }

    // ── Presence checks ───────────────────────────────────────────────────────
    get hasMissingBrands()  { return !!this.auditResult?.abcBrandsMissing; }
    get hasAbcMatch()       { return !!this.auditResult?.abcBrandsDetected; }
    get hasShelfShare()     { return this.auditResult != null && this.auditResult.shelfShare != null; }
    get showShelfShareAccordion() { return false && this.hasShelfShare; }
    get hasPlacementIssues(){ return !!this.auditResult?.placementIssues; }
    get hasCompetitors()    { return this.auditResult?.competitorSummary && this.auditResult.competitorSummary !== 'No competitor products detected.'; }
    get hasOtherProducts()  { return !!this.auditResult?.otherProductsSummary; }
    get hasLowStockAlerts() { return !!this.auditResult?.lowStockProducts; }

    // ── Count getters ─────────────────────────────────────────────────────────
    get abcFoundCount()   { return this.abcFoundList.length; }
    get missingCount()    { return this.abcMissingList.length; }
    get placementCount()  { return this.placementIssuesList.length; }
    get competitorCount() { return this.competitorList.length; }
    get otherCount()      { return this.otherProductsList.length; }

    // ── Shelf share values ────────────────────────────────────────────────────
    get shelfSharePct()          { return Math.min(this.auditResult?.shelfShare ?? 0, 100); }
    get shelfShareLabel()        { return (this.auditResult?.shelfShare ?? 0) + '%'; }
    get shelfShareBarStyle()     { return `width:${this.shelfSharePct}%; height:100%; background:linear-gradient(90deg,#e8590c,#f28c38); border-radius:8px; transition:width 1s ease;`; }
    get compShelfSharePct()      { return Math.min(this.auditResult?.competitorShelfShare ?? 0, 100); }
    get compShelfShareLabel()    { return (this.auditResult?.competitorShelfShare ?? 0) + '%'; }
    get compShelfShareBarStyle() { return `width:${this.compShelfSharePct}%; height:100%; background:linear-gradient(90deg,#f28c38,#f7b267); border-radius:8px; transition:width 1s ease;`; }
    get otherShelfSharePct()     { return Math.min(this.auditResult?.otherShelfShare ?? 0, 100); }
    get otherShelfShareLabel()   { return (this.auditResult?.otherShelfShare ?? 0) + '%'; }
    get otherShelfShareBarStyle(){ return `width:${this.otherShelfSharePct}%; height:100%; background:linear-gradient(90deg,#f7b267,#fbe3c2); border-radius:8px; transition:width 1s ease;`; }

    // ── Product lists ─────────────────────────────────────────────────────────
    _toList(str) {
        if (!str) return [];
        return str.split('\n')
            .map(l => l.trim())
            .filter(l => l.length > 0)
            .map((name, idx) => ({ id: idx, name }));
    }

    get abcFoundList()        { return this._toList(this.auditResult?.abcBrandsDetected); }
    get abcMissingList()      { return this._toList(this.auditResult?.abcBrandsMissing); }
    get competitorList()      { return this._toList(this.auditResult?.competitorSummary); }
    get otherProductsList()   { return this._toList(this.auditResult?.otherProductsSummary); }
    get placementIssuesList() { return this._toList(this.auditResult?.placementIssues); }
    get lowStockList()        { return this._toList(this.auditResult?.lowStockProducts); }

    // ── Step classes ──────────────────────────────────────────────────────────
    get step1Class() { return `step-item ${this.step1Done ? 'step-done' : 'step-active'}`; }
    get step2Class() { return `step-item ${this.step2Done ? 'step-done' : this.step1Done ? 'step-active' : 'step-waiting'}`; }
    get step3Class() { return `step-item ${this.step3Done ? 'step-done' : this.step2Done ? 'step-active' : 'step-waiting'}`; }
    get step4Class() { return `step-item ${this.step4Done ? 'step-done' : this.step3Done ? 'step-active' : 'step-waiting'}`; }

    // ── Capture handlers ──────────────────────────────────────────────────────
    handleCameraCapture() {
        this.template.querySelector('[data-id="cameraInput"]')?.click();
    }

    handleImageSelected(evt) {
        const file = evt.target.files?.[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (e) => {
            this.capturedImageUrl    = e.target.result;
            this.capturedImageBase64 = e.target.result.split(',')[1];
        };
        reader.readAsDataURL(file);
    }

    handleRetake() {
        this.capturedImageUrl    = null;
        this.capturedImageBase64 = null;
    }

    handleAisleChange(evt) {
        this.aisleSection = evt.detail.value;
    }

    get analyzeDisabled() { return !this.capturedImageUrl; }

    // ── AI Analysis ───────────────────────────────────────────────────────────
    async handleAnalyze() {
        this.showCapture   = false;
        this.showAnalyzing = true;
        this.showError     = false;

        const apexPromise = this._runAuditApex();

        await this.delay(STEP_DELAY);  this.step1Done = true;
        await this.delay(STEP_DELAY);  this.step2Done = true;
        await this.delay(STEP_DELAY);  this.step3Done = true;

        try {
            const result = await apexPromise;
            console.log('=== AUDIT RESULT RECEIVED ===');
            console.log('Result object:', result);
            console.log('Result keys:', Object.keys(result || {}));
            
            this.step4Done = true;
            await this.delay(400);

            if (!result?.success) {
                console.error('Audit failed:', result?.errorMessage);
                throw new Error(result?.errorMessage ?? 'Analysis failed');
            }

            this.auditResult   = result;
            console.log('Audit result assigned to component:', JSON.stringify(this.auditResult, null, 2));
            console.log('Has competitors:', this.hasCompetitors);
            console.log('Has low stock:', this.hasLowStockAlerts);
            console.log('Competitor list:', JSON.stringify(this.competitorList, null, 2));
            console.log('Low stock list:', JSON.stringify(this.lowStockList, null, 2));
            console.log('Competitor list (raw):', this.competitorList);
            console.log('Low stock list (raw):', this.lowStockList);
            
            this.showAnalyzing = false;
            this.showResults   = true;

        } catch (err) {
            console.error('=== AUDIT ERROR ===');
            console.error('Error message:', err.message);
            console.error('Error body:', err.body);
            console.error('Full error:', err);
            
            this.showAnalyzing = false;
            this.showError     = true;
            this.errorMessage  = err.body?.message ?? err.message ?? 'An unexpected error occurred.';
        }
    }

    async _runAuditApex() {
        const contentDocumentId = await uploadShelfImage({
            imageBase64: this.capturedImageBase64,
            visitId: this.effectiveVisitId
        });
        const response = await conductShelfAudit({
            visitId           : this.effectiveVisitId,
            storeId           : this.storeId,
            contentDocumentId : contentDocumentId,
            aisleSection      : this.aisleSection,
            parentAuditId     : this.parentAuditId
        });
        console.log('=== SHELF AUDIT COMPLETE RESPONSE ===');
        console.log('Full Response:', response);
        console.log('Success:', response?.success);
        console.log('Audit ID:', response?.auditId);
        console.log('Compliance Score:', response?.complianceScore);
        console.log('ABC Brands Detected:', response?.abcBrandsDetected);
        console.log('ABC Brands Missing:', response?.abcBrandsMissing);
        console.log('Placement Issues:', response?.placementIssues);
        console.log('Competitor Summary:', response?.competitorSummary);
        console.log('Low Stock Products:', response?.lowStockProducts);
        console.log('Other Products Summary:', response?.otherProductsSummary);
        console.log('Shelf Share:', response?.shelfShare);
        console.log('Competitor Shelf Share:', response?.competitorShelfShare);
        console.log('Other Shelf Share:', response?.otherShelfShare);
        console.log('Raw API Response:', response?.rawApiResponse);
        console.log('=====================================');
        return response;
    }

    handleRescan() {
        this.parentAuditId       = this.auditResult.auditId;
        this.showResults         = false;
        this.showCapture         = true;
        this.capturedImageUrl    = null;
        this.capturedImageBase64 = null;
        this.auditResult         = null;
        this.resetSteps();
    }

    // ── WhatsApp handlers ─────────────────────────────────────────────────────
    get sendDisabled() { return !this.whatsAppPhone || this.whatsAppSending; }

    async handleOpenWhatsApp() {
        this.showWhatsAppModal = true;
        this.whatsAppSent      = false;
        this.whatsAppError     = '';
        this.whatsAppSending   = false;
        this.whatsAppLoading   = true;
        this.whatsAppPreview   = '';
        try {
            this.whatsAppPreview = await getFormattedReport({ auditId: this.auditResult.auditId });
        } catch (e) {
            this.whatsAppPreview = 'Could not load message preview.';
        }
        this.whatsAppLoading = false;
    }

    handlePhoneChange(evt) {
        this.whatsAppPhone = evt.target.value;
    }

    async handleSendWhatsApp() {
        if (!this.whatsAppPhone) return;
        this.whatsAppSending = true;
        this.whatsAppError   = '';
        await this.delay(1500);
        this.whatsAppSent    = true;
        this.whatsAppSending = false;
    }

    handleCloseWhatsApp() {
        this.showWhatsAppModal = false;
        this.whatsAppSent      = false;
        this.whatsAppError     = '';
        this.whatsAppPreview   = '';
        this.whatsAppPhone     = '';
    }

    // ── Navigation ────────────────────────────────────────────────────────────
    handleDone() {
        this.dispatchEvent(new CustomEvent('auditcomplete', {
            detail: {
                auditId        : this.auditResult.auditId,
                auditNumber    : this.auditResult.auditNumber,
                complianceScore: this.auditResult.complianceScore
            }
        }));
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleRetry() {
        this.showError   = false;
        this.showCapture = true;
        this.resetSteps();
    }

    resetSteps() { this.step1Done = this.step2Done = this.step3Done = this.step4Done = false; }
    delay(ms)    { return new Promise(resolve => setTimeout(resolve, ms)); }
}