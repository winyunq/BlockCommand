# ==============================================================================
# [Configuration Area / 配置参数区]
# ==============================================================================
# EN: Define target commands, subcommands, and the customized warning message.
# ZH: 定义要拦截的目标命令、子命令，以及自定义的警告提示信息。
# Format: @{ "main_cmd" = @{ "subs" = @("sub1", "sub2"); "warn" = "Custom Alert Message" } }
$INTERCEPT_RULES = @{
    "git" = @{
        "subs" = @("checkout", "restore","push");
        "warn" = "need user agree"
    }
}

# EN: Script display language during installation ("ZH" for Chinese, "EN" for English).
# ZH: 脚本安装期间控制台显示的语言（"ZH" 表示中文，"EN" 表示英文）。
$DISPLAY_LANGUAGE = "ZH"
# ==============================================================================

# EN: Auto-bypass restricted execution policies if needed.
# ZH: 如果执行策略受限，自动以 Bypass 临时策略重新拉起本脚本。
if ($env:PSExecutionPolicyRestore -eq $null -and (Get-ExecutionPolicy) -eq "Restricted") {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# EN: Localization Resources for Installation CLI
# ZH: 安装程序自身的本地化多语言文本资源
$Text = @{
    "ZH" = @{
        "Title"       = "             Command Interceptor"
        "Banner"      = "=========================================================="
        "Intercepts"  = "当前配置拦截以下命令操作: "
        "Prompt"      = "请输入要设置的命令拦截密码（输入 'uninstall' 将卸载保护）"
        "InputLabel"  = "您的输入"
        "Uninstalled" = "已成功卸载命令保护策略！"
        "NoPolicy"    = "配置文件中未发现保护策略，无需卸载。"
        "NoProfile"   = "配置文件不存在，无需卸载。"
        "EmptyPwd"    = "错误: 密码不能为空！"
        "Installed"   = "已经成功加载并配置命令保护策略！"
        "RuleInfo"    = "保护规则映射已部署！"
        "PwdInfo"     = "设置的校验密码: "
        "RestartHint" = "请重启所有的终端窗口使配置生效。"
        "PressKey"    = "按任意键退出..."
        "AskPwd"      = "Password: "
        "Fail"        = "deny"
    }
    "EN" = @{
        "Title"       = "             Command Interceptor Configurator"
        "Banner"      = "=========================================================="
        "Intercepts"  = "Current interception rules configured: "
        "Prompt"      = "Enter the validation password (or type 'uninstall' to remove protection)"
        "InputLabel"  = "Your Input"
        "Uninstalled" = "Interception policy uninstalled successfully!"
        "NoPolicy"    = "No protection policy found in your Profile."
        "NoProfile"   = "Profile file does not exist, nothing to uninstall."
        "EmptyPwd"    = "Error: Password cannot be empty!"
        "Installed"   = "Protection policy loaded and configured successfully!"
        "RuleInfo"    = "Protection Rules Map Deployed!"
        "PwdInfo"     = "Validation Password: "
        "RestartHint" = "Please restart all terminal windows to apply."
        "PressKey"    = "Press any key to exit..."
        "AskPwd"      = "Password: "
        "Fail"        = "deny"
    }
}

$L = $Text[$DISPLAY_LANGUAGE]

Clear-Host
Write-Host $L["Banner"] -ForegroundColor Cyan
Write-Host $L["Title"] -ForegroundColor Green
Write-Host $L["Banner"] -ForegroundColor Cyan
Write-Host $L["Intercepts"] -ForegroundColor Yellow

# EN: Construct the hash map string representation for runtime injection.
# ZH: 解析并构建注入用的多维哈希字符串映射表。
$mapItems = @()
foreach ($key in $INTERCEPT_RULES.Keys) {
    $rule = $INTERCEPT_RULES[$key]
    $subCmds = ($rule["subs"] | ForEach-Object { "`"$_`"" }) -join ", "
    $customWarn = $rule["warn"]
    Write-Host " - $key [ $subCmds ] -> Alert: $customWarn" -ForegroundColor Red
    
    $mapItems += "`"$key`" = @{ `"subs`" = @($subCmds); `"warn`" = `"$customWarn`" }"
}
$rulesMapString = "@{" + ($mapItems -join "; ") + "}"

# EN: Prompt for input.
# ZH: 交互式提示输入。
Write-Host $L["Prompt"] -ForegroundColor Cyan
$userInput = Read-Host $L["InputLabel"]

if ($userInput -eq "uninstall") {
    # EN: Uninstall policy.
    # ZH: 卸载逻辑。
    if (Test-Path $PROFILE) {
        $content = Get-Content $PROFILE -Raw
        if ($content -and ($content.Contains("Command Interceptor AI Shield"))) {
            $cleanContent = $content -replace "(?s)# ==================== Command Interceptor AI Shield ====================.*?# ========================================================================\r?\n?", ""
            Set-Content -Path $PROFILE -Value $cleanContent -Encoding utf8
            Write-Host $L["Uninstalled"] -ForegroundColor Green
        } else {
            Write-Host $L["NoPolicy"] -ForegroundColor Yellow
        }
    } else {
        Write-Host $L["NoProfile"] -ForegroundColor Yellow
    }
} else {
    # EN: Load and Install policy.
    # ZH: 安装与加载逻辑。
    if ([string]::IsNullOrEmpty($userInput)) {
        Write-Host $L["EmptyPwd"] -ForegroundColor Red
    } else {
        $profileDir = Split-Path $PROFILE -Parent
        if (!(Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        if (!(Test-Path $PROFILE)) {
            New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        }

        # EN: Core payload to be injected into PowerShell PROFILE.
        # ZH: 注入到 PROFILE 的通用极简拦截函数。
        $interceptCode = @'

# ==================== Command Interceptor AI Shield ====================
$InterceptRules = _PLACEHOLDER_RULES_
$ShieldPassword = "_PLACEHOLDER_PASSWORD_"

function Invoke-InterceptedCommand {
    param(
        [string]$CmdName,
        [object]$CmdArgs
    )
    
    # Check if target command and subcommands match
    if ($CmdArgs.Count -gt 0 -and $InterceptRules.ContainsKey($CmdName)) {
        $rule = $InterceptRules[$CmdName]
        $subcommands = $rule["subs"]
        if ($subcommands -contains $CmdArgs[0]) {
            $alertMsg = $rule["warn"]
            
            # EN: Print: [command] [subcommand] need user agree
            # ZH: 打印: git checkout need user agree
            Write-Host "$CmdName $($CmdArgs[0]) $alertMsg" -ForegroundColor Yellow
            $pwd = Read-Host -AsSecureString "_PLACEHOLDER_ASK_"
            if ($pwd -ne $null) {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd)
                $Plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                if ($Plain -eq $ShieldPassword) {
                    Get-Command "$CmdName.exe" | Select-Object -ExpandProperty Definition | & $_ $CmdArgs
                    return
                }
            }
            # EN: Print 'deny' on failure
            # ZH: 验证失败直接打印 'deny'
            Write-Host "_PLACEHOLDER_FAIL_" -ForegroundColor Red
            return
        }
    }
    
    # Fallback to normal execution
    Get-Command "$CmdName.exe" | Select-Object -ExpandProperty Definition | & $_ $CmdArgs
}

# Dynamically define wrapper functions for each monitored command
foreach ($cmd in $InterceptRules.Keys) {
    Set-Item -Path "Env:\$cmd" -Value ""
    New-Item -Path "Function:\$cmd" -Value ([ValueType]::CreateInstance) -Force | Out-Null
    Set-Item -Path "Function:\$cmd" -Value (
        [scriptblock]::Create("Invoke-InterceptedCommand -CmdName '$cmd' -CmdArgs `$args")
    ) -Force
}
# ========================================================================
'@

        # Replace dynamic parameters inside code template
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_RULES_", $rulesMapString)
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_PASSWORD_", $userInput)
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_ASK_", $L["AskPwd"])
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_FAIL_", $L["Fail"])

        $currentContent = ""
        if (Test-Path $PROFILE) {
            $rawContent = Get-Content $PROFILE -Raw
            if ($rawContent) {
                $currentContent = $rawContent
            }
        }

        # EN: Clean existing old policy blocks to prevent duplications.
        # ZH: 清理可能存在的旧策略代码块。
        if ($currentContent.Contains("Command Interceptor AI Shield")) {
            $currentContent = $currentContent -replace "(?s)# ==================== Command Interceptor AI Shield ====================.*?# ========================================================================\r?\n?", ""
        }

        # EN: Write back updated code to system PROFILE.
        # ZH: 重新追加写入更新后的配置策略。
        $newContent = $currentContent.Trim() + "`r`n" + $interceptCode
        Set-Content -Path $PROFILE -Value $newContent -Encoding utf8

        Write-Host $L["Installed"] -ForegroundColor Green
        Write-Host "$($L['PwdInfo']) $userInput" -ForegroundColor Cyan
        Write-Host $L["RestartHint"] -ForegroundColor Yellow
    }
}

Write-Host "`n$($L['PressKey'])" -ForegroundColor Gray
[void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
