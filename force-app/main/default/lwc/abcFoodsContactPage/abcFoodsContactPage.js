import { LightningElement, track } from 'lwc';

export default class AbcFoodsContactPage extends LightningElement {
    @track formData = {
        firstName: '', lastName: '', email: '',
        phone: '', subject: '', message: ''
    };
    @track formSubmitted = false;
    @track hasError = false;
    @track errorMessage = '';
    @track touched = {};

    contactCards = [
        {
            icon: '📍',
            title: 'Head Office',
            value: '14th Floor, Brigade Gateway',
            sub: 'Rajajinagar, Bengaluru 560 055'
        },
        {
            icon: '📞',
            title: 'Phone',
            value: '+91 80 4568 9100',
            sub: 'Mon – Fri, 9 AM – 6 PM IST'
        },
        {
            icon: '✉️',
            title: 'Email',
            value: 'hello@abcfoods.in',
            sub: 'Response within 1 business day'
        },
        {
            icon: '🏭',
            title: 'Manufacturing',
            value: 'Mysore Road Industrial Area',
            sub: 'Bengaluru 562 130 (no walk-ins)'
        }
    ];

    get firstNameClass() { return this._inputClass('firstName'); }
    get lastNameClass()  { return this._inputClass('lastName'); }
    get emailClass()     { return this._inputClass('email'); }
    get subjectClass()   { return this._inputClass('subject', 'form-select'); }
    get messageClass()   { return this._inputClass('message', 'form-textarea'); }

    _inputClass(field, base = 'form-input') {
        if (!this.touched[field]) return base;
        return `${base}${this._valid(field) ? '' : ' input-error'}`;
    }

    _valid(field) {
        const v = this.formData[field];
        if (field === 'email') return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
        return v && v.trim().length > 0;
    }

    handleInput(event) {
        const { field } = event.currentTarget.dataset;
        this.formData = { ...this.formData, [field]: event.target.value };
        this.touched = { ...this.touched, [field]: true };
        if (this.hasError) this.hasError = false;
    }

    handleSubmit(event) {
        event.preventDefault();
        const required = ['firstName', 'lastName', 'email', 'subject', 'message'];
        const allTouched = {};
        required.forEach(f => { allTouched[f] = true; });
        this.touched = { ...this.touched, ...allTouched };

        const invalid = required.filter(f => !this._valid(f));
        if (invalid.length > 0) {
            this.hasError = true;
            this.errorMessage = 'Please fill in all required fields correctly.';
            return;
        }

        this.formSubmitted = true;
        this.hasError = false;
    }

    handleReset() {
        this.formData = { firstName: '', lastName: '', email: '', phone: '', subject: '', message: '' };
        this.formSubmitted = false;
        this.touched = {};
        this.hasError = false;
    }
}