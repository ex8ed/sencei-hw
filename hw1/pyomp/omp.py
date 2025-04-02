import time
import sys
from numba import jit, prange, config, threading_layer


config.THREADING_LAYER = 'omp'


@jit(nopython=True, parallel=True)
def calc_pi(num_steps):
    step = 1.0 / num_steps
    sum_total = 0.0
    for i in prange(num_steps):
        x = (i + 0.5) * step
        sum_total += 4.0 / (1.0 + x * x)
    return sum_total * step


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python omp.py <num_steps>")
        sys.exit()
    
    num_steps = int(sys.argv[1])
    start = time.time()
    pi = calc_pi(num_steps)
    print(f"Pi: {pi}\nTime: {time.time() - start} s")
    print(f"Threading layer: {threading_layer()}")