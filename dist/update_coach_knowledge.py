#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import ctypes
import io
import os
import builtins

# ========== 立即释放控制台（彻底隐藏窗口）==========
if sys.platform == 'win32':
    try:
        ctypes.windll.kernel32.FreeConsole()
    except:
        pass

# ========== 安全的打印函数（避免 emoji 编码错误）==========
_original_print = builtins.print

def _safe_print(*args, **kwargs):
    try:
        _original_print(*args, **kwargs)
    except UnicodeEncodeError:
        text = ' '.join(str(arg) for arg in args)
        try:
            safe_text = text.encode('gbk', errors='ignore').decode('gbk')
        except Exception:
            safe_text = text.encode('ascii', errors='ignore').decode('ascii')
        _original_print(safe_text, **kwargs)

builtins.print = _safe_print

# ========== 其余导入 ==========
import json
import hashlib
import re
import time
import random
from pathlib import Path
import threading

import requests
import feedparser
from Bio import Entrez
from bs4 import BeautifulSoup

if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ========== 配置 ==========
Entrez.email = "Ethocas@outlook.com"

BAIDU_SEARCH_URL = "https://www.baidu.com/s"
BING_SEARCH_URL = "https://cn.bing.com/search"

ARXIV_QUERY = "ti:strength training OR ti:resistance training OR ti:muscle hypertrophy"
ARXIV_URL = "http://export.arxiv.org/api/query"
SCIENCEDAILY_RSS = "https://www.sciencedaily.com/rss/health_medicine/fitness.xml"

# 本地文件路径 - 相对于 exe 所在目录
JSON_PATH = Path(BASE_DIR) / "data/flutter_assets/assets/coach_rules.json"
PRESET_MYTHS_FILE = Path(__file__).parent / "preset_myths.txt"
PRESET_PROTOCOLS_FILE = Path(__file__).parent / "preset_protocols.txt"

MAX_RESULTS_PER_SOURCE = 30
MAX_CHINESE_SEARCH = 30

QUOTE_SOURCES = [
    "https://www.bodybuilding.com/fun/88-motivational-quotes-for-bodybuilders.html",
    "https://www.greatist.com/fitness/fitness-quotes",
    "https://www.muscleandfitness.com/flexpress/fitness-quotes/",
    "https://www.verywellfit.com/best-fitness-quotes-5114038",
    "https://www.healthline.com/health/fitness-exercise/fitness-quotes",
    "https://www.menshealth.com/fitness/a19544090/motivational-fitness-quotes/",
    "https://www.womenshealthmag.com/fitness/a19995330/fitness-quotes/",
    "https://www.shape.com/fitness/tips/fitness-quotes",
    "https://www.cosmopolitan.com/health-fitness/a13159237/fitness-quotes/",
    "https://www.eatthis.com/fitness-quotes/",
    "https://www.prevention.com/fitness/a20451935/motivational-fitness-quotes/",
    "https://www.self.com/story/fitness-quotes",
    "https://www.rd.com/list/fitness-quotes/",
    "https://www.briantracy.com/blog/personal-success/motivational-fitness-quotes/",
    "https://www.keepinspiring.me/fitness-quotes/",
    "https://www.thelawofattraction.com/fitness-quotes/",
    "https://www.goalcast.com/fitness-quotes/",
    "https://www.everydaypower.com/fitness-quotes/",
    "https://www.powerofpositivity.com/fitness-quotes/",
    "https://www.lifehack.org/articles/lifestyle/50-fitness-quotes-that-will-inspire-you-to-workout.html",
]

BLACKLIST_KEYWORDS = [
    "click here", "buy now", "discount", "miracle", "guaranteed", "ad", "sponsored", "promotion", "sale", "limited time", "exclusive", "new release",
    "affiliate", "sponsored", "advertisement", "产品", "促销", "代理",
    "点击", "购买", "优惠", "神奇", "保证", "广告", "赞助", "影视剧", "小说", "漫画", "游戏", "娱乐", "八卦", "明星", "网红", "影视",
    "测评", "推荐", "选购", "百度百科", "辭典", "檢視", "康复", "字典", "释义", "意思", "是什么", "怎么吃", "方法", "步骤", "教程", "指南", "方案", "计划",
    "excellent", "amazing", "incredible", "unbelievable", "best", "worst", "top", "review", "comparison", "评测", "对比", "排行榜", "最佳", "最差", "神评",
    "张雪峰", "免费", "免费试用", "试用装", "限时", "限量", "独家", "首发", "新品", "开箱", "开箱视频", "开箱测评",
    "娱乐圈", "影视圈", "明星八卦", "网红八卦", "娱乐八卦", "影视八卦",
    "京东", "好物", "畅游", "运动户外",
    "特价", "秒杀", "包邮", "满减", "领券", "优惠券", "拼团", "砍价", "免单", "返现", "赠品", "买一送一",
    "热卖", "爆款", "销量第一", "好评如潮", "口碑爆棚",
    "正品保障", "假一赔十", "七天无理由", "运费险", "极速退款", "闪电发货",
    "会员专享", "VIP特价", "黑卡会员", "钻石会员", "超级会员",
    "蛋白粉", "肌酸", "支链氨基酸", "氮泵", "左旋肉碱", "维生素", "益生菌", "鱼油",
    "红牛", "魔爪", "东鹏特饮", "乐虎", "战马",
    "康比特", "诺特兰德", "肌肉科技", "GNC", "健安喜", "汤臣倍健",
    "速看", "慎入", "深度好文", "必读", "收藏", "转发", "扩散", "感恩", "感动", "泪目",
    "揭秘", "内幕", "潜藏", "隐藏", "不为人知", "惊人", "震惊",
    "GitHub", "研发", "意义", "服务", "怎么样", "最新",
    "股價", "走勢", "社群", "股市", "登录", "用户", "引擎", "巨量", "抖音", "营销",
    "zhihu", "知乎", "理財", "理财", "資料", "股份", "资料", "上市", "高三", "瑞文", "测试",
    "百度知道",
]

def get_combined_blacklist():
    return BLACKLIST_KEYWORDS

def add_blacklist_to_script(word):
    script_path = Path(__file__).resolve()
    with open(script_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    start_idx = -1
    end_idx = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('BLACKLIST_KEYWORDS = ['):
            start_idx = i
            bracket_count = 0
            for j in range(i, len(lines)):
                bracket_count += lines[j].count('[') - lines[j].count(']')
                if bracket_count == 0:
                    end_idx = j
                    break
            break
    
    if start_idx == -1 or end_idx == -1:
        print("⚠️ 无法在脚本中找到黑名单列表，跳过写入脚本。")
        return False
    
    current_words = []
    for i in range(start_idx + 1, end_idx):
        line = lines[i].strip()
        if line and not line.startswith('#'):
            matches = re.findall(r'"([^"]*)"', line)
            current_words.extend(matches)
    
    if word not in current_words:
        current_words.append(word)
    
    new_lines = lines[:start_idx + 1]
    items_per_line = 100
    for i in range(0, len(current_words), items_per_line):
        batch = current_words[i:i + items_per_line]
        line = '    ' + ', '.join(f'"{w}"' for w in batch) + ',\n'
        new_lines.append(line)
    new_lines.append(']\n')
    new_lines.extend(lines[end_idx + 1:])
    
    with open(script_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    return True

def interactive_add_blacklist():
    try:
        if sys.stdin is None or not sys.stdin.isatty():
            print("检测到非交互式环境，跳过添加屏蔽词。")
            return
    except Exception:
        print("无法检测交互式环境，跳过添加屏蔽词。")
        return

    print("\n是否添加新的屏蔽词？ (1=是, 0=否) [5秒后自动跳过]")
    input_available = threading.Event()
    user_input = [None]
    
    def get_input():
        try:
            user_input[0] = sys.stdin.readline().strip()
            input_available.set()
        except:
            pass
    
    thread = threading.Thread(target=get_input)
    thread.daemon = True
    thread.start()
    thread.join(5)
    
    if not input_available.is_set():
        print("超时，跳过添加屏蔽词。")
        return
    
    choice = user_input[0]
    if choice == "1":
        while True:
            print("请输入要添加的屏蔽词（直接回车结束添加）：")
            word = sys.stdin.readline().strip()
            if not word:
                break
            if word not in BLACKLIST_KEYWORDS:
                if add_blacklist_to_script(word):
                    BLACKLIST_KEYWORDS.append(word)
                    print(f"✅ 已添加并写入脚本: {word}")
                else:
                    print(f"⚠️ 写入脚本失败: {word}")
            else:
                print("该词已存在，跳过。")
            print("按回车继续添加，按空格结束添加")
            cont = sys.stdin.readline().strip()
            if cont == " ":
                break
    elif choice == "0":
        print("跳过添加屏蔽词。")
    else:
        print("无效输入，跳过。")

def fetch_quotes_from_url(url, max_quotes=20):
    quotes = []
    try:
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        resp = requests.get(url, headers=headers, timeout=15)
        if resp.status_code != 200:
            return []
        soup = BeautifulSoup(resp.text, 'html.parser')
        selectors = ['.quote', '.quotes', 'blockquote', '.quote-text', '.message', 'li', 'p', '.content', '.text', '.description', '.post-content']
        for selector in selectors:
            elements = soup.select(selector)
            for elem in elements:
                text = elem.get_text(strip=True)
                if text and 15 < len(text) < 300:
                    if not any(bad in text.lower() for bad in ['copyright', 'cookie', 'subscribe', 'sign up', 'login', 'register']):
                        text = re.sub(r'\s+', ' ', text)
                        text = re.sub(r'^[\"\']+|[\"\']+$', '', text)
                        if text not in quotes:
                            quotes.append(text)
                if len(quotes) >= max_quotes:
                    break
            if len(quotes) >= max_quotes:
                break
        time.sleep(0.5)
    except Exception as e:
        print(f"  抓取 {url} 失败: {e}")
    return quotes[:max_quotes]

def load_preset_short_texts(file_path, category_name):
    texts = []
    if file_path.exists():
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and len(line) < 200:
                    texts.append(line)
    else:
        default_texts = {
            "myth_busters": [
                "局部减脂（只减肚子）并不存在，脂肪减少是全身性的。",
                "练后不拉伸等于白练？拉伸主要改善柔韧性，对肌肉增长影响有限。",
                "流汗多不等于减脂多，汗水只是体温调节。",
                "肌肉不会变成脂肪，两者是不同的组织。",
                "训练后马上吃饭会变胖？错，训练后是补充营养的最佳窗口。",
            ],
            "training_protocols": [
                "渐进超负荷是力量增长的核心。",
                "复合动作（深蹲、卧推、硬拉）是训练的基础。",
                "减载周每4-8周安排一次，帮助恢复。",
                "训练后30分钟内补充快碳+蛋白质，促进恢复。",
                "罗尼·库尔曼：'Everybody wants to be a bodybuilder, but nobody wants to lift no heavy ass weights.'",
                "阿诺德·施瓦辛格：'The last three or four reps is what makes the muscle grow.'",
            ]
        }
        default_list = default_texts.get(category_name, [])
        with open(file_path, "w", encoding="utf-8") as f:
            for line in default_list:
                f.write(line + "\n")
        texts = default_list
    return texts

def hash_text(text):
    return hashlib.md5(text.encode("utf-8")).hexdigest()

def is_quality_text(text, min_len=15):
    if len(text) < min_len:
        return False
    lower = text.lower()
    for kw in BLACKLIST_KEYWORDS:
        if kw in lower:
            return False
    return True

def clean_text(text):
    text = re.sub(r'\s+', ' ', text).strip()
    text = re.sub(r'<[^>]+>', '', text)
    return text

def shorten_text(text, max_len=800):
    if len(text) <= max_len:
        return text
    for sep in ['.', '!', '?', '。', '！', '？', '；', ';']:
        pos = text.find(sep, max_len // 2, max_len)
        if pos != -1:
            return text[:pos + 1].strip()
    return text[:max_len].strip() + "..."

def load_existing_hashes(json_path, categories):
    if not json_path.exists():
        print(f"⚠️ JSON 文件不存在: {json_path}")
        return set()
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    hashes = set()
    for cat in categories:
        if cat in data and isinstance(data[cat], list):
            for item in data[cat]:
                if isinstance(item, str):
                    hashes.add(hash_text(item))
    return hashes

def remove_blacklisted_entries(json_path):
    if not json_path.exists():
        print("⚠️ coach_rules.json 不存在，跳过清理步骤")
        return
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    removed_count = 0
    for category in ["scientific_facts", "research_summaries", "myth_busters", "training_protocols", "tips", "encouragements"]:
        if category not in data or not isinstance(data[category], list):
            continue
        original = data[category]
        filtered = []
        for item in original:
            text = item if isinstance(item, str) else item.get("text", "") if isinstance(item, dict) else ""
            if is_quality_text(text, min_len=10):
                filtered.append(item)
            else:
                removed_count += 1
                print(f"  移除屏蔽条目: {text[:80]}...")
        data[category] = filtered
    if removed_count > 0:
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✅ 已从 JSON 中移除 {removed_count} 条包含屏蔽词的条目")
    else:
        print("ℹ️ 未发现需要移除的屏蔽条目")

def append_to_json(json_path, category, new_entries):
    if not json_path.exists():
        print(f"错误：找不到 {json_path}，请确认路径正确")
        return
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if category not in data:
        data[category] = []
    existing_hashes = set()
    for item in data[category]:
        if isinstance(item, str):
            existing_hashes.add(hash_text(item))
    added = 0
    for entry in new_entries:
        if hash_text(entry) not in existing_hashes:
            data[category].append(entry)
            added += 1
    if added > 0:
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"✅ 已向 {category} 添加 {added} 条新知识")
    else:
        print(f"ℹ️  {category} 无新内容")

def fetch_baidu_fact(keyword, max_results=5):
    results = []
    try:
        params = {"wd": keyword, "pn": 0, "rn": max_results}
        resp = requests.get(BAIDU_SEARCH_URL, params=params, timeout=10)
        if resp.status_code != 200:
            return []
        soup = BeautifulSoup(resp.text, 'html.parser')
        for result in soup.select('.result, .c-container'):
            title_elem = result.select_one('h3 a')
            if not title_elem:
                continue
            title = title_elem.get_text(strip=True)
            summary_elem = result.select_one('.c-abstract, .content-right_2nJd9')
            summary = summary_elem.get_text(strip=True) if summary_elem else ""
            combined = f"{title}。{summary}" if summary else title
            combined = clean_text(combined)
            combined = shorten_text(combined, max_len=800)
            if is_quality_text(combined, min_len=40):
                results.append(combined)
            if len(results) >= max_results:
                break
        time.sleep(1)
    except Exception as e:
        print(f"    百度搜索异常: {e}")
    return results

def fetch_bing_fact(keyword, max_results=5):
    results = []
    try:
        params = {"q": keyword, "count": max_results, "setlang": "zh-Hans"}
        resp = requests.get(BING_SEARCH_URL, params=params, timeout=10)
        if resp.status_code != 200:
            return []
        soup = BeautifulSoup(resp.text, 'html.parser')
        for result in soup.select('#b_results .b_algo'):
            title_elem = result.select_one('h2 a')
            if not title_elem:
                continue
            title = title_elem.get_text(strip=True)
            summary_elem = result.select_one('.b_caption p')
            summary = summary_elem.get_text(strip=True) if summary_elem else ""
            combined = f"{title}。{summary}" if summary else title
            combined = clean_text(combined)
            combined = shorten_text(combined, max_len=800)
            if is_quality_text(combined, min_len=40):
                results.append(combined)
            if len(results) >= max_results:
                break
        time.sleep(1)
    except Exception as e:
        print(f"    必应搜索异常: {e}")
    return results

def fetch_chinese_facts(keywords, max_results=5):
    all_results = []
    for kw in keywords:
        print(f"    搜索关键词：{kw}")
        baidu_items = fetch_baidu_fact(f"{kw} 健身 科学", max_results=max_results // 2)
        bing_items = fetch_bing_fact(f"{kw} 健身 科学", max_results=max_results // 2)
        all_results.extend(baidu_items)
        all_results.extend(bing_items)
        time.sleep(random.uniform(1, 2))
    seen = set()
    unique = []
    for item in all_results:
        h = hash_text(item)
        if h not in seen:
            seen.add(h)
            unique.append(item)
    return unique[:max_results * len(keywords)]

def fetch_pubmed(term, max_results=2):
    try:
        handle = Entrez.esearch(db="pubmed", term=term, retmax=max_results)
        record = Entrez.read(handle)
        id_list = record["IdList"]
        if not id_list:
            return []
        facts = []
        for pid in id_list:
            fetch_handle = Entrez.efetch(db="pubmed", id=pid, retmode="xml")
            articles = Entrez.read(fetch_handle)
            for article in articles.get("PubmedArticle", []):
                medline = article["MedlineCitation"]["Article"]
                title = medline.get("ArticleTitle", "").strip()
                abstract_list = medline.get("Abstract", {}).get("AbstractText", [])
                abstract = " ".join(abstract_list).strip() if abstract_list else ""
                if abstract and len(abstract) > 50:
                    raw = f"{title}. {abstract}"
                    raw = clean_text(raw)
                    if is_quality_text(raw):
                        facts.append(raw)
            time.sleep(0.5)
        return facts[:max_results]
    except Exception as e:
        print(f"PubMed 抓取失败 ({term}): {e}")
        return []

def fetch_arxiv(query, max_results=5):
    try:
        params = {"search_query": query, "start": 0, "max_results": max_results, "sortBy": "submittedDate", "sortOrder": "descending"}
        resp = requests.get(ARXIV_URL, params=params, timeout=15)
        if resp.status_code != 200:
            print(f"arXiv 请求失败: {resp.status_code}")
            return []
        feed = feedparser.parse(resp.text)
        summaries = []
        for entry in feed.entries:
            title = entry.title.strip()
            summary = entry.summary.strip()
            summary = re.sub(r'<[^>]+>', '', summary)
            if not summary:
                continue
            raw = f"{title}. {summary}"
            raw = clean_text(raw)
            if is_quality_text(raw):
                summaries.append(raw)
        return summaries[:max_results]
    except Exception as e:
        print(f"arXiv 抓取失败: {e}")
        return []

def fetch_sciencedaily_rss(max_items=5):
    try:
        feed = feedparser.parse(SCIENCEDAILY_RSS)
        items = []
        for entry in feed.entries[:max_items]:
            title = entry.title.strip()
            description = entry.description.strip() if hasattr(entry, 'description') else ""
            description = re.sub(r'<[^>]+>', '', description)
            raw = f"{title}. {description}"
            raw = clean_text(raw)
            if is_quality_text(raw, min_len=50):
                items.append(raw)
        return items
    except Exception as e:
        print(f"ScienceDaily RSS 抓取失败: {e}")
        return []

def get_predefined_tips():
    return [
        "💡 每组动作的最后一两次要竭尽全力，这才是刺激肌肉生长的关键。",
        "💡 训练前动态热身，训练后静态拉伸，能有效预防受伤。",
        "💡 记录每一次训练的重量和组数，便于追踪进步。",
        "💡 睡眠不足会严重影响肌肉恢复和生长激素分泌。",
        "💡 多关节复合动作比孤立动作更能提升整体力量。",
        "💡 渐进超负荷是力量增长的核心原则。",
        "💡 减载周每4-8周安排一次，帮助神经和肌肉充分恢复。",
        "💡 练后30分钟内补充快碳+蛋白质，促进肌肉合成。",
        "💡 动作质量永远比重量更重要。",
        "💡 训练计划每6-8周调整一次，避免平台期。",
        "💡 离心阶段控制2-3秒，增肌效果更佳。",
        "💡 训练容量（组数×次数×重量）是衡量训练量的关键指标。",
        "💡 深蹲、卧推、硬拉是黄金三大复合动作。",
        "💡 训练后补充乳清蛋白吸收最快，酪蛋白适合睡前。",
        "💡 每天饮水2-3升，维持新陈代谢和关节润滑。",
        "💡 训练后冰敷可减少炎症，热敷促进血液循环。",
        "💡 每周至少安排1-2天完全休息，防止过度训练。",
        "💡 训练前1-2小时补充复合碳水，提供持久能量。",
        "💡 使用腰带、护腕等护具可降低受伤风险，但不要过度依赖。",
        "💡 训练后拉伸保持15-30秒，改善柔韧性。",
    ]

def get_predefined_encouragements():
    return [
        "🌟 你今天又进步了！哪怕只是多加了一组。",
        "💪 坚持就是胜利，肌肉会在你休息时悄悄生长。",
        "🏆 别忘了，罗马不是一天建成的，好身材也是。",
        "🔥 今天的汗水，是明天的勋章。",
        "✨ 你已经比昨天的自己更强了。",
        "💪 没有痛苦，就没有收获。",
        "🏋️ 每一次举起，都是对昨天的超越。",
        "🌟 相信过程，肌肉会回报你的耐心。",
        "🔥 流汗是脂肪在哭泣。",
        "💪 你的极限，只是别人的起点。",
        "🏆 坚持，是最强大的力量。",
        "✨ 昨天的你，已经配不上今天的训练。",
        "💫 动作质量比重量更重要。",
        "🏔️ 攀登自己的顶峰，哪怕一步。",
        "💎 肌肉是用铁铸成的，不是用嘴。",
        "🦁 像野兽一样训练，像国王一样饮食，像婴儿一样睡眠。",
        "💪 每一次力竭，都是一次重生。",
        "🌟 训练是投资，回报是健康和自信。",
        "🔥 酸痛是暂时的，自豪是永恒的。",
        "🏋️ 器械是你的画笔，身体是你的画布。",
        "✨ 今天的克制，是为了明天的自由。",
        "💪 放弃很容易，但坚持更酷。",
        "🏆 冠军在别人休息时仍在训练。",
        "💫 不要羡慕别人的腹肌，那是你还没付出的努力。",
        "🔥 汗水是最好的护肤品。",
    ]

def ensure_default_json():
    """如果 JSON 文件不存在，创建包含正确结构的默认文件"""
    if JSON_PATH.exists():
        return
    print(f"📝 未找到 coach_rules.json，正在创建默认文件: {JSON_PATH}")
    JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    default_data = {
        "openings": ["🔍 让我看看你的训练数据～", "📊 分析中，请稍候..."],
        "volume_analysis": {
            "high": ["🔥 本次训练容量很高！总做功 ${work} 千焦，恢复要跟上。"],
            "moderate": ["💪 本次训练容量适中，总做功 ${work} 千焦，继续保持。"],
            "low": ["📉 本次训练容量较低（${work} 千焦），可以尝试增加强度。"]
        },
        "part_balance": {
            "complete": ["✅ 今天训练部位覆盖了 ${parts}，非常全面！"],
            "missing": ["⚠️ 今天没有训练 ${parts}，下次记得补上。"]
        },
        "progress_tracking": {
            "improved": ["📈 比上次提升 ${diff}kg，进步明显！"],
            "declined": ["📉 比上次下降 ${diff}kg，可能是疲劳或减载期。"],
            "same": ["🔄 重量与上次持平，可以尝试突破。"],
            "first": ["✨ 首次记录 ${name}，打好基础。"]
        },
        "predictions": {
            "templates": ["📊 预测 ${name} 在 ${weeks} 周内有望达到 ${target} kg，保持渐进超负荷。"]
        },
        "week_frequency": {
            "excellent": ["🏆 本周训练 ${sessions} 次，频率优秀！"],
            "good": ["👍 本周训练 ${sessions} 次，频率不错。"],
            "fair": ["📌 本周训练 ${sessions} 次，可以增加频率。"],
            "poor": ["⏰ 本周暂无训练，快动起来！"]
        },
        "week_volume": {
            "high": ["🔥 本周总容量 ${work} 千焦，强度很高，注意恢复。"],
            "moderate": ["💪 本周总容量 ${work} 千焦，适中。"],
            "low": ["📉 本周总容量 ${work} 千焦，建议增加训练量。"]
        },
        "week_part_advice": {
            "complete": ["✅ 本周训练部位覆盖全面！"],
            "missing": ["⚠️ 本周缺少 ${parts} 的训练，下周注意平衡。"]
        },
        "history_summary": {
            "template": "📜 从开始到现在，你一共完成了 ${totalSessions} 次训练，${totalSets} 组动作，输出 ${totalWorkKJ} 千焦，消耗约 ${calories} 大卡热量。",
            "fav_part": "💪 你最常训练的部位是「${part}」，${comment}",
            "first_compare": {
                "improved": "📈 相比第一次训练（${firstKJ} 千焦），最近一次容量提升了 ${diff} 千焦，进步显著！",
                "declined": "📉 相比第一次训练（${firstKJ} 千焦），最近一次容量有所下降，可能是减载或状态波动。",
                "same": "⚖️ 相比第一次训练，容量保持稳定，可以尝试突破。"
            },
            "milestone": "🎉 恭喜完成第 ${sessions} 次训练！这是一个重要的里程碑！"
        },
        "encouragements": [
            "✨ 每一次力竭都是成长的信号，继续加油！",
            "💪 坚持就是胜利！",
            "🌟 你已经比昨天更强了。"
        ],
        "tips": [
            "💡 练后30分钟内补充快碳+蛋白质，有助于肌肉恢复。",
            "💡 每组动作的最后一两次要竭尽全力，这才是刺激肌肉生长的关键。"
        ],
        "scientific_facts": [],
        "research_summaries": [],
        "myth_busters": [],
        "training_protocols": []
    }
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(default_data, f, ensure_ascii=False, indent=2)
    print("✅ 默认 JSON 文件创建成功")

def main():
    print(f"📂 当前工作目录: {os.getcwd()}")
    print(f"📂 基础目录: {BASE_DIR}")
    print(f"📂 JSON 路径: {JSON_PATH}")

    interactive_add_blacklist()

    print("🚀 开始执行健身科学知识更新任务...")

    # 确保 JSON 文件存在（如果不存在则创建默认）
    ensure_default_json()

    print("\n🧹 清理 JSON 中的广告/屏蔽词条目...")
    remove_blacklisted_entries(JSON_PATH)

    categories = ["scientific_facts", "research_summaries", "myth_busters", "training_protocols", "tips", "encouragements"]
    existing_hashes = load_existing_hashes(JSON_PATH, categories)
    print(f"📚 已加载 {len(existing_hashes)} 条现有知识哈希")

    seen = set(existing_hashes)
    all_facts = []
    all_research = []
    all_myths = []
    all_protocols = []
    all_tips = []
    all_encouragements = []

    print("\n🌐 抓取科学事实...")
    chinese_keywords = [
        "运动营养", "力量训练 研究", "肌肉增长 科学", "高强度间歇训练 效果",
        "健身 误区", "运动恢复 最新", "抗阻训练 进展", "健身 科学研究"
    ]
    chinese_facts = fetch_chinese_facts(chinese_keywords, max_results=MAX_CHINESE_SEARCH)
    for item in chinese_facts:
        h = hash_text(item)
        if h not in seen:
            seen.add(h)
            all_facts.append(item)
    print(f"  搜索获得 {len(chinese_facts)} 条新科学事实")

    print("\n📄 抓取 PubMed...")
    terms = [
        "resistance training muscle hypertrophy",
        "protein intake muscle growth",
        "high intensity interval training health",
        "strength training elderly",
        "nutrition recovery exercise"
    ]
    pubmed_facts = []
    for term in terms:
        facts = fetch_pubmed(term, max_results=2)
        pubmed_facts.extend(facts)
        time.sleep(1)
    for f in pubmed_facts:
        h = hash_text(f)
        if h not in seen:
            seen.add(h)
            all_facts.append(f)
    print(f"  从 PubMed 获得 {len(pubmed_facts)} 条新科学事实")

    print("\n📑 抓取 arXiv...")
    arxiv_research = fetch_arxiv(ARXIV_QUERY, max_results=MAX_RESULTS_PER_SOURCE)
    for a in arxiv_research:
        h = hash_text(a)
        if h not in seen:
            seen.add(h)
            all_research.append(a)
    print(f"  从 arXiv 获得 {len(arxiv_research)} 条新研究总结")

    print("\n📰 抓取 ScienceDaily RSS...")
    sd_facts = fetch_sciencedaily_rss(max_items=MAX_RESULTS_PER_SOURCE)
    for sd in sd_facts:
        h = hash_text(sd)
        if h not in seen:
            seen.add(h)
            all_facts.append(sd)
    print(f"  从 ScienceDaily 获得 {len(sd_facts)} 条新科学事实")

    print("\n📚 加载预设的健身谚语和迷思...")
    preset_myths = load_preset_short_texts(PRESET_MYTHS_FILE, "myth_busters")
    for item in preset_myths:
        h = hash_text(item)
        if h not in seen:
            seen.add(h)
            all_myths.append(item)
    print(f"  从预设文件获得 {len(preset_myths)} 条迷思")

    preset_protocols = load_preset_short_texts(PRESET_PROTOCOLS_FILE, "training_protocols")
    for item in preset_protocols:
        h = hash_text(item)
        if h not in seen:
            seen.add(h)
            all_protocols.append(item)
    print(f"  从预设文件获得 {len(preset_protocols)} 条训练经验")

    print("\n📖 从健身名言网站抓取鼓励语和小贴士...")
    for url in QUOTE_SOURCES:
        print(f"  抓取: {url[:60]}...")
        quotes = fetch_quotes_from_url(url, max_quotes=10)
        for quote in quotes:
            if len(quote) < 80 and any(word in quote.lower() for word in ['you', 'your', 'can', 'will', 'never', 'always', 'every']):
                h = hash_text(quote)
                if h not in seen:
                    seen.add(h)
                    all_encouragements.append(quote)
            elif len(quote) < 120:
                h = hash_text(quote)
                if h not in seen:
                    seen.add(h)
                    all_tips.append(quote)
        time.sleep(0.5)
    print(f"  从网站抓取获得 {len(all_encouragements)} 条鼓励语，{len(all_tips)} 条小贴士")

    print("\n📝 使用预定义内容补充鼓励语和小贴士...")
    predefined_tips = get_predefined_tips()
    for item in predefined_tips:
        h = hash_text(item)
        if h not in seen:
            seen.add(h)
            all_tips.append(item)
    
    predefined_encouragements = get_predefined_encouragements()
    for item in predefined_encouragements:
        h = hash_text(item)
        if h not in seen:
            seen.add(h)
            all_encouragements.append(item)
    
    print(f"  最终新增 {len(all_tips)} 条 tips，{len(all_encouragements)} 条 encouragements")

    if all_facts:
        append_to_json(JSON_PATH, "scientific_facts", all_facts)
    if all_research:
        append_to_json(JSON_PATH, "research_summaries", all_research)
    if all_myths:
        append_to_json(JSON_PATH, "myth_busters", all_myths)
    if all_protocols:
        append_to_json(JSON_PATH, "training_protocols", all_protocols)
    if all_tips:
        append_to_json(JSON_PATH, "tips", all_tips)
    if all_encouragements:
        append_to_json(JSON_PATH, "encouragements", all_encouragements)

    print("\n🎉 更新完成！")

if __name__ == "__main__":
    HEADERS = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    }
    main()