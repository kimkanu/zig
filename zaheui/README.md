# Zaheui

Zig으로 만들어진 아희 구현체

```sh
# build
zig build -Drelease-fast=true

# run
./zig-out/bin/zaheui {aheui_file} < {in_file} > {out_file}

# test
pushd snippets && AHEUI="../zig-out/bin/zaheui" bash test.sh && popd
```
