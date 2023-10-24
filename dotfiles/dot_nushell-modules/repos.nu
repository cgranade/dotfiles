use "./gh.nu"
export use "./utils.nu" [config]


# TODO: Set up config file instead of random env vars.
export def "path" [
    kind?: string
] {
    let config_base = config | get -i path
    let base = if $config_base != null { $config_base } else { "~/repos" }
        | path expand
    if $kind == null { 
        $base
    } else {
        $base | path join $kind
    }
}

export def "clone all gh" [
    name?: string
    --limit: int = 30
    --dry-run
] {
    let repos_to_backup = gh repo list (if $name == null {""} else {$name}) --limit $limit;
    $repos_to_backup
    | each {|r|
          let r_name = $"($r.owner)/($r.name)"
          let r_path = repos path gh
              | path join $r_name
          if ($r_path | path exists) {
              {repo: $r_name status: "Path exists, no clone needed."}
          } else {
              if $dry_run {
                  {repo: $r_name status: $"Would run `gh repo clone ($r_name) ($r_path)`" }
              } else {
                  let result = gh repo clone $r_name $r_path
                      | complete
                  {repo: $r_name exit_code: $result.exit_code}
              }
          }
      }
}

export def "push all backups for" [
    kind: string
    --limit: int = 200
] {
    let repos_to_backup = ls -f (repos path $kind)
        | where type == dir
        | each {|i| ls -f $i.name | where type == dir}
        | flatten
        | get name
        | take $limit
    for $repo in $repos_to_backup {
        let pwd = $env.PWD
        cd $repo
            print $"Entering ($repo)..."
            let remotes = git remote -v
                | lines
                | each {|i|
                    let row = $i | split row -r '\s+'
                    {name: $row.0 url: $row.1 mode: ($row.2?)}
                }
            if ("backup" in $remotes.name) and ("origin" in $remotes.name) {
                git fetch origin
                git push --mirror backup
            } else {
                print "Skipping, as repo is missing either backup or origin."
            }
        cd $pwd
    }
}
