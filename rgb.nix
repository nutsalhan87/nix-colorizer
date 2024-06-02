rgb255ToHex:
let
  utils = import ./utils.nix;
  clampSingle = x: if x > 1.0 then 1.0 else if x < 0.0 then 0.0 else x;

  negativeDegreeToPositive = x: (1 - (x / 360)) * 360 + x;
  clampHue = hue: let degree = if hue < 0 then negativeDegreeToPositive hue else hue;
    in utils.mod degree 360;

  toHSVL = { r, g, b }: let
    xMax = utils.max (utils.max r g) b;
    xMin = utils.min (utils.min r g) b;
    c = xMax - xMin;
    l = (xMax + xMin) / 2.0;
    h = clampHue (utils.round (if c == 0 then 0 else
        if xMax == r then 60 * ((g - b) / c) else
        if xMax == g then 60 * ((b - r) / c + 2) else
        60 * ((r - g) / c + 4)));
    sV = if xMax == 0 then 0 else c / xMax;
    sL = if (l == 0 || l == 1) then 0 else (xMax - l) / (utils.min l (1 - l));
  in 
    {
      hsv = {
        inherit h;
        s = sV;
        v = xMax;
      };
      hsl = {
        inherit h l;
        s = sL;
      };
    };
in
{
  clamp = { r, g, b }@args: builtins.mapAttrs (name: val: (clampSingle val)) args;

  to = rec {
    hex = { r, g, b }@args: rgb255ToHex (rgb255 args);
    rgb255 = { r, g, b }@args: builtins.mapAttrs (name: val: utils.round (val * 255.0)) args;
    hsv = { r, g, b }@args: (toHSVL args).hsv;
    hsl = { r, g, b }@args: (toHSVL args).hsl;
  };

  add = { r, g, b }@self: { ... }@args: {
    r = self.r + (args.r or 0.0);
    g = self.g + (args.g or 0.0);
    b = self.b + (args.b or 0.0);
  };
  sub = { r, g, b }@self: { ... }@args: {
    r = self.r - (args.r or 0.0);
    g = self.g - (args.g or 0.0);
    b = self.b - (args.b or 0.0);
  };
  mul = { r, g, b }@self: { ... }@args: {
    r = self.r * (args.r or 1.0);
    g = self.g * (args.g or 1.0);
    b = self.b * (args.b or 1.0);
  };
  div = { r, g, b }@self: { ... }@args: {
    r = self.r / (args.r or 1.0);
    g = self.g / (args.g or 1.0);
    b = self.b / (args.b or 1.0);
  };
}