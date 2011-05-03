#!/bin/bash
FILE=$1
TPATH=$2

SRC_LIB_PATH=`${CROSS_COMPILE}gcc -print-sysroot`
SRC_LIB_PATH=`echo $SRC_LIB_PATH/lib`

get_libs(){
	KAKA=`${CROSS_COMPILE}objdump -x $1 |grep NEEDED|sed -e "s/\s\s*/ /g"|cut -d ' ' -f 3`
	echo $KAKA
}

LIBS=`get_libs $1`

while [ x"$LIBS" != x ]
do
	L=""
	for lib in $LIBS
	do
		if [ -e $TPATH/$lib ]; then
			echo "Exists $TPATH/$lib"
			continue
		fi
		if [ -e "$SRC_LIB_PATH/$lib" ]; then
			LIBRARY="$SRC_LIB_PATH/$lib"
			R_PATH=`realpath $LIBRARY`
			cp -va $LIBRARY $R_PATH $TPATH
			L="$L $R_PATH"
		else
			echo "$SRC_LIB_PATH/$lib DOES NOT EXIST!!!"
		fi
	done
	LIBS=""
	for lib in $L
	do
		l=`get_libs $lib`
		if [ x"$l" != x ]; then
			LIBS="$LIBS $l"
			echo "$lib -> $l"
		else
			echo "$lib has no dependency!"
		fi
	done
done

# Copy libgcc as well..
LGCC=`${CROSS_COMPILE}gcc -print-libgcc-file-name`
cp -va $LGCC $TPATH
