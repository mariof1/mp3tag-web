#!/usr/bin/env python3
"""Patch xpra HTML5 client for CSD window handling and mouse alignment."""

WJS = "/usr/share/xpra/www/js/Window.js"
CSS = "/usr/share/xpra/www/css/client.css"

# --- JS patches ---
with open(WJS) as f:
    code = f.read()

# 1. Only force decoration on non-Wine CSD windows (Telegram etc).
#    Wine windows (class-instance contains ".exe") keep native behavior.
old = '_set_decorated(decorated){this.decorated=decorated;'
new = (
    '_set_decorated(decorated){'
    'if(!decorated&&!this.override_redirect){'
    'var ci=this.metadata["class-instance"]||[];'
    'if(ci[0]&&ci[0].indexOf(".exe")<0)decorated=true;'
    '}'
    'this.decorated=decorated;'
)
assert old in code, f"Pattern not found in {WJS}: {old[:60]}..."
code = code.replace(old, new)

# 2. Use outerHeight() instead of css("height") for header offset calc.
old2 = 'jQuery(this.d_header).css("height")'
new2 = 'jQuery(this.d_header).outerHeight()'
assert old2 in code, f"Pattern not found in {WJS}: {old2}"
code = code.replace(old2, new2)

with open(WJS, "w") as f:
    f.write(code)

# --- CSS patches ---
with open(CSS, "a") as f:
    f.write("\n.windowhead { box-sizing: border-box; }\n")
    f.write(".undecorated:not(.override-redirect) { border: 1px solid transparent; }\n")

print("xpra patches applied successfully")
