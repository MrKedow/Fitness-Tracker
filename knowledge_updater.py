#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
from pathlib import Path
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
import re

# ========== 配置区域 ==========
LOCAL_JSON_PATH = Path("assets/coach_rules.json")
SECONDARY_JSON_PATH = Path(r"C:\Users\Ethoc\Documents\GitHub\Fitness-Tracker_Windows-Dev\Fitness-Tracker\assets\coach_rules.json")
GIT_REPO_PATH = Path(".")  # 当前目录即为 Git 仓库根目录
# 远程仓库 URL（使用 HTTPS + Personal Access Token）
GIT_REMOTE_URL = "https://github.com/MrKedow/Fitness-Tracker.git"
SCRAPE_INTERVAL = 3600
# Git 推送间隔（秒）—— 10 小时
PUSH_INTERVAL = 5400
# 推送失败最大重试次数
MAX_RETRIES = 50
# 重试间隔（秒）
RETRY_DELAY = 30
# 坚果云 WebDAV 配置（可选，用于抓取 PubMed/arXiv 时可能用到）
ENTREZ_EMAIL = "Ethocas@outlook.com"
# 在配置区域之后添加
if not (GIT_REPO_PATH / ".git").exists():
    print(
        "Error: Current directory is not a Git repository. Please run the script from the project root."
    )
    sys.exit(1)
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
    "https://www.acefitness.org/education-and-resources/lifestyle/blog/6730/debunking-common-fitness-myths/",
    "https://www.healthline.com/nutrition/20-fitness-myths",
    "https://www.verywellfit.com/common-fitness-myths-1229814",
    "https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/fitness-myths/art-20047099",
    "https://www.webmd.com/fitness-exercise/ss/slideshow-fitness-myths",
    "https://www.self.com/story/fitness-myths-debunked",
    "https://www.shape.com/fitness/tips/fitness-myths-debunked",
    "https://www.prevention.com/fitness/a20451935/fitness-myths/",
    "https://www.rd.com/list/fitness-myths/",
    "https://www.eatthis.com/fitness-myths/",
    "https://www.lifehack.org/articles/lifestyle/10-fitness-myths-you-need-to-stop-believing.html",
    "https://www.bodybuilding.com/content/10-fitness-myths-debunked.html",
    "https://www.muscleandfitness.com/workouts/workout-tips/10-fitness-myths-busted/",
    "https://www.greatist.com/fitness/common-fitness-myths",
    "https://www.health.com/fitness/fitness-myths",
    "https://www.thehealthy.com/exercise/fitness-myths/",
    "https://www.livestrong.com/article/13725598-fitness-myths-debunked/",
    "https://www.acefitness.org/education-and-resources/lifestyle/blog/6593/7-strength-training-protocols-for-muscle-growth/",
    "https://www.healthline.com/health/fitness-exercise/strength-training-routines",
    "https://www.verywellfit.com/best-strength-training-workouts-4154676",
    "https://www.mayoclinic.org/healthy-lifestyle/fitness/in-depth/strength-training/art-20046670",
    "https://www.webmd.com/fitness-exercise/ss/slideshow-strength-training-basics",
    "https://www.self.com/story/best-strength-training-workouts",
    "https://www.shape.com/fitness/workouts/best-workout-routines",
    "https://www.prevention.com/fitness/workouts/a20451935/best-workout-plans/",
    "https://www.rd.com/list/best-exercise-routines/",
    "https://www.eatthis.com/best-workout-routines/",
    "https://www.lifehack.org/articles/lifestyle/10-best-workout-routines-for-men-and-women.html",
    "https://www.bodybuilding.com/content/10-best-muscle-building-workout-routines.html",
    "https://www.muscleandfitness.com/workouts/workout-routines/",
    "https://www.greatist.com/fitness/best-workout-routines",
    "https://www.health.com/fitness/best-workout-plans",
    "https://www.thehealthy.com/exercise/best-workout-routines/",
    "https://www.livestrong.com/article/13725599-best-workout-routines/",
]

CHINESE_KEYWORDS = [
    "运动营养",
    "力量训练 研究",
    "肌肉增长 科学",
    "高强度间歇训练 效果",
    "健身 误区",
    "运动恢复 最新",
    "抗阻训练 进展",
    "健身 科学研究",
    "增肌 方法",
    "减脂 科学",
    "有氧运动 益处",
    "核心训练 原理",
    "拉伸 重要性",
    "健身 饮食",
    "补剂 研究",
    "训练计划 设计",
    "女性 健身",
    "老年人 力量训练",
    "青少年 运动",
    "运动损伤 预防",
    "健身 心理学",
    "睡眠 与 运动恢复",
    "HIIT 研究",
    "瑜伽 健康",
    "普拉提 好处",
    "CrossFit 研究",
    "健美 营养",
    "跑步 健康",
    "游泳 健身",
    "骑行 锻炼",
    "登山 体力",
    "跳绳 燃脂",
    "Tabata 效果",
    "功能性训练",
    "平衡训练",
    "柔韧性 训练",
    "爆发力 训练",
    "速度 训练",
    "敏捷性 训练",
    "耐力 训练",
]

ARXIV_QUERIES = [
    "strength training",
    "muscle hypertrophy",
    "exercise physiology",
    "sports nutrition",
    "resistance training",
    "endurance exercise",
    "protein metabolism",
    "creatine supplementation",
    "concurrent training",
    "periodization",
    "plyometric training",
    "blood flow restriction",
    "recovery modalities",
    "sleep and athletic performance",
    "caffeine performance",
    "beta alanine",
    "citrulline malate",
    "HMB supplementation",
    "vitamin D athletic performance",
    "omega 3 exercise",
    "probiotics athlete",
    "intermittent fasting exercise",
    "ketogenic diet performance",
    "vegan athlete",
    "female athlete triad",
    "youth resistance training",
    "master athlete",
    "tendon adaptation",
    "bone density exercise",
    "sarcopenia prevention",
]

PUBMED_QUERIES = [
    "resistance training muscle hypertrophy",
    "protein intake muscle protein synthesis",
    "high intensity interval training cardiovascular health",
    "creatine supplementation strength",
    "beta alanine exercise performance",
    "caffeine ergogenic aid",
    "concurrent training interference",
    "stretching injury prevention",
    "foam rolling recovery",
    "sleep deprivation athletic performance",
    "menstrual cycle exercise performance",
    "aging sarcopenia resistance exercise",
    "obesity exercise intervention",
    "type 2 diabetes resistance training",
    "hypertension aerobic exercise",
    "depression physical activity",
    "bone density weight bearing exercise",
    "tendinopathy rehabilitation",
    "ACL injury prevention",
    "probiotics immune function athlete",
    "vitamin D muscle strength",
    "omega 3 fatty acid inflammation exercise",
    "citrulline malate fatigue",
    "HMB muscle damage",
    "sodium bicarbonate buffering capacity",
    "nitrate supplementation endurance",
    "carbohydrate mouth rinse performance",
    "cold water immersion recovery",
    "compression garments muscle soreness",
    "high intensity interval training health",
    "strength training elderly",
    "nutrition recovery exercise",
]

BLACKLIST = [
    "click here",
    "buy now",
    "discount",
    "miracle",
    "guaranteed",
    "ad",
    "sponsored",
    "promotion",
    "sale",
    "limited time",
    "exclusive",
    "new release",
    "affiliate",
    "advertisement",
    "产品",
    "促销",
    "代理",
    "点击",
    "购买",
    "优惠",
    "神奇",
    "保证",
    "广告",
    "赞助",
    "影视剧",
    "小说",
    "漫画",
    "游戏",
    "娱乐",
    "八卦",
    "明星",
    "网红",
    "测评",
    "推荐",
    "选购",
    "百度百科",
    "辭典",
    "檢視",
    "康复",
    "字典",
    "释义",
    "意思",
    "是什么",
    "怎么吃",
    "方法",
    "步骤",
    "教程",
    "指南",
    "方案",
    "计划",
    "excellent",
    "amazing",
    "incredible",
    "unbelievable",
    "best",
    "worst",
    "top",
    "review",
    "comparison",
    "评测",
    "对比",
    "排行榜",
    "最佳",
    "最差",
    "神评",
    "张雪峰",
    "免费",
    "免费试用",
    "试用装",
    "限时",
    "限量",
    "独家",
    "首发",
    "新品",
    "开箱",
    "开箱视频",
    "开箱测评",
    "娱乐圈",
    "影视圈",
    "明星八卦",
    "网红八卦",
    "娱乐八卦",
    "影视八卦",
    "京东",
    "好物",
    "畅游",
    "运动户外",
    "特价",
    "秒杀",
    "包邮",
    "满减",
    "领券",
    "优惠券",
    "拼团",
    "砍价",
    "免单",
    "返现",
    "赠品",
    "买一送一",
    "热卖",
    "爆款",
    "销量第一",
    "好评如潮",
    "口碑爆棚",
    "正品保障",
    "假一赔十",
    "七天无理由",
    "运费险",
    "极速退款",
    "闪电发货",
    "会员专享",
    "VIP特价",
    "黑卡会员",
    "钻石会员",
    "超级会员",
    "蛋白粉",
    "肌酸",
    "支链氨基酸",
    "氮泵",
    "左旋肉碱",
    "维生素",
    "益生菌",
    "鱼油",
    "红牛",
    "魔爪",
    "东鹏特饮",
    "乐虎",
    "战马",
    "康比特",
    "诺特兰德",
    "肌肉科技",
    "GNC",
    "健安喜",
    "汤臣倍健",
    "速看",
    "慎入",
    "深度好文",
    "必读",
    "收藏",
    "转发",
    "扩散",
    "感恩",
    "感动",
    "泪目",
    "揭秘",
    "内幕",
    "潜藏",
    "隐藏",
    "不为人知",
    "惊人",
    "震惊",
    "GitHub",
    "研发",
    "意义",
    "服务",
    "怎么样",
    "最新",
    "股價",
    "走勢",
    "社群",
    "股市",
    "登录",
    "用户",
    "引擎",
    "巨量",
    "抖音",
    "营销",
    "zhihu",
    "知乎",
    "理財",
    "理财",
    "資料",
    "股份",
    "资料",
    "上市",
    "高三",
    "瑞文",
    "测试",
    "百度知道",
    "360问答",
    "搜狗问问",
    "新浪爱问",
    "腾讯问问",
    "网易知道",
    "问答",
    "提问",
    "回答",
    "问题",
    "答案",
    "解答",
    "咨询",
    "客服",
    "教程",
    "教学",
    "课程",
    "培训",
    "学习",
    "教育",
    "视频",
    "直播",
    "讲座",
    "研讨会",
    "会议",
    "论坛",
    "社区",
    "贴吧",
    "群",
    "微信群",
    "QQ群",
    "公众号",
    "小红书",
    "快手",
    "B站",
    "哔哩哔哩",
    "微博",
    "微信",
    "Instagram",
    "Facebook",
    "Twitter",
    "LinkedIn",
    "YouTube",
    "TikTok",
    "Snapchat",
    "Reddit",
    "Pinterest",
    "康复",
    "字典",
    "意思",
    "怎么吃",
    "方法",
    "步骤",
    "教程",
    "指南",
    "方案",
    "计划",
    "评测",
    "对比",
    "排行榜",
    "最佳",
    "最差",
    "神评",
    "免费",
    "试用",
    "限时",
    "限量",
    "独家",
    "首发",
    "新品",
    "开箱",
    "娱乐圈",
    "明星八卦",
    "网红八卦",
    "娱乐八卦",
    "影视八卦",
    "京东",
    "好物",
    "畅游",
    "运动户外",
    "特价",
    "秒杀",
    "包邮",
    "满减",
    "领券",
    "优惠券",
    "拼团",
    "砍价",
    "免单",
    "返现",
    "赠品",
    "买一送一",
    "热卖",
    "爆款",
    "销量第一",
    "好评如潮",
    "口碑爆棚",
    "正品保障",
    "假一赔十",
    "七天无理由",
    "运费险",
    "极速退款",
    "闪电发货",
    "会员专享",
    "VIP特价",
    "黑卡会员",
    "钻石会员",
    "超级会员",
    "蛋白粉",
    "肌酸",
    "支链氨基酸",
    "氮泵",
    "左旋肉碱",
    "维生素",
    "益生菌",
    "鱼油",
    "红牛",
    "魔爪",
    "东鹏特饮",
    "乐虎",
    "战马",
    "康比特",
    "诺特兰德",
    "肌肉科技",
    "GNC",
    "健安喜",
    "汤臣倍健",
    "速看",
    "慎入",
    "深度好文",
    "必读",
    "收藏",
    "转发",
    "扩散",
    "感恩",
    "感动",
    "泪目",
    "揭秘",
    "内幕",
    "潜藏",
    "隐藏",
    "不为人知",
    "惊人",
    "震惊",
    "GitHub",
    "研发",
    "意义",
    "服务",
    "怎么样",
    "最新",
    "股價",
    "走勢",
    "社群",
    "股市",
    "登录",
    "用户",
    "引擎",
    "巨量",
    "抖音",
    "营销",
    "zhihu",
    "知乎",
    "理財",
    "理财",
    "資料",
    "股份",
    "资料",
    "上市",
    "高三",
    "瑞文",
    "测试",
    "百度知道",
    "360问答",
    "搜狗问问",
    "新浪爱问",
    "腾讯问问",
    "网易知道",
    "问答",
    "提问",
    "回答",
    "问题",
    "答案",
    "解答",
    "咨询",
    "客服",
    "教程",
    "教学",
    "课程",
    "培训",
    "学习",
    "教育",
    "视频",
    "直播",
    "讲座",
    "研讨会",
    "会议",
    "论坛",
    "社区",
    "贴吧",
    "群",
    "微信群",
    "QQ群",
    "公众号",
    "小红书",
    "快手",
    "B站",
    "哔哩哔哩",
    "微博",
    "微信",
    "Instagram",
    "Facebook",
    "Twitter",
    "LinkedIn",
    "YouTube",
    "TikTok",
    "Snapchat",
    "Reddit",
    "Pinterest",
    "高启强",
    "张雪峰",
    "李佳琦",
    "薇娅",
    "罗永浩",
    "papi酱",
    "办公室小野",
    "李子柒",
    "高启盛",
    "高启胜",
    "高启航",
    "高启明",
    "高启东",
    "高启华",
    "高启文",
    "高启国",
    "高启强的父亲",
    "高三",
    "瑞文",
    "测试",
    "百度知道",
    "360问答",
    "搜狗问问",
    "新浪爱问",
    "腾讯问问",
    "网易知道",
    "问答",
    "武器装备",
    "武器",
    "军事",
    "战争",
    "国防",
    "军工",
    "军队",
    "战斗",
    "作战",
    "战略",
    "战术",
    "兵器",
    "坦克",
    "飞机",
    "舰船",
    "导弹",
    "核武器",
    "无人机",
    "特种部队",
    "情报",
    "间谍",
    "反恐",
    "批判",
    "政治",
    "时政",
    "国际关系",
    "外交",
    "内政",
    "经济政策",
    "社会问题",
    "文化评论",
    "注音",
    "驱动",
    "程序",
    "更新",
    "下载",
    "卸载",
    "至尊",
    "钻石",
    "法律",
    "王者",
    "青铜",
    "维基",
    "词典",
    "表意",
    "文字",
    "漢字",
    "词语",
    "歷史",
    "硬件",
    "Nvidia",
    "AMD",
    "Intel",
    "Apple Silicon",
    "GPU",
    "CPU",
    "TPU",
    "AI芯片",
    "深度学习加速器",
    "数据库",
    "图书馆",
    "中文",
    "官話",
    "拼音",
    "解释",
    "份量",
    "背叛",
    "词性",
    "论衡",
    "发音",
    "汉语",
    "本义",
    "表示",
    "笔顺",
    "官网",
    "期刊",
    "国际",
    "跳转",
    "教练",
    "补子",
    "官员",
    "诊断",
    "治疗",
    "医疗",
    "用药",
    "服药",
    "服用",
    "省钱",
    "牌意",
    "关键词",
    "补子",
    "政策",
    "法规",
    "法律",
    "司法",
    "行政",
    "立法",
    "监管",
    "合规",
    "审查",
    "处罚",
    "罚款",
    "监禁",
    "判决",
    "律师",
    "法官",
    "法院",
    "检察院",
    "公安局",
    "国家安全局",
    "情报局",
    "军队",
    "武警",
    "特警",
    "反恐",
    "维稳",
    "铁路",
    "动车",
    "高铁",
    "——《",
    "覆盖",
    "棺木",
    "组词",
    "市盈率",
    "茅台",
    "贵州",
    "虚构",
    "古井",
    "机械运动",
    "知识点",
    "参照物",
    "宇宙",
    "图片",
    "白领",
    "伏案",
    "针",
    "通“",
    "地球",
    "历史",
    "火车",
    "动车",
    "高铁",
    "——《",
    "覆盖",
    "棺木",
    "组词",
    "市盈率",
    "茅台",
    "贵州",
    "虚构",
    "古井",
]

BLACKLIST = list(set(BLACKLIST))

REGEX_BLACKLIST = [
    r"\d{4}年\d{1,2}月\d{1,2}日",  # 2023年10月5日
    r"\d{4}-\d{1,2}-\d{1,2}",  # 2023-10-05
    r"\d{4}/\d{1,2}/\d{1,2}",  # 2023/10/05
    r"\d{1,2}月\d{1,2}日",  # 10月5日（不带年份）
    r"\d{4}\.\d{1,2}\.\d{1,2}",  # 2023.10.05
    r"\d{1,2}/\d{1,2}/\d{4}",  # 10/05/2023
]

# ========== 预设内容（与原 Dart 保持一致，作为保底） ==========
PRESET_RESEARCH = [
    "🔬 研究：每周2-3次力量训练可增加肌肉质量并提高骨密度。",
    "🔬 蛋白质摄入时机：训练后30分钟内补充20-25g蛋白质最能促进肌肉合成。",
    "🔬 HIIT 训练能显著提高心肺功能和胰岛素敏感性。",
    "🔬 睡眠不足会降低肌肉恢复速度并增加受伤风险。",
    "🔬 渐进超负荷是肌肉增长的核心原则。",
    "🔬 离心收缩比向心收缩更能引发肌肉肥大。",
    "🔬 每天步行8000步可降低全因死亡率20%。",
    "🔬 抗阻训练可改善老年人认知功能。",
    "🔬 运动后冰浴可能减弱肌肉蛋白合成。",
    "🔬 咖啡因能提高耐力运动表现约5-10%。",
    "🔬 补充肌酸可增加肌肉力量和爆发力。",
    "🔬 运动前动态拉伸比静态拉伸更能提升表现。",
    "🔬 高强度力量训练后需要48小时恢复。",
    "🔬 饮食中蛋白质应均匀分配于每餐。",
    "🔬 维生素D缺乏会降低肌肉功能。",
    "🔬 每日摄入1.6-2.2g/kg蛋白质对增肌最佳。",
    "🔬 复合动作（深蹲、硬拉）比孤立动作更高效。",
    "🔬 女性进行力量训练不会变得粗壮，反而更紧致。",
    "🔬 训练多样化可避免平台期。",
    "🔬 冥想结合运动能减轻压力。",
    "🔬 研究：大重量低次数（4-6次）主要增强力量。",
    "🔬 中高次数（8-12次）最利于肌肉肥大。",
    "🔬 高次数（15+次）主要提升耐力。",
    "🔬 训练容量（组数×次数×重量）是增肌关键。",
    "🔬 组间休息2-3分钟更适合力量训练。",
    "🔬 组间休息45-90秒更适合增肌训练。",
    "🔬 运动前摄入碳水化合物可提高耐力。",
    "🔬 训练后补充蛋白质促进肌肉修复。",
    "🔬 水合状态影响运动表现达20%。",
    "🔬 核心稳定性训练可预防下背痛。",
    "🔬 平衡训练可减少老年人跌倒风险。",
    "🔬 柔韧性训练可提高关节活动度。",
    "🔬 爆发力训练（跳箱、药球）提高运动表现。",
    "🔬 速度训练可提高神经系统效率。",
    "🔬 敏捷性训练可减少运动损伤。",
    "🔬 长期有氧运动可增加海马体体积。",
    "🔬 运动可缓解抑郁症状，效果类似药物。",
    "🔬 运动后内啡肽释放产生愉悦感。",
    "🔬 睾酮在力量训练后短暂升高。",
    "🔬 生长激素在睡眠和训练后分泌。",
    "🔬 皮质醇过高会分解肌肉。",
    "🔬 胰岛素敏感性随运动提高。",
    "🔬 运动可降低静息心率。",
    "🔬 最大摄氧量是心肺耐力指标。",
    "🔬 无氧阈值越高耐力越强。",
    "🔬 肌肉纤维分为I型（慢肌）和II型（快肌）。",
    "🔬 快肌纤维更容易肥大。",
    "🔬 慢肌纤维更耐疲劳。",
    "🔬 基因决定肌肉纤维比例。",
    "🔬 年龄增长导致肌肉流失（肌少症）。",
    "🔬 力量训练是预防肌少症最有效方法。",
]

PRESET_ENCOURAGEMENTS = [
    "💪 每一次力竭都是成长的信号！",
    "💪 坚持就是胜利，肌肉在休息时生长。",
    "💪 你流的每一滴汗，都在雕刻更好的自己。",
    "💪 别放弃，今天的痛苦是明天的力量。",
    "💪 健身是最好的抗衰老药。",
    "💪 运动改变大脑，让你更快乐。",
    "💪 没有借口，只有更好的自己。",
    "💪 身体是灵魂的殿堂，保持洁净。",
    "💪 进步来自舒适区之外。",
    "💪 每天进步1%，一年强大37倍。",
    "💪 运动是你能为自己做的最好的投资。",
    "💪 累吗？说明你在走上坡路。",
    "💪 健身不是为了比过别人，而是为了超越昨天的自己。",
    "💪 汗水不会欺骗你。",
    "💪 肌肉是用痛苦交换的礼物。",
    "💪 成功不是将来才有的，而是从决定去做的那一刻起，持续累积而成。",
    "💪 健身是唯一付出就一定会有回报的事情。",
    "💪 不要让昨天的疲惫，阻止今天的你。",
    "💪 强壮的身体，是意志力的证明。",
    "💪 训练时你对抗的是重力，生活中你对抗的是惰性。",
    "💪 每次力竭，都是肌肉在呐喊生长。",
    "💪 健身让你成为更好的自己。",
    "💪 只有汗水不会骗你。",
    "💪 坚持，就是胜利。",
    "💪 别让懒惰占据你的生活。",
    "💪 健身是一种生活态度。",
    "💪 每天进步一点点。",
    "💪 相信自己，你可以。",
    "💪 没有痛苦，就没有收获。",
    "💪 健身让你更自信。",
]

PRESET_TIPS = [
    "💡 训练前动态热身，训练后静态拉伸。",
    "💡 每组最后一两次要竭尽全力。",
    "💡 保持水分，每天至少喝2-3升水。",
    "💡 睡眠7-9小时对恢复至关重要。",
    "💡 使用大重量低次数（4-6次）增力，中重量中次数（8-12次）增肌。",
    "💡 训练计划每6-8周调整一次。",
    "💡 动作质量比重量更重要。",
    "💡 训练后补充碳水化合物和蛋白质。",
    "💡 记录训练日志以追踪进步。",
    "💡 不要忽视核心训练。",
    "💡 深蹲时膝盖不要内扣。",
    "💡 硬拉保持背部挺直。",
    "💡 卧推时肩胛骨收紧。",
    "💡 引体向上避免摆动借力。",
    "💡 有氧和力量训练分开进行效果更佳。",
    "💡 训练前摄入咖啡因可提高专注力。",
    "💡 训练后冷热交替淋浴促进恢复。",
    "💡 使用泡沫轴放松肌肉。",
    "💡 每周至少休息1-2天。",
    "💡 训练强度比训练量更重要。",
    "💡 多样化训练避免平台期。",
    "💡 倾听身体信号，避免过度训练。",
    "💡 大重量训练时使用腰带保护腰部。",
    "💡 握力带可辅助大重量拉类动作。",
    "💡 训练前2小时进食，避免空腹。",
    "💡 训练中补充电解质。",
    "💡 训练后补充快碳（如香蕉、白面包）。",
    "💡 使用训练App记录进度。",
    "💡 寻找训练伙伴互相激励。",
    "💡 设定短期和长期目标。",
]

PRESET_FACTS = [
    "📚 蛋白质摄入建议每公斤体重1.6-2.2克。",
    "📚 睡眠不足会抑制肌肉恢复。",
    "📚 一磅肌肉每天消耗约6-10卡路里。",
    "📚 运动后过量氧耗（EPOC）可持续数小时。",
    "📚 人体有超过600块肌肉。",
    "📚 最大心率约为220减去年龄。",
    "📚 高强度间歇训练（HIIT）后燃效应更强。",
    "📚 水占肌肉重量的75%左右。",
    "📚 力量训练可提高基础代谢率。",
    "📚 久坐每小时起身活动2分钟可降低血糖。",
    "📚 深蹲可以锻炼全身200多块肌肉。",
    "📚 拉伸不能预防所有运动损伤，但能提高柔韧性。",
    "📚 肌肉酸痛并不代表训练有效。",
    "📚 基因影响肌肉形态和增长潜力。",
    "📚 女性睾酮水平仅为男性1/10，不会轻易练出大块肌肉。",
    "📚 一公斤脂肪约含7700卡路里。",
    "📚 肌肉密度大于脂肪。",
    "📚 体重指数(BMI)不区分肌肉和脂肪。",
    "📚 体脂率是更准确的健康指标。",
    "📚 内脏脂肪危害最大。",
    "📚 褐色脂肪帮助燃烧热量。",
    "📚 寒冷环境可激活褐色脂肪。",
    "📚 禁食16小时以上开始消耗脂肪。",
    "📚 生酮饮食初期体重下降主要是水分。",
    "📚 碳水化合物不是肥胖元凶，总热量才是。",
    "📚 膳食纤维有助于控制体重。",
    "📚 蛋白质热效应最高（20-30%）。",
    "📚 碳水化合物热效应5-10%。",
    "📚 脂肪热效应0-3%。",
    "📚 食物热效应占总消耗10%。",
]

PRESET_MYTHS = [
    "🧠 局部减脂不存在。",
    "🧠 流汗多不等于减脂多。",
    "🧠 肌肉不会变成脂肪，两者不同组织。",
    "🧠 举重不会让你变矮。",
    "🧠 女性举重不会变壮硕。",
    "🧠 训练后不需要立即喝蛋白粉。",
    "🧠 有氧运动不会燃烧肌肉（只要摄入足够蛋白质）。",
    "🧠 碳水化合物不会让你变胖，过量热量才会。",
    "🧠 力量训练不会降低柔韧性。",
    "🧠 老年人也可以增肌。",
    "🧠 健身补剂不是必须的。",
    "🧠 肌肉酸痛不代表肌肉增长。",
    "🧠 空腹有氧并不更减脂。",
    "🧠 拉伸不会防止肌肉拉伤。",
    "🧠 健身不需要每天练。",
    "🧠 训练后肌肉酸痛是乳酸堆积？不，是微损伤。",
    "🧠 吃脂肪不会让你长脂肪。",
    "🧠 基础代谢低不是肥胖主因。",
    "🧠 排毒产品是骗局。",
    "🧠 燃脂心率区不是必须的。",
    "🧠 健身不会让你变笨重。",
    "🧠 重量训练不会让女性变成金刚芭比。",
    "🧠 健身可以改善皮肤。",
    "🧠 健身不会导致脱发（除非基因）。",
    "🧠 健身不会让你长不高（青少年）。",
    "🧠 健身不会影响生育。",
    "🧠 健身不会导致肾损伤（除非滥用药物）。",
]

PRESET_PROTOCOLS = [
    "🏋️ 渐进超负荷原则：逐步增加重量或次数。",
    "🏋️ 复合动作是基础：深蹲、硬拉、卧推。",
    "🏋️ 分化训练：推拉腿、上下肢分化。",
    "🏋️ 周期性训练：力量、增肌、耐力周期轮换。",
    "🏋️ 热身组：先用轻重量激活神经。",
    "🏋️ 超级组：拮抗肌群交替训练节省时间。",
    "🏋️ 递减组：力竭后减重继续，增加代谢压力。",
    "🏋️ 休息暂停：每组最后力竭后休息15秒再完成几次。",
    "🏋️ 离心强化：慢放阶段增加时间。",
    "🏋️ 血流限制训练：用轻重量达到类似大重量效果。",
    "🏋️ 塔巴塔训练：20秒冲刺10秒休息，共8轮。",
    "🏋️ 法特莱克跑：变速跑提高耐力。",
    "🏋️ 5x5训练法：5组5次，专注力量。",
    "🏋️ 10x10德国壮汉训练：高容量增肌。",
    "🏋️ 三组8-12次：经典增肌范围。",
    "🏋️ 每周3次全身训练适合初学者。",
    "🏋️ 每周4次上下肢分化适合中级。",
    "🏋️ 每周5次推拉腿分化适合高级。",
    "🏋️ 训练前动态拉伸：弓步转体、高抬腿。",
    "🏋️ 训练后静态拉伸：每个部位保持20秒。",
    "🏋️ 主动恢复日：低强度有氧或瑜伽。",
    "🏋️ 减载周：每6-8周降低强度50%。",
    "🏋️ 优先训练弱项：先做弱势部位。",
    "🏋️ 训练顺序：复合动作→孤立动作。",
    "🏋️ 大重量组前增加神经激活组。",
    "🏋️ 使用弹力带辅助引体向上。",
    "🏋️ 使用TRX训练核心稳定性。",
    "🏋️ 壶铃摇摆锻炼后链。",
    "🏋️ 保加利亚分腿蹲单侧训练。",
    "🏋️ 罗马尼亚硬拉针对腘绳肌。",
]


# ========== 工具函数 ==========
def random_select(lst):
    return random.choice(lst) if lst else ""


# 预编译正则表达式（提高性能）
_COMPILED_REGEX = [re.compile(pattern) for pattern in REGEX_BLACKLIST]


def contains_blacklisted(text):
    lower = text.lower()
    # 1. 关键词黑名单检查
    if any(kw.lower() in lower for kw in BLACKLIST):
        return True
    # 2. 正则表达式黑名单检查
    for regex in _COMPILED_REGEX:
        if regex.search(text):
            return True
    return False


def fetch_with_retry(url, max_retries=2, delay=2):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Accept-Encoding": "gzip, deflate, br",
        "Connection": "keep-alive",
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
            soup = BeautifulSoup(resp.text, "html.parser")
            for el in soup.select("li, p, blockquote, .quote, .quote-text"):
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
            soup = BeautifulSoup(resp.text, "html.parser")
            texts = []
            for el in soup.select("p, li, h2, h3"):
                text = el.get_text(strip=True)
                if "myth" in text.lower() or "误区" in text or "迷思" in text:
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
            soup = BeautifulSoup(resp.text, "html.parser")
            texts = []
            for el in soup.select("p, li"):
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
    session.headers.update(
        {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
    )
    for kw in CHINESE_KEYWORDS[:15]:
        time.sleep(5)
        try:
            url = f"https://www.bing.com/search?q={requests.utils.quote(kw)}&count=2"
            resp = session.get(url, timeout=15)
            if resp.status_code != 200:
                continue
            soup = BeautifulSoup(resp.text, "html.parser")
            for p in soup.select(".b_caption p"):
                text = p.get_text(strip=True)
                if 40 < len(text) < 300:
                    results.append(f"📚 {text}")
        except Exception:
            continue
    return list(set(results))


def fetch_baidu_facts():
    results = []
    session = requests.Session()
    session.headers.update(
        {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
    )
    for kw in CHINESE_KEYWORDS[:15]:
        time.sleep(2)
        try:
            url = f"https://www.baidu.com/s?wd={requests.utils.quote(kw)}&rn=2"
            resp = session.get(url, timeout=15)
            if resp.status_code != 200:
                continue
            soup = BeautifulSoup(resp.text, "html.parser")
            for p in soup.select(".c-abstract"):
                text = p.get_text(strip=True)
                if 40 < len(text) < 300:
                    results.append(f"📚 {text}")
        except Exception:
            continue
    return list(set(results))


def fetch_pubmed_summaries(max_retries=3):
    results = []
    session = requests.Session()
    for query in PUBMED_QUERIES[:10]:
        for attempt in range(max_retries):
            try:
                time.sleep(3)
                search_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term={requests.utils.quote(query)}&retmax=2&retmode=json&email={ENTREZ_EMAIL}"
                search_resp = session.get(search_url, timeout=30)
                if search_resp.status_code != 200:
                    raise Exception(f"HTTP {search_resp.status_code}")
                data = search_resp.json()
                ids = data.get("esearchresult", {}).get("idlist", [])
                if not ids:
                    break
                fetch_url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id={','.join(ids)}&retmode=xml&email={ENTREZ_EMAIL}"
                fetch_resp = session.get(fetch_url, timeout=30)
                if fetch_resp.status_code != 200:
                    raise Exception(f"HTTP {fetch_resp.status_code}")
                root = ET.fromstring(fetch_resp.content)
                for article in root.findall(".//PubmedArticle"):
                    title = article.find(".//ArticleTitle")
                    title_text = (
                        title.text.strip() if title is not None and title.text else ""
                    )
                    abstract_parts = []
                    for abs_text in article.findall(".//AbstractText"):
                        if abs_text.text:
                            abstract_parts.append(abs_text.text.strip())
                    abstract = " ".join(abstract_parts)
                    if title_text and abstract:
                        combined = f"{title_text}. {abstract}".replace(
                            "\n", " "
                        ).replace("\r", " ")
                        if 50 < len(combined) < 600:
                            results.append(f"🔬 {combined}")
                break  # 成功，跳出重试循环
            except Exception as e:
                print(f"PubMed error (attempt {attempt+1}): {e}")
                if attempt == max_retries - 1:
                    break
                time.sleep(5 * (attempt + 1))
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
            for entry in root.findall(".//{http://www.w3.org/2005/Atom}entry"):
                title = entry.find(".//{http://www.w3.org/2005/Atom}title")
                summary = entry.find(".//{http://www.w3.org/2005/Atom}summary")
                title_text = (
                    title.text.strip().replace("\n", " ")
                    if title is not None and title.text
                    else ""
                )
                summary_text = (
                    summary.text.strip().replace("\n", " ")
                    if summary is not None and summary.text
                    else ""
                )
                if title_text and summary_text:
                    if len(summary_text) > 200:
                        summary_text = summary_text[:200] + "..."
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
        for item in root.findall(".//item")[:10]:
            title = item.find("title")
            desc = item.find("description")
            title_text = title.text.strip() if title is not None and title.text else ""
            desc_text = desc.text.strip() if desc is not None and desc.text else ""
            if title_text and desc_text:
                import re

                clean_desc = (
                    re.sub(r"<[^>]*>", "", desc_text).replace("\n", " ").strip()
                )
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
            tips.append(s.replace("💪", "💡"))
    return tips + PRESET_TIPS


def fetch_all_facts():
    bing = fetch_bing_facts()
    baidu = fetch_baidu_facts()
    pubmed = fetch_pubmed_summaries()
    arxiv = fetch_arxiv_research()
    return bing + baidu + pubmed + arxiv + PRESET_FACTS


# ========== 新增清理函数 ==========
def clean_data(data):
    """根据 BLACKLIST 清理所有类别中的违规条目"""
    cleaned = {}
    total_removed = 0
    for cat in [
        "scientific_facts",
        "research_summaries",
        "myth_busters",
        "training_protocols",
        "tips",
        "encouragements",
    ]:
        original = data.get(cat, [])
        new_list = []
        for item in original:
            if not contains_blacklisted(item):
                new_list.append(item)
        removed = len(original) - len(new_list)
        total_removed += removed
        cleaned[cat] = new_list
        if removed > 0:
            print(f"   🧹 {cat}: 清理了 {removed} 条违规内容")
    print(f"总共清理了 {total_removed} 条违规条目")
    return cleaned


def ensure_preset_fallback(data):
    """确保每个类别至少有一定数量的预设内容（如果为空）"""
    for cat, preset in [
        ("scientific_facts", PRESET_FACTS),
        ("research_summaries", PRESET_RESEARCH),
        ("myth_busters", PRESET_MYTHS),
        ("training_protocols", PRESET_PROTOCOLS),
        ("tips", PRESET_TIPS),
        ("encouragements", PRESET_ENCOURAGEMENTS),
    ]:
        if not data.get(cat):
            data[cat] = preset
            print(f"📦 {cat} 为空，已填充预设 {len(preset)} 条")
    return data


# ========== 主抓取入口 ==========
def fetch_all():
    print("开始抓取所有类别...")
    research = fetch_all_research()
    encouragements = fetch_all_encouragements()
    tips = fetch_all_tips()
    facts = fetch_all_facts()
    myths = fetch_myths()
    protocols = fetch_protocols()
    print(
        f"抓取结果: 研究{len(research)} 鼓励{len(encouragements)} 提示{len(tips)} 事实{len(facts)} 迷思{len(myths)} 方案{len(protocols)}"
    )
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
    """加载现有 JSON，如果文件损坏则返回空字典"""
    if not LOCAL_JSON_PATH.exists():
        print("本地 JSON 文件不存在，将创建新文件")
        return {}
    try:
        with open(LOCAL_JSON_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"⚠️ JSON 解析失败: {e}")
        print("将重置为空数据，后续会用预设内容填充")
        backup_path = LOCAL_JSON_PATH.with_suffix(".json.broken")
        try:
            LOCAL_JSON_PATH.rename(backup_path)
            print(f"已备份损坏文件到 {backup_path}")
        except:
            pass
        return {}


def save_json(data):
    LOCAL_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(LOCAL_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"[{datetime.now()}] JSON saved to {LOCAL_JSON_PATH}")

    if SECONDARY_JSON_PATH:
        SECONDARY_JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
        with open(SECONDARY_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"[{datetime.now()}] JSON also saved to {SECONDARY_JSON_PATH}")


def merge_data(existing, new):
    merged = {}
    for cat in [
        "scientific_facts",
        "research_summaries",
        "myth_busters",
        "training_protocols",
        "tips",
        "encouragements",
    ]:
        existing_set = set(existing.get(cat, []))
        new_set = set(new.get(cat, []))
        merged[cat] = list(existing_set | new_set)
    return merged


# ========== Git 推送逻辑 ==========
def git_commit_and_push():
    try:
        os.chdir(GIT_REPO_PATH)
        rel_path = str(LOCAL_JSON_PATH.relative_to(GIT_REPO_PATH))

        # 检查文件是否有变更
        status = subprocess.run(
            ["git", "status", "--porcelain", rel_path], capture_output=True, text=True
        )
        if not status.stdout.strip():
            print(f"[{datetime.now()}] No changes to commit, skipping push.")
            return True  # 无变化视为成功，避免重试

        subprocess.run(["git", "add", rel_path], check=True, capture_output=True)
        subprocess.run(
            [
                "git",
                "commit",
                "-m",
                f"Auto update knowledge {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            ],
            check=True,
            capture_output=False,
        )
        subprocess.run(["git", "push", GIT_REMOTE_URL], check=True, capture_output=False)
        print(f"[{datetime.now()}] Git push successful")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[{datetime.now()}] Git operation failed: {e}")
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

    # 启动时先清理一次现有数据
    print("正在清理现有知识库...")
    existing = load_existing_data()
    if existing:
        cleaned = clean_data(existing)
        cleaned = ensure_preset_fallback(cleaned)
        save_json(cleaned)
        existing = cleaned
    else:
        fresh = {
            "scientific_facts": PRESET_FACTS,
            "research_summaries": PRESET_RESEARCH,
            "myth_busters": PRESET_MYTHS,
            "training_protocols": PRESET_PROTOCOLS,
            "tips": PRESET_TIPS,
            "encouragements": PRESET_ENCOURAGEMENTS,
        }
        save_json(fresh)
        existing = fresh
        print("已使用预设内容初始化知识库")

    while True:
        now = time.time()
        if now - last_scrape_time >= SCRAPE_INTERVAL:
            print(f"[{datetime.now()}] Scraping...")
            new_data = fetch_all()
            merged = merge_data(existing, new_data)
            merged = clean_data(merged)
            merged = ensure_preset_fallback(merged)
            save_json(merged)
            existing = merged
            last_scrape_time = now

        if now - last_push_time >= PUSH_INTERVAL:
            print(f"[{datetime.now()}] Attempting to push to GitHub...")
            success = push_with_retry()
            if success:
                last_push_time = now
            else:
                print("Push failed, will retry after 5 minutes.")
                # 可选：将 last_push_time 设置为当前时间减去一半间隔，以便稍后重试
                last_push_time = now - PUSH_INTERVAL + 300  # 5 分钟后重试
        time.sleep(60)


if __name__ == "__main__":
    main_loop()
