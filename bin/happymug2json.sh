#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 <Happy Mug Product URL>" >&2
	exit 1
fi

# Try wget
webgrab="$(which wget)"
webargs="-qO-"
# Try curl if no wget
if [ -z "$webgrab" ]; then
	webgrab="$(which curl)"
	webargs="-s"
fi

# bail if no wget or curl
if [ -z "$webgrab" ]; then
	echo "Couldn't locate wget or curl, one is required." >&2
	exit 1
fi

urlencode () {
        tab="`echo -en "\x9"`"
        i="$@"
        i=${i//%/%25}  ; i=${i//' '/%20} ; i=${i//$tab/%09}
        i=${i//!/%21}  ; i=${i//'"'/%22}  ; i=${i//#/%23}
        i=${i//\$/%24} ; i=${i//\&/%26}  ; i=${i//\'/%27}
        i=${i//(/%28}  ; i=${i//)/%29}   ; i=${i//\*/%2a}
        i=${i//+/%2b}  ; i=${i//,/%2c}   ; i=${i//-/%2d}
        i=${i//\./%2e} ; i=${i//\//%2f}  ; i=${i//:/%3a}
        i=${i//;/%3b}  ; i=${i//</%3c}   ; i=${i//=/%3d}
        i=${i//>/%3e}  ; i=${i//\?/%3f}  ; i=${i//@/%40}
        i=${i//\[/%5b} ; i=${i//\\/%5c}  ; i=${i//\]/%5d}
        i=${i//\^/%5e} ; i=${i//_/%5f}   ; i=${i//\`/%60}
        i=${i//\{/%7b} ; i=${i//|/%7c}   ; i=${i//\}/%7d}
        i=${i//\~/%7e}
        echo "$i"
        i=""
}

get_region () {
	"$webgrab" "$webargs" "https://happymugcoffee.com/collections/green-coffee" |while read line
	do
		if [ "${line//'green-coffee-title'}" != "$line" ]; then
			region="$line"
		fi
		if [ "${line//$1}" != "$line" ]; then
			region="${region##*'<h2>'}"
			region="${region%%'<'*}"
			echo "$region"
			break
		fi
	done
}


echo "{"
"$webgrab" "$webargs" "$1" |while read line
do
	# Get prodcut name
	if [ "${line//'property="og:title"'}" != "$line" ]; then
		product_name="${line##*'content="'}"
		product_name="${product_name%'"'*}"
		echo -e "\"name\": \"$(urlencode "$product_name")\","
	fi

	# Try to get region
	if [ -n "$product_name" ] && [ -z "$region" ]; then
		region="$(get_region "$product_name")"
		if [ -z "$region" ]; then
		       	# Make sure we don't try more than once
			region="Unknown"
		fi
		echo -e "\"region\": \"$(urlencode "$region")\","
	
	fi
	
	# Get description
	if [ "${line//'"description": "'}" != "$line" ]; then
		description="$line"
		while [ "${line//'"brand":'}" == "$line" ]
		do
			read -t1 line
			description+="$line"
		done
		description="${description##*'"description": "'}"
		description="${description%%'","brand":'**}"
		echo -e "\"description\": \"$(urlencode "$description")\""
	fi
done
echo "}"
