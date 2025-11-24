## Kanata Keyboard Configuration Learnings

### Danish Keyboard Layout (ThinkPad T14s)

**Physical Layout Understanding:**

- Top row: `q w e r t y u i o ø å ¨` (positions 1-12)
- Home row: `a s d f g h j k l ø æ '` (where ø is KeyL, æ is Semicolon, ' is Quote)
- Danish keyboard differs from US layout in positions 10-13 of top row and 10-12 of home row

**Critical Kanata Keycodes for Danish Layout:**

- `KeyO` = physical 'o' key (position 9 top row)
- `KeyP` = physical 'p' key (position 10 top row, produces ø on Danish layout)
- `BracketLeft` = physical 'å' key (position 11 top row)
- `BracketRight` = physical '¨' key (position 12 top row)
- `KeyL` = physical 'l' key (position 9 home row)
- `Semicolon` = physical 'æ' key (position 10 home row)
- `Quote` = physical 'ø' key on home row (position 11 home row)
- `Backslash` = physical ''' key (position 12 home row)

**Character vs Keycode Issue:**

- NEVER use literal characters like `'` in kanata mappings
- Characters are interpreted as "key that produces this character on current layout"
- Use proper keycodes instead: `'` → `apos`, not the literal character
- Example: `KeyP '` fails because `'` refers to Quote key position, use `KeyP apos`

**Working Configuration Structure:**

```
(defsrc
tab q w e r t y u i KeyO KeyP BracketLeft BracketRight ret
caps a s d f g h j k KeyL Semicolon Quote Backslash
)

(deflayermap colemak-dh
KeyP apos  ; Physical P key produces apostrophe
Quote apos ; Physical ø key produces apostrophe in colemak-dh
)
```

**Layer System:**

- Use `deflayermap` for complex layouts with long keycode names
- Space bar tap-hold: `(tap-hold 200 200 spc (layer-toggle lefthand))`
- Caps lock smart behavior: `(fork bspc caps (rsft))` - backspace with lshift, caps with rshift
- In lefthand layer: `caps ret` makes caps produce enter when space is held

**Home Row Modifiers:**

- `(tap-hold 200 200 <key> <modifier>)` for tap-hold behavior
- a/o keys: alt when held (`lalt`/`ralt`)
- r/i keys: ctrl when held (`lctl`/`rctl`)
- g/m keys: super when held (`lmet`/`rmet`)

**Debugging Tips:**

- Always check kanata service status: `systemctl status kanata-laptop.service`
- Look for "entering the processing loop" and "Starting kanata proper" in logs
- Use deflayermap when keycode names are long (KeyO, KeyP, etc.)
- Count defsrc items carefully - layer count mismatches cause build failures

**Bottom Row Remapping:**

- `102d` key is the `<>` key next to left shift on ISO keyboards
- Shifted bottom row: `< key→z, z→x, x→c, c→d, v→v, b→<`

**Mirror Layer Constraints:**

- User wants only pinkie-key mirroring: `a↔æ` (Semicolon key)
- NOT full mirroring - rest of hand stays in normal colemak-dh positions
- In lefthand layer: `a @o-alt  Semicolon @a-alt` for the a↔æ swap
