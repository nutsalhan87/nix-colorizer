let
  pkgs = (import <nixpkgs> {});
  
  nixColorizer = (import ./flake.nix).outputs { self = ./.; };
  
  math = import ./src/utils/math.nix;

  testUtils = rec {
    abs = x: if x < 0 then x * (-1) else x;
    
    approxEqual = a: b: epsilon: (abs (a - b)) < epsilon;
    
    srgbApproxEqual = color1: color2: epsilon: 
      (approxEqual color1.r color2.r epsilon) &&
      (approxEqual color1.g color2.g epsilon) &&
      (approxEqual color1.b color2.b epsilon) &&
      (approxEqual color1.a color2.a epsilon);
    
    oklchApproxEqual = color1: color2: epsilon:
      let
        chromaThreshold = 0.1;
        minChroma = if color1.C < color2.C then color1.C else color2.C;
        chromaFactor = if minChroma >= chromaThreshold then 1.0 else (minChroma / chromaThreshold);
        hueEpsilon = epsilon + (1.0 - chromaFactor) * (2.0 * math.pi);
      in
        (testUtils.approxEqual color1.L color2.L epsilon) &&
        (testUtils.approxEqual color1.C color2.C epsilon) &&
        (testUtils.approxEqual color1.h color2.h hueEpsilon) &&
        (testUtils.approxEqual color1.a color2.a epsilon);
    
    isValidHex = hex: 
      builtins.isString hex &&
      (builtins.stringLength hex == 7 || builtins.stringLength hex == 9) &&
      (builtins.substring 0 1 hex == "#");
  };

  conversionTests = import ./tests/conversion.nix { inherit nixColorizer testUtils; };
  validationTests = import ./tests/validation.nix { inherit nixColorizer testUtils; };

  allTests = 
    conversionTests //
    validationTests;

  results = pkgs.lib.debug.runTests allTests;
in
  map (result: result // { inherit (allTests.${result.name}) description; }) results