import numpy as np
import sys

def load(fn):
    with open(fn) as f:
        n = int(f.readline())
        M = np.empty((n, n))
        for i in range(n):
            M[i] = list(map(float, f.readline().split()))
    return M

A = load("matrix_a.txt")
B = load("matrix_b.txt")
C_cpp = load("result_cpp.txt")
C_ref = A @ B

abs_e = float(np.max(np.abs(C_ref - C_cpp)))
denom = float(np.max(np.abs(C_ref))) or 1.0
rel_e = abs_e / denom

print("\n========== ВЕРИФИКАЦИЯ ==========")
print(f"Макс. абсолютная   ошибка: {abs_e:.3e}")
print(f"Макс. относительная ошибка: {rel_e:.3e}")

if rel_e < 1e-7:
    print("ВЕРИФИКАЦИЯ ПРОЙДЕНА! Результаты совпадают.")
    sys.exit(0)
else:
    print("ВЕРИФИКАЦИЯ НЕ ПРОЙДЕНА! Результаты не совпадают.")
    sys.exit(1)
