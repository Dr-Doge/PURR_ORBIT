from pathlib import Path
script = Path(__file__).with_name('build_plan.py').read_text(encoding='utf-8')
script = script.replace('v0.1.md', 'v0.2_精简版.md').replace('v0.1.docx', 'v0.2_精简版.docx').replace('v0.1  ·', 'v0.2  ·')
script = script.replace("font.size = Pt(10.5)", "font.size = Pt(11)")
script = script.replace("line_spacing = Pt(15.8)", "line_spacing = Pt(17)")
exec(compile(script, str(Path(__file__).with_name('build_plan.py')), 'exec'))
