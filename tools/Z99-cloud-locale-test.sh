#!/bin/sh
# vi: ts=4 noexpandtab
#
# Author: Ben Howard <ben.howard@canonical.com>
# Author: Scott Moser <scott.moser@ubuntu.com>
# (c) 2012, Canonical Group, Ltd.
#
# Purpose: Detect invalid locale settings and inform the user
#  of how to fix them.
#

locale_warn() {
	local cr="
"
	local bad_names="" bad_lcs="" key="" value="" var=""
	local w1 w2 w3 w4 remain
	# locale is expected to output either:
	# VARIABLE=
	# VARIABLE="value"
	# locale: Cannot set LC_SOMETHING to default locale
	while read -r w1 w2 w3 w4 remain; do
		case "$w1" in
			locale:) bad_names="${bad_names} ${w4}";;
			*)
				key=${w1%%=*}
				val=${w1#*=}
				val=${val#\"}
				val=${val%\"}
				vars="${vars} $key=$val";;
		esac
	done
	for bad in $bad_names; do
		for var in ${vars}; do
			[ "${bad}" = "${var%=*}" ] || continue
			value=${var#*=}
			[ "${bad_lcs#* ${value}}" = "${bad_lcs}" ] &&
        			bad_lcs="${bad_lcs} ${value}"
			break
		done
	done
	bad_lcs=${bad_lcs# }
	[ -n "$bad_lcs" ] || return 0

	printf "_____________________________________________________________________\n"
	printf "WARNING! Your environment specifies an invalid locale.\n"
	printf " This can affect your user experience significantly, including the\n"
	printf " ability to manage packages. You may install the locales by running:\n\n"

	local bad invalid="" to_gen="" sfile="/usr/share/i18n/SUPPORTED"
	local pkgs=""
	if [ -e "$sfile" ]; then
		for bad in ${bad_lcs}; do
			grep -q -i "${bad}" "$sfile" &&
				to_gen="${to_gen} ${bad}" ||
				invalid="${invalid} ${bad}"
		done
	else
		printf "  sudo apt-get install locales\n"
		to_gen=$bad_lcs
	fi
	to_gen=${to_gen# }

	local pkgs=""
	for bad in ${to_gen}; do
		pkgs="${pkgs} language-pack-${bad%%_*}"
	done
	pkgs=${pkgs# }

	if [ -n "${pkgs}" ]; then
		printf "   sudo apt-get install ${pkgs# }\n"
		printf "     or\n"
		printf "   sudo locale-gen ${to_gen# }\n"
		printf "\n"
	fi
	for bad in ${invalid}; do
        	printf "WARNING: '${bad}' is an invalid locale\n"
	done

	printf "To see all available language packs, run:\n"
	printf "   apt-cache search \"^language-pack-[a-z][a-z]$\"\n"
	printf "To disable this message for all users, run:\n"
	printf "   sudo touch /var/lib/cloud/instance/locale-check.skip\n"
	printf "_____________________________________________________________________\n\n"

	# only show the message once
	: > ~/.cloud-locale-test.skip 2>/dev/null || :
}

[ -f ~/.cloud-locale-test.skip -o -f /var/lib/cloud/instance/locale-check.skip ] ||
	locale 2>&1 | locale_warn

unset locale_warn
