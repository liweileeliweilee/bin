#!/usr/bin/env python3
import os
import subprocess
import sys
import re
import socket
import shutil
from datetime import datetime

def get_system_info():
    """獲取系統識別資訊"""
    try:
        hostname = socket.gethostname()
    except:
        hostname = "unknown-host"
    
    username = os.getenv('USER') or os.getenv('USERNAME') or "unknown-user"
    script_name = os.path.basename(sys.argv[0])
    
    return {
        'hostname': hostname,
        'username': username,
        'script_name': script_name,
        'timestamp': datetime.now().strftime('%Y%m%d-%H%M%S')
    }

def get_git_helper_identity():
    """生成Git Helper的識別資訊"""
    system_info = get_system_info()
    
    return {
        'author_name': f"{system_info['username']}@{system_info['hostname']}-via-{system_info['script_name']}",
        'author_email': f"git-helper@{system_info['hostname']}.local",
        'commit_prefix': f"[{system_info['script_name']} on {system_info['hostname']} by {system_info['username']}]"
    }

# 全局識別配置
GIT_HELPER_IDENTITY = get_git_helper_identity()

def run_command(command, use_helper_identity=False):
    """執行命令並返回結果"""
    print(f"執行指令: {command}")
    try:
        env = os.environ.copy()
        
        if use_helper_identity:
            env['GIT_AUTHOR_NAME'] = GIT_HELPER_IDENTITY['author_name']
            env['GIT_AUTHOR_EMAIL'] = GIT_HELPER_IDENTITY['author_email']
            env['GIT_COMMITTER_NAME'] = GIT_HELPER_IDENTITY['author_name']
            env['GIT_COMMITTER_EMAIL'] = GIT_HELPER_IDENTITY['author_email']
        
        result = subprocess.run(command, shell=True, capture_output=True, text=True, env=env)
        if result.returncode == 0:
            return result.stdout if result.stdout else "操作成功完成"
        else:
            return f"錯誤: {result.stderr}"
    except Exception as e:
        return f"錯誤: {str(e)}"

def git_helper_commit(message):
    """使用Git Helper的專用提交函數"""
    # 跳脫特殊字元
    safe_message = message.replace('"', '\\"').replace('`', '\\`').replace('$', '\\$')
    
    formatted_message = f"{GIT_HELPER_IDENTITY['commit_prefix']} {safe_message}"
    print(f"執行指令: git commit -m \"{formatted_message}\"")
    
    # 使用直接參數傳遞，避免 shell 解析
    try:
        env = os.environ.copy()
        env['GIT_AUTHOR_NAME'] = GIT_HELPER_IDENTITY['author_name']
        env['GIT_AUTHOR_EMAIL'] = GIT_HELPER_IDENTITY['author_email']
        
        result = subprocess.run(
            ['git', 'commit', '-m', formatted_message],
            env=env,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            return result.stdout if result.stdout else "提交成功完成"
        else:
            return f"錯誤: {result.stderr}"
            
    except Exception as e:
        return f"錯誤: {str(e)}"

def get_repo_info():
    """獲取倉庫資訊，包括遠端URL和本地目錄名稱"""
    repo_info = {
        'is_git_repo': False,
        'has_remote': False,
        'remote_url': None,
        'repo_name': os.path.basename(os.getcwd()),
        'username': None
    }
    
    try:
        print("執行指令: git rev-parse --is-inside-work-tree")
        subprocess.run(['git', 'rev-parse', '--is-inside-work-tree'], 
                      capture_output=True, check=True)
        repo_info['is_git_repo'] = True
        
        print("執行指令: git remote get-url origin")
        result = subprocess.run(['git', 'remote', 'get-url', 'origin'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            repo_info['has_remote'] = True
            repo_info['remote_url'] = result.stdout.strip()
            
            match = re.search(r'[:/]([^/]+)/[^/]+\.git$', repo_info['remote_url'])
            if match:
                repo_info['username'] = match.group(1)
        
    except:
        pass
    
    return repo_info

def detect_username():
    """智能檢測用戶名（允許使用者確認或修改）"""
    repo_info = get_repo_info()
    detected = None

    if repo_info['username']:
        detected = repo_info['username']
    else:
        try:
            print("執行指令: git config user.name")
            result = subprocess.run(['git', 'config', 'user.name'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                detected = result.stdout.strip()
        except:
            pass
    
    if not detected:
        try:
            username = os.getenv('USER') or os.getenv('USERNAME')
            if username:
                detected = username.lower()
        except:
            pass
    
    if not detected:
        detected = "liweileeliweilee"

    # 提示使用者確認或輸入
    user_input = input(f"github的使用者名稱 ({detected}): ").strip()
    if user_input:
        return user_input
    return detected

def ensure_remote_setup():
    """確保遠端倉庫已正確設定"""
    repo_info = get_repo_info()
    
    if not repo_info['is_git_repo']:
        return "不在Git倉庫中"
    
    if repo_info['has_remote']:
        return repo_info['remote_url']
    
    username = detect_username()
    repo_name = repo_info['repo_name']
    remote_url = f"git@github.com:{username}/{repo_name}.git"
    
    print(f"自動設定遠端倉庫: {remote_url}")
    result = run_command(f'git remote add origin {remote_url}')
    
    try:
        validation = run_command(f'git ls-remote {remote_url} --heads 2>/dev/null || echo "invalid"')
        if "invalid" in validation:
            print(f"警告: 遠端倉庫可能不存在: {remote_url}")
    except:
        pass
    
    return remote_url

def convert_to_ssh_url(url):
    """將HTTPS URL轉換為SSH URL"""
    if url.startswith('https://github.com/'):
        return url.replace('https://github.com/', 'git@github.com:')
    return url

def get_current_branch():
    """取得當前分支名稱"""
    try:
        result = subprocess.run(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], capture_output=True, text=True)
        if result.returncode == 0:
            branch = result.stdout.strip()
            return branch if branch else "main"
    except:
        pass
    return "main"

def smart_clone():
    """智能克隆倉庫 (git clone)"""
    url = input("請輸入倉庫 URL (直接Enter使用智能生成): ").strip()
    
    if not url:
        repo_name = input("請輸入倉庫名稱: ").strip()
        if not repo_name:
            repo_name = input("請輸入要克隆的倉庫名稱: ").strip()
        
        username = detect_username()
        url = f"git@github.com:{username}/{repo_name}.git"
        print(f"使用智能生成URL: {url}")
    
    url = convert_to_ssh_url(url)
    
    # 添加分支选择
    branch = input("請輸入要克隆的分支名稱 (預設: main): ").strip()
    clone_command = f'git clone {url}'
    
    if branch:
        clone_command += f' --branch {branch}'
        print(f"將克隆分支: {branch}")
    else:
        print("使用預設分支: main")
    
    print(f"\n=== 克隆倉庫 (git clone) ===")
    result = run_command(clone_command)
    print(result)
    
    if "正克隆 into" in result or "Cloning into" in result:
        match = re.search(r"into '([^']+)'", result)
        if match:
            repo_dir = match.group(1)
            os.chdir(repo_dir)
            print(f"已切換到目錄: {os.getcwd()}")
    
    return result

def smart_init():
    """智能初始化倉庫 (git init)"""
    print("\n=== 初始化倉庫 (git init) ===")
    result = run_command('git init')
    print(result)
    
    # 先詢問用戶是否要設定遠端倉庫
    setup_remote = input("\n是否要設定遠端倉庫? (Y/n): ").strip().lower()
    
    if setup_remote == 'y' or setup_remote == '':
        # 詢問用戶遠端倉庫名稱
        default_repo_name = os.path.basename(os.getcwd())
        repo_name = input(f"請輸入遠端倉庫名稱 (預設: {default_repo_name}): ").strip() or default_repo_name
        
        # 詢問用戶 GitHub 用戶名
        username = detect_username()
        
        # 生成遠端 URL
        remote_url = f"git@github.com:{username}/{repo_name}.git"
        https_url = f"https://github.com/{username}/{repo_name}.git"
        
        # 確認設定
        confirm = input(f"遠端倉庫將設定為: {remote_url}\n確認嗎? (Y/n): ").strip().lower()
        
        if confirm == 'y' or confirm == '':
            # 設定遠端
            run_command(f'git remote add origin {remote_url}')
            
            # 檢查遠端倉庫是否存在
            validation = run_command(f'git ls-remote {remote_url} --heads 2>/dev/null || echo "invalid"')
            if "invalid" in validation:
                print(f"⚠️  遠端倉庫可能不存在: {remote_url}")
                print(f"📋 請在 GitHub 上創建倉庫: https://github.com/new")
                print(f"🔧 倉庫名稱: {repo_name}")
                print(f"👤 用戶名: {username}")
                print(f"🔗 創建後可以使用: git push -u origin main")
            else:
                print(f"✅ 遠端已設定為: {remote_url}")
        else:
            print("取消設定遠端倉庫")
    else:
        print("跳過遠端倉庫設定")
    
    if not os.path.exists('.gitignore'):
        basic_gitignore = """# 編譯產物
/build/
/dist/
/out/

# 依賴管理
/node_modules/
/vendor/

# 日誌檔案
*.log
logs/

# 作業系統
.DS_Store
Thumbs.db

# Python
__pycache__/
*.pyc
"""
        with open('.gitignore', 'w') as f:
            f.write(basic_gitignore)
        print("執行指令: 創建 .gitignore 檔案")
        print("已創建基本 .gitignore")
    
    # 按照您的要求修改提示文字
    rename_choice = input("\n是否將本地預設分支master自動重新命名為 'main'(跟github WebGUI的一樣)? (Yy/Nn): ").strip().lower()
    
    # 修改條件：按Enter（空字串）或輸入y都執行重命名
    if rename_choice == 'y' or rename_choice == '':
        # 直接嘗試重命名，不先檢查是否存在
        rename_result = run_command('git branch -m master main')
        print(rename_result)
        if "錯誤" not in rename_result and "fatal" not in rename_result.lower():
            print("已將分支重命名為 'main'")
        else:
            # 如果重命名失敗，可能是因為分支已經不存在或是其他原因
            print("重命名失敗或分支已不存在")
    else:
        print("保持預設分支為 'master'")
    
    # 添加一些有用的指引
    print("\n📋 下一步建議:")
    print("1. 添加檔案: git add .")
    print("2. 提交更改: git commit -m '初始提交'")
    print("3. 如果遠端倉庫已存在: git push -u origin main")
    print("4. 如果遠端倉庫不存在: 請先在 GitHub 上創建倉庫")
    
    return result

def restore_file():
    """回復檔案功能 (git restore)"""
    print("\n=== 回復檔案 (git restore) ===")
    file_path = input("請輸入要回復的檔案路徑: ").strip()
    
    if not file_path:
        print("請輸入檔案路徑")
        return
    
    if not os.path.exists(file_path):
        print(f"錯誤: 檔案 '{file_path}' 不存在")
        return
    
    # 先備份檔案
    backup_path = f"{file_path}.backup"
    shutil.copy2(file_path, backup_path)
    print(f"已創建備份: {backup_path}")
    
    print("\n回復選項:")
    print("1. 回復到最新提交版本 (git restore)")
    print("2. 回復到特定提交版本")
    print("3. 先查看差異再決定")
    
    restore_choice = input("請選擇 (1-3): ").strip()
    
    if restore_choice == '1':
        result = run_command(f'git restore {file_path}')
        print(result)
        print(f"已回復 {file_path} 到最新提交版本")
        
    elif restore_choice == '2':
        history_result = run_command(f'git log --oneline -- {file_path}')
        print("檔案提交歷史:")
        print(history_result if history_result else "無歷史記錄")
        
        commit_hash = input("請輸入要回復的提交哈希值 (前7位即可): ").strip()
        if commit_hash:
            result = run_command(f'git restore --source={commit_hash} {file_path}')
            print(result)
            print(f"已回復 {file_path} 到提交 {commit_hash}")
            
    elif restore_choice == '3':
        diff_result = run_command(f'git diff {file_path}')
        print("當前修改的差異:")
        print(diff_result if diff_result else "無差異")
        
        confirm = input("是否要回復? (y/N): ").strip().lower()
        if confirm == 'y':
            result = run_command(f'git restore {file_path}')
            print(result)
            print(f"已回復 {file_path}")
    else:
        print("無效選擇")

def view_file_history():
    """查看檔案歷史 (git log -- 檔案名稱)"""
    print("\n=== 查看檔案歷史 (git log) ===")
    file_path = input("請輸入要查看歷史的檔案路徑: ").strip()
    if file_path:
        result = run_command(f'git log --oneline -- {file_path}')
        print(result if result else "該檔案無提交歷史")
    else:
        print("請輸入有效的檔案路徑")

def get_commit_history_with_source():
    """顯示提交歷史並詳細標記來源"""
    print("\n=== 提交歷史 (git log) - 詳細來源標記 ===")
    
    result = run_command('git log --pretty=format:"%h - %an (%ae) - %ad - %s" --date=short -20')
    
    if not result or "錯誤" in result:
        print("暫無提交歷史")
        return
    
    lines = result.split('\n')
    for line in lines:
        if 'github-web-ui' in line:
            print(f"Web UI: {line}")
        elif 'git-helper' in line.lower() or '-via-' in line:
            print(f"Git-Helper: {line}")
        else:
            print(f"手動Git: {line}")

def show_identity_info():
    """顯示當前識別資訊"""
    system_info = get_system_info()
    print("\n=== 當前識別資訊 ===")
    print(f"主機名稱: {system_info['hostname']}")
    print(f"使用者: {system_info['username']}")
    print(f"執行檔: {system_info['script_name']}")
    print(f"作者名稱: {GIT_HELPER_IDENTITY['author_name']}")
    print(f"作者郵箱: {GIT_HELPER_IDENTITY['author_email']}")
    print(f"提交前綴: {GIT_HELPER_IDENTITY['commit_prefix']}")

def print_menu_simple():
    """顯示選單（純文字版本）"""
    print("\n" + "="*60)
    print("Git 操作助手")
    print("="*60)
    print("1.  檢查狀態 (git status)")
    print("2.  添加所有變更 (git add -A)")
    print("3.  提交變更 (git commit) - 帶識別標記")
    print("4.  推送到 GitHub (git push)")
    print("5.  拉取更新 (git pull)")
    print("6.  查看歷史 (git log)")
    print("7.  智能克隆倉庫 (git clone)")
    print("8.  智能初始化倉庫 (git init)")
    print("9.  設置遠端倉庫 (git remote add)")
    print("10. 強制推送 (git push --force)")
    print("11. 處理刪除的檔案 (git rm)")
    print("12. 查看分支資訊 (git branch)")
    print("13. 查看遠端資訊 (git remote -v)")
    print("14. 創建新分支 (git checkout -b)")
    print("15. 修復遠端設定")
    print("16. 顯示倉庫資訊")
    print("17. 查看標記的提交歷史 (git log)")
    print("18. 顯示當前識別資訊")
    print("19. 回復檔案 (git restore)")
    print("20. 查看檔案歷史 (git log -- 檔案名稱)")
    print("0.  退出")
    print("="*60)

def main():
    print("Git 操作助手已啟動!")
    print("當前工作目錄:", os.getcwd())
    print(f"識別標記: {GIT_HELPER_IDENTITY['commit_prefix']}")
    
    try:
        print("執行指令: git rev-parse --is-inside-work-tree")
        subprocess.run(['git', 'rev-parse', '--is-inside-work-tree'], 
                      capture_output=True, check=True)
        ensure_remote_setup()
    except:
        print("注意: 當前不在 Git 倉庫中")
    
    while True:
        print_menu_simple()
        choice = input("請選擇操作: ").strip()
        
        if choice == '0':
            print("感謝使用！")
            break
            
        elif choice == '1':
            print("\n=== 檢查狀態 (git status) ===")
            result = run_command('git status')
            print(result)
            
        elif choice == '2':
            print("\n=== 添加所有變更 (git add -A) ===")
            result = run_command('git add -A')
            print(result)
            
        elif choice == '3':
            message = input("請輸入提交訊息: ").strip()
            if not message:
                message = "更新提交"
            print(f"\n=== 提交變更 (git commit) - 帶識別標記 ===")
            result = git_helper_commit(message)
            print(result)
            
        elif choice == '4':
            default_branch = get_current_branch()
            branch = input(f"請輸入分支名稱 (預設: {default_branch}): ").strip() or default_branch
            print(f"\n=== 推送到 GitHub (git push) ===")
            ensure_remote_setup()
            result = run_command(f'git push origin {branch}')
            print(result)
            
            # 添加智慧提示和選項
            if "rejected" in result and "fetch first" in result:
                print("\n⚠️  遠端有您沒有的更新，請選擇處理方式:")
                print("1. 先拉取更新再推送 (推薦) - 選擇選項5")
                print("2. 強制覆寫遠端 (危險) - 選擇選項10")
                print("3. 放棄推送")
                
                push_choice = input("請選擇 (1-3): ").strip()
                if push_choice == '1':
                    # 自動執行拉取
                    print("\n=== 自動執行拉取更新 ===")
                    pull_result = run_command(f'git pull origin {branch}')
                    print(pull_result)
                    
                    # 再次嘗試推送
                    if "error" not in pull_result.lower():
                        print("\n=== 再次嘗試推送 ===")
                        push_again = run_command(f'git push origin {branch}')
                        print(push_again)
                        
                elif push_choice == '2':
                    # 詢問確認強制推送
                    confirm = input("⚠️  確定要強制覆寫遠端倉庫嗎？這會丟失遠端的更改！(y/N): ").strip().lower()
                    if confirm == 'y':
                        print("\n=== 執行強制推送 ===")
                        force_result = run_command(f'git push --force origin {branch}')
                        print(force_result)
            
        elif choice == '5':
            default_branch = get_current_branch()
            branch = input(f"請輸入分支名稱 (預設: {default_branch}): ").strip() or default_branch
            print("\n=== 拉取更新 (git pull) ===")
            ensure_remote_setup()
            result = run_command(f'git pull origin {branch}')
            print(result)
            
            # 添加提示訊息
            if "error:" in result.lower() or "衝突" in result.lower() or "conflict" in result.lower():
                print("\n⚠️  提示: 如果遇到衝突，請手動解決衝突後再提交")
            elif "已經是最新的" in result or "Already up to date" in result:
                print("✅ 本地倉庫已經是最新的")
            
        elif choice == '6':
            print("\n=== 查看歷史 (git log) ===")
            result = run_command('git log --oneline -10')
            print(result if result else "暫無提交歷史")
            
        elif choice == '7':
            smart_clone()
                
        elif choice == '8':
            smart_init()
            
        elif choice == '9':
            url = input("請輸入遠端倉庫 URL: ").strip()
            if url:
                name = input("請輸入遠端名稱 (預設: origin): ").strip() or "origin"
                
                # 檢查遠端是否已存在
                check_result = run_command(f'git remote get-url {name} 2>/dev/null; echo $?')
                if '0' in check_result:
                    # 遠端已存在，詢問是否要覆蓋
                    overwrite = input(f"遠端 '{name}' 已存在，是否要覆蓋? (y/N): ").strip().lower()
                    if overwrite != 'y':
                        print("取消設置遠端倉庫")
                        continue
                    # 先移除現有的遠端
                    run_command(f'git remote remove {name}')
                
                print(f"\n=== 設置遠端倉庫 (git remote add) ===")
                result = run_command(f'git remote add {name} {url}')
                print(result if result else "設置成功")
                
        elif choice == '10':
            default_branch = get_current_branch()
            branch = input(f"請輸入分支名稱 (預設: {default_branch}): ").strip() or default_branch
            
            # 更明確的警告訊息
            print("⚠️  " + "="*50)
            print("⚠️  警告：強制推送會覆寫遠端歷史！")
            print("⚠️  這會導致遠端倉庫的更改永久丟失！")
            print("⚠️  請確保您知道自己在做什麼！")
            print("⚠️  " + "="*50)
            
            confirm = input("確定要強制推送嗎？(輸入 'YES' 確認): ").strip()
            if confirm == 'YES':
                print(f"\n=== 強制推送 (git push --force) ===")
                ensure_remote_setup()
                result = run_command(f'git push --force origin {branch}')
                print(result)
            else:
                print("取消強制推送")
                
        elif choice == '11':
            print("\n=== 處理刪除的檔案 (git rm) ===")
            result = run_command('git status')
            print(result)
            
        elif choice == '12':
            print("\n=== 查看分支資訊 (git branch) ===")
            result = run_command('git branch -a')
            print(result)
            
        elif choice == '13':
            print("\n=== 查看遠端資訊 (git remote -v) ===")
            result = run_command('git remote -v')
            print(result)
            
        elif choice == '14':
            branch = input("請輸入新分支名稱: ").strip()
            if branch:
                print(f"\n=== 創建新分支 (git checkout -b) ===")
                result = run_command(f'git checkout -b {branch}')
                print(result)
                
        elif choice == '15':
            print("\n=== 修復遠端設定 ===")
            remote_url = ensure_remote_setup()
            print(f"遠端已設定為: {remote_url}")
            result = run_command('git remote -v')
            print(result)
                
        elif choice == '16':
            print("\n=== 倉庫資訊 ===")
            repo_info = get_repo_info()
            for key, value in repo_info.items():
                print(f"{key}: {value}")
                
        elif choice == '17':
            get_commit_history_with_source()
                
        elif choice == '18':
            show_identity_info()
                
        elif choice == '19':
            restore_file()
                
        elif choice == '20':
            view_file_history()
                
        else:
            print("無效選擇")
        
        input("\n按 Enter 繼續...")

if __name__ == '__main__':
    main()
