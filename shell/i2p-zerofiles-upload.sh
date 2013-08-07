#!/usr/bin/env bash
# Copyright (c) 2012 fbt <fbt@fleshless.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#   - Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
# OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# About:
# A simple upload script for ZFH (http://zerofiles.i2p/)

export http_proxy=127.0.0.1:4444

cfg_url_regex='^[a-z]+://.+'
cfg_tmp_dir="/tmp/$USER/sup"
cfg_script_url='http://zfh.so/upload'

cfg_default_tags='sup'
cfg_default_title="Uploaded: `date +%Y.%m.%d\ at\ %H:%M:%S`"

[[ -f $HOME/.suprc ]] && { source $HOME/.suprc; }

sup.msg() { echo "[sup] $1"; }
sup.err() { sup.msg "(error) $1" >&2; }

sup.usage() {
	echo "Usage: `basename $0` [-c title] [-t tags] [-RsF] [-D num] [file/url]"
}

sup.env() {
	for i in "$cfg_tmp_dir"; do
		[[ -d "$i" ]] || { mkdir -p "$i"; }
	done
}

sup.upload() {
	[[ "$file_title" ]] || { file_title="$cfg_default_title"; }

	curl -F file="@$file" \
		-F tags="$file_tags" \
		-F upload_mode='api' \
		-F submit="" \
		"$cfg_script_url" -s -L -A 'Sup Phost'

	[[ "$flag_rm" ]] && { rm "$file"; }
}

sup.scrot() {
	[[ "$scrot_exec" ]] || { scrot_exec=`which scrot`; }
	[[ "$scrot_exec" ]] || {
		sup.err "Please install scrot to use this function"
		return 1
	}

	[[ "$flag_scrot_fullscreen" ]] || { scrot_args+=( '-s' ); }
	[[ "$cfg_scrot_delay" ]] && { scrot_args+=( "-d $cfg_scrot_delay" ); }

	file=`mktemp "$cfg_tmp_dir/sup_tmp_XXXXXX.png"`
	scrot "${scrot_args[@]}" "$file"
}

sup.exclude() {
	[[ "$2" ]] && { echo "$1"; return 1; }
	return 0
}

sup.if_url() { echo "$1" | grep -oE "$cfg_url_regex" &>/dev/null; }

while getopts "c:t:D:sFrRh" option; do
	case "$option" in
		c) file_title="$OPTARG";;
		t) file_tags="$OPTARG";;

		R) flag_rm='1';;

		s) flag_scrot='1';;
		F) flag_scrot_fullscreen='1';;
		D) cfg_scrot_delay="$OPTARG";;

		h|*) sup.usage;;
	esac
done

[[ "$OPTIND" ]] && { shift $(($OPTIND-1)); }

sup.env

[[ "$flag_scrot" ]] && {
	sup.scrot
} || {
	sup.if_url "$1" && {
		file=`mktemp "$cfg_tmp_dir/sup_tmp_XXXXXX"`
		[[ "$file_title" ]] || { file_title="Source: $file; $cfg_default_title"; }

		curl -s "$1" > "$file"
	}
}

[[ "$file" ]] || { file="$1"; }
sup.upload
