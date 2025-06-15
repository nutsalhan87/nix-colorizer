{ nixColorizer, testUtils }:

let
  epsilon = 0.0001;
  
  testColors = rec {
    red = {
      hex = "#FF0000";
      srgb = { r = 1.0; g = 0.0; b = 0.0; a = 1.0; };
      oklch = { L = 0.628; C = 0.2577; h = 0.5102; a = 1.0; };
    };
    
    green = {
      hex = "#00FF00";
      srgb = { r = 0.0; g = 1.0; b = 0.0; a = 1.0; };
      oklch = { L = 0.8664; C = 0.2948; h = 2.487; a = 1.0; };
    };
    
    blue = {
      hex = "#0000FF";
      srgb = { r = 0.0; g = 0.0; b = 1.0; a = 1.0; };
      oklch = { L = 0.452; C = 0.3132; h = 4.6086; a = 1.0; };
    };
    
    white = {
      hex = "#FFFFFF";
      srgb = { r = 1.0; g = 1.0; b = 1.0; a = 1.0; };
      oklch = { L = 1.0; C = 0.0; h = 0.0; a = 1.0; };
    };
    
    black = {
      hex = "#000000";
      srgb = { r = 0.0; g = 0.0; b = 0.0; a = 1.0; };
      oklch = { L = 0.0; C = 0.0; h = 0.0; a = 1.0; };
    };
    
    gray = {
      hex = "#808080";
      srgb = { r = 0.502; g = 0.502; b = 0.502; a = 1.0; };
      oklch = { L = 0.5999; C = 0.0; h = 0.0; a = 1.0; };
    };
    
    redWithAlpha = {
      hex = "#FF000080";
      srgb = red.srgb // { a = 0.502; };
      oklch = red.oklch // { a = 0.502; };
    };
  };

in {
  testHexToSrgbRed = {
    description = "Convert red hex to sRGB";
    expr = nixColorizer.hex.to.srgb testColors.red.hex;
    expected = testColors.red.srgb;
  };
  
  testSrgbToHexRed = {
    description = "Convert red sRGB to hex";
    expr = nixColorizer.srgb.to.hex testColors.red.srgb;
    expected = testColors.red.hex;
  };
  
  testHexToSrgbWhite = {
    description = "Convert white hex to sRGB";
    expr = nixColorizer.hex.to.srgb testColors.white.hex;
    expected = testColors.white.srgb;
  };
  
  testHexToSrgbBlack = {
    description = "Convert black hex to sRGB";
    expr = nixColorizer.hex.to.srgb testColors.black.hex;
    expected = testColors.black.srgb;
  };
  
  testHexWithAlphaToSrgb = {
    description = "Convert hex with alpha to sRGB";
    expr = let
      result = nixColorizer.hex.to.srgb testColors.redWithAlpha.hex;
      expected = testColors.redWithAlpha.srgb;
    in
      testUtils.srgbApproxEqual result expected epsilon;
    expected = true;
  };
  
  testHexSrgbRoundTrip = {
    description = "Hex -> sRGB -> Hex round trip";
    expr = nixColorizer.srgb.to.hex (nixColorizer.hex.to.srgb testColors.red.hex);
    expected = testColors.red.hex;
  };
  
  testSrgbHexRoundTrip = {
    description = "sRGB -> Hex -> sRGB round trip";
    expr = let
      original = testColors.green.srgb;
      converted = nixColorizer.hex.to.srgb (nixColorizer.srgb.to.hex original);
    in
      testUtils.srgbApproxEqual original converted epsilon;
    expected = true;
  };
  
  testHexOklchRoundTrip = {
    description = "Hex -> OKLCH -> Hex round trip";
    expr = nixColorizer.oklch.to.hex (nixColorizer.hex.to.oklch testColors.blue.hex);
    expected = testColors.blue.hex;
  };
  
  testSrgbOklchRoundTrip = {
    description = "sRGB -> OKLCH -> sRGB round trip";
    expr = let
      original = testColors.gray.srgb;
      converted = nixColorizer.oklch.to.srgb (nixColorizer.srgb.to.oklch original);
    in
      testUtils.srgbApproxEqual original converted epsilon;
    expected = true;
  };
  
  testOklchSrgbRoundTrip = {
    description = "OKLCH -> sRGB -> OKLCH round trip";
    expr = let
      original = testColors.white.oklch;
      converted = nixColorizer.srgb.to.oklch (nixColorizer.oklch.to.srgb original);
    in
      testUtils.oklchApproxEqual original converted epsilon;
    expected = true;
  };
  
  testAlphaPreservationHexToSrgb = {
    description = "Alpha channel preserved in hex to sRGB conversion";
    expr = let
      hexWithAlpha = "#FF000080";  # 50% of alpha
      result = nixColorizer.hex.to.srgb hexWithAlpha;
    in
      testUtils.approxEqual result.a 0.502 epsilon;
    expected = true;
  };
  
  testAlphaPreservationSrgbToHex = {
    description = "Alpha channel preserved in sRGB to hex conversion";
    expr = nixColorizer.srgb.to.hex testColors.redWithAlpha.srgb;
    expected = "#FF000080";
  };
}