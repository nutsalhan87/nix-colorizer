{
  description = "Color adjustment in Nix";

  outputs = { self }: let 
    srgb = import ./src/srgb.nix;
    oklch = (import ./src/oklch.nix) { inherit srgb; };
    hex = (import ./src/hex.nix) { inherit oklch srgb; };
  in 
    { inherit oklch hex srgb; };
}
