#!/bin/bash

tmux set-buffer -b oob "ip netns exec oob_ns bash"
tmux set-buffer -b ib  "ip netns exec vrfns_default bash"
tmux set-buffer -b debug $"set follow-fork-mode child\nrun"

