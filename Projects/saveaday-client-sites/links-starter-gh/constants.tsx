
import { ApiResponse, Catalogue } from './types';

export const SAMPLE_CATALOGUE: Catalogue = {
  "id": "VzB8iwGnFV40SeRXOH0p",
  "ownerId": "x0P8bcooVLMknfD0FL86KcxOsMH3",
  "businessName": "My New Catalogue",
  "slug": "qonYYQTZj3",
  "status": "draft",
  "theme": {
    "primaryColor": "#000000",
    "font": "sans"
  },
  "createdAt": {
    "_seconds": 1769001099,
    "_nanoseconds": 177000000
  },
  "categories": [
    {
      "title": "Hair Styles & Cuts",
      "items": [
        {
          "title": "BlowDry Straight",
          "description": "Professional blow dry with straight styling",
          "price": 60,
          "variants": [
            { "label": "Short", "price": 60 },
            { "label": "Medium", "price": 80 },
            { "label": "Long", "price": 100 },
            { "label": "Long+", "price": 120 }
          ]
        },
        {
          "title": "BlowDry Wavy",
          "description": "Professional blow dry with wavy styling",
          "price": 80,
          "variants": [
            { "label": "Short", "price": 80 },
            { "label": "Medium", "price": 100 },
            { "label": "Long", "price": 150 },
            { "label": "Long+", "price": 180 }
          ]
        },
        {
          "title": "Hair Style",
          "description": "Complete hair styling service",
          "price": 150,
          "variants": [
            { "label": "Short", "price": 150 },
            { "label": "Medium", "price": 200 },
            { "label": "Long", "price": 250 },
            { "label": "Long+", "price": 300 }
          ]
        },
        {
          "title": "Wavy Hair Style",
          "description": "Complete wavy hair styling service",
          "price": 120,
          "variants": [
            { "label": "Short", "price": 120 },
            { "label": "Medium", "price": 150 },
            { "label": "Long", "price": 200 },
            { "label": "Long+", "price": 250 }
          ]
        },
        {
          "title": "Hair Wash",
          "description": "Professional hair washing service",
          "price": 20
        },
        {
          "title": "Machine Cut",
          "description": "Hair cut with machine",
          "price": 80
        },
        {
          "title": "Haircut (Stylized)",
          "description": "Professional stylized haircut",
          "price": 80
        },
        {
          "title": "Hair Trim",
          "description": "Hair trimming service",
          "price": 50
        },
        {
          "title": "Front Cut",
          "description": "Front hair cutting service",
          "price": 30
        }
      ]
    },
    {
      "title": "Nail Services",
      "items": [
        {
          "title": "Regular Extension",
          "description": "Standard nail extension",
          "price": 60
        },
        {
          "title": "Extension with Gel Polish",
          "description": "Nail extension with gel polish finish",
          "price": 120
        },
        {
          "title": "Polygel",
          "description": "Polygel nail application",
          "price": 250
        },
        {
          "title": "Acrylic",
          "description": "Acrylic nail application",
          "price": 230
        },
        {
          "title": "Hard Gel",
          "description": "Hard gel nail application",
          "price": 280
        },
        {
          "title": "Tip In",
          "description": "Nail tip application",
          "price": 250
        },
        {
          "title": "Refill",
          "description": "Nail refill service",
          "price": 180
        },
        {
          "title": "Repair",
          "description": "Nail repair service (starting price)",
          "price": 20
        },
        {
          "title": "Nail Art",
          "description": "Custom nail art design (starting price)",
          "price": 20
        },
        {
          "title": "Pedicure",
          "description": "Professional pedicure service",
          "price": 70
        },
        {
          "title": "Manicure",
          "description": "Professional manicure service",
          "price": 60
        },
        {
          "title": "Essie Color",
          "description": "Essie nail polish application",
          "price": 35
        },
        {
          "title": "Gel Color",
          "description": "Gel nail polish application",
          "price": 70
        },
        {
          "title": "Foot / Hand Spa",
          "description": "Relaxing spa treatment for feet and hands",
          "price": 120
        },
        {
          "title": "Hand Paraffin",
          "description": "Paraffin treatment for hands",
          "price": 50
        },
        {
          "title": "Foot Paraffin",
          "description": "Paraffin treatment for feet",
          "price": 70
        },
        {
          "title": "Nails Protection",
          "description": "Protective coating for nails",
          "price": 50
        }
      ]
    },
    {
      "title": "Facial & Body Services",
      "items": [
        {
          "title": "Wave Facial Cleansing",
          "description": "Signature Wave facial cleansing treatment",
          "price": 250
        },
        {
          "title": "Underarm Cleansing",
          "description": "Professional underarm cleansing",
          "price": 150
        },
        {
          "title": "Natural Face Mask",
          "description": "Natural ingredients face mask",
          "price": 50
        },
        {
          "title": "Casmara Mask",
          "description": "Premium Casmara face mask",
          "price": 50
        },
        {
          "title": "Wave Bath",
          "description": "Signature Morrocan bath experience",
          "price": 250
        },
        {
          "title": "Lufa",
          "description": "Traditional lufa scrub",
          "price": 25
        },
        {
          "title": "Organic Body Scrub",
          "description": "Natural organic body scrub treatment",
          "price": 100
        }
      ]
    },
    {
      "title": "Hair Treatments",
      "items": [
        {
          "title": "Protein Treatment",
          "description": "Deep protein hair treatment",
          "price": 500,
          "variants": [
            { "label": "Short", "price": 500 },
            { "label": "Medium", "price": 700 },
            { "label": "Long", "price": 1000 },
            { "label": "Long+", "price": 1200 }
          ]
        },
        {
          "title": "BB Cream Treatment",
          "description": "BB cream hair treatment",
          "price": 500,
          "variants": [
            { "label": "Short", "price": 500 },
            { "label": "Medium", "price": 700 },
            { "label": "Long", "price": 1000 },
            { "label": "Long+", "price": 1200 }
          ]
        },
        {
          "title": "Scalp Treatment",
          "description": "Professional scalp treatment",
          "price": 120
        },
        {
          "title": "Organic Hair Treatment - 1 Session",
          "description": "Single session organic hair treatment",
          "price": 120
        },
        {
          "title": "Organic Hair Treatment - 5 Sessions",
          "description": "Package of 5 organic hair treatment sessions",
          "price": 480
        },
        {
          "title": "Hair Henna",
          "description": "Natural henna hair treatment (starting price)",
          "price": 120
        }
      ]
    },
    {
      "title": "Hair Extensions & Coloring",
      "items": [
        {
          "title": "Clip Extension",
          "description": "Clip-in hair extensions (starting price)",
          "price": 1200
        },
        {
          "title": "Tape Extension",
          "description": "Tape-in hair extensions (starting price)",
          "price": 800
        },
        {
          "title": "Tape Extension Removal",
          "description": "Professional removal of tape extensions",
          "price": 50
        },
        {
          "title": "Tape Extension Application",
          "description": "Professional application of tape extensions",
          "price": 50
        },
        {
          "title": "Schwarzkopf Hair Color",
          "description": "Premium Schwarzkopf hair coloring (starting price)",
          "price": 400
        },
        {
          "title": "Roots Coloring",
          "description": "Root touch-up coloring service (starting price)",
          "price": 200
        },
        {
          "title": "Highlights",
          "description": "Hair highlighting service (starting price)",
          "price": 500
        },
        {
          "title": "Rincage",
          "description": "Hair rinsing/toning service (starting price)",
          "price": 200
        }
      ]
    }
  ],
  "updatedAt": {
    "_seconds": 1769515782,
    "_nanoseconds": 19000000
  }
};

export const INITIAL_DATA: ApiResponse = {
  "success": true,
  "data": [
    {
      "id": "8JeIMaXKpX7QPAgtXj2e",
      "ownerId": "x0P8bcooVLMknfD0FL86KcxOsMH3",
      "slug": "saveaday",
      "status": "active",
      "createdAt": "2026-01-21T11:16:27.236Z",
      "views": 0,
      "clicks": 0,
      "profile": {
        "name": "Saveaday",
        "bio": "Saveaday helps business to save a day every week automating repetitive and boring tasks",
        "logo": "https://img.freepik.com/free-vector/bird-colorful-gradient-design-vector_343694-2506.jpg?semt=ais_hybrid&w=740&q=80",
        "address": "Dubai dubai",
        "email": "me@bigmints.com",
        "phone": "+971569737344"
      },
      "links": [
        {
          "id": "-6Kl-m-qNWomTPoRQfXa6",
          "type": "social",
          "label": "Instagram",
          "url": "https://instagram.com/saveaday",
          "order": 0,
          "active": true,
          "icon": "instagram"
        },
        {
          "id": "Zf4qEKs41bFSJrRXfy6a6",
          "type": "social",
          "label": "Facebook",
          "url": "https://facebook.com/saveaday",
          "order": 1,
          "active": true,
          "icon": "facebook"
        },
        {
          "id": "mB0ubn1MVDr7asYlQNkBz",
          "type": "social",
          "label": "YouTube",
          "url": "https://youtube.com/@saveaday",
          "order": 2,
          "active": true,
          "icon": "youtube"
        },
        {
          "id": "QcFevwPFFHAtSn5aNuIDa",
          "type": "whatsapp",
          "label": "Book Online",
          "url": "+971569737344",
          "order": 3,
          "active": true
        }
      ],
      "theme": {
        "background": "bg-gray-50",
        "buttonStyle": "pill",
        "font": "sans"
      },
      "updatedAt": "2026-01-21T11:19:17.120Z"
    }
  ],
  "count": 1,
  "hasMore": false
};

// Import generated data from webhook payload (if exists)
// Using Vite's import.meta.glob for conditional imports
const generatedDataModules = import.meta.glob('./src/generated-data.json', { eager: true });
const generatedData = (generatedDataModules['./src/generated-data.json'] as any)?.default;

// Export data for use in App
// If generated data exists (from webhook build), use it; otherwise use fallback
export const PAGE_DATA = generatedData?.linkPage || INITIAL_DATA.data[0];
export const CATALOGUE_DATA = generatedData?.catalogue || SAMPLE_CATALOGUE;
export const SURVEY_DATA = generatedData?.survey || null;
export const LEAD_FORM_DATA = generatedData?.leadForm || null;
