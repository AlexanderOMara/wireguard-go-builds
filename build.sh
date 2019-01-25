#!/usr/bin/env bash
set -e
set -u

version='0.0.20181222'
src_file_sha256="53dc611524c40cddd242c972a9559f9793e128a0ce772483f12a2704c9f48c54"

src_file="wireguard-go-${version}.tar.xz"
src_url="https://git.zx2c4.com/wireguard-go/snapshot/${src_file}"

base_dir="$PWD"
vendor_dir="$base_dir/vendor"
src_dir="$base_dir/src"
build_dir="$base_dir/build"
src_file_path="$vendor_dir/$src_file"

# Remove existing build directories (add write access to src directories to avoid permission issues).
chmod -R u+w "$src_dir"
rm -rf "$vendor_dir" "$src_dir" "$build_dir" "$src_file"
mkdir "$vendor_dir" "$src_dir" "$build_dir"

# Get and verify extract source file.
wget -O "$src_file_path" "$src_url"
echo "$src_file_sha256  $src_file_path" | shasum -c
tar --strip-components=1 -C "$src_dir" -xJf "$src_file_path"

# Patch Makefile to remove building on Linux check.
sed -i.bak 's/$(wildcard .git),linux/$(wildcard .git),linux_check_disabled/g' "$src_dir/Makefile"

# Build all the targets.
targets=(
	'darwin 386'
	'darwin amd64'

	'linux 386'
	'linux amd64'
	'linux arm'
	'linux arm64'
	'linux ppc64'
	'linux ppc64le'
	'linux mips'
	'linux mipsle'

	'freebsd 386'
	'freebsd amd64'
	'freebsd arm'

	'openbsd amd64'
)
for target in "${targets[@]}"; do
	target_=($target)
	target_os="${target_[0]}"
	target_arch="${target_[1]}"
	build_archive_file="wireguard-go-$target_os-$target_arch.tar.xz"
	build_archive_path="$build_dir/$build_archive_file"
	build_archive_file_sha256="$build_archive_file.sha256"

	echo '------------------------------------------------------------'
	echo "Building: $target_os $target_arch"
	echo '------------------------------------------------------------'

	export GOOS="$target_os"
	export GOARCH="$target_arch"

	pushd "$src_dir" > /dev/null
	make
	tar cfJ "$build_archive_path" wireguard-go*

	pushd "$build_dir" > /dev/null
	shasum -a 256 "$build_archive_file" > "$build_archive_file_sha256"
	cat "$build_archive_file_sha256"
	popd > /dev/null

	make clean

	popd > /dev/null
done
