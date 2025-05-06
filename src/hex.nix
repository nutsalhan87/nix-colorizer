{ oklch, srgb }:

let
  math = import ./utils/math.nix;

  tr = (import ./utils/transform.nix) { inherit math; };

in rec {
  to = {
    oklch = hex: srgb.to.oklch (to.srgb hex);

    oklchs = hexes: map (hex: to.oklch hex) hexes;

    srgb = hex: {
      r = (tr.hexToDecimal (builtins.substring 1 2 hex)) / 255.0;
      g = (tr.hexToDecimal (builtins.substring 3 2 hex)) / 255.0;
      b = (tr.hexToDecimal (builtins.substring 5 2 hex)) / 255.0;
      a = let
        a = builtins.substring 7 2 hex;
      in
        (if builtins.stringLength a == 2 then (tr.hexToDecimal a) else 255) / 255.0;
    };

    srgbs = hexes: map (hex: to.srgb hex) hexes;
  };

  lighten = hex: percent: oklch.to.hex (lighten (to.oklch hex) percent);

  darken = hex: percent: oklch.to.hex (darken (to.oklch hex) percent);
  
  blend =
    hex: another: percent:
    oklch.to.hex (blend (to.oklch hex) (to.oklch another) percent);

  gradient =
    hex: another: steps:
    oklch.to.hexes (gradient (to.oklch hex) (to.oklch another) steps);

  shades = hex: steps: oklch.to.hexes (shades (to.oklch hex) steps);

  tints = hex: steps: oklch.to.hexes (tints (to.oklch hex) steps);

  tones = hex: steps: oklch.to.hexes (tones (to.oklch hex) steps);

  polygon = hex: count: oklch.to.hexes (polygon (to.oklch hex) count);

  complementary = hex: oklch.to.hex (complementary (to.oklch hex));

  analogous = hex: oklch.to.hexes (analogous (to.oklch hex));

  splitComplementary = hex: oklch.to.hexes (splitComplementary (to.oklch hex));

  setAlpha = hex: alpha: let
    rgb = (to.srgb hex) // { a = alpha / 100.0; };
  in srgb.to.hex rgb;

  stripAlpha = hex: let
    rgb = (to.srgb hex) // { a = 1.0; };
  in srgb.to.hex rgb;

  incAlpha = hex: percent: let
    rgb = to.srgb hex;
    inc = rgb // {
      a = rgb.a + (percent / 100.0);
    };
  in srgb.to.hex inc;

  decAlpha = hex: percent: let
    rgb = to.srgb hex;
    dec = rgb // {
      a = rgb.a - (percent / 100.0);
    };
  in srgb.to.hex dec;
}