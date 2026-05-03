import { LightningElement } from 'lwc';

export default class AbcFoodsAboutPage extends LightningElement {
    milestones = [
        { year: '1998', text: 'Founded in Bangalore. First products reach local kirana stores across South India.' },
        { year: '2003', text: 'Launched the Cookies & Biscuits line. Entered Maharashtra and Andhra Pradesh.' },
        { year: '2008', text: 'National distribution network established. Crossed 10,000 retail touchpoints.' },
        { year: '2013', text: 'Premium/Seasonal gifting range launched. First year of Diwali hamper collections.' },
        { year: '2018', text: 'Health Bars and reduced-sugar lines introduced. E-commerce channel opened.' },
        { year: '2023', text: '48 product SKUs. 60,000+ retail outlets. 400+ distribution partners nationwide.' }
    ];

    values = [
        {
            icon: '🌿',
            title: 'Clean Ingredients',
            desc: 'No artificial colours or preservatives. We source from trusted ingredient partners and are transparent about what goes into every pack.'
        },
        {
            icon: '🏭',
            title: 'Made in India',
            desc: 'Every product is manufactured in India with locally sourced ingredients, supporting domestic farmers and the agri-food ecosystem.'
        },
        {
            icon: '💡',
            title: 'Practical Innovation',
            desc: 'We innovate based on real consumer needs — not trends. Every new product line starts with kitchen-table research and honest taste testing.'
        },
        {
            icon: '🤝',
            title: 'Community First',
            desc: 'Long-term relationships with local farmers, packaging partners, and kirana owners are the backbone of our supply chain.'
        },
        {
            icon: '📦',
            title: 'Consistent Quality',
            desc: 'Every batch is held to the same rigorous standard. We invest in quality control so that every purchase feels like the first great one.'
        },
        {
            icon: '♻️',
            title: 'Responsible Packaging',
            desc: 'We are progressively moving toward recyclable and reduced-plastic packaging as part of our sustainability roadmap for 2030.'
        }
    ];

    stats = [
        { value: '1998', label: 'Founded' },
        { value: '25+',  label: 'Years of Market Presence' },
        { value: '48',   label: 'Product SKUs' },
        { value: '7',    label: 'Product Categories' },
        { value: '60K+', label: 'Retail Outlets' },
        { value: '400+', label: 'Distribution Partners' }
    ];

    pillars = [
        { icon: '🔬', title: 'Science-Backed Nutrition', desc: 'Nutritionists review every formulation before launch.' },
        { icon: '🌾', title: 'Responsible Sourcing',   desc: 'We work with certified and traceable ingredient suppliers.' },
        { icon: '📊', title: 'Transparent Labelling',  desc: 'Clear, honest ingredient and nutrition information on every pack.' },
        { icon: '🌍', title: 'Local Impact',           desc: 'Thousands of livelihoods supported through our supply network.' }
    ];
}