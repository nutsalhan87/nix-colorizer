let
  utils = import ./utils.nix;
  clampSingle = x: if x > 255 then 255 else if x < 0 then 0 else x;
in
rec {
  clamp = { r, g, b }@args: 
    builtins.mapAttrs (name: val: (clampSingle val)) args;

  to = {
    hex = { r, g, b }@args: let 
      clamped = clamp args;
    in
      "#" + utils.alignedDecimalToHex clamped.r 2 + utils.alignedDecimalToHex clamped.g 2 + utils.alignedDecimalToHex clamped.b 2;

    rgb = { r, g, b }@args: builtins.mapAttrs (name: val: val / 255.0) args;
  };

  add = { r, g, b }@self: { ... }@args: {
    r = self.r + (args.r or 0);
    g = self.g + (args.g or 0);
    b = self.b + (args.b or 0);
  };
  sub = { r, g, b }@self: { ... }@args: {
    r = self.r - (args.r or 0);
    g = self.g - (args.g or 0);
    b = self.b - (args.b or 0);
  };
}