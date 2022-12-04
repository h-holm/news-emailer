#!/usr/bin/env bash
# Script to send scraped news files as email attachments (using Mutt) to the recipient specified by
# the --recipient flag. News files in the --from-dir are considered, as long their filename align
# with the sources specified in the line-by-line --sources-file. The --body-file specifies the path
# to a text file containing the email body.

set -e

print_help_message() {
  cat <<-EOF
		This script sends files as email attachments using `mutt` to the recipient specified by the
		--recipient flag. NeNews files in the --from-dir are considered, as long their filename align
		with the sources specified in the line-by-line --sources-file. The --body-file specifies the
		path to a text file containing the email body.
	EOF
  echo
  cat <<-EOF
		Usage: fetch_news
			[ -r | --recipient ]
			[ -s | --sources-file ]
			[ -b | --body-file ]
			[ -f | --from-dir ]
			[ -h | --help ]"
	EOF
}

SHORT_OPTS=r:,s:,b:,f:,h
LONG_OPTS=recipient:,sources-file:,body-file:,from-dir:,help
OPTS=$(getopt --options $SHORT_OPTS --longoptions $LONG_OPTS --name fetch_news.sh -- "$@")

# Returns the count of arguments that are in short or long options
VALID_ARGUMENTS=$#

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  print_help_message
  exit 2
fi

eval set -- "$OPTS"

while [ $# -ge 1 ]; do
  case "$1" in
    -r | --recipient )
      RECIPIENT="$2"
      shift 2
      ;;
    -s | --sources-file )
      SOURCES_FILE="$2"
      shift 2
      ;;
    -b | --body-file )
      BODY_FILE="$2"
      shift 2
      ;;
    -s | --from-dir )
      FROM_DIR="$2"
      shift 2
      ;;
    -h | --help )
      print_help_message
      exit 2
      ;;
    --)
      # No more options left.
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      print_help_message
      exit 2
      ;;
  esac
done

if [ ! -f "$SOURCES_FILE" ]; then
  echo "No file found at value specified by --sources-file. Please provide the path to an existing file. Exiting..."
  exit 2
else
  readarray -t SOURCES < $SOURCES_FILE
  if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "The provided --sources-file is empty. Please specify the path to a line-by-line file of valid Calibre news sources. Exiting..."
    exit 2
  fi
fi

if [ ! -f "$BODY_FILE" ]; then
  echo "No file found at value specified by --body-file. Please provide the path to an existing file. Exiting..."
  exit 2
fi

if [ ! -d "$FROM_DIR" ]; then
  echo "No directory found at value specified by --from-dir. Please provide the path to an existing directory. Exiting..."
  exit 2
fi

# Check that the provided $RECIPIENT is a string on a valid email format.
email_regex="^(([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))\.)*([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))@\w((-|\w)*\w)*\.(\w((-|\w)*\w)*\.)*\w{2,4}$"
if ! [[ "$RECIPIENT" =~ $email_regex ]]; then
  echo "The provided --recipient is not a string on a valid email format (name[.name]@domain.something)."
  exit 2
fi

echo "-------------------------------------------------------------"
echo "Starting script <send_news_over_email.sh> at $(date)."
echo "Considering the following news sources: ${SOURCES[@]}."

timestamp=$(date +%Y-%m-%d-%H%M)

attachments=()
for source in "${SOURCES[@]}"; do
  echo
  echo "${source}:"
  echo "- find "$FROM_DIR" -name "*$source*" -mtime -1 -type f -print"
  file_to_attach=$(find "$FROM_DIR" -name "*$source*" -mtime -1 -type f -print)
  echo "- ${file_to_attach}"
  if [ -f "$file_to_attach" ]; then
    echo "- Attaching news from $source to the attachment string..."
    attachments+=("$file_to_attach")
  fi
done

todays_date=$(date '+%Y-%m-%d')
echo
echo "Using command 'mutt -s \"${todays_date} News\" -a ${attachments[@]} -- ${RECIPIENT} < \"${BODY_FILE}\"'"
echo
mutt -s "${todays_date} News" -a "${attachments[@]}" -- ${RECIPIENT} < "${BODY_FILE}"

echo
echo "Script <send_news_over_email.sh> completed at $(date)."
