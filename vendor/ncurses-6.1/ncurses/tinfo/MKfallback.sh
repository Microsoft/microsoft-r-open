#!/bin/sh
##############################################################################
# Copyright (c) 1998-2016,2017 Free Software Foundation, Inc.                #
#                                                                            #
# Permission is hereby granted, free of charge, to any person obtaining a    #
# copy of this software and associated documentation files (the "Software"), #
# to deal in the Software without restriction, including without limitation  #
# the rights to use, copy, modify, merge, publish, distribute, distribute    #
# with modifications, sublicense, and/or sell copies of the Software, and to #
# permit persons to whom the Software is furnished to do so, subject to the  #
# following conditions:                                                      #
#                                                                            #
# The above copyright notice and this permission notice shall be included in #
# all copies or substantial portions of the Software.                        #
#                                                                            #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    #
# THE ABOVE COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        #
# DEALINGS IN THE SOFTWARE.                                                  #
#                                                                            #
# Except as contained in this notice, the name(s) of the above copyright     #
# holders shall not be used in advertising or otherwise to promote the sale, #
# use or other dealings in this Software without prior written               #
# authorization.                                                             #
##############################################################################
# $Id: MKfallback.sh,v 1.21 2017/04/12 00:50:50 tom Exp $
#
# MKfallback.sh -- create fallback table for entry reads
#
# This script generates source code for a custom version of read_entry.c
# that (instead of reading capabilities for an argument terminal type
# from an on-disk terminfo tree) tries to match the type with one of a
# specified list of types generated in.
#

terminfo_dir=$1
shift

terminfo_src=$1
shift

tic_path=$1
shift

case $tic_path in #(vi
/*)
	tic_head=`echo "$tic_path" | sed -e 's,/[^/]*$,,'`
	PATH=$tic_head:$PATH
	export PATH
	;;
esac

if test $# != 0 ; then
	tmp_info=tmp_info
	echo creating temporary terminfo directory... >&2

	TERMINFO=`pwd`/$tmp_info
	export TERMINFO

	TERMINFO_DIRS=$TERMINFO:$terminfo_dir
	export TERMINFO_DIRS

	$tic_path -x $terminfo_src >&2
else
	tmp_info=
fi

cat <<EOF
/* This file was generated by $0 */

/*
 * DO NOT EDIT THIS FILE BY HAND!
 */

#include <curses.priv.h>

EOF

if [ "$*" ]
then
	cat <<EOF
#include <tic.h>

/* fallback entries for: $* */
EOF
	for x in $*
	do
		echo "/* $x */"
		infocmp -E $x | sed -e 's/\<short\>/NCURSES_INT2/g'
	done

	cat <<EOF
static const TERMTYPE2 fallbacks[$#] =
{
EOF
	comma=""
	for x in $*
	do
		echo "$comma /* $x */"
		infocmp -e $x
		comma=","
	done

	cat <<EOF
};

EOF
fi

cat <<EOF
NCURSES_EXPORT(const TERMTYPE2 *)
_nc_fallback2 (const char *name GCC_UNUSED)
{
EOF

if [ "$*" ]
then
	cat <<EOF
    const TERMTYPE2	*tp;

    for (tp = fallbacks;
	 tp < fallbacks + sizeof(fallbacks)/sizeof(TERMTYPE2);
	 tp++) {
	if (_nc_name_match(tp->term_names, name, "|")) {
	    return(tp);
	}
    }
EOF
else
	echo "	/* the fallback list is empty */";
fi

cat <<EOF
    return((const TERMTYPE2 *)0);
}

#if NCURSES_EXT_NUMBERS
#undef _nc_fallback

/*
 * This entrypoint is used by tack.
 */
NCURSES_EXPORT(const TERMTYPE *)
_nc_fallback (const char *name)
{
    const TERMTYPE2 *tp = _nc_fallback2(name);
    const TERMTYPE *result = 0;
    if (tp != 0) {
	static TERMTYPE temp;
	_nc_export_termtype2(&temp, tp);
	result = &temp;
    }
    return result;
}
#endif
EOF

if test -n "$tmp_info" ; then
	echo removing temporary terminfo directory... >&2
	rm -rf $tmp_info
fi
