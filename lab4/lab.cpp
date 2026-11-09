#include <iostream>
#include <fstream>
#include <vector>
#include <chrono>
#include <omp.h>
using namespace std;
int main() {
    ifstream fa("matrix_a.txt"), fb("matrix_b.txt");
    int n; fa >> n; fb >> n;
    vector<double> A(n*n), B(n*n), C(n*n, 0);
    for(int i=0; i<n*n; i++) fa >> A[i];
    for(int i=0; i<n*n; i++) fb >> B[i];
    auto t0 = chrono::steady_clock::now();
    #pragma omp parallel for
    for(int i=0; i<n; i++) {
        for(int k=0; k<n; k++) {
            double a = A[i*n+k];
            for(int j=0; j<n; j++) C[i*n+j] += a * B[k*n+j];
        }
    }
    auto t1 = chrono::steady_clock::now();
    cout << "Время: " << chrono::duration<double>(t1-t0).count() << " c" << endl;
    ofstream rf("result_cpp.txt");
    rf << n << endl;
    for(int i=0; i<n; i++) {
        for(int j=0; j<n; j++) rf << C[i*n+j] << " ";
        rf << endl;
    }
    system("python3 verify.py");
    return 0;
}
