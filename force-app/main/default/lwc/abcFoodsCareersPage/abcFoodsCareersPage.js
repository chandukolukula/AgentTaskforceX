import { LightningElement, track } from 'lwc';

export default class AbcFoodsCareersPage extends LightningElement {
    @track showApplyModal = false;
    @track selectedRole = '';

    benefits = [
        { icon: '📈', title: 'Real Growth',         desc: 'Structured career paths with internal mobility across functions and geographies.' },
        { icon: '🏥', title: 'Health & Wellness',   desc: 'Comprehensive medical insurance covering self and family, plus mental health support.' },
        { icon: '🎓', title: 'Learning Budget',      desc: '₹30,000 annual learning allowance for courses, certifications, and conferences.' },
        { icon: '🍱', title: 'Daily Meals',          desc: 'Free breakfast and lunch at all office locations. Because we make food and we mean it.' },
        { icon: '🏠', title: 'Flexible Work',        desc: 'Hybrid model for eligible roles — 3 days in office, 2 days from anywhere.' },
        { icon: '🎁', title: 'ESOP Pool',            desc: 'Eligible senior hires receive stock options in our upcoming Series C round.' }
    ];

    cultureStats = [
        { value: '38%',  label: 'Women in Leadership' },
        { value: '4.4★', label: 'Glassdoor Rating' },
        { value: '92%',  label: 'Recommend to a Friend' },
        { value: '8 yr', label: 'Avg. Tenure (Senior Staff)' }
    ];

    openRoles = [
        {
            id: 1,
            title: 'Senior Brand Manager',
            department: 'Marketing',
            location: 'Bengaluru',
            type: 'Full-time',
            desc: 'Own the P&L and brand strategy for our Salty Snacks portfolio. Drive campaigns across ATL, BTL, and digital channels.',
            tags: ['FMCG', 'Brand Strategy', 'P&L Ownership', 'Digital Marketing']
        },
        {
            id: 2,
            title: 'Area Sales Manager — Modern Trade',
            department: 'Sales',
            location: 'Mumbai / Pune',
            type: 'Full-time',
            desc: 'Lead key account relationships with national supermarket chains. Drive distribution, visibility, and shelf share targets.',
            tags: ['Key Accounts', 'FMCG Sales', 'Modern Trade', 'Channel Strategy']
        },
        {
            id: 3,
            title: 'R&D Food Technologist',
            department: 'Product Development',
            location: 'Bengaluru (Mysore Road)',
            type: 'Full-time',
            desc: 'Formulate and commercialise new snack and confectionery products. Manage vendor qualification and shelf-life testing.',
            tags: ['Food Science', 'NPD', 'Sensory Analysis', 'Regulatory']
        },
        {
            id: 4,
            title: 'Supply Chain Analyst',
            department: 'Operations',
            location: 'Bengaluru',
            type: 'Full-time',
            desc: 'Optimise our nationwide distribution network. Build demand-sensing models and reduce stockout rates across 400+ partners.',
            tags: ['Supply Planning', 'SQL', 'Power BI', 'Logistics']
        },
        {
            id: 5,
            title: 'D2C Growth Manager',
            department: 'E-Commerce',
            location: 'Remote-first',
            type: 'Full-time',
            desc: 'Scale our direct-to-consumer channel across Amazon, Flipkart, Blinkit, and our own storefront. Own CAC and LTV metrics.',
            tags: ['E-Commerce', 'Performance Marketing', 'Retention', 'Analytics']
        },
        {
            id: 6,
            title: 'HR Business Partner',
            department: 'People & Culture',
            location: 'Bengaluru',
            type: 'Full-time',
            desc: 'Partner with senior leaders across Sales and Operations. Drive talent acquisition, engagement, and organisational effectiveness.',
            tags: ['HRBP', 'Talent Management', 'OD', 'FMCG HR']
        }
    ];

    get applyEmailHref() {
        return `mailto:careers@abcfoods.in?subject=Application – ${encodeURIComponent(this.selectedRole)}`;
    }

    handleApply(event) {
        event.preventDefault();
        this.selectedRole = event.currentTarget.dataset.role;
        this.showApplyModal = true;
    }

    closeModal() {
        this.showApplyModal = false;
        this.selectedRole = '';
    }
}