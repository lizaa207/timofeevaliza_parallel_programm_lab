#include <iostream>
#include <fstream>
#include <vector>
#include <cstdlib>
#include <iomanip>
#include <algorithm>
#include <cuda_runtime.h>

using namespace std;

#define CUDA_CHECK(call) do { cudaError_t e = (call); if (e != cudaSuccess) { \
    cerr << "CUDA ошибка: " << cudaGetErrorString(e) << " (строка " << __LINE__ << ")" << endl; \
    exit(1); } } while (0)

// Один поток вычисляет один элемент C[row][col]
__global__ void multiplyKernel(const double* A, const double* B, double* C, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < n && col < n) {
        double s = 0.0;
        for (int k = 0; k < n; k++)
            s += A[row * n + k] * B[k * n + col];
        C[row * n + col] = s;
    }
}

int main(int argc, char* argv[]) {
    cout << "========== УМНОЖЕНИЕ МАТРИЦ (CUDA) ==========" << endl;

    int bx   = (argc > 1) ? atoi(argv[1]) : 16;   // размер блока по x
    int by   = (argc > 2) ? atoi(argv[2]) : 16;   // размер блока по y
    int reps = (argc > 3) ? atoi(argv[3]) : 5;

    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    cout << "GPU: " << prop.name << endl;

    if (bx * by > prop.maxThreadsPerBlock || bx <= 0 || by <= 0) {
        cerr << "Ошибка: в блоке не более " << prop.maxThreadsPerBlock << " потоков" << endl;
        return 1;
    }

    ifstream fileA("matrix_a.txt");
    ifstream fileB("matrix_b.txt");
    if (!fileA.is_open() || !fileB.is_open()) {
        cerr << "Ошибка: не удалось открыть файлы!" << endl;
        return 1;
    }

    int n;
    fileA >> n;
    fileB >> n;

    size_t count = (size_t)n * n;
    size_t bytes = count * sizeof(double);
    vector<double> A(count), B(count), C(count);

    for (size_t i = 0; i < count; i++) fileA >> A[i];
    for (size_t i = 0; i < count; i++) fileB >> B[i];
    fileA.close();
    fileB.close();

    cout << "Размер матриц: " << n << "x" << n << endl;

    double *dA, *dB, *dC;
    CUDA_CHECK(cudaMalloc(&dA, bytes));
    CUDA_CHECK(cudaMalloc(&dB, bytes));
    CUDA_CHECK(cudaMalloc(&dC, bytes));

    dim3 block(bx, by);
    dim3 grid((n + bx - 1) / bx, (n + by - 1) / by);

    cudaEvent_t k0, k1, t0, t1;
    cudaEventCreate(&k0); cudaEventCreate(&k1);
    cudaEventCreate(&t0); cudaEventCreate(&t1);

    // прогревочный запуск
    CUDA_CHECK(cudaMemcpy(dA, A.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, B.data(), bytes, cudaMemcpyHostToDevice));
    multiplyKernel<<<grid, block>>>(dA, dB, dC, n);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    double kernelTotal = 0.0, kernelBest = 1e18, fullTotal = 0.0;
    for (int r = 0; r < reps; r++) {
        cudaEventRecord(t0);
        CUDA_CHECK(cudaMemcpy(dA, A.data(), bytes, cudaMemcpyHostToDevice));
        CUDA_CHECK(cudaMemcpy(dB, B.data(), bytes, cudaMemcpyHostToDevice));

        cudaEventRecord(k0);
        multiplyKernel<<<grid, block>>>(dA, dB, dC, n);
        cudaEventRecord(k1);

        CUDA_CHECK(cudaMemcpy(C.data(), dC, bytes, cudaMemcpyDeviceToHost));
        cudaEventRecord(t1);
        CUDA_CHECK(cudaEventSynchronize(t1));
        CUDA_CHECK(cudaGetLastError());

        float km, tm;
        cudaEventElapsedTime(&km, k0, k1);
        cudaEventElapsedTime(&tm, t0, t1);
        kernelTotal += km / 1000.0;
        fullTotal   += tm / 1000.0;
        kernelBest = min(kernelBest, (double)km / 1000.0);
    }
    double kernelAvg = kernelTotal / reps;
    double fullAvg   = fullTotal / reps;

    cout << "Сетка блоков: " << grid.x << "x" << grid.y
         << ", блок: " << bx << "x" << by << " (" << bx * by << " потоков)" << endl;
    cout << "Прогонов: " << reps << endl;
    cout << "Время ядра (среднее): " << fixed << setprecision(6) << kernelAvg << " c" << endl;
    cout << "Время ядра (лучшее):  " << kernelBest << " c" << endl;
    cout << "Время с копированием (среднее): " << fullAvg << " c" << endl;

    {
        ofstream rf("result_cpp.txt");   // то же имя, чтобы verify.py работал без изменений
        rf << setprecision(10);
        rf << n << endl;
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++)
                rf << C[(size_t)i * n + j] << " ";
            rf << endl;
        }
    }

    long long memory = 3LL * n * n * (long long)sizeof(double);
    long long operations = 2LL * n * n * n;
    double gflops = (operations / 1e9) / kernelAvg;

    cout << "\n========== МЕТРИКИ ==========" << endl;
    cout << "Память: " << memory / 1024 << " KB" << endl;
    cout << "Операций: " << operations << endl;
    cout << "Производительность: " << fixed << setprecision(3) << gflops << " GFLOPS" << endl;

    cudaFree(dA); cudaFree(dB); cudaFree(dC);

    cout << "\nЗапуск верификации через Python..." << endl;
    int rc = system("python3 verify.py");
    bool verified = (rc == 0);

    ofstream log("results_cuda.csv", ios::app);
    log << n << "," << bx << "," << by << ","
        << grid.x << "x" << grid.y << ","
        << fixed << setprecision(6) << kernelAvg << "," << fullAvg << ","
        << setprecision(4) << gflops << ","
        << (verified ? "OK" : "FAIL") << endl;

    return verified ? 0 : 2;
}
