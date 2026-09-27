#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "${1:-.}" && pwd -P)"
WORK_NAME="${WORK_NAME:-project-transfer}"
WORK="$ROOT/$WORK_NAME"
BUNDLES="$WORK/bundles"
RESPONSES="$WORK/responses"
RECONSTRUCTED="$WORK/reconstructed"
REPORTS="$WORK/reports"
ARCHIVES="$WORK/archives"
CONTEXT="$WORK/context.md"
MAX_SIZE="${MAX_FILE_SIZE:-1048576}"
FILES=()

mkdir -p "$WORK" "$BUNDLES" "$RESPONSES" "$RECONSTRUCTED" "$REPORTS" "$ARCHIVES"

msg(){ printf '\033[1;36m[INFO]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[ATTENTION]\033[0m %s\n' "$*" >&2; }
die(){ printf '\033[1;31m[ERREUR]\033[0m %s\n' "$*" >&2; exit 1; }

install_self(){
  local src target="$WORK/project-bundler.sh"
  src="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"
  if [[ -f "$src" && "$src" != "$target" ]]; then
    cp "$src" "$target"
    chmod +x "$target"
  fi
}
install_self

create_context(){
  [[ -f "$CONTEXT" ]] && cp "$CONTEXT" "$CONTEXT.backup-$(date +%Y%m%d-%H%M%S)"
  cat > "$CONTEXT" <<'EOF'
# Project Context

## Processing rules

- Analyze the full project first.
- Preserve paths and existing behavior.
- Prefer separate downloadable files.
- Return changed files in full.
- Never use ellipses in code.

## Context maintenance

- Generate this file from the project and prompts.
- Keep only stable reusable rules.
- Use short imperative bullet points.
- Merge overlaps and remove duplicates.
- Replace obsolete or contradicted rules.
- Exclude temporary tasks and history.
- Keep at most 30 bullets.

## Project rules

- Infer concise project rules.
EOF
  msg "Contexte cree : $CONTEXT"
}

valid_file(){
  local f="$1" rel size mime
  rel="${f#$ROOT/}"
  [[ "$rel" == "$WORK_NAME" || "$rel" == "$WORK_NAME/"* ]] && return 1
  [[ "$rel" =~ (^|/)(\.git|node_modules|vendor|dist|build|coverage|\.next|\.nuxt|\.cache|cache|tmp|temp|venv|\.venv|__pycache__)(/|$) ]] && return 1
  [[ -f "$f" && -r "$f" ]] || return 1
  size=$(stat -c %s "$f" 2>/dev/null || echo 999999999)
  (( size <= MAX_SIZE )) || return 1
  mime=$(file -b --mime-type "$f" 2>/dev/null || true)
  [[ "$mime" == text/* || "$mime" =~ ^application/(json|xml|javascript|x-shellscript)$ ]] || grep -Iq . "$f" 2>/dev/null
}

collect(){
  local recursive="$1" f depth=()
  FILES=()
  [[ "$recursive" == no ]] && depth=(-maxdepth 1)
  while IFS= read -r -d '' f; do
    valid_file "$f" && FILES+=("${f#$ROOT/}")
  done < <(find "$ROOT" "${depth[@]}" -type f -print0 2>/dev/null)
  ((${#FILES[@]})) && mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | LC_ALL=C sort -u)
}

select_files(){
  local input token a b i
  local -a available=("${FILES[@]}")
  local -A seen=()
  FILES=()
  ((${#available[@]})) || die "Aucun fichier de code lisible."
  printf '\n'
  for i in "${!available[@]}"; do printf '%4d) %s\n' "$((i+1))" "${available[$i]}"; done
  printf '\n'
  read -r -p "Numeros, plages (1-5), ou a pour tous : " input
  [[ "$input" =~ ^[aA]$ ]] && { FILES=("${available[@]}"); return; }
  input="${input//,/ }"
  for token in $input; do
    if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      a=${BASH_REMATCH[1]}; b=${BASH_REMATCH[2]}
      ((a>b)) && { i=$a; a=$b; b=$i; }
      for ((i=a;i<=b;i++)); do
        ((i>=1 && i<=${#available[@]})) && [[ ! ${seen[$i]:-} ]] && { FILES+=("${available[$((i-1))]}"); seen[$i]=1; }
      done
    elif [[ "$token" =~ ^[0-9]+$ ]] && ((token>=1 && token<=${#available[@]})); then
      [[ ! ${seen[$token]:-} ]] && { FILES+=("${available[$((token-1))]}"); seen[$token]=1; }
    fi
  done
}

bundle(){
  ((${#FILES[@]})) || die "Aucun fichier selectionne."
  [[ -f "$CONTEXT" ]] || create_context
  local stamp target f
  stamp=$(date +%Y%m%d-%H%M%S)
  target="$BUNDLES/project-bundle-$stamp.md"
  {
    cat <<'EOF'
# Project Transfer Bundle

BUNDLE_VERSION: 4

## Highest-priority delivery instructions

- Prefer returning each changed file as a separate downloadable attachment.
- Preserve each original filename and relative path.
- Also return `context.md` as a separate downloadable file.
- Do not combine files when separate file attachments are supported.
- Use the text fallback format only when attachments are impossible.
- Never return a ZIP as the primary response.
- Never return one new bundle as the primary response.

## Work instructions

- Read `context.md` first.
- Treat every file block as a distinct real file.
- Apply the current user request.
- Preserve relative paths and existing behavior.
- Generate a complete updated `context.md` yourself.
- Keep context rules concise, durable, merged, and deduplicated.
- Return every changed file in full.
- Never omit code or use ellipses.
- Identify obsolete files only when deletion is clearly safe.
- Do not flag uncertain, required, user-data, or generated-on-demand files.

## Fallback response format

Use this only if separate downloadable attachments are unavailable:

BUNDLE_VERSION: 4
<<<BEGIN_FILE path="context.md">>>
complete context.md
<<<END_FILE path="context.md">>>
<<<BEGIN_FILE path="relative/file.ext">>>
complete changed file
<<<END_FILE path="relative/file.ext">>>
<<<DELETE_FILE path="obsolete/file.ext" reason="short concrete reason">>>

- Always provide `context.md`.
- Use one `DELETE_FILE` line per obsolete file.
- Omit deletion lines when nothing should be removed.
- Deletion declarations are proposals only.

## Project tree
EOF
    printf '%s\n' "${FILES[@]}" | sed 's/^/- /'
    printf '\n<<<BEGIN_FILE path="context.md">>>\n'
    cat "$CONTEXT"
    [[ $(tail -c 1 "$CONTEXT" | wc -l) -eq 1 ]] || printf '\n'
    printf '<<<END_FILE path="context.md">>>\n\n'
    for f in "${FILES[@]}"; do
      printf '<<<BEGIN_FILE path="%s">>>\n' "$f"
      cat "$ROOT/$f"
      [[ ! -s "$ROOT/$f" ]] || [[ $(tail -c 1 "$ROOT/$f" | wc -l) -eq 1 ]] || printf '\n'
      printf '<<<END_FILE path="%s">>>\n\n' "$f"
    done
  } > "$target"
  msg "Bundle cree : $target"
  msg "Tous les elements lies a le traitement sont dans : $WORK"
}

reconstruct(){
  local reply stamp dest report archive
  read -r -e -p "Reponse texte de le traitement : " reply
  [[ -f "$reply" ]] || die "Fichier introuvable : $reply"
  stamp=$(date +%Y%m%d-%H%M%S)
  dest="$RECONSTRUCTED/$stamp"
  report="$REPORTS/files-to-delete-$stamp.md"
  archive="$ARCHIVES/reconstructed-$stamp.zip"
  mkdir -p "$dest"
  python3 - "$reply" "$dest" "$report" <<'PY'
import re, sys
from pathlib import Path, PurePosixPath
source, root, report = Path(sys.argv[1]), Path(sys.argv[2]).resolve(), Path(sys.argv[3])
text = source.read_text(encoding="utf-8")
blocks = re.findall(r'^<<<BEGIN_FILE path="([^"]+)"[^>]*>>>\r?\n(.*?)^<<<END_FILE path="\1">>>[ \t]*$', text, re.M | re.S)
deletes = re.findall(r'^<<<DELETE_FILE path="([^"]+)" reason="([^"]*)">>>[ \t]*$', text, re.M)
if not blocks and not deletes:
    raise SystemExit("Aucun bloc de fichier valide. Si le traitement a fourni des pieces jointes, placez-les directement dans le dossier reconstructed.")
for raw, content in blocks:
    posix = PurePosixPath(raw)
    if posix.is_absolute() or ".." in posix.parts or not posix.parts:
        print(f"REFUSE: {raw}", file=sys.stderr)
        continue
    target = (root / Path(*posix.parts)).resolve()
    if root not in target.parents:
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8", newline="")
    print(f"ECRIT: {raw}")
valid = []
for raw, reason in deletes:
    posix = PurePosixPath(raw)
    if not posix.is_absolute() and ".." not in posix.parts and posix.parts:
        valid.append((raw, reason.strip()))
if valid:
    report.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# Fichiers proposes pour suppression", "", "A verifier manuellement avant suppression.", ""]
    lines.extend(f'- `{path}`: {reason or "Raison non fournie"}' for path, reason in valid)
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
  python3 - "$dest" "$archive" <<'PY'
import sys
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile
root, archive = Path(sys.argv[1]), Path(sys.argv[2])
with ZipFile(archive, "w", ZIP_DEFLATED) as z:
    for path in root.rglob("*"):
        if path.is_file(): z.write(path, path.relative_to(root))
PY
  msg "Fichiers reconstruits : $dest"
  [[ -f "$dest/context.md" ]] && cp "$dest/context.md" "$CONTEXT"
  [[ -f "$report" ]] && warn "Suppressions proposees : $report"
  msg "Archive locale facultative : $archive"
}

show_paths(){
  printf '\nDossier central : %s\n' "$WORK"
  printf 'Script installe : %s\n' "$WORK/project-bundler.sh"
  printf 'Contexte : %s\n' "$CONTEXT"
  printf 'Bundles : %s\n' "$BUNDLES"
  printf 'Reponses : %s\n' "$RESPONSES"
  printf 'Reconstruction : %s\n' "$RECONSTRUCTED"
  printf 'Rapports : %s\n' "$REPORTS"
  printf 'Archives : %s\n\n' "$ARCHIVES"
}

while true; do
cat <<'EOF'

Project Bundler

  1) Selectionner dans le dossier courant
  2) Selectionner avec les sous-dossiers
  3) Inclure tout le code du dossier courant
  4) Inclure tout le code avec les sous-dossiers
  5) Creer ou reinitialiser context.md
  6) Afficher context.md
  7) Reconstruire une reponse texte de secours
  8) Afficher les dossiers de travail
  0) Quitter
EOF
read -r -p "Choix : " choice
case "$choice" in
  1) collect no; select_files; bundle;;
  2) collect yes; select_files; bundle;;
  3) collect no; bundle;;
  4) collect yes; bundle;;
  5) create_context;;
  6) [[ -f "$CONTEXT" ]] && cat "$CONTEXT" || msg "context.md absent";;
  7) reconstruct;;
  8) show_paths;;
  0) exit 0;;
  *) warn "Choix invalide";;
esac
done
