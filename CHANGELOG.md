# Changelog

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
