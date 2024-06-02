rec {
  max = x: y: if x > y then x else y;
  min = x: y: if x < y then x else y;

  mod = base: int: base - (int * (builtins.div base int));
  fmod = divisible: divisor: let
    flooredDivisible = builtins.floor divisible;
  in
    (mod flooredDivisible divisor) + divisible - flooredDivisible;

  abs = x: if x < 0 then x * (-1) else x;

  round = x: let 
    ceiled = builtins.ceil x; 
    floored = builtins.floor x; 
  in 
    if (x - floored) > (ceiled - x) then ceiled else floored;

  symbols = str: builtins.genList (p: builtins.substring p 1 str) (builtins.stringLength str);

  merge = listOfAttrSets: builtins.foldl' (a: b: a // b) { } listOfAttrSets;
}