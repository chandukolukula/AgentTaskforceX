import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin }          from 'lightning/navigation';
import { refreshApex }              from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Id                           from '@salesforce/user/Id';
import NAME_FIELD                   from '@salesforce/schema/User.Name';
import getTodayVisits               from '@salesforce/apex/RepDashboardController.getTodayVisits';
import getPriorityRecommendations   from '@salesforce/apex/RepDashboardController.getPriorityRecommendations';
import getDashboardKPIs             from '@salesforce/apex/RepDashboardController.getDashboardKPIs';
import getComplianceTrend           from '@salesforce/apex/RepDashboardController.getComplianceTrend';

const USER_FIELDS = [NAME_FIELD];

export default class RepDashboard extends NavigationMixin(LightningElement) {
    @track todayVisits       = [];
    @track recommendations   = [];
    @track complianceTrend   = [];
    @track isLoadingVisits   = true;
    @track visitsCompleted   = 0;
    @track visitsPlanned     = 0;
    @track openTasks         = 0;
    @track criticalTasks     = 0;

    _wiredVisits;
    _wiredRecs;

    @wire(getRecord, { recordId: Id, fields: USER_FIELDS })
    userRecord;

    get repName() {
        return getFieldValue(this.userRecord.data, NAME_FIELD)?.split(' ')[0] ?? 'Rep';
    }

    get timeOfDay() {
        const h = new Date().getHours();
        return h < 12 ? 'morning' : h < 17 ? 'afternoon' : 'evening';
    }

    get today() {
        return new Date().toLocaleDateString('en-IN', {
            weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
        });
    }

    get visitProgress() {
        return this.visitsPlanned > 0
            ? Math.round((this.visitsCompleted / this.visitsPlanned) * 100)
            : 0;
    }

    get visitProgressStyle() {
        return `width: ${this.visitProgress}%`;
    }

    get noVisitsToday()      { return !this.isLoadingVisits && this.todayVisits.length === 0; }
    get hasRecommendations() { return this.recommendations.length > 0; }

    // ── Compliance trend getters ───────────────────────────────────────────────
    get hasTrend() { return this.complianceTrend && this.complianceTrend.length >= 2; }

    get trendAvgScore() {
        if (!this.complianceTrend.length) return 0;
        const sum = this.complianceTrend.reduce((s, p) => s + (p.score ?? 0), 0);
        return Math.round(sum / this.complianceTrend.length);
    }

    get trendAvgClass() {
        const s = this.trendAvgScore;
        return `trend-avg-badge ${s >= 80 ? 'trend-avg--green' : s >= 60 ? 'trend-avg--amber' : 'trend-avg--red'}`;
    }

    get trendColor() {
        const s = this.trendAvgScore;
        return s >= 80 ? '#2e844a' : s >= 60 ? '#e07000' : '#ba0517';
    }

    get trendPoints() {
        if (!this.hasTrend) return [];
        const xStart = 10, xEnd = 290, baseline = 48;
        const n = this.complianceTrend.length;
        const spacing = (xEnd - xStart) / (n - 1);
        const allSameDate = this.complianceTrend.every(p => p.dateLabel === this.complianceTrend[0].dateLabel);
        return this.complianceTrend.map((pt, i) => ({
            id        : i,
            x         : Math.round(xStart + spacing * i),
            y         : Math.round(baseline - (pt.score / 100) * 36),
            score     : Math.round(pt.score),
            dateLabel : allSameDate ? `#${i + 1}` : pt.dateLabel,
        }));
    }

    get trendPolylinePoints() {
        return this.trendPoints.map(p => `${p.x},${p.y}`).join(' ');
    }

    get trendAreaPath() {
        const pts = this.trendPoints;
        if (pts.length < 2) return '';
        const base = 48;
        const line = pts.map(p => `${p.x},${p.y}`).join(' L');
        return `M${pts[0].x},${base} L${line} L${pts[pts.length - 1].x},${base} Z`;
    }

    get trendLatestScore() {
        const pts = this.trendPoints;
        return pts.length ? pts[pts.length - 1].score : 0;
    }

    get trendHighScore() {
        return this.complianceTrend.length
            ? Math.round(Math.max(...this.complianceTrend.map(p => p.score ?? 0)))
            : 0;
    }

    get trendLowScore() {
        return this.complianceTrend.length
            ? Math.round(Math.min(...this.complianceTrend.map(p => p.score ?? 0)))
            : 0;
    }

    @wire(getTodayVisits)
    wiredVisits(result) {
        this._wiredVisits    = result;
        this.isLoadingVisits = false;
        if (result.data) {
            this.todayVisits = result.data.map((v, idx) => ({
                ...v,
                seq        : idx + 1,
                storeName  : v.RetailStore?.Name ?? 'Unknown Store',
                address    : [v.RetailStore?.Street, v.RetailStore?.City].filter(Boolean).join(', '),
                plannedTime: v.PlannedVisitStartTime
                    ? new Date(v.PlannedVisitStartTime).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
                    : 'Anytime',
                statusClass: `status-badge status-${(v.Status ?? 'planned').toLowerCase().replace(' ', '-')}`,
                status     : v.Status ?? 'Planned',
                cardClass  : `visit-card ${v.Status === 'Completed' ? 'visit-completed' : ''}`
            }));
            this.visitsPlanned   = this.todayVisits.length;
            this.visitsCompleted = this.todayVisits.filter(v => v.Status === 'Completed').length;
        }
    }

    @wire(getComplianceTrend)
    wiredTrend({ data, error }) {
        if (data)  this.complianceTrend = data;
        if (error) this.complianceTrend = [];
    }

    @wire(getPriorityRecommendations)
    wiredRecs(result) {
        this._wiredRecs = result;
        if (result.data) {
            this.recommendations = result.data.map(r => ({
                ...r,
                storeName  : r.ShelfAudit__r?.RetailStore__r?.Name ?? '',
                rowClass   : `rec-row priority-${(r.Priority__c ?? 'medium').toLowerCase()}`,
                priorityDot: `priority-dot dot-${(r.Priority__c ?? 'medium').toLowerCase()}`
            }));
        }
    }

    connectedCallback() { this.loadKPIs(); }

    async loadKPIs() {
        try {
            const kpis       = await getDashboardKPIs();
            this.openTasks   = kpis.openTasks    ?? 0;
            this.criticalTasks = kpis.criticalTasks ?? 0;
        } catch (e) {
            console.error('KPI load error', e);
        }
    }

    handleVisitTap()  { /* navigate to Visit detail */ }
    handleRecAction() { /* navigate to Recommendation detail */ }
    refreshData()     { refreshApex(this._wiredVisits); refreshApex(this._wiredRecs); this.loadKPIs(); }
    navigateToVisits(){ this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: 'Visit', actionName: 'list' } }); }
    navigateToTasks() { this[NavigationMixin.Navigate]({ type: 'standard__objectPage', attributes: { objectApiName: 'Task',  actionName: 'list' } }); }
}