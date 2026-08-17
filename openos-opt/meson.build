# openos-opt — 独立 App (自包含, 可单独构建)
project('openos-opt', 'cpp',
  version: 'DEV2026.1',
  default_options: ['cpp_std=c++17'])
qt6 = import('qt6')
qt6_dep = dependency('qt6', modules: ['Core', 'Gui', 'Qml', 'Quick'])
qt6_res = qt6.preprocess(qresources: 'qml.qrc')
executable('openos-opt',
  sources: ['main.cpp', qt6_res],
  dependencies: [qt6_dep],
  install: true)
