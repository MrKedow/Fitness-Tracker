#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import shutil
import time
from pathlib import Path

# 颜色支持（Windows 10+ 支持 ANSI 颜色）
class Colors:
    RESET = '\033[0m'
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GRAY = '\033[90m'

# 启用 Windows ANSI 颜色支持
if sys.platform == 'win32':
    import ctypes
    try:
        # 正确的函数名是 GetStdHandle，参数 -11 表示 STD_OUTPUT_HANDLE
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except Exception:
        # 如果设置失败，忽略（不影响主要功能）
        pass

def print_header(text):
    """打印标题"""
    print(f"{Colors.CYAN}{'=' * 50}{Colors.RESET}")
    print(f"{Colors.CYAN}{text.center(50)}{Colors.RESET}")
    print(f"{Colors.CYAN}{'=' * 50}{Colors.RESET}")
    print()

def print_success(text):
    """打印成功信息"""
    print(f"{Colors.GREEN}✓ {text}{Colors.RESET}")

def print_error(text):
    """打印错误信息"""
    print(f"{Colors.RED}✗ {text}{Colors.RESET}")

def print_info(text):
    """打印普通信息"""
    print(f"{Colors.YELLOW}→ {text}{Colors.RESET}")

def print_step(step, text):
    """打印步骤"""
    print(f"{Colors.GRAY}[{step}] {text}...{Colors.RESET}", end=' ', flush=True)

def kill_process(process_name):
    """终止进程"""
    try:
        if sys.platform == 'win32':
            subprocess.run(['taskkill', '/F', '/IM', f'{process_name}.exe'], 
                          capture_output=True, timeout=5)
        else:
            subprocess.run(['pkill', '-f', process_name], capture_output=True, timeout=5)
    except:
        pass

def delete_directory(path):
    """删除目录"""
    try:
        if os.path.exists(path):
            shutil.rmtree(path, ignore_errors=True)
    except:
        pass

def delete_file(path):
    """删除文件"""
    try:
        if os.path.exists(path):
            os.remove(path)
    except:
        pass

def run_command(cmd, cwd=None, show_output=False):
    """运行命令"""
    try:
        if show_output:
            process = subprocess.Popen(
                cmd,
                cwd=cwd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding='utf-8',
                errors='replace'
            )
            
            for line in process.stdout:
                print(f"  {line.rstrip()}")
            
            process.wait()
            return process.returncode
        else:
            result = subprocess.run(
                cmd,
                cwd=cwd,
                shell=True,
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace'
            )
            return result.returncode
    except Exception as e:
        print_error(f"命令执行失败: {e}")
        return 1

def verify_project():
    """验证是否在 Flutter 项目目录"""
    if not os.path.exists('pubspec.yaml'):
        print_error("未找到 pubspec.yaml 文件！")
        print_info("请将此工具放在 Flutter 项目根目录下运行。")
        return False
    return True

def clean_project():
    """清理项目"""
    project_dir = os.getcwd()
    
    # 1. 停止进程
    print_step(1, "停止 Flutter 进程")
    kill_process('dart')
    kill_process('flutter_tools')
    print_success("完成")
    
    # 2. 删除构建目录
    print_step(2, "删除构建目录")
    delete_directory(os.path.join(project_dir, 'build'))
    delete_directory(os.path.join(project_dir, 'windows', 'build'))
    print_success("完成")
    
    # 3. 删除 CMake 缓存
    print_step(3, "删除 CMake 缓存")
    delete_file(os.path.join(project_dir, 'CMakeCache.txt'))
    delete_file(os.path.join(project_dir, 'cmake_install.cmake'))
    delete_directory(os.path.join(project_dir, 'CMakeFiles'))
    print_success("完成")
    
    # 4. Flutter clean
    print_step(4, "清理 Flutter 缓存")
    run_command('flutter clean', cwd=project_dir)
    print_success("完成")
    
    # 5. 清理 pub 缓存
    print_step(5, "清理 pub 缓存")
    delete_file(os.path.join(project_dir, 'pubspec.lock'))
    delete_directory(os.path.join(project_dir, '.dart_tool'))
    print_success("完成")
    
    print()
    print_header("清理完成！")
    
    # 获取依赖
    #print_info("正在获取依赖包...")
    #print()
    #run_command('flutter pub get', cwd=project_dir, show_output=True)
    #print()

def debug_mode():
    """启动调试"""
    print_header("启动调试模式")
    project_dir = os.getcwd()
    run_command('flutter run -d windows', cwd=project_dir, show_output=True)

def build_release():
    """构建发布版本"""
    print_header("构建发布版本")
    project_dir = os.getcwd()
    ret = run_command('flutter build windows', cwd=project_dir, show_output=True)
    
    print()
    if ret == 0:
        print_header("构建完成！")
        release_path = os.path.join(project_dir, 'build', 'windows', 'x64', 'runner', 'Release')
        print_info(f"输出位置: {release_path}")
        
        # 询问是否打开目录
        print()
        choice = input(f"{Colors.YELLOW}是否打开输出目录？(y/N): {Colors.RESET}").strip().lower()
        if choice == 'y':
            if sys.platform == 'win32':
                os.startfile(release_path)
            else:
                subprocess.run(['open', release_path])
    else:
        print_error("构建失败，请检查上方错误信息。")
    
    print()
    input("按 Enter 键继续...")

def open_release_dir():
    """打开发布目录"""
    project_dir = os.getcwd()
    release_path = os.path.join(project_dir, 'build', 'windows', 'x64', 'runner', 'Release')
    
    if os.path.exists(release_path):
        if sys.platform == 'win32':
            os.startfile(release_path)
        else:
            subprocess.run(['open', release_path])
        print_success(f"已打开目录: {release_path}")
    else:
        print_error("发布目录不存在，请先构建项目。")
    
    print()
    input("按 Enter 键继续...")

def show_menu():
    """显示菜单"""
    while True:
        os.system('cls' if sys.platform == 'win32' else 'clear')
        
        print_header("Fitness Tracker Build Tool v1.0")
        
        print(f"  {Colors.CYAN}[1]{Colors.RESET} 🧹 清理 (flutter clean)")
        print(f"  {Colors.CYAN}[2]{Colors.RESET} 🚀 调试 (flutter run)")
        print(f"  {Colors.CYAN}[3]{Colors.RESET} 📦 构建 (flutter build)")
        print(f"  {Colors.CYAN}[4]{Colors.RESET} 📂 打开构建目录")
        print(f"  {Colors.CYAN}[5]{Colors.RESET} 🔄 清理 → 获取依赖 → 调试")
        print(f"  {Colors.CYAN}[6]{Colors.RESET} ⚡ 清理 → 获取依赖 → 构建")
        print(f"  {Colors.CYAN}[0]{Colors.RESET} 🚪 退出")
        print()
        
        choice = input(f"{Colors.YELLOW}请输入选项 (0-6): {Colors.RESET}").strip()
        
        if choice == '0':
            print()
            print_success("再见！")
            break
        
        elif choice == '1':
            if verify_project():
                clean_project()
            input("\n按 Enter 键返回菜单...")
        
        elif choice == '2':
            if verify_project():
                debug_mode()
        
        elif choice == '3':
            if verify_project():
                build_release()
        
        elif choice == '4':
            open_release_dir()
        
        elif choice == '5':
            if verify_project():
                clean_project()
                print()
                input("按 Enter 键启动调试...")
                debug_mode()
        
        elif choice == '6':
            if verify_project():
                clean_project()
                print()
                input("按 Enter 键开始构建...")
                build_release()
        
        else:
            print_error("无效选项，请重新选择")
            time.sleep(1)

def main():
    """主函数"""
    # 检查是否在正确的目录
    if not verify_project():
        print()
        input("按 Enter 键退出...")
        sys.exit(1)
    
    # 如果有命令行参数，直接执行
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        if arg == 'clean':
            clean_project()
        elif arg == 'debug':
            debug_mode()
        elif arg == 'build':
            build_release()
        elif arg == 'all':
            clean_project()
            build_release()
        else:
            print_error(f"未知参数: {arg}")
            print_info("可用参数: clean, debug, build, all")
    else:
        # 显示交互式菜单
        show_menu()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print()
        print()
        print_success("操作已取消")
    except Exception as e:
        print_error(f"发生错误: {e}")
        print()
        input("按 Enter 键退出...")