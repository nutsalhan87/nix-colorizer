let
  utils = import ./utils.nix;
  clampSingle = x: if x > 1.0 then 1.0 else if x < 0.0 then 0.0 else x;
  negativeDegreeToPositive = x: ((x / 360) * (-1) + 1) * 360 + x;
  clampHue = hue: let degree = if hue < 0 then negativeDegreeToPositive hue else hue;
    in utils.mod degree 360;
in
{
  clamp = { h, s, v }: {
    h = clampHue h;
    s = clampSingle s;
    v = clampSingle v;
  };

  to = {
    hsl = { h, s, v }: let
      l = v * (1 - (s / 2));
      sL = if (l == 0 || l == 1) then 0 else
        (v - l) / (utils.min l (1 - l));
    in {
      inherit h l;
      s = sL;
    };

    rgb = { h, s, v }: let
      c = v * s;
      h' = (clampHue h) / 60.0;
      x = c * (1 - utils.abs ((utils.fmod h' 2) - 1));
      rgb' = if (h' >= 0 && h' < 1) then { r = c; g = x; b = 0; } else
            if (h' >= 1 && h' < 2) then { r = x; g = c; b = 0; } else
            if (h' >= 2 && h' < 3) then { r = 0; g = c; b = x; } else
            if (h' >= 3 && h' < 4) then { r = 0; g = x; b = c; } else
            if (h' >= 4 && h' < 5) then { r = x; g = 0; b = c; } else
                                        { r = c; g = 0; b = x; };
      m = v - c;
    in builtins.mapAttrs (name: value: value + m) rgb';
  };

  add = { h, s, v }@self: { ... }@args: {
    h = clampHue (self.h + (args.h or 0));
    s = self.s + (args.s or 0.0);
    v = self.v + (args.v or args.b or 0.0);
  };
  sub = { h, s, v }@self: { ... }@args: {
    h = clampHue (self.h - (args.h or 0));
    s = self.s - (args.s or 0.0);
    v = self.v - (args.v or args.b or 0.0);
  };
  mul = { h, s, v }@self: { ... }@args: {
    inherit h;
    s = self.s * (args.s or 1.0);
    v = self.v * (args.v or args.b or 1.0);
  };
  div = { h, s, v }@self: { ... }@args: {
    inherit h;
    s = self.s / (args.s or 1.0);
    v = self.v / (args.v or args.b or 1.0);
  };
}