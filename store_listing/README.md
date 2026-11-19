# Store listing text

`<app>/<language>/{title,short_description,full_description}.txt` for the
Play listings, `<app>` = `paid` (com.lomoware.screen_translate) or `lite`
(com.lomoware.screen_translate.lite). Upload with
`python tools/store_assets/upload_text.py` (dry run; `--commit` sends the
changes to review). Screenshots are separate: `tools/store_assets/`.

Only languages kept here are managed by the script; the rest of each
listing (other languages, video, images) is left alone.

| App | Language | Why |
|---|---|---|
| paid | vi, id | Vietnam and Indonesia are the 2nd and 3rd largest sources of store visitors (Oct-Nov 2026), and their old titles were literal translations of "Screen translation". Titles now use the local search words; the opening points price-sensitive visitors to the free Lite app. The feature list and the accessibility/data-safety paragraphs are the live text, unchanged. |
| lite | vi, id | Lite only had en-US. No pricing claims ("one-time", "no subscription"), because the paywall's plans change through Remote Config. |

Limits: title 30, short description 80, full description 4000 characters
(upload_text.py checks them).
