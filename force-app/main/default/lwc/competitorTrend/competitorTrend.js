import { LightningElement, api } from 'lwc';

export default class CompetitorTrend extends LightningElement {
    storeName;
    displayMessage;
    periodDays = 30;
    brand1Name; brand1AvgShare; brand1Trend; brand1Delta;
    brand2Name; brand2AvgShare; brand2Trend; brand2Delta;
    brand3Name; brand3AvgShare; brand3Trend; brand3Delta;

    _value;

    @api
    get value() { return this._value; }
    set value(val) {
        this._value = val;
        if (!val) return;
        const r            = val.results || val;
        this.storeName      = r.storeName;
        this.displayMessage = r.displayMessage;
        this.periodDays     = r.periodDays ?? 30;
        this.brand1Name     = r.brand1Name;  this.brand1AvgShare = r.brand1AvgShare; this.brand1Trend = r.brand1Trend; this.brand1Delta = r.brand1Delta;
        this.brand2Name     = r.brand2Name;  this.brand2AvgShare = r.brand2AvgShare; this.brand2Trend = r.brand2Trend; this.brand2Delta = r.brand2Delta;
        this.brand3Name     = r.brand3Name;  this.brand3AvgShare = r.brand3AvgShare; this.brand3Trend = r.brand3Trend; this.brand3Delta = r.brand3Delta;
    }

    get hasBrands() { return !!this.brand1Name; }

    get brands() {
        return [
            { id: 0, name: this.brand1Name, share: this.brand1AvgShare, trend: this.brand1Trend, delta: this.brand1Delta },
            { id: 1, name: this.brand2Name, share: this.brand2AvgShare, trend: this.brand2Trend, delta: this.brand2Delta },
            { id: 2, name: this.brand3Name, share: this.brand3AvgShare, trend: this.brand3Trend, delta: this.brand3Delta },
        ]
        .filter(b => !!b.name)
        .map(b => ({
            ...b,
            initial   : b.name.charAt(0).toUpperCase(),
            shareLabel: (b.share != null ? Math.round(b.share) : 0) + '%',
            trendText : b.trend === 'up'   ? `+${Math.round(b.delta ?? 0)} pts ↑`
                      : b.trend === 'down' ? `−${Math.round(b.delta ?? 0)} pts ↓`
                      : 'stable →',
            trendClass: `brand-trend brand-trend--${b.trend || 'stable'}`,
        }));
    }
}