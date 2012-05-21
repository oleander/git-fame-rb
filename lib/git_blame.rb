require "git_blame/version"
require "progressbar"
require "mimer_plus"
require "hirb"
require "action_view"
require "git_blame/author"
require "git_blame/base"

# Suppress warnings produced by hirb
output = $-v
$-v = false

$-v = output