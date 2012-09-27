# TitanPlayed

Played time recording add-on for *World of Warcraft*, with out-of-game visualization script.
It keeps a record of your total playing time for each day, for each of your characters.


## Add-on

The add-on is located in the *TitanPlayed/* folder

### Requirements

This add-on requires [TitanPanel](http://www.titanpanel.org/) .

### What does it do?

The add-on will appear as a right-only icon on the Titan bar of your choice. When the
mouse is over this icon, a tooltip showing the */played* time of all your characters
will be shown.

The */played* time of the current character will be recorded:

* on log in
* on log out
* each time the tooltip is displayed
* each time the */played* command is executed
* before each loading screen

**Note**: Only one */played* time is recorded for each day for each character

### Installation

Copy the folder *TitanPlayed/* into the *Interface/AddOns/* subfolder of your
*World of Warcraft* instance.


## Visualization script

The *scripts/* folder contains the various visualization scripts available.

### File format

The data saved by the TitanPlayed is located at
*WTF/Account/<your_account_name>/SavedVariables/TitanPlayed.lua*

Here is an example of such file (from the file *scripts/example.lua*):

`TitanPlayedTimes = {
	["Bob"] = {
		[1348012800] = 439874,
		[1348444800] = 441001,
		["last"] = 1348444800,
		["class"] = "HUNTER",
	},
	["John"] = {
		[1348012800] = 339784,
		[1348185600] = 345900,
		[1348272000] = 349877,
		[1348358400] = 353909,
		[1348444800] = 355062,
		["last"] = 1348444800,
		["class"] = "WARRIOR",
	},
}`

Here we have two characters (Bob, a hunter, and John, a warrior). Bob played on two
different days (represented by the number of seconds since 0 hours, 0 minutes, 0 seconds,
January 1, 1970, Coordinated Universal Time): 1348012800 (2012/9/19) and 1348444800
(2012/9/24).

On 2012/9/19, the */played* time of Bob was 439874 (seconds) and on 2012/9/24 it was
440001. Therefore, Bob played 441001 - 439874 = 1127 seconds = 18 minutes and 47 seconds
on 2012/9/24.

For convenience, the *last* entry indicates which day is the last one.

### plot-html.py

Usage: `./plot-html.py <your_data_file> [<dest_folder>]`

The default value for *dest_folder* is `./html`.

It will produce a web page in *dest_folder* (complete with CSS and JavaScript files)
displaying various interactive graphs:

* your activity per character
* your activity per day
* your percentage time played with each character for various periods

![Activity per character](https://raw.github.com/Kanma/TitanPlayed/master/images/html1.png)

![Activity per day](https://raw.github.com/Kanma/TitanPlayed/master/images/html2.png)

![Activity per day](https://raw.github.com/Kanma/TitanPlayed/master/images/html3.png)

If you want to ignore some characters, or to change their colors, you can copy the file
*settings_example.py* (your copy must be called *settings.py* and be located alongside
the *plot-html.py* script) and modify it to your liking.

You can customize the generated HTML page by modifying the template located at:
*scripts/templates/index.html*.


### plot-stats.py

**Note**: This script requires *matplotlib* and *numpy*

Usage: `./plot-stats.py <your_data_file>`

It will produce an image (*stats-played.png*) containing a graph showing your activity per
character:

![Example graph](https://raw.github.com/Kanma/TitanPlayed/master/images/stats-played.png)

If you want to ignore some characters, or to change their colors, you can copy the file
*settings_example.py* (your copy must be called *settings.py* and be located alongside
the *plot-stats.py* script) and modify it to your liking.


## License

TitanPlayed is is made available under the MIT License. The text of the license is in the
file 'LICENSE'.

Under the MIT License you may use TitanPlayed for any purpose you wish, without warranty,
and modify it if you require, subject to one condition:

>   "The above copyright notice and this permission notice shall be included in
>   all copies or substantial portions of the Software."

In practice this means that whenever you distribute your application, whether as binary
or as source code, you must include somewhere in your distribution the text in the file
'LICENSE'. This might be in the printed documentation, as a file on delivered media, or
even on the credits / acknowledgements of the runtime application itself; any of those
would satisfy the requirement.

Even if the license doesn't require it, please consider to contribute your modifications
back to the community.
