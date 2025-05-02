#include <iostream>
#include <vector>
#include <chrono>
#include <cuda_runtime.h>
#include <cuda_device_runtime_api.h>
#include <cmath>
#include <iomanip>


#define BLOCK_SIZE 16
#define SIMULATION_TIME 2.0f  // seconds


void print_matrix(const float* matrix, int n, int max_size=20) {
    int display_size = std::min(n, max_size);
    
    std::cout << "\nHeat map (first " << display_size << "x" << display_size << " elements):\n";
    std::cout << std::fixed << std::setprecision(2);
    
    for (int i = 0; i < display_size; ++i) {
        for (int j = 0; j < display_size; ++j) {
            std::cout << std::setw(8) << matrix[i * n + j];
        }
        std::cout << std::endl;
    }
}


__global__ void heat2d_kernel(float* u_new, float* u_old, int n, float alpha, float dt, float dx, float dy) {
    __shared__ float tile[BLOCK_SIZE+2][BLOCK_SIZE+2];
    
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (i < n && j < n) {
        tile[threadIdx.y+1][threadIdx.x+1] = u_old[i * n + j];
        
        if (threadIdx.x == 0 && blockIdx.x > 0) 
            tile[threadIdx.y+1][0] = u_old[(i-1)*n + j];
        if (threadIdx.x == BLOCK_SIZE-1 && i < n-1)
            tile[threadIdx.y+1][BLOCK_SIZE+1] = u_old[(i+1)*n + j];
        if (threadIdx.y == 0 && blockIdx.y > 0)
            tile[0][threadIdx.x+1] = u_old[i*n + (j-1)];
        if (threadIdx.y == BLOCK_SIZE-1 && j < n-1)
            tile[BLOCK_SIZE+1][threadIdx.x+1] = u_old[i*n + (j+1)];
    }

    __syncthreads();

    if (i > 0 && i < n-1 && j > 0 && j < n-1) {

        float d2u_dx2 = (tile[threadIdx.y+1][threadIdx.x+2] - 
                         2*tile[threadIdx.y+1][threadIdx.x+1] + 
                         tile[threadIdx.y+1][threadIdx.x]) / (dx*dx);

        float d2u_dy2 = (tile[threadIdx.y+2][threadIdx.x+1] - 
                        2*tile[threadIdx.y+1][threadIdx.x+1] + 
                        tile[threadIdx.y][threadIdx.x+1]) / (dy*dy);

        u_new[i*n + j] = tile[threadIdx.y+1][threadIdx.x+1] + alpha * dt * (d2u_dx2 + d2u_dy2);
    }
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <grid_size>" << std::endl;
        return 1;
    }

    const int n = std::stoi(argv[1]);
    const float alpha = 0.01f;
    const float dx = 1.0f / (n - 1);
    const float dy = 1.0f / (n - 1);
    
    const std::vector<float> dt_values = {0.1f, 0.05f, 0.025f, 0.0125f, 
                                          0.00625f, 0.003125f, 0.0015625f, 0.00078125f, 
                                          0.000390625f, 0.0001953125f};  // steps values
    
    std::vector<float> u_host(n * n, 0.0f);
    u_host[(n/2)*n + (n/2)] = 100.0f;

    /* TEST PRINT */
    // std::cout << "\nНачальное состояние:";
    // print_matrix(u_host.data(), n);

    float *u_old, *u_new;
    cudaMalloc(&u_old, n * n * sizeof(float));
    cudaMalloc(&u_new, n * n * sizeof(float));
    cudaMemcpy(u_old, u_host.data(), n * n * sizeof(float), cudaMemcpyHostToDevice);

    dim3 block(BLOCK_SIZE, BLOCK_SIZE);
    dim3 grid((n + block.x - 1) / block.x, (n + block.y - 1) / block.y);

    std::cout << "n,dt,steps,time_ms" << std::endl;

    for (float dt : dt_values) {
        const int steps = static_cast<int>(round(SIMULATION_TIME / dt));
        
        cudaEvent_t start, stop;
        cudaEventCreate(&start);
        cudaEventCreate(&stop);
        
        cudaEventRecord(start);
        
        for (int step = 0; step < steps; ++step) {
            heat2d_kernel<<<grid, block>>>(u_new, u_old, n, alpha, dt, dx, dy);
            std::swap(u_new, u_old);
        }
        
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        
        float time_ms = 0;
        cudaEventElapsedTime(&time_ms, start, stop);
        
        std::cout << n << "," << dt << "," << steps << "," << time_ms << std::endl;
        
        cudaEventDestroy(start);
        cudaEventDestroy(stop);
    }

    /* TEST PRINT */
    // std::vector<float> u_result(n * n);
    // cudaMemcpy(u_result.data(), u_old, n * n * sizeof(float), cudaMemcpyDeviceToHost);
    // print_matrix(u_result.data(), n);

    cudaFree(u_old);
    cudaFree(u_new);
    
    return 0;
}