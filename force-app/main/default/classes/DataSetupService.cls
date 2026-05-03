/**
 * One-shot data setup class for demo environment.
 * Run via: DataSetupService.runSetup();
 */
public without sharing class DataSetupService {

    public static void runSetup() {
        updateProductPlanogramFields();
        insertCompetitorProducts();
        createPricebookEntries();
        createOperatingAndVisitHours();
        createTodayVisits();
        System.debug('=== DataSetupService.runSetup() complete ===');
    }

    private static void updateProductPlanogramFields() {
        Map<String, String> positions = new Map<String, String>{
            'ABCF-SM-500' => 'Eye Level - Shelf 2',
            'ABCF-CB-200' => 'Eye Level - Shelf 2',
            'ABCF-PS-300' => 'Eye Level - Shelf 2',
            'ABCF-MB-150' => 'Shelf 3 - Mid Level',
            'ABCF-CP-150' => 'Shelf 1 - Top',
            'ABCF-PM-400' => 'Bottom Shelf - Shelf 4',
            'ABCF-DC-100' => 'Checkout Lane Display',
            'ABCF-SM-250' => 'Eye Level - Shelf 2'
        };
        Map<String, Integer> facings = new Map<String, Integer>{
            'ABCF-SM-500' => 4, 'ABCF-CB-200' => 3, 'ABCF-PS-300' => 3,
            'ABCF-MB-150' => 2, 'ABCF-CP-150' => 2, 'ABCF-PM-400' => 2,
            'ABCF-DC-100' => 6, 'ABCF-SM-250' => 3
        };
        List<Product2> prods = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'ABCF-%'];
        for (Product2 p : prods) {
            p.Planogram_Position__c = positions.get(p.ProductCode);
            p.Expected_Facings__c   = facings.get(p.ProductCode);
        }
        update prods;
        System.debug('Updated ' + prods.size() + ' product planogram fields.');
    }

    private static void insertCompetitorProducts() {
        Integer existing = [SELECT COUNT() FROM CompetitorProduct__c];
        if (existing > 0) { System.debug('Competitor products already loaded. Skipping.'); return; }

        List<CompetitorProduct__c> comps = new List<CompetitorProduct__c>{
            new CompetitorProduct__c(Name='Lays Classic 200g',         CompetitorBrand__c='Lays (PepsiCo)',       Category__c='Salty Snacks',  ProductSKU__c='COMP-LAYS-200', IsActive__c=true, AIDetectionKeywords__c='lays, lay\'s, pepsico chips, classic potato'),
            new CompetitorProduct__c(Name='Doritos Nacho Cheese 180g', CompetitorBrand__c='Doritos (PepsiCo)',    Category__c='Salty Snacks',  ProductSKU__c='COMP-DOR-180',  IsActive__c=true, AIDetectionKeywords__c='doritos, nacho, tortilla chips, frito lay'),
            new CompetitorProduct__c(Name='Pringles Original 165g',    CompetitorBrand__c='Pringles (Kellanova)', Category__c='Salty Snacks',  ProductSKU__c='COMP-PRG-165',  IsActive__c=true, AIDetectionKeywords__c='pringles, pringle, tube chips, kellanova'),
            new CompetitorProduct__c(Name='KitKat Chunky 40g',         CompetitorBrand__c='KitKat (Nestle)',      Category__c='Confectionery', ProductSKU__c='COMP-KK-40',    IsActive__c=true, AIDetectionKeywords__c='kitkat, kit kat, nestle chocolate, wafer bar'),
            new CompetitorProduct__c(Name='Snickers Bar 50g',          CompetitorBrand__c='Snickers (Mars)',      Category__c='Confectionery', ProductSKU__c='COMP-SNK-50',   IsActive__c=true, AIDetectionKeywords__c='snickers, mars bar, caramel peanut chocolate'),
            new CompetitorProduct__c(Name='Cheetos Crunchy 180g',      CompetitorBrand__c='Cheetos (PepsiCo)',    Category__c='Salty Snacks',  ProductSKU__c='COMP-CHT-180',  IsActive__c=true, AIDetectionKeywords__c='cheetos, chester cheetah, cheese puffs frito'),
            new CompetitorProduct__c(Name='Oreo Original 154g',        CompetitorBrand__c='Oreo (Mondelez)',      Category__c='Biscuits',      ProductSKU__c='COMP-ORE-154',  IsActive__c=true, AIDetectionKeywords__c='oreo, mondelez, sandwich cookie, nabisco'),
            new CompetitorProduct__c(Name='Ruffles Sour Cream 184g',   CompetitorBrand__c='Ruffles (PepsiCo)',    Category__c='Salty Snacks',  ProductSKU__c='COMP-RUF-184',  IsActive__c=true, AIDetectionKeywords__c='ruffles, ridged chips, sour cream onion')
        };
        insert comps;
        System.debug('Inserted ' + comps.size() + ' competitor products.');
    }

    private static void createPricebookEntries() {
        List<Product2> prods = [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'ABCF-%'];
        if (prods.isEmpty()) { System.debug('No ABCF products found.'); return; }

        List<Pricebook2> pbs = [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true LIMIT 1];
        if (pbs.isEmpty()) { System.debug('Standard pricebook not found. Skipping pricebook entries.'); return; }
        Id stdPricebook = pbs[0].Id;

        Set<Id> alreadyEntried = new Set<Id>();
        for (PricebookEntry pbe : [SELECT Product2Id FROM PricebookEntry WHERE Product2Id IN :new Map<Id,Product2>(prods).keySet()]) {
            alreadyEntried.add(pbe.Product2Id);
        }
        Map<String, Decimal> priceMap = new Map<String, Decimal>{
            'ABCF-SM-500' => 4.99, 'ABCF-CB-200' => 2.49, 'ABCF-PS-300' => 5.49,
            'ABCF-MB-150' => 1.99, 'ABCF-CP-150' => 1.79, 'ABCF-PM-400' => 6.99,
            'ABCF-DC-100' => 2.99, 'ABCF-SM-250' => 2.99
        };
        List<PricebookEntry> entries = new List<PricebookEntry>();
        for (Product2 p : prods) {
            if (!alreadyEntried.contains(p.Id)) {
                entries.add(new PricebookEntry(
                    Pricebook2Id = stdPricebook,
                    Product2Id   = p.Id,
                    UnitPrice    = priceMap.containsKey(p.ProductCode) ? priceMap.get(p.ProductCode) : 3.99,
                    IsActive     = true
                ));
            }
        }
        if (!entries.isEmpty()) insert entries;
        System.debug('Created ' + entries.size() + ' pricebook entries.');
    }

    private static void createOperatingAndVisitHours() {
        List<RetailStore> stores = [
            SELECT Id, Name, OperatingHoursId, PreferredVisitHoursId
            FROM   RetailStore
            WHERE  Name IN ('Metro Hypermarket - Downtown', 'FreshMart - Westside',
                            'QuickStop Convenience - Midtown', 'SuperSave - Northside')
        ];
        if (stores.isEmpty()) { System.debug('No matching RetailStores found. Skipping.'); return; }

        /*
         * Set A — Metro Hypermarket - Downtown & QuickStop Convenience - Midtown
         *   Operating Hours : Mon–Sun 07:00–22:00  (extended / convenience hours)
         *   Preferred Visit : Mon–Sat 07:30–10:00  (early-morning rep window before peak traffic)
         *
         * Set B — FreshMart - Westside & SuperSave - Northside
         *   Operating Hours : Mon–Fri 09:00–20:00, Sat 09:00–18:00, Sun 10:00–16:00
         *   Preferred Visit : Tue–Thu 10:00–13:00  (mid-week midday rep window)
         */
        Set<String> setAStores = new Set<String>{
            'Metro Hypermarket - Downtown',
            'QuickStop Convenience - Midtown'
        };

        List<String> allWeek   = new List<String>{ 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday' };
        List<String> weekdays  = new List<String>{ 'Monday','Tuesday','Wednesday','Thursday','Friday' };
        List<String> midWeek   = new List<String>{ 'Tuesday','Wednesday','Thursday' };

        List<OperatingHours> ohToInsert  = new List<OperatingHours>();
        List<OperatingHours> pvhToInsert = new List<OperatingHours>();

        for (RetailStore s : stores) {
            if (s.OperatingHoursId == null) {
                ohToInsert.add(new OperatingHours(
                    Name     = s.Name + ' - Operating Hours',
                    TimeZone = 'Asia/Kolkata'
                ));
            }
            if (s.PreferredVisitHoursId == null) {
                pvhToInsert.add(new OperatingHours(
                    Name     = s.Name + ' - Preferred Visit Hours',
                    TimeZone = 'Asia/Kolkata'
                ));
            }
        }

        if (!ohToInsert.isEmpty())  insert ohToInsert;
        if (!pvhToInsert.isEmpty()) insert pvhToInsert;

        Map<String, Id> ohMap  = new Map<String, Id>();
        Map<String, Id> pvhMap = new Map<String, Id>();
        for (OperatingHours oh : ohToInsert)  ohMap.put(oh.Name.replace(' - Operating Hours', ''),       oh.Id);
        for (OperatingHours pv : pvhToInsert) pvhMap.put(pv.Name.replace(' - Preferred Visit Hours', ''), pv.Id);

        List<TimeSlot> slots = new List<TimeSlot>();

        for (RetailStore s : stores) {
            Id ohId  = ohMap.containsKey(s.Name)  ? ohMap.get(s.Name)  : s.OperatingHoursId;
            Id pvhId = pvhMap.containsKey(s.Name) ? pvhMap.get(s.Name) : s.PreferredVisitHoursId;
            Boolean isSetA = setAStores.contains(s.Name);

            if (ohId != null) {
                if (isSetA) {
                    // Set A: every day 07:00–22:00
                    for (String day : allWeek) {
                        slots.add(new TimeSlot(
                            OperatingHoursId = ohId,
                            DayOfWeek        = day,
                            StartTime        = Time.newInstance(7, 0, 0, 0),
                            EndTime          = Time.newInstance(22, 0, 0, 0),
                            Type             = 'Normal'
                        ));
                    }
                } else {
                    // Set B: Mon–Fri 09:00–20:00
                    for (String day : weekdays) {
                        slots.add(new TimeSlot(
                            OperatingHoursId = ohId,
                            DayOfWeek        = day,
                            StartTime        = Time.newInstance(9, 0, 0, 0),
                            EndTime          = Time.newInstance(20, 0, 0, 0),
                            Type             = 'Normal'
                        ));
                    }
                    // Set B: Sat 09:00–18:00
                    slots.add(new TimeSlot(
                        OperatingHoursId = ohId,
                        DayOfWeek        = 'Saturday',
                        StartTime        = Time.newInstance(9, 0, 0, 0),
                        EndTime          = Time.newInstance(18, 0, 0, 0),
                        Type             = 'Normal'
                    ));
                    // Set B: Sun 10:00–16:00
                    slots.add(new TimeSlot(
                        OperatingHoursId = ohId,
                        DayOfWeek        = 'Sunday',
                        StartTime        = Time.newInstance(10, 0, 0, 0),
                        EndTime          = Time.newInstance(16, 0, 0, 0),
                        Type             = 'Normal'
                    ));
                }
            }

            if (pvhId != null) {
                if (isSetA) {
                    // Set A: Mon–Sat 07:30–10:00
                    List<String> setAVisitDays = new List<String>{ 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday' };
                    for (String day : setAVisitDays) {
                        slots.add(new TimeSlot(
                            OperatingHoursId = pvhId,
                            DayOfWeek        = day,
                            StartTime        = Time.newInstance(7, 30, 0, 0),
                            EndTime          = Time.newInstance(10, 0, 0, 0),
                            Type             = 'Normal'
                        ));
                    }
                } else {
                    // Set B: Tue–Thu 10:00–13:00
                    for (String day : midWeek) {
                        slots.add(new TimeSlot(
                            OperatingHoursId = pvhId,
                            DayOfWeek        = day,
                            StartTime        = Time.newInstance(10, 0, 0, 0),
                            EndTime          = Time.newInstance(13, 0, 0, 0),
                            Type             = 'Normal'
                        ));
                    }
                }
            }
        }

        if (!slots.isEmpty()) insert slots;

        List<RetailStore> toUpdate = new List<RetailStore>();
        for (RetailStore s : stores) {
            Boolean changed = false;
            if (s.OperatingHoursId == null && ohMap.containsKey(s.Name)) {
                s.OperatingHoursId = ohMap.get(s.Name);
                changed = true;
            }
            if (s.PreferredVisitHoursId == null && pvhMap.containsKey(s.Name)) {
                s.PreferredVisitHoursId = pvhMap.get(s.Name);
                changed = true;
            }
            if (changed) toUpdate.add(s);
        }
        if (!toUpdate.isEmpty()) update toUpdate;

        System.debug('Created OperatingHours for ' + ohToInsert.size() + ' stores, PreferredVisitHours for ' + pvhToInsert.size() + ' stores, ' + slots.size() + ' TimeSlots total.');
    }

    private static void createTodayVisits() {
        Integer existingToday = [SELECT COUNT() FROM Visit
            WHERE OwnerId = :UserInfo.getUserId()
              AND PlannedVisitStartTime >= :DateTime.newInstance(Date.today(), Time.newInstance(0,0,0,0))
        ];
        if (existingToday > 0) { System.debug('Visits already exist for today. Skipping.'); return; }

        List<RetailStore> stores = [
            SELECT Id, Name FROM RetailStore
            WHERE Name IN ('Metro Hypermarket - Downtown','FreshMart - Westside',
                           'QuickStop Convenience - Midtown','SuperSave - Northside')
            ORDER BY Name ASC
        ];
        List<Visit> visits = new List<Visit>();
        Integer hour = 9;
        for (RetailStore s : stores) {
            visits.add(new Visit(
                OwnerId               = UserInfo.getUserId(),
                PlaceId               = s.Id,
                Status                = 'Planned',
                PlannedVisitStartTime = DateTime.newInstance(Date.today(), Time.newInstance(hour, 0, 0, 0)),
                PlannedVisitEndTime   = DateTime.newInstance(Date.today(), Time.newInstance(hour + 1, 0, 0, 0))
            ));
            hour += 2;
        }
        if (!visits.isEmpty()) insert visits;
        System.debug('Created ' + visits.size() + ' visits for today.');
    }
}