{
  description = "Color adjustment in Nix";

  outputs = { self }: rec {
    rgb255 = import ./rgb255.nix;
    hex = import ./hex.nix rgb255.to.rgb;
    rgb = import ./rgb.nix rgb255.to.hex;
    hsv = import ./hsv.nix;
    hsl = import ./hsl.nix;
  };
}
