# MineSpace Unofficial

Minecraft **1.12.2** / Forge **14.23.5.2859** 的 GregTech CE: TJ Edition +
Galacticraft 整合与附属模组，版本 **0.2.0**。

一个 jar 内含四个 Forge 模组：

- `minespace_core`：GT 材料、机器、跨模组统一与兼容层
- `minespace_planets`：天体、行星岩石/石种、矿脉与地形
- `minespace_navigation`：星图、目标选择、火箭飞行与降落
- `minespace_cosmic`：研究链、观测设备、戴森球与超光速内容

当前内容包含 GT 行星矿脉、EU↔gJ 能量桥、NuclearCraft/QMD 材料与配方统一、
BYG 群系/矿物/林业兼容、星图与火箭降落流程、敌对生物默认不主动攻击（受击后反击，Boss 正常），
以及一批运行时性能优化。已加入 RTG，新建世界时可选择真实地形世界类型。

完整说明、安装步骤、操作方式、已知事项和构建命令见
[readme.txt](readme.txt)。

快速启动：

```text
Minespace-unofficial-dev\Play-Minespace.bat
```

构建：

```powershell
cd Minespace-unofficial
.\tools\gradle.ps1 build
.\tools\gradle.ps1 deployToInstance
.\tools\verify-pack.ps1
```

详细开发记录见 [PROGRESS.md](PROGRESS.md) 和
[DEV-NOTES.md](Minespace-unofficial/DEV-NOTES.md)。
