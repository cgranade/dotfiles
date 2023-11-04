export def "with flag" [
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

export def "config" [] {
    # TODO: set location for windows too
    let config_path = "~/.config/repos/repos.yaml" | path expand
    if ($config_path | path exists) {
        open $config_path
    } else {
        {}
    }
}

export def "retry" [
    times: int
    task: closure
    on_failure?: closure
] {
    mut n = 0
    mut succeeded = false
    while ($n < $times) and (not $succeeded) {
        
        $succeeded = $env.LAST_EXIT_CODE == 0
        $n += 1
        if (not $succeeded) and ($on_failure != null) {
            $n | do $on_failure
        }
    }
}
