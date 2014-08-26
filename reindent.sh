#/bin/sh

# This reindents all C files in the directory following PG rules (ported to gnu indent)
# as some of us have tab=8 spaces, and others tab=4 spaces

indent -bad -bap -bbo -bbb -bc -bl -brs -c33 -cd33 -cdb -nce -ci4 -cli0 \
       -cp33 -cs -d0 -di12 -nfc1 -nfca -nfc1 -i4 -nip -l79 -lp -nip -npcs \
       -nprs -npsl -saf -sai -saw -nsc -nsob -nss -nut *.c
