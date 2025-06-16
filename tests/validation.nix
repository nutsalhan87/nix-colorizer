{ nixColorizer, testUtils }:

{
  testSrgbOutputBounds = {
    description = "sRGB output values are within [0,1] bounds";
    expr = let
      testHex = "#FF8000";
      result = nixColorizer.hex.to.srgb testHex;
    in
      (result.r >= 0.0 && result.r <= 1.0) &&
      (result.g >= 0.0 && result.g <= 1.0) &&
      (result.b >= 0.0 && result.b <= 1.0) &&
      (result.a >= 0.0 && result.a <= 1.0);
    expected = true;
  };

  testOklchOutputBounds = {
    description = "OKLCH output values are within valid bounds";
    expr = let
      testSrgb = { r = 0.8; g = 0.3; b = 0.6; a = 0.9; };
      result = nixColorizer.srgb.to.oklch testSrgb;
    in
      (result.L >= 0.0 && result.L <= 1.0) &&   # Lightness [0;1]
      result.C >= 0.0 &&                        # Chroma >= 0
      (result.a >= 0.0 && result.a <= 1.0);     # Alpha [0;1]
    expected = true;
  };

  testHexOutputFormat = {
    description = "Hex output has correct format";
    expr = let
      testSrgb = { r = 1.0; g = 0.5; b = 0.0; a = 1.0; };
      result = nixColorizer.srgb.to.hex testSrgb;
    in
      testUtils.isValidHex result;
    expected = true;
  };

  testHexAlphaFormat = {
    description = "Hex with alpha has correct format";
    expr = let
      testSrgb = { r = 1.0; g = 0.0; b = 0.0; a = 0.5; };
      result = nixColorizer.srgb.to.hex testSrgb;
    in
      testUtils.isValidHex result && builtins.stringLength result == 9;
    expected = true;
  };

  testSrgbClamping = {
    description = "Out-of-range sRGB values are clamped";
    expr = let
      overflowColor = { r = 1.5; g = -0.2; b = 0.8; a = 2.0; };
      result = nixColorizer.srgb.to.hex overflowColor;
    in
      testUtils.isValidHex result;
    expected = true;
  };

  testAlphaConsistency = {
    description = "Alpha channel remains consistent through conversions";
    expr = let
      originalAlpha = 0.75;
      testColor = { r = 0.6; g = 0.4; b = 0.8; a = originalAlpha; };
      hexResult = nixColorizer.srgb.to.hex testColor;
      backToSrgb = nixColorizer.hex.to.srgb hexResult;
    in
      testUtils.approxEqual backToSrgb.a originalAlpha (1.0 / 255.0);
    expected = true;
  };
}