# Kash - Prompt Recreation Guide

If you ever need an LLM to recreate this project from scratch, use the following mega-prompt to capture the exact tech stack, design philosophy, and feature set of Kash.

---

**Prompt:**

Act as an expert Full-Stack Software Engineer and UI/UX Designer. I want you to build a comprehensive, privacy-first, self-hosted household finance tracker called **"Kash"**. 

**Core Philosophies:**
1. **Private By Default:** This app must be designed for self-hosting (e.g., via Proxmox LXC). There are no cloud accounts or third-party analytic trackers. 
2. **Native Mobile App Feel:** It is strictly a Single Page Application (SPA). There are no page reloads. The UI must aggressively prioritize mobile-first design, specifically functioning flawlessly as a Progressive Web App (PWA) with iOS safe-area notch padding, swipe-to-close bottom-sheet menus ("drawers"), and bottom tab-bar navigation (Dashboard, Spending, Budgets, Income).
3. **Ultra-Fast & Lightweight:** Do *not* use heavy frameworks like React, Vue, or Angular. Use pure Vanilla JavaScript, HTML5, and raw CSS. Do not use Tailwind CSS.
4. **Premium "Midnight Teal" Aesthetic:** The color palette should center around a deep navy / midnight blue (`#0a2540` to `#0d3d52`) with a vibrant, electric teal accent (`#00d4aa`). Use extensive glassmorphism (translucent cards with backdrop blur), smooth gradients, and micro-animations for interactions. Design must look incredibly premium and modern. Icons must be pure inline SVGs (no network dependencies).
5. **Simplicity:** The backend must be Python / Flask using a single local SQLite database (`expenses.db`). Use Gunicorn for production serving. All logic should live directly in python functions with clean API endpoints returning JSON. There is only one HTML file (`index.html`) rendered by Flask that handles the entire frontend UI. 

**Required App Features:**
1. **Authentication & Multi-User:** Secure login system. Accounts can only be created by an Admin user (to prevent public signup). Include a "Share" feature that allows an owner to share specific expenses, budgets, or bills with other users in the home.
2. **Dashboard Overview:** A complex widgetized dashboard. Include a top "Hero Card" showing total earned, spent, and net saved for the current month. Include smart insights (Largest Expense, Savings Streaks, Anomalies). Include a 12-Month Area Trend Chart and a Donut Chart for categorical spending breakdown. Dashboard widgets should be toggleable per user.
3. **The Core Modules:** 
    *   **Spending / Income:** Tables to track money in and out. Include sorting, filtering, and a "Who Owes What" bill-splitting system.
    *   **Budgets:** An envelope-style monthly budget tracker per category with percentage progress bars. Include features to "Copy Last Month" and "Rollover" under-budget amounts.
    *   **Recurring Bills:** A system to track fixed cadence bills (weekly, monthly) with countdown alerts indicating days remaining until due. 
    *   **Savings Goals:** Long-term goals tracking amount saved vs target date.
    *   **Credit Cards:** Overall balance and utilization progress bars.
4. **Bank CSV Importer:** A robust engine allowing users to upload a bank CSV file. It must auto-map columns, intelligently guess expense categories based on string matching (e.g., "Netflix" -> "Entertainment"), and present a review table before committing to the database. It must ignore duplicates.
5. **Local AI Integration (Ollama):** The application must be capable of calling out to a local Ollama LLM endpoint over the network on the backend. 
    *   *AI Categorization:* The CSV importer should be able to send unknown line items to the local AI to determine the category contextually.
    *   *AI Advisor:* A button on the Budgets tab that sends the user's Total Income, Fixed Bills, Credit Card Debts, and Budget Limits to the LLM. The AI will output a heavily formatted Markdown action plan on how to snowball debt or adjust their budget safely. (Ensure the Gunicorn timeout is extended heavily to allow local slow GPUs to finish calculating).
6. **Email Notifications:** A background scheduler (APScheduler) that sends customized HTML email alerts over SMTP: 7-day bill warnings, budget limit warnings (80% and 100%), and a neat summary on the 1st of every month. Email templates must use ultra-resilient styling, utilizing remote-hosted transparent PNG logos (like GitHub's raw CDN) rather than inline SVGs or complex CSS `text-shadows`, ensuring pixel-perfect branding across aggressive clients like Gmail and Outlook.

Write the complete project structure (Flask app file, configuration classes, pure CSS/JS HTML template file, install script) optimized for production.
