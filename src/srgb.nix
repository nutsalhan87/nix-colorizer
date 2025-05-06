let
  math = import ./utils/math.nix;

  tr = (import ./utils/transform.nix) { inherit math; };

  clampSingle = x: if x > 255 then 255 else if x < 0 then 0 else x;

  clamp = { r, g, b, a }@args: 
    builtins.mapAttrs (name: val: (clampSingle val)) args;

in rec {
  to = {
    hex = { r, g, b, a }@srgb: let
      clamped = clamp {
        r = math.round (srgb.r * 255.0);
        g = math.round (srgb.g * 255.0);
        b = math.round (srgb.b * 255.0);
        a = math.round (srgb.a * 255.0);
      };
    in
      "#"
        + tr.alignedDecimalToHex clamped.r 2
        + tr.alignedDecimalToHex clamped.g 2
        + tr.alignedDecimalToHex clamped.b 2
        + (if clamped.a == 255 then "" else tr.alignedDecimalToHex clamped.a 2);

    hexes = srgbs: map (srgb: to.hex srgb) srgbs;

    oklch = { r, g, b, a }@srgb: let
      linear = {
        r = tr.srgbToLinear srgb.r;
        g = tr.srgbToLinear srgb.g;
        b = tr.srgbToLinear srgb.b;
        inherit (srgb) a;
      };
      l = math.cbrt (0.4122214708 * linear.r + 0.5363325363 * linear.g + 0.0514459929 * linear.b);
      m = math.cbrt (0.2119034982 * linear.r + 0.6806995451 * linear.g + 0.1073969566 * linear.b);
      s = math.cbrt (0.0883024619 * linear.r + 0.2817188376 * linear.g + 0.6299787005 * linear.b);
      L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
      a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
      b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    in {
      inherit L;
      C = math.sqrt ((math.powInt a 2) + (math.powInt b 2));
      h = math.atan2 b a;
      inherit (linear) a;
    };

    oklchs = srgbs: map (srgb: to.oklch srgb) srgbs;
  };
}