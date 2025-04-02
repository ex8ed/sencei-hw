#include <iostream>
#include <chrono>
#include <omp.h>

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <num_steps>\n";
        return 1;
    }

    unsigned long num_steps = std::stoul(argv[1]);
    double step = 1.0 / num_steps;
    double sum = 0.0;

    auto start = std::chrono::high_resolution_clock::now();

    #pragma omp parallel for reduction(+:sum)
    for (unsigned long i = 0; i < num_steps; ++i) {
        double x = (i + 0.5) * step;
        sum += 4.0 / (1.0 + x * x);
    }

    double pi = sum * step;
    auto end = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> diff = end - start;

    std::cout << pi << "," << diff.count() << std::endl;
    return 0;
}
