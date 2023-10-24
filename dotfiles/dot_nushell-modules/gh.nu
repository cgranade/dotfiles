use "./utils.nu" *

export def "repo list" [
    --all
    --archived
    --fork
    --language (-l): string
    --limit (-L): int
    --no-archived
    --source
    --template (-t): string
    --topic: string
    --visibility: string
    ...rest
] {
    let flags = []
        | with flag archived $archived
        | with flag fork $fork
        | with flag language $language
        | with flag no-archived $no_archived
        | with flag source $source
        | with flag template $template
        | with flag topic $topic
        | with flag visibility $visibility

    mut fields = []
    if $all {
        # Get a list of fields.
        $fields = (do { ^gh repo list --json }
            | complete
            | get stderr
            | lines
            | skip 1
            | each {|i| $i | str trim})
    } else {
        $fields = [
            "name"
            "owner"
            "description"
            "visibility"
            "pushedAt"
        ]
    }
    let result = ^gh repo list $flags --json ($fields | str join ",") $rest
        | from json
        | upsert owner {|o| $o.owner.login}
        | upsert pushedAt {|p| $p.pushedAt | into datetime}
        | move name --before description
        | move owner --before name
        | move visibility --after description

    $result
}
