// Single source of truth for the API's base URL.
//
// Local dev falls back to localhost. The production build (`vite build`) picks
// up VITE_API_URL from .env.production, so the deployed site calls the live
// API Gateway instead. Vite inlines import.meta.env.* at build time.
export const API_BASE =
  import.meta.env.VITE_API_URL ?? 'http://localhost:8000'
