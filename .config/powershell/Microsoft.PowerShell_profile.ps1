# See https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/
# and http://stackoverflow.com/a/4167071
# for why this works.
function config {
	/usr/bin/git --git-dir=$home/.cfg --work-tree=$home $args
}

# Configure aliases to point to built-in cmdlets over native commands.
# We use -ErrorAction Ignore to deal with the case where these
# aliases may already be defined.
New-Alias -Name "ls" -Value Get-ChildItem -ErrorAction Ignore
New-Alias -Name "mv" -Value Move-Item -ErrorAction Ignore
New-Alias -Name "rm" -Value Remove-Item -ErrorAction Ignore
New-Alias -Name "rmdir" -Value Remove-Item -ErrorAction Ignore

# which is a bit more complicated...
# In particular, Get-Command is very powerful, but
# we often want something quick, as the less powerful
# native command `which` gives us.
function which {
    param(
        [string] $name
    )

    $cmd = Get-Command $name -ErrorAction Ignore
    if (-not $cmd) {
        return
    } else {
        switch ($cmd.CommandType) {
            "Alias" {
                return "{0} -> {1}" -f $cmd.Name, $cmd.Definition
            }

            "Application" {
                return $cmd.Path
            }

            "Function" {
                return "function {0}" -f $cmd.Name
            }

            default {
                return $cmd
            }

        }
    }
}