use "./keepassxc-cli.nu"
use "./utils.nu" [config]
use "./gh.nu"
use "./repos.nu"

export def "get instance secrets" [
    name: string
] {
    let config = config
    (
        keepassxc-cli show
        --all
        ($config.database)
        ($config.instances | get $name)
    )
}

export def-env "use instance" [
    name: string
] {
    let entry = get instance secrets $name
    $env.GITEA_USE_USER = $entry.attributes.UserName
    $env.GITEA_USE_URL = $entry.attributes.URL
    $env.GITEA_USE_APIKEY = ($entry.attributes | get "API Key")
}

def "common headers" [] {
    [
        "Accept" "application/json"
        "Authorization" $"token ($env.GITEA_USE_APIKEY)"
    ]
}

def "api endpoint" [name] {
    $"($env.GITEA_USE_URL)api/v1($name)"
}

export def "repo list" [name?: string] {
    let endpoint = if $name == null {
        "/user/repos"
    } else {
        $"/users/($name)/repos"
    }
    # TODO check if use instance has been run.
    http get -H (common headers) (api endpoint $endpoint)
}

export def "repo create" [
    name: string
    description: string # TODO make optional
] {
    # TODO add more params
    http post -H (common headers) -t application/json (api endpoint "/user/repos") { name: $name description: $description }
}

export def "create backup-remotes for" [
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
            if "backup" in $remotes.name {
                print "Remote exists, skipping."
            } else if not ("origin" in $remotes.name) {
                print "No origin, not backing up."
            } else {
                let origin = $remotes | where name == origin | where mode == "(fetch)" | get 0.url
                let backup_name = "backup-" + (
                    $origin
                    | str replace -a ":" "_cl_"
                    | str replace -a "/" "_sl_"
                    | str replace -a "." "_dot_"                
                )
                let new_repo = repo create $backup_name $"Backup of repo at ($origin)"
                git remote add backup ($new_repo.clone_url)
            }
        cd $pwd
    }
}
