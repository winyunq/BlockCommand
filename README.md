# BlockCommand - Terminal Shield Guarding Against Risky AI Commands

Have you ever suffered from the reckless decisions of AI coding assistants? They always tend to swing between two extremes.

### 🎭 A Familiar Drama

> **User**: "Help me design feature XX."
>
> **AI**: "Sure, I'll do that right away." *(makes edits)*
>
> **User**: "Great, now add feature YY."
>
> **AI**: "No problem!" *(edits again, messing up previous logic)*
>
> **User**: "Actually, this is worse than before."
>
> **AI**: `git checkout .` *(wipes out all uncommitted changes, including your own precious manual modifications)*
>
> **User**: "WHAT?!"

---

Taking Git version management as an example, dealing with AI assistants can be a painful dilemma:
* **Either they never use Git to back up versions**, letting important local changes disappear silently during massive AI rewrites;
* **Or they abuse tools**, executing commands like `git checkout .` or `git restore` as if they were toys, with zero regard for safety.

Sometimes, this leads to catastrophic consequences!

If we grant AI agents full terminal access, we live in constant fear of their recklessness, bearing the risk of data loss. If we deny them terminal access entirely, our development and collaboration productivity drops significantly.

It feels like always increasing the system variance while dragging down the expected return.
Since these risks are caused by a few high-risk instructions, **let's lock those risk-prone commands!**

---

## 🚀 How It Works

`BlockCommand` is a lightweight **PowerShell Command Interceptor** designed for Windows.
By injecting a secure wrapper function into your PowerShell `$PROFILE`, it proxies and monitors specific commands and subcommands.

Whenever an AI agent (or you yourself) runs a risky command (e.g., `git checkout` or `git restore`), the wrapper intercepts the process and **forces you to enter a validation password**:
* **Correct Password**: The command is handed off to the original executable and executes normally.
* **Incorrect/No Password**: The command is aborted with a `deny` feedback, successfully preventing the AI from discarding your unsaved changes.

---

## 📦 Getting Started

### 1. Download the Script
Download `setup.ps1` from this repository.

### 2. Run the Installer
Double-click `setup.ps1` or run it in your PowerShell terminal:
```powershell
./setup.ps1
```

### 3. Setup Your Password & Rules
* Enter your desired validation password when prompted during setup.
* By default, it intercepts `git checkout` and `git restore`.
* You can configure additional rules (such as `git reset --hard` or `rm`) by editing the configuration hash table at the top of the script:
```powershell
$INTERCEPT_RULES = @{
    "git" = @{
        "subs" = @("checkout", "restore");
        "warn" = "need user agree"
    }
}
```

### 4. Uninstall
To completely remove the interception policy, simply run the script again and type `uninstall`.

---

## ⭐ Support & Star

Share this with friends who are also co-piloting with AI!
If this tool saves your code from AI accidents, please give us a **Star** 🌟!

I am more than happy to design customized blocking scripts and rules based on your scenarios and feedback.
