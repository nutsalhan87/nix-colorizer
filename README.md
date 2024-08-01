# Nix colorizer

Adjust your colors or calculate new harmony colors.

Everything is calculating in the oklch model. Therefore the flake have functions that convert hex color to oklch and vice versa.

## Install
Add `nix-colorizer` to flake inputs:
```nix
inputs.nix-colorizer.url = "github:nutsalhan87/nix-colorizer";
```

Then pass to `specialArgs` for NixOS configuration or to `extraSpecialArgs` for Home Manager configuration:
```nix
outputs = { nixpkgs, nix-colorizer, ... }: {
    nixosConfigurations = {
        # ...
      foo = nixpkgs.lib.nixosSystem {
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

## Functions

* `hexToOklch: hex -> oklch` - Convert hex to oklch.
  
  _hex_ is string in format #AAAAAA.

* `oklchToHex: oklch -> hex` - Convert oklch to hex.
  
  _oklch_ is attrset like { L, C, h }.

* `oklchsToHexes: [oklch] -> [hex]` - Convert many oklch attrsets to hex strings.

* `lighten: oklch, percent -> oklch` - Increase lightness of color.
  
  Increasing by _percent_ means that lightness just will simply be summed up, not multiplied.

* `darken: oklch, percent -> oklch` - Decrease lightness of color.

  Behaviour is similar to `lighten` but decreases lightness.

* `gradient: oklch, oklch, steps -> [oklch]` - Calculates colors that change uniformly from the first to the second.

  _steps_ means number of color between first and second. So, if you call `gradient a b 2`, as result you'll get list with 4 colors.

* `shades: oklch, steps -> [oklch]` - Calculates colors that change uniformly from the passed to black.

  _steps_ means the same as `gradient`.

* `tints: oklch, steps -> [oklch]` - Calculates colors that change uniformly from the passed to white.

  _steps_ means the same as `gradient`.

* `tones: okclh, steps -> [oklch]` - Calculates colors that change uniformly from the passed to grey by decreasing its chroma.

  _steps_ means the same as `gradient`.

* `polygon: oklch, count -> [oklch]` - Calculates colors that evenly distrubuted on the hue wheel.

  _count_ means number of colors in addition to the passed. So there will be _count + 1_ colors in the result list.

  Example: `polygon a 1` will return the passed color and its complementary color, `polygon a 2` - traidic, `polygon a 3` - square.

* `complementary: oklch -> oklch` - Calculates complementary color for the passed one.

* `analoguos: oklch -> [oklch]` - Calculates two analogous colors for the passed one.

  Returns list with two color - first is 30 degree anti-clockwise for the passed one and second - 30 degree clockwise.

* `splitComplementary: oklch -> [oklch]` - Calculates split-complementary color for the passed one.

  I.e. analogous colors for complementary color for the passed one.

## Some notes

1. Oklch is wider than sRGB. So some colors just won't fit when converting to hex. Therefore they will be just clamped to sRGB bounds - no smart converting.

2. If you want change `{ L, C, h }` attrset by yourself, note that _L_ is float in [0; 1] and _h_ is in radians.
