#!/usr/bin/env bash
# Builds the testing results page for the report (section 5.5.1) and opens it.
# It asks which tests to run (all, main parts, or project work only) and for a
# Supabase access token (press Enter to skip the Supabase numbers).
#
#   tool/report/report.sh            asks
#   tool/report/report.sh --all      all tests, no question
#   tool/report/report.sh --main     main parts only
#
# More options at the top of tool/report/make_report.dart.
set -euo pipefail
cd "$(dirname "$0")/../.."
dart run tool/report/make_report.dart "$@"
