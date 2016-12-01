# See https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/
# and http://stackoverflow.com/a/4167071
# for why this works.
function config {
	/usr/bin/git --git-dir=$home/.cfg --work-tree=$home $args
}
