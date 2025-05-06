{ srgb }:

let
  math = import ./utils/math.nix;

  tr = (import ./utils/transform.nix) { inherit math; };

  modifiers = steps: let 
    steps' = let
      rounded = math.round steps;
    in
      if rounded < 0 then (abort "Steps count must be positive number") else rounded;
  in
    builtins.genList (x: x / (steps' + 1.0)) (steps' + 2);

in rec {
  to = {
    hex = { L, C, h, a }@lch: srgb.to.hex (to.srgb lch);

    hexes = oklchs: map (oklch: to.hex oklch) oklchs;

    srgb = { L, C, h, a }@lch: let 
      a = lch.C * math.cos lch.h;
      b = lch.C * math.sin lch.h;
      l = math.powInt (lch.L + 0.3963377774 * a + 0.2158037573 * b) 3;
      m = math.powInt (lch.L - 0.1055613458 * a - 0.0638541728 * b) 3;
      s = math.powInt (lch.L - 0.0894841775 * a - 1.2914855480 * b) 3;
      linear = {
        r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
        g = (-1.2684380046) * l + 2.6097574011 * m - 0.3413193965 * s;
        b = (-0.0041960863) * l - 0.7034186147 * m + 1.7076147010 * s;
        inherit (lch) a;
      };
    in {
      r = tr.linearToSrgb linear.r;
      g = tr.linearToSrgb linear.g;
      b = tr.linearToSrgb linear.b;
      inherit (linear) a;
    };

    srgbs = oklchs: map (oklch: to.srgb oklch) oklchs;
  };
  
  lighten = { L, C, h, a }@lch: percent:
    lch // {
      L = lch.L + (percent / 100.0);
    };

  darken = { L, C, h, a }@lch: percent:
    lch // {
      L = lch.L - (percent / 100.0);
    };

  blend = { L, C, h, a }@lch: { L, C, h, a }@another: percent: let
    mod = percent / 100.0;
  in {
    L = (1 - mod) * lch.L + mod * another.L;
    C = (1 - mod) * lch.C + mod * another.C;
    h = (1 - mod) * lch.h + mod * another.h;
    a = (1 - mod) * lch.a + mod * another.a;
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
      rounded = math.round count;
    in
      if rounded < 0 then (abort "Colors count must be positive number") else rounded;
    shifts = builtins.genList (x: 2 * math.pi * x / (count' + 1)) (count' + 1);
  in
    map (shift: lch // {
      h = lch.h + shift;
    }) shifts;

  complementary = { L, C, h, a }@lch:
    builtins.elemAt (polygon lch 1) 1;

  analogous = { L, C, h, a }@lch:
    [
      (lch // {
        h = lch.h - (math.pi / 6);
      })
      (lch // {
        h = lch.h + (math.pi / 6);
      })
    ];

  splitComplementary = { L, C, h, a }@lch:
    analogous (complementary lch);
}