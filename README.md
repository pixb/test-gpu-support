# GPU 视频转码测试工具

用于测试 Linux 系统 GPU 硬件加速视频转码支持的脚本集合。

## 脚本说明

| 脚本 | 功能 |
|------|------|
| `hardware_info.sh` | 检测并打印硬件信息（CPU、内存、GPU、PCI设备、FFmpeg编码器） |
| `gpu_transcode_test.sh` | 对 test.mp4 进行转码测试，自动检测并测试可用的硬件编码器 |
| `update_vaapi.sh` | 更新 Intel VAAPI 驱动 |
| `update_libva.sh` | 更新 libva 库（解决驱动兼容性问题） |
| `backup_apt.sh` | 备份 APT 源到 /etc/apt/ |
| `restore_apt.sh` | 恢复 APT 源 |
| `restore_libva.sh` | 还原 libva 到原始版本 |
| `install_env.sh` | 安装必要的依赖工具 |

## 支持的硬件加速

- **NVIDIA**: h264_nvenc, hevc_nvenc, av1_nvenc
- **AMD**: h264_amf, hevc_amf (ROCm)
- **Intel Quick Sync (QSV)**: h264_qsv, hevc_qsv
- **Intel VAAPI**: h264_vaapi, hevc_vaapi
- **Apple VideoToolbox**: h264_videotoolbox, hevc_videotoolbox (macOS)

## 使用方法

```bash
# 1. 安装依赖（首次使用）
./install_env.sh

# 2. 查看硬件信息
bash hardware_info.sh

# 3. 运行转码测试
bash gpu_transcode_test.sh

# 4. 如需更新驱动（仅 Intel GPU 失败时）
./update_vaapi.sh
# 或
./update_libva.sh
```

**注意**: 脚本使用 `bash` 运行（非 zsh）。

## 硬件信息输出说明

`hardware_info.sh` 会输出以下信息：

1. **CPU 信息** - 型号、核心数、线程数
2. **内存信息** - 总量、使用情况
3. **PCI VGA/Display 设备** - 所有显卡设备列表
4. **Intel GPU 代数** - 支持的 Intel 核显 PCI ID 对照表
5. **DRI 设备映射** - /dev/dri/cardX 对应的 PCI 设备
6. **FFmpeg 硬件编码器** - 支持的编码器列表
7. **VAAPI 测试** - 测试各 DRI 设备是否可用

### Intel GPU PCI ID 对照表

| 代数 | 代号 | PCI Device ID |
|------|------|---------------|
| Skylake (6th) | SKL | 1912, 191a, 191b, 191d, 191e |
| Kaby Lake (7th) | KBL | 5912, 5916, 5917, 591a, 591b |
| Coffee Lake (8th) | CFL | 3e71, 3e91, 3e92, 3e99, 3e9b |
| Comet Lake (10th) | CML | 9b41, 9b42, 9b21, 9b61 |
| Ice Lake (10th) | ICL | 8a51, 8a70, 8a71 |
| Tiger Lake (11th) | TGL | 9a49, 9a60, 9a61 |
| Rocket Lake (11th) | RKL | 4c8a, 4c8b, 4c8c |
| Alder Lake (12th) | ADL | 4680, 4682, 4690, 4692, 4693 |
| Meteor Lake (14th) | MTL | 7d55, 7d67, 7d75 |
| Lunar Lake (18th) | LNL | 7d14, 7d72 |

## 依赖

- ffmpeg
- ffprobe
- lspci (pciutils)
- coreutils (basename, cut, ls)
- findutils
- grep

推荐使用 `install_env.sh` 自动安装。

## 输出

- 转码测试结果保存在 `output/` 目录
- 备份文件保存在 `/etc/apt/sources.list.backup_YYYYMMDD_HHMMSS`

## 驱动更新说明（Intel GPU）

当 VAAPI 转码失败时，可能需要更新 libva 库。

### 升级步骤

```bash
# 1. 备份当前 APT 源（可选）
./backup_apt.sh

# 2. 更新 libva 库
./update_libva.sh

# 3. 验证
bash gpu_transcode_test.sh
```

### 还原步骤

如果更新失败，执行以下命令还原：

```bash
# 还原 libva 到原始版本
./restore_libva.sh

# 或恢复 APT 源
./restore_apt.sh
```

## 常见问题

### Q: 虚拟机中 Intel GPU 已直通但无法使用 VAAPI

A: 检查以下内容：
1. 确认 PCI 设备已直通（lspci 应显示 Intel GPU）
2. 确认 /dev/dri/ 目录下有对应设备
3. 检查是否为正确的 DRI 设备（card0 可能是虚拟显卡，card1 是 Intel 核显）
4. 更新 intel-media-va-driver 和 libva

### Q: 如何判断哪个 DRI 设备是 Intel 核显

A: 运行 `bash hardware_info.sh`，查看 "DRI by-path mapping" 部分：
```
/dev/dri/card0 -> QXL 虚拟显卡 (1b36:0100)
/dev/dri/card1 -> Intel HD Graphics P530 (8086:191d)
```
带 vendor ID `8086` 的是 Intel 核显。

### Q: 脚本在 zsh 下运行出错

A: 使用 `bash` 运行脚本：
```bash
bash hardware_info.sh
bash gpu_transcode_test.sh
```
