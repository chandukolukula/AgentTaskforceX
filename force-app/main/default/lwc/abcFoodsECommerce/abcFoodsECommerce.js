import { LightningElement, api } from 'lwc';

export default class AbcFoodsECommerce extends LightningElement {

    _value;

    logValue(prefix, value) {
        try {
            console.log(prefix, JSON.stringify(value, null, 2));
        } catch (error) {
            console.log(prefix, value);
            console.warn('abcFoodsECommerce log serialization failed', error);
        }
    }

    @api
    get value() {
        this.logValue('abcFoodsECommerce.get value ->', this._value);
        return this._value;
    }

    set value(val) {
        this._value = val;
        this.logValue('abcFoodsECommerce.set value <-', val);
    }

    connectedCallback() {
        this.logValue('abcFoodsECommerce.connectedCallback value ->', this._value);
    }

    get result() {
        this.logValue('abcFoodsECommerce.result ->', this._value || {});
        return this._value || {};
    }

    get message() {
        console.log('abcFoodsECommerce.message ->', this.result.message);
        return this.result.message;
    }

    get productCount() {
        console.log('abcFoodsECommerce.productCount ->', this.result.productCount || 0);
        return this.result.productCount || 0;
    }

    get products() {
        const products = Array.isArray(this.result.productDetails) ? this.result.productDetails : [];
        this.logValue('abcFoodsECommerce.products ->', products);
        return products;
    }

    get hasProducts() {
        const hasProducts = this.products.length > 0;
        console.log('abcFoodsECommerce.hasProducts ->', hasProducts);
        return hasProducts;
    }
}