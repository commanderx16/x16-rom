10 REM THIS IS A TEST PROGRAM TO DO SIMLE VERIFICATION
20 REM OF THE SQUARE ROOT FUNCTION
30 REM IN THE X16.

1000 REM TEST SMALL SQUARES
1010 PRINT SQR(0)
1020 PRINT SQR(1)
1030 PRINT SQR(4)
1040 PRINT SQR(9)
1050 PRINT SQR(1E-4)
1060 PRINT SQR(1E-10)
1070 PRINT SQR(1E-20)

1100 REM TEST LARGE SQUARES
1110 PRINT SQR(1E20)
1120 PRINT SQR(1E10)
1130 PRINT SQR(1E4)
1140 PRINT SQR(17*17)
1150 PRINT SQR(127*127)
1160 PRINT SQR(129*129)
1170 PRINT SQR(1023*1023)
1180 PRINT SQR(1025*1025)
1190 PRINT SQR(65535*65535)
1200 PRINT SQR(65537*65537)

2000 REM TEST FRACTIONS
2010 PRINT SQR(1/4)
2020 PRINT SQR(1/9)
2030 PRINT SQR(1/25)
2040 PRINT SQR(1/36)
2050 PRINT SQR(1/81)

3000 REM TEST OTHER NUMBERS
3010 FOR I=1000 TO 1050
3020 PRINT SQR(I)
3030 NEXT

RUN

SYS 65535

