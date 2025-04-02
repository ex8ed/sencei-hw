from mpi4py import MPI
import sys
import time


def calc_part(start, end, step):
    partial = 0.0
    for i in range(start, end):
        x = (i + 0.5) * step
        partial += 4.0 / (1.0 + x * x)
    return partial


if __name__ == '__main__':
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    if len(sys.argv) < 2:
        if rank == 0:
            print("Usage: python mpi.py <num_steps>")
        sys.exit()

    num_steps = int(sys.argv[1])
    step = 1.0 / num_steps

    chunk = num_steps // size
    start = rank * chunk
    end = start + chunk if rank != size - 1 else num_steps

    comm.barrier()
    start_time = time.time()

    local_sum = calc_part(start, end, step)
    total_sum = comm.reduce(local_sum, op=MPI.SUM, root=0)

    if rank == 0:
        pi = total_sum * step
        print(f"Pi: {pi}\nTime: {time.time() - start_time} s")
