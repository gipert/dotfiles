prompt_singularity_venv() {
    if [[ -n "$CENV_NAME" ]]; then
        p10k segment -i 'ﱾ' -t "$CENV_NAME"
    elif [[ -n "$APPTAINER_CONTAINER" ]]; then
        local name=$(readlink "$APPTAINER_CONTAINER")
        name=$(basename "$name")
        p10k segment -i 'ﱾ' -t "$name"
    fi
}

# vim: syntax=sh
