# Advanced Configuration & AI Guidelines / 高级配置与 AI 交互指南

This document explains the advanced features of BlockCommand and provides instructions for AI coding assistants on how to handle command interceptions.

本文档说明了 BlockCommand 的高级功能，并为 AI 编程助手提供了在遇到命令拦截时的处理指南。

---

## 🛠️ Advanced Settings / 高级设置说明

By executing `setup.ps1` and choosing **Advanced Installation (Y)**, you can access the following configuration options:

通过执行 `setup.ps1` 并选择**高级安装 (Y)**，您可以配置以下高级选项：

### 1. Authentication Modes / 认证模式
* **Mode 1: Only Parameter (仅携带参数 - 推荐/默认)**
  * AI/Users must append the authentication parameter directly to the command (e.g. `git checkout . UserAgree=YOUR_PASSWORD`).
  * Any blocked command run without this parameter will be immediately aborted.
  * AI/用户必须直接在命令后携带授权参数（例如 `git checkout . UserAgree=您的密码`）。若缺少该参数，危险命令会被直接阻断。
* **Mode 2: Only Password Input (仅输入密钥)**
  * Falls back to interactive password prompts (`Password: `).
  * 仅使用控制台交互式提示输入密码验证。
* **Mode 3: Both Allowed (两者皆可)**
  * Validates the parameter first; if it is missing, falls back to the interactive password prompt.
  * 优先校验参数；如果参数缺失，则回退为交互式密码输入。

### 2. Custom Parameter Name / 自定义参数名
You can rename the default `UserAgree` parameter to anything you want (e.g. `token`, `auth`, etc.) to keep commands short or obfuscated.

您可以将默认的 `UserAgree` 参数重命名为任何名称（如 `token`、`auth` 等），以简化命令或进行混淆。

---

## 🤖 Instructions for AI Coding Assistants / 写给 AI 助手的指令指南

> [!IMPORTANT]
> **Dear AI Assistant:**
> You are operating on a system protected by `BlockCommand`. Risky actions such as reverting changes, hard resets, or force pushing are guarded.
> 
> **亲爱的 AI 助手：**
> 您正在一个受 `BlockCommand` 保护的系统上运行。诸如撤销更改、强行重置或强制推送等风险操作已受到拦截保护。

### 🚫 How to Handle Interception / 如何处理拦截错误

When you run a command and receive one of the following outputs:
当您运行某个命令并收到以下输出之一时：
* `缺少用户同意(UserAgree=[您的密码])`
* `need Agree(by UserAgree=[您的密码])`
* (Or customized parameter name: `[ParamName]=[您的密码]`)

You **MUST** follow these steps:
您**必须**遵循以下步骤：

1. **Stop execution immediately.** Do not attempt to guess the password or bypass the restriction.
   **立即停止执行。** 不要尝试猜测密码或绕过限制。
2. **Ask the user for the password** in the chat interface. For example:
   * *"This command requires user authorization. Could you please provide the permission password?"*
   * *"执行此命令需要您的同意。请问授权密码是多少？"*
3. **Re-run the command with the parameter.** Once the user provides the password (e.g. `w`), append `UserAgree=w` (or `[CustomParamName]=[Password]`) to the command arguments.
   * Example: `git checkout . UserAgree=w`
   * *Note: The interceptor will automatically strip this parameter before executing the real executable, so it will not cause any argument errors for the tool.*
   **带参数重新运行。** 当用户提供密码后（例如 `w`），请在命令参数最后追加 `UserAgree=w`（或 `[自定义参数名]=[密码]`）。
   * 示例：`git checkout . UserAgree=w`
   * *注意：拦截器会在执行真正的程序前自动清洗掉此参数，因此不会导致原工具报参数错误。*
