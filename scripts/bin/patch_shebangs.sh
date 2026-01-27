#!/usr/bin/env bash
set -euo pipefail

MODE="dry"
if [[ "${1:-}" == "--apply" ]]; then
  MODE="apply"
elif [[ "${1:-}" != "" ]]; then
  echo "Usage: $0 [--apply]" >&2
  exit 2
fi

scripts_dir="$(cd "$(dirname "$0")" && pwd)"

target_shebang='#!/usr/bin/env dotpy'
shebang_regex='^#!.*[[:space:]/](python|python3)([[:space:]]|$)'

candidates=()
skipped=()
changed=()

for path in "$scripts_dir"/*; do
  if [[ ! -f "$path" ]]; then
    continue
  fi

  filename="$(basename "$path")"
  # Skip the patcher itself and dotpy shim
  if [[ "$filename" == "patch_shebangs.sh" || "$filename" == "dotpy" ]]; then
    continue
  fi

  first_line=""
  if IFS= read -r first_line < "$path"; then
    :
  fi

  file_info=""
  if command -v file >/dev/null 2>&1; then
    file_info="$(file -b "$path" || true)"
  fi

  is_py=0
  if [[ "$path" == *.py ]]; then
    is_py=1
  elif [[ "$first_line" =~ $shebang_regex ]]; then
    is_py=1
  elif [[ -x "$path" && "$file_info" == *"Python script"* ]]; then
    is_py=1
  fi

  if [[ $is_py -eq 0 ]]; then
    skipped+=("$path|not-python")
    continue
  fi

  candidates+=("$path|$first_line")

done

if [[ ${#candidates[@]} -eq 0 ]]; then
  echo "No Python candidates found."
  exit 0
fi

echo "Candidates (path | current shebang):"
for entry in "${candidates[@]}"; do
  echo "  $entry"
  # safety: confirm candidate shebang is python or .py
  shebang="${entry#*|}"
  path="${entry%%|*}"
  if [[ "$path" != *.py && ! "$shebang" =~ $shebang_regex ]]; then
    echo "  WARNING: $path is not clearly Python. Aborting." >&2
    exit 1
  fi

done

if [[ "$MODE" != "apply" ]]; then
  echo "Dry-run only. Re-run with --apply to modify shebangs."
  exit 0
fi

for entry in "${candidates[@]}"; do
  path="${entry%%|*}"
  shebang="${entry#*|}"

  if [[ "$shebang" == "$target_shebang" ]]; then
    skipped+=("$path|already-dotpy")
    continue
  fi

  cp -p "$path" "$path.bak"

  tmpfile="${path}.tmp"
  if [[ "$file_info" == *"CRLF"* ]]; then
    python3 - <<'PY' "$path" "$tmpfile" "$target_shebang"
import sys

src = sys.argv[1]
dst = sys.argv[2]
shebang = sys.argv[3]

with open(src, "rb") as f:
    data = f.read()

lines = data.splitlines(keepends=True)
if not lines:
    lines = [b""]

lines[0] = (shebang + "\r\n").encode("utf-8")
out = b"".join(lines)

with open(dst, "wb") as f:
    f.write(out)
PY
  else
    {
      echo "$target_shebang"
      tail -n +2 "$path"
    } > "$tmpfile"
  fi

  mv "$tmpfile" "$path"

  changed+=("$path")

done

echo
printf "Changed files: %d\n" "${#changed[@]}"
for path in "${changed[@]}"; do
  echo "  $path"
done

echo
printf "Skipped files: %d\n" "${#skipped[@]}"
for entry in "${skipped[@]}"; do
  echo "  $entry"
done
