import csv
import matplotlib.pyplot as plt

rows = list(csv.DictReader(open("results.csv")))
sizes = sorted({int(r["N"]) for r in rows})
ths   = sorted({int(r["threads"]) for r in rows})

plt.figure(figsize=(9, 6))
for T in ths:
    xs = [s for s in sizes if any(int(r["N"]) == s and int(r["threads"]) == T for r in rows)]
    ys = [next(float(r["time_sec"]) for r in rows
               if int(r["N"]) == s and int(r["threads"]) == T) for s in xs]
    plt.plot(xs, ys, "o-", label=f"{T} поток(ов)")
plt.xlabel("N"); plt.ylabel("Время, с")
plt.title("Время умножения: зависимость от N и числа потоков")
plt.grid(alpha=.3); plt.legend()
plt.savefig("graph_time.png", dpi=200, bbox_inches="tight")

plt.figure(figsize=(9, 6))
for N in sizes:
    base = next(float(r["time_sec"]) for r in rows
                if int(r["N"]) == N and int(r["threads"]) == 1)
    xs = [T for T in ths if any(int(r["N"]) == N and int(r["threads"]) == T for r in rows)]
    ys = [base / next(float(r["time_sec"]) for r in rows
                      if int(r["N"]) == N and int(r["threads"]) == T) for T in xs]
    plt.plot(xs, ys, "o-", label=f"N={N}")
plt.plot(ths, ths, "k--", alpha=.4, label="идеальное")
plt.xlabel("Потоки"); plt.ylabel("Ускорение")
plt.title("Ускорение относительно 1 потока")
plt.grid(alpha=.3); plt.legend()
plt.savefig("graph_speedup.png", dpi=200, bbox_inches="tight")

print("Графики сохранены: graph_time.png, graph_speedup.png")
