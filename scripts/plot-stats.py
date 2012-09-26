#! /usr/bin/env python

import sys
import json
import matplotlib
from datetime import date

matplotlib.use('agg')

import pylab
import numpy
import matplotlib
import matplotlib.dates


# Colors from http://www.wowwiki.com/Class_colors
CLASS_COLORS = {
    'DEATHKNIGHT':  '#C41F3B',
    'DRUID':        '#FF7D0A',
    'HUNTER':       '#ABD473',
    'MAGE':         '#69CCF0',
    'MONK':         '#558A84',
    'PALADIN':      '#F58CBA',
    'PRIEST':       '#FFFFFF',
    'ROGUE':        '#FFF569',
    'SHAMAN':       '#0070DE',
    'WARLOCK':      '#9482C9',
    'WARRIOR':      '#C79C6E',
}

DEFAULT_COLOR = '#808080'

BAR_WIDTH = 0.35


# Try to import the user's custom settings
CHARACTERS_TO_IGNORE = []
CHARACTERS_COLORS = {}
try:
    module = __import__('settings')

    if hasattr(module, 'CHARACTERS_TO_IGNORE'):
        CHARACTERS_TO_IGNORE = module.CHARACTERS_TO_IGNORE

    if hasattr(module, 'CHARACTERS_COLORS'):
        CHARACTERS_COLORS = module.CHARACTERS_COLORS
except:
    pass


# Open the data file and read it
input_file = open(sys.argv[1], 'r')
lines = filter(lambda x: len(x) > 0, map(lambda x: x.strip(), input_file.readlines()))
input_file.close()

processed_lines = []
for line in lines:
    if line == 'TitanPlayedTimes = {':
        line = '{'
    elif line.startswith('}'):
        if processed_lines[-1].endswith(','):
            processed_lines[-1] = processed_lines[-1][:-1]
    elif line.find('=') > 0:
        (name, value) = tuple(map(lambda x: x.strip(), line.split('=')))
        if value.startswith("'") and value.endswith("',"):
            value = '"' + value[1:-2] + '",'
        if name.startswith('["') and name.endswith('"]'):
            line = name[1:-1] + ': ' + value
        elif name.startswith('[') and name.endswith(']'):
            line = '"' + name[1:-1] + '": ' + value
    processed_lines.append(line)

entries = json.loads(''.join(processed_lines))


# Retrieves a sorted list of all the timestamps in the data file
timestamps = []
for name, details in entries.items():
    for timestamp in filter(lambda x: (x != u'last') and (x != u'class'), details.keys()):
        timestamps.append(int(timestamp))

timestamps = list(set(timestamps))
timestamps.sort()


# Retrieves a sorted list of all the characters in the data file
names = entries.keys()
names.sort()


# Initialize our figure
if hasattr(pylab.plt, 'subplot2grid'):
    ax = pylab.plt.subplot2grid((50,50), (0,0), colspan=45, rowspan=50)
else:
    pylab.figure()
    ax = pylab.subplot(1, 1.1, 1)

pylab.grid(True)


# Create the graph
old_y = [0] * (len(timestamps) - 1)
x = [date.fromtimestamp(timestamp) for timestamp in timestamps[1:] ]

for name in filter(lambda x: x not in CHARACTERS_TO_IGNORE, names):
    color = CHARACTERS_COLORS.get(name, CLASS_COLORS.get(entries[name]['class'], DEFAULT_COLOR))

    y = []
    previous_timestamp = None
    for index, timestamp in enumerate(timestamps):
        str_timestamp = unicode(timestamp)
        if entries[name].has_key(str_timestamp):
            if previous_timestamp is not None:
                y.append((entries[name][str_timestamp] - entries[name][previous_timestamp]) / 3600.)
                previous_timestamp = str_timestamp
            else:
                previous_timestamp = str_timestamp
                if index > 0:
                    y.append(0)
        elif index > 0:
            y.append(0)

    ax.bar(x, y, BAR_WIDTH, bottom=old_y, color=color, label=name)
    old_y = numpy.add(old_y, y)

pylab.legend(bbox_to_anchor=(1.05, 1), loc=2, borderaxespad=0., prop={'size':8})

ax.xaxis_date()

locator = matplotlib.dates.DayLocator(interval=2)
ax.xaxis.set_major_locator(locator)
ax.xaxis.set_major_formatter(matplotlib.dates.AutoDateFormatter(locator))

# Save the image
pylab.savefig('stats-played.png', dpi=200)
