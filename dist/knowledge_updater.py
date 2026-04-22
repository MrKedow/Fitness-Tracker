#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import json
import time
import random
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Set
import requests
from bs4 import BeautifulSoup
import xml.etree.ElementTree as ET

# ========== 配置区域（请根据实际情况修改） ==========
# 本地 JSON 文件保存路径（建议放在 Flutter 项目的 assets 目录下）
LOCAL_JSON_PATH = Path(r"C:\your_flutter_project\assets\knowledge_latest.json")
# Git 仓库本地路径（需要先 clone 到本地）
GIT_REPO_PATH = Path(r"C:\your_flutter_project")
# 远程仓库 URL（使用 HTTPS + Personal Access Token 或 SSH）
GIT_REMOTE_URL = "https://github.com/your_username/your_repo.git"
# 抓取间隔（秒）—— 1 小时
SCRAPE_INTERVAL = 3600
# Git 推送间隔（秒）—— 10 小时
PUSH_INTERVAL = 36000
# 推送失败最大重试次数
MAX_RETRIES = 50
# 重试间隔（秒）
RETRY_DELAY = 30
# 坚果云 WebDAV 配置（可选，用于抓取 PubMed/arXiv 时可能用到）
ENTREZ_EMAIL = "Ethocas@outlook.com"

# ========== 抓取源列表（与原 Dart 代码完全一致） ==========
QUOTE_SOURCES = [
    "https://www.bodybuilding.com/fun/88-motivational-quotes-for-bodybuilders.html",
    "https://www.greatist.com/fitness/fitness-quotes",
    "https://www.muscleandfitness.com/flexpress/fitness-quotes/",
    "https://www.verywellfit.com/best-fitness-quotes-5114038",
    "https://www.healthline.com/health/fitness-exercise/fitness-quotes",
    "https://www.shape.com/fitness/tips/fitness-quotes",
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
    "https://www.brainyquote.com/topics/fitness-quotes",
    "https://www.quotescover.com/topic/fitness",
    "https://www.wiseoldsayings.com/fitness-quotes/",
    "https://www.inspiringquotes.us/topic/fitness",
    "https://www.azquotes.com/quotes/topics/fitness.html",
    "https://www.quotegarden.com/fitness.html",
    "https://www.quotehd.com/quotes/topics/fitness",
    "https://www.quoteswave.com/topic/fitness",
    'https://www.acefitness.org/education-and-resources/lifestyle/blog/6730/debunking-common-fitness-myths/',
    'https://www.healthline.com/nutrition/20-fitness-myths',
    'https://www.verywellfit.com/common-fitness-myths-1229814',
    'https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/fitness-myths/art-20047099',
    'https://www.webmd.com/fitness-exercise/ss/slideshow-fitness-myths',
    'https://www.self.com/story/fitness-myths-debunked',
    'https://www.shape.com/fitness/tips/fitness-myths-debunked',
    'https://www.prevention.com/fitness/a20451935/fitness-myths/',
    'https://www.rd.com/list/fitness-myths/',
    'https://www.eatthis.com/fitness-myths/',
    'https://www.lifehack.org/articles/lifestyle/10-fitness-myths-you-need-to-stop-believing.html',
    'https://www.bodybuilding.com/content/10-fitness-myths-debunked.html',
    'https://www.muscleandfitness.com/workouts/workout-tips/10-fitness-myths-busted/',
    'https://www.greatist.com/fitness/common-fitness-myths',
    'https://www.health.com/fitness/fitness-myths',
    'https://www.thehealthy.com/exercise/fitness-myths/',
    'https://www.livestrong.com/article/13725598-fitness-myths-debunked/',
    'https://www.acefitness.org/education-and-resources/lifestyle/blog/6593/7-strength-training-protocols-for-muscle-growth/',
    'https://www.healthline.com/health/fitness-exercise/strength-training-routines',
    'https://www.verywellfit.com/best-strength-training-workouts-4154676',
    'https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/strength-training/art-20046670',
    'https://www.webmd.com/fitness-exercise/ss/slideshow-strength-training-basics',
    'https://www.self.com/story/best-strength-training-workouts',
    'https://www.shape.com/fitness/workouts/best-workout-routines',
    'https://www.prevention.com/fitness/workouts/a20451935/best-workout-plans/',
    'https://www.rd.com/list/best-exercise-routines/',
    'https://www.eatthis.com/best-workout-routines/',
    'https://www.lifehack.org/articles/lifestyle/10-best-workout-routines-for-men-and-women.html',
    'https://www.bodybuilding.com/content/10-best-muscle-building-workout-routines.html',
    'https://www.muscleandfitness.com/workouts/workout-routines/',
    'https://www.greatist.com/fitness/best-workout-routines',
    'https://www.health.com/fitness/best-workout-plans',
    'https://www.thehealthy.com/exercise/best-workout-routines/',
    'https://www.livestrong.com/article/13725599-best-workout-routines/',
]

CHINESE_KEYWORDS = [
    '运动营养', '力量训练 研究', '肌肉增长 科学', '高强度间歇训练 效果',
    '健身 误区', '运动恢复 最新', '抗阻训练 进展', '健身 科学研究',
    '增肌 方法', '减脂 科学', '有氧运动 益处', '核心训练 原理',
    '拉伸 重要性', '健身 饮食', '补剂 研究', '训练计划 设计',
    '女性 健身', '老年人 力量训练', '青少年 运动', '运动损伤 预防',
    '健身 心理学', '睡眠 与 运动恢复', 'HIIT 研究', '瑜伽 健康',
    '普拉提 好处', 'CrossFit 研究', '健美 营养', '跑步 健康',
    '游泳 健身', '骑行 锻炼', '登山 体力', '跳绳 燃脂',
    'Tabata 效果', '功能性训练', '平衡训练', '柔韧性 训练',
    '爆发力 训练', '速度 训练', '敏捷性 训练', '耐力 训练',
]

ARXIV_QUERIES = [
    'strength training', 'muscle hypertrophy', 'exercise physiology',
    'sports nutrition', 'resistance training', 'endurance exercise',
    'protein metabolism', 'creatine supplementation', 'concurrent training',
    'periodization', 'plyometric training', 'blood flow restriction',
    'recovery modalities', 'sleep and athletic performance', 'caffeine performance',
    'beta alanine', 'citrulline malate', 'HMB supplementation',
    'vitamin D athletic performance', 'omega 3 exercise', 'probiotics athlete',
    'intermittent fasting exercise', 'ketogenic diet performance', 'vegan athlete',
    'female athlete triad', 'youth resistance training', 'master athlete',
    'tendon adaptation', 'bone density exercise', 'sarcopenia prevention',
]

PUBMED_QUERIES = [
    'resistance training muscle hypertrophy',
    'protein intake muscle protein synthesis',
    'high intensity interval training cardiovascular health',
    'creatine supplementation strength',
    'beta alanine exercise performance',
    'caffeine ergogenic aid',
    'concurrent training interference',
    'stretching injury prevention',
    'foam rolling recovery',
    'sleep deprivation athletic performance',
    'menstrual cycle exercise performance',
    'aging sarcopenia resistance exercise',
    'obesity exercise intervention',
    'type 2 diabetes resistance training',
    'hypertension aerobic exercise',
    'depression physical activity',
    'bone density weight bearing exercise',
    'tendinopathy rehabilitation',
    'ACL injury prevention',
    'probiotics immune function athlete',
    'vitamin D muscle strength',
    'omega 3 fatty acid inflammation exercise',
    'citrulline malate fatigue',
    'HMB muscle damage',
    'sodium bicarbonate buffering capacity',
    'nitrate supplementation endurance',
    'carbohydrate mouth rinse performance',
    'cold water immersion recovery',
    'compression garments muscle soreness',
    'high intensity interval training health',
    'strength training elderly',
    'nutrition recovery exercise',
]

BLACKLIST = [
    "click here", "buy now", "discount", "miracle", "guaranteed", "ad", "sponsored",
    "promotion", "sale", "limited time", "exclusive", "new release", "affiliate",
    "advertisement", "产品", "促销", "代理", "点击", "购买", "优惠", "神奇", "保证",
    "广告", "赞助", "影视剧", "小说", "漫画", "游戏", "娱乐", "八卦", "明星", "网红",
    "测评", "推荐", "选购", "百度百科", "辭典", "檢視", "康复", "字典", "释义", "意思",
    "是什么", "怎么吃", "方法", "步骤", "教程", "指南", "方案", "计划", "excellent",
    "amazing", "incredible", "unbelievable", "best", "worst", "top", "review",
    "comparison", "评测", "对比", "排行榜", "最佳", "最差", "神评", "张雪峰", "免费",
    "免费试用", "试用装", "限时", "限量", "独家", "首发", "新品", "开箱", "开箱视频",
    "开箱测评", "娱乐圈", "影视圈", "明星八卦", "网红八卦", "娱乐八卦", "影视八卦",
    "京东", "好物", "畅游", "运动户外", "特价", "秒杀", "包邮", "满减", "领券",
    "优惠券", "拼团", "砍价", "免单", "返现", "赠品", "买一送一", "热卖", "爆款",
    "销量第一", "好评如潮", "口碑爆棚", "正品保障", "假一赔十", "七天无理由",
    "运费险", "极速退款", "闪电发货", "会员专享", "VIP特价", "黑卡会员", "钻石会员",
    "超级会员", "蛋白粉", "肌酸", "支链氨基酸", "氮泵", "左旋肉碱", "维生素", "益生菌",
    "鱼油", "红牛", "魔爪", "东鹏特饮", "乐虎", "战马", "康比特", "诺特兰德", "肌肉科技",
    "GNC", "健安喜", "汤臣倍健", "速看", "慎入", "深度好文", "必读", "收藏", "转发",
    "扩散", "感恩", "感动", "泪目", "揭秘", "内幕", "潜藏", "隐藏", "不为人知", "惊人",
    "震惊", "GitHub", "研发", "意义", "服务", "怎么样", "最新", "股價", "走勢", "社群",
    "股市", "登录", "用户", "引擎", "巨量", "抖音", "营销", "zhihu", "知乎", "理財",
    "理财", "資料", "股份", "资料", "上市", "高三", "瑞文", "测试", "百度知道", "360问答",
    "搜狗问问", "新浪爱问", "腾讯问问", "网易知道", "问答", "提问", "回答", "问题",
    "答案", "解答", "咨询", "客服", "教程", "教学", "课程", "培训", "学习", "教育",
    "视频", "直播", "讲座", "研讨会", "会议", "论坛", "社区", "贴吧", "群", "微信群",
    "QQ群", "公众号", "小红书", "快手", "B站", "哔哩哔哩", "微博", "微信", "Instagram",
    "Facebook", "Twitter", "LinkedIn", "YouTube", "TikTok", "Snapchat", "Reddit",
    "Pinterest", "康复", "字典", "意思", "怎么吃", "方法", "步骤", "教程", "指南",
    "方案", "计划", "评测", "对比", "排行榜", "最佳", "最差", "神评", "免费", "试用",
    "限时", "限量", "独家", "首发", "新品", "开箱", "娱乐圈", "明星八卦", "网红八卦",
    "娱乐八卦", "影视八卦", "京东", "好物", "畅游", "运动户外", "特价", "秒杀", "包邮",
    "满减", "领券", "优惠券", "拼团", "砍价", "免单", "返现", "赠品", "买一送一",
    "热卖", "爆款", "销量第一", "好评如潮", "口碑爆棚", "正品保障", "假一赔十",
    "七天无理由", "运费险", "极速退款", "闪电发货", "会员专享", "VIP特价", "黑卡会员",
    "钻石会员", "超级会员", "蛋白粉", "肌酸", "支链氨基酸", "氮泵", "左旋肉碱", "维生素",
    "益生菌", "鱼油", "红牛", "魔爪", "东鹏特饮", "乐虎", "战马", "康比特", "诺特兰德",
    "肌肉科技", "GNC", "健安喜", "汤臣倍健", "速看", "慎入", "深度好文", "必读", "收藏",
    "转发", "扩散", "感恩", "感动", "泪目", "揭秘", "内幕", "潜藏", "隐藏", "不为人知",
    "惊人", "震惊", "GitHub", "研发", "意义", "服务", "怎么样", "最新", "股價", "走勢",
    "社群", "股市", "登录", "用户", "引擎", "巨量", "抖音", "营销", "zhihu", "知乎",
    "理財", "理财", "資料", "股份", "资料", "上市", "高三", "瑞文", "测试", "百度知道",
    "360问答", "搜狗问问", "新浪爱问", "腾讯问问", "网易知道", "问答", "提问", "回答",
    "问题", "答案", "解答", "咨询", "客服", "教程", "教学", "课程", "培训", "学习",
    "教育", "视频", "直播", "讲座", "研讨会", "会议", "论坛", "社区", "贴吧", "群",
    "微信群", "QQ群", "公众号", "小红书", "快手", "B站", "哔哩哔哩", "微博", "微信",
    "Instagram", "Facebook", "Twitter", "LinkedIn", "YouTube", "TikTok", "Snapchat",
    "Reddit", "Pinterest",
]

# ========== 预设内容（与原 Dart 保持一致，作为保底） ==========
PRESET_RESEARCH = [
    "🔬 研究：每周2-3次力量训练可增加肌肉质量并提高骨密度。",
    "🔬 蛋白质摄入时机：训练后30分钟内补充20-25g蛋白质最能促进肌肉合成。",
    # ... 此处应有完整预设（因篇幅省略，实际请从原 Dart 复制全部 _presetResearch）
]

PRESET_ENCOURAGEMENTS = [
    "💪 每一次力竭都是成长的信号！",
    # ...
]

PRESET_TIPS = [
    "💡 训练前动态热身，训练后静态拉伸。",
    # ...
]

PRESET_FACTS = [
    "📚 蛋白质摄入建议每公斤体重1.6-2.2克。",
    # ...
]

PRESET_MYTHS = [
    "🧠 局部减脂不存在。",
    # ...
]

PRESET_PROTOCOLS = [
    "🏋️ 渐进超负荷原则：逐步增加重量或次数。",
    # ...
]

# ========== 工具函数 ==========
def random_select(lst):
    return random.choice(lst) if lst else ""

def contains_blacklisted(text):
    lower = text.lower()
    return any(kw.lower() in lower for kw in BLACKLIST)

def fetch_with_retry(url, max_retries=2, delay=2):
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
    }
    for i in range(max_retries + 1):
        try:
            resp = requests.get(url, headers=headers, timeout=15)
            if resp.status_code == 200:
                return resp
        except Exception:
            if i == max_retries:
                raise
            time.sleep(delay)
    return None

# ========== 抓取函数 ==========
def fetch_encouragements_from_web():
    results = []
    for url in QUOTE_SOURCES[:30]:
        time.sleep(0.8)
        try:
            resp = fetch_with_retry(url)
            if not resp:
                continue
            soup = BeautifulSoup(resp.text, 'html.parser')
            for el in soup.select('li, p, blockquote, .quote, .quote-text'):
                text = el.get_text(strip=True)
                if 15 < len(text) < 200 and not contains_blacklisted(text):
                    results.append(f"💪 {text}")
            if len(results) >= 100:
                break
        except Exception:
            continue
    return list(set(results))

def fetch_myths():
    results = []
    for url in QUOTE_SOURCES[:30]:
        time.sleep(1.2)
        try:
            resp = fetch_with_retry(url)
            if not resp:
                continue
            soup = BeautifulSoup(resp.text, 'html.parser')
            texts = []
            for el in soup.select('p, li, h2, h3'):
                text = el.get_text(strip=True)
                if 'myth' in text.lower() or '误区' in text or '迷思' in text:
                    if 15 < len(text) < 200:
                        texts.append(f"🧠 {text}")
            results.extend(texts)
            if len(results) >= 80:
                break
        except Exception:
            continue
    unique = list(set(results))[:60]
    return unique + PRESET_MYTHS

def fetch_protocols():
    results = []
    for url in QUOTE_SOURCES[:30]:
        time.sleep(1.2)
        try:
            resp = fetch_with_retry(url)
            if not resp:
                continue
            soup = BeautifulSoup(resp.text, 'html.parser')
            texts = []
            for el in soup.select('p, li'):
                text = el.get_text(strip=True)
                if 30 < len(text) < 200:
                    texts.append(f"🏋️ {text}")
            results.extend(texts)
            if len(results) >= 80:
                break
        except Exception:
            continue
    unique = list(set(results))[:60]
    return unique + PRESET_PROTOCOLS

def fetch_bing_facts():
    results = []
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
    for kw in CHINESE_KEYWORDS[:15]:
        time.sleep(2)
        try:
            url = f"https://www.bing.com/search?q={requests.utils.quote(kw)}&count=2"
            resp = session.get(url, timeout=15)
            if resp.status_code != 200:
                continue
            soup = BeautifulSoup(resp.text, 'html.parser')
            for p in soup.select('.b_caption p'):
                text = p.get_text(strip=True)
                if 40 < len(text) < 300:
                    results.append(f"📚 {text}")
        except Exception:
            continue
    return list(set(results))

def fetch_baidu_facts():
    results = []
    session = requests.Session()
    session.headers.update({'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
    for kw in CHINESE_KEYWORDS[:15]:
        time.sleep(2)
        try:
            url = f"https://www.baidu.com/s?wd={requests.utils.quote(kw)}&rn=2"
            resp = session.get(url, timeout=15)
            if resp.status_code != 200:
                continue
            soup = BeautifulSoup(resp.text, 'html.parser')
            for p in soup.select('.c-abstract'):
                text = p.get_text(strip=True)
                if 40 < len(text) < 300:
                    results.append(f"📚 {text}")
        except Exception:
            continue
    return list(set(results))

def fetch_pubmed_summaries():
    results = []
    session = requests.Session()
    for query in PUBMED_QUERIES[:10]:
        time.sleep(2)
        try:
            search_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term={requests.utils.quote(query)}&retmax=2&retmode=json&email={ENTREZ_EMAIL}"
            search_resp = session.get(search_url, timeout=25)
            if search_resp.status_code != 200:
                continue
            data = search_resp.json()
            ids = data.get('esearchresult', {}).get('idlist', [])
            if not ids:
                continue
            fetch_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id={','.join(ids)}&retmode=xml&email={ENTREZ_EMAIL}"
            fetch_resp = session.get(fetch_url, timeout=25)
            if fetch_resp.status_code != 200:
                continue
            root = ET.fromstring(fetch_resp.content)
            for article in root.findall('.//PubmedArticle'):
                title = article.find('.//ArticleTitle')
                title_text = title.text.strip() if title is not None and title.text else ''
                abstract_parts = []
                for abs_text in article.findall('.//AbstractText'):
                    if abs_text.text:
                        abstract_parts.append(abs_text.text.strip())
                abstract = ' '.join(abstract_parts)
                if title_text and abstract:
                    combined = f"{title_text}. {abstract}".replace('\n', ' ').replace('\r', ' ')
                    if 50 < len(combined) < 600:
                        results.append(f"🔬 {combined}")
        except Exception as e:
            print(f"PubMed error: {e}")
            continue
    return list(set(results))

def fetch_arxiv_research():
    results = []
    session = requests.Session()
    for query in ARXIV_QUERIES[:10]:
        time.sleep(2)
        try:
            url = f"http://export.arxiv.org/api/query?search_query=all:{requests.utils.quote(query)}&start=0&max_results=1"
            resp = session.get(url, timeout=20)
            if resp.status_code != 200:
                continue
            root = ET.fromstring(resp.content)
            for entry in root.findall('.//{http://www.w3.org/2005/Atom}entry'):
                title = entry.find('.//{http://www.w3.org/2005/Atom}title')
                summary = entry.find('.//{http://www.w3.org/2005/Atom}summary')
                title_text = title.text.strip().replace('\n', ' ') if title is not None and title.text else ''
                summary_text = summary.text.strip().replace('\n', ' ') if summary is not None and summary.text else ''
                if title_text and summary_text:
                    if len(summary_text) > 200:
                        summary_text = summary_text[:200] + '...'
                    results.append(f"🔬 {title_text}: {summary_text}")
        except Exception:
            continue
    return list(set(results))

def fetch_sciencedaily_rss():
    results = []
    try:
        url = "https://www.sciencedaily.com/rss/health_medicine/fitness.xml"
        resp = requests.get(url, timeout=20)
        if resp.status_code != 200:
            return []
        root = ET.fromstring(resp.content)
        for item in root.findall('.//item')[:10]:
            title = item.find('title')
            desc = item.find('description')
            title_text = title.text.strip() if title is not None and title.text else ''
            desc_text = desc.text.strip() if desc is not None and desc.text else ''
            if title_text and desc_text:
                import re
                clean_desc = re.sub(r'<[^>]*>', '', desc_text).replace('\n', ' ').strip()
                combined = f"{title_text}. {clean_desc}"
                if 50 < len(combined) < 500:
                    results.append(f"📰 {combined}")
    except Exception as e:
        print(f"ScienceDaily error: {e}")
    return results

def fetch_all_research():
    arxiv = fetch_arxiv_research()
    pubmed = fetch_pubmed_summaries()
    rss = fetch_sciencedaily_rss()
    return arxiv + pubmed + rss

def fetch_all_encouragements():
    web = fetch_encouragements_from_web()
    return web + PRESET_ENCOURAGEMENTS

def fetch_all_tips():
    quotes = fetch_encouragements_from_web()
    tips = []
    for s in quotes:
        if len(s) < 80:
            tips.append(s.replace('💪', '💡'))
    return tips + PRESET_TIPS

def fetch_all_facts():
    bing = fetch_bing_facts()
    baidu = fetch_baidu_facts()
    pubmed = fetch_pubmed_summaries()
    arxiv = fetch_arxiv_research()
    return bing + baidu + pubmed + arxiv + PRESET_FACTS

# ========== 主抓取入口 ==========
def fetch_all():
    print("开始抓取所有类别...")
    research = fetch_all_research()
    encouragements = fetch_all_encouragements()
    tips = fetch_all_tips()
    facts = fetch_all_facts()
    myths = fetch_myths()
    protocols = fetch_protocols()
    print(f"抓取结果: 研究{len(research)} 鼓励{len(encouragements)} 提示{len(tips)} 事实{len(facts)} 迷思{len(myths)} 方案{len(protocols)}")
    return {
        "scientific_facts": facts,
        "research_summaries": research,
        "myth_busters": myths,
        "training_protocols": protocols,
        "tips": tips,
        "encouragements": encouragements,
    }

# ========== 增量更新逻辑 ==========
def load_existing_data():
    if LOCAL_JSON_PATH.exists():
        with open(LOCAL_JSON_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def merge_data(existing, new):
    merged = {}
    for cat in ["scientific_facts", "research_summaries", "myth_busters",
                "training_protocols", "tips", "encouragements"]:
        existing_set = set(existing.get(cat, []))
        new_set = set(new.get(cat, []))
        merged[cat] = list(existing_set | new_set)
    return merged

def save_json(data):
    LOCAL_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(LOCAL_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[{datetime.now()}] JSON saved to {LOCAL_JSON_PATH}")

# ========== Git 推送逻辑 ==========
def git_commit_and_push():
    try:
        os.chdir(GIT_REPO_PATH)
        # 添加文件
        subprocess.run(["git", "add", str(LOCAL_JSON_PATH.relative_to(GIT_REPO_PATH))], check=True, capture_output=True)
        # 提交（如果没有变化则跳过）
        subprocess.run(["git", "commit", "-m", f"Auto update knowledge {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"], check=True, capture_output=True)
        # 推送
        subprocess.run(["git", "push", GIT_REMOTE_URL], check=True, capture_output=True)
        print(f"[{datetime.now()}] Git push successful")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[{datetime.now()}] Git push failed: {e}")
        return False

def push_with_retry():
    for attempt in range(1, MAX_RETRIES + 1):
        if git_commit_and_push():
            return True
        print(f"Push failed, retrying {attempt}/{MAX_RETRIES} in {RETRY_DELAY}s...")
        time.sleep(RETRY_DELAY)
    print("Push failed after maximum retries.")
    return False

# ========== 主循环 ==========
def main_loop():
    print("Knowledge updater started.")
    last_push_time = time.time()
    last_scrape_time = 0

    while True:
        now = time.time()
        if now - last_scrape_time >= SCRAPE_INTERVAL:
            print(f"[{datetime.now()}] Scraping...")
            new_data = fetch_all()
            existing_data = load_existing_data()
            merged_data = merge_data(existing_data, new_data)
            save_json(merged_data)
            last_scrape_time = now

        if now - last_push_time >= PUSH_INTERVAL:
            print(f"[{datetime.now()}] Attempting to push to GitHub...")
            push_with_retry()
            last_push_time = now

        time.sleep(60)

if __name__ == "__main__":
    main_loop()