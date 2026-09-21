# Corps Haven — Operating Notes

Keep this somewhere handy (Notes app, Google Docs, printed out — doesn't
need to be on the live site). This is just for you.

---

## 1. Monthly backup routine (do this on the 1st of every month)

Supabase's free tier doesn't include automatic backups — if something
goes badly wrong, there's no safety net unless you make one yourself.
This takes about 5 minutes.

1. Go to your Supabase project → **Table Editor**.
2. For each of these tables, click the table name, then find the
   **Export** button (usually near the top-right of the table view) and
   choose **Export as CSV**:
   - `housing_listings`
   - `placements`
   - `reports`
   - `admin_users`
3. Save all four CSV files into one dated folder, e.g.
   `corps-haven-backup-2026-10-01/`
4. Upload that folder to Google Drive (or anywhere off your computer) —
   the point is having a copy that survives even if your laptop dies.
5. Delete backup folders older than 6 months if storage gets tight —
   keeping the most recent 2–3 is enough.

**If something ever goes wrong** (accidental mass-delete, corrupted
data), these CSVs are how you'd manually reconstruct what was lost —
not instant, but far better than nothing.

---

## 2. Before every deploy — quick checklist

Run through this before uploading changed files to GitHub, every time:

- [ ] Did I test this change on my own device first (not just assume it works)?
- [ ] If I changed a form, did I actually submit a test entry through it?
- [ ] If I changed SQL, did I run it in Supabase **before** the matching
      code that depends on it? (New columns before the code that reads them.)
- [ ] Did I check the browser console (F12 → Console tab) for red errors
      after loading the changed page?
- [ ] Am I uploading *every* file that changed, not just the one I
      remember editing? (Check this conversation's file list if unsure.)
- [ ] After uploading, did I **hard-refresh** (Ctrl+Shift+R) before
      deciding something's broken? A normal refresh can show a stale
      cached version even after a real fix.

Skipping this list is exactly how the `admin (1).html` naming bug and
the broken CDN link both happened earlier — five minutes now saves an
hour of confused debugging later.

---

## 3. Analytics

Cloudflare Web Analytics is set up (see the beacon script in every
public page). To check your traffic: log into dash.cloudflare.com →
Web Analytics → click on corps-haven.netlify.app. No setup needed
beyond pasting your token into the site files once.

---

## 4. If Corps Haven ever needs real legal help

The Privacy Policy and Terms were drafted to be honest and reasonable,
but they are not a substitute for an actual lawyer. Get one reviewed
by a real lawyer once:
- Corps Haven has meaningful real users, or
- You register it as a business, or
- You start collecting anything more sensitive than what it collects today.
