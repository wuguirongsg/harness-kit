# 设计文档：中英文双语支持（方案 B）

> **阶段**：DESIGN
> **关联功能**：feat-010
> **状态**：设计完成，待实施

---

## 背景

harness-kit 的协议文件（SESSION_START.md、SESSION_END.md、HARNESS_SETUP.md）和
Hook 脚本的输出目前以中文为主，英文用户无法顺畅使用。

调研了三种方案后，选择**方案 B：安装时语言包覆盖**。

## 方案对比

| 方案 | 说明 | 工作量 |
|------|------|--------|
| A. 仅翻译用户文档 | 只改 README、install 提示 | ~1 天，覆盖面窄 |
| **B. 语言包目录（本方案）** | `template/locales/<lang>/` 安装时覆盖 | ~1 周，覆盖协议核心 |
| C. 全链路运行时 i18n | key-value 化，运行时切换 | ~3 周，改动面极大 |

## 方案 B 设计

### 核心思路

```
template/
├── ...（通用文件，与语言无关）
└── locales/
    ├── zh/   # 中文语言包（当前内容的副本）
    └── en/   # 英文语言包
```

安装时，`install.sh` / `install.bat` 先执行常规复制，
再用 `locales/<lang>/` 下的文件**覆盖**对应位置，实现语言替换。

### 调用方式

```bash
# install.sh
bash install.sh                              # 中文（默认）
bash install.sh --lang en                   # 英文
bash install.sh --lang en /path/to/project  # 英文 + 指定目录

# install.bat（Windows）
install.bat                                  # 中文（默认）
install.bat --lang en                        # 英文
install.bat --lang en C:\path\to\project     # 英文 + 指定目录

# npx
npx harness-kit --lang en                    # 英文
```

### 覆盖逻辑（伪代码）

```bash
LANG_OPT="zh"   # 默认中文

# 解析 --lang 参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang) LANG_OPT="$2"; shift 2 ;;
    *) TARGET_DIR="$1"; shift ;;
  esac
done

# 验证语言包存在
LOCALE_DIR="$TMPL/locales/$LANG_OPT"
[ -d "$LOCALE_DIR" ] || { echo "不支持的语言：$LANG_OPT（可用：zh en）"; exit 1; }

# ... 常规复制完成后 ...

# 用语言包覆盖
if [ "$LANG_OPT" != "zh" ]; then
  cp -r "$LOCALE_DIR/." "$TARGET_DIR/.harness/"
  # 覆盖 hooks 中有本地化文字的脚本
  cp "$LOCALE_DIR/hooks/"*.sh "$TARGET_DIR/.harness/hooks/" 2>/dev/null || true
fi
```

### 需要本地化的文件

| 文件 | 原始位置 | 语言包路径 |
|------|---------|-----------|
| `SESSION_START.md` | `template/.harness/` | `locales/en/.harness/` |
| `SESSION_END.md` | `template/.harness/` | `locales/en/.harness/` |
| `HARNESS_SETUP.md` | `template/` | `locales/en/` |
| `AGENTS.md` | `template/` | `locales/en/` |
| `hooks/session-start.sh` | `template/.harness/hooks/` | `locales/en/.harness/hooks/` |
| `hooks/session-end.sh` | `template/.harness/hooks/` | `locales/en/.harness/hooks/` |
| `hooks/guard-dangerous.sh` | `template/.harness/hooks/` | `locales/en/.harness/hooks/` |
| `karpathy-guidelines.mdc` | `template/.cursor/rules/` | `locales/en/.cursor/rules/` |

**不本地化**：hook 逻辑文件（`post-write.sh`、`commit-msg`）、配置 JSON、VERSION。

### upgrade.sh 的处理

`upgrade.sh` 升级协议文件时，需要读取当前项目的语言设置。
方案：在 `.harness/VERSION` 文件旁记录 `.harness/LANG`，内容为 `zh` 或 `en`，
upgrade 时读取后选对应语言包覆盖。

## 实施检查点

实施时按以下顺序进行：

1. **翻译英文语言包**：逐文件翻译，标识符（`:discover`、`feat-xxx`、`passes` 等）保持不变
2. **改造 install.sh**：加 `--lang` 参数解析 + 覆盖逻辑
3. **改造 install.bat**：同步 install.sh 改动
4. **改造 bin/harness-kit.js**：透传 `--lang` 参数给 install 脚本
5. **改造 upgrade.sh**：读取 `.harness/LANG` 选择语言包
6. **更新 CI smoke-test**：补充英文安装的冒烟测试用例
7. **更新 README.md**：说明 `--lang` 用法

## 约束与注意事项

- `zh/` 语言包不需要创建实体文件（默认就是中文），仅 `en/` 需要维护
- 翻译时不得修改任何标识符：`:discover`、`DISCOVER`、`feat-xxx`、`passes`、`_index` 等
- 新增语言包后，`install.sh` 的语言校验列表同步更新
- `locales/en/` 的维护者：每次修改根协议文件后，须同步更新 `locales/en/` 对应文件
