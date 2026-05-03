import { LightningElement, api } from 'lwc';

export default class RepPerformanceSummary extends LightningElement {
    repName; displayMessage; weekLabel;
    storesAudited; avgCompliance; trendLabel;
    bestStoreName; bestStoreScore; worstStoreName; worstStoreScore;

    _value;

    @api
    get value() { return this._value; }
    set value(val) {
        this._value = val;
        if (!val) return;
        const r            = val.results || val;
        this.repName        = r.repName;
        this.displayMessage = r.displayMessage;
        this.weekLabel      = r.weekLabel;
        this.storesAudited  = r.storesAudited;
        this.avgCompliance  = r.avgCompliance;
        this.trendLabel     = r.trendLabel;
        this.bestStoreName  = r.bestStoreName;
        this.bestStoreScore = r.bestStoreScore;
        this.worstStoreName = r.worstStoreName;
        this.worstStoreScore = r.worstStoreScore;
        console.log('RepPerformanceSummary value set:', r);
    }

    get bestStoreDisplay()  { return this.bestStoreScore  != null ? Math.round(this.bestStoreScore)  : '--'; }
    get worstStoreDisplay() { return this.worstStoreScore != null ? Math.round(this.worstStoreScore) : '--'; }
    get showWorstStore()    { return !!this.worstStoreName && this.worstStoreName !== this.bestStoreName; }

    get stats() {
        const s   = this.avgCompliance ?? 0;
        const cls = s >= 80 ? 'stat-pill stat-pill--green'
                  : s >= 60 ? 'stat-pill stat-pill--amber'
                  :           'stat-pill stat-pill--red';
        return [
            { id: 0, label: 'Stores Audited', value: this.storesAudited ?? 0,     cls: 'stat-pill' },
            { id: 1, label: 'Avg Compliance', value: Math.round(s) + '%',          cls: 'stat-pill' },
            { id: 2, label: 'Status',         value: this.trendLabel ?? '--',      cls },
        ];
    }
}