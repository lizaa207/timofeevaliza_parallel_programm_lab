import numpy as np
import sys

n = int(sys.argv[1]) if len(sys.argv) > 1 else 200
rng = np.random.default_rng(42)
A = rng.random((n, n))
B = rng.random((n, n))

def save(fn, M):
    with open(fn, "w") as f:
        f.write(f"{M.shape[0]}\n")
        for row in M:
            f.write(" ".join(f"{x:.10f}" for x in row) + "\n")

save("matrix_a.txt", A)
save("matrix_b.txt", B)
print(f"Матрицы {n}x{n} сгенерированы")
