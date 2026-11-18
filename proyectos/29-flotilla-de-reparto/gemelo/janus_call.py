#!/usr/bin/env python3
# Runner genérico invocado por janus_bridge.pl
# Uso: python3 janus_call.py <modulo_o_ruta> <funcion> <json_args>
import json
import sys
import importlib
import importlib.util
import os


def load_module(modname):
    # si es ruta a .py
    if modname.endswith('.py') or '/' in modname or '\\' in modname:
        path = modname
        if not os.path.isabs(path):
            path = os.path.join(os.getcwd(), path)
        spec = importlib.util.spec_from_file_location('_janus_mod', path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    # si existe archivo local homónimo
    local = os.path.join(os.getcwd(), modname + '.py')
    if os.path.exists(local):
        return load_module(local)
    return importlib.import_module(modname)


def main():
    if len(sys.argv) < 3:
        print(json.dumps({'error': 'uso: janus_call.py modulo funcion [json_args]'}))
        return 1
    modname = sys.argv[1]
    funcname = sys.argv[2]
    raw = sys.argv[3] if len(sys.argv) > 3 else '[]'
    try:
        args = json.loads(raw)
    except Exception as e:
        print(json.dumps({'error': f'json invalido: {e}'}))
        return 1
    try:
        mod = load_module(modname)
    except Exception as e:
        print(json.dumps({'error': f'no se pudo cargar modulo {modname}: {e}'}))
        return 1
    fn = getattr(mod, funcname, None)
    if fn is None or not callable(fn):
        print(json.dumps({'error': f'funcion no encontrada: {modname}.{funcname}'}))
        return 1
    if isinstance(args, dict):
        pos, kw = [], args
    elif isinstance(args, list):
        pos, kw = args, {}
    else:
        pos, kw = [args], {}
    try:
        res = fn(*pos, **kw)
        print(json.dumps(res, ensure_ascii=False))
        return 0
    except Exception as e:
        print(json.dumps({'error': str(e), 'modulo': modname, 'funcion': funcname}))
        return 1


if __name__ == '__main__':
    sys.exit(main())
