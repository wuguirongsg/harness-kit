# locales/ — 中英文双语支持（预留目录）

> **状态：设计阶段，尚未实现。** 目录结构已预留，等待 feat-010 实施。
> 详细设计见 `docs/design/i18n-bilingual.md`。

---

## 目录结构（规划）

```
locales/
├── zh/            # 中文语言包（默认）
│   ├── SESSION_START.md
│   ├── SESSION_END.md
│   ├── HARNESS_SETUP.md
│   ├── AGENTS.md
│   └── hooks/     # 含中文 echo 的 hook 脚本
│       ├── session-start.sh
│       ├── session-end.sh
│       └── guard-dangerous.sh
└── en/            # 英文语言包
    ├── SESSION_START.md
    ├── SESSION_END.md
    ├── HARNESS_SETUP.md
    ├── AGENTS.md
    └── hooks/
        ├── session-start.sh
        ├── session-end.sh
        └── guard-dangerous.sh
```

## 使用方式（规划）

安装时通过 `--lang` 参数选择语言，默认中文：

```bash
bash install.sh --lang en /path/to/project   # 英文版
bash install.sh                               # 中文版（默认）
```

`install.sh` / `install.bat` 根据所选语言，将 `locales/<lang>/` 下的文件
覆盖 `template/` 对应位置后再执行常规复制流程。

## 需要本地化的文件清单

| 文件 | 说明 |
|------|------|
| `SESSION_START.md` | 8 个阶段协议，中文固定句式最多 |
| `SESSION_END.md` | 各阶段收尾清单 |
| `HARNESS_SETUP.md` | 初始化引导协议 |
| `AGENTS.md` | Agent 规范占位 |
| `hooks/session-start.sh` | 动态拼接的中文标题 / 统计输出 |
| `hooks/session-end.sh` | 中文提示信息 |
| `hooks/guard-dangerous.sh` | 中文拦截消息 |
| `.cursor/rules/karpathy-guidelines.mdc` | 编码准则（中英混合） |

**不需要本地化的文件**（含纯代码逻辑或不可翻译标识符）：

- `hooks/post-write.sh`、`hooks/commit-msg`（无自然语言输出）
- `state/features.json`、`registry/_index.md`（结构性占位，标识符不翻译）
- `.claude/settings.json`、`.cursor/hooks.json`（配置文件）
