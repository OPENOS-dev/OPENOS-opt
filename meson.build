# opt — OPENOS 统一包管理前端 (CLI)
project('opt')

install_data('opt.sh',
  install_dir: get_option('bindir'),
  rename: 'opt')

# 后端源配置与模板
install_subdir('opt',
  install_dir: get_option('sysconfdir') / 'opt',
  strip_directory: true)

# 内置 apt 源码 (src/apt) 由 opt 首次运行时本地构建
