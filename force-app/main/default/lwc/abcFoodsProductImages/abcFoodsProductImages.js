const CATEGORY_THEMES = {
    'Salty Snacks': {
        color1: '#FF8C00',
        color2: '#B22200',
        accent: '#FFD700',
        badgeColor: '#B22200',
        badgeText: '#FFFFFF',
        resourceName: 'abcProdCat_SaltySnacks'
    },
    'Sweet Snacks': {
        color1: '#E91E63',
        color2: '#7B0040',
        accent: '#FFCDD2',
        badgeColor: '#7B0040',
        badgeText: '#FFFFFF',
        resourceName: 'abcProdCat_SweetSnacks'
    },
    'Confectionery': {
        color1: '#6A1B9A',
        color2: '#1A0035',
        accent: '#CE93D8',
        badgeColor: '#1A0035',
        badgeText: '#CE93D8',
        resourceName: 'abcProdCat_Confectionery'
    },
    'Cookies & Biscuits': {
        color1: '#8D6E63',
        color2: '#3E2723',
        accent: '#FFCC80',
        badgeColor: '#3E2723',
        badgeText: '#FFCC80',
        resourceName: 'abcProdCat_CookiesBiscuits'
    },
    'Premium/Seasonal': {
        color1: '#8B6914',
        color2: '#2A1800',
        accent: '#FFD700',
        badgeColor: '#2A1800',
        badgeText: '#FFD700',
        resourceName: 'abcProdCat_PremiumRange'
    },
    'Health Bars': {
        color1: '#2E7D32',
        color2: '#0D3B0F',
        accent: '#A5D6A7',
        badgeColor: '#0D3B0F',
        badgeText: '#A5D6A7',
        resourceName: 'abcProdCat_HealthBars'
    },
    'Kids Range': {
        color1: '#FF5722',
        color2: '#8B1700',
        accent: '#FFF176',
        badgeColor: '#8B1700',
        badgeText: '#FFF176',
        resourceName: 'abcProdCat_KidsRange'
    }
};

const PRODUCTS = [
    {
        id: 1, name: 'SpicyMix Crunch', category: 'Salty Snacks',
        price: 45, weight: '120g',
        description: 'Fiery spiced mixed snack with a satisfying crunch in every bite.'
    },
    {
        id: 2, name: 'CrunchBits Original', category: 'Salty Snacks',
        price: 35, weight: '100g',
        description: 'Classic original-flavored crunchy bite-sized snacks for everyday snacking.'
    },
    {
        id: 3, name: 'Cheese Puffs Classic', category: 'Salty Snacks',
        price: 40, weight: '80g',
        description: 'Light and airy cheese-flavored puffs with a melt-in-your-mouth texture.'
    },
    {
        id: 4, name: 'Party Mix Variety', category: 'Salty Snacks',
        price: 120, weight: '350g',
        description: 'Assorted salty snack mix — perfect for sharing at any gathering.'
    },
    {
        id: 5, name: 'Premium Sweets Assortment', category: 'Sweet Snacks',
        price: 180, weight: '400g',
        description: 'A curated selection of premium sweet treats for gifting or indulging.'
    },
    {
        id: 6, name: 'Mango Bites Gummy', category: 'Sweet Snacks',
        price: 55, weight: '150g',
        description: 'Sun-ripened mango flavored gummies that burst with tropical sweetness.'
    },
    {
        id: 7, name: 'Dark Chocolate Bites', category: 'Confectionery',
        price: 75, weight: '100g',
        description: 'Rich, intense dark chocolate pieces crafted for true chocolate lovers.'
    },
    {
        id: 8, name: 'CrunchBits BBQ', category: 'Salty Snacks',
        price: 38, weight: '100g',
        description: 'Smoky BBQ-flavored crunch bites inspired by slow-grilled perfection.'
    },
    {
        id: 9, name: 'CrunchBits Sour Cream', category: 'Salty Snacks',
        price: 38, weight: '100g',
        description: 'Tangy sour cream and onion flavored bites with an irresistible zing.'
    },
    {
        id: 10, name: 'Nacho Cheese Triangles', category: 'Salty Snacks',
        price: 42, weight: '110g',
        description: 'Triangle-shaped nacho crisps loaded with bold cheddar cheese flavor.'
    },
    {
        id: 11, name: 'Salted Potato Crisps', category: 'Salty Snacks',
        price: 36, weight: '90g',
        description: 'Thinly sliced, perfectly salted potato crisps with a satisfying snap.'
    },
    {
        id: 12, name: 'Onion Rings Crispy', category: 'Salty Snacks',
        price: 40, weight: '90g',
        description: 'Crunchy, onion-flavored ring snacks that deliver bold savory flavor.'
    },
    {
        id: 13, name: 'Veggie Mix Chips', category: 'Salty Snacks',
        price: 48, weight: '100g',
        description: 'Colorful vegetable chips — beetroot, spinach, carrot — lightly seasoned.'
    },
    {
        id: 14, name: 'Masala Munch', category: 'Salty Snacks',
        price: 35, weight: '80g',
        description: 'Indian-spiced masala snack with a complex blend of aromatic spices.'
    },
    {
        id: 15, name: 'Cheese Puffs XL', category: 'Salty Snacks',
        price: 65, weight: '200g',
        description: 'Extra-large family-size cheese puffs pack — more to share, more to love.'
    },
    {
        id: 16, name: 'Party Mix Family', category: 'Salty Snacks',
        price: 150, weight: '500g',
        description: 'Jumbo family value pack of mixed salty snacks for big celebrations.'
    },
    {
        id: 17, name: 'Caramel Toffee Chews', category: 'Sweet Snacks',
        price: 60, weight: '150g',
        description: 'Buttery caramel toffee with a chewy center and smooth finish.'
    },
    {
        id: 18, name: 'Fruit Burst Gummies', category: 'Sweet Snacks',
        price: 50, weight: '120g',
        description: 'Assorted tropical fruit gummies that burst with real fruit juice flavor.'
    },
    {
        id: 19, name: 'Strawberry Jellies', category: 'Sweet Snacks',
        price: 45, weight: '100g',
        description: 'Soft, sweet strawberry jelly candies with a natural berry aroma.'
    },
    {
        id: 20, name: 'Orange Citrus Candies', category: 'Sweet Snacks',
        price: 40, weight: '100g',
        description: 'Zesty orange hard candies with a refreshing citrus burst in every piece.'
    },
    {
        id: 21, name: 'Mint Fresh Drops', category: 'Sweet Snacks',
        price: 35, weight: '80g',
        description: 'Cool, refreshing mint drops that leave a clean, long-lasting freshness.'
    },
    {
        id: 22, name: 'Chocolate Cream Wafers', category: 'Sweet Snacks',
        price: 55, weight: '120g',
        description: 'Crispy wafer layers filled with smooth, indulgent chocolate cream.'
    },
    {
        id: 23, name: 'Milk Chocolate Bar', category: 'Confectionery',
        price: 65, weight: '90g',
        description: 'Velvety smooth milk chocolate with a rich, creamy cocoa flavor.'
    },
    {
        id: 24, name: 'Dark Chocolate Bar', category: 'Confectionery',
        price: 70, weight: '90g',
        description: 'Intense 70% dark chocolate bar for the sophisticated palate.'
    },
    {
        id: 25, name: 'White Chocolate Dreams', category: 'Confectionery',
        price: 70, weight: '90g',
        description: 'Delicate white chocolate infused with vanilla for a dreamy sweetness.'
    },
    {
        id: 26, name: 'Mixed Candy Jar', category: 'Confectionery',
        price: 130, weight: '400g',
        description: 'A colorful assorted candy jar — the perfect treat for home or office.'
    },
    {
        id: 27, name: 'Butter Cookies Classic', category: 'Cookies & Biscuits',
        price: 55, weight: '150g',
        description: 'Traditional golden butter cookies with a rich, crumbly texture.'
    },
    {
        id: 28, name: 'Chocolate Chip Cookies', category: 'Cookies & Biscuits',
        price: 60, weight: '150g',
        description: 'Soft-baked cookies packed with generous chocolate chips in every bite.'
    },
    {
        id: 29, name: 'Coconut Crunch Biscuits', category: 'Cookies & Biscuits',
        price: 50, weight: '150g',
        description: 'Crispy biscuits with toasted coconut flakes for a tropical crunch.'
    },
    {
        id: 30, name: 'Oatmeal Raisin Cookies', category: 'Cookies & Biscuits',
        price: 58, weight: '160g',
        description: 'Hearty oatmeal cookies loaded with plump, juicy raisins.'
    },
    {
        id: 31, name: 'Cream Sandwich Biscuits', category: 'Cookies & Biscuits',
        price: 52, weight: '140g',
        description: 'Crunchy biscuit sandwiches filled with smooth vanilla cream.'
    },
    {
        id: 32, name: 'Digestive Wheat Biscuits', category: 'Cookies & Biscuits',
        price: 48, weight: '200g',
        description: 'Wholesome whole-wheat digestive biscuits, lightly sweetened.'
    },
    {
        id: 33, name: 'Festive Gift Box Assortment', category: 'Premium/Seasonal',
        price: 350, weight: '500g',
        description: 'Luxurious gift box curated with premium ABC Foods festive favourites.'
    },
    {
        id: 34, name: 'Executive Selection Chocolates', category: 'Premium/Seasonal',
        price: 450, weight: '400g',
        description: 'An elegant chocolate collection ideal for corporate gifting.'
    },
    {
        id: 35, name: 'Holiday Special Mix', category: 'Premium/Seasonal',
        price: 280, weight: '450g',
        description: 'Festive holiday season snack mix with seasonal flavors and cheer.'
    },
    {
        id: 36, name: 'Luxury Truffle Collection', category: 'Premium/Seasonal',
        price: 500, weight: '300g',
        description: 'Handcrafted chocolate truffles in a signature premium gift box.'
    },
    {
        id: 37, name: 'Gourmet Nut Clusters', category: 'Premium/Seasonal',
        price: 380, weight: '350g',
        description: 'Premium mixed nuts enrobed in caramel and dark chocolate clusters.'
    },
    {
        id: 38, name: 'Artisan Cookie Box', category: 'Premium/Seasonal',
        price: 320, weight: '400g',
        description: 'Small-batch artisan cookies in six varieties, elegantly boxed.'
    },
    {
        id: 39, name: 'PowerPro Protein Bar', category: 'Health Bars',
        price: 95, weight: '60g',
        description: 'High-protein performance bar with 20g protein for active lifestyles.'
    },
    {
        id: 40, name: 'Energy Boost Bar', category: 'Health Bars',
        price: 85, weight: '60g',
        description: 'Natural energy bar with dates, nuts, and slow-release carbohydrates.'
    },
    {
        id: 41, name: 'Granola Crunch Bar', category: 'Health Bars',
        price: 80, weight: '60g',
        description: 'Wholesome granola bar with mixed seeds, honey, and oat clusters.'
    },
    {
        id: 42, name: 'Nutri-Grain Bar', category: 'Health Bars',
        price: 78, weight: '55g',
        description: 'Nutritious multi-grain bar with a real fruit filling inside.'
    },
    {
        id: 43, name: 'FitBite Energy', category: 'Health Bars',
        price: 90, weight: '55g',
        description: 'Compact energy bite with superfoods for on-the-go fitness fuel.'
    },
    {
        id: 44, name: 'Rainbow Pop Candies', category: 'Kids Range',
        price: 40, weight: '80g',
        description: 'Fun rainbow-colored pop candies with a fizzy surprise inside.'
    },
    {
        id: 45, name: 'Jelly Bears Mix', category: 'Kids Range',
        price: 45, weight: '100g',
        description: 'Adorable jelly bear gummies in six fruity flavors kids adore.'
    },
    {
        id: 46, name: 'Chocolate Buttons', category: 'Kids Range',
        price: 50, weight: '80g',
        description: 'Bite-sized milk chocolate buttons — a beloved classic for kids.'
    },
    {
        id: 47, name: 'Fruit Chews Variety', category: 'Kids Range',
        price: 42, weight: '100g',
        description: 'Chewy fruit candy sticks in strawberry, orange, and grape flavors.'
    },
    {
        id: 48, name: 'Popcorn Sweet & Salty', category: 'Kids Range',
        price: 38, weight: '90g',
        description: 'The irresistible combination of sweet caramel and salty popcorn.'
    }
];

const CATEGORIES = [
    'Salty Snacks',
    'Sweet Snacks',
    'Confectionery',
    'Cookies & Biscuits',
    'Premium/Seasonal',
    'Health Bars',
    'Kids Range'
];

export { PRODUCTS, CATEGORY_THEMES, CATEGORIES };