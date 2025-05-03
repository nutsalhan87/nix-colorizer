from dataclasses import dataclass
from typing import Callable, Iterable
import matplotlib.pyplot as plt
import numpy as np
import subprocess


def template_single_fn(fn: str, x: Iterable[float]) -> list[float]:
    ser = (
        "[ "
        + " ".join(map(lambda x: f"({np.format_float_positional(x, trim='-')})", x))
        + " ]"
    )
    result = subprocess.run(
        [
            "nix",
            "eval",
            "--expr",
            f"let utils = import ./utils.nix; in (map (x: utils.{fn} x) {ser})",
            "--impure",
        ],
        capture_output=True,
    )
    if len(result.stderr) != 0:
        print(str(result.stderr).replace("\\n", "\n"))
        raise Exception()
    return list(map(float, result.stdout.split()[1:-1]))


def sqrt(x: Iterable[float]) -> list[float]:
    return template_single_fn("sqrt", x)


def cbrt(x: Iterable[float]) -> list[float]:
    return template_single_fn("cbrt", x)


def sin(x: Iterable[float]) -> list[float]:
    return template_single_fn("sin", x)


def cos(x: Iterable[float]) -> list[float]:
    return template_single_fn("cos", x)


def arctan(x: Iterable[float]) -> list[float]:
    return template_single_fn("arctan", x)


def srgbToLinear(x: Iterable[float]) -> list[float]:
    return template_single_fn("srgbToLinear", x)


def linearToSrgb(x: Iterable[float]) -> list[float]:
    return template_single_fn("linearToSrgb", x)


def ln(x: Iterable[float]) -> list[float]:
    return template_single_fn("ln", x)


def exp(x: Iterable[float]) -> list[float]:
    return template_single_fn("exp", x)


def srgbToLinearPy(x: Iterable[float]) -> list[float]:
    ret = []
    for s in x:
        if s <= 0.0404482362771082:
            ret.append(s / 12.92)
        else:
            ret.append(((s + 0.055) / 1.055) ** 2.4)
    return ret


def linearToSrgbPy(x: Iterable[float]) -> list[float]:
    ret = []
    for l in x:
        if l <= 0.00313066844250063:
            ret.append(l * 12.92)
        else:
            ret.append(1.055 * l ** (1 / 2.4) - 0.055)
    return ret


border = 10


@dataclass
class TestCase:
    start: float
    stop: float
    testing: Callable[[Iterable[float]], Iterable[float]]
    ideal: Callable[[Iterable[float]], np.ndarray]


test_cases = {
    "sqrt": TestCase(0, border, sqrt, lambda x: np.sqrt(np.array(x))),
    "cbrt": TestCase(-border, border, cbrt, lambda x: np.cbrt(np.array(x))),
    "sin": TestCase(-border, border, sin, lambda x: np.sin(np.array(x))),
    "cos": TestCase(-border, border, cos, lambda x: np.cos(np.array(x))),
    "arctan": TestCase(-border, border, arctan, lambda x: np.arctan(np.array(x))),
    "srgbToLinear": TestCase(0, 1, srgbToLinear, lambda x: np.array(srgbToLinearPy(x))),
    "linearToSrgb": TestCase(0, 1, linearToSrgb, lambda x: np.array(linearToSrgbPy(x))),
    "ln": TestCase(1e-9, border, ln, lambda x: np.log(np.array(x))),
    "exp": TestCase(1e-9, border, exp, lambda x: np.exp(np.array(x))),
}

for name in test_cases:
    test_case = test_cases[name]
    fig, ax = plt.subplots()
    ax.set_title(name)
    x = np.linspace(test_case.start, test_case.stop, 1000)
    y_nix = np.array(test_case.testing(x))
    y_np = test_case.ideal(x)
    ax.plot(x, y_nix, "b")
    ax.plot(x, y_np, "r")
    diff = np.abs(y_nix - y_np)
    max_diff = np.max(diff)
    max_index = np.argmax(diff)
    x_at_max_diff = x[max_index]
    print(f"{name} max diff is {max_diff} at x={x_at_max_diff}")

plt.show()
