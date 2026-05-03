public with sharing class ImageAnalysisService {

    // ─── Prompt Template entry point ───────────────────────────────────────

    public static AnalysisResult analyzeWithPromptTemplate(String contentDocumentId, String storeId) {
        System.debug('### ImageAnalysisService.analyzeWithPromptTemplate called | contentDocumentId=' + contentDocumentId);

        Map<String, String> contentdocumentidMap = new Map<String, String>();
        contentdocumentidMap.put('id', contentDocumentId);

        ConnectApi.WrappedValue val = new ConnectApi.WrappedValue();
        val.value = contentdocumentidMap;

        Map<String, ConnectApi.WrappedValue> inputMap = new Map<String, ConnectApi.WrappedValue>();
        inputMap.put('Input:ContentDocumentID', val);

        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputMap;

        System.debug('### input for prompt template: ' + executeTemplateInput);

        ConnectApi.EinsteinPromptTemplateGenerationsRepresentation response =
            ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                'Shelf_Image_Analysis', executeTemplateInput
            );

        String ocrText = response.generations[0].text;
        System.debug('### analyzeWithPromptTemplate OCR response: ' + ocrText);

        AnalysisResult result = new AnalysisResult();
        result.detectedProducts      = new List<DetectedProduct>();
        result.detectedLabels        = new List<String>();
        result.competitorNameToBrand = new Map<String, String>();
        result.abcFoodsShelfShare    = 0;
        result.rawApiResponse     = ocrText;

        if (String.isNotBlank(ocrText)) {
            // Strip markdown code fences if present
            String cleaned = ocrText.trim();
            if (cleaned.startsWith('```')) {
                Integer firstNewline = cleaned.indexOf('\n');
                if (firstNewline > 0) cleaned = cleaned.substring(firstNewline + 1);
                if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length() - 3).trim();
            }

            // JSON path first, text section fallback
            if (cleaned.startsWith('{')) {
                try {
                    parseJsonResponse(cleaned, result);
                    System.debug('### analyzeWithPromptTemplate parsed via JSON path');
                } catch (Exception e) {
                    System.debug('### analyzeWithPromptTemplate JSON parse failed, falling back to text: ' + e.getMessage());
                    parseTextResponse(ocrText, result);
                }
            } else {
                parseTextResponse(ocrText, result);
            }
        }
        System.debug('### ImageAnalysisService.analyzeWithPromptTemplate COMPLETE | detectedLabels.size()=' + (result.detectedLabels != null ? result.detectedLabels.size() : 0));
        return result;
    }

    // ─── JSON response parser ──────────────────────────────────────────────

    @TestVisible
    private static void parseJsonResponse(String jsonText, AnalysisResult result) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonText);

        Map<String, Object> products   = (Map<String, Object>) root.get('products');
        Map<String, Object> shelfShare = (Map<String, Object>) root.get('shelfShare');

        if (products != null) {
            Map<String, Object> abcFoods = (Map<String, Object>) products.get('abcFoods');
            if (abcFoods != null) {

                // Present ABC products
                List<Object> present = (List<Object>) abcFoods.get('present');
                if (present != null && !present.isEmpty()) {
                    List<String> lines         = new List<String>();
                    List<String> issueLines    = new List<String>();
                    List<String> lowStockLines = new List<String>();
                    for (Object item : present) {
                        Map<String, Object> p = (Map<String, Object>) item;
                        Integer qty = toInteger(p.get('quantity'));
                        if (qty != null && qty <= 0) continue;
                        String name            = String.valueOf(p.get('productName')     != null ? p.get('productName')     : '');
                        String pos             = String.valueOf(p.get('shelfPosition')   != null ? p.get('shelfPosition')   : '');
                        String placementStatus = String.valueOf(p.get('placementStatus') != null ? p.get('placementStatus') : '');
                        String alertType       = String.valueOf(p.get('alertType')       != null ? p.get('alertType')       : '');
                        Object storeQtyObj     = p.get('storeQuantity');
                        if (String.isNotBlank(name)) {
                            lines.add(name);
                            if (placementStatus.equalsIgnoreCase('Needs Attention')) {
                                issueLines.add(name);
                            }
                            if (alertType.equalsIgnoreCase('LOW_STOCK')) {
                                lowStockLines.add(name);
                            }
                            DetectedProduct dp  = new DetectedProduct();
                            dp.label            = name;
                            dp.isABCFoods       = true;
                            dp.position         = pos;
                            dp.placementStatus  = placementStatus;
                            dp.confidence       = 1.0;
                            result.detectedProducts.add(dp);
                        }
                    }
                    if (!lines.isEmpty()) {
                        result.foundAbcProducts = String.join(lines, '\n');
                        result.foundAbcCount    = lines.size();
                    }
                    if (!issueLines.isEmpty()) {
                        result.placementIssues = String.join(issueLines, '\n');
                    }
                    if (!lowStockLines.isEmpty()) {
                        result.lowStockProducts = String.join(lowStockLines, '\n');
                    }
                }

                // Missing ABC products
                List<Object> missing = (List<Object>) abcFoods.get('missing');
                if (missing != null && !missing.isEmpty()) {
                    List<String> lines = new List<String>();
                    for (Object item : missing) {
                        String name;
                        if (item instanceof Map<String, Object>) {
                            name = String.valueOf(((Map<String, Object>) item).get('productName') != null ? ((Map<String, Object>) item).get('productName') : '');
                        } else {
                            name = String.valueOf(item != null ? item : '');
                        }
                        if (String.isNotBlank(name)) lines.add(name);
                    }
                    if (!lines.isEmpty()) {
                        result.missingAbcProducts = String.join(lines, '\n');
                        result.missingAbcCount    = lines.size();
                    }
                }
            }

            // Competitor products
            List<Object> competitors = (List<Object>) products.get('competitors');
            System.debug('### ImageAnalysisService.parseJsonResponse competitors list: ' + competitors);
            if (competitors != null && !competitors.isEmpty()) {
                System.debug('### ImageAnalysisService competitors.size()=' + competitors.size());
                List<String> lines = new List<String>();
                for (Object item : competitors) {
                    Map<String, Object> c = (Map<String, Object>) item;
                    String name  = String.valueOf(c.get('productName')  != null ? c.get('productName')  : '');
                    String brand = String.valueOf(c.get('brand')        != null ? c.get('brand')        : '');
                    System.debug('### ImageAnalysisService competitor item: name=' + name + ' | brand=' + brand);
                    if (String.isNotBlank(name)) {
                        lines.add(name);
                        result.detectedLabels.add(name);
                        if (String.isNotBlank(brand)) {
                            result.competitorNameToBrand.put(name, brand);
                        }
                        System.debug('### ImageAnalysisService added to detectedLabels: ' + name + (String.isNotBlank(brand) ? ' | brand: ' + brand : ''));
                    }
                }
                if (!lines.isEmpty()) {
                    result.competitorProductsText = String.join(lines, '\n');
                    System.debug('### ImageAnalysisService competitorProductsText=' + result.competitorProductsText);
                }
            } else {
                System.debug('### ImageAnalysisService competitors list is null or empty');
            }

            // Other products (non-competitor third-party)
            List<Object> otherProducts = (List<Object>) products.get('otherProducts');
            if (otherProducts != null && !otherProducts.isEmpty()) {
                List<String> lines = new List<String>();
                for (Object item : otherProducts) {
                    Map<String, Object> p = (Map<String, Object>) item;
                    String name  = String.valueOf(p.get('productName') != null ? p.get('productName') : '');
                    String brand = String.valueOf(p.get('brand')       != null ? p.get('brand')       : '');
                    if (String.isNotBlank(name)) {
                        lines.add(name);
                    }
                }
                if (!lines.isEmpty()) {
                    result.otherProductsText = String.join(lines, '\n');
                }
            }
        }

        if (shelfShare != null) {
            Map<String, Object> abcShare   = (Map<String, Object>) shelfShare.get('abcFoods');
            Map<String, Object> compShare  = (Map<String, Object>) shelfShare.get('competitors');
            Map<String, Object> otherShare = (Map<String, Object>) shelfShare.get('otherProducts');
            if (abcShare   != null) result.abcFoodsShelfShare  = toDecimal(abcShare.get('percentage'));
            if (compShare  != null) result.competitorShelfShare = toDecimal(compShare.get('percentage'));
            if (otherShare != null) result.otherShelfShare      = toDecimal(otherShare.get('percentage'));
        }

        System.debug('### JSON parse: foundAbcProducts=' + result.foundAbcProducts);
        System.debug('### JSON parse: missingAbcProducts=' + result.missingAbcProducts);
        System.debug('### JSON parse: competitorProductsText=' + result.competitorProductsText);
        System.debug('### JSON parse: abcFoodsShelfShare=' + result.abcFoodsShelfShare + ' | competitorShelfShare=' + result.competitorShelfShare);
    }

    // ─── Text section parser (legacy fallback) ─────────────────────────────

    private static void parseTextResponse(String ocrText, AnalysisResult result) {
        String extractedText     = extractSection(ocrText, 'EXTRACTED TEXT',            'ABC FOODS PRODUCTS FOUND');
        String abcSection        = extractSection(ocrText, 'ABC FOODS PRODUCTS FOUND',  'MISSING ABC FOODS PRODUCTS');
        if (String.isBlank(abcSection)) {
            abcSection           = extractSection(ocrText, 'ABC FOODS PRODUCTS FOUND',  'COMPETITOR PRODUCTS FOUND');
        }
        String missingSection    = extractSection(ocrText, 'MISSING ABC FOODS PRODUCTS','COMPETITOR PRODUCTS FOUND');
        String competitorSection = extractSection(ocrText, 'COMPETITOR PRODUCTS FOUND', 'SHELF SHARE');
        String shelfShareSect    = extractSection(ocrText, 'SHELF SHARE',               'COMPETITOR PRESENCE SUMMARY');

        if (String.isNotBlank(extractedText)) result.rawApiResponse = extractedText;

        result.foundAbcProducts   = normalizeSection(abcSection);
        result.missingAbcProducts = normalizeSection(missingSection);
        System.debug('### text parse foundAbcProducts=' + result.foundAbcProducts);
        System.debug('### text parse missingAbcProducts=' + result.missingAbcProducts);

        if (String.isNotBlank(competitorSection) && !competitorSection.trim().equalsIgnoreCase('None')) {
            result.competitorProductsText = competitorSection.trim();
            for (String line : competitorSection.split('\n')) {
                String l = line.trim().replaceAll('^[-*•|]+\\s*', '');
                if (String.isNotBlank(l) && !l.equalsIgnoreCase('None') && l.length() > 2) {
                    result.detectedLabels.add(l);
                }
            }
        }

        if (String.isNotBlank(shelfShareSect)) {
            try {
                Integer abcIdx = shelfShareSect.indexOfIgnoreCase('ABC Foods:');
                if (abcIdx >= 0) {
                    String afterAbc = shelfShareSect.substring(abcIdx + 'ABC Foods:'.length()).trim();
                    Integer pctIdx  = afterAbc.indexOf('%');
                    if (pctIdx > 0) {
                        result.abcFoodsShelfShare = Decimal.valueOf(afterAbc.substring(0, pctIdx).trim()).setScale(1);
                    }
                }
                Integer compIdx = shelfShareSect.indexOfIgnoreCase('Competitors:');
                if (compIdx >= 0) {
                    String afterComp = shelfShareSect.substring(compIdx + 'Competitors:'.length()).trim();
                    Integer pctIdx   = afterComp.indexOf('%');
                    if (pctIdx > 0) {
                        result.competitorShelfShare = Decimal.valueOf(afterComp.substring(0, pctIdx).trim()).setScale(1);
                    }
                }
            } catch (Exception e) {
                System.debug('### text parse shelf share error: ' + e.getMessage());
            }
        }
        
        System.debug('### ImageAnalysisService.parseJsonResponse COMPLETE | detectedLabels.size()=' + (result.detectedLabels != null ? result.detectedLabels.size() : 0) + ' | detectedLabels=' + result.detectedLabels);
        System.debug('### ImageAnalysisService result | foundAbcProducts=' + result.foundAbcProducts + ' | missingAbcProducts=' + result.missingAbcProducts + ' | competitorProductsText=' + result.competitorProductsText);
    }

    // ─── Helpers ───────────────────────────────────────────────────────────

    private static String extractSection(String fullText, String startHeader, String endHeader) {
        if (String.isBlank(fullText)) return '';
        Integer startIdx = fullText.indexOfIgnoreCase(startHeader);
        if (startIdx < 0) return '';
        startIdx += startHeader.length();
        if (endHeader != null) {
            Integer endIdx = fullText.indexOfIgnoreCase(endHeader, startIdx);
            return endIdx >= 0
                ? fullText.substring(startIdx, endIdx).trim()
                : fullText.substring(startIdx).trim();
        }
        return fullText.substring(startIdx).trim();
    }

    private static String normalizeSection(String raw) {
        if (String.isBlank(raw) || raw.trim().equalsIgnoreCase('None')) return null;
        return raw.trim();
    }

    public static Integer countItems(String section) {
        if (String.isBlank(section)) return 0;
        Integer count = 0;
        for (String line : section.split('\n')) {
            String l = line.trim().replaceAll('^[-*•|]+\\s*', '');
            if (String.isNotBlank(l) && !l.equalsIgnoreCase('None')) {
                count++;
            }
        }
        return count;
    }

    private static Decimal toDecimal(Object val) {
        if (val == null) return 0;
        try { return Decimal.valueOf(String.valueOf(val)).setScale(1); }
        catch (Exception e) { return 0; }
    }

    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { return Integer.valueOf(String.valueOf(val)); }
        catch (Exception e) { return null; }
    }

    // ─── Data classes ──────────────────────────────────────────────────────

    public class AnalysisResult {
        public List<DetectedProduct> detectedProducts;
        public List<String>          detectedLabels;
        public Map<String, String>   competitorNameToBrand;
        public Decimal               abcFoodsShelfShare;
        public Decimal               competitorShelfShare;
        public Decimal               otherShelfShare;
        public String                rawApiResponse;
        public String                competitorProductsText;
        public String                otherProductsText;
        public String                foundAbcProducts;
        public String                missingAbcProducts;
        public Integer               foundAbcCount;
        public Integer               missingAbcCount;
        public String                placementIssues; // newline-separated products flagged as "Needs Attention" by PT v9
        public String                lowStockProducts; // newline-separated products flagged as LOW_STOCK by PT
    }

    public class DetectedProduct {
        public String  label;
        public Decimal confidence;
        public Boolean isABCFoods;
        public String  position;
        public String  productCode;
        public String  placementStatus; // "Correct" or "Needs Attention" from PT v9
    }
}
