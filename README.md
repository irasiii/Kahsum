# خصم / Khasm

B2C discount marketplace connecting traders directly with consumers in Saudi Arabia and the GCC.

## Tech Stack

- **Mobile & Web App**: Flutter (iOS + Android + Web)
- **SEO/Brochure Site**: Next.js
- **Backend**: Node.js + Express
- **Database**: PostgreSQL + Prisma ORM
- **AI Pricing Engine**: Claude Haiku (Anthropic) + Apify scrapers (Noon + Amazon.sa)

## Project Structure

```
/khasm
  /apps
    /flutter_app     # Flutter mobile + web app
    /web             # Next.js marketing site (SEO)
  /server            # Express backend
  /shared            # i18n files, types, API specs
  /infra             # Docker, seed data
```

## Getting Started

### Prerequisites

- Node.js 20+
- Flutter SDK 3.16+
- Docker (for PostgreSQL)

### Setup

```bash
# 1. Start PostgreSQL
docker compose -f infra/docker/docker-compose.yml up -d

# 2. Setup backend
cd server
cp .env.example .env
# Edit .env with your API keys
npm install
npx prisma migrate dev
npx tsx src/seed.ts
npm run dev

# 3. Start Flutter app
cd apps/flutter_app
flutter pub get
flutter run

# 4. Start Next.js SEO site
cd apps/web
npm install
npm run dev
```

## Environment Variables

See `server/.env.example` for all required keys:
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - JWT signing secret
- `ANTHROPIC_API_KEY` - Claude AI API key
- `APIFY_API_KEY` - Apify API key for web scraping
- `CLOUDINARY_*` - Cloudinary image upload credentials

## Features

- Arabic-first bilingual interface (AR/EN)
- Guest mode (browse without login)
- AI-powered price verification
- QR code deal claiming + scanning
- Pay-per-post model (49/99/199 SAR)
- 40 categories across 8 groups
- GPS-based deal discovery
- Hijri calendar + VAT display
