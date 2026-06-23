# ==============================================================================
# [Configuration Area / 配置参数区]
# ==============================================================================
# EN: Define target commands, subcommands, and the customized warning message.
# ZH: 定义要拦截的目标命令、子命令，以及自定义的警告提示信息。
# Format: @{ "main_cmd" = @{ "subs" = @("sub1", "sub2"); "warn" = "Custom Alert Message" } }
$INTERCEPT_RULES = @{
    "git" = @{
        "subs" = @("checkout", "restore", "reset");
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
        "MissingParam" = "缺少用户同意(_PLACEHOLDER_PARAM_NAME_=[您的密码])"
    }
    "EN" = @{
        "Title"       = "             Command Interceptor Configurator"
        "Banner"      = "=========================================================="
        "Intercepts"  = "Current interception rules configured: "
        "Prompt" = "Enter the validation password (or type 'uninstall' to remove protection)"
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
        "MissingParam" = "need Agree(by _PLACEHOLDER_PARAM_NAME_=[您的密码])"
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
        # Config options
        $authMode = "1" # Default: 1 (Only Parameter)
        $paramName = "UserAgree" # Default parameter name

        # Display Advanced Config query
        Write-Host ""
        if ($DISPLAY_LANGUAGE -eq "ZH") {
            Write-Host "是否执行高级安装？[Y/N] (默认: N): " -ForegroundColor Cyan -NoNewline
        } else {
            Write-Host "Perform advanced installation? [Y/N] (Default: N): " -ForegroundColor Cyan -NoNewline
        }
        $advanced = Read-Host
        
        if ($advanced -eq "Y" -or $advanced -eq "y") {
            Write-Host ""
            if ($DISPLAY_LANGUAGE -eq "ZH") {
                Write-Host "选择 AI 认证模式：" -ForegroundColor Cyan
                Write-Host "  1) 仅携带参数 (直接拒绝，要求带参数，推荐，默认)"
                Write-Host "  2) 仅输入密钥 (不推荐)"
                Write-Host "  3) 两者皆可"
                Write-Host "请选择 [1-3] (默认: 1): " -ForegroundColor Cyan -NoNewline
            } else {
                Write-Host "Select AI authentication mode:" -ForegroundColor Cyan
                Write-Host "  1) Only Parameter (Directly deny, require parameter, recommended, default)"
                Write-Host "  2) Only Password Input"
                Write-Host "  3) Both Allowed"
                Write-Host "Select option [1-3] (Default: 1): " -ForegroundColor Cyan -NoNewline
            }
            $modeChoice = Read-Host
            if ($modeChoice -match "^[1-3]$") {
                $authMode = $modeChoice
            }
            
            if ($authMode -eq "1" -or $authMode -eq "3") {
                Write-Host ""
                if ($DISPLAY_LANGUAGE -eq "ZH") {
                    Write-Host "请输入自定义参数名称 (默认: UserAgree): " -ForegroundColor Cyan -NoNewline
                } else {
                    Write-Host "Enter custom parameter name (Default: UserAgree): " -ForegroundColor Cyan -NoNewline
                }
                $customParam = Read-Host
                if (![string]::IsNullOrWhiteSpace($customParam)) {
                    $paramName = $customParam.Trim()
                }
            }
        }

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
$AuthMode = "_PLACEHOLDER_AUTH_MODE_"
$ParamName = "_PLACEHOLDER_PARAM_NAME_"

function Invoke-InterceptedCommand {
    param(
        [string]$CmdName,
        [object]$CmdArgs
    )
    
    # Strip .exe suffix from command name for rule lookup
    $ruleKey = $CmdName
    if ($ruleKey.EndsWith(".exe")) {
        $ruleKey = $ruleKey.Substring(0, $ruleKey.Length - 4)
    }
    
    # Check if target command and subcommands match
    if ($CmdArgs.Count -gt 0 -and $InterceptRules.ContainsKey($ruleKey)) {
        $rule = $InterceptRules[$ruleKey]
        $subcommands = $rule["subs"]
        if ($subcommands -contains $CmdArgs[0]) {
            $alertMsg = $rule["warn"]
            
            # Check parameter authentication if mode requires/allows it
            $expectedToken = "$ParamName=$ShieldPassword"
            $authenticatedByParam = $false
            if ($AuthMode -eq "1" -or $AuthMode -eq "3") {
                $cleanArgs = $CmdArgs | Where-Object { $_ -ne $expectedToken }
                $authenticatedByParam = ($cleanArgs.Count -lt $CmdArgs.Count)
            } else {
                $cleanArgs = $CmdArgs
            }
            
            if ($authenticatedByParam) {
                # Exec command with parameter cleaned
                $realCmd = $CmdName
                if (-not $realCmd.EndsWith(".exe")) {
                    $realCmd = "$realCmd.exe"
                }
                $cmdPath = (Get-Command -CommandType Application $realCmd).Definition
                & $cmdPath $cleanArgs
                return
            }
            
            # Parameter missing or auth mode is password only
            if ($AuthMode -eq "1") {
                # Only parameter mode: Deny immediately with clean warning, hiding plain password
                Write-Host "_PLACEHOLDER_MISSING_" -ForegroundColor Red
                return
            }
            
            # Mode 2 (Only Password) or Mode 3 (Both Allowed, parameter missing) -> prompt password
            Write-Host "$CmdName $($CmdArgs[0]) $alertMsg" -ForegroundColor Yellow
            $pwd = Read-Host -AsSecureString "_PLACEHOLDER_ASK_"
            if ($pwd -ne $null) {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd)
                $Plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                if ($Plain -eq $ShieldPassword) {
                    $realCmd = $CmdName
                    if (-not $realCmd.EndsWith(".exe")) {
                        $realCmd = "$realCmd.exe"
                    }
                    $cmdPath = (Get-Command -CommandType Application $realCmd).Definition
                    & $cmdPath $cleanArgs
                    return
                }
            }
            Write-Host "_PLACEHOLDER_FAIL_" -ForegroundColor Red
            return
        }
    }
    
    # Fallback to normal execution (use -CommandType Application to bypass script wrappers)
    $realCmd = $CmdName
    if (-not $realCmd.EndsWith(".exe")) {
        $realCmd = "$realCmd.exe"
    }
    $cmdPath = (Get-Command -CommandType Application $realCmd).Definition
    & $cmdPath $CmdArgs
}

# Dynamically define wrapper functions for each monitored command and its .exe version
foreach ($cmd in $InterceptRules.Keys) {
    # Define wrapper for basic command (e.g. git)
    Set-Item -Path "Function:\$cmd" -Value (
        [scriptblock]::Create("Invoke-InterceptedCommand -CmdName '$cmd' -CmdArgs `$args")
    ) -Force
    
    # Define wrapper for .exe suffix (e.g. git.exe) to prevent bypass
    if (-not $cmd.EndsWith(".exe")) {
        $exeCmd = "$cmd.exe"
        Set-Item -Path "Function:\$exeCmd" -Value (
            [scriptblock]::Create("Invoke-InterceptedCommand -CmdName '$exeCmd' -CmdArgs `$args")
        ) -Force
    }
}
# ========================================================================
'@

        # Replace dynamic parameters inside code template
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_RULES_", $rulesMapString)
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_PASSWORD_", $userInput)
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_AUTH_MODE_", $authMode)
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_PARAM_NAME_", $paramName)
        $missingParamMsg = $L["MissingParam"].Replace("_PLACEHOLDER_PARAM_NAME_", $paramName)
        $interceptCode = $interceptCode.Replace("_PLACEHOLDER_MISSING_", $missingParamMsg)
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
