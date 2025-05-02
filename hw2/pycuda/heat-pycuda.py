import pycuda.autoinit
import pycuda.driver as cuda
import numpy as np
from pycuda.compiler import SourceModule
import time


BLOCK_SIZE = 16
SIMULATION_TIME = 2.0
ALPHA = 0.01


def print_matrix(matrix, n, max_size=20):
    display_size = min(n, max_size)
    print(f"\nHeat map (first {display_size}x{display_size} elements):")
    for i in range(display_size):
        print(" ".join(f"{matrix[i*n + j]:6.2f}" for j in range(display_size)))


kernel_code = """
__global__ void heat2d(float* u_new, float* u_old, int n, float alpha, float dt, float dx, float dy) {
    __shared__ float tile[%(block_size)d+2][%(block_size)d+2];
    
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    int ti = threadIdx.x + 1;
    int tj = threadIdx.y + 1;
    
    if (i < n && j < n) {
        tile[tj][ti] = u_old[i * n + j];
        
        if (threadIdx.x == 0 && blockIdx.x > 0) 
            tile[tj][0] = u_old[(i-1)*n + j];
        if (threadIdx.x == blockDim.x-1 && i < n-1)
            tile[tj][blockDim.x+1] = u_old[(i+1)*n + j];
        if (threadIdx.y == 0 && blockIdx.y > 0)
            tile[0][ti] = u_old[i*n + (j-1)];
        if (threadIdx.y == blockDim.y-1 && j < n-1)
            tile[blockDim.y+1][ti] = u_old[i*n + (j+1)];
    }
    __syncthreads();

    if (i > 0 && i < n-1 && j > 0 && j < n-1) {
        float d2u_dx2 = (tile[tj][ti+1] - 2*tile[tj][ti] + tile[tj][ti-1]) / (dx*dx);
        float d2u_dy2 = (tile[tj+1][ti] - 2*tile[tj][ti] + tile[tj-1][ti]) / (dy*dy);
        u_new[i*n + j] = tile[tj][ti] + alpha * dt * (d2u_dx2 + d2u_dy2);
    }
}
""" % {'block_size': BLOCK_SIZE}


def solve_heat_equation(n):
    mod = SourceModule(kernel_code)
    heat2d = mod.get_function("heat2d")
    
    block = (BLOCK_SIZE, BLOCK_SIZE, 1)
    grid = (int(np.ceil(n / block[0])), int(np.ceil(n / block[1])))
    
    u_host = np.zeros(n*n, dtype=np.float32)
    u_host[n//2 * n + n//2] = 100.0 
    
    # TEST PRINT #
    # print_matrix(u_host, n)

    u_old = cuda.to_device(u_host)
    u_new = cuda.mem_alloc(u_host.nbytes)
    
    cuda.memcpy_dtod(u_new, u_old, u_host.nbytes)
    
    dt_values = [0.1, 0.05, 0.025, 0.0125, 
                 0.00625, 0.003125, 0.0015625, 
                 0.00078125, 0.000390625, 0.0001953125]
    
    dx = dy = 1.0 / (n - 1)
    
    print("n,dt,steps,time_ms")
    
    for dt in dt_values:
        steps = int(round(SIMULATION_TIME / dt))
        
        start = time.time()
        
        for _ in range(steps):
            heat2d(u_new, u_old, np.int32(n), np.float32(ALPHA), 
                  np.float32(dt), np.float32(dx), np.float32(dy),
                  block=block, grid=grid)
            u_old, u_new = u_new, u_old 
            
        cuda.Context.synchronize()
        time_ms = (time.time() - start) * 1000
        
        print(f"{n},{dt},{steps},{time_ms:.2f}")
        
        result = np.empty_like(u_host)
        cuda.memcpy_dtoh(result, u_old)
    
    # TEST PRINT #
    # print_matrix(result, n)
    
    u_old.free()
    u_new.free()

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python heat-pycuda.py <grid_size>")
        sys.exit(1)
    
    n = int(sys.argv[1])
    solve_heat_equation(n)
