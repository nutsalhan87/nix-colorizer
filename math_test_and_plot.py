import matplotlib.pyplot as plt
import numpy as np
import math
import subprocess


def template_single_fn(fn: str, x: [float]) -> [float]:
    ser = "[ " + " ".join(map(lambda x: f"({np.format_float_positional(x, trim='-')})", x)) + " ]"
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


def sqrt(x: [float]) -> [float]:
    return template_single_fn("sqrt", x)


def cbrt(x: [float]) -> [float]:
    return template_single_fn("cbrt", x)


def sin(x: [float]) -> [float]:
    return template_single_fn("sin", x)


def cos(x: [float]) -> [float]:
    return template_single_fn("cos", x)


def arctan(x: [float]) -> [float]:
    return template_single_fn("arctan", x)


def srgbToLinear(x: [float]) -> [float]:
    return template_single_fn("srgbToLinear", x)


def linearToSrgb(x: [float]) -> [float]:
    return template_single_fn("linearToSrgb", x)


def ln(x: [float]) -> [float]:
    return template_single_fn("ln", x)


def exp(x: [float]) -> [float]:
    return template_single_fn("exp", x)


def srgbToLinearPy(x: [float]) -> [float]:
    ret = []
    for s in x:
        if s <= 0.0404482362771082:
            ret.append(s / 12.92)
        else:
            ret.append(((s + 0.055) / 1.055) ** 2.4)
    return ret


def linearToSrgbPy(x: [float]) -> [float]:
    ret = []
    for l in x:
        if l <= 0.00313066844250063:
            ret.append(l * 12.92)
        else:
            ret.append(1.055 * l ** (1 / 2.4) - 0.055)
    return ret


border = 10

fig, ax = plt.subplots()
ax.set_title("sqrt")
x = np.linspace(0, border, 1000)
y_nix = np.array(sqrt(x))
y_np = np.sqrt(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"sqrt max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("cbrt")
x = np.linspace(-border, border, 1000)
y_nix = np.array(cbrt(x))
y_np = np.cbrt(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"cbrt max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("sin")
x = np.linspace(-border, border, 1000)
y_nix = np.array(sin(x))
y_np = np.sin(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"sin max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("cos")
x = np.linspace(-border, border, 1000)
y_nix = np.array(cos(x))
y_np = np.cos(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"cos max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("arctan")
x = np.linspace(-border, border, 1000)
y_nix = np.array(arctan(x))
y_np = np.arctan(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"arctan max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("srgbToLinear")
x = np.linspace(0, 1, 1000)
y_nix = np.array(srgbToLinear(x))
y_np = np.array(srgbToLinearPy(x))
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"srgbToLinear max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("linearToSrgb")
x = np.linspace(0, 1, 1000)
y_nix = np.array(linearToSrgb(x))
y_np = np.array(linearToSrgbPy(x))
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"linearToSrgb max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("ln")
x = np.linspace(1e-9, border, 1000)
y_nix = np.array(ln(x))
y_np = np.log(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"ln max diff: {np.max(np.abs(y_nix - y_np))}")

fig, ax = plt.subplots()
ax.set_title("exp")
x = np.linspace(1e-9, border, 1000)
y_nix = np.array(exp(x))
y_np = np.exp(x)
ax.plot(x, y_nix, 'b')
ax.plot(x, y_np, 'r')
print(f"exp max diff: {np.max(np.abs(y_nix - y_np))}")

plt.show()
