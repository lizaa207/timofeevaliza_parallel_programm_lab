import re
import matplotlib.pyplot as plt

data = {1: {}, 2: {}}
for line in open("speedup_blockwise.txt"):
    m = re.search(r"view=(\d) threads=(\d+).*?([\d.]+)x speedup", line)
    if m:
        data[int(m[1])][int(m[2])] = float(m[3])

plt.figure(figsize=(7, 5))
for v, d in data.items():
    plt.plot(list(d.keys()), list(d.values()), marker="o", label=f"view {v}")
plt.plot(range(2, 9), range(2, 9), "--", color="gray", label="идеальное ускорение")
plt.xlabel("Число потоков")
plt.ylabel("Ускорение")
plt.title("Mandelbrot: блочное разбиение")
plt.legend()
plt.grid(True)
plt.savefig("speedup_blockwise.png", dpi=150, bbox_inches="tight")
