export extern-wrapped "gh repo list" [...rest] {
    # Get a list of fields.
    let json_hint = do { ^gh repo list --json }
        | complete
        | get stderr
        | lines
        | skip 1
        | each {|i| $i | str trim}
        | str join ","
    ^gh repo list --json $json_hint $rest
        | from json
}
