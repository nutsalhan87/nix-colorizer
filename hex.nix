rgb255ToRgb:
let
  utils = import ./utils.nix;
in
{
  to = rec {
    rgb255 = hex: {
      r = utils.hexToDecimal (builtins.substring 1 2 hex);
      g = utils.hexToDecimal (builtins.substring 3 2 hex);
      b = utils.hexToDecimal (builtins.substring 5 2 hex);
    };
    rgb = hex: rgb255ToRgb (rgb255 hex);
  };
}