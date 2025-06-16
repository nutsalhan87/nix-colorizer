# Nix colorizer

Adjust your colors or calculate new harmony colors.

Everything is calculated in the oklch model. Therefore the flake has functions to convert between hex, sRGB and oklch and provides useful functions for generating derived palettes.

## Install

Add `nix-colorizer` to flake inputs:

```nix
inputs.nix-colorizer.url = "github:nutsalhan87/nix-colorizer";
```

Then pass to `specialArgs` for NixOS configuration or to `extraSpecialArgs` for Home Manager configuration:

```nix
outputs = { nixpkgs, nix-colorizer, ... }: {
  nixosConfigurations = {
    foo = nixpkgs.lib.nixosSystem {
      # ...
      specialArgs = { inherit nix-colorizer; };
    };
  };

  homeConfigurations = {
    "bar@baz" = home-manager.lib.homeManagerConfiguration {
      # ...
      extraSpecialArgs = { inherit nix-colorizer; };
    };
  };
};
```

## Modules and functions

Functions operate with these types:

* `hex` is a string in #AABBCC or #AABBCCDD format with lowercase letters support

* `srgb` is an attrset in the format `{ r, g, b, a }` where all values are in [0; 1] range

* `oklch` is an attrset in the format `{ L, C, h, a }` where `L` and `a` are in [0; 1] range and h is in radians 

The flake exposes a single attrset, structured by color models:

```nix
{
  hex = { ... };
  oklch = { ... };
  srgb = { ... };
}
```

All of them have `to` attrset with conversion functions:

* `hex.to`
  
  * `oklch: hex -> oklch` — convert hex to oklch

  * `oklchs: [hex] -> [oklch]` — convert many hex strings to oklch attrsets
  
  * `srgb: hex -> srgb` — convert hex to srgb
  
  * `srgbs: [hex] -> [srgb]` — convert many hex strings to srgb attrsets

* `oklch.to`

  * `hex: oklch -> hex` — convert oklch to hex

  * `hexes: [oklch] -> [hex]` — convert many oklch attrsets to hex strings 

  * `srgb: oklch -> srgb` — convert oklch to srgb

  * `srgbs: oklch -> srgb` — convert many oklch attrsets to srgb attrsets

* `srgb.to`

  * `hex: srgb -> hex` — convert srgb to hex

  * `hexes: [srgb] -> [hex]` — convert many srgb attrsets to hex strings 

  * `oklch: srgb -> oklch` — convert srgb to oklch

  * `oklchs: [srgb] -> [oklch]` — convert many srgb attrsets to oklch attrsets

**Important thing**. If alpha channel is 1.0 and you are converting color to hex, it will be converted to #AABBCC format, i.e. without alpha channel. 

Modules `hex` and `oklch` provide color modification and generation functions. These functions have similar syntax between modules but you must notice an important thing: all modifications are done internally in oklch and clamped to sRGB when converting back to hex. So if you are doing a chain of color modifications, do it in oklch mode. Otherwise it is more convenient to do it in the hex mode to avoid unnecessary function calls that convert hex color to oklch and back. The functions are:

* `lighten: color, value -> color` — increase lightness of color

  Increasing by _value_ means that lightness just will simply be summed up.

  Example: lightening `#808080` on 0.2 is `#BDBDBD` and lightening oklch's `{ L = 0.6; ... }` on 0.2 is `{ L = 0.8; ... }`.

* `darken: color, value -> color` — decrease lightness of color

  Behaviour is similar to `lighten` but decreases lightness.

* `blend: color, color, mod -> color` — calculates color that smoothly transitioned from the first one to the second one by a given modifier

* `gradient: color, color, steps -> [color]` — calculates colors that change uniformly from the first to the second

  _steps_ is the number of color between the first and the second. So, if you call `gradient a b 2`, as result you'll get list with 4 colors.

* `shades: color, steps -> [color]` — calculates colors that change uniformly from the passed to black

* `tints: color, steps -> [color]` — calculates colors that change uniformly from the passed to white

* `tones: color, steps -> [color]` — calculates colors that change uniformly from the passed to grey by decreasing its chroma

* `polygon: color, count -> [color]` — calculates colors that evenly distributed on the hue wheel

  _count_ means number of colors in addition to the passed. So there will be _count + 1_ colors in the result list.

  Example: `polygon a 1` will return the passed color and its complementary color, `polygon a 2` — triadic, `polygon a 3` — square.

* `complementary: color -> color` — calculates complementary color for the passed one

* `analogous: color -> [color]` — calculates two analogous colors for the passed one

  Returns list with two color — first is 30 degree anti-clockwise for the passed one and second — 30 degree clockwise.

* `splitComplementary: color -> [color]` — calculates split-complementary color for the passed one

  I.e. analogous colors for complementary color for the passed one.

Finally, the `hex` module also includes functions for working with alpha channel:

* `setAlpha: hex, value -> hex` — set alpha channel in the hex color

  If you set it to 1.0, the alpha channel will be stripped from the output hex string. So if you want to preserve this information, just write `hexColor + "FF"`.

* `stripAlpha: hex -> hex` — set alpha channel to 1.0

* `incAlpha: hex, value -> hex` — increase alpha

* `decAlpha: hex, value -> hex` — decrease alpha

## Some notes

1. Oklch is wider than sRGB. So some colors just won't fit when converting to hex. Therefore they will be just clamped to sRGB bounds — no smart converting.

2. Alpha channel is preserved across conversions. However, hex format only supports 8-bit alpha, so precision may slightly degrade when converting back and forth.

3. All color math (lighten, shades, polygon etc.) is performed in the oklch space for perceptual uniformity.

4. There are tests available, and you can run them. Run `nix repl` and execute there `:p import ./tests.nix`. It will print a list with information about failed tests: their names and descriptions — what should be and what didn't happen. Thus, if it prints an empty list, all tests have passed.
