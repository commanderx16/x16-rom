# Licenses

The X16 ROM consists of various components with different licenses:

## Commercial Licenses

The following components are based on non-open source projects, and their base code has commercial licenses:

| Component                                   | Subdirectory    | Copyright |
|---------------------------------------------|-----------------|-----------|
| Commodore KERNAL                            | `kernal/cbm`    | &copy;1983 Commodore Business Machines (CBM) |
| Microsoft BASIC (with Commodore extensions) | `basic`,`math`  | &copy;1977 Microsoft Corp.<br/>&copy;1983 Commodore Business Machines (CBM) |
| GEOS                                        | `geos`          | &copy;1985 Berkeley Softworks |

The X16 project has a license to use this code in the context of the X16 computer. If you want to use these components outside of the context of the X16, please contaxt [Cloanto](https://www.amigaforever.com) (KERNAL and BASIC) and [Click Here Software](https://clickheresoftware.com) (GEOS) for details.

## General Public License V3

The following component is GPLv3-licensed.

| Component                                 | Subdirectory       | License |
|-------------------------------------------|--------------------|---------|
| MEGA65 KERNAL Reimplementation            | `kernal/open-roms` | GPLv3   |

This component is **not** a part of a default build!

## Public Domain

The following components are in the public domain:

| Component                                 | Subdirectory | License       |
|-------------------------------------------|--------------|---------------|
| PETSCII charset                           | `charset`    | public domain |
| ISO charset (PXLfont)                     | `charset`    | public domain |
| Keyboard tables                           | `keymap`     | public domain |
| Machine Language Monitor                  | `monitor`    | public domain |

## 3-Clause BSD

The following components are under the 3-clause BSD license:

| Component                                 | File            | License       |
|-------------------------------------------|-----------------|---------------|
| LZSA2 Decompression                       | `kernal/lzsa.s` | 3-clause BSD  |

## 2-Clause BSD

All code outside of the subdirectories above as well as *additions* to legacy code are under the 2-clause BSD license.

| Component                                 | Subdirectory | License       |
|-------------------------------------------|--------------|---------------|
| BASIC *additions*                         | `basic`      | 2-clause BSD  |
| KERNAL *additions*                        | `kernal`     | 2-clause BSD  |
| GEOS *additions*                          | `geos`       | 2-clause BSD  |
| CMDR-DOS and FAT32 for 6502               | `dos`        | 2-clause BSD  |
| CodeX Interactive Assembly Environment    | `codex`      | 2-clause BSD  |

