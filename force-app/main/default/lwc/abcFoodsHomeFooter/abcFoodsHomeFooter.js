import { LightningElement } from 'lwc';

export default class AbcFoodsHomeFooter extends LightningElement {
    showFallbackLogo = false;

    get logoUrl() {
        return '/sfsites/c/resource/abcFoodsLogo';
    }

    get currentYear() {
        return new Date().getFullYear();
    }

    handleLogoError() {
        this.showFallbackLogo = true;
    }
}