{
  ...
}: {
  # Enable uinput module for kanata
  boot.kernelModules = ["uinput"];

  # Enable uinput hardware support
  hardware.uinput.enable = true;

  # Set up udev rules for uinput access
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  # Ensure uinput group exists
  users.groups.uinput = {};

  # Kanata keyboard remapping service
  services.kanata = {
    enable = true;
    keyboards = {
      laptop = {
        devices = [
          "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
        ];
        config = ''
          ;; Complete Danish keyboard source layer mapping all physical keys
          (defsrc
            ;; Number row
            grv 1 2 3 4 5 6 7 8 9 0 - = bspc
            ;; Top letter row with correct Danish keycodes
            tab q w e r t y u i KeyO KeyP BracketLeft BracketRight ret
            ;; Home row with correct Danish keycodes
            caps a s d f g h j k KeyL Semicolon Quote Backslash
            ;; Bottom row (including 102d key for < >)
            lsft 102d z x c v b n m , . / rsft
            ;; Space row
            lctl lmet lalt spc ralt menu rctl
          )

          ;; Define smart caps lock: backspace with left shift, caps lock with right shift
          (defalias
            caps-smart (fork bspc caps (rsft))
            ;; Space with tap-hold for left-handed layer access
            spc-hold (tap-hold 200 200 spc (layer-toggle lefthand))
            ;; Tab with tap-hold for arrow layer access
            tab-arrows (tap-hold 200 300 tab (layer-toggle arrows))
            ;; Tap-hold for home row modifiers (300ms hold time to prevent accidental activation)
            a-alt (tap-hold 200 300 a lalt)
            o-alt (tap-hold 200 300 o ralt)
            r-ctrl (tap-hold 200 300 r lctl)
            i-ctrl (tap-hold 200 300 i rctl)
            g-super (tap-hold 200 300 g lmet)
            m-super (tap-hold 200 300 m rmet)
            ;; One-shot modifiers for bottom row
            lctl-os (one-shot 1000 lctl)
            lmet-os (one-shot 1000 lmet)
            lalt-os (one-shot 1000 lalt)
            ralt-os (one-shot 1000 ralt)
            rctl-os (one-shot 1000 rctl)
          )

          ;; Colemak-DH target layer using deflayermap for cleaner Danish key mapping
          (deflayermap colemak-dh
            ;; Tab with tap-hold for arrow layer
            tab @tab-arrows
            ;; Alphabet keys to Colemak-DH positions
            q q  w w  e f  r p  t b  y j  u l  i u  KeyO y  KeyP apos
            ;; Home row with tap-hold modifiers
            caps @caps-smart  a @a-alt  s @r-ctrl  d s  f t  g @g-super  h @m-super  j n  k e  KeyL @i-ctrl  Semicolon @o-alt  Quote apos  Backslash \
            ;; Bottom row with shifted layout
            lsft (one-shot 1000 lsft)  102d z  z x  x c  c d  v v  b <  n k  m h  , ,  . .  / /  rsft (one-shot 1000 rsft)
            ;; Space row with one-shot modifiers and tap-hold for lefthand layer access
            lctl @lctl-os  lmet @lmet-os  lalt @lalt-os  spc @spc-hold  ralt @ralt-os  rctl @rctl-os
          )

          ;; Left-handed layer using deflayermap - mirrored only up to pinkies
          (deflayermap lefthand
            ;; Top row - mirrored positions
            q apos  w y  e u  r l  t j  y b  u p  i f  KeyO w  KeyP q
            ;; Home row - mirror a↔æ only as requested, rest normal colemak-dh, caps as enter
            caps ret  a @o-alt  s @i-ctrl  d e  f n  g @m-super  h @g-super  j t  k s  KeyL @r-ctrl  Semicolon @a-alt  Quote o  Backslash \
            ;; Bottom row - mirrored
            102d /  z .  x ,  c h  v k  b <  n v  m d  , c  . x  / z
          )

          ;; Arrow layer using ESDF on left hand (activated by holding tab)
          (deflayermap arrows
            ;; ESDF arrows - e=up, s=left, d=down, f=right
            e up
            s left
            d down
            f right
          )
        '';
      };
    };
  };
}
