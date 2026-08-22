#!/usr/bin/env bash
# Copyright (C) 2026 OPENOS-dev
# This program is free software: you can redistribute it and/or modify
# it under the terms of the OPENOS-PROJECT-LICENSE (OPL) v1.2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# OPL for more details.
#
# You should have received a copy of the OPL along with this program.
# If not, see <https://github.com/OPENOS-dev/OPL>.
#
# opt — OPENOS 统一包管理前端 (v0.1, DEV2026.1)
#
# 职责:
#   - 首次启动: 检测/安装 apt, 询问是否安装其他后端
#   - 后端源: 从 /etc/opt/backends.sources 的 URL (JSON 索引) 动态获取
#   - 后端安装: 克隆 git 仓库 -> 打补丁 -> 构建 -> 安装 -> 注册
#   - 通过 vmappapi 进入/退出软件隔离视图 (opt 运行时独立 /vmapp/opt 视图)
#
# 用法:
#   opt <后端名> <子命令> [参数]   # 调用已安装后端
#   opt --init                     # 手动触发初始化
#   opt --list-backends            # 列出可用后端
#   opt adapt <源码路径>           # (实验性) AI 生成适配补丁
#   opt --force                    # 跳过依赖检查重试

set -uo pipefail

# ---------- 配置 ----------
OPT_CONF_DIR="${OPT_CONF_DIR:-/etc/opt}"
OPT_SOURCES="$OPT_CONF_DIR/backends.sources"
OPT_BACKENDS_DIR="${OPT_BACKENDS_DIR:-/var/lib/opt/backends}"
OPT_LOG="/var/log/opt-init.log"
OPT_BIN_DIR="/usr/local/bin"
OPT_PATHS="/opt/bin:/usr/local/bin:/usr/bin:/bin"

# ---------- 工具 ----------
log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$OPT_LOG"; }
err() { printf '[ERROR] %s\n' "$*" >&2 | tee -a "$OPT_LOG" >/dev/null; }
have() { command -v "$1" >/dev/null 2>&1; }

# JSON 解析 (需 jq; 无 jq 用 python3)
jget() { # jget <json> <key>  输出 key 的值
	local json="$1" key="$2"
	if have jq; then echo "$json" | jq -r "$key";
	elif have python3; then python3 -c "import json,sys;print(json.loads('''$json''')$key)";
	else return 1; fi
}

# ---------- 内置 apt 后端 (本地源码构建, 不下载) ----------
OPT_APT_SRC="${OPT_APT_SRC:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../apt" && pwd)}"

install_builtin_apt() {
	if have apt && have apt-get; then
		log "apt 已就绪, 跳过内置安装"
		return 0
	fi
	log "从本地源码构建并安装 apt (内置后端, 不下载): $OPT_APT_SRC"
	if [ ! -d "$OPT_APT_SRC" ]; then
		err "缺少内置 apt 源码: $OPT_APT_SRC"
		return 1
	fi
	local work="/tmp/opt-apt-build"
	rm -rf "$work"; mkdir -p "$work"; cd "$work"
	cmake "$OPT_APT_SRC" -DCMAKE_INSTALL_PREFIX=/usr \
	      -DWITH_DOC=OFF -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1 || {
		err "apt cmake 配置失败 (需 cmake + 依赖: zlib lz4 zstd libcurl libdb bz2 libgcrypt gettext)"
		return 1
	}
	make -j"${JOBS:-$(nproc)}" >/dev/null 2>&1 || { err "apt 编译失败"; return 1; }
	sudo make install >/dev/null 2>&1 || { err "apt 安装失败 (需 root)"; return 1; }
	# OPENOS 发行版标识
	echo "OPENOS" | sudo tee /etc/openos_version >/dev/null 2>&1 || true
	log "apt 内置安装完成 ($(apt --version 2>/dev/null | head -n1))"
	return 0
}

# ---------- 首次初始化 ----------
opt_init() {
	log "OPENOS opt 首次启动初始化..."
	# 内置 apt (本地源码构建, 不下载)
	install_builtin_apt

	# 从后端源加载列表
	log "正在从后端源加载可用后端列表..."
	local backends=()
	load_backends backends || err "加载后端源失败"

	if [ ${#backends[@]} -eq 0 ]; then
		log "暂无可选后端 (当前仅内置 apt)。"
		return 0
	fi

	echo ""
	echo "发现以下可选后端:"
	local i=0
	for b in "${backends[@]}"; do
		i=$((i+1))
		echo "  $i. $(echo "$b" | cut -d'|' -f2)"
	done
	echo ""
	printf '是否要安装其他包管理器? [y/N] '
	read -r ans
	[ "$ans" = "y" ] || [ "$ans" = "Y" ] || { log "跳过可选后端。"; return 0; }

	printf '输入要安装的编号 (多选用空格, all=全部): '
	read -r sel
	local idx
	for idx in $sel; do
		if [ "$idx" = "all" ]; then
			for b in "${backends[@]}"; do install_backend "$b" || true; done
			break
		fi
		if [ "$idx" -ge 1 ] && [ "$idx" -le "${#backends[@]}" ]; then
			install_backend "${backends[$((idx-1))]}" || true
		fi
	done

	local installed
	installed=$(ls "$OPT_BACKENDS_DIR" 2>/dev/null | tr '\n' ', ')
	log "初始化完成。已安装的后端: ${installed:-none}"
	echo "现在您可以使用: opt <子命令> 管理软件包"
}

# ---------- 后端源加载 ----------
load_backends() {
	local -n _out="$1"
	local src url json
	[ -f "$OPT_SOURCES" ] || { err "缺少 $OPT_SOURCES"; return 1; }
	while IFS= read -r url; do
		[ -n "$url" ] || continue
		# 支持本地目录
		if [ -d "$url" ]; then
			json="$(cat "$url/index.json" 2>/dev/null)"
		else
			json="$(curl -fsSL "$url" 2>/dev/null)" || continue
		fi
		local n
		n="$(jget "$json" '.backends | length' 2>/dev/null || echo 0)"
		local i=0
		while [ "$i" -lt "${n:-0}" ]; do
			local id name repo build patch deps
			id="$(jget "$json" ".backends[$i].id")"
			name="$(jget "$json" ".backends[$i].name")"
			repo="$(jget "$json" ".backends[$i].repo")"
			build="$(jget "$json" ".backends[$i].build_script")"
			patch="$(jget "$json" ".backends[$i].patch")"
			deps="$(jget "$json" ".backends[$i].dependencies | join(\",\")" 2>/dev/null || echo "")"
			[ -n "$id" ] && [ -n "$repo" ] && _out+=("$id|$name|$repo|$build|$patch|$deps")
			i=$((i+1))
		done
	done < <(grep -v '^#' "$OPT_SOURCES")
}

# ---------- 后端安装 ----------
install_backend() {
	local entry="$1"
	local id name repo build patch deps
	id="$(echo "$entry" | cut -d'|' -f1)"
	name="$(echo "$entry" | cut -d'|' -f2)"
	repo="$(echo "$entry" | cut -d'|' -f3)"
	build="$(echo "$entry" | cut -d'|' -f4)"
	patch="$(echo "$entry" | cut -d'|' -f5)"
	deps="$(echo "$entry" | cut -d'|' -f6)"

	log "安装后端: $name ($id)"
	# 依赖检查
	if [ -n "$deps" ] && [ "${FORCE:-0}" != "1" ]; then
		log "检查依赖: $deps"
		if have pacman; then pacman -S --noconfirm --needed $deps 2>/dev/null || true; fi
	fi

	# 克隆
	local work="$OPT_BACKENDS_DIR/$id"
	mkdir -p "$work"
	if [ ! -d "$work/.git" ]; then
		log "克隆 $repo"
		git clone "$repo" "$work" 2>&1 | tee -a "$OPT_LOG" || {
			err "克隆失败, 跳过 $id"; return 1; }
	fi

	# 打补丁
	if [ -n "$patch" ] && [ -f "$work/$patch" ]; then
		log "应用适配补丁 $patch"
		( cd "$work" && patch -p1 < "$patch" 2>&1 | tee -a "$OPT_LOG" )
	fi

	# 构建
	local bs="${build:-build.sh}"
	if [ -x "$work/$bs" ]; then
		log "执行构建脚本 $bs"
		( cd "$work" && ./"$bs" 2>&1 | tee -a "$OPT_LOG" )
	elif [ -f "$work/$bs" ]; then
		log "执行 $bs"
		( cd "$work" && bash "$bs" 2>&1 | tee -a "$OPT_LOG" )
	else
		log "无构建脚本, 尝试 autotools"
		( cd "$work" && ./configure --prefix=/usr/local 2>&1 | tee -a "$OPT_LOG" &&
		  make 2>&1 | tee -a "$OPT_LOG" &&
		  sudo make install 2>&1 | tee -a "$OPT_LOG" )
	fi

	# 注册
	echo "$entry" > "$work/.opt-registered"
	log "后端 $id 已注册。可用: opt $id <子命令>"
}

# ---------- 调用后端 ----------
opt_call() {
	local backend="$1"; shift
	local bin="$OPT_BIN_DIR/$backend"
	if [ ! -x "$bin" ]; then
		# 在已安装后端目录找
		if [ -x "$OPT_BACKENDS_DIR/$backend/$backend" ]; then
			bin="$OPT_BACKENDS_DIR/$backend/$backend"
		else
			err "后端 $backend 未安装。运行 opt --init 安装。"
			return 127
		fi
	fi
	vmapp_enter
	exec "$bin" "$@"
}

# ---------- 实验性: adapt ----------
opt_adapt() {
	local src="$1"
	err "adapt 为实验性功能: 需 AI 服务。当前占位。"
	return 1
}

# ---------- 主入口 ----------
main() {
	# 首次初始化标记
	local init_flag="$OPT_CONF_DIR/.initialized"
	if [ ! -f "$init_flag" ] || [ "${1:-}" = "--init" ]; then
		if [ "${1:-}" = "--init" ]; then shift; fi
		opt_init && touch "$init_flag"
	fi

	case "${1:-}" in
		--list-backends)
			local -a bs; load_backends bs
			for b in "${bs[@]}"; do echo "$b" | cut -d'|' -f1,2; done ;;
		adapt) opt_adapt "${2:-}" ;;
		--force) FORCE=1; shift; opt_call "$@" ;;
		"") err "用法: opt <后端> <子命令>"; exit 1 ;;
		*) opt_call "$@" ;;
	esac
}

mkdir -p "$OPT_BACKENDS_DIR"
main "$@"
