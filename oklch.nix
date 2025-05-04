let
  utils = import ./utils.nix;
  clampSingle = x: if x > 255 then 255 else if x < 0 then 0 else x;
  clamp = { r, g, b, a }@args: 
    builtins.mapAttrs (name: val: (clampSingle val)) args;
  modifiers = steps: let 
    steps' = let
      rounded = utils.round steps;
    in
      if rounded < 0 then (abort "Steps count must be positive number") else rounded;
  in
    builtins.genList (x: x / (steps' + 1.0)) (steps' + 2);
in
rec {
  hexToRgb = hex: {
    r = (utils.hexToDecimal (builtins.substring 1 2 hex)) / 255.0;
    g = (utils.hexToDecimal (builtins.substring 3 2 hex)) / 255.0;
    b = (utils.hexToDecimal (builtins.substring 5 2 hex)) / 255.0;
    a =
      let
        a = builtins.substring 7 2 hex;
      in
      (if builtins.stringLength a == 2 then (utils.hexToDecimal a) else 255) / 255.0;
  };

  rgbToOklch = { r, g, b, a }@rgb: let
    linear = {
      r = utils.srgbToLinear rgb.r;
      g = utils.srgbToLinear rgb.g;
      b = utils.srgbToLinear rgb.b;
      inherit (rgb) a;
    };
    l = utils.cbrt (0.4122214708 * linear.r + 0.5363325363 * linear.g + 0.0514459929 * linear.b);
    m = utils.cbrt (0.2119034982 * linear.r + 0.6806995451 * linear.g + 0.1073969566 * linear.b);
  	s = utils.cbrt (0.0883024619 * linear.r + 0.2817188376 * linear.g + 0.6299787005 * linear.b);
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
  in {
    inherit L;
    C = utils.sqrt ((utils.powInt a 2) + (utils.powInt b 2));
    h = utils.atan2 b a;
    inherit (linear) a;
  };

  hexToOklch = hex: rgbToOklch (hexToRgb hex);

  oklchToRgb = { L, C, h, a }@lch: let 
    a = lch.C * utils.cos lch.h;
    b = lch.C * utils.sin lch.h;
    l = utils.powInt (lch.L + 0.3963377774 * a + 0.2158037573 * b) 3;
    m = utils.powInt (lch.L - 0.1055613458 * a - 0.0638541728 * b) 3;
    s = utils.powInt (lch.L - 0.0894841775 * a - 1.2914855480 * b) 3;
    linear = {
      r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
      g = (-1.2684380046) * l + 2.6097574011 * m - 0.3413193965 * s;
      b = (-0.0041960863) * l - 0.7034186147 * m + 1.7076147010 * s;
      inherit (lch) a;
    };
  in {
    r = utils.linearToSrgb linear.r;
    g = utils.linearToSrgb linear.g;
    b = utils.linearToSrgb linear.b;
    inherit (linear) a;
  };

  rgbToHex = { r, g, b, a }@rgb: let
    clamped = clamp {
      r = utils.round (rgb.r * 255.0);
      g = utils.round (rgb.g * 255.0);
      b = utils.round (rgb.b * 255.0);
      a = utils.round (rgb.a * 255.0);
    };
  in
    "#"
      + utils.alignedDecimalToHex clamped.r 2
      + utils.alignedDecimalToHex clamped.g 2
      + utils.alignedDecimalToHex clamped.b 2
      + (if clamped.a == 255 then "" else utils.alignedDecimalToHex clamped.a 2);

  oklchToHex = { L, C, h, a }@lch: rgbToHex (oklchToRgb lch);

  oklchsToHexes = oklchs: map (oklch: oklchToHex oklch) oklchs;

  lighten = { L, C, h, a }@lch: percent:
    lch // {
      L = lch.L + (percent / 100.0);
    };

  darken = { L, C, h, a }@lch: percent:
    lch // {
      L = lch.L - (percent / 100.0);
    };

  gradient = { L, C, h, a }@lch: { L, C, h, a }@another: steps:
    map (mod: {
      L = (1 - mod) * lch.L + mod * another.L;
      C = (1 - mod) * lch.C + mod * another.C;
      h = (1 - mod) * lch.h + mod * another.h;
      a = (1 - mod) * lch.a + mod * another.a;
    }) (modifiers steps);

  shades = { L, C, h, a }@lch: steps:
    gradient lch (lch // {
      L = 0.0;
      C = 0.0;
    }) steps;

  tints = { L, C, h, a }@lch: steps:
    gradient lch (lch // {
      L = 1.0;
      C = 0.0;
    }) steps;

  tones = { L, C, h, a }@lch: steps:
    gradient lch (lch // {
      C = 0.0;
    }) steps;

  polygon = { L, C, h, a }@lch: count: let
    count' = let
      rounded = utils.round count;
    in
      if rounded < 0 then (abort "Colors count must be positive number") else rounded;
    shifts = builtins.genList (x: 2 * utils.pi * x / (count' + 1)) (count' + 1);
  in
    map (shift: lch // {
      h = lch.h + shift;
    }) shifts;

  complementary = { L, C, h, a }@lch:
    builtins.elemAt (polygon lch 1) 1;

  analogous = { L, C, h, a }@lch:
    [
      (lch // {
        h = lch.h - (utils.pi / 6);
      })
      (lch // {
        h = lch.h + (utils.pi / 6);
      })
    ];

  splitComplementary = { L, C, h, a }@lch:
    analogous (complementary lch);

  hex = {
    lighten = hex: percent: oklchToHex (lighten (hexToOklch hex) percent);

    darken = hex: percent: oklchToHex (darken (hexToOklch hex) percent);

    gradient =
      hex: another: steps:
      oklchsToHexes (gradient (hexToOklch hex) (hexToOklch another) steps);

    shades = hex: steps: oklchsToHexes (shades (hexToOklch hex) steps);

    tints = hex: steps: oklchsToHexes (tints (hexToOklch hex) steps);

    tones = hex: steps: oklchsToHexes (tones (hexToOklch hex) steps);

    polygon = hex: count: oklchsToHexes (polygon (hexToOklch hex) count);

    complementary = hex: oklchToHex (complementary (hexToOklch hex));

    analogous = hex: oklchsToHexes (analogous (hexToOklch hex));

    splitComplementary = hex: oklchsToHexes (splitComplementary (hexToOklch hex));

    setAlpha = hex: alpha: let
      rgb = (hexToRgb hex) // { a = alpha / 100.0; };
    in rgbToHex rgb;

    stripAlpha = hex: let
      rgb = (hexToRgb hex) // { a = 1.0; };
    in rgbToHex rgb;

    incAlpha = hex: percent: let
      rgb = hexToRgb hex;
      inc = rgb // {
        a = rgb.a + (percent / 100.0);
      };
    in rgbToHex inc;

    decAlpha = hex: percent: let
      rgb = hexToRgb hex;
      dec = rgb // {
        a = rgb.a - (percent / 100.0);
      };
    in rgbToHex dec;
  };
}