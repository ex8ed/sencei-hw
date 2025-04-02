#include <mpi.h>
#include <iostream>
#include <chrono>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc < 2 && rank == 0) {
        std::cerr << "Usage: " << argv[0] << " <num_steps>\n";
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    unsigned long num_steps = std::stoul(argv[1]);
    double step = 1.0 / num_steps;
    double sum = 0.0;

    unsigned long chunk = num_steps / size;
    unsigned long start = rank * chunk;
    unsigned long end = (rank == size - 1) ? num_steps : start + chunk;

    double start_time = MPI_Wtime();

    for (unsigned long i = start; i < end; ++i) {
        double x = (i + 0.5) * step;
        sum += 4.0 / (1.0 + x * x);
    }

    double total_sum;
    MPI_Reduce(&sum, &total_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        double pi = total_sum * step;
        double time = MPI_Wtime() - start_time;
        std::cout << pi << "," << time << std::endl;
    }

    MPI_Finalize();
    return 0;
}