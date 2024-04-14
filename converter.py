#!/usr/bin/env python
# coding: utf-8
from enum import Enum, auto
from collections import namedtuple
import fire


class LineType(Enum):
    Rule = auto()
    Recipe = auto()
    Other = auto()
    
class GroupType(Enum):
    Rule = auto()
    Other = auto()

Line = namedtuple('Line', 'type data')
Group = namedtuple('Group', 'type lines')

def process_quote(group):
    string = '(QUOTE-RULE #[[\n'
    for line in group.lines:
        string = string + line.data + '\n'
    string += ']])'
    return string

def process_rule(group):
    def _get_target(group):
        return group.lines[0].data.split(':', 1)[0]

    def _get_deps(group):
        deps = group.lines[0].data.split(':', 1)[1]
        return deps.split()

    def _get_recipes(group):
        return [x.data.strip() for x in group.lines[1:]]
    
    def _process_deps(deps):
        return ' '.join([f'"{x}"' for x in deps])

    def _process_recipes(rlist):
        return '\n'.join([f'\t\t"{x}"' for x in rlist])
    
    string_tmpl = '(RULE\n\t:target "{target}"\n\t:deps [{deps}]\n\t:recipes [\n{recipes}])'
    return string_tmpl.format(target = _get_target(group), 
                             deps = _process_deps(_get_deps(group)), 
                             recipes = _process_recipes(_get_recipes(group)))

def process_group(group: Group):
    if group.type == GroupType.Other:
        return process_quote(group)
    else:
        return process_rule(group)

def parse_lines(lines):
    type_lines = []
    for line in lines:
        if line.startswith('\t'):
            new_line = Line(type = LineType.Recipe, data = line)
        elif (':' in line) and ('=' not in line) and (line.strip()[0] != '#'):
            new_line = Line(type = LineType.Rule, data = line)
        elif line.strip() == '':
            continue
        else:
            new_line = Line(type = LineType.Other, data = line)
            
        type_lines.append(new_line)
    return type_lines

def parse_groups(type_lines):
    mode = GroupType.Other
    groups = []
    cur_group = []
    for line in type_lines:
        if mode == GroupType.Other:
            if line.type in (LineType.Other, LineType.Recipe):
                cur_group.append(line)
            else:
                groups.append(Group(type = GroupType.Other, lines = cur_group))
                cur_group = [line]
                mode = GroupType.Rule
        elif mode == GroupType.Rule:
            if line.type == LineType.Recipe:
                cur_group.append(line)
            elif line.type == LineType.Rule:
                groups.append(Group(type = GroupType.Rule, lines = cur_group))
                cur_group = [line]
            else:
                groups.append(Group(type = GroupType.Rule, lines = cur_group))
                cur_group = [line]
                mode = GroupType.Other

    if cur_group != []:
        groups.append(Group(type = mode, lines = cur_group))
    
    return groups

def main(input_makefile, output_build_file):    
    with open(input_makefile) as f:
        data = f.read()

    lines = data.split('\n')

    type_lines = parse_lines(lines)
    
    groups = parse_groups(type_lines)    

    with open(output_build_file, 'w') as f:
        for g in groups:
            f.write(process_group(g))
            f.write('\n\n')

if __name__ == '__main__':
    fire.Fire(main)