This directory contains a number of benchmarks:

* The Rugg/Feldman benchmarks
* Creative Computing Benchmark
* Byte Sieve

## Results

The timings measured (in seconds) are:
| Benchmark       | Original | Optimized | Speedup (%) |
| ---------       | -------- | --------- | ----------- |
| [RF 1](rf1.bas) |    0.4   |    0.4    |     0.0     |
| [RF 2](rf2.bas) |    1.5   |    1.5    |     0.0     |
| [RF 3](rf3.bas) |    2.6   |    2.4    |     7.7     |
| [RF 4](rf4.bas) |    2.8   |    2.7    |     3.6     |
| [RF 5](rf5.bas) |    3.1   |    3.0    |     3.2     |
| [RF 6](rf6.bas) |    4.6   |    4.6    |     0.0     |
| [RF 7](rf7.bas) |    7.2   |    7.1    |     1.4     |
| [RF 8](rf8.bas) |   14.7   |   10.5    |    28.6     |
| [CC](cc.bas)    |   15.9   |    7.9    |    50.3     |
| [BS](bs.bas)    |   39.2   |   38.7    |     1.3     |

Compared to the numbers in the [Wikipedia
article](https://en.wikipedia.org/wiki/Rugg/Feldman_benchmarks) the X-16 runs
like a Commodore 64 at roughly 7.5 MHz.

The results for RF 8 show that the speedup in the multiplication routine has a
benefit for the transcendental functions too, because their implementation
makes heavy use of floating point multiplication.

The speedup in CC is mainly because of the much faster SQR function.

