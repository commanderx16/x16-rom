# Performance measurements of floating point subroutines

| Test                     | Original | Optimized | Speedup (%) |
| ------------------------ | -------- | --------- | ----------- |
| simple for loop          |   106    |     97    |    8.5      |
| counter                  |   333    |    315    |    5.4      |
| cos calculation          |   225    |    168    |   25.3      |
| multiplication           |   464    |    417    |   10.1      |
| multiplication underflow |   555    |    386    |   30.5      |
| sqr                      |   402    |     77    |   80.8      |

