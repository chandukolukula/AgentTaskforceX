import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class AbcFoodsHomeHero extends NavigationMixin(LightningElement) {
    categoryPills = [
        { label: 'Salty Snacks',       icon: '🌶️', style: 'border-color:rgba(255,140,0,0.5);background:rgba(255,140,0,0.2);' },
        { label: 'Sweet Snacks',       icon: '🍬', style: 'border-color:rgba(233,30,99,0.5);background:rgba(233,30,99,0.2);' },
        { label: 'Confectionery',      icon: '🍫', style: 'border-color:rgba(106,27,154,0.5);background:rgba(106,27,154,0.2);' },
        { label: 'Cookies & Biscuits', icon: '🍪', style: 'border-color:rgba(141,110,99,0.5);background:rgba(141,110,99,0.2);' },
        { label: 'Premium Range',      icon: '⭐', style: 'border-color:rgba(255,215,0,0.5);background:rgba(255,215,0,0.18);' },
        { label: 'Health Bars',        icon: '💪', style: 'border-color:rgba(46,125,50,0.5);background:rgba(46,125,50,0.2);' },
        { label: 'Kids Range',         icon: '🌈', style: 'border-color:rgba(255,87,34,0.5);background:rgba(255,87,34,0.2);' },
        { label: 'New Arrivals',       icon: '✨', style: 'border-color:rgba(255,255,255,0.4);background:rgba(255,255,255,0.12);' }
    ];

    navigateToProducts() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Products__c' }
        });
    }

    navigateToAbout() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'About__c' }
        });
    }
}