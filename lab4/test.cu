#include <iostream>
#include <fstream>
#include <vector>
#include <iomanip>
#include <chrono>
#include <omp.h>

using namespace std;

int main(int argc, char* argv[]) {
    int bx = (argc > 1) ? atoi(argv[1]) : 16;
    int by = (argc > 2) ? atoi(argv[2]) : 16;
    int reps = (argc > 3) ? atoi(argv[3]) : 5;

    ifstream fileA("matrix_a.txt");
    ifstream fileB("matrix_b.txt");
    if (!fileA.is_open() || !fileB.is_open()) {
        cerr << "Ошибка файлов!" << endl;
        return 1;
    }

    int n; fileA >> n; fileB >> n;
    size_t count = (size_t)n * n;
    vector<double> A(count), B(count), C(count);

    for (size_t i = 0; i < count; i++) fileA >> A[i];
    for (size_t i = 0; i < count; i++) fileB >> B[i];

    cout << "Размер матриц: " << n << "x" << n << endl;

    int gridX = (n + bx - 1) / bx;
    int gridY = (n + by - 1) / by;

    double best = 1e18;
    for (int r = 0; r < reps; r++) {
        fill(C.begin(), C.end(), 0.0);
        auto t0 = chrono::steady_clock::now();
        
        #pragma omp parallel for collapse(2) schedule(static)
        for (int gy = 0; gy < gridY; gy++) {
            for (int gx = 0; gx < gridX; gx++) {
                for (int ty = 0; ty < by; ty++) {
                    for (int tx = 0; tx < bx; tx++) {
                        int row = gy * by + ty;
                        int col = gx * bx + tx;
                        if (row < n && col < n) {
                            double s = 0.0;
                            for (int k = 0; k < n; k++)
                                s += A[row * n + k] * B[k * n + col];
                            C[row * n + col] = s;
                        }
                    }
                }
            }
        }
        
        auto t1 = chrono::steady_clock::now();
        double dt = chrono::duration<double>(t1 - t0).count();
        if (dt < best) best = dt;
    }

    cout << "Сетка: " << gridX << "x" << gridY << ", Блок: " << bx << "x" << by << endl;
    cout << "Время ядра (лучшее): " << fixed << setprecision(6) << best << " c" << endl;

    ofstream rf("result_cpp.txt");
    rf << setprecision(10) << n << endl;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++)
            rf << C[(size_t)i * n + j] << " ";
        rf << endl;
    }

    system("python3 verify.py");
    return 0;
}
