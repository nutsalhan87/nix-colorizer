rgb255ToRgb:
let
  utils = import ./utils.nix;
  hexEnum =
    (utils.merge (map 
      (x: { "${builtins.toString x}" = x; }) 
      (builtins.genList (x: x) 10)
    ))
    // { "a" = 10; "A" = 10; "b" = 11; "B" = 11; "c" = 12; "C" = 12; "d" = 13; "D" = 13; "e" = 14; "E" = 14; "f" = 15; "F" = 15; };
  hexToDecimal = hex: builtins.foldl' (a: b: a * 16 + b) 0 
    (map (x: hexEnum.${x}) (utils.symbols hex));
in
{
  to = rec {
    rgb255 = hex: {
      r = hexToDecimal (builtins.substring 1 2 hex);
      g = hexToDecimal (builtins.substring 3 2 hex);
      b = hexToDecimal (builtins.substring 5 2 hex);
    };
    rgb = hex: rgb255ToRgb (rgb255 hex);
  };
}