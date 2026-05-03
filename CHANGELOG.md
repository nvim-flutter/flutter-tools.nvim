# Changelog

## [4.0.0](https://github.com/nvim-flutter/flutter-tools.nvim/compare/v3.0.0...v4.0.0) (2026-05-03)


### ⚠ BREAKING CHANGES

* remove support to older than 0.11 nvim versions ([#525](https://github.com/nvim-flutter/flutter-tools.nvim/issues/525))
* **config:** allow to pass additional arguments to flutter run command ([#407](https://github.com/nvim-flutter/flutter-tools.nvim/issues/407))
* **outline:** remove code actions from outline ([#387](https://github.com/nvim-flutter/flutter-tools.nvim/issues/387))
* **lsp:** remove deprecated lsp start method
* rename setup file to minimal_init.lua
* **ui:** replace (some) custom ui with `vim.ui.*` ([#221](https://github.com/nvim-flutter/flutter-tools.nvim/issues/221))
* **ui:** change vim.notify function signature ([#210](https://github.com/nvim-flutter/flutter-tools.nvim/issues/210))
* **setup:** refactor autocommands
* **setup:** convert commands to use 0.7 apis

### Features

* add (statusline) decorations ([#76](https://github.com/nvim-flutter/flutter-tools.nvim/issues/76)) ([692846c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/692846c228347dd7c5cab20941bcc6510ac13db5))
* add ability to filter flutter output in dev log ([#371](https://github.com/nvim-flutter/flutter-tools.nvim/issues/371)) ([654c477](https://github.com/nvim-flutter/flutter-tools.nvim/commit/654c4779a42575d12edd8177e70263d63ae39833))
* add command to clear dev log ([ba13479](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ba134799e7d43360598dff8b830a77429f6a7503))
* add commandline args for run command ([#71](https://github.com/nvim-flutter/flutter-tools.nvim/issues/71)) ([214016b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/214016bdfc0d97ed6f9ab443746af1ee9c08a853))
* add dart icon to notifications ([79caafb](https://github.com/nvim-flutter/flutter-tools.nvim/commit/79caafbefab82fc139f9ac9d2983efb3fd04c066))
* add flutter dependency detection ([#326](https://github.com/nvim-flutter/flutter-tools.nvim/issues/326)) ([7f93847](https://github.com/nvim-flutter/flutter-tools.nvim/commit/7f93847e32bb00bedeb2648219584c606a860d99))
* add flutter detach command ([#113](https://github.com/nvim-flutter/flutter-tools.nvim/issues/113)) ([20518be](https://github.com/nvim-flutter/flutter-tools.nvim/commit/20518beb244c59214b58cfde3358d0124f554671))
* add flutter pub get command ([9ecdc96](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9ecdc965b24d6d9e3e22f0f899362ef5cf9d5c53))
* add FlutterAttach command ([#425](https://github.com/nvim-flutter/flutter-tools.nvim/issues/425)) ([cf92ff1](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cf92ff1f0c3d18c1599d3af684b9a08c825c58c8))
* add FlutterDebug command ([#420](https://github.com/nvim-flutter/flutter-tools.nvim/issues/420)) ([da3682a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/da3682a3bdd3e19ed42194381a53e7bbace7682a))
* add FlutterRename command ([#234](https://github.com/nvim-flutter/flutter-tools.nvim/issues/234)) ([4d9391b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4d9391b5c217003666d4ffb4db665ad30362a959))
* add handler for textDocument/documentColor ([#125](https://github.com/nvim-flutter/flutter-tools.nvim/issues/125)) ([3283a31](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3283a31c004a27f2290f95a85555e168141eada7))
* add highlight groups for popup windows ([6a599fa](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6a599fa4308d252be97a542f510f7e7f5e966682)), closes [#66](https://github.com/nvim-flutter/flutter-tools.nvim/issues/66)
* Add Inspect Widget command ([#509](https://github.com/nvim-flutter/flutter-tools.nvim/issues/509)) ([5e863a2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5e863a2325ad216c36e88e860eedbb9e23ad4aa6))
* add option to configure flutter mode via config ([#314](https://github.com/nvim-flutter/flutter-tools.nvim/issues/314)) ([69466cc](https://github.com/nvim-flutter/flutter-tools.nvim/commit/69466cc5ce3743bfb08ae07b0c415d7e549437d4))
* add option to disable ftplugin ([#417](https://github.com/nvim-flutter/flutter-tools.nvim/issues/417)) ([85492be](https://github.com/nvim-flutter/flutter-tools.nvim/commit/85492bee069af1155bb10bfbee90ac7d4168eced))
* Add outline CodeActions support ([#31](https://github.com/nvim-flutter/flutter-tools.nvim/issues/31)) ([415604b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/415604bd9aba1bb149cedc9a6831ff9af2019383))
* add performance_overlay, repaint_rainbow and slow_animations commands ([deb4fa8](https://github.com/nvim-flutter/flutter-tools.nvim/commit/deb4fa80812157e6c6dadaa25dfe0cfa42950e5c))
* add possibility to set default run args ([#471](https://github.com/nvim-flutter/flutter-tools.nvim/issues/471)) ([d1022db](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d1022db80dab2a565563993843e8c60b20a3df39))
* add pub workspace support for LSP root detection ([#505](https://github.com/nvim-flutter/flutter-tools.nvim/issues/505)) ([2f26317](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2f26317d001e715065889b15ab922b5ae16c9397))
* add root_patterns to config ([#287](https://github.com/nvim-flutter/flutter-tools.nvim/issues/287)) ([0ba9698](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0ba969873f1fb345efef4baa053c8c43c443ab84))
* add telescope picker for commands ([95318db](https://github.com/nvim-flutter/flutter-tools.nvim/commit/95318db56418c728a7930d49f6ea5b124585d142))
* add Toggle Dev Log in telescope menu ([#511](https://github.com/nvim-flutter/flutter-tools.nvim/issues/511)) ([ad5fd81](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ad5fd8149e5a376c80afb17805bdaee6f6742ac8))
* add web port param to config ([#320](https://github.com/nvim-flutter/flutter-tools.nvim/issues/320)) ([b13d46b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b13d46b3a06a9e2c414d0020c0cb7cf0dd51d426))
* adds analyzer_web_port config which starts the LSP analysis server with the given port ([#479](https://github.com/nvim-flutter/flutter-tools.nvim/issues/479)) ([ed9f78b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ed9f78bfd649c3d87238a20ebe08f72e46a3380a))
* allow completely custom lsp command ([791b57e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/791b57ee7e1b881d2d58e966b1250de5c601978a))
* allow specifying border styles ([6d5a770](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6d5a770a5f08ebf243494bfb03b0bb8c176228ba))
* allow specifying lsp setting as a function ([b374c70](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b374c707f1c3143099e6ef3c751885bf5bbba9e1))
* **CI:** add ability to trigger CI workflow manually ([b6b62ba](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b6b62baa0ade0b78c44a452244aadbc4f74082e6))
* **closing tags:** add option to disable ([058443d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/058443dd21e92e73c9244cee408b708274ae17eb)), closes [#36](https://github.com/nvim-flutter/flutter-tools.nvim/issues/36)
* **code_actions:** fix telescope picker ([beb3f20](https://github.com/nvim-flutter/flutter-tools.nvim/commit/beb3f2094a3b9ac5db8c58298ec3eead17bdbafe)), closes [#225](https://github.com/nvim-flutter/flutter-tools.nvim/issues/225)
* **commands:** add FlutterSuper and FlutterReanalyze ([#170](https://github.com/nvim-flutter/flutter-tools.nvim/issues/170)) ([15d78dc](https://github.com/nvim-flutter/flutter-tools.nvim/commit/15d78dc088802d83e216da828d05c74af75f6aea))
* **commands:** add install/uninstall commands to menu ([#315](https://github.com/nvim-flutter/flutter-tools.nvim/issues/315)) ([cd73844](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cd738444c27d3a34f03b6d43df08c814e8232fb7))
* **commands:** add option to silence flutter errors ([#246](https://github.com/nvim-flutter/flutter-tools.nvim/issues/246)) ([bafdc2c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bafdc2c931bad4495835f51b819df842c615ae52))
* **commands:** add widget inspector and construction lines ([#136](https://github.com/nvim-flutter/flutter-tools.nvim/issues/136)) ([ffe36b4](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ffe36b437e7a47352ecf8301a2f2ba6dee2094e7))
* **commands:** open dev tools ([#156](https://github.com/nvim-flutter/flutter-tools.nvim/issues/156)) ([89854b9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/89854b9b29a35589ee40d61fef1e6f2dd6b2cea2))
* **config:** add ability to set web-browser-flag ([#406](https://github.com/nvim-flutter/flutter-tools.nvim/issues/406)) ([80770c6](https://github.com/nvim-flutter/flutter-tools.nvim/commit/80770c67aa2d9e1eccf6bb52fac78115831acd04))
* **config:** add an optional pre_run_callback attribute to `setup_project` ([f898850](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f8988508798ebc4af2c43405d2c35432a50efd9f))
* **config:** add possibility to provide cwd via project configuration ([#383](https://github.com/nvim-flutter/flutter-tools.nvim/issues/383)) ([7efc0d8](https://github.com/nvim-flutter/flutter-tools.nvim/commit/7efc0d86094ecd80fb50e19935596acd7956255c)), closes [#329](https://github.com/nvim-flutter/flutter-tools.nvim/issues/329)
* **config:** add project configuration ([#232](https://github.com/nvim-flutter/flutter-tools.nvim/issues/232)) ([f898ac2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f898ac2340b4ff1950e82f7181a92d0b9134e78b))
* **config:** allow to pass additional arguments to flutter run command ([#407](https://github.com/nvim-flutter/flutter-tools.nvim/issues/407)) ([4f48d8b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4f48d8b84bb09cfe66e13884f5fb1847b18d403f))
* create overridable notification highlights ([#64](https://github.com/nvim-flutter/flutter-tools.nvim/issues/64)) ([95e5f29](https://github.com/nvim-flutter/flutter-tools.nvim/commit/95e5f2993252dc6ef541db169d1a41bcaec74f08))
* **dap:** add custom commands to dap ([af591f5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/af591f5504250ba285a564aa75895e1e5fb166d6))
* **dap:** add option `evaluate_to_string_in_debug_views` ([#377](https://github.com/nvim-flutter/flutter-tools.nvim/issues/377)) ([0842bbe](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0842bbedf43bb3643b3b8402160687b5bb90054b))
* **debugger:** add ability to attach to app ([1903539](https://github.com/nvim-flutter/flutter-tools.nvim/commit/19035394b471d9a5f4da3fcf7a6e3dad1e027827))
* **debugger:** add options to specify exception breakpoints ([0eab3b1](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0eab3b11a740c2674f4bc8e4e5ca1d17d07a4ab0))
* **debugger:** fix file URI handling for Windows in inspect event ([#514](https://github.com/nvim-flutter/flutter-tools.nvim/issues/514)) ([3b2f652](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3b2f652e4f15c859d421f7520e15c74b9abde836))
* **decorations:** view selected project config in statusline ([#241](https://github.com/nvim-flutter/flutter-tools.nvim/issues/241)) ([5967d65](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5967d65f993427f7fd33bd4d7d9ca85a384db9f4))
* derive executable path async ([b9e707a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b9e707afa1d1ab1d035affb847c7efb3b13bc946))
* **devices:** add cold boot option for android emulators ([#412](https://github.com/nvim-flutter/flutter-tools.nvim/issues/412)) ([40f974b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/40f974b15f82f9af498adda8d93aabd637f3ab58))
* Execute flutter commands in lsp project root ([#95](https://github.com/nvim-flutter/flutter-tools.nvim/issues/95)) ([4c084b1](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4c084b1afb8a7755a4f80eea31d0813b2e0dc3f8))
* **fvm:** support FVM in monorepo setup ([21c4496](https://github.com/nvim-flutter/flutter-tools.nvim/commit/21c4496ad8e0aaca10a5abed5acef3b831b8b460))
* implement automatic widget inspector navigation ([#507](https://github.com/nvim-flutter/flutter-tools.nvim/issues/507)) ([685321f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/685321f6de92a57d2c38be96dcc885237b40bd04)), closes [#503](https://github.com/nvim-flutter/flutter-tools.nvim/issues/503)
* improve dev tools setup ([#204](https://github.com/nvim-flutter/flutter-tools.nvim/issues/204)) ([d67caa7](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d67caa7dd17eccb89bfda1c0657d0723e339ef60))
* improves project root detection by always going up the directory tree until we find a project root marker ([#482](https://github.com/nvim-flutter/flutter-tools.nvim/issues/482)) ([3a3f6f5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3a3f6f5fadf7e1b976ba5f35df0219d1d4762a38))
* Introduce dap-based runner ([#108](https://github.com/nvim-flutter/flutter-tools.nvim/issues/108)) ([6acf7d2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6acf7d2ed2aeebf932808e99e64a4f71fe508606))
* **labels:** add option to set closing tag virtual text priority ([#373](https://github.com/nvim-flutter/flutter-tools.nvim/issues/373)) ([18a28d6](https://github.com/nvim-flutter/flutter-tools.nvim/commit/18a28d6e4c71bb85a1cd5ce0ce42a63dfcdfa4c6))
* **labels:** Update to use extmarks ([#96](https://github.com/nvim-flutter/flutter-tools.nvim/issues/96)) ([85fbff6](https://github.com/nvim-flutter/flutter-tools.nvim/commit/85fbff673687f38d5763c3e4b76883294e14cfd8))
* **log:** add focus option for log window ([9ad676c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9ad676c61dfc590f3852955ed2030abacc54b0e1))
* **log:** add toggle command for log buffer ([#411](https://github.com/nvim-flutter/flutter-tools.nvim/issues/411)) ([bc36e2e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bc36e2eb3f2d8be939aa5667615cc3aceebb5874))
* **lsp:** add restart command ([bf1611f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bf1611fd7063d0a5aead960d968a8d57706c1c84))
* **notify:** key notification by source ([20f90d2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/20f90d2e25f4492db153074389f0cf622be71c2b))
* only print guides error if debug is true ([7679f10](https://github.com/nvim-flutter/flutter-tools.nvim/commit/7679f100b35e493cbb57cb2ce060e981a2439990))
* open dev tools when running in debug mode ([#419](https://github.com/nvim-flutter/flutter-tools.nvim/issues/419)) ([2f9db8b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2f9db8b15133ab789cd1be913e2d081e19b1f88d))
* **outline:** add auto-open and toggle ([af637b9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/af637b9b726ea33fb441465131ae8c8a9b5e25be))
* **outline:** match and highlight strings ([3e87282](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3e87282bf57ed5106b654e59d584b2b026867bd9))
* **outline:** remove code actions from outline ([#387](https://github.com/nvim-flutter/flutter-tools.nvim/issues/387)) ([6610090](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6610090a4e68d10fd73b68450004dafd26e7cc34))
* **popup:** add "q" mapping to close window ([16646d8](https://github.com/nvim-flutter/flutter-tools.nvim/commit/16646d8753beba406fb93fe7d226d3b3450c8773))
* prevent writes to files in pub cache and FVM folder ([#173](https://github.com/nvim-flutter/flutter-tools.nvim/issues/173)) ([3dfe94c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3dfe94cec788e274178bbd0e872d2ab660bf9e59))
* **project_config:** add extra arguments ([#258](https://github.com/nvim-flutter/flutter-tools.nvim/issues/258)) ([5fbd2a1](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5fbd2a146bfebcbcff1aec832f7e9d1263737db2))
* prompt for name before performing refactors ([#104](https://github.com/nvim-flutter/flutter-tools.nvim/issues/104)) ([8c7af76](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8c7af76c4f4422a079e43718c1ac1160c5a00df2))
* **pub get:** increase error notification timeout ([6e92ced](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6e92ced927a1d56030110d6e864c71486f3d9e24))
* remove support to older than 0.11 nvim versions ([#525](https://github.com/nvim-flutter/flutter-tools.nvim/issues/525)) ([417304b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/417304b5c83633a60c353f64ad6ba090fda6eab0))
* resolve package urls when using `gf` or `gF` ([#392](https://github.com/nvim-flutter/flutter-tools.nvim/issues/392)) ([6bf887b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6bf887bb9442b80a67f36e7465a66de4202d8a3f))
* respect cwd when detecting is it flutter project, handle running dart-only projects ([#384](https://github.com/nvim-flutter/flutter-tools.nvim/issues/384)) ([cde6625](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cde66252ae44f4cafd130fd2c4e117dcd36b05b5)), closes [#375](https://github.com/nvim-flutter/flutter-tools.nvim/issues/375)
* set dart comments options ([#172](https://github.com/nvim-flutter/flutter-tools.nvim/issues/172)) ([19c16dd](https://github.com/nvim-flutter/flutter-tools.nvim/commit/19c16ddf70dc64b1fe4019fb3562a54d6254b624))
* setup plugin on `require("flutter-tools").setup_project` ([#408](https://github.com/nvim-flutter/flutter-tools.nvim/issues/408)) ([fb976f0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fb976f0e83296d011be95701085ff4711a89de94))
* **setup:** add pubspec.yaml as another start point ([#167](https://github.com/nvim-flutter/flutter-tools.nvim/issues/167)) ([c4a7a53](https://github.com/nvim-flutter/flutter-tools.nvim/commit/c4a7a532bbf865d48b111f42f3b2956d12a65559))
* stack notification windows if multiple open ([bea5f17](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bea5f17d0554ce5a922273ac04012b28c82944a3))
* support for fvm ([#99](https://github.com/nvim-flutter/flutter-tools.nvim/issues/99)) ([10b3bb0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/10b3bb0b674dd4f2cd992a7649430380eb53e397))
* support passing args to FlutterAttach command ([#454](https://github.com/nvim-flutter/flutter-tools.nvim/issues/454)) ([a643f2f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a643f2ff012d5c3ec4322576d48bce1dea244841))
* **syntax:** include improved dart syntax file ([0417d4c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0417d4c45e732b5c96f4a42dbb562e5be0af81c1))
* **ui:** change vim.notify function signature ([#210](https://github.com/nvim-flutter/flutter-tools.nvim/issues/210)) ([c6e68b3](https://github.com/nvim-flutter/flutter-tools.nvim/commit/c6e68b3ea365431f91834bf969691b9f4fa76608))
* **ui:** place cursor on the first actionable line ([8b1b33c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8b1b33cfebb06e4b330db24958f2438fbb3d4e50))
* update lsp completion capabilities ([a9863e1](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a9863e16b1bb8bd37de9460b2190e967dd6d9a50))


### Bug Fixes

* adapt to nvim depractions ([#379](https://github.com/nvim-flutter/flutter-tools.nvim/issues/379)) ([e951b0a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e951b0a1bcc5abe2d801e3a1762b37b0fbbf2acd))
* add conditional use of client.notify because of deprecation ([#481](https://github.com/nvim-flutter/flutter-tools.nvim/issues/481)) ([0fcb08a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0fcb08a4ae46fafff6cfd8f4af0207305e3bcf10))
* add max width to notifications ([464a919](https://github.com/nvim-flutter/flutter-tools.nvim/commit/464a9193d8639fffb2d65b418fb9bc2a314b1a90))
* add offset encoding to outline code action ([8020b6f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8020b6fab44b8421302ec7fb55c5948df16a431d)), closes [#130](https://github.com/nvim-flutter/flutter-tools.nvim/issues/130)
* add write permission to release workflow ([654c013](https://github.com/nvim-flutter/flutter-tools.nvim/commit/654c01335248a21be0b9d145103b3f40115ca63a))
* allow flutter run to take cli arguments ([#119](https://github.com/nvim-flutter/flutter-tools.nvim/issues/119)) ([9458303](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9458303fcaa5cc35e0b1915edb8509886ed986d7))
* attach LSP to buffer only once ([#163](https://github.com/nvim-flutter/flutter-tools.nvim/issues/163)) ([8b0d82f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8b0d82f1aa6d09cad74489d35d9fecfdc7fa45ec))
* Buffer is not 'modifiable' ([#477](https://github.com/nvim-flutter/flutter-tools.nvim/issues/477)) ([d4b0cb9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d4b0cb9cfcda4cb27e6b68bad20cba0be542b55b))
* call notify function from correct place ([#153](https://github.com/nvim-flutter/flutter-tools.nvim/issues/153)) ([63bec8e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/63bec8e4741e5a163108cd397943b16d4cd88e01))
* callback name for plenary job execution ([#114](https://github.com/nvim-flutter/flutter-tools.nvim/issues/114)) ([11513c9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/11513c97ad8736b63b90851f7f9355d387315db1))
* check colorProvider capability before sending a request ([#151](https://github.com/nvim-flutter/flutter-tools.nvim/issues/151)) ([5e88b96](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5e88b963b360c3b6941a19ab5fc82c70c6818a3a))
* check document colour is supported ([a664e92](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a664e929f5c53cda3dabc80b33b2ab201dec3270))
* check for nil value when handle_log is called ([#436](https://github.com/nvim-flutter/flutter-tools.nvim/issues/436)) ([26c511d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/26c511d5009c87c740a544e2c9d4139aff18a692))
* check if highlight exists before executing ([5aa3f6b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5aa3f6b406576e72da6d5eccc1fa86d5f5b01614))
* check if the window is valid before closing ([6655d1a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6655d1a2b739db096d7bc950a41ee1bd5ce8acdb))
* **closing tags:** add space before closing tag ([66fb51f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/66fb51fbdea0a5e57022cf90aba0b97005fb585e))
* **color:** ensure values exist when setting colors ([bdd6365](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bdd6365b92e42ceb6404d493c0f1fef76fa42b90))
* **colors:** check the return value of vim.fn.has ([c0909a0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/c0909a073348db3dbc5bdcbeddd49cc6f04ebeb1)), closes [#135](https://github.com/nvim-flutter/flutter-tools.nvim/issues/135)
* **color:** use correct require path ([f12b1f4](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f12b1f43c8d4617cc6454bfd066e72175c117755))
* **colour:** increase priority of highlights ([055c082](https://github.com/nvim-flutter/flutter-tools.nvim/commit/055c0823d295aa3449d59c85397e35ef2c138bd9)), closes [#129](https://github.com/nvim-flutter/flutter-tools.nvim/issues/129)
* **commands:** force debug with FlutterDebug command ([4a8aad2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4a8aad2839482fbe3bb3f14d8ac574f711fdfd53))
* **commands:** make inspect widget command work in debug runner ([#413](https://github.com/nvim-flutter/flutter-tools.nvim/issues/413)) ([824faf5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/824faf57964c77ae8a80c9e642e5124d0e5c28e9))
* **commands:** set current device while running project ([045fa0f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/045fa0f56234943464a06666183cd1a3089aeca2))
* **commands:** use utils.map for selecting device ([9c3fc97](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9c3fc97ba33717f26fcf328725590720a5f9abca))
* **config:** use correct require path ([7db39ef](https://github.com/nvim-flutter/flutter-tools.nvim/commit/7db39ef83d22656e19bc65dd58234fd33dcc2d1e))
* correct function reference for choosing device ([0666eae](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0666eaea0f65a6590bd64006392d9cc8940cb1db))
* correct vim API reference in color utils ([1d6b57f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1d6b57f8f9622218f775063e9bc465863ea3099e))
* correct vim.fn.has() comparisons to use explicit == 1 ([6faf2c7](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6faf2c70bd56f1fe78620591a2bb73f4dc6f4870))
* **dap:** attach debugger on windows ([#381](https://github.com/nvim-flutter/flutter-tools.nvim/issues/381)) ([d8f2eac](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d8f2eac1734e0e68050bc57600e5f2ba775b1ec4))
* **dap:** define adapter and config when running standalone dart ([#272](https://github.com/nvim-flutter/flutter-tools.nvim/issues/272)) ([356f643](https://github.com/nvim-flutter/flutter-tools.nvim/commit/356f64339ff44ae1e615b90bb0739892acf2c522))
* **dap:** fix cwd not being considered ([0c97d46](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0c97d46afead1885560c5c5c8bbfe0a9f1d13f05))
* **dap:** improve debugger integration with nvim-dap ([#455](https://github.com/nvim-flutter/flutter-tools.nvim/issues/455)) ([8edcdab](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8edcdabfe982c77482ebde2ba3f46f2adc677e64))
* **dap:** pass correct flutter sdk path the dap ([1f165d2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1f165d22927903e9231b49d9a75da5ec4e52a7be))
* **dap:** read vmServiceUri for profiler_url ([#198](https://github.com/nvim-flutter/flutter-tools.nvim/issues/198)) ([ae0be3c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ae0be3cef35c0cb41d6c7f814a19b3402d50fd7a))
* **daprunner:** Check for nil in dap events ([#110](https://github.com/nvim-flutter/flutter-tools.nvim/issues/110)) ([9c76482](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9c7648234e382101e0a9d6b0f031869b52154833))
* **dap:** use full path to flutter executable when running via DAP ([#216](https://github.com/nvim-flutter/flutter-tools.nvim/issues/216)) ([31f75ae](https://github.com/nvim-flutter/flutter-tools.nvim/commit/31f75ae70780cb593bbd3b5179203a9e2b05cefa))
* default closing tags prefix should have space ([5c23e30](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5c23e3049ce8a1861aef4a2e4b38e39002ed3032))
* derive flutter sdk path for normal executables ([4b51ee5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4b51ee5ff55a88db0e059269bfa38c1df7a931af))
* derive flutter sdk path from flutter_path ([#33](https://github.com/nvim-flutter/flutter-tools.nvim/issues/33)) ([8d77d16](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8d77d1693894da78febc078bfd64e73cd5f6d58d))
* **dev_tools:** don't buffer devtools stdout ([0f4294e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0f4294e90c3ecbbd5f259388159308c66a5be3ea))
* **dev_tools:** notify user if data is not valid ([69fe6c8](https://github.com/nvim-flutter/flutter-tools.nvim/commit/69fe6c8d1acbb16b14cbc43f83b214d9e4d06405)), closes [#139](https://github.com/nvim-flutter/flutter-tools.nvim/issues/139)
* **devices:** don't render empty platform strings ([5039d23](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5039d238200db5063652622afa299ff62c07e604))
* **devices:** filter out unwanted device lines ([1787090](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1787090d66482552505a6498e3d2f06fb4290f96))
* **devices:** update mapping to use new helper ([e7c61ce](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e7c61ce1561821319730575104430b269b8d5429))
* **devtools:** stop DevTools server on flutter shutdown ([#521](https://github.com/nvim-flutter/flutter-tools.nvim/issues/521)) ([1f532b5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1f532b515cffd45ea6dc2d9399e06622515f42e7))
* **devtools:** use new dart devtools command ([#214](https://github.com/nvim-flutter/flutter-tools.nvim/issues/214)) ([4c3c440](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4c3c440f1a87aa8db7020d7393ae9924b168953e))
* do not attach LSP to buffer with diffview file URI ([#191](https://github.com/nvim-flutter/flutter-tools.nvim/issues/191)) ([b666a05](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b666a057108c7655882cbc64217222228aad68da))
* do not start new LSP client when navigating to flutter dependency file ([#483](https://github.com/nvim-flutter/flutter-tools.nvim/issues/483)) ([65b7399](https://github.com/nvim-flutter/flutter-tools.nvim/commit/65b7399804315a1160933b64292d3c5330aa4e9f))
* **docs:** remove misleading debugger instructions ([377f21c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/377f21c46c2e5092d79ad50d48816280c0262539))
* **docs:** update repo name ([#400](https://github.com/nvim-flutter/flutter-tools.nvim/issues/400)) ([3d6979b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3d6979b900c8787906427fece1344a25c8e17eba))
* **documentChanges:** allow document renames ([a090c8e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a090c8e5a69fd91b93d750f46554faf07f026820))
* don't analyse flutter sdk packages ([#58](https://github.com/nvim-flutter/flutter-tools.nvim/issues/58)) ([cac78e7](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cac78e7b578c38c0c40dd619d7779833b0c96f59))
* don't attach lsp to buffer with empty path ([78b5a42](https://github.com/nvim-flutter/flutter-tools.nvim/commit/78b5a4249bada514be1e0471d50c6856cb416503))
* don't attempt to render nil guides ([c6db645](https://github.com/nvim-flutter/flutter-tools.nvim/commit/c6db6455aaac5642fac1b0fff1353ba6ddc0975d))
* don't scroll dev log if focused ([68d8637](https://github.com/nvim-flutter/flutter-tools.nvim/commit/68d863741e743af18c6892b1306cb9b2f271b371))
* don't show widget guides in preview windows ([fdfa48d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fdfa48d33de5d8fe51104d064aea4bc7e879c2c7))
* error on color ext marks set ([fdca1cf](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fdca1cf1ee1f02347b0b7f627cc73e04c6854484))
* **executable:** don't presume snap installation ([080144c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/080144ce1a2670664da1499b3d3a9b0cc2a70b8a))
* **executable:** resolve links for flutter_path ([#102](https://github.com/nvim-flutter/flutter-tools.nvim/issues/102)) ([5dc88c2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5dc88c2521004b9bb62cc8e0b5fb5ae76da96b12))
* **executable:** use exepath to flutter not snap ([db31c79](https://github.com/nvim-flutter/flutter-tools.nvim/commit/db31c79035e30c8ec65fbe9d2499d7e56c7ef685))
* fix dap crash on BufWritePost ([#427](https://github.com/nvim-flutter/flutter-tools.nvim/issues/427)) ([197c547](https://github.com/nvim-flutter/flutter-tools.nvim/commit/197c547954155b9eb81ddc7eac47c90c198fbca5))
* fixes error when no flutter binary was present and notifies user that we could not find the executable ([#480](https://github.com/nvim-flutter/flutter-tools.nvim/issues/480)) ([8a761c6](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8a761c6a8a3e6796158fee529bd4c0f8c7cff69c))
* **flutter-debug:** pass run options to runner callbacks ([#444](https://github.com/nvim-flutter/flutter-tools.nvim/issues/444)) ([d135e1d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d135e1d02f6a3a8808efc2b58950ab1fdd49d000))
* **fvm/windows:** append .bat extension on fvm command ([#469](https://github.com/nvim-flutter/flutter-tools.nvim/issues/469)) ([93e64d4](https://github.com/nvim-flutter/flutter-tools.nvim/commit/93e64d423784f473468e98dc7f29ace5cae8194e))
* **fvm/windows:** append '.bat' extention to flutter path ([#468](https://github.com/nvim-flutter/flutter-tools.nvim/issues/468)) ([f33c5b2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f33c5b2b94b7442c7b96a60e09319d71afb265bc))
* **guides:** do not draw guides over text ([#143](https://github.com/nvim-flutter/flutter-tools.nvim/issues/143)) ([e9471a9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e9471a942900d18f4cf2376400a36f8592321d52))
* **guides:** don't pass a list to utils.notify ([e6408b5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e6408b507ced052e04bae377279dbb366429391c))
* **guides:** improve error message rendering ([f8612bd](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f8612bda65109e7fdecb1cd42980920475180bf8))
* **guides:** prevent overwriting custom guide colors ([#335](https://github.com/nvim-flutter/flutter-tools.nvim/issues/335)) ([e44df1c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e44df1c8c4cc3bc31244a775cd04a95f7de91e53))
* **guides:** show guides for first child and adjust start index ([#134](https://github.com/nvim-flutter/flutter-tools.nvim/issues/134)) ([12d229a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/12d229aaff45e562e341142bd841c3061ea22727))
* handle deprecated vim.tbl_islist function ([e9f6f65](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e9f6f65ca5f72123a0f1e3a162d888e3889163f2))
* handle too many notification windows opening ([04afe19](https://github.com/nvim-flutter/flutter-tools.nvim/commit/04afe194f4de046437feab17a045519e51ff1b44))
* **highlights:** refresh on colorscheme change ([17484bb](https://github.com/nvim-flutter/flutter-tools.nvim/commit/17484bb2baa9bfdf3362d1269f67e2c68d6ced52))
* ignore invalid end indicices ([#32](https://github.com/nvim-flutter/flutter-tools.nvim/issues/32)) ([845656d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/845656df90262ba65a1fd65b84c094dd0923fc29))
* keep LSP attached and auto-save buffers after LSP rename operations ([8fa438f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8fa438f36fa6cb747a93557d67ec30ef63715c20))
* **labels:** add error handling to setting extmarks ([cb4f8d9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cb4f8d908279bc76c47faf3a79580ec11f27c0b3)), closes [#132](https://github.com/nvim-flutter/flutter-tools.nvim/issues/132)
* **lazy:** do not lazy require plenary modules ([469270a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/469270a3d52c81699849d0b6f73a3a72c4c89368))
* **log:** correct buffer variable in append function ([9955c98](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9955c98d1587ee92bd452e0c6f39cbd18de5cad9))
* **log:** ensure autoscroll finds correct window ([f06ac07](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f06ac0714e60c596af4d27efcf9f754919c58a8b))
* **log:** handle nil when clearing log ([7e6d861](https://github.com/nvim-flutter/flutter-tools.nvim/commit/7e6d8611d8606efca64cb8cf1ca07550b7087d1c))
* **log:** prevent cursor autoscroll spam ([1891476](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1891476b463d49a8d2fb3c8fc766ee2a8e8de772)), closes [#252](https://github.com/nvim-flutter/flutter-tools.nvim/issues/252) [#253](https://github.com/nvim-flutter/flutter-tools.nvim/issues/253)
* **log:** remove redundant autoscroll call in toggle ([e5a3998](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e5a399895ab92a66ad5f8c0c91b7980858d7e924))
* lsp rename when files with import is opened in another buffer ([29da857](https://github.com/nvim-flutter/flutter-tools.nvim/commit/29da857afe886ab476e69cd40af944b230628593))
* **lsp:** allow client to re-attach multiple times ([0bd2397](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0bd239706f3a512b4619118a0f1e736976ff4f46))
* **lsp:** avoid using private lsp client methods ([3ec80d3](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3ec80d3a1d800b80d64b50145764f053b6a385f4)), closes [#256](https://github.com/nvim-flutter/flutter-tools.nvim/issues/256)
* **lsp:** exclude pub-cache from analysis ([a936613](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a936613f596ac0919d8a013ce343f1214e4e2af5)), closes [#57](https://github.com/nvim-flutter/flutter-tools.nvim/issues/57)
* **lsp:** prefer re-using existing servers cwd ([b649892](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b6498925bc7ee9b8fa3c8dbf47cded7b77da4c82))
* **lsp:** restore dart go to super functionality ([#438](https://github.com/nvim-flutter/flutter-tools.nvim/issues/438)) ([b2ec4e0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b2ec4e0e1cc8df188c9ae9d4a0332acb020508dd))
* **lsp:** use regex for pub workspace detection instead of YAML parsing ([#516](https://github.com/nvim-flutter/flutter-tools.nvim/issues/516)) ([6d040bc](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6d040bc2606ce7e3b194dfaf0e70146162852eb6)), closes [#515](https://github.com/nvim-flutter/flutter-tools.nvim/issues/515)
* maybe fix type error using utils.echomsg ([b297950](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b29795065e7d11277c858c7b1cdad6e1a17704b0))
* **outline:** ensure window is valid ([ecd25ea](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ecd25eac6ae13f6fccd1aba4b7091ebf6db9a502))
* **outline:** improve outline URI handling ([#447](https://github.com/nvim-flutter/flutter-tools.nvim/issues/447)) ([8199f8b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8199f8b3b2234a534e518a7a4054364dcf6369c8))
* **outline:** position cursor correctly on select ([8f301cd](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8f301cd297b6f446e91ebf66253ff7552009457c))
* **outline:** remove duplicate prefix in hl names ([e17c2f5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e17c2f53a058a59a913291e47f612349dab4b956))
* parse fvm command json output ([#421](https://github.com/nvim-flutter/flutter-tools.nvim/issues/421)) ([54314bc](https://github.com/nvim-flutter/flutter-tools.nvim/commit/54314bcb6856dfd31a500226587c95402122e29f))
* prefer root-sdk binary over path ([#100](https://github.com/nvim-flutter/flutter-tools.nvim/issues/100)) ([a26797f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a26797f2b9613dafe7ce47e54d6adbd85b757c3c))
* prevent lsp colour configuration error ([9742a06](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9742a06f4468bfa0c0cb414eb757d2a3b8bbf782))
* **project_config:** show project config selector once on start ([#423](https://github.com/nvim-flutter/flutter-tools.nvim/issues/423)) ([a5a6036](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a5a6036d9a1a9dc4e32c526444c6cdfd349b9c86))
* **pub get:** show error messages if command fails ([ccfb761](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ccfb761c99579fa91e8c5916c011b44d0d89ca11))
* **quit:** remove attempt to close emulator job ([59682a0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/59682a056c37310f07825c2322f526e6ac0a3bd1))
* **README:** typo in 'Full Configuration' snippet ([#94](https://github.com/nvim-flutter/flutter-tools.nvim/issues/94)) ([d3c3d6d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d3c3d6d44334b1967f1069754d9044ea46cbf248))
* remove newline from guides error msg ([d9697b9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d9697b913a7e199e48b09403755774bed7063a90))
* replace deprecated vim.lsp.get_active_clients with  vim.lsp.get_clients ([c19f945](https://github.com/nvim-flutter/flutter-tools.nvim/commit/c19f94576f866888f1b84aa73c690b30de4b86fb))
* search plain strings in file path ([#174](https://github.com/nvim-flutter/flutter-tools.nvim/issues/174)) ([89a4727](https://github.com/nvim-flutter/flutter-tools.nvim/commit/89a47278d9d27537735ae4e5e97acfc58ceebf2b))
* select device only once when starting ([#424](https://github.com/nvim-flutter/flutter-tools.nvim/issues/424)) ([a526c30](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a526c30f1941a7472509aaedda13758f943c968e))
* select only dart language server when requesting color info ([#157](https://github.com/nvim-flutter/flutter-tools.nvim/issues/157)) ([6b13345](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6b13345dd7ffe3b0a08536b8fadfa288af137616))
* **start:** call lsp setup on start up ([a6e8b7d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a6e8b7de3d447fc2c69c6a0ceba6c6fd277f43cc))
* **telescope:** guard against nil opts in Run command from telescope ([d9c3bf9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d9c3bf9dcb256544782b4c99d9182a02708730a2))
* **telescope:** use dropdown theme for command picker ([b1f971a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b1f971acb3df4ac1364c05f3fbc9e818cc6542c0))
* toggling of boolean flutter dev tools commands ([#460](https://github.com/nvim-flutter/flutter-tools.nvim/issues/460)) ([07e1603](https://github.com/nvim-flutter/flutter-tools.nvim/commit/07e1603ef7e585d7944c14a7662ddc95e23cd3b7))
* **ui:** add check for line in buffer range ([0fbb3ee](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0fbb3ee9056236d907b4b5680fcaa1da23cddc29))
* **ui:** add correct default case for notify level ([15b770d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/15b770dcdca7ad2dab11cdf0dfdca34f04739471))
* **ui:** do not show empty notifications ([#192](https://github.com/nvim-flutter/flutter-tools.nvim/issues/192)) ([fc336d9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fc336d95ca00ae9c2a7c4fad57f131494fc825dd))
* **ui:** render labels only in the document range ([#360](https://github.com/nvim-flutter/flutter-tools.nvim/issues/360)) ([fd0443e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fd0443ede63d7ff52b98c25b75a822c65315df7c))
* **ui:** replace newlines ([#175](https://github.com/nvim-flutter/flutter-tools.nvim/issues/175)) ([bca467f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bca467f43d40b1a8ab15341b7c3d9d76bb3c88fb))
* **ui:** use correct mapping helper function ([cb49ca7](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cb49ca75cff20c9d444f2cdfbcabc1b750ab5995))
* update github actions ([cb09e56](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cb09e56b0a2fce36a260c933b766609eb0ed49a4))
* use default sorter for telescope picker ([bc0e026](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bc0e026c796d7c1cc5d42206a5b65d333bb0542c))
* use new vim.validate only in nvim v0.11 ([49be6d4](https://github.com/nvim-flutter/flutter-tools.nvim/commit/49be6d474c0cf9af089ff981be5ae22514f10c9c))
* use yaml parser for flutter dependency detection in pubspec.yaml ([#389](https://github.com/nvim-flutter/flutter-tools.nvim/issues/389)) ([ce18f5d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ce18f5da5f9c458cd26eef5c3accb0c37b2263c2))
* user proper names for validation function ([2d91a86](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2d91a86a43a1ae1303e48aac55542f57b5731990))
* **utils:** use correct name for group key ([37482ee](https://github.com/nvim-flutter/flutter-tools.nvim/commit/37482ee4120e1ba5df434bf815881880d7fef78e)), closes [#160](https://github.com/nvim-flutter/flutter-tools.nvim/issues/160)
* **widget_guides:** handle invalid start indices ([0d2fe47](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0d2fe479c54204c4b3e1fa675fd3ac86a5c01a2e))
* **windows:** devtools opening ([#492](https://github.com/nvim-flutter/flutter-tools.nvim/issues/492)) ([69db9cd](https://github.com/nvim-flutter/flutter-tools.nvim/commit/69db9cdac65ce536e20a8fc9a83002f007cc049c))


### Code Refactoring

* **lsp:** remove deprecated lsp start method ([ac07b75](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ac07b754977d6a99997aa41ba7903109143d7c28))
* **setup:** convert commands to use 0.7 apis ([68e246f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/68e246fb49ad56627be7307cd719d5580cc23e7c))
* **setup:** refactor autocommands ([276b477](https://github.com/nvim-flutter/flutter-tools.nvim/commit/276b477e806c2d1799938d1930505ca9f9960e12))
* **ui:** replace (some) custom ui with `vim.ui.*` ([#221](https://github.com/nvim-flutter/flutter-tools.nvim/issues/221)) ([467847f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/467847f694beb2e6496c83e56631d7dfae901a9d))


### Tests

* rename setup file to minimal_init.lua ([2707077](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2707077fed4e01add9fb468347be59775e7ee829))

## [3.0.0](https://github.com/nvim-flutter/flutter-tools.nvim/compare/v2.2.0...v3.0.0) (2026-05-03)


### ⚠ BREAKING CHANGES

* remove support to older than 0.11 nvim versions ([#525](https://github.com/nvim-flutter/flutter-tools.nvim/issues/525))

### Features

* remove support to older than 0.11 nvim versions ([#525](https://github.com/nvim-flutter/flutter-tools.nvim/issues/525)) ([417304b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/417304b5c83633a60c353f64ad6ba090fda6eab0))


### Bug Fixes

* **devtools:** stop DevTools server on flutter shutdown ([#521](https://github.com/nvim-flutter/flutter-tools.nvim/issues/521)) ([1f532b5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1f532b515cffd45ea6dc2d9399e06622515f42e7))

## [2.2.0](https://github.com/nvim-flutter/flutter-tools.nvim/compare/v2.1.0...v2.2.0) (2026-01-14)


### Features

* Add Inspect Widget command ([#509](https://github.com/nvim-flutter/flutter-tools.nvim/issues/509)) ([5e863a2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/5e863a2325ad216c36e88e860eedbb9e23ad4aa6))
* add Toggle Dev Log in telescope menu ([#511](https://github.com/nvim-flutter/flutter-tools.nvim/issues/511)) ([ad5fd81](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ad5fd8149e5a376c80afb17805bdaee6f6742ac8))
* **debugger:** fix file URI handling for Windows in inspect event ([#514](https://github.com/nvim-flutter/flutter-tools.nvim/issues/514)) ([3b2f652](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3b2f652e4f15c859d421f7520e15c74b9abde836))


### Bug Fixes

* **lsp:** use regex for pub workspace detection instead of YAML parsing ([#516](https://github.com/nvim-flutter/flutter-tools.nvim/issues/516)) ([6d040bc](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6d040bc2606ce7e3b194dfaf0e70146162852eb6)), closes [#515](https://github.com/nvim-flutter/flutter-tools.nvim/issues/515)

## [2.1.0](https://github.com/nvim-flutter/flutter-tools.nvim/compare/v2.0.0...v2.1.0) (2026-01-04)


### Features

* implement automatic widget inspector navigation ([#507](https://github.com/nvim-flutter/flutter-tools.nvim/issues/507)) ([685321f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/685321f6de92a57d2c38be96dcc885237b40bd04)), closes [#503](https://github.com/nvim-flutter/flutter-tools.nvim/issues/503)

## [2.0.0](https://github.com/nvim-flutter/flutter-tools.nvim/compare/v1.14.0...v2.0.0) (2026-01-03)


### ⚠ BREAKING CHANGES

* **config:** allow to pass additional arguments to flutter run command ([#407](https://github.com/nvim-flutter/flutter-tools.nvim/issues/407))
* **outline:** remove code actions from outline ([#387](https://github.com/nvim-flutter/flutter-tools.nvim/issues/387))

### Features

* add FlutterAttach command ([#425](https://github.com/nvim-flutter/flutter-tools.nvim/issues/425)) ([cf92ff1](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cf92ff1f0c3d18c1599d3af684b9a08c825c58c8))
* add FlutterDebug command ([#420](https://github.com/nvim-flutter/flutter-tools.nvim/issues/420)) ([da3682a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/da3682a3bdd3e19ed42194381a53e7bbace7682a))
* add option to disable ftplugin ([#417](https://github.com/nvim-flutter/flutter-tools.nvim/issues/417)) ([85492be](https://github.com/nvim-flutter/flutter-tools.nvim/commit/85492bee069af1155bb10bfbee90ac7d4168eced))
* add possibility to set default run args ([#471](https://github.com/nvim-flutter/flutter-tools.nvim/issues/471)) ([d1022db](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d1022db80dab2a565563993843e8c60b20a3df39))
* add pub workspace support for LSP root detection ([#505](https://github.com/nvim-flutter/flutter-tools.nvim/issues/505)) ([2f26317](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2f26317d001e715065889b15ab922b5ae16c9397))
* adds analyzer_web_port config which starts the LSP analysis server with the given port ([#479](https://github.com/nvim-flutter/flutter-tools.nvim/issues/479)) ([ed9f78b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ed9f78bfd649c3d87238a20ebe08f72e46a3380a))
* **config:** add ability to set web-browser-flag ([#406](https://github.com/nvim-flutter/flutter-tools.nvim/issues/406)) ([80770c6](https://github.com/nvim-flutter/flutter-tools.nvim/commit/80770c67aa2d9e1eccf6bb52fac78115831acd04))
* **config:** allow to pass additional arguments to flutter run command ([#407](https://github.com/nvim-flutter/flutter-tools.nvim/issues/407)) ([4f48d8b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4f48d8b84bb09cfe66e13884f5fb1847b18d403f))
* **devices:** add cold boot option for android emulators ([#412](https://github.com/nvim-flutter/flutter-tools.nvim/issues/412)) ([40f974b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/40f974b15f82f9af498adda8d93aabd637f3ab58))
* improves project root detection by always going up the directory tree until we find a project root marker ([#482](https://github.com/nvim-flutter/flutter-tools.nvim/issues/482)) ([3a3f6f5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3a3f6f5fadf7e1b976ba5f35df0219d1d4762a38))
* **log:** add focus option for log window ([9ad676c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9ad676c61dfc590f3852955ed2030abacc54b0e1))
* **log:** add toggle command for log buffer ([#411](https://github.com/nvim-flutter/flutter-tools.nvim/issues/411)) ([bc36e2e](https://github.com/nvim-flutter/flutter-tools.nvim/commit/bc36e2eb3f2d8be939aa5667615cc3aceebb5874))
* open dev tools when running in debug mode ([#419](https://github.com/nvim-flutter/flutter-tools.nvim/issues/419)) ([2f9db8b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2f9db8b15133ab789cd1be913e2d081e19b1f88d))
* **outline:** remove code actions from outline ([#387](https://github.com/nvim-flutter/flutter-tools.nvim/issues/387)) ([6610090](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6610090a4e68d10fd73b68450004dafd26e7cc34))
* resolve package urls when using `gf` or `gF` ([#392](https://github.com/nvim-flutter/flutter-tools.nvim/issues/392)) ([6bf887b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6bf887bb9442b80a67f36e7465a66de4202d8a3f))
* setup plugin on `require("flutter-tools").setup_project` ([#408](https://github.com/nvim-flutter/flutter-tools.nvim/issues/408)) ([fb976f0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fb976f0e83296d011be95701085ff4711a89de94))
* support passing args to FlutterAttach command ([#454](https://github.com/nvim-flutter/flutter-tools.nvim/issues/454)) ([a643f2f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a643f2ff012d5c3ec4322576d48bce1dea244841))


### Bug Fixes

* add conditional use of client.notify because of deprecation ([#481](https://github.com/nvim-flutter/flutter-tools.nvim/issues/481)) ([0fcb08a](https://github.com/nvim-flutter/flutter-tools.nvim/commit/0fcb08a4ae46fafff6cfd8f4af0207305e3bcf10))
* add write permission to release workflow ([654c013](https://github.com/nvim-flutter/flutter-tools.nvim/commit/654c01335248a21be0b9d145103b3f40115ca63a))
* Buffer is not 'modifiable' ([#477](https://github.com/nvim-flutter/flutter-tools.nvim/issues/477)) ([d4b0cb9](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d4b0cb9cfcda4cb27e6b68bad20cba0be542b55b))
* check for nil value when handle_log is called ([#436](https://github.com/nvim-flutter/flutter-tools.nvim/issues/436)) ([26c511d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/26c511d5009c87c740a544e2c9d4139aff18a692))
* **commands:** force debug with FlutterDebug command ([4a8aad2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/4a8aad2839482fbe3bb3f14d8ac574f711fdfd53))
* **commands:** make inspect widget command work in debug runner ([#413](https://github.com/nvim-flutter/flutter-tools.nvim/issues/413)) ([824faf5](https://github.com/nvim-flutter/flutter-tools.nvim/commit/824faf57964c77ae8a80c9e642e5124d0e5c28e9))
* correct vim API reference in color utils ([1d6b57f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1d6b57f8f9622218f775063e9bc465863ea3099e))
* correct vim.fn.has() comparisons to use explicit == 1 ([6faf2c7](https://github.com/nvim-flutter/flutter-tools.nvim/commit/6faf2c70bd56f1fe78620591a2bb73f4dc6f4870))
* **dap:** improve debugger integration with nvim-dap ([#455](https://github.com/nvim-flutter/flutter-tools.nvim/issues/455)) ([8edcdab](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8edcdabfe982c77482ebde2ba3f46f2adc677e64))
* **devices:** filter out unwanted device lines ([1787090](https://github.com/nvim-flutter/flutter-tools.nvim/commit/1787090d66482552505a6498e3d2f06fb4290f96))
* do not start new LSP client when navigating to flutter dependency file ([#483](https://github.com/nvim-flutter/flutter-tools.nvim/issues/483)) ([65b7399](https://github.com/nvim-flutter/flutter-tools.nvim/commit/65b7399804315a1160933b64292d3c5330aa4e9f))
* **docs:** remove misleading debugger instructions ([377f21c](https://github.com/nvim-flutter/flutter-tools.nvim/commit/377f21c46c2e5092d79ad50d48816280c0262539))
* **docs:** update repo name ([#400](https://github.com/nvim-flutter/flutter-tools.nvim/issues/400)) ([3d6979b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/3d6979b900c8787906427fece1344a25c8e17eba))
* error on color ext marks set ([fdca1cf](https://github.com/nvim-flutter/flutter-tools.nvim/commit/fdca1cf1ee1f02347b0b7f627cc73e04c6854484))
* fix dap crash on BufWritePost ([#427](https://github.com/nvim-flutter/flutter-tools.nvim/issues/427)) ([197c547](https://github.com/nvim-flutter/flutter-tools.nvim/commit/197c547954155b9eb81ddc7eac47c90c198fbca5))
* fixes error when no flutter binary was present and notifies user that we could not find the executable ([#480](https://github.com/nvim-flutter/flutter-tools.nvim/issues/480)) ([8a761c6](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8a761c6a8a3e6796158fee529bd4c0f8c7cff69c))
* **flutter-debug:** pass run options to runner callbacks ([#444](https://github.com/nvim-flutter/flutter-tools.nvim/issues/444)) ([d135e1d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/d135e1d02f6a3a8808efc2b58950ab1fdd49d000))
* **fvm/windows:** append .bat extension on fvm command ([#469](https://github.com/nvim-flutter/flutter-tools.nvim/issues/469)) ([93e64d4](https://github.com/nvim-flutter/flutter-tools.nvim/commit/93e64d423784f473468e98dc7f29ace5cae8194e))
* **fvm/windows:** append '.bat' extention to flutter path ([#468](https://github.com/nvim-flutter/flutter-tools.nvim/issues/468)) ([f33c5b2](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f33c5b2b94b7442c7b96a60e09319d71afb265bc))
* keep LSP attached and auto-save buffers after LSP rename operations ([8fa438f](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8fa438f36fa6cb747a93557d67ec30ef63715c20))
* **log:** correct buffer variable in append function ([9955c98](https://github.com/nvim-flutter/flutter-tools.nvim/commit/9955c98d1587ee92bd452e0c6f39cbd18de5cad9))
* **log:** ensure autoscroll finds correct window ([f06ac07](https://github.com/nvim-flutter/flutter-tools.nvim/commit/f06ac0714e60c596af4d27efcf9f754919c58a8b))
* **log:** handle nil when clearing log ([7e6d861](https://github.com/nvim-flutter/flutter-tools.nvim/commit/7e6d8611d8606efca64cb8cf1ca07550b7087d1c))
* **log:** remove redundant autoscroll call in toggle ([e5a3998](https://github.com/nvim-flutter/flutter-tools.nvim/commit/e5a399895ab92a66ad5f8c0c91b7980858d7e924))
* **lsp:** restore dart go to super functionality ([#438](https://github.com/nvim-flutter/flutter-tools.nvim/issues/438)) ([b2ec4e0](https://github.com/nvim-flutter/flutter-tools.nvim/commit/b2ec4e0e1cc8df188c9ae9d4a0332acb020508dd))
* **outline:** improve outline URI handling ([#447](https://github.com/nvim-flutter/flutter-tools.nvim/issues/447)) ([8199f8b](https://github.com/nvim-flutter/flutter-tools.nvim/commit/8199f8b3b2234a534e518a7a4054364dcf6369c8))
* parse fvm command json output ([#421](https://github.com/nvim-flutter/flutter-tools.nvim/issues/421)) ([54314bc](https://github.com/nvim-flutter/flutter-tools.nvim/commit/54314bcb6856dfd31a500226587c95402122e29f))
* **project_config:** show project config selector once on start ([#423](https://github.com/nvim-flutter/flutter-tools.nvim/issues/423)) ([a5a6036](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a5a6036d9a1a9dc4e32c526444c6cdfd349b9c86))
* select device only once when starting ([#424](https://github.com/nvim-flutter/flutter-tools.nvim/issues/424)) ([a526c30](https://github.com/nvim-flutter/flutter-tools.nvim/commit/a526c30f1941a7472509aaedda13758f943c968e))
* toggling of boolean flutter dev tools commands ([#460](https://github.com/nvim-flutter/flutter-tools.nvim/issues/460)) ([07e1603](https://github.com/nvim-flutter/flutter-tools.nvim/commit/07e1603ef7e585d7944c14a7662ddc95e23cd3b7))
* update github actions ([cb09e56](https://github.com/nvim-flutter/flutter-tools.nvim/commit/cb09e56b0a2fce36a260c933b766609eb0ed49a4))
* use new vim.validate only in nvim v0.11 ([49be6d4](https://github.com/nvim-flutter/flutter-tools.nvim/commit/49be6d474c0cf9af089ff981be5ae22514f10c9c))
* use yaml parser for flutter dependency detection in pubspec.yaml ([#389](https://github.com/nvim-flutter/flutter-tools.nvim/issues/389)) ([ce18f5d](https://github.com/nvim-flutter/flutter-tools.nvim/commit/ce18f5da5f9c458cd26eef5c3accb0c37b2263c2))
* user proper names for validation function ([2d91a86](https://github.com/nvim-flutter/flutter-tools.nvim/commit/2d91a86a43a1ae1303e48aac55542f57b5731990))
* **windows:** devtools opening ([#492](https://github.com/nvim-flutter/flutter-tools.nvim/issues/492)) ([69db9cd](https://github.com/nvim-flutter/flutter-tools.nvim/commit/69db9cdac65ce536e20a8fc9a83002f007cc049c))

## [1.14.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.13.0...v1.14.0) (2024-08-29)


### Features

* **config:** add possibility to provide cwd via project configuration ([#383](https://github.com/akinsho/flutter-tools.nvim/issues/383)) ([7efc0d8](https://github.com/akinsho/flutter-tools.nvim/commit/7efc0d86094ecd80fb50e19935596acd7956255c)), closes [#329](https://github.com/akinsho/flutter-tools.nvim/issues/329)
* respect cwd when detecting is it flutter project, handle running dart-only projects ([#384](https://github.com/akinsho/flutter-tools.nvim/issues/384)) ([cde6625](https://github.com/akinsho/flutter-tools.nvim/commit/cde66252ae44f4cafd130fd2c4e117dcd36b05b5)), closes [#375](https://github.com/akinsho/flutter-tools.nvim/issues/375)


### Bug Fixes

* **dap:** attach debugger on windows ([#381](https://github.com/akinsho/flutter-tools.nvim/issues/381)) ([d8f2eac](https://github.com/akinsho/flutter-tools.nvim/commit/d8f2eac1734e0e68050bc57600e5f2ba775b1ec4))

## [1.13.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.12.0...v1.13.0) (2024-08-23)


### Features

* **CI:** add ability to trigger CI workflow manually ([b6b62ba](https://github.com/akinsho/flutter-tools.nvim/commit/b6b62baa0ade0b78c44a452244aadbc4f74082e6))
* **dap:** add option `evaluate_to_string_in_debug_views` ([#377](https://github.com/akinsho/flutter-tools.nvim/issues/377)) ([0842bbe](https://github.com/akinsho/flutter-tools.nvim/commit/0842bbedf43bb3643b3b8402160687b5bb90054b))


### Bug Fixes

* adapt to nvim depractions ([#379](https://github.com/akinsho/flutter-tools.nvim/issues/379)) ([e951b0a](https://github.com/akinsho/flutter-tools.nvim/commit/e951b0a1bcc5abe2d801e3a1762b37b0fbbf2acd))

## [1.12.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.11.0...v1.12.0) (2024-08-19)


### Features

* **labels:** add option to set closing tag virtual text priority ([#373](https://github.com/akinsho/flutter-tools.nvim/issues/373)) ([18a28d6](https://github.com/akinsho/flutter-tools.nvim/commit/18a28d6e4c71bb85a1cd5ce0ce42a63dfcdfa4c6))

## [1.11.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.10.0...v1.11.0) (2024-08-14)


### Features

* add ability to filter flutter output in dev log ([#371](https://github.com/akinsho/flutter-tools.nvim/issues/371)) ([654c477](https://github.com/akinsho/flutter-tools.nvim/commit/654c4779a42575d12edd8177e70263d63ae39833))

## [1.10.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.9.1...v1.10.0) (2024-06-25)


### Features

* **config:** add an optional pre_run_callback attribute to `setup_project` ([f898850](https://github.com/akinsho/flutter-tools.nvim/commit/f8988508798ebc4af2c43405d2c35432a50efd9f))


### Bug Fixes

* **ui:** add check for line in buffer range ([0fbb3ee](https://github.com/akinsho/flutter-tools.nvim/commit/0fbb3ee9056236d907b4b5680fcaa1da23cddc29))
* **ui:** render labels only in the document range ([#360](https://github.com/akinsho/flutter-tools.nvim/issues/360)) ([fd0443e](https://github.com/akinsho/flutter-tools.nvim/commit/fd0443ede63d7ff52b98c25b75a822c65315df7c))

## [1.9.1](https://github.com/akinsho/flutter-tools.nvim/compare/v1.9.0...v1.9.1) (2024-05-18)


### Bug Fixes

* handle deprecated vim.tbl_islist function ([e9f6f65](https://github.com/akinsho/flutter-tools.nvim/commit/e9f6f65ca5f72123a0f1e3a162d888e3889163f2))
* replace deprecated vim.lsp.get_active_clients with  vim.lsp.get_clients ([c19f945](https://github.com/akinsho/flutter-tools.nvim/commit/c19f94576f866888f1b84aa73c690b30de4b86fb))

## [1.9.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.8.0...v1.9.0) (2024-03-28)


### Features

* **fvm:** support FVM in monorepo setup ([21c4496](https://github.com/akinsho/flutter-tools.nvim/commit/21c4496ad8e0aaca10a5abed5acef3b831b8b460))


### Bug Fixes

* **guides:** prevent overwriting custom guide colors ([#335](https://github.com/akinsho/flutter-tools.nvim/issues/335)) ([e44df1c](https://github.com/akinsho/flutter-tools.nvim/commit/e44df1c8c4cc3bc31244a775cd04a95f7de91e53))

## [1.8.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.7.0...v1.8.0) (2024-02-14)


### Features

* add flutter dependency detection ([#326](https://github.com/akinsho/flutter-tools.nvim/issues/326)) ([7f93847](https://github.com/akinsho/flutter-tools.nvim/commit/7f93847e32bb00bedeb2648219584c606a860d99))


### Bug Fixes

* don't attach lsp to buffer with empty path ([78b5a42](https://github.com/akinsho/flutter-tools.nvim/commit/78b5a4249bada514be1e0471d50c6856cb416503))

## [1.7.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.6.0...v1.7.0) (2024-01-03)


### Features

* add option to configure flutter mode via config ([#314](https://github.com/akinsho/flutter-tools.nvim/issues/314)) ([69466cc](https://github.com/akinsho/flutter-tools.nvim/commit/69466cc5ce3743bfb08ae07b0c415d7e549437d4))
* add performance_overlay, repaint_rainbow and slow_animations commands ([deb4fa8](https://github.com/akinsho/flutter-tools.nvim/commit/deb4fa80812157e6c6dadaa25dfe0cfa42950e5c))
* add web port param to config ([#320](https://github.com/akinsho/flutter-tools.nvim/issues/320)) ([b13d46b](https://github.com/akinsho/flutter-tools.nvim/commit/b13d46b3a06a9e2c414d0020c0cb7cf0dd51d426))

## [1.6.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.5.1...v1.6.0) (2023-12-18)


### Features

* **commands:** add install/uninstall commands to menu ([#315](https://github.com/akinsho/flutter-tools.nvim/issues/315)) ([cd73844](https://github.com/akinsho/flutter-tools.nvim/commit/cd738444c27d3a34f03b6d43df08c814e8232fb7))


### Bug Fixes

* **commands:** set current device while running project ([045fa0f](https://github.com/akinsho/flutter-tools.nvim/commit/045fa0f56234943464a06666183cd1a3089aeca2))

## [1.5.1](https://github.com/akinsho/flutter-tools.nvim/compare/v1.5.0...v1.5.1) (2023-10-04)


### Bug Fixes

* **dap:** fix cwd not being considered ([0c97d46](https://github.com/akinsho/flutter-tools.nvim/commit/0c97d46afead1885560c5c5c8bbfe0a9f1d13f05))

## [1.5.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.4.1...v1.5.0) (2023-10-01)


### Features

* **dap:** add custom commands to dap ([af591f5](https://github.com/akinsho/flutter-tools.nvim/commit/af591f5504250ba285a564aa75895e1e5fb166d6))

## [1.4.1](https://github.com/akinsho/flutter-tools.nvim/compare/v1.4.0...v1.4.1) (2023-09-20)


### Bug Fixes

* lsp rename when files with import is opened in another buffer ([29da857](https://github.com/akinsho/flutter-tools.nvim/commit/29da857afe886ab476e69cd40af944b230628593))

## [1.4.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.3.1...v1.4.0) (2023-09-18)


### Features

* add root_patterns to config ([#287](https://github.com/akinsho/flutter-tools.nvim/issues/287)) ([0ba9698](https://github.com/akinsho/flutter-tools.nvim/commit/0ba969873f1fb345efef4baa053c8c43c443ab84))

## [1.3.1](https://github.com/akinsho/flutter-tools.nvim/compare/v1.3.0...v1.3.1) (2023-07-24)


### Bug Fixes

* **dap:** define adapter and config when running standalone dart ([#272](https://github.com/akinsho/flutter-tools.nvim/issues/272)) ([356f643](https://github.com/akinsho/flutter-tools.nvim/commit/356f64339ff44ae1e615b90bb0739892acf2c522))

## [1.3.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.2.1...v1.3.0) (2023-05-10)


### Features

* **project_config:** add extra arguments ([#258](https://github.com/akinsho/flutter-tools.nvim/issues/258)) ([5fbd2a1](https://github.com/akinsho/flutter-tools.nvim/commit/5fbd2a146bfebcbcff1aec832f7e9d1263737db2))


### Bug Fixes

* **lsp:** avoid using private lsp client methods ([3ec80d3](https://github.com/akinsho/flutter-tools.nvim/commit/3ec80d3a1d800b80d64b50145764f053b6a385f4)), closes [#256](https://github.com/akinsho/flutter-tools.nvim/issues/256)

## [1.2.1](https://github.com/akinsho/flutter-tools.nvim/compare/v1.2.0...v1.2.1) (2023-05-04)


### Bug Fixes

* **log:** prevent cursor autoscroll spam ([1891476](https://github.com/akinsho/flutter-tools.nvim/commit/1891476b463d49a8d2fb3c8fc766ee2a8e8de772)), closes [#252](https://github.com/akinsho/flutter-tools.nvim/issues/252) [#253](https://github.com/akinsho/flutter-tools.nvim/issues/253)

## [1.2.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.1.0...v1.2.0) (2023-04-20)


### Features

* **commands:** add option to silence flutter errors ([#246](https://github.com/akinsho/flutter-tools.nvim/issues/246)) ([bafdc2c](https://github.com/akinsho/flutter-tools.nvim/commit/bafdc2c931bad4495835f51b819df842c615ae52))

## [1.1.0](https://github.com/akinsho/flutter-tools.nvim/compare/v1.0.2...v1.1.0) (2023-04-18)


### Features

* add FlutterRename command ([#234](https://github.com/akinsho/flutter-tools.nvim/issues/234)) ([4d9391b](https://github.com/akinsho/flutter-tools.nvim/commit/4d9391b5c217003666d4ffb4db665ad30362a959))
* **config:** add project configuration ([#232](https://github.com/akinsho/flutter-tools.nvim/issues/232)) ([f898ac2](https://github.com/akinsho/flutter-tools.nvim/commit/f898ac2340b4ff1950e82f7181a92d0b9134e78b))
* **decorations:** view selected project config in statusline ([#241](https://github.com/akinsho/flutter-tools.nvim/issues/241)) ([5967d65](https://github.com/akinsho/flutter-tools.nvim/commit/5967d65f993427f7fd33bd4d7d9ca85a384db9f4))

## [1.0.2](https://github.com/akinsho/flutter-tools.nvim/compare/v1.0.1...v1.0.2) (2023-03-31)


### Bug Fixes

* **color:** ensure values exist when setting colors ([bdd6365](https://github.com/akinsho/flutter-tools.nvim/commit/bdd6365b92e42ceb6404d493c0f1fef76fa42b90))

## [1.0.1](https://github.com/akinsho/flutter-tools.nvim/compare/v1.0.0...v1.0.1) (2023-03-31)


### Bug Fixes

* **color:** use correct require path ([f12b1f4](https://github.com/akinsho/flutter-tools.nvim/commit/f12b1f43c8d4617cc6454bfd066e72175c117755))
* **config:** use correct require path ([7db39ef](https://github.com/akinsho/flutter-tools.nvim/commit/7db39ef83d22656e19bc65dd58234fd33dcc2d1e))
