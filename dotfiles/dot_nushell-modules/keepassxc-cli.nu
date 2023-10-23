def "with flag" [
    name: string
    value?: any
] {
    if ($value | describe) == "bool" and $value {
        $in
        | append $"--($name)"
    } else if ($value | describe) == "bool" and (not $value) {
        $in
    } else if ($value | describe) == "nothing" {
        $in
    } else {
        $in
        | append $"--($name) ($value)"
    }
}

export def "maybe apply" [
    cond: bool
    closure: closure
] {
    if $cond {
        $in | do $closure
    } else {
        $in
    }
}

export extern-wrapped "keepassxc-cli show" [
    --quiet (-q)
    --key-file (-k): string
    --no-password
    --yubikey (-y): string
    --totp (-t)
    --attributes (-a): string
    --show-protected (-s)
    --all
    --show-attachments
    database: string
    entry: string
    ...rest
] {
    let flags = []
        | with flag quiet $quiet
        | with flag key-file $key_file
        | with flag no-password $no_password
        | with flag yubikey $yubikey
        | with flag totp $totp
        | with flag attributes $attributes
        | with flag show-protected $show_protected
        | with flag all $all
        | with flag show-attachments $show_attachments

    let result = ^keepassxc-cli show $flags ($database | path expand) $entry
        | complete
    if $result.exit_code == 0 {
        let output = $result.stdout
            | lines
            | each {|i| $i | str trim}
            | where {|i| ($i | str length) > 0}
            | split list "Attachments:"
        let attributes = $output.0
            | each {|row|
                $row
                | split row ":"
                | each {|i| $i | str trim}
            }
            | reduce --fold {} {|it, acc|
                $acc
                | upsert $it.0 $it.1
            }
            | upsert Tags {|row|
                $row.Tags
                | split row ","
            }
        let attachments = if $output.1? == null {
            null
        } else {
            $output.1
            | each {|row|
                let parts = $row
                | split row "("
                | each {|i| $i | str trim}
                let size = $parts.1
                    | str trim -r -c ')'
                    | into filesize
                {name: $parts.0 size: $size}
            }                
        }

        {attributes: $attributes}
        | maybe apply ($attachments != null) {||
            $in | upsert attachments $attachments
        }
    } else {
        $result
    }
}
