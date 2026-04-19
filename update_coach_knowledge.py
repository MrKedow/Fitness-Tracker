#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
健身科学知识自动爬取与合并脚本（中文优先 + 百度/必应搜索 + 完整内容 + 自动剔除广告）
数据源：PubMed、arXiv、ScienceDaily（英文）
       百度搜索 + 必应搜索 + 知乎热榜/简书/RSSHub 多镜像 + 新增中文源
输出：更新 assets/coach_rules.json 中的 scientific_facts, research_summaries, myth_busters, training_protocols
新增：每次运行先根据自身屏蔽词列表剔除已有 JSON 中的广告条目，再执行抓取
"""

import json
import hashlib
import re
import time
import random
from pathlib import Path

import requests
import feedparser
from Bio import Entrez
from bs4 import BeautifulSoup

# ========== 配置 ==========
Entrez.email = "Ethocas@outlook.com"

# 百度搜索 URL
BAIDU_SEARCH_URL = "https://www.baidu.com/s"
# 必应搜索 URL
BING_SEARCH_URL = "https://cn.bing.com/search"

# RSSHub 镜像列表（降级使用）
RSSHUB_MIRRORS = [
    "https://rsshub.bili.xyz",
    "https://rsshub.sksren.com",
    "https://rsshub.uneasy.win",
]

# 英文源配置
ARXIV_QUERY = "ti:strength training OR ti:resistance training OR ti:muscle hypertrophy"
ARXIV_URL = "http://export.arxiv.org/api/query"
SCIENCEDAILY_RSS = "https://www.sciencedaily.com/rss/health_medicine/fitness.xml"

# 中文源 RSS 路径（扩充）
ZHIHU_HOT_PATH = "/zhihu/hotlist"
ZHIHU_TOPIC_PATH = "/zhihu/topic/19550923/hot"       # 健身话题
JIANSHU_PATH = "/jianshu/collection/59Zqsi"          # 简书健身专题
# 新增中文源（通过 RSSHub 获取）
SSPAI_PATH = "/sspai/tag/健身"                        # 少数派健身标签
JIKE_PATH = "/jike/topic/健身"                        # 即刻健身话题
XIUJUAN_PATH = "/xiujuan/健身"                       # 抽屉新热榜健身标签
CNBLOG_PATH = "/cnblogs/category/健身"                # 博客园健身分类
JUEJIN_PATH = "/juejin/tag/健身"                     # 掘金健身标签
CSDN_PATH = "/csdn/blogs/健身"                       # CSDN 健身博客
DOUBAN_PATH = "/douban/group/健身"                   # 豆瓣健身小组
HUANGLIU_PATH = "/huangliu/健身"                     # 黄流（备用）
MEIRIYI_PATH = "/meiriyi/健身"                       # 每日壹（备用）

# 本地 JSON 文件路径
JSON_PATH = Path(__file__).parent / "assets/coach_rules.json"

# 抓取数量限制
MAX_RESULTS_PER_SOURCE = 100
MAX_CHINESE_SEARCH = 100   # 每个搜索引擎获取的结果数

# 营销号关键词黑名单（可手动编辑）
BLACKLIST_KEYWORDS = [
    "click here", "buy now", "discount", "miracle", "guaranteed", "ad", "sponsored", "promotion", "sale", "limited time", "exclusive", "new release",
    "affiliate", "sponsored", "advertisement", "产品", "促销", "代理",
    "点击", "购买", "优惠", "神奇", "保证", "广告", "赞助", "影视剧", "小说", "漫画", "游戏", "娱乐", "八卦", "明星", "网红", "影视",
    "测评", "推荐", "选购", "百度百科", "辭典", "檢視", "康复", "字典", "释义", "意思", "是什么", "怎么吃", "方法", "步骤", "教程", "指南", "方案", "计划",
    "excellent", "amazing", "incredible", "unbelievable", "best", "worst", "top", "review", "comparison", "评测", "对比", "排行榜", "最佳", "最差", "神评", "测评", "对比", "排行榜", "最佳", "最差",
    "张雪峰", "免费", "免费试用", "试用装", "限时", "限量", "独家", "首发", "新品", "开箱", "开箱视频", "开箱测评", "开箱评测", "开箱对比", "开箱推荐", "开箱指南", "开箱教程", "开箱方案", "开箱计划",
    "娱乐圈", "影视圈", "明星八卦", "网红八卦", "娱乐八卦", "影视八卦", "明星绯闻", "网红绯闻", "娱乐绯闻", "影视绯闻", "明星新闻", "网红新闻", "娱乐新闻", "影视新闻",
    "京东", "好物", "畅游", "运动户外", "天猫运动户外", "拼多多运动户外", "亚马逊运动户外", "苏宁易购运动户外", "唯品会运动户外", "国美在线运动户外", "当当网运动户外", "小米有品运动户外",
    "特价", "限时抢购", "秒杀", "包邮", "满减", "领券", "优惠券", "折扣券", "代金券", "拼团", "砍价", "免单", "返现", "赠品", "买一送一", "第二件半价",
    "热卖", "爆款", "销量第一", "好评如潮", "口碑爆棚", "网红同款", "明星代言", "主播推荐", "小红书同款", "抖音爆款", "快手精选", "淘宝热销", "京东自营", "天猫旗舰",
    "拼多多百亿补贴", "苏宁自营", "唯品会特卖", "网易严选", "小米有品", "华为商城", "OPPO商城", "vivo商城", "荣耀商城", "三星商城", "苹果官网", "官方旗舰",
    "正品保障", "假一赔十", "七天无理由", "运费险", "极速退款", "破损包赔", "闪电发货", "次日达", "当日达", "隔日达", "顺丰包邮", "京东快递", "菜鸟裹裹", "邮政包裹",
    "物流跟踪", "开箱验货", "货到付款", "分期付款", "白条免息", "花呗分期", "信用卡支付", "微信支付", "支付宝红包", "云闪付", "银联优惠", "银行活动", "积分兑换",
    "会员专享", "VIP特价", "黑卡会员", "钻石会员", "超级会员", "京东PLUS", "淘宝88VIP", "拼多多省钱月卡", "美团会员", "饿了么会员", "肯德基大神卡", "麦当劳OH麦卡",
    "星巴克星享卡", "瑞幸咖啡券", "喜茶会员", "奈雪会员", "茶颜悦色充值", "海底捞黑海", "必胜客尊享卡", "沃尔玛会员", "山姆卓越卡", "Costco会员", "宜家会员",
    "迪卡侬会员", "安踏会员", "李宁会员", "耐克会员", "阿迪达斯会员", "彪马会员", "斐乐会员", "斯凯奇会员", "匡威会员", "万斯会员", "新百伦会员", "亚瑟士会员",
    "美津浓会员", "安德玛会员", "露露柠檬会员", "始祖鸟会员", "北面会员", "哥伦比亚会员", "狼爪会员", "探路者会员", "凯乐石会员", "牧高笛会员", "骆驼会员",
    "奥索卡会员", "诺诗兰会员", "土拨鼠会员", "猛犸象会员", "巴塔哥尼亚会员", "火柴棍会员", "攀山鼠会员", "老人头会员", "北极狐会员", "神秘农场会员", "花岗岩会员",
    "格里高利会员", "鱼鹰会员", "多特会员", "沃德会员", "三夫会员", "绿野会员", "户外特工", "户外帮", "户外探险", "户外装备", "户外用品", "登山杖", "帐篷", "睡袋",
    "防潮垫", "头灯", "手电", "炉头", "套锅", "水袋", "净水器", "急救包", "户外手表", "登山鞋", "徒步鞋", "越野跑鞋", "溯溪鞋", "攀岩鞋", "滑雪板", "滑雪镜", "滑雪服",
    "冲浪板", "潜水镜", "救生衣", "瑜伽垫", "瑜伽服", "健身手套", "护腰带", "护膝", "护肘", "护腕", "髌骨带", "压力袜", "压缩衣", "速干衣", "跑步腰包", "运动水壶",
    "蛋白粉", "肌酸", "支链氨基酸", "氮泵", "左旋肉碱", "共轭亚油酸", "维生素", "矿物质", "益生菌", "鱼油", "氨糖", "胶原蛋白", "蛋白棒", "能量胶", "盐丸", "运动饮料",
    "电解质", "椰子水", "功能饮料", "红牛", "魔爪", "东鹏特饮", "乐虎", "战马", "卡拉宝", "力保健", "日加满", "体质能量", "黑卡", "外星人", "元气森林", "燃力士",
    "醒着拼", "焕醒源", "神采", "迈胜", "康比特", "诺特兰德", "肌肉科技", "欧普特蒙", "奥赛德斯", "熊猫粉", "北欧海盗", "海德力", "迪马泰斯", "BSN", "GNC", "健安喜",
    "汤臣倍健", "善存", "钙尔奇", "养生堂", "康恩贝", "健康元", "江中", "仁和", "修正", "葵花", "哈药", "三九", "白云山", "同仁堂", "云南白药", "片仔癀", "东阿阿胶",
    "九芝堂", "太极", "桐君阁", "胡庆余堂", "雷允上", "陈李济", "潘高寿", "敬修堂", "王老吉", "加多宝", "和其正", "维他奶", "六个核桃", "露露", "银鹭", "娃哈哈",
    "农夫山泉", "怡宝", "康师傅", "统一", "可口可乐", "百事可乐", "雪碧", "芬达", "美年达", "七喜", "激浪",
    "速看", "慎入", "深度好文", "必读", "收藏", "转发", "扩散", "感恩", "感动", "泪目", "看完沉默", "看哭", "扎心", "暖心", "正能量", "负能量", "鸡汤", "毒鸡汤",
    "反鸡汤", "清醒", "励志", "逆袭", "翻身", "成功学", "厚黑学", "潜规则", "职场法则", "人际关系", "说话技巧", "情商课", "智商税", "韭菜", "收割", "套路", "陷阱",
    "揭秘", "内幕", "潜藏", "隐藏", "不为人知", "惊人", "震惊", "吓尿", "跪了", "服了", "厉害了", "我的哥", "我的姐", "我的天", "我的神", "我的佛", "我的主", "我的妈",
    "我的爸", "我的爷", "我的奶", "我的舅", "我的叔", "我的姨", "我的姑", "我的婶", "我的侄", "我的甥", "我的孙", "我的曾", "我的祖", "我的宗", "我的族", "我的家",
    "我的国", "我的城", "我的乡", "我的村", "我的店", "我的厂", "我的司", "我的部", "我的局", "我的委", "我的办", "我的院", "我的所", "我的站", "我的台", "我的网",
    "我的云", "我的端", "我的机", "我的器", "我的具", "我的材", "我的料", "我的药", "我的方", "我的法", "我的术", "我的道", "我的理", "我的论", "我的说", "我的讲",
    "我的谈", "我的议", "我的评", "我的论", "我的辩", "我的证", "我的明", "我的确", "我的实", "我的真", "我的假", "我的虚", "我的幻", "我的梦", "我的想", "我的念",
    "我的思", "我的虑", "我的忧", "我的愁", "我的悲", "我的喜", "我的乐", "我的怒", "我的哀", "我的惧", "我的爱", "我的恨", "我的情", "我的欲", "我的求", "我的得",
    "我的失", "我的成", "我的败", "我的赢", "我的输", "我的利", "我的害", "我的福", "我的祸", "我的吉", "我的凶", "我的生", "我的死", "我的存", "我的亡", "我的兴",
    "我的衰", "我的盛", "我的弱", "我的强", "我的大", "我的小", "我的多", "我的少", "我的长", "我的短", "我的高", "我的低", "我的深", "我的浅", "我的宽", "我的窄",
    "我的厚", "我的薄", "我的重", "我的轻", "我的硬", "我的软", "我的干", "我的湿", "我的热", "我的冷", "我的明", "我的暗", "我的亮", "我的黑", "我的白", "我的红",
    "我的绿", "我的蓝", "我的黄", "我的紫", "我的青", "我的橙", "我的粉", "我的灰", "我的棕", "我的褐", "我的银", "我的金", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁", "我的锡", "我的铅",
    "我的锌", "我的镍", "我的钴", "我的锰", "我的铬", "我的钒", "我的钛", "我的钼", "我的钨", "我的铀", "我的钚", "我的镭", "我的锕", "我的镧", "我的铈", "我的镨",
    "我的钕", "我的钷", "我的钐", "我的铕", "我的钆", "我的铽", "我的镝", "我的钬", "我的铒", "我的铥", "我的镱", "我的镥", "我的钪", "我的钇", "我的锆", "我的铪",
    "我的钽", "武器", "高德", "高启盛", "狂飙", "高铁", "哥哥", "国学", "组词", "我的铌", "我的钒", "我的铬", "我的钼", "我的钨", "我的铼", "我的锇", "我的铱", "我的铂", "我的金", "我的银", "我的铜", "我的铁",
    "click here", "buy now", "discount", "miracle", "guaranteed", "ad", "sponsored", "promotion", "sale", "limited time", "exclusive", "new release", "affiliate", "advertisement", "excellent", "amazing", "incredible", "unbelievable", "best", "worst", "top", "review", "comparison", "free", "free trial", "trial offer", "risk free", "money back", "satisfaction guaranteed", "no questions asked", "hurry", "limited offer", "act now", "order now", "subscribe now", "click now", "download now", "install now", "get it now", "shop now", "buy now", "sign up now", "register now", "join now", "start now", "learn more", "read more", "see more", "find out more", "discover more", "explore more", "watch now", "listen now", "try now", "test now", "claim now", "reserve now", "book now", "donate now", "vote now", "enter now", "apply now", "enroll now", "enlist now", "enquire now", "contact us", "call now", "text now", "message now", "chat now", "live chat", "24/7", "24 hours", "anytime", "anywhere", "worldwide", "global", "international", "shipping", "free shipping", "fast shipping", "express shipping", "overnight shipping", "same day shipping", "next day shipping", "international shipping", "worldwide shipping", "free delivery", "fast delivery", "express delivery", "overnight delivery", "same day delivery", "next day delivery", "clickbank", "amazon", "ebay", "walmart", "target", "best buy", "etsy", "alibaba", "aliexpress", "wish", "shopify", "paypal", "stripe", "square", "venmo", "cash app", "bitcoin", "crypto", "cryptocurrency", "forex", "trading", "invest", "investment", "investor", "stock", "stocks", "option", "options", "future", "futures", "commodity", "commodities", "forex trading", "binary options", "cryptocurrency trading", "day trading", "swing trading", "scalping", "make money", "earn money", "passive income", "work from home", "home business", "online business", "internet marketing", "digital marketing", "affiliate marketing", "network marketing", "multi level marketing", "mlm", "pyramid", "scheme", "get rich", "wealth", "fortune", "success", "prosperity", "abundance", "manifest", "law of attraction", "secret", "hidden secret", "revealed", "unveiled", "exposed", "truth", "real truth", "shocking truth", "shocking", "mind blowing", "eye opening", "life changing", "game changing", "revolutionary", "breakthrough", "discovery", "invention", "innovation", "cutting edge", "state of the art", "advanced", "patented", "proven", "scientific", "clinically proven", "doctor recommended", "expert recommended", "top rated", "award winning", "bestseller", "bestselling", "trending", "viral", "popular", "famous", "celebrity", "celebrity endorsed", "influencer", "influencer endorsed", "as seen on", "as featured in", "as heard on", "tv", "television", "cnn", "bbc", "fox", "nbc", "abc", "cbs", "msnbc", "ny times", "wall street journal", "forbes", "entrepreneur", "inc", "business insider", "huffpost", "buzzfeed", "upworthy", "vice", "vox", "medium", "quora", "reddit", "twitter", "facebook", "instagram", "tiktok", "youtube", "linkedin", "pinterest", "snapchat", "whatsapp", "telegram", "wechat", "weibo", "qq", "line", "vk", "discord", "twitch", "periscope", "flickr", "tumblr", "myspace", "friendster", "orkut", "google plus", "google", "bing", "yahoo", "aol", "ask", "duckduckgo", "baidu", "yandex", "naver", "seznam", "ecosia", "qwant", "wolfram alpha", "webmd", "mayoclinic", "healthline", "medical news today", "verywell health", "health", "fitness", "wellness", "nutrition", "diet", "weight loss", "lose weight", "burn fat", "belly fat", "fat burner", "metabolism booster", "appetite suppressant", "detox", "cleanse", "juice cleanse", "smoothie diet", "keto", "ketogenic", "paleo", "vegan", "vegetarian", "gluten free", "dairy free", "sugar free", "low carb", "low fat", "low calorie", "high protein", "protein packed", "nutrient dense", "superfood", "antioxidant", "probiotic", "prebiotic", "digestive health", "immune support", "brain health", "heart health", "joint health", "bone health", "skin health", "hair health", "nail health", "anti aging", "age defying", "youthful", "rejuvenate", "revitalize", "restore", "repair", "heal", "recover", "regenerate", "renew", "refresh", "energize", "boost", "enhance", "optimize", "maximize", "supercharge", "turbocharge", "amplify", "intensify", "accelerate", "fast track", "kickstart", "jumpstart", "ignite", "activate", "unlock", "release", "trigger", "stimulate", "invigorate", "awaken", "enlighten", "empower", "transform", "change", "improve", "upgrade", "update", "refine", "perfect", "master", "dominate", "conquer", "overcome", "beat", "defeat", "win", "victory", "triumph", "champion", "legend", "hero", "guru", "ninja", "rockstar", "superstar", "megastar", "all star", "hall of fame", "legendary", "iconic", "epic", "awesome", "fantastic", "fabulous", "terrific", "tremendous", "extraordinary", "exceptional", "remarkable", "outstanding", "superb", "superior", "supreme", "ultimate", "paramount", "premier", "prime", "primary", "leading", "foremost", "number one", "one of a kind", "unique", "unparalleled", "unmatched", "unrivaled", "unequaled", "peerless", "matchless", "incomparable", "second to none", "the best", "the finest", "the greatest", "the most", "the only", "the real", "the true", "authentic", "genuine", "original", "official", "authorized", "licensed", "certified", "accredited", "verified", "validated", "confirmed", "proved", "demonstrated", "shown", "observed", "documented", "recorded", "published", "peer reviewed", "studied", "researched", "analyzed", "evaluated", "assessed", "tested", "trialled", "experimented", "clinical trial", "double blind", "placebo controlled", "randomized", "controlled study", "case study", "case report", "case series", "systematic review", "meta analysis", "evidence based", "science based", "data driven", "fact based", "real world", "real life", "practical", "actionable", "usable", "applicable", "relevant", "meaningful", "significant", "substantial", "considerable", "notable", "noticeable", "perceptible", "measurable", "quantifiable", "tangible", "concrete", "solid", "strong", "powerful", "potent", "effective", "efficacious", "efficient", "productive", "fruitful", "profitable", "lucrative", "rewarding", "beneficial", "advantageous", "helpful", "useful", "valuable", "worthwhile", "worthy", "deserving", "meritorious", "laudable", "praiseworthy", "commendable", "admirable", "respectable", "honorable", "noble", "virtuous", "righteous", "good", "great", "fine", "nice", "pleasant", "enjoyable", "delightful", "wonderful", "marvelous", "splendid", "magnificent", "glorious", "sublime", "exquisite", "elegant", "graceful", "beautiful", "lovely", "charming", "attractive", "appealing", "engaging", "captivating", "enchanting", "mesmerizing", "hypnotic", "entrancing", "spellbinding", "riveting", "gripping", "compelling", "persuasive", "convincing", "forceful", "potent", "dynamic", "vibrant", "lively", "energetic", "vigorous", "robust", "sturdy", "durable", "resilient", "tough", "hardy", "strong", "powerful", "mighty", "herculean", "massive", "huge", "enormous", "immense", "colossal", "gigantic", "titanic", "monumental", "epic", "grand", "great", "big", "large", "vast", "wide", "broad", "expansive", "extensive", "comprehensive", "thorough", "exhaustive", "complete", "full", "total", "absolute", "utter", "perfect", "flawless", "impeccable", "faultless", "ideal", "optimal", "optimum", "perfect", "prime", "peak", "summit", "pinnacle", "apex", "zenith", "acme", "crown", "crest", "top", "highest", "maximum", "utmost", "supreme", "paramount", "overriding", "dominant", "prevailing", "prevalent", "common", "frequent", "recurring", "persistent", "constant", "continuous", "uninterrupted", "unbroken", "steady", "stable", "consistent", "uniform", "even", "level", "flat", "smooth", "calm", "peaceful", "serene", "tranquil", "quiet", "still", "silent", "noiseless", "soundless", "mute", "dumb", "speechless", "wordless", "voiceless", "unspoken", "unsaid", "unuttered", "unexpressed", "untold", "unrevealed", "undisclosed", "unpublished", "unreleased", "unavailable", "inaccessible", "unobtainable", "unreachable", "unattainable", "unachievable", "impossible", "impractical", "unrealistic", "unfeasible", "infeasible", "unworkable", "unviable", "unsustainable", "untenable", "unmaintainable", "undependable", "unreliable", "untrustworthy", "dishonest", "deceptive", "misleading", "false", "untrue", "inaccurate", "incorrect", "wrong", "erroneous", "flawed", "defective", "faulty", "imperfect", "incomplete", "partial", "limited", "restricted", "constrained", "confined", "bounded", "finite", "mortal", "mortal", "temporary", "transient", "ephemeral", "fleeting", "short lived", "brief", "momentary", "instant", "immediate", "direct", "prompt", "swift", "quick", "fast", "rapid", "speedy", "hasty", "hurried", "rushed", "urgent", "pressing", "critical", "crucial", "vital", "essential", "necessary", "required", "mandatory", "compulsory", "obligatory", "forced", "involuntary", "unwilling", "reluctant", "hesitant", "uncertain", "doubtful", "questionable", "suspicious", "shady", "fishy", "sketchy", "dodgy", "sleazy", "seedy", "grubby", "sordid", "squalid", "shabby", "cheap", "tacky", "gaudy", "garish", "flashy", "showy", "ostentatious", "pretentious", "affected", "artificial", "fake", "counterfeit", "forged", "fraudulent", "bogus", "phony", "sham", "spurious", "false", "misleading", "deceitful", "dishonest", "untruthful", "lying", "mendacious", "perjurious", "fabricated", "manufactured", "invented", "fictitious", "imaginary", "mythical", "legendary", "fabled", "apocryphal", "unsubstantiated", "unconfirmed", "unverified", "uncorroborated", "unattested", "unproven", "unsupported", "unfounded", "baseless", "groundless", "unwarranted", "unjustified", "unsound", "weak", "flimsy", "tenuous", "slight", "insubstantial", "inadequate", "insufficient", "deficient", "lacking", "wanting", "short", "scarce", "rare", "uncommon", "infrequent", "sporadic", "occasional", "intermittent", "irregular", "erratic", "uneven", "patchy", "spotty", "inconsistent", "variable", "changeable", "fluctuating", "volatile", "unstable", "unsettled", "turbulent", "stormy", "tempestuous", "rough", "choppy", "bumpy", "jolting", "shaky", "wobbly", "rickety", "unsteady", "precarious", "dangerous", "hazardous", "risky", "perilous", "dicey", "chancy", "touchy", "tricky", "delicate", "sensitive", "fragile", "brittle", "crispy", "crumbly", "flaky", "powdery", "dusty", "sandy", "gritty", "granular", "coarse", "rough", "scratchy", "raspy", "harsh", "severe", "intense", "extreme", "radical", "drastic", "dramatic", "sudden", "abrupt", "sharp", "steep", "precipitous", "sheer", "vertical", "upright", "erect", "standing", "vertical", "straight", "linear", "direct", "shortest", "quickest", "fastest", "easiest", "simplest", "most convenient", "most efficient", "most effective", "most powerful", "most reliable", "most trustworthy", "most honest", "most genuine", "most authentic", "most original", "most unique", "most innovative", "most advanced", "most cutting edge", "most state of the art", "most revolutionary", "most groundbreaking", "most phenomenal", "most spectacular", "most impressive", "most stunning", "most breathtaking", "most awe inspiring", "most incredible", "most unbelievable", "most amazing", "most astonishing", "most astounding", "most remarkable", "most extraordinary", "most exceptional", "most outstanding", "most superb", "most magnificent", "most glorious", "most splendid", "most wonderful", "most marvelous", "most fantastic", "most fabulous", "most terrific", "most tremendous", "most excellent", "most perfect", "most flawless", "most impeccable", "most ideal", "most optimal", "most supreme", "most ultimate", "most paramount", "most preeminent", "most dominant", "most prevailing", "most powerful", "most mighty", "most potent", "most dynamic", "most vibrant", "most energetic", "most vigorous", "most robust", "most sturdy", "most durable", "most resilient", "most tough", "most hardy", "most strong", "most massive", "most huge", "most enormous", "most immense", "most colossal", "most gigantic", "most titanic", "most monumental", "most epic", "most grand", "most great", "most big", "most large", "most vast", "most wide", "most broad", "most expansive", "most extensive", "most comprehensive", "most thorough", "most exhaustive", "most complete", "most full", "most total", "most absolute", "most utter", "most perfect", "most flawless", "most impeccable", "most ideal", "most optimal", "most prime", "most peak", "most summit", "most pinnacle", "most apex", "most zenith", "most acme", "most crown", "most crest", "most top", "most highest", "most maximum", "most utmost", "most supreme", "most paramount", "most overriding", "most dominant", "most prevailing", "most prevalent", "most common", "most frequent", "most recurring", "most persistent", "most constant", "most continuous", "most uninterrupted", "most unbroken", "most steady", "most stable", "most consistent", "most uniform", "most even", "most level", "most flat", "most smooth", "most calm", "most peaceful", "most serene", "most tranquil", "most quiet", "most still", "most silent"
]
# 请求头
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

# ========== 工具函数 ==========
def hash_text(text):
    return hashlib.md5(text.encode("utf-8")).hexdigest()

def is_quality_text(text, min_len=30):
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

def shorten_text(text, max_len=200):
    """智能缩短文本，保留完整句子，用于谚语、经验总结"""
    if len(text) <= max_len:
        return text
    # 寻找句尾符号
    for sep in ['.', '!', '?', '。', '！', '？', '；', ';', '，', ',', ' ']:
        pos = text.find(sep, max_len//2, max_len)
        if pos != -1:
            return text[:pos+1].strip()
    return text[:max_len].strip() + "..."

def load_existing_hashes(json_path, categories):
    if not json_path.exists():
        return set()
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    hashes = set()
    for cat in categories:
        if cat in data:
            for item in data[cat]:
                if isinstance(item, str):
                    hashes.add(hash_text(item))
    return hashes

def remove_blacklisted_entries(json_path):
    """根据 BLACKLIST_KEYWORDS 删除 JSON 中包含屏蔽词的条目"""
    if not json_path.exists():
        print("⚠️ coach_rules.json 不存在，跳过清理步骤")
        return
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    removed_count = 0
    for category in ["scientific_facts", "research_summaries", "myth_busters", "training_protocols"]:
        if category not in data:
            continue
        original = data[category]
        filtered = []
        for item in original:
            text = item if isinstance(item, str) else item.get("text", "")
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
    existing_hashes = {hash_text(item) for item in data[category] if isinstance(item, str)}
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

# ========== 百度搜索抓取 ==========
def fetch_baidu_search(keyword, max_results=5):
    """使用百度搜索获取结果标题和摘要"""
    results = []
    try:
        params = {
            "wd": keyword,
            "pn": 0,
            "rn": max_results
        }
        resp = requests.get(BAIDU_SEARCH_URL, params=params, headers=HEADERS, timeout=10)
        if resp.status_code != 200:
            print(f"    百度搜索失败，状态码：{resp.status_code}")
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
            # 限制长度，适应谚语/经验
            combined = shorten_text(combined, max_len=200)
            if len(combined) > 200:
                combined = combined[:200] + "……"
            if is_quality_text(combined, min_len=30):
                results.append(combined)
            if len(results) >= max_results:
                break
        time.sleep(1)
    except Exception as e:
        print(f"    百度搜索异常: {e}")
    return results

# ========== 必应搜索抓取 ==========
def fetch_bing_search(keyword, max_results=5):
    """使用必应搜索获取结果标题和摘要"""
    results = []
    try:
        params = {
            "q": keyword,
            "count": max_results,
            "setlang": "zh-Hans"
        }
        resp = requests.get(BING_SEARCH_URL, params=params, headers=HEADERS, timeout=10)
        if resp.status_code != 200:
            print(f"    必应搜索失败，状态码：{resp.status_code}")
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
            combined = shorten_text(combined, max_len=200)
            if len(combined) > 200:
                combined = combined[:200] + "……"
            if is_quality_text(combined, min_len=30):
                results.append(combined)
            if len(results) >= max_results:
                break
        time.sleep(1)
    except Exception as e:
        print(f"    必应搜索异常: {e}")
    return results

# ========== 中文搜索引擎综合抓取（通用）==========
def fetch_chinese_search_results(keywords, max_results=5, prefix_query="健身 科学"):
    """综合百度+必应搜索结果，支持自定义查询后缀"""
    all_results = []
    for kw in keywords:
        print(f"    搜索关键词：{kw}")
        baidu_items = fetch_baidu_search(f"{kw} {prefix_query}", max_results=max_results//2)
        bing_items = fetch_bing_search(f"{kw} {prefix_query}", max_results=max_results//2)
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

# ========== 通用 RSS 抓取（降级）==========
def fetch_rss_feed(path, max_items=5, prefix=""):
    for mirror in RSSHUB_MIRRORS:
        try:
            url = f"{mirror}{path}"
            resp = requests.get(url, timeout=10)
            if resp.status_code != 200:
                continue
            feed = feedparser.parse(resp.text)
            items = []
            for entry in feed.entries[:max_items]:
                title = entry.title.strip()
                text = f"{prefix}{title}" if prefix else title
                text = clean_text(text)
                text = shorten_text(text, max_len=200)
                if is_quality_text(text, min_len=15):
                    items.append(text)
            if items:
                return items
        except Exception:
            continue
    return []

# 定义多个中文源抓取函数
def fetch_zhihu_hot(max_items=5):
    return fetch_rss_feed(ZHIHU_HOT_PATH, max_items, "知乎热议：")

def fetch_zhihu_topic(max_items=5):
    return fetch_rss_feed(ZHIHU_TOPIC_PATH, max_items, "知乎健身话题：")

def fetch_jianshu(max_items=5):
    return fetch_rss_feed(JIANSHU_PATH, max_items, "简书健身：")

def fetch_sspai(max_items=5):
    return fetch_rss_feed(SSPAI_PATH, max_items, "少数派健身：")

def fetch_jike(max_items=5):
    return fetch_rss_feed(JIKE_PATH, max_items, "即刻健身：")

def fetch_xiujuan(max_items=5):
    return fetch_rss_feed(XIUJUAN_PATH, max_items, "抽屉健身：")

def fetch_cnblog(max_items=5):
    return fetch_rss_feed(CNBLOG_PATH, max_items, "博客园健身：")

def fetch_juejin(max_items=5):
    return fetch_rss_feed(JUEJIN_PATH, max_items, "掘金健身：")

def fetch_csdn(max_items=5):
    return fetch_rss_feed(CSDN_PATH, max_items, "CSDN健身：")

def fetch_douban(max_items=5):
    return fetch_rss_feed(DOUBAN_PATH, max_items, "豆瓣健身：")

# ========== 英文数据源（保留完整内容，但 myth_busters 也需简短）==========
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
        params = {
            "search_query": query,
            "start": 0,
            "max_results": max_results,
            "sortBy": "submittedDate",
            "sortOrder": "descending"
        }
        resp = requests.get(ARXIV_URL, params=params, timeout=10)
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

# ========== 主流程 ==========
def main():
    print("🚀 开始执行健身科学知识更新任务...")

    # 第一步：根据最新的屏蔽词列表清理已有 JSON
    print("\n🧹 清理 JSON 中的广告/屏蔽词条目...")
    remove_blacklisted_entries(JSON_PATH)

    # 第二步：加载现有知识哈希（用于去重）
    categories = ["scientific_facts", "research_summaries", "myth_busters", "training_protocols"]
    existing_hashes = load_existing_hashes(JSON_PATH, categories)
    print(f"📚 已加载 {len(existing_hashes)} 条现有知识哈希")

    seen = set()
    all_facts = []          # scientific_facts
    all_research = []       # research_summaries
    all_myths = []          # myth_busters
    all_protocols = []      # training_protocols

    # ----- 1. 中文搜索引擎抓取（针对不同类别）-----
    # 1.1 科学事实（常规抓取，保留较多内容）
    print("\n🌐 使用百度+必应搜索中文健身科学知识（科学事实）...")
    chinese_keywords = [
        "运动营养", "力量训练 研究", "肌肉增长 科学", "高强度间歇训练 效果",
        "健身 误区", "运动恢复 最新", "抗阻训练 进展", "健身 科学研究"
    ]
    chinese_search_results = fetch_chinese_search_results(chinese_keywords, max_results=MAX_CHINESE_SEARCH)
    for item in chinese_search_results:
        h = hash_text(item)
        if h not in existing_hashes and h not in seen:
            seen.add(h)
            all_facts.append(item)
    print(f"  科学事实共获得 {len(chinese_search_results)} 条新内容")

    # 1.2 打破迷思（简短谚语、结论）
    print("\n🔍 抓取健身迷思与真相（myth_busters）...")
    myth_keywords = [
        "健身谣言", "健身误区 真相", "健身骗局", "肌肉 误解", "减肥 谎言",
        "健身 常识 纠正", "运动 误区", "健康 迷思", "饮食 误区"
    ]
    myth_results = fetch_chinese_search_results(myth_keywords, max_results=50, prefix_query="")
    for item in myth_results:
        # 确保简短
        short = shorten_text(item, max_len=150)
        h = hash_text(short)
        if h not in existing_hashes and h not in seen:
            seen.add(h)
            all_myths.append(short)
    print(f"  打破迷思共获得 {len(myth_results)} 条新内容")

    # 1.3 训练方案（简短经验、建议）
    print("\n🏋️ 抓取训练方案/经验（training_protocols）...")
    protocol_keywords = [
        "健身 经验", "训练 技巧", "增肌 秘诀", "减脂 方法", "健身 计划 推荐",
        "力量训练 建议", "有氧 技巧", "健身 大神 经验", "训练 法则"
    ]
    protocol_results = fetch_chinese_search_results(protocol_keywords, max_results=50, prefix_query="")
    for item in protocol_results:
        short = shorten_text(item, max_len=150)
        h = hash_text(short)
        if h not in existing_hashes and h not in seen:
            seen.add(h)
            all_protocols.append(short)
    print(f"  训练方案共获得 {len(protocol_results)} 条新内容")

    # ----- 2. 备用中文 RSS 源（扩充数量）-----
    print("\n📡 抓取扩展中文 RSS 源...")
    chinese_rss_sources = [
        ("知乎热榜", fetch_zhihu_hot),
        ("知乎健身话题", fetch_zhihu_topic),
        ("简书健身", fetch_jianshu),
        ("少数派健身", fetch_sspai),
        ("即刻健身", fetch_jike),
        ("抽屉健身", fetch_xiujuan),
        ("博客园健身", fetch_cnblog),
        ("掘金健身", fetch_juejin),
        ("CSDN健身", fetch_csdn),
        ("豆瓣健身", fetch_douban),
    ]
    for name, func in chinese_rss_sources:
        print(f"  抓取 {name}...")
        items = func(MAX_CHINESE_SEARCH // 2)  # 每个源抓取较少条目，避免过多重复
        for item in items:
            h = hash_text(item)
            if h not in existing_hashes and h not in seen:
                seen.add(h)
                # 简单分类：将 RSS 标题放入科学事实（因为内容较杂），也可以单独处理，这里统一放入科学事实
                all_facts.append(item)
        print(f"    获得 {len(items)} 条")

    # ----- 3. 英文源（科学事实和研究总结）-----
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
        if h not in existing_hashes and h not in seen:
            seen.add(h)
            all_facts.append(f)
    print(f"  从 PubMed 获得 {len(pubmed_facts)} 条新科学事实")

    print("\n📑 抓取 arXiv...")
    arxiv_research = fetch_arxiv(ARXIV_QUERY, max_results=MAX_RESULTS_PER_SOURCE)
    for a in arxiv_research:
        h = hash_text(a)
        if h not in existing_hashes and h not in seen:
            seen.add(h)
            all_research.append(a)
    print(f"  从 arXiv 获得 {len(arxiv_research)} 条新研究总结")

    print("\n📰 抓取 ScienceDaily RSS...")
    sd_facts = fetch_sciencedaily_rss(max_items=MAX_RESULTS_PER_SOURCE)
    for sd in sd_facts:
        h = hash_text(sd)
        if h not in existing_hashes and h not in seen:
            seen.add(h)
            all_facts.append(sd)
    print(f"  从 ScienceDaily 获得 {len(sd_facts)} 条新科学事实")

    # ----- 4. 合并到 JSON -----
    if all_facts:
        append_to_json(JSON_PATH, "scientific_facts", all_facts)
    if all_research:
        append_to_json(JSON_PATH, "research_summaries", all_research)
    if all_myths:
        append_to_json(JSON_PATH, "myth_busters", all_myths)
    if all_protocols:
        append_to_json(JSON_PATH, "training_protocols", all_protocols)

    print("\n🎉 更新完成！")

if __name__ == "__main__":
    main()