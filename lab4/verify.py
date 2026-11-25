import sys
import numpy as np

def read_matrix(filename):
    with open(filename, 'r') as f:
        n = int(f.readline())
        matrix = np.loadtxt(f)
    return matrix

try:
    A = read_matrix("matrix_a.txt")
    B = read_matrix("matrix_b.txt")
    C_cuda = read_matrix("result_cpp.txt")
    
    C_ref = np.dot(A, B)
    
    if np.allclose(C_cuda, C_ref, rtol=1e-5, atol=1e-5):
        print("Верификация пройдена! (OK)")
        sys.exit(0)
    else:
        print("Ошибка! Результаты не совпадают.")
        sys.exit(1)
except Exception as e:
    print(f"Ошибка при проверке: {e}")
    sys.exit(1)
