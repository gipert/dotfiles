function borg-backup() {
    local repo="ge28fok@sator.e15.ph.tum.de:~/.backups/$(hostname)"

    # TODO: periodic message

    # borg init --encryption repokey ${repo}

    borg create \
        --stats \
        --progress \
        --compression lz4 \
        --patterns-from ~/.zsh/backup-patterns.lst \
        $@ \
        ${repo}::{user}-{hostname}-{now}
}
