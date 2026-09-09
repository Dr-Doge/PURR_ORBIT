from pathlib import Path
script = Path(__file__).with_name('render_pages.py').read_text(encoding='utf-8').replace("/'render'", "/'render_v02'")
exec(compile(script, str(Path(__file__).with_name('render_pages.py')), 'exec'))
