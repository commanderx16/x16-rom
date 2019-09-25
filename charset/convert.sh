cat iso-8859-15.s | sed -e "s/$(echo -e "\xE2\x96\x88")/1/g" | sed -e s/_/0/g > iso-8859-15.tmp.s
cat petscii.s | sed -e "s/$(echo -e "\xE2\x96\x88")/1/g" | sed -e s/_/0/g > petscii.tmp.s
