import { LightningElement, track } from 'lwc';

export default class GoogleVision extends LightningElement {
    imageUrl = '';
    analysisResult = '';
    imageBase64 = '';

    @track rawApiResponse = '';
    @track showRawResponse = true;

    get rawResponseLabel() { return this.showRawResponse ? 'Hide ▲' : 'Show ▼'; }
    toggleRawResponse() { this.showRawResponse = !this.showRawResponse; }

    handleImageUpload(event) {
        const file = event.target.files[0];
        console.log('[GoogleVision] handleImageUpload — file:', file?.name, '| size:', file?.size, 'bytes | type:', file?.type);
        if (file) {
            const reader = new FileReader();
            reader.onloadend = () => {
                this.imageBase64 = reader.result.split(',')[1];
                this.imageUrl = reader.result;
                console.log('[GoogleVision] FileReader onloadend — base64 length:', this.imageBase64?.length);
            };
            reader.readAsDataURL(file);
        } else {
            console.warn('[GoogleVision] handleImageUpload — no file selected');
        }
    }

    handleAnalyzeImage() {
        console.log('[GoogleVision] handleAnalyzeImage — Google Vision API has been removed');
        this.analysisResult = 'Google Vision API has been removed.';
    }

    handleCancel() {
        console.log('[GoogleVision] handleCancel — clearing state');
        this.imageUrl = '';
        this.analysisResult = '';
        this.imageBase64 = '';
        this.rawApiResponse = '';
    }
}