# Time Bucket Frontend

Next.js 16 application for Time Bucket app.

## Requirements

- Node.js 20+
- pnpm 9+

## Setup

### Using Docker (Recommended)

```bash
# From project root
docker compose up --build

# Access at http://localhost:3000
```

### Local Development

```bash
# Install dependencies
corepack enable
pnpm install

# Setup environment
cp .env.example .env.local
# Edit .env.local with your settings

# Start development server
pnpm dev

# Open http://localhost:3000
```

## Scripts

```bash
pnpm dev      # Start development server
pnpm build    # Build for production
pnpm start    # Start production server
pnpm lint     # Run ESLint
```

## Tech Stack

- Next.js 16.0.3 (App Router)
- React 19.2.0
- TypeScript 5
- Tailwind CSS 4
- PostHog (Analytics)

## Project Structure

```
src/
  app/          # Next.js App Router pages
  lib/          # Utility functions and helpers
public/         # Static assets
```

## Environment Variables

See `.env.example` for required environment variables.

## API Integration

Backend API: `http://localhost:4000` (configured via `NEXT_PUBLIC_BACKEND_URL`)

