# system_profiler SPHardwareDataType | awk '/UUID/{print $NF}'
#
# sw_vers | awk '/ProductName:/{print $2 $3 $NF}'

# info=`sw_vers`
# curl -d "$info" -X POST http://localhost:8080/

# Constructing JSON payload
# info -> awk
# loop over ..? make key value string?
# JSON string for posting?

# Bash version 3.2?
# posix compatible
# Construct function

bin_md5() {
  openssl dgst -binary -md5
}

detect_os_name() {
  sw_vers | awk -F':\t' '/ProductName/{print $2}'
}

detect_os_version() {
  sw_vers | awk -F':\t' '/ProductVersion/{print $2}'
}

detect_hardware_uuid() {
  system_profiler SPHardwareDataType | awk '/UUID/{print $NF}'
}

generate_uuid() {
  # content_md5="$(bin_md5 < $(detect_hardware_uuid) | base64)"
  printf $(detect_hardware_uuid) | bin_md5 | base64
}

encode_json() {
  echo '{'
  local key value
  while [ $# -gt 0 ]; do
    key="$1"
    value="$2"
    shift 2
    printf '"%s":"%s"' "$(escape_json_string "$key")" "$(escape_json_string "$value")"
    [ $# -eq 0 ] || printf ','
  done
  echo '}'
}

escape_json_string() {
  printf "%s" "${1//\"/\\\"}" | tr '\n\t' ' '
}

system_info_payload() {
  encode_json \
    os "$(detect_os_name)" \
    os_version "$(detect_os_version)" \
    uuid "$(generate_uuid)"
}

json_envelope() {
  encode_json \
    system_info_payload "$(system_info_payload)"
}


system_info_payload | ruby -rjson -e 'p JSON.parse(STDIN.read)'

# curl -d system_info_payload -X POST http://localhost:8080/

# curl -X POST -H "Content-Type: application/json" -d json_envelope http://localhost:8080/
