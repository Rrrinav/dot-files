#!/usr/bin/env python3
import time
import sys


def get_cpu_times():
    cpus = []
    try:
        with open('/proc/stat') as f:
            for line in f:
                if line.startswith('cpu') and line.split()[0] != 'cpu':
                    parts = line.split()
                    # parts: [cpuN, user, nice, system, idle, iowait, ...]
                    values = [int(x) for x in parts[1:]]
                    idle = values[3] + values[4]
                    total = sum(values)
                    cpus.append({'id': parts[0], 'idle': idle, 'total': total})
    except FileNotFoundError:
        return []
    return cpus


# 1. Take first snapshot
first = get_cpu_times()

# 2. Wait a bit for accurate reading
time.sleep(0.1)

# 3. Take second snapshot
second = get_cpu_times()

# 4. Calculate Usage
usage_list = []
for c1, c2 in zip(first, second):
    delta_total = c2['total'] - c1['total']
    delta_idle = c2['idle'] - c1['idle']

    if delta_total == 0:
        usage = 0.0
    else:
        usage = 100.0 - ((delta_idle / delta_total) * 100.0)

    # Format: "Core 0: 12%"
    label = c1['id'].replace("cpu", "Core ")
    usage_list.append(f"{label}: {int(usage)}%")

# 5. Format Output (Columns vs Single List)
num_cores = len(usage_list)

# If we have many cores (e.g. > 8), split into 2 columns
if num_cores > 4:
    mid = (num_cores + 1) // 2
    left_col = usage_list[:mid]
    right_col = usage_list[mid:]

    output_lines = []
    for i in range(mid):
        left_text = left_col[i]
        # Check if right column has this index (handles odd number of cores)
        right_text = right_col[i] if i < len(right_col) else ""
        # Pad left text to 18 characters for alignment
        output_lines.append(f"{left_text:<12} | {right_text}")

    print("\n".join(output_lines))
else:
    # Few cores, just list them vertically
    print("\n".join(usage_list))
