#!/bin/bash
set -e

echo "N,threads,time_sec,gflops,verified" > results.csv

echo "Компиляция..."
g++ -O2 -fopenmp main.cpp -o matrix_mult

for N in 200 400 800 1200; do
    echo "Генерация матриц $N x $N..."
    python3 generate.py $N
    for T in 1 2 4 8; do
        echo "== N=$N, потоков=$T =="
        ./matrix_mult $T 5
    done
done

echo ""
echo "Готово! Все результаты в results.csv"
