rem 0 gosub3000:end

rem detect drive
rem 0 = 1541 feature set (base)
rem 1 = 1571 extra features
rem 2 = cmd fd/hd extra features
rem 4 = c65 drive extra features
rem 8 = cmdr-dos extra features

1 dos"ui":open15,8,15:input#15,s,s$,x,y:close15
2 ifright$(s$,4)="1541"thenf=0:goto8
3 ifright$(s$,4)="1571"thenf=1:goto8
4 ifleft$(s$,4)="cmd "thenf=2+1:goto8
5 ifleft$(s$,12)="cbm c65 1565"thenf=4+2+1:goto8
6 ifleft$(s$,8)="cmdr-dos"thenf=8+4+2+1:goto8
7 print"unknown drive":stop

rem detect second partition

8 open15,8,15,"g-p"+chr$(2):get#15,t$:fori=0to29:get#15,a$:next:close15
9 t=asc(t$+chr$(0)):p2=t=11ort=12


10 gosub100:gosub200:gosub300:gosub400:gosub500:gosub600:gosub700:gosub800
11 gosub900:gosub1000:gosub1100:gosub1200:gosub1300:gosub1400:gosub1500
12 gosub1600
13 gosub1700
14 gosub1800
15 gosub1900
16 gosub2000
17 gosub2100
18 gosub2200
19 gosub2300
20 gosub2400:gosub2500
21 gosub2600             
22 gosub2700
23 gosub2800
24 gosub2900
25 gosub3000:gosub3100:gosub3200:gosub3300:gosub3400:gosub3500
26 gosub3600
27 gosub3700
28 gosub3800
29 gosub3900
30 gosub4000
31 gosub4100
32 gosub4200
34 gosub4300
35 gosub4400
36 gosub4500
37 gosub4600
38 gosub4700

98 end
99 goto10

100 print"01 create/read file, ',p,x'",;
110 open1,8,2,"file,p,w"
120 print#1,"hello world!"
130 close1
140 open1,8,2,"file,p,r"
150 input#1,a$
160 ifa$<>"hello world!"thenstop
170 ifst<>64thenstop
180 close1
190 dos"s:file"
199 dos"u0>t":print"ok":return

200 print"02 create/read file, chan 1/0",;
210 open1,8,1,"file"
220 print#1,"hello world!"
230 close1
240 open1,8,0,"file"
250 input#1,a$
260 ifa$<>"hello world!"thenstop
270 ifst<>64thenstop
280 close1
290 dos"s:file"
299 dos"u0>t":print"ok":return

300 print"03 create/read file, chan 1/2",;
310 open1,8,1,"file"
320 print#1,"hello world!"
330 close1
340 open1,8,2,"file"
350 input#1,a$
360 ifa$<>"hello world!"thenstop
370 ifst<>64thenstop
380 close1
390 dos"s:file"
399 dos"u0>t":print"ok":return

400 print"04 r/w mult. listen/talk sess",;
410 open1,8,2,"file,p,w":print#1,"one":print#1,"two":close1
420 open1,8,2,"file"
430 input#1,a$:ifa$<>"one"thenstop
440 input#1,a$:ifa$<>"two"thenstop
450 ifst<>64thenstop
460 close1
470 dos"s:file"
499 dos"u0>t":print"ok":return

500 print"05 two files open for writing",;
510 open1,8,2,"file1,p,w":open2,8,3,"file2,p,w"
515 print#1,"one":print#2,"two":print#1,"three":print#2,"four"
520 close1:close2
525 open1,8,2,"file1"
530 input#1,a$:ifa$<>"one"thenstop
535 input#1,a$:ifa$<>"three"thenstop
540 ifst<>64thenstop
545 close1
550 open1,8,2,"file2"
555 input#1,a$:ifa$<>"two"thenstop
560 input#1,a$:ifa$<>"four"thenstop
565 ifst<>64thenstop
570 close1
580 dos"s:file1,file2"
599 dos"u0>t":print"ok":return

600 print"06 two files open for reading",;
610 open1,8,2,"file1,p,w":print#1,"one":print#1,"three":close1
615 open1,8,2,"file2,p,w":print#1,"two":print#1,"four":close1
625 open1,8,2,"file1":open2,8,3,"file2"
630 input#1,a$:ifa$<>"one"thenstop
635 input#2,a$:ifa$<>"two"thenstop
640 input#1,a$:ifa$<>"three"thenstop
645 input#2,a$:ifa$<>"four"thenstop
650 ifst<>64thenstop
655 ifst<>64thenstop
660 close1:close2
665 dos"s:file1,file2"
699 dos"u0>t":print"ok":return

700 print"07 c: copy file",,;
710 open1,8,2,"file1,p,w":print#1,"hello world!":close1
720 dos"c:file2=file1
730 open1,8,2,"file2"
740 input#1,a$:ifa$<>"hello world!"thenstop
750 ifst<>64thenstop
760 close1
770 dos"s:file1,file2"
799 dos"u0>t":print"ok":return

800 print"08 c: concatenate files",;
805 open1,8,2,"file1,p,w":print#1,"one":print#1,"two":close1
810 open1,8,2,"file2,p,w":print#1,"three":print#1,"four":close1
815 open1,8,2,"file3,p,w":print#1,"five":print#1,"six":close1
820 dos"c:file4=file1,file2,file3
825 open1,8,2,"file4"
830 input#1,a$:ifa$<>"one"thenstop
835 input#1,a$:ifa$<>"two"thenstop
840 input#1,a$:ifa$<>"three"thenstop
845 input#1,a$:ifa$<>"four"thenstop
850 input#1,a$:ifa$<>"five"thenstop
855 input#1,a$:ifa$<>"six"thenstop
860 ifst<>64thenstop
865 close1
870 dos"s:file1,file2,file3,file4"
899 dos"u0>t":print"ok":return

900 print"09 load non-existent file",;
910 open1,8,2,"nonexist"
920 open15,8,15:input#15,s,s$,x,y:close15:ifs<>62thenstop
930 close1
999 dos"u0>t":print"ok":return

1000 print"10 rename file",,;
1005 open1,8,2,"file1,p,w":print#1,"hello":close1
1010 dos"r:file2=file1"
1015 open1,8,2,"file2"
1020 input#1,a$:ifa$<>"hello"thenstop
1025 ifst<>64thenstop
1030 close1
1035 open1,8,2,"file1"
1040 open15,8,15:input#15,s,s$,x,y:close15:ifs<>62thenstop
1045 close1
1050 dos"s:file2"
1099 dos"u0>t":print"ok":return

1100 print"11 rename to file that exists",;
1105 open1,8,2,"file1,p,w":print#1,"hello":close1
1110 open1,8,2,"file2,p,w":print#1,"hello":close1
1120 dos"r:file2=file1"
1130 open15,8,15:input#15,s,s$,x,y:close15:ifs<>63thenstop
1140 dos"s:file1,file2"
1199 dos"u0>t":print"ok":return

1200 print"12 copy to file that exists",;
1205 open1,8,2,"file1,p,w":print#1,"hello":close1
1210 open1,8,2,"file2,p,w":print#1,"hello":close1
1220 dos"c:file2=file1"
1230 open15,8,15:input#15,s,s$,x,y:close15:ifs<>63thenstop
1240 dos"s:file1,file2"
1299 dos"u0>t":print"ok":return

1300 print"13 ui",,,;
1310 dos"ui"
1320 open15,8,15:input#15,s,s$,x,y:close15:ifs<>73thenstop
1399 dos"u0>t":print"ok":return

1400 print"14 scratch non-existent file",;
1410 dos"s:nonexist"
1420 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1425 ifx<>0thenstop
1499 dos"u0>t":print"ok":return

1500 print"15 scratch two files",;
1505 open1,8,2,"file1,p,w":print#1,"hello":close1
1510 open1,8,2,"file2,p,w":print#1,"hello":close1
1515 dos"s:file1,file2"
1520 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1525 ifx<>2thenstop
1599 dos"u0>t":print"ok":return

1600 print"16 lock file (l)",,;
1601 ifnotfand1thenprint"skipped":return
1605 open1,8,2,"file,p,w":print#1,"hello":close1
1610 open15,8,15,"l:file":close15
1615 dos"s:file"
1620 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1625 ifx<>0thenstop
1630 open15,8,15,"l:file":close15
1635 dos"s:file"
1640 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1645 ifx<>1thenstop
1699 dos"u0>t":print"ok":return

1700 print"17 lock file (f-l/f-u)",;
1701 ifnotfand4thenprint"skipped":return
1705 open1,8,2,"file,p,w":print#1,"hello":close1
1710 open15,8,15,"f-l:file":close15
1715 dos"s:file"
1720 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1725 ifx<>0thenstop
1730 open15,8,15,"f-u:file":close15
1735 dos"s:file"
1740 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1745 ifx<>1thenstop
1799 dos"u0>t":print"ok":return

1800 print"18 create file, ill. dir",;
1801 ifnotfand2thenprint"skipped":return
1802 iffand8thenprint"known bad":return:rem todo: should return status 39
1810 open1,8,2,"//dir/:file,p,w":
1820 open15,8,15:input#15,s,s$,x,y:close15:ifs<>39thenstop
1830 close1
1899 dos"u0>t":print"ok":return

1900 print"19 make/remove directory",;
1901 ifnotfand2thenprint"skipped":return
1905 dos"md:dir"
1915 open15,8,15:input#15,s,s$,x,y:close15:ifs<>0thenstop
1920 dos"rd:dir
1925 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1thenstop
1930 ifx<>1thenstop
1999 dos"u0>t":print"ok":return

2000 print"20 create/read file in subdir",;
2001 ifnotfand2thenprint"skipped":return
2002 ifnotfand8thenprint"skipped":return:rem todo: problem on cmd
2005 dos"md:dir"
2020 open1,8,2,"//dir/:file,p,w"
2025 open15,8,15:input#15,s,s$,x,y:close15:ifs<>0thenstop
2030 print#1,"hello":close1
2035 open1,8,2,"//dir/:file"
2037 open15,8,15:input#15,s,s$,x,y:close15:ifs<>0thenstop
2040 input#1,a$:ifa$<>"hello"thenstop
2045 ifst<>64thenstop
2050 close1
2060 dos"s//dir/:file"
2065 dos"rd:dir
2099 dos"u0>t":print"ok":return

2100 print"21 change dir, read file",;
2101 ifnotfand2thenprint"skipped":return
2105 dos"md:dir"
2110 open1,8,2,"file1,p,w":print#1,"one":close1
2115 open1,8,2,"//dir/:file2,p,w":print#1,"two":close1
2120 dos"cd:dir"
2135 open1,8,2,"file2"
2140 input#1,a$:ifa$<>"two"thenstop
2145 close1
2150 open1,8,2,"//:file1"
2155 input#1,a$:ifa$<>"one"thenstop
2160 close1
2165 dos"cd:_"
2170 dos"s//dir/:file2,file1"
2175 dos"rd:dir
2199 dos"u0>t":print"ok":return

2200 print"22 memory write/read",;
2201 ifnotfand8thenprint"skipped":return:rem disabled on non-cmdr-dos
2205 b=$0200
2210 open15,8,15,"m-w"+chr$(band255)+chr$(int(b/256))+chr$(5)+"hello":close15
2215 open15,8,15,"m-r"+chr$((b+1)and255)+chr$(int((b+1)/256))+chr$(4):close15
2220 a$="":open1,8,15
2225 fori=1to4:get#1,c$:a$=a$+c$:next:ifa$<>"ello"thenstop
2230 get#1,a$:ifa$<>chr$(13)thenstop
2235 ifst<>64thenstop
2240 close1
2245 dos"ui"
2299 dos"u0>t":print"ok":return

2300 print"23 change to non-existent dir",;
2301 ifnotfand2thenprint"skipped":return
2302 iffand8thenprint"known bad":return:rem todo: should return status 39
2310 dos"cd:nonexist
2320 open15,8,15:input#15,s,s$,x,y:close15:ifs<>39thenstop
2399 dos"u0>t":print"ok":return

2400 print"24 change partition",,;
2401 ifnotfand2thenprint"skipped":return
2410 dos"cp1
2420 open15,8,15:input#15,s,s$,x,y:close15:ifs<>2thenstop
2430 ifx<>1thenstop
2499 dos"u0>t":print"ok":return

2500 print"25 change to non-exist. part",;
2501 ifnotfand2thenprint"skipped":return
2510 dos"cp200
2520 open15,8,15:input#15,s,s$,x,y:close15:ifs<>77thenstop
2530 ifx<>200thenstop
2599 dos"u0>t":print"ok":return

2600 print"26 memory execute",,;
2601 ifnotfand8thenprint"skipped":return:rem disabled on non-cmds-dos
2605 b=$0200:bl=band255:bh=int(b/256)
2610 a$="m-w"+chr$(bl)+chr$(bh)+chr$(11)+chr$(169)+chr$(77)+chr$(141)
2615 a$=a$+chr$(bl)+chr$(bh)+chr$(169)+chr$(83)+chr$(141)+chr$(bl+1)
2620 a$=a$+chr$(bh)+chr$(96)
2625 open15,8,15,a$:close15
2630 open15,8,15,"m-e"+chr$(bl)+chr$(bh):close15
2635 open15,8,15,"m-r"+chr$(bl)+chr$(bh)+chr$(2):close15
2640 open1,8,15
2645 get#1,a$:ifa$<>chr$($4d)thenstop
2650 get#1,a$:ifa$<>chr$($53)thenstop
2655 get#1,a$:ifa$<>chr$(13)thenstop
2660 ifst<>64thenstop
2670 close1
2699 dos"u0>t":print"ok":return

2700 print"27 initialize",,;
2710 dos"i
2720 open15,8,15:input#15,s,s$,x,y:close15:ifs<>0thenstop
2799 dos"u0>t":print"ok":return

2800 print"28 initialize non-exist. part",;
2801 ifnotfand2thenprint"skipped":return
2810 dos"i200
2820 open15,8,15:input#15,s,s$,x,y:close15:ifs<>74thenstop
2899 dos"u0>t":print"ok":return

2900 print"29 rename, wildcard source",;
2901 ifnotfand8thenprint"skipped":return:rem only supported on cmdr-dos
2905 open1,8,2,"file1,p,w":print#1,"hello":close1
2910 open1,8,2,"file2,p,w":print#1,"hello":close1
2920 dos"r:file2=?ile1"
2930 open15,8,15:input#15,s,s$,x,y:close15:ifs<>63thenstop
2940 dos"s:file1,file2"
2999 dos"u0>t":print"ok":return

3000 print"30 read past eof",,;
3005 open1,8,1,"file":print#1,"hi!":close1
3010 open1,8,0,"file"
3015 get#1,a$:ifa$<>"h"thenstop
3020 ifstthenstop
3025 get#1,a$:ifa$<>"i"thenstop
3030 ifstthenstop
3035 get#1,a$:ifa$<>"!"thenstop
3040 ifstthenstop
3045 get#1,a$:ifa$<>chr$(13)thenstop
3050 ifst<>64thenstop
3055 get#1,a$:ifa$<>chr$(199)thenstop
3060 ifst<>66thenstop
3065 close1
3070 dos"s:file"
3099 dos"u0>t":print"ok":return

3100 print"31 read from fnf channel",;
3110 open1,8,0,"nonexist"
3120 ifst<>0thenstop
3130 get#1,a$:ifa$<>chr$(199)thenstop
3140 ifst<>66thenstop
3150 get#1,a$:ifa$<>chr$(199)thenstop
3160 ifst<>66thenstop
3170 close1
3199 dos"u0>t":print"ok":return

3200 print"32 read from channel w/o fn",;
3210 open1,8,02
3220 ifst<>0thenstop
3230 get#1,a$:ifa$<>chr$(199)thenstop
3240 ifst<>66thenstop
3250 get#1,a$:ifa$<>chr$(199)thenstop
3260 ifst<>66thenstop
3270 close1
3299 dos"u0>t":print"ok":return

3300 print"33 status string",,;
3305 dos"i":open15,8,15
3310 forj=0to10
3315 s$="":fori=1to12:get#15,a$:s$=s$+a$
3320 ifstthenstop
3325 next
3330 ifs$<>"00, ok,00,00"thenstop
3335 get#15,a$:ifa$<>chr$(13)thenstop
3340 ifst<>64thenstop
3345 next
3350 close15
3399 dos"u0>t":print"ok":return

3400 print"34 write to fnf channel",;
3410 open1,8,1,"*"
3420 ifstthenstop
3430 print#1,"a";
3440 ifst<>-128thenstop
3450 print#1,"a";
3460 ifst<>-128thenstop
3470 close1
3499 dos"u0>t":print"ok":return

3500 print"35 write to channel w/o fn",;
3510 open1,8,1
3520 ifstthenstop
3530 print#1,"a";
3540 ifst<>-128thenstop
3550 print#1,"a";
3560 ifst<>-128thenstop
3570 close1
3599 dos"u0>t":print"ok":return

3600 print"36 get diskchange",,;
3601 ifnotfand2thenprint"skipped":return
3610 dos"g-d"
3620 open15,8,15
3630 get#15,a$:ifa$<>""anda$<>chr$(1)thenstop
3640 ifstthenstop
3650 iff=3goto3699 : rem cmd fd/hd is buggy
3660 get#15,a$:ifa$<>chr$(13)thenstop
3670 ifst<>64thenstop
3680 close15
3699 dos"u0>t":print"ok":return

3700 print"37 get partition info",;
3701 ifnotfand8thenprint"skipped":return:rem buggy on cmd
3710 open15,8,15,"g-p"+chr$(1):close15
3720 open15,8,15
3730 fori=0to29:get#15,a$:ifstthenstop
3740 next
3750 get#15,a$:ifa$<>chr$(13)thenstop
3760 ifst<>64thenstop
3770 close15
3799 dos"u0>t":print"ok":return

3800 print"38 re-send name to channel",;
3805 open1,8,2,"file1,p,w":print#1,"one":close1
3810 open1,8,2,"file2,p,w":print#1,"two":close1
3815 open1,8,2,"file1"
3825 open2,8,2,"file2"
3840 input#1,a$:ifa$<>"two"thenstop
3845 open3,8,2,"file1"
3855 input#1,a$:ifa$<>"one"thenstop
3860 close1:close2:close3
3865 dos"s:file1,file2
3899 dos"u0>t":print"ok":return

3900 print"39 scratch with wildcards",;
3901 ifnotfand2thenprint"skipped":return
3905 open1,8,2,"nomatch1,p,w":print#1,"hello":close1
3910 dos"c:file1=nomatch1
3915 dos"md:file2
3920 dos"c:file3=nomatch1
3925 dos"l:file3
3930 dos"c:nomatch2=nomatch1
3935 dos"c:file4=nomatch1
3940 dos"s:file?
3945 open1,8,2,"file1":close1
3950 close15:open15,8,15:input#15,s,s$,x,y:close15:ifs<>62thenstop
3955 dos"rd:file2
3960 open15,8,15:input#15,s,s$,x,y:close15:ifs<>1andx<>1thenstop
3965 open1,8,2,"file3":close1
3970 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
3972 open1,8,2,"file4":close1
3974 open15,8,15:input#15,s,s$,x,y:close15:ifs<>62thenstop
3976 open1,8,2,"nomatch1":close1
3978 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
3980 open1,8,2,"nomatch2":close1
3982 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
3984 dos"l:file3
3986 dos"s:nomatch?,file3
3999 dos"u0>t":print"ok":return

4000 print"40 overflow buffers",,;
4005 open1,8,2,"file1,p,w":print#1,"one":close1:dos"md:dir1
4010 open15,8,15:fori=0to8
4015 openi+1,8,i+2,mid$(str$(i),2)+",p,w"
4020 input#15,s,s$,x,y:ifs=0thennext
4022 ifs=0goto4060 : rem couldn't overflow buffers!
4025 iffand2then:dos"l:file1":input#15,s,s$,x,y:ifs<>1ands<>70thenstop
4030 iffand4then:dos"f-l:file1":input#15,s,s$,x,y:ifs<>1ands<>70thenstop
4035 iffand4then:dos"f-u:file1":input#15,s,s$,x,y:ifs<>1ands<>70thenstop
4040 dos"r:file2=file1":input#15,s,s$,x,y:ifs<>0ands<>70thenstop
4045 dos"s:file1,file2":input#15,s,s$,x,y:ifs<>1ands<>70thenstop
4050 iffand2then:dos"md:dir2":input#15,s,s$,x,y:ifs<>1ands<>70thenstop
4055 iffand2then:dos"rd:dir1":input#15,s,s$,x,y:ifs<>1ands<>70thenstop
4060 fori=0to11:closei+1:next:close15
4070 dos"s:file1":dos"rd:dir1":dos"s:0,1,2,3,4,5,6,7,8
4099 dos"u0>t":print"ok":return

4100 print"41 create existing file",;
4110 open1,8,2,"file,p,w":print#1,"hello world!":close1
4140 open1,8,2,"file,p,w":print#1,"hello world!":close1
4150 open15,8,15:input#15,s,s$,x,y:close15:ifs<>63thenstop
4160 dos"s:file
4199 dos"u0>t":print"ok":return

4200 print"42 overwrite existing file",;
4210 open1,8,2,"file,p,w":print#1,"hello":close1
4240 open1,8,2,"@:file,p,w":print#1,"world!":close1
4250 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
4260 open1,8,2,"file":input#1,a$:close1:ifa$<>"world!"thenstop
4260 dos"s:file
4299 dos"u0>t":print"ok":return

4300 print"43 create/read on two part",;
4301 ifnotp2thenprint"skipped":return
4310 open1,8,2,"1:file1,p,w":print#1,"one":close1
4320 open1,8,2,"2:file2,p,w":print#1,"two":close1
4330 open1,8,2,"1:file1,p,r":input#1,a$:close1:ifa$<>"one"thenstop
4340 ifst<>64thenstop
4350 open1,8,2,"2:file2,p,r":input#1,a$:close1:ifa$<>"two"thenstop
4360 ifst<>64thenstop
4370 dos"s1:file1":open15,8,15:input#15,s,s$,x,y:close15:ifx<>1thenstop
4380 dos"s2:file2":open15,8,15:input#15,s,s$,x,y:close15:ifx<>1thenstop
4399 dos"u0>t":print"ok":return

4400 print"44 copy between partitions",;
4401 ifnotp2thenprint"skipped":return
4410 open1,8,2,"1:file1,p,w":print#1,"hello world!":close1
4420 dos"c2:file2=1:file1
4430 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
4440 open1,8,2,"2:file2,p,r":input#1,a$:close1:ifa$<>"hello world!"thenstop
4450 dos"s1:file1":open15,8,15:input#15,s,s$,x,y:close15:ifx<>1thenstop
4460 dos"s2:file2":open15,8,15:input#15,s,s$,x,y:close15:ifx<>1thenstop
4499 dos"u0>t":print"ok":return

4500 print"45 c: copy non-existent file",;
4502 iffand8thenprint"known bad":return:rem should not create file
4510 dos"c:file=nonexist
4520 open15,8,15:input#15,s,s$,x,y:close15:ifs<>62thenstop
4530 open1,8,2,"file":close1
4540 open15,8,15:input#15,s,s$,x,y:close15:ifs<>62thenstop
4599 dos"u0>t":print"ok":return

4600 print"46 software write protect",;
4601 ifnotp2thenprint"skipped":return
4610 dos"w-1
4620 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
4630 open1,8,2,"1:file,p,w":close1
4640 open15,8,15:input#15,s,s$,x,y:close15:ifs<>26thenstop
4650 dos"w-0
4660 open15,8,15:input#15,s,s$,x,y:close15:ifsthenstop
4699 dos"u0>t":print"ok":return

4700 print"47 command channel echo",;
4701 ifnotfand8thenprint"skipped":return
4710 doschr$(255)+"hello"+chr$(0)
4720 open15,8,15:input#15,s,s$,x,y:close15:ifs<>79ors$<>"hello"thenstop
4730 doschr$(66)+chr$(45)+chr$(63)+ti$
4740 open15,8,15:input#15,s,s$,x,y:close15:ifs<>79orlen(s$)<>25thenstop
4750 doschr$(66)+chr$(45)+chr$(42)+ti$
4760 open15,8,15:input#15,s,s$,x,y:close15:ifs<>79orlen(s$)<>28thenstop
4799 dos"u0>t":print"ok":return

run
