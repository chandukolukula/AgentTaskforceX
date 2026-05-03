import { LightningElement, api } from 'lwc';

export default class AbcFoodsECommerceStores extends LightningElement {
    _value;

    logValue(prefix, value) {
        try {
            console.log(prefix, JSON.stringify(value, null, 2));
        } catch (error) {
            console.log(prefix, value);
            console.warn('abcFoodsECommerceStores log serialization failed', error);
        }
    }

    @api
    get value() {
        this.logValue('abcFoodsECommerceStores.get value ->', this._value);
        return this._value;
    }

    set value(val) {
        this._value = val;
        this.logValue('abcFoodsECommerceStores.set value <-', val);
    }

    connectedCallback() {
        this.logValue('abcFoodsECommerceStores.connectedCallback value ->', this._value);
    }

    get result() {
        const result = this._value || {};
        this.logValue('abcFoodsECommerceStores.result ->', result);
        return result;
    }

    get message() {
        console.log('abcFoodsECommerceStores.message ->', this.result.message);
        return this.result.message;
    }

    get citySearched() {
        console.log('abcFoodsECommerceStores.citySearched ->', this.result.citySearched);
        return this.result.citySearched;
    }

    get storeCount() {
        const count = this.result.storeCount || 0;
        console.log('abcFoodsECommerceStores.storeCount ->', count);
        return count;
    }

    get stores() {
        const stores = Array.isArray(this.result.retailStores) ? this.result.retailStores : [];
        this.logValue('abcFoodsECommerceStores.stores ->', stores);
        return stores;
    }

    get hasStores() {
        const hasStores = this.stores.length > 0;
        console.log('abcFoodsECommerceStores.hasStores ->', hasStores);
        return hasStores;
    }
}