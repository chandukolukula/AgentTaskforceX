import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class AbcFoodsHomeHeader extends NavigationMixin(LightningElement) {
    @track menuOpen = false;
    @track isScrolled = false;
    showFallbackLogo = false;
    _scrollHandler;

    get logoUrl() {
        return '/sfsites/c/resource/abcFoodsLogo';
    }

    get headerClass() {
        return `site-header${this.isScrolled ? ' scrolled' : ''}`;
    }

    get mobileMenuBtnClass() {
        return `mobile-menu-btn${this.menuOpen ? ' open' : ''}`;
    }

    connectedCallback() {
        this._scrollHandler = () => {
            this.isScrolled = window.scrollY > 10;
        };
        window.addEventListener('scroll', this._scrollHandler, { passive: true });
    }

    disconnectedCallback() {
        window.removeEventListener('scroll', this._scrollHandler);
    }

    handleLogoError() {
        this.showFallbackLogo = true;
    }

    toggleMenu() {
        this.menuOpen = !this.menuOpen;
    }

    navigateTo(event) {
        const page = event.currentTarget.dataset.page;
        this.menuOpen = false;
        this[NavigationMixin.Navigate](this._pageRef(page));
    }

    navigateHome() {
        this.menuOpen = false;
        this[NavigationMixin.Navigate](this._pageRef('home'));
    }

    _pageRef(page) {
        const pages = {
            home:    'Home',
            about:   'About__c',
            careers: 'Careers__c',
            contact: 'Contact__c',
            products: 'Products__c'
        };
        return {
            type: 'comm__namedPage',
            attributes: { name: pages[page] || 'Home' }
        };
    }
}