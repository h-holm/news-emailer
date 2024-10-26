#!/usr/bin/env bash
# Script to send scraped news EPUBs as email attachments using Mutt to the recipient
# specified by the `--recipient` flag. News files in the `--from-dir` are considered,
# as long their filenames align with the sources specified in the line-by-line
# `--sources-file`. The `--body-file` specifies the path to a text file containing the
# email body to use.

set -e

PROGRAM_NAME="send_news_over_email.sh"
MAX_NUM_DAYS="3"

function usage {
  echo 'This script sends files as email attachments using `mutt` to the recipient' \
    'specified by the `--recipient` flag. News files in the `--from-dir` are' \
    "considered, as long their filenames align with the sources specified in the" \
    'line-by-line `--sources-file`. The `--body-file` specifies the path to a text' \
    "file containing the email body to use."
  echo
  echo "Usage: $PROGRAM_NAME [ -r | --recipient ] [ -s | --sources-file ]"\
    "[ -b | --body-file ] [ -f | --from-dir ] [ -m | --max-num-days ] [ -h | --help ]"
  echo "  -r | --recipient      Email address to send email(s) to."
  echo "  -s | --sources-file   Path to line-by-line file of in-scope news sources."
  echo "  -b | --body-file      Path to file containing the email body to use."
  echo "  -f | --from-dir       Path to directory containing news EPUBs."
  echo "  -m | --max-num-days   Max allowed age (in days) of the EPUB files." \
    "Default: $MAX_NUM_DAYS."
  echo "  -h | --help           Display this help message."
}

SHORT_OPTS=r:,s:,b:,f:,h
LONG_OPTS=recipient:,sources-file:,body-file:,from-dir:,help
OPTS=$(getopt --options $SHORT_OPTS --longoptions $LONG_OPTS --name $PROGRAM_NAME -- "$@")

# Returns the count of provided args that are in the short or long options.
VALID_ARGUMENTS=$#

if [ "$VALID_ARGUMENTS" -eq 0 ]; then
  usage
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
    -f | --from-dir )
      FROM_DIR="$2"
      shift 2
      ;;
    -m | --max-num-days )
      MAX_NUM_DAYS="$2"
      shift 2
      ;;
    -h | --help )
      usage
      exit 2
      ;;
    --)
      # No more options left.
      shift;
      break
      ;;
    *)
      echo "Unexpected option: $1"
      usage
      exit 2
      ;;
  esac
done

if [ ! command -v mutt &> /dev/null ]; then
  echo 'The `mutt` command-line utility is required by this script but could not be' \
    "found. Please install and configure Mutt before running this script."
  exit 2
fi

if [ ! -f "${SOURCES_FILE}" ]; then
  echo "No valid \`--sources-file\` found at '${SOURCES_FILE}'. Please provide the" \
    "path to an existing file. Exiting..."
  exit 2
else
  readarray -t SOURCES < ${SOURCES_FILE}
  if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "The provided '${SOURCES_FILE}' file appears to be empty. Please specify" \
      "the path to a line-by-line file of valid Calibre news sources. Exiting..."
    exit 2
  fi
fi

if [ ! -f "${BODY_FILE}" ]; then
  echo "No valid \`--body-file\` found at '${BODY_FILE}'. Please provide the path to" \
    "an existing file. Exiting..."
  exit 2
fi

if [ ! -d "${FROM_DIR}" ]; then
  echo "No valid \`--from-dir\` directory found at '${FROM_DIR}'. Please provide the" \
    "path to an existing directory. Exiting..."
  exit 2
fi

if [[ ! "${MAX_NUM_DAYS}" -gt 0 ]]; then
  echo "The provided \`--max-num-days\` (${MAX_NUM_DAYS}) is not a positive integer." \
    " Exiting..."
  exit 2
fi
# Check that the provided $RECIPIENT is a string on a valid email format.
email_regex="^(([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))\.)*([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))@\w((-|\w)*\w)*\.(\w((-|\w)*\w)*\.)*\w{2,4}$"
if ! [[ "${RECIPIENT}" =~ $email_regex ]]; then
  echo "'${RECIPIENT}' is not a valid \`--recipient\`! Please provide a string on a" \
    "valid email format: (name[.name]@domain.something)."
  exit 2
fi

echo "-------------------------------------------------------------"
echo "Starting script <$PROGRAM_NAME> at $(date)."
echo "Considering the following news sources: ${SOURCES[@]}."

todays_date=$(date '+%Y-%m-%d')

for source in "${SOURCES[@]}"; do
  echo
  echo "${source}:"
  echo "- find "${FROM_DIR}" -name "*${source}*" -mtime -"${MAX_NUM_DAYS}" -type f -print"
  file_to_attach=$(find "${FROM_DIR}" -name "*${source}*" -mtime -"${MAX_NUM_DAYS}" -type f -print)
  echo "- ${file_to_attach}"
  if [ -f "${file_to_attach}" ]; then
    echo
    echo "mutt -s \"${todays_date} ${source}\" -a ${file_to_attach} -- ${RECIPIENT} < \"${BODY_FILE}\""
    echo
    mutt -s "${todays_date} ${source}" -a "${file_to_attach}" -- ${RECIPIENT} < "${BODY_FILE}"
  fi
done

echo
echo "Script <$PROGRAM_NAME> completed at $(date)."
