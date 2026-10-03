"""Decode RouterOS export arguments without treating them as shell syntax."""
import re


def split(text):
    tokens, token = [], []
    quoted = False
    started = False
    index = 0
    escapes = {'a': '\a', 'b': '\b', 'f': '\f', 'n': '\n', 'r': '\r',
               't': '\t', 'v': '\v', '_': ' ', '\\': '\\', '"': '"', '$': '$', '?': '?'}
    while index < len(text):
        char = text[index]
        if char == '\\':
            index += 1
            if index >= len(text):
                raise ValueError('Incomplete RouterOS escape')
            char = text[index]
            if index + 1 < len(text) and re.fullmatch('[0-9A-Fa-f]{2}', text[index:index + 2]):
                token.append(chr(int(text[index:index + 2], 16)))
                index += 1
            elif char in escapes:
                token.append(escapes[char])
            else:
                raise ValueError(f'Unsupported RouterOS escape character code {ord(char)}')
            started = True
        elif char == '"':
            quoted = not quoted
            started = True
        elif char.isspace() and not quoted:
            if started:
                tokens.append(''.join(token))
                token, started = [], False
        else:
            token.append(char)
            started = True
        index += 1
    if quoted:
        raise ValueError('Unterminated RouterOS string')
    if started:
        tokens.append(''.join(token))
    return tokens


def parse_export(text):
    text = re.sub(r'\\\n[ \t]*', '', text)
    records, menu = [], ''
    for line in text.splitlines():
        if not line or line.startswith('#'):
            continue
        if line.startswith('/') and not re.search(r' (add|set) ', line):
            menu = line
            continue
        if not line.startswith('/'):
            line = menu + ' ' + line
        match = re.fullmatch(r'(/.+?) (add|set) (.*)', line)
        if not match:
            raise ValueError('Unsupported export syntax')
        path, operation, args = match.groups()
        record = {'path': path, 'operation': operation}
        if args.startswith('[ find '):
            selector, args = args[7:].split(' ] ', 1)
            record['selector'] = dict(token.split('=', 1) for token in split(selector))
        elif operation == 'set' and re.match(r'^\d+ ', args):
            number, args = args.split(' ', 1)
            record['number'] = int(number)
        elif operation == 'set' and not re.match(r'^\S+=', args):
            name, args = args.split(' ', 1)
            record['selector'] = {'name': name}
        values, unset, prefix = {}, [], ''
        for token in split(args):
            if token.startswith('!') and '=' not in token:
                key, value = token[1:], ''
                unset.append(key)
            else:
                key, value = token.split('=', 1) if '=' in token else (token, 'yes')
            if key.startswith('.'):
                if not prefix:
                    raise ValueError('Missing RouterOS property prefix')
                key = prefix + key
            elif '.' in key:
                prefix = key.rsplit('.', 1)[0]
            else:
                prefix = ''
            values[key] = value
        record['values'] = values
        if unset:
            record['unset'] = unset
        records.append(record)
    return records
