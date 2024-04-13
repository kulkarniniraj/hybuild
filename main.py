import hy 
import sys
from icecream import ic
from pathlib import Path
import yaml
import os
import fire
import sh

STATE = {}

def _quote_rule(string):
    with open('Makefile', 'a') as f:
        f.write(string)
        f.write('\n')

def QUOTE_RULE(string):
    return _quote_rule(string)

def _rule(target, deps, recipes, phony):
    def _stringify_token(val: str):
        if isinstance(val, list):
            return ' '.join(val)
        else:
            return str(val)
        
    def _process_token(tok: str):
        if tok.startswith('$'):
            val = _get(tok.lstrip('$'))
            return _stringify_token(val)
        else:
            return str(tok)

    def _process_one_recipe(rule):
        if isinstance(rule, str):
            return rule.strip()
        else:
            return ' '.join([_process_token(tok) for tok in rule])
    
    lines = []
    if phony is True:
        lines.append(f'.PHONY: {target}')
    lines.append(f'{target}: {" ".join(deps)}')
    for rec in recipes:
        lines.append(f'\t{_process_one_recipe(rec)}')
    with open('Makefile', 'a') as f:
        for line in lines:
            f.write(f'{line}\n')
        f.write('\n')

def RULE(target, deps = [], recipes = [], phony = False):
    return _rule(target, deps, recipes, phony)

def _set(var, val):
    STATE[var] = val

def SET(var, val):
    return _set(var, val)

def _get(var):
    return STATE.get(var, None)

def GET(var):
    return _get(var)

def _get_str(var):
    return str(STATE.get(var, ''))

def GET_STR(var):
    return _get_str(var)

def _is_set(var):
    return var in STATE

def IS_SET(var):
    return _is_set(var)

def IS_NOT_SET(var):
    return not _is_set(var)

def _run(cmd):
    return sh.bash('-c', cmd)

def RUN(cmd: str):
    return _run(cmd)

def RUN_SAFE(cmd: str):
    try:
        return _run(cmd)
    except:
        return ''
    
def main(spec_file):
    target = Path(spec_file)
    with open('Makefile', 'w') as f:
        pass

    with open(target) as f:
        stream = hy.read_many(f)
        for expr in stream:
            hy.eval(expr)

if __name__ == '__main__':
    fire.Fire(main)