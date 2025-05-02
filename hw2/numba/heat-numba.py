import numpy as np
from numba import cuda
import time
import math

ALPHA = 0.1
SIMULATION_TIME = 1
BLOCK_SIZE = 16
SHARED_DIM = BLOCK_SIZE + 2 

@cuda.jit
def heat2d_kernel(u_new, u_old, n, alpha, dt, dx, dy):
    shared = cuda.shared.array(shape=(SHARED_DIM, SHARED_DIM), dtype=np.float32)
    
    i, j = cuda.grid(2)
    ti = cuda.threadIdx.x + 1
    tj = cuda.threadIdx.y + 1
    
    if i < n and j < n:
        shared[tj, ti] = u_old[i, j]
        
        if cuda.threadIdx.x == 0 and cuda.blockIdx.x > 0:
            shared[tj, 0] = u_old[i-1, j]
        if cuda.threadIdx.x == BLOCK_SIZE-1 and i < n-1:
            shared[tj, BLOCK_SIZE+1] = u_old[i+1, j]
        if cuda.threadIdx.y == 0 and cuda.blockIdx.y > 0:
            shared[0, ti] = u_old[i, j-1]
        if cuda.threadIdx.y == BLOCK_SIZE-1 and j < n-1:
            shared[BLOCK_SIZE+1, ti] = u_old[i, j+1]
    
    cuda.syncthreads()

    if 0 < i < n-1 and 0 < j < n-1:
        d2u_dx2 = (shared[tj, ti+1] - 2*shared[tj, ti] + shared[tj, ti-1]) / (dx**2)
        d2u_dy2 = (shared[tj+1, ti] - 2*shared[tj, ti] + shared[tj-1, ti]) / (dy**2)
        u_new[i, j] = shared[tj, ti] + alpha * dt * (d2u_dx2 + d2u_dy2)

def print_matrix(matrix, n, max_size=20):
    display_size = min(n, max_size)
    print(f"\nHeat map (first {display_size}x{display_size} elements):")
    for i in range(display_size):
        print(" ".join(f"{matrix[i,j]:6.2f}" for j in range(display_size)))

def solve_heat_equation(n):
    u_host = np.zeros((n, n), dtype=np.float32)
    u_host[n//2, n//2] = 100.0
    
    # TEST PRINT #
    # print_matrix(u_host, n)

    d_u_old = cuda.to_device(u_host)
    d_u_new = cuda.to_device(u_host.copy())
    
    grid_size = (math.ceil(n / BLOCK_SIZE), math.ceil(n / BLOCK_SIZE))
    block_size = (BLOCK_SIZE, BLOCK_SIZE)
    
    dt_values = [0.1, 0.05, 0.025, 0.0125, 
                 0.00625, 0.003125, 0.0015625, 
                 0.00078125, 0.000390625, 0.0001953125]
    dx = dy = 1.0 / (n - 1)
    
    print("n,dt,steps,time_ms")
    
    for dt in dt_values:

        steps = int(round(SIMULATION_TIME / dt))
        start = time.time()
        
        for _ in range(steps):
            heat2d_kernel[grid_size, block_size](d_u_new, d_u_old, n, ALPHA, dt, dx, dy)
            d_u_old, d_u_new = d_u_new, d_u_old
        
        cuda.synchronize()
        time_ms = (time.time() - start) * 1000
        print(f"{n},{dt},{steps},{time_ms:.2f}")
        
        # TEST PRINT
        # result = d_u_old.copy_to_host()
        # print(f"\nResult for dt={dt}:")
        # print_matrix(result, n)
        
        d_u_old.copy_to_device(u_host)
        d_u_new.copy_to_device(u_host)
        

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python heat_numba.py <grid_size>")
        sys.exit(1)
    
    n = int(sys.argv[1])
    solve_heat_equation(n)
