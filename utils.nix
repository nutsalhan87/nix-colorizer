let
  pi = 3.1415926535897932384626433832795028841971693993751058209749445923;
  
  merge = listOfAttrSets: builtins.foldl' (a: b: a // b) { } listOfAttrSets;
  
  decEnum = 
    (merge (map 
      (x: { "${builtins.toString x}" = x; }) 
      (builtins.genList (x: x) 10)
    ));
  
  symbols = str: builtins.genList (p: builtins.substring p 1 str) (builtins.stringLength str);
  
  repeatString = str: n: if n == 0 then "" else str + (repeatString str (n - 1));
  
  factorial = x: if x == 0 then 1 else builtins.foldl' (a: b: a * b) 1 (builtins.genList (i: i + 1) x);

  mod = base: int: base - (int * (builtins.div base int));

  abs = x: if x < 0 then x * (-1) else x;

  round = x: let 
    ceiled = builtins.ceil x; 
    floored = builtins.floor x; 
  in 
    if (x - floored) > (ceiled - x) then ceiled else floored;

  hexToDecimal = hex: let 
    hexEnum = decEnum
      // { "a" = 10; "A" = 10; "b" = 11; "B" = 11; "c" = 12; "C" = 12; "d" = 13; "D" = 13; "e" = 14; "E" = 14; "f" = 15; "F" = 15; };
  in
    builtins.foldl' (a: b: a * 16 + b) 0 (map (x: hexEnum.${x}) (symbols hex));

  decimalToHex = dec: let
    revHexEnum = decEnum // { "10" = "A"; "11" = "B"; "12" = "C"; "13" = "D"; "14" = "E"; "15" = "F"; };
    decimalToHexInner = dec: if dec == 0 
      then ""
      else decimalToHexInner (dec / 16) + builtins.toString revHexEnum.${builtins.toString (mod dec 16)};
    h = decimalToHexInner dec;
  in
    if (builtins.stringLength h) == 0 then "0" else h;

  alignedDecimalToHex = dec: minNums: let
    hex = decimalToHex dec;
    diff = minNums - (builtins.stringLength hex);
    zerosNum = if diff <= 0 then 0 else diff;
  in
    (repeatString "0" zerosNum) + hex;

  srgbToLinear = s:
    if s <= 0.0404482362771082 then
      s / 12.92
    else
      powFloat ((s + 0.055) / 1.055) 2.4;

  linearToSrgb = l:
    if l <= 0.00313066844250063 then
      l * 12.92
    else
      1.055 * (powFloat l (1 / 2.4)) - 0.055;

  powInt = x: n: if n == 0 then 1 else x * powInt x (n - 1);

  powFloat = x: a: exp (a * ln x);

  ln = x: let
    ln2 = 0.6931471805599453094172321214581765680755001343602552541206800094;
    normalize = base: order: 
      if base < 2.0 && base >= 1.0 then { inherit base order; } else
      if base >= 2.0 then normalize (base / 2.0) (order + 1) else
      normalize (base * 2.0) (order - 1);
    x' = normalize x 0;
    lnx = x: (-1.7417939) + (2.8212026 + ((-1.4699568) + (0.44717955 - 0.056570851 * x) * x) * x) * x;
  in
    if x <= 0.0 then abort "x must be > 0.0" else
    lnx x'.base + (x'.order * ln2);

  exp = x: let
    ln2Inv = 1.4426950408889634073599246810018921374266459541529859341354494069;
    sign = if x >= 0.0 then 1 else (-1);
    x' = x * sign * ln2Inv;
    truncated = builtins.floor x';
    fractated = x' - truncated;
    twoPowXPart = x: 
      1.41421 
      + 0.980258 * (x - 0.5) 
      + 0.339732 * powInt (x - 0.5) 2
      + 0.0784947 * powInt (x - 0.5) 3
      + 0.0136021 * powInt (x - 0.5) 4
      + 0.00188565 * powInt (x - 0.5) 5;
    res = (powInt 2 truncated) * twoPowXPart fractated;
  in
    if sign == 1 then res else 1.0 / res;

  sqrt = x: let
    power = if (abs x) > 1.0 then 1 else -1;
    x' = if power == 1 then 1.0 * x else 1.0 / x;
    epsilon = 0.0000001;
    bs = l: r: let
      mid = (l + r) / 2.0;
      mid2 = mid * mid;
    in
      if abs (mid2 - x') <= epsilon then mid
      else
        if mid2 < x' then bs mid r
        else bs l mid;
    y' = bs 0.0 x';
  in
    if x < 0.0 then abort "x must be positive number" else
    if x < epsilon then 0.0 else
    if power == 1 then y' else 1.0 / y';
  
  cbrt = x: let
    sign = if x >= 0.0 then 1 else -1;
    power = if (abs x) > 1.0 then 1 else -1;
    x' = (if power == 1 then 1.0 * x else 1.0 / x) * sign;
    epsilon = 0.0000001;
    bs = l: r: let
      mid = (l + r) / 2.0;
      mid3 = mid * mid * mid;
    in
      if abs (mid3 - x') <= epsilon then mid
      else
        if mid3 < x' then bs mid r
        else bs l mid;
    y' = sign * (bs 0.0 x');
  in
    if abs x < epsilon then 0.0 else
    if power == 1 then y' else 1.0 / y';

  sin = x: let
    oneDivSqrtTwo = 0.7071067811865475244008443621048490392848359376884740365883398689;
    pows = builtins.genList (i: { power = i; sign = if (mod (i / 2) 2) == 0 then 1 else -1; }) 11;
    sinPart = x: let
      argShift = x - (pi / 4.0);
    in
      if x < 0 || x > (pi / 2) then abort "Internal error: x must be in [0; pi/2]" else
      builtins.foldl' (a: b: a + b) 0 (
        map ({ power, sign }: 
          (powInt argShift power) * oneDivSqrtTwo * sign / (factorial power)
        ) pows
      );
    sign = if x >= 0.0 then 1.0 else -1.0;
    index = builtins.floor (2 * sign * x / pi);
    group = mod index 4;
    x' = sign * x - index * pi / 2;
  in
    sign * (if x == 0.0 then 0.0 else
    if group == 0 then sinPart x' else
    if group == 1 then sinPart (pi / 2 - x') else
    if group == 2 then sinPart (x') * (-1) else
    if group == 3 then sinPart (pi / 2 - x') * (-1) else
    abort "Internal error: Unexpected group");

  cos = x:
    if x == 0.0 then 1.0 else sin (x + pi / 2);

  arctan = x: let
    arctanPart = x: let
      xx = x * x;
      a = [ 0.00289394245323327 (-0.0162911733512761) 0.0431408641542157 
        (-0.0755120841589429) 0.10668127080775 (-0.142123340834229) 
        0.199940412794435 (-0.333331728467737) 1.0 ];
    in
      x * (builtins.foldl' (a: b: a * xx + b) 0 a);
    arctanPositive = x: 
      if x <= 1.0 then arctanPart x else pi / 2 - arctanPart (1.0 / x);
  in
    if x >= 0.0 then arctanPositive x else (-1.0) * arctanPositive (-x);

  atan2 = y: x:
    if x > 0 then arctan (y * 1.0 / x) else
    if x < 0 && y >= 0 then arctan (y * 1.0 / x) + pi else
    if x < 0 && y < 0 then arctan (y * 1.0 / x) - pi else
    if x == 0 && y > 0 then pi / 2 else
    if x == 0 && y < 0 then (-1) * pi / 2 else
    0.0;
in
rec {
  inherit alignedDecimalToHex hexToDecimal 
    srgbToLinear linearToSrgb 
    powInt 
    sqrt cbrt 
    pi sin cos atan2 
    round;
  inherit arctan exp ln;
}