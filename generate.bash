#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

DIRECTORY="$1"

export COMPANY="${COMPANY:-ACME CORPORATION}"
export DISCLAIMER="${DISCLAIMER:-This document is for internal use only.}"
export WATERMARK="${WATERMARK:-Official Copy}"
export WEBSITE_BASE_DIR="${WEBSITE_BASE_DIR:-/}"
export LOGO_PATH="${LOGO_PATH:-}"

DEST="$PWD/logo.png"

if [ -z "$LOGO_PATH" ]; then
    company_slug=$(printf '%s' "${COMPANY:-ACME CORPORATION}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//')
    for candidate in \
        "$DIRECTORY/logo.png" \
        "$DIRECTORY/logo.svg" \
        "./logo.png" \
        "./logo.svg" \
        "./${company_slug}.png" \
        "./${company_slug}.svg" \
        "./logos/${company_slug}.png" \
        "./logos/${company_slug}.svg" \
        "./assets/${company_slug}.png" \
        "./assets/${company_slug}.svg" \
        "./app/assets/${company_slug}.png" \
        "./app/assets/${company_slug}.svg"; do
        if [ -f "$candidate" ]; then
            LOGO_PATH="$candidate"
            break
        fi
    done
fi

if [ -n "$LOGO_PATH" ] && [ -f "$LOGO_PATH" ]; then
    if [ "$LOGO_PATH" != "$DEST" ]; then
        rm -f "$DEST" >/dev/null 2>&1 || true
        cp --remove-destination "$LOGO_PATH" "$DEST"
    fi
    trap 'rm -f "$DEST"' EXIT
fi

if [ -n "$SCCS_BASE_URL" ]; then
    SCCS_BASE_URL="${SCCS_BASE_URL%/}/"
    case "$SCCS_BASE_URL" in
        */commit/) ;;
        */commit/*) ;;
        *) SCCS_BASE_URL="${SCCS_BASE_URL}commit/" ;;
    esac
fi

# Rhetorical Question: Why is 0 true and 1 false in bash? 🤦‍♂️
function check_git() {
    if ! command -v git &>/dev/null; then
        echo "Git command not found. WARN: Skipping advanced features."
        return 1
    fi

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        return 0
    fi

    # At runtime inside a container, the mounted repo may not be auto-detected.
    # This fallback belongs here in the runtime script, not in the Dockerfile.
    # We try the GH Actions workspace first, then the current working directory.
    if [ -n "${GITHUB_WORKSPACE:-}" ] && [ -d "$GITHUB_WORKSPACE/.git" ]; then
        if git --git-dir="$GITHUB_WORKSPACE/.git" --work-tree="$GITHUB_WORKSPACE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            export GIT_DIR="$GITHUB_WORKSPACE/.git"
            export GIT_WORK_TREE="$GITHUB_WORKSPACE"
            return 0
        fi
    fi

    if [ -n "${PWD:-}" ] && [ -d "$PWD/.git" ]; then
        if git --git-dir="$PWD/.git" --work-tree="$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            export GIT_DIR="$PWD/.git"
            export GIT_WORK_TREE="$PWD"
            return 0
        fi
    fi

    echo "Not inside a Git repository. WARN: Skipping advanced features."
    return 1
}

function utc_date_from_epoch() {
    local epoch="$1"
    if date -u -r "$epoch" +"%Y-%m-%d %H:%M:%S" >/dev/null 2>&1; then
        date -u -r "$epoch" +"%Y-%m-%d %H:%M:%S"
    elif date -u -d "@${epoch}" +"%Y-%m-%d %H:%M:%S" >/dev/null 2>&1; then
        date -u -d "@${epoch}" +"%Y-%m-%d %H:%M:%S"
    else
        echo "$epoch"
    fi
}

function generate_changelog() {
    # NOTE: git log --follow is unreliable across file renames/moves, especially
    # when combined with merge history. This script currently tracks history
    # only by path and does not guarantee a complete pre-move history traversal.
    #
    # If a document is moved, older commits may not appear in the generated
    # changelog or signature history.
    if ! check_git; then
        return
    fi

    local md_file="$1"
    local changelog="## Changelog\n"
    changelog+="|Version|Date|Author|Message|\n"
    changelog+="|---|---|---|---------|\n"

    if [ "${VERSIONING_STYLE:-auto}" = 'tagged' ]; then
        changelog+="$(git log --first-parent --merges -m \
            --pretty=tformat:"|[%(describe:tags,abbrev=0)]($SCCS_BASE_URL%h)|%as|%an|%s|" \
            -- "$md_file")"
    else
        changelog+="$(git log --reverse --first-parent --merges -m --pretty=format:'%h%x1f%as%x1f%an%x1f%s' -- "$md_file" | \
            awk -v base="$SCCS_BASE_URL" -F '\x1f' '{
                label=sprintf("V%03d", NR)
                if (base != "") {
                    printf("|[%s](%s%s)|%s|%s|%s|\n", label, base, $1, $2, $3, $4)
                } else {
                    printf("|%s|%s|%s|%s|\n", label, $2, $3, $4)
                }
            }')"
    fi

    echo -e "$changelog"
}

function generate_signature_log() {
    if ! check_git; then
        return
    fi

    local md_file="$1"

    merge_history=$(git log --reverse --first-parent --merges -m --pretty=format:"%h" -- "$md_file")

    if [ -n "$merge_history" ]; then
        signature_log="## Electronic Signatures\n"
        signature_log+="|Time (UTC)|Signature ID|Actor|Reason|\n"
        signature_log+="|----|-----|---|---|"

        local signature_index=0
        for merge_commit in $merge_history; do
            signature_index=$((signature_index + 1))
            change_commit=$(git log --pretty=format:'%h' --no-merges "${merge_commit}^2" -- "$md_file" | head -n 1)
            if [ -z "$change_commit" ]; then
                change_commit="$merge_commit"
            fi

            local author_date
            author_date="\`$(utc_date_from_epoch "$(git show -s --format=%at "$change_commit")")\`"
            local approval_date
            approval_date="\`$(utc_date_from_epoch "$(git show -s --format=%ct "$merge_commit")")\`"

            local tag_name
            tag_name=$(git tag --points-at "$merge_commit" --list 'V[0-9]*' | sort -V | tail -n 1)
            if [ -z "$tag_name" ]; then
                if [ "${VERSIONING_STYLE:-auto}" = 'auto' ]; then
                    tag_name=$(printf 'V%03d' "$signature_index")
                else
                    tag_name=$(git rev-parse --short "$merge_commit" 2>/dev/null || echo "UNKNOWN")
                fi
            fi

            local author_line
            author_line=$(git show --no-patch --format="|%GK %GS|%an|Author ${tag_name}|" "$change_commit")
            local approval_line
            approval_line=$(git show --no-patch --format="|%GK %GS|%an|Approval ${tag_name}|" "$merge_commit")

            signature_log+="\n|${approval_date}${approval_line}"
            signature_log+="\n|${author_date}${author_line}"
        done

        echo -e "$signature_log"
    else
        echo "No merge commits found for $md_file so electronic signatures are not generated."
    fi
}

function detect_versioning_style() {
    export VERSIONING_STYLE='auto'

    if ! check_git; then
        return
    fi

    if git tag --list 'V[0-9]*' | grep -q .; then
        export VERSIONING_STYLE='tagged'
    fi
}

function resolve_version_tag() {
    local md_file="$1"

    if [ "${VERSIONING_STYLE:-auto}" = 'auto' ]; then
        if ! check_git; then
            export VERSION='UNTAGGED'
            return
        fi

        local revision_count
        revision_count=$(git log --follow --oneline -- "$md_file" 2>/dev/null | wc -l | tr -d ' ')
        revision_count=${revision_count:-0}
        export VERSION=$(printf 'V%03d' "$revision_count")
        return
    fi

    if ! check_git; then
        return
    fi

    local commit
    commit=$(git log -n1 --format=%H -- "$md_file" 2>/dev/null || true)
    if [ -z "$commit" ]; then
        return
    fi

    local version_tag
    version_tag=$(git tag --points-at "$commit" --list 'V[0-9]*' | sort -V | tail -n 1)
    if [ -n "$version_tag" ]; then
        export VERSION="$version_tag"
        return
    fi

    echo "ERROR: repository contains explicit V... tags, so this document must also be version-tagged." >&2
    echo "       $md_file has no V... tag on its latest commit. Do not mix explicit tagging with auto versioning." >&2
    exit 1
}

function load_markdown_content() {
    local md_file="$1"
    combined_content=$(cat "$md_file" |
        sed "s|]:[[:space:]]*$WEBSITE_BASE_DIR|]:$WEBSITE_BASE_URL|g; s|\.md|\.pdf|g")
}

detect_versioning_style

find "$DIRECTORY" -type f -name "*.md" | while read -r md_file; do
    pdf_file="${md_file%.md}.pdf"

    TITLE=$(grep -m 1 '^# ' "$md_file" | sed 's/^# //')
    SUBTITLE=$(basename "$md_file" .md)

    echo "Processing title: $TITLE, subtitle: $SUBTITLE"

    ### VERSIONS ###
    VERSION=''
    resolve_version_tag "$md_file"

    load_markdown_content "$md_file"

    ### CHANGELOG ##
    change_log=$(generate_changelog "$md_file")
    combined_content+="\n\n$change_log"

    ### ELECTRONIC SIGNATURES ###
    signature_log=$(generate_signature_log "$md_file")
    combined_content+="\n\n$signature_log"

    echo -e "$combined_content" | pandoc -o "$pdf_file" -f markdown_github \
        --number-sections --quiet --toc \
        --pdf-engine=xelatex \
        --include-in-header="$(dirname "$0")/header-template.latex" \
        -V title="$TITLE" \
        -V subtitle="$SUBTITLE" \
        -V author="$COMPANY" \
        -V linkcolor="url-color" \
        -V filecolor="black" \
        -V urlcolor="url-color" \
        -V documentclass="report" \
        -V geometry:"margin=1in" \
        -V mainfont="Inter" \
        -V fontsize="11pt"
done
