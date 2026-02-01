<div align="center">
<img width="1200" height="475" alt="LinkPages Template" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# LinkPages Template - Webhook-Triggered Static Sites

A reusable template for creating client-specific link-in-bio pages with webhook-triggered deployments to GitHub Pages.

## Architecture

This template uses a **webhook-triggered static build** approach:

1. **Trigger**: Backend sends HTTP POST to GitHub's `repository_dispatch` API
2. **Payload**: POST includes all content data (profile, links, catalogue, etc.)
3. **Build**: GitHub Actions builds static site with injected content
4. **Deploy**: Static HTML/JS/CSS deployed to GitHub Pages
5. **Runtime**: No API calls - all content is baked into the build

**Workflow:**

```
CMS/Backend → repository_dispatch POST → GitHub Actions → Build with payload → Deploy to Pages
```

---

## Creating a New Client Instance

### 1. Copy Template

```bash
rsync -av --exclude='node_modules' --exclude='dist' --exclude='.git' \
  /path/to/links-starter-gh/ \
  /path/to/CLIENT_NAME/
```

### 2. Customize Client Files

**package.json**

```json
{
  "name": "client-name",
  "version": "1.0.0"
}
```

**metadata.json**

```json
{
  "name": "Client Business Name",
  "description": "Client description"
}
```

**src/generated-data.json**

Create with client's initial data:

```json
{
  "linkPage": {
    "slug": "client-slug",
    "profile": {
      "name": "Client Name",
      "bio": "Client bio",
      "logo": "https://...",
      "email": "client@email.com",
      "phone": "+1234567890"
    },
    "links": [...],
    "theme": {...}
  },
  "catalogue": {...}
}
```

### 3. Initialize Git Repository

```bash
cd /path/to/CLIENT_NAME
git init
git add .
git commit -m "Initial commit: CLIENT_NAME setup"
```

### 4. Create GitHub Repository

```bash
# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_ORG/CLIENT_NAME.git
git push -u origin master
```

### 5. Configure GitHub Pages

1. Go to repository **Settings → Pages**
2. Source: **GitHub Actions**
3. Save

### 6. Test Deployment

Trigger a deployment via webhook:

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer YOUR_GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_ORG/CLIENT_NAME/dispatches \
  -d '{
    "event_type": "publish_content",
    "client_payload": {
      "data": {
        "linkPage": {
          "id": "...",
          "slug": "client-slug",
          "profile": {...},
          "links": [...],
          "theme": {...}
        },
        "catalogue": {...}
      }
    }
  }'
```

---

## Webhook Payload Structure

The `client_payload.data` object should contain:

### Required: linkPage

```json
{
  "linkPage": {
    "id": "unique-id",
    "slug": "page-slug",
    "status": "active",
    "profile": {
      "name": "Business Name",
      "bio": "Business description",
      "logo": "https://...",
      "address": "Location",
      "email": "contact@email.com",
      "phone": "+1234567890"
    },
    "links": [
      {
        "id": "link-1",
        "type": "social",
        "label": "Instagram",
        "url": "https://instagram.com/username",
        "order": 0,
        "active": true,
        "icon": "instagram"
      }
    ],
    "theme": {
      "background": "bg-gray-50",
      "buttonStyle": "rounded",
      "font": "sans"
    }
  }
}
```

### Optional: catalogue

```json
{
  "catalogue": {
    "id": "catalogue-id",
    "businessName": "Business Name",
    "slug": "catalogue-slug",
    "categories": [
      {
        "title": "Category Name",
        "items": [
          {
            "title": "Service Name",
            "description": "Service description",
            "price": 100,
            "variants": [
              { "label": "Option 1", "price": 100 },
              { "label": "Option 2", "price": 150 }
            ]
          }
        ]
      }
    ]
  }
}
```

### Optional: survey

```json
{
  "survey": {
    "id": "survey-id",
    "name": "Survey Name",
    "description": "Survey description",
    "questions": [...],
    "embedCode": "<script>...</script>"
  }
}
```

### Optional: leadForm

```json
{
  "leadForm": {
    "id": "form-id",
    "name": "Form Name",
    "description": "Form description",
    "fields": [...],
    "embedCode": "<script>...</script>"
  }
}
```

---

## Local Development

```bash
# Install dependencies
npm install

# Run dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

The app will use data from `src/generated-data.json` if it exists, otherwise falls back to `INITIAL_DATA` in `constants.tsx`.

---

## How It Works

### GitHub Actions Workflow

[.github/workflows/deploy.yml](.github/workflows/deploy.yml) handles webhook deployments:

1. Receives `repository_dispatch` event with `publish_content` type
2. Writes `client_payload.data` to `src/generated-data.json`
3. Runs `npm run build` to create static bundle
4. Deploys to GitHub Pages

### Data Loading

[constants.tsx](constants.tsx) uses Vite's `import.meta.glob` to conditionally load data:

```typescript
const generatedDataModules = import.meta.glob("./generated-data.json", {
  eager: true,
});
const generatedData = generatedDataModules["./generated-data.json"];

export const PAGE_DATA = generatedData?.linkPage || INITIAL_DATA.data[0];
export const CATALOGUE_DATA = generatedData?.catalogue || SAMPLE_CATALOGUE;
```

### Application

[App.tsx](App.tsx) imports and uses the data directly - no runtime API calls:

```typescript
import { PAGE_DATA, CATALOGUE_DATA } from "./constants";

const ProfilePage = () => {
  const [pageData] = useState<LinkPage>(PAGE_DATA);
  // Render with pageData
};
```

---

## Tech Stack

- React 19
- TypeScript
- Vite
- Tailwind CSS
- React Router
- Lucide Icons

---

## Features

- 🎨 Customizable themes and styling
- 📱 Fully responsive design
- 🔗 Social media links (Instagram, Facebook, WhatsApp, etc.)
- 📋 Services catalogue with categories and pricing variants
- ⚡ Lightning-fast static site (no runtime API calls)
- 🚀 Automated deployment via webhooks
- 🔄 Content updates trigger automatic rebuilds

---

## Template Maintenance

### Updating the Template

When you make improvements to the template:

1. Test changes in `links-starter-gh`
2. Document changes in this README
3. Manually apply updates to existing client instances as needed

### Syncing Updates to Clients

To apply template updates to an existing client:

```bash
# Review changes in template
cd /path/to/links-starter-gh
git log

# Manually cherry-pick or copy specific files to client repo
# Be careful not to overwrite client-specific customizations
```

---

© 2026 SaveADay
