#! /usr/bin/env python

import os
import sys
import json
import shutil


# Process the command-line arguments
if (len(sys.argv) != 2) and (len(sys.argv) != 3):
    print "Usage: %s <data_file> <output_folder>" % sys.argv[0]
    print
    sys.exit(-1)

data_file = sys.argv[1]

if len(sys.argv) == 3:
    dest = sys.argv[2]
else:
    dest = './html'

dest = os.path.abspath(dest)


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


# Open the data file and convert its content to JSON
input_file = open(data_file, 'r')
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

entries_stringified = ''.join(processed_lines)
entries = json.loads(entries_stringified)


# Retrieves a sorted list of all the timestamps in the data file, without missing days
first_day = None
last_day = None
for name, details in entries.items():
    if first_day is not None:
        last_day = max(last_day, details['last'])
        first_day = min(first_day, min(map(lambda x: int(x), filter(lambda x: (x != u'last') and (x != u'class'), details.keys()))))
    else:
        last_day = details['last']
        first_day = min(map(lambda x: int(x), filter(lambda x: (x != u'last') and (x != u'class'), details.keys())))

timestamps = range(first_day, last_day + 1, 3600 * 24)


# Retrieves a sorted list of all the characters in the data file
names = entries.keys()
names.sort()


# Generate the HTML page
if os.path.exists(dest):
    shutil.rmtree(dest)

shutil.copytree(os.path.join(os.path.dirname(sys.argv[0]), 'templates'), dest)

input_file = open(os.path.join(dest, 'index.html'), 'r')
content = input_file.read()
input_file.close()

content = content.replace('$ENTRIES$', entries_stringified). \
                  replace('$TIMETAMPS$', str(timestamps)).   \
                  replace('$CHARACTER_NAMES$', str(map(lambda x: str(x), names))). \
                  replace('$CHARACTERS_TO_IGNORE$', str(CHARACTERS_TO_IGNORE)). \
                  replace('$CHARACTERS_COLORS$', str(CHARACTERS_COLORS))

output_file = open(os.path.join(dest, 'index.html'), 'w')
output_file.write(content)
output_file.close()
