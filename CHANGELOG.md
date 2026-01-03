# Changelog

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
