import random


n = 1024

print(f"Генерация матриц {n}x{n}...")


with open("matrix_a.txt", "w") as f:
    f.write(f"{n}\n")
    for i in range(n):
        row = [str(round(random.uniform(-10, 10), 4)) for _ in range(n)]
        f.write(" ".join(row) + "\n")


with open("matrix_b.txt", "w") as f:
    f.write(f"{n}\n")
    for i in range(n):
        row = [str(round(random.uniform(-10, 10), 4)) for _ in range(n)]
        f.write(" ".join(row) + "\n")

print("Готово! Созданы matrix_a.txt и matrix_b.txt")
