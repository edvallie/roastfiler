#!/bin/bash

if [ -z "$1" ]; then
	echo "Usage: $0 <Sweet Maria's Product URL>" >&2
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


echo "{"
"$webgrab" "$webargs" "$1" |while read line
do
	# Get prodcut name
	if [ "${line//'property="og:title"'}" != "$line" ]; then
		product_name="${line##*'content="'}"
		product_name="${product_name%'"'*}"
		echo -e "\"name\": \"$(urlencode "$product_name")\","
	fi

	# Get region
	if [ "${line//'<td class="col data" data-th="Region">'}" != "$line" ]; then
		read -t1 region
		region="${region%%'<'*}"
		echo -e "\"region\": \"$(urlencode "$region")\","
	fi
	
	# Get description
	if [ "${line//'property="og:description"'}" != "$line" ]; then
		description="${line##*'content="'}"
		description="${description%'"'*}"
		echo -e "\"description\": \"$(urlencode "$description")\","
	fi	

	# Get notes
	if [ "${line//'<td class="col data" data-th="Roast Recommendations">'}" != "$line" ]; then
		read -t1 notes
		notes="${notes%%'<'*}"
		echo -e "\"notes\": \"$(urlencode "$notes")\""
	fi
done
echo "}"
