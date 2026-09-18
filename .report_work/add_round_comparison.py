from pathlib import Path
from lxml import html, etree
import re

path = Path(r'C:/Users/ruohaojing/Desktop/爽开/地球盲盒考古/报告/GPT6_Astra综合报告_新版建模与游戏开发.html')
source = path.read_text(encoding='utf-8')
match = re.search(r'<section\b[^>]*\bid="s05"[^>]*>.*?</section>', source, re.S)
assert match, 'Section 05 not found'
section = html.fromstring(match.group())
assert not section.xpath('.//*[@id="s05-rounds"]'), 'Comparison already added'
block = html.fragment_fromstring('''
<div id="s05-rounds">
  <h3>相似需求的对话轮数：约8轮 → 约5轮</h3>
  <p class="claim"><strong>在“从零星的想法到拥有基础交互玩法的场景”这类需求中，Astra所需的对话轮数由Sol阶段的约8轮降至约5轮，约少3轮、减少约38%。我们的判断是，提效不仅发生在代码实现环节：前期策划更完整、实现路线更清晰，减少了开发过程中反复补充规则和纠正方向的沟通。</strong></p>
  <div class="table-scroll">
    <table class="workflow-comparison">
      <colgroup><col style="width:26%"><col style="width:37%"><col style="width:37%"></colgroup>
      <thead><tr><th scope="col">对比项</th><th scope="col">5.6 Sol</th><th scope="col">6.0 Astra</th></tr></thead>
      <tbody>
        <tr><th scope="row">相似需求目标</th><td colspan="2">从零星的想法出发，整理策划并实现一个拥有基础交互玩法的场景。</td></tr>
        <tr><th scope="row">对话轮数（约）</th><td><strong>8轮</strong></td><td><strong>5轮</strong>，约少3轮（减少约38%）</td></tr>
        <tr><th scope="row">前期策划的作用</th><td>相对更依赖负责人在后续沟通中补充零散规则、明确系统衔接与实现方向。</td><td>更能在策划阶段梳理核心交互与规则关联，为引擎实装提供清晰的实现路线。</td></tr>
        <tr><th scope="row">沟通重点的变化</th><td>较多轮次用于把“想做什么”继续解释为“具体怎样运行”。</td><td>减少方向与规则的反复澄清，更快进入可操作场景的体验反馈与调整。</td></tr>
      </tbody>
    </table>
  </div>
  <p class="evidence"><strong>为何策划质量会影响实装效率：</strong>零散想法往往只描述局部效果，而可玩的场景还需要明确操作入口、反馈、奖励去向和下一步目标。Astra更善于将这些环节整理成相互衔接的规则，让开发阶段知道先实现什么、各系统如何连接。我们认为，这种前置整理是本次对话轮数减少的重要原因，而不只是生成代码更快。</p>
  <p class="evidence" style="font-size:14px">数据口径：约8轮与约5轮由项目负责人根据实际协作经验估算，覆盖从想法整理到基础交互场景的沟通过程；约38%按（8−5）÷8取整。此处比较的是相似需求的对话轮数，不是同输入受控测试，也不等同于开发工时或内部debug次数减少38%。</p>
</div>
''')
section.xpath('./h3')[0].addprevious(block)
old = '可以更多围绕整体体验和关键规则给反馈。我们的使用感受是问答与返工负担减轻，但尚未进行统一的次数和工时统计。'
new = '可以更多围绕整体体验和关键规则给反馈。上述相似需求的经验估算为约5轮，相比Sol约8轮更少；开发工时与内部debug次数未作统一统计。'
matches = [n for n in section.xpath('.//td') if n.text == old]
assert len(matches) == 1
matches[0].text = new
replacement = html.tostring(section, encoding='unicode', method='html')
result = source[:match.start()] + replacement + source[match.end():]
assert result[:match.start()] == source[:match.start()]
assert result.endswith(source[match.end():])
path.write_text(result, encoding='utf-8')
print('Updated section 05 only: approx. 8 vs 5 rounds; estimate attribution and planning-quality explanation included.')
