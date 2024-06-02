let
  utils = import ./utils.nix;
  clampSingle = x: if x > 255 then 255 else if x < 0 then 0 else x;
  
  revHexEnum = 
    (utils.merge (map 
      (x: { "${builtins.toString x}" = x; }) 
      (builtins.genList (x: x) 10)
    ))
    // { "10" = "A"; "11" = "B"; "12" = "C"; "13" = "D"; "14" = "E"; "15" = "F"; };
  decimalToHex = dec: if dec == 0 
    then "" 
    else decimalToHex (dec / 16) + builtins.toString revHexEnum.${builtins.toString (utils.mod dec 16)};
  alignedDecimalToHex = dec: let 
    hex = decimalToHex dec;
    hexLen = builtins.stringLength hex; 
  in
    if hexLen == 2 then hex else if hexLen == 1 then "0" + hex else "00";
in
rec {
  clamp = { r, g, b }@args: 
    builtins.mapAttrs (name: val: (clampSingle val)) args;

  to = {
    hex = { r, g, b }@args: let 
      clamped = clamp args;
    in
      "#" + alignedDecimalToHex clamped.r + alignedDecimalToHex clamped.g + alignedDecimalToHex clamped.b;

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