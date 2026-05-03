import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callPromptTemplate from '@salesforce/apex/RetailStoresController.invokePromptTemplate';
import createStoreVisits from '@salesforce/apex/RetailStoresController.createStoreVisits';

export default class RetailStoreMap extends LightningElement {
    @track mapMarkers = [];
    @track summary = {};
    @track route = {};
    @track isRunning = false;
    @track errorMessage;
    @track hasStores = false;
    @track noStores = false;
    @track selectedMarkerValue;
    @track checkedStoreNames = [];
    @track isCreatingVisits = false;

    zoomLevel = 12;
    _stores = [];

    get today() {
        return new Date().toLocaleDateString('en-IN', {
            weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
        });
    }

    get cityName() {
        return this._stores.length > 0 ? (this._stores[0].city || '') : '';
    }

    get hasCheckedStores() {
        return this.checkedStoreNames.length > 0;
    }

    get selectionLabel() {
        const n = this.checkedStoreNames.length;
        return `${n} store${n !== 1 ? 's' : ''} selected`;
    }

    get hasRoute() {
        return Array.isArray(this.route?.routeSummary) && this.route.routeSummary.length > 0;
    }

    get routeSummaryItems() {
        const summary = this.route?.routeSummary ?? [];
        return summary.map((line, i) => {
            // line format: "1. Store Name — Street Address"
            const dashIdx = line.indexOf(' — ');
            const dotIdx  = line.indexOf('. ');
            const order   = dotIdx > -1 ? line.substring(0, dotIdx) : String(i + 1);
            const rest    = dotIdx > -1 ? line.substring(dotIdx + 2) : line;
            const name    = dashIdx > -1 ? rest.substring(0, rest.indexOf(' — ')) : rest;
            const addr    = dashIdx > -1 ? line.substring(dashIdx + 3) : '';
            return {
                key: i,
                visitOrder: order,
                name,
                address: addr,
                hasNext: i < summary.length - 1
            };
        });
    }

    get storeItems() {
        const categoryClassMap = {
            'Supermarket':    'cat-badge cat-supermarket',
            'Hypermarket':    'cat-badge cat-hypermarket',
            'Discount Store': 'cat-badge cat-discount',
            'Convenience':    'cat-badge cat-convenience'
        };
        return this._stores.map((store, idx) => {
            const isChecked  = this.checkedStoreNames.includes(store.name);
            const isSelected = store.name === this.selectedMarkerValue;
            let itemClass = 'store-item';
            if (isSelected) itemClass += ' store-item_selected';
            if (isChecked)  itemClass += ' store-item_checked';
            return {
                index: store.visitOrder ?? (idx + 1),
                name: store.name,
                category: store.category,
                categoryClass: categoryClassMap[store.category] || 'cat-badge cat-other',
                address: (() => {
                    const street = store.streetAddress || '';
                    const neighbourhood = store.neighborhood || '';
                    const city = store.city || '';
                    const parts = [street];
                    if (neighbourhood && !street.toLowerCase().includes(neighbourhood.toLowerCase())) {
                        parts.push(neighbourhood);
                    }
                    if (city) parts.push(city);
                    return parts.filter(Boolean).join(', ');
                })(),
                phone: store.phone,
                isSelected,
                isChecked,
                itemClass
            };
        });
    }

    handleMarkerSelect(event) {
        this.selectedMarkerValue = event.detail.selectedMarkerValue;
        console.log('[retailStoreMap] Marker selected:', this.selectedMarkerValue);
        this._buildMapMarkers();
        const selected = this.template.querySelector(`[data-name="${this.selectedMarkerValue}"]`);
        if (selected) selected.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    handleListItemClick(event) {
        const name = event.currentTarget.dataset.name;
        console.log('[retailStoreMap] List item clicked:', name);
        this.selectedMarkerValue = name;
        this._buildMapMarkers();
    }

    handleCheckboxClick(event) {
        event.stopPropagation(); // prevent triggering map highlight
        const name = event.currentTarget.dataset.name;
        if (this.checkedStoreNames.includes(name)) {
            this.checkedStoreNames = this.checkedStoreNames.filter(n => n !== name);
        } else {
            this.checkedStoreNames = [...this.checkedStoreNames, name];
        }
        console.log('[retailStoreMap] Checked stores:', this.checkedStoreNames);
    }

    handleClearSelection() {
        this.checkedStoreNames = [];
    }

    async handleCreateVisits() {
        const storeNames = [...this.checkedStoreNames];
        console.log('[retailStoreMap] Creating visits for:', storeNames);
        this.isCreatingVisits = true;
        try {
            await createStoreVisits({ storeNames });
            this.dispatchEvent(new ShowToastEvent({
                title: 'Visits Created',
                message: `Successfully created visits for ${storeNames.length} store${storeNames.length !== 1 ? 's' : ''}.`,
                variant: 'success'
            }));
            this.checkedStoreNames = [];
        } catch (err) {
            console.error('[retailStoreMap] createStoreVisits failed:', err);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error Creating Visits',
                message: err?.body?.message ?? 'An unexpected error occurred.',
                variant: 'error'
            }));
        } finally {
            this.isCreatingVisits = false;
        }
    }

    async handleFindStores() {
        console.log('[retailStoreMap] handleFindStores called');
        this.isRunning = true;
        this.errorMessage = undefined;
        this.hasStores = false;
        this.noStores = false;
        this.mapMarkers = [];
        this.summary = {};
        this.route = {};
        this._stores = [];
        this.selectedMarkerValue = undefined;
        this.checkedStoreNames = [];

        try {
            console.log('[retailStoreMap] Invoking prompt template: Retail_Stores_Extraction_Template');
            const response = await callPromptTemplate({ promptName: 'Retail_Stores_Extraction_Template' });
            console.log('[retailStoreMap] Raw response:', response);
            this._parseAndDisplay(response);
        } catch (err) {
            console.error('[retailStoreMap] Apex call failed:', err);
            this.errorMessage = err?.body?.message ?? JSON.stringify(err);
        } finally {
            this.isRunning = false;
        }
    }

    handleOptimizeRoute() {
        console.log('[retailStoreMap] handleOptimizeRoute called with', this._stores.length, 'stores');
        if (this._stores.length === 0) return;
        const toAddress = (store) =>
            [store.streetAddress, store.neighborhood, store.city, store.state, store.country]
                .filter(Boolean).join(', ');
        const origin      = encodeURIComponent(toAddress(this._stores[0]));
        const destination = encodeURIComponent(toAddress(this._stores[this._stores.length - 1]));
        const waypoints   = this._stores.slice(1, -1)
            .map(s => encodeURIComponent(toAddress(s))).join('|');
        let url = `https://www.google.com/maps/dir/?api=1&origin=${origin}&destination=${destination}&travelmode=driving`;
        if (waypoints) url += `&waypoints=${waypoints}`;
        console.log('[retailStoreMap] Opening Google Maps route URL:', url);
        window.open(url, '_blank');
    }

    _buildMapMarkers() {
        this.mapMarkers = this._stores.map((store, idx) => {
            const seq = store.visitOrder ?? (idx + 1);
            const isSelected = store.name === this.selectedMarkerValue;
            return {
                location: {
                    Street: [store.streetAddress, store.neighborhood].filter(Boolean).join(', '),
                    City: store.city,
                    State: store.state,
                    PostalCode: store.postalCode,
                    Country: store.country
                },
                title: `${seq}. ${store.name}`,
                description: store.category + (store.phone ? '\nPhone: ' + store.phone : ''),
                value: store.name,
                mapIcon: {
                    url: this._numberedPinUrl(seq, isSelected),
                    scaledSize: { width: 32, height: 44 }
                }
            };
        });
        console.log('[retailStoreMap] Map markers rebuilt, selected:', this.selectedMarkerValue);
    }

    _numberedPinUrl(num, isSelected) {
        const bg     = isSelected ? '#e8a000' : '#0176d3';
        const stroke = isSelected ? '#7a5000' : '#032d60';
        const fontSize = num > 9 ? 10 : 13;
        const svg =
            `<svg xmlns="http://www.w3.org/2000/svg" width="32" height="44" viewBox="0 0 32 44">` +
            `<path d="M16 0C7.163 0 0 7.163 0 16c0 12.558 16 28 16 28S32 28.558 32 16C32 7.163 24.837 0 16 0z" fill="${bg}" stroke="${stroke}" stroke-width="1.5"/>` +
            `<text x="16" y="20" text-anchor="middle" dominant-baseline="middle" font-family="Arial,Helvetica,sans-serif" font-size="${fontSize}" font-weight="bold" fill="white">${num}</text>` +
            `</svg>`;
        return 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(svg);
    }

    _parseAndDisplay(responseText) {
        let data;
        try {
            const cleaned = responseText
                .replace(/^```(?:json)?\s*/i, '')
                .replace(/\s*```\s*$/, '')
                .trim();
            console.log('[retailStoreMap] Cleaned response:', cleaned);
            data = JSON.parse(cleaned);
            console.log('[retailStoreMap] Parsed data:', JSON.stringify(data));
        } catch (e) {
            const preview = responseText ? responseText.substring(0, 120) : '(empty)';
            console.error('[retailStoreMap] JSON parse failed:', e.message, '| Raw response:', responseText);
            this.errorMessage = 'Could not parse AI response: ' + preview;
            return;
        }

        if (data.error) {
            console.warn('[retailStoreMap] Response contains error:', data.error);
            this.errorMessage = data.error;
            return;
        }

        const stores = data.stores ?? [];
        this.summary = data.summary ?? {};
        this.route = data.route ?? {};
        console.log('[retailStoreMap] Store count:', stores.length, '| Summary:', JSON.stringify(this.summary));

        if (stores.length === 0) {
            console.log('[retailStoreMap] No stores found for this city');
            this.noStores = true;
            return;
        }

        this._stores = [...stores].sort((a, b) => (a.visitOrder ?? 0) - (b.visitOrder ?? 0));
        this._buildMapMarkers();
        console.log('[retailStoreMap] Map markers built:', JSON.stringify(this.mapMarkers));
        this.hasStores = true;
    }
}