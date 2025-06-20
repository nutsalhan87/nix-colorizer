{ math }: 

let
  merge = listOfAttrSets: builtins.foldl' (a: b: a // b) { } listOfAttrSets;

  decEnum = 
    (merge (map 
      (x: { "${builtins.toString x}" = x; }) 
      (builtins.genList (x: x) 10)
    ));

  symbols = str: builtins.genList (p: builtins.substring p 1 str) (builtins.stringLength str);

  repeatString = str: n: if n == 0 then "" else str + (repeatString str (n - 1));

  decimalToHex = dec: let
    revHexEnum = decEnum // { "10" = "A"; "11" = "B"; "12" = "C"; "13" = "D"; "14" = "E"; "15" = "F"; };
    decimalToHexInner = dec: if dec == 0 
      then ""
      else decimalToHexInner (dec / 16) + builtins.toString revHexEnum.${builtins.toString (math.mod dec 16)};
    h = decimalToHexInner dec;
  in
    if (builtins.stringLength h) == 0 then "0" else h;

in rec {
  hexToDecimal = hex: let 
    hexEnum = decEnum
      // { "a" = 10; "A" = 10; "b" = 11; "B" = 11; "c" = 12; "C" = 12; "d" = 13; "D" = 13; "e" = 14; "E" = 14; "f" = 15; "F" = 15; };
  in
    builtins.foldl' (a: b: a * 16 + b) 0 (map (x: hexEnum.${x}) (symbols hex));

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
      math.powFloat ((s + 0.055) / 1.055) 2.4;

  linearToSrgb = l:
    if l <= 0.00313066844250063 then
      l * 12.92
    else
      1.055 * (math.powFloat l (1 / 2.4)) - 0.055;
}