#include <iostream>
#include <fstream>
#include <vector>
#include <chrono>
#include <cstdlib>
#include <iomanip>
#include <algorithm>

#ifdef _OPENMP
#include <omp.h>
#endif

using namespace std;
using namespace chrono;

static void readMatrix(ifstream& f, vector<vector<double>>& M, int n) {
    for (int i = 0; i < n; i++)
        for (int j = 0; j < n; j++)
            f >> M[i][j];
}

static void multiply(const vector<vector<double>>& A,
                     const vector<vector<double>>& B,
                     vector<vector<double>>& C, int n) {
#pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        double* Ci = C[i].data();
        const double* Ai = A[i].data();
        for (int k = 0; k < n; k++) {
            double aik = Ai[k];
            const double* Bk = B[k].data();
            for (int j = 0; j < n; j++)
                Ci[j] += aik * Bk[j];
        }
    }
}

int main(int argc, char* argv[]) {
    cout << "========== УМНОЖЕНИЕ МАТРИЦ ==========" << endl;

    int threads = (argc > 1) ? atoi(argv[1]) : 0;
    int reps    = (argc > 2) ? atoi(argv[2]) : 5;

#ifdef _OPENMP
    if (threads > 0) omp_set_num_threads(threads);
#endif

    ifstream fileA("matrix_a.txt");
    ifstream fileB("matrix_b.txt");
    if (!fileA.is_open() || !fileB.is_open()) {
        cerr << "Ошибка: не удалось открыть файлы!" << endl;
        return 1;
    }

    int n;
    fileA >> n;
    fileB >> n;

    vector<vector<double>> A(n, vector<double>(n));
    vector<vector<double>> B(n, vector<double>(n));
    vector<vector<double>> C(n, vector<double>(n, 0.0));

    readMatrix(fileA, A, n);
    readMatrix(fileB, B, n);
    fileA.close();
    fileB.close();

    cout << "Размер матриц: " << n << "x" << n << endl;

    multiply(A, B, C, n);
    for (auto& row : C) fill(row.begin(), row.end(), 0.0);

    double total = 0.0, best = 1e18;
    for (int r = 0; r < reps; r++) {
        for (auto& row : C) fill(row.begin(), row.end(), 0.0);
        auto t0 = steady_clock::now();
        multiply(A, B, C, n);
        auto t1 = steady_clock::now();
        double dt = duration<double>(t1 - t0).count();
        total += dt;
        if (dt < best) best = dt;
    }
    double time_avg = total / reps;

    int actualThreads = 1;
#ifdef _OPENMP
    actualThreads = (threads > 0) ? threads : omp_get_max_threads();
#endif

    cout << "Число потоков: " << actualThreads << endl;
    cout << "Прогонов: " << reps << endl;
    cout << "Время (среднее): " << fixed << setprecision(6) << time_avg << " c" << endl;
    cout << "Время (лучшее):  " << best << " c" << endl;

    {
        ofstream rf("result_cpp.txt");
        rf << setprecision(10);
        rf << n << endl;
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++)
                rf << C[i][j] << " ";
            rf << endl;
        }
    }

    long long memory = 3LL * n * n * (long long)sizeof(double);
    long long operations = 2LL * n * n * n;
    double gflops = (operations / 1e9) / time_avg;

    cout << "\n========== МЕТРИКИ ==========" << endl;
    cout << "Память: " << memory / 1024 << " KB" << endl;
    cout << "Операций: " << operations << endl;
    cout << "Производительность: " << fixed << setprecision(3) << gflops << " GFLOPS" << endl;

    cout << "\nЗапуск верификации через Python..." << endl;
    int rc = system("python3 verify.py");
    bool verified = (rc == 0);

    ofstream log("results.csv", ios::app);
    log << n << "," << actualThreads << ","
        << fixed << setprecision(6) << time_avg << ","
        << setprecision(4) << gflops << ","
        << (verified ? "OK" : "FAIL") << endl;

    return verified ? 0 : 2;
}
