This is a client side minetest mod.


* highlights a message if you are mentioned in it,
* every player gets a different colour (near to white),
* you can give players different chat priorities:
stark-hide: completely ignore every message emanating from the player
hide: if you are mentioned, mark it as usual, else print the message black in terminal
dark-grey: print it dark-grey in terminal and chat (except mentions)
grey: like dark-grey but brighter
default: like dark-grey but the player's colour
important: show every message as if you were mentioned
nil: remove the player from the list of specified priorities
* You can also change which priority is given when not explicitly specified using the ```chatcolour``` chatcommand.
* Of course, tab autocompletion is available that you don't have to type so much (I need to make https://github.com/minetest/minetest/pull/4437 client side)

TODO:
* tab autocompletion