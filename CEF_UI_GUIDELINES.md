# CEF UI guidelines

All new CEF screens in this gamemode should follow the shared motion rules:

- Use a short entrance animation (`opacity` + `transform`) with a 450–600ms ease-out curve.
- Use the same properties for exit animations, then hide/remove the view after the animation ends.
- Never animate layout properties such as `width`, `height`, `top`, `left`, `margin`, or `filter`.
- Keep hover/focus feedback around 150–200ms and use `transform`/`opacity` where possible.
- Avoid persistent `backdrop-filter`, large blur radii, and continuous animations on mobile.
- Add a mobile media query that disables expensive blur/background layers.
- Respect `@media (prefers-reduced-motion: reduce)` and disable non-essential motion.
- Keep each CEF self-contained, but copy these motion rules into its stylesheet or extract them into a shared stylesheet when the CEF bundle supports it.

The current login CEF follows these rules in `scriptfiles/cef/lsrp/style.css`. It has smooth entrance motion; view exit transitions should be added whenever a future CEF needs animated closing or screen replacement.
