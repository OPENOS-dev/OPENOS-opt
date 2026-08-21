# openos-opt — Pacman GUI 前端 (独立 App, 可单独构建)
project('openos-opt', 'cpp',
  version: 'DEV2026.1',
  default_options: ['cpp_std=c++17'])

qt6 = import('qt6')
qt6_dep = dependency('qt6', modules: ['Core', 'Gui', 'Qml', 'Quick', 'WaylandClient'])
qt6svg_dep = dependency('Qt6Svg', required: true)
qt6_res = qt6.preprocess(qresources: 'qml.qrc')

executable('openos-opt',
  sources: [
    'main.cpp',
    'pacmanbridge.cpp', 'pacmanbridge.h',
    'iconloader.cpp', 'iconloader.h',
    'iconprovider.cpp', 'iconprovider.h',
    qt6_res,
  ],
  dependencies: [qt6_dep, qt6svg_dep],
  install: true,
)