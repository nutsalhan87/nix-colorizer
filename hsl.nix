let
  utils = import ./utils.nix;
  clampSingle = x: if x > 1.0 then 1.0 else if x < 0.0 then 0.0 else x;
  negativeDegreeToPositive = x: ((x / 360) * (-1) + 1) * 360 + x;
  clampHue = hue: let degree = if hue < 0 then negativeDegreeToPositive hue else hue;
    in utils.mod degree 360;
in
{
  clamp = { h, s, l }: {
    h = clampHue h;
    s = clampSingle s;
    l = clampSingle l;
  };

  to = {
    hsv = { h, s, l }: let
      v = s * (utils.min l (1 - l)) + l;
      sV = if v == 0 then 0 else
        2 * (1 - (l / v));  
    in {
      inherit h v;
      s = sV;
    };

    rgb = { h, s, l }: let
      c = s * (1 - (utils.abs (2 * l - 1)));
      h' = (clampHue h) / 60.0;
      x = c * (1 - utils.abs ((utils.fmod h' 2) - 1));
      rgb' = if (h' >= 0 && h' < 1) then { r = c; g = x; b = 0; } else
            if (h' >= 1 && h' < 2) then { r = x; g = c; b = 0; } else
            if (h' >= 2 && h' < 3) then { r = 0; g = c; b = x; } else
            if (h' >= 3 && h' < 4) then { r = 0; g = x; b = c; } else
            if (h' >= 4 && h' < 5) then { r = x; g = 0; b = c; } else
                                        { r = c; g = 0; b = x; };
      m = l - (c / 2);
    in builtins.mapAttrs (name: value: value + m) rgb';
  };

  add = { h, s, l }@self: { ... }@args: {
    h = clampHue (self.h + (args.h or 0));
    s = self.s + (args.s or 0.0);
    l = self.l + (args.l or 0.0);
  };
  sub = { h, s, l }@self: { ... }@args: {
    h = clampHue (self.h - (args.h or 0));
    s = self.s - (args.s or 0.0);
    l = self.l - (args.l or 0.0);
  };
  mul = { h, s, l }@self: { ... }@args: {
    inherit h;
    s = self.s * (args.s or 1.0);
    l = self.l * (args.l or 1.0);
  };
  div = { h, s, l }@self: { ... }@args: {
    inherit h;
    s = self.s / (args.s or 1.0);
    l = self.l / (args.l or 1.0);
  };
}