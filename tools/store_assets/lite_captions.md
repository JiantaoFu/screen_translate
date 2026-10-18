# Lite screenshot captions (en-US), for compose.py SHOTS

Order: home, manga, game, webtoon, chat. Each is (headline, subline). They avoid the paid app's wording because of Play's repetitive-content rule. The 4 keywords are covered once each.

```python
LITE_SHOTS_EN = {
    'home':    ('5 free translations every day', 'Unlock Pro once for unlimited. No ads'),
    'manga':   ('Manga translator on your screen', 'Reads vertical Japanese bubbles'),
    'game':    ('Game translator, no app switching', 'Tap the bubble, read the dialogue'),
    'webtoon': ('Scroll and translate webtoons', 'Korean, Japanese, Chinese and more'),
    'chat':    ('Screen translator with OCR', 'Any text in any app, even images'),
}
```

Checks:
- The home caption must match the app: the quota really is 5 a day and the Pro entry is visible. If the app shows a different number, change the caption to that number.
- "No ads" is true for Lite (no ad SDK, no AD_ID).
- The longest headline is 33 characters. compose.py wraps at 58 to 72 px, so check the render.
