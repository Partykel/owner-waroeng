"""Offline smoke check for the self-contained design artifact; run from any cwd."""
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess
import tempfile


class PreviewParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.references = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.append(attrs['id'])
        if tag == 'use':
            self.references.append(attrs['href'].removeprefix('#'))
        if 'data-icon' in attrs:
            self.references.append(attrs['data-icon'])


source = Path(__file__).with_name('preview.html').read_text(encoding='utf-8')
parser = PreviewParser()
parser.feed(source)
assert not [key for key, n in Counter(parser.ids).items() if n > 1], 'Duplicate DOM ids'
assert set(parser.references) <= set(parser.ids), 'Missing icon symbols'
assert not re.search(r'(?:src|href)=[\"\']https?://', source), 'Preview must work offline'
assert (Path(__file__).parent / '../../assets/fonts/noto_sans/NotoSans.ttf').resolve().is_file()
script = source.split('<script>', 1)[1].split('</script>', 1)[0]
with tempfile.TemporaryDirectory() as temporary:
    path = Path(temporary) / 'preview.js'
    path.write_text(script, encoding='utf-8')
    subprocess.run(['node', '--check', str(path)], check=True)
print('PASS: unique ids, icon references, offline asset, JavaScript syntax')
