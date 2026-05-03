import { LightningElement } from 'lwc';

export default class AbcFoodsHeader extends LightningElement {
    showFallbackLogo = false;

    get logoUrl() {
        return '/sfsites/c/resource/abcFoodsLogo';
    }

    handleLogoError() {
        this.showFallbackLogo = true;
    }
}