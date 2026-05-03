import { LightningElement, track } from 'lwc';
import { PRODUCTS, CATEGORY_THEMES, CATEGORIES } from 'c/abcFoodsProductImages';

const PAGE_SIZE = 12;

const CATEGORY_META = {
    'Salty Snacks':      { icon: '🌶️', short: 'Salty' },
    'Sweet Snacks':      { icon: '🍬', short: 'Sweet' },
    'Confectionery':     { icon: '🍫', short: 'Choc' },
    'Cookies & Biscuits':{ icon: '🍪', short: 'Cookies' },
    'Premium/Seasonal':  { icon: '⭐', short: 'Premium' },
    'Health Bars':       { icon: '💪', short: 'Health' },
    'Kids Range':        { icon: '🌈', short: 'Kids' }
};

export default class AbcFoodsHomeBody extends LightningElement {
    @track selectedCategory = 'all';
    @track visibleCount = PAGE_SIZE;

    get isAllSelected() {
        return this.selectedCategory === 'all';
    }

    get allBtnClass() {
        return `filter-btn${this.isAllSelected ? ' filter-btn-active' : ''}`;
    }

    get categoryFilters() {
        return CATEGORIES.map(cat => {
            const count = PRODUCTS.filter(p => p.category === cat).length;
            const meta = CATEGORY_META[cat] || { icon: '', short: cat };
            return {
                value: cat,
                label: cat,
                icon: meta.icon,
                count,
                isActive: this.selectedCategory === cat,
                btnClass: `filter-btn${this.selectedCategory === cat ? ' filter-btn-active' : ''}`
            };
        });
    }

    get filteredProductList() {
        const base = this.isAllSelected
            ? PRODUCTS
            : PRODUCTS.filter(p => p.category === this.selectedCategory);

        return base.map(p => {
            const theme = CATEGORY_THEMES[p.category] || {};
            const meta = CATEGORY_META[p.category] || {};
            const words = p.name.split(' ');
            const mid = Math.ceil(words.length / 2);
            const padded = String(p.id).padStart(2, '0');
            return {
                ...p,
                imageUrl: `/sfsites/c/resource/abcProd_${padded}?v=2`,
                nameLine1: words.slice(0, mid).join(' '),
                nameLine2: words.slice(mid).join(' ') || '',
                categoryShort: meta.short || p.category,
                badgeStyle: `background: ${theme.badgeColor || '#333'}; color: ${theme.badgeText || '#fff'};`,
                shopBtnStyle: `background: ${theme.color1 || '#ff5a2b'};`
            };
        });
    }

    get filteredCount() {
        return this.filteredProductList.length;
    }

    get totalCount() {
        return PRODUCTS.length;
    }

    get displayedProducts() {
        return this.filteredProductList.slice(0, this.visibleCount);
    }

    get hasMore() {
        return this.visibleCount < this.filteredProductList.length;
    }

    get remainingCount() {
        return this.filteredProductList.length - this.visibleCount;
    }

    handleFilter(event) {
        const cat = event.currentTarget.dataset.category;
        this.selectedCategory = cat;
        this.visibleCount = PAGE_SIZE;
        this.scrollToProducts();
    }

    handleLoadMore() {
        this.visibleCount = Math.min(
            this.visibleCount + PAGE_SIZE,
            this.filteredProductList.length
        );
    }

    handleShopNow(event) {
        const { id, name } = event.currentTarget.dataset;
        this.dispatchEvent(
            new CustomEvent('shopnow', {
                detail: { productId: id, productName: name },
                bubbles: true,
                composed: true
            })
        );
    }

    handleImgError(event) {
        event.currentTarget.style.display = 'none';
    }

    scrollToProducts() {
        const section = this.template.querySelector('.products-section');
        if (section) {
            section.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
    }
}