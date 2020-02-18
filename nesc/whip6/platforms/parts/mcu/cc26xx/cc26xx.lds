/*
 @file       cc26x0f128.lds
 @brief      CC26x0F128 linker configuration file for GNU compiler.

 @Revised     $Date: 2015-11-20 13:18:46 +0100 (fr, 20 nov 2015) $
 @Revision    $Revision: 16377 $

  Copyright (C) 2015 Texas Instruments Incorporated - http:www.ti.com/


  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions
  are met:

    Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

    Neither the name of Texas Instruments Incorporated nor the names of
    its contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

MEMORY
{
    FLASH (RX) : ORIGIN = 0x0, LENGTH = 0x1D000
    FLASH_FLOG (R) : ORIGIN = 0x1D000, LENGTH = 0x1000
    FLASH_BL (RX) : ORIGIN = 0x1E000, LENGTH = 0x1FA8
    FLASH_CCFG (RX) : ORIGIN = 0x1FFA8, LENGTH = 88
    SRAM (RWX) : ORIGIN = 0x20000000, LENGTH = 0x5000
    GPRAM (RWX) : ORIGIN = 0x11000000, LENGTH = 0x2000
}

/* Highest address of the stack. Used in the startup file.*/
_estack = ORIGIN(SRAM) + LENGTH(SRAM);

_sram = ORIGIN(SRAM);
_esram = ORIGIN(SRAM) + LENGTH(SRAM);

_Min_Stack_Size = 0x200;

SECTIONS
{
    .text :
    {
        _text = .;
        KEEP(*(.vectors))
        *(.text*)
        *(.rodata*)
        *(.init)
        *(.fini*)
        *(.eh_frame*)
        _etext = .;
    } > FLASH = 0

    .ARM.exidx :
    {
        __exidx_start = .;
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
        __exidx_end = .;
    } > FLASH

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > FLASH

    .bss (NOLOAD) : ALIGN(4)
    {
        _bss = .;
        *(.bigalignbss*)
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > SRAM

    .data : ALIGN(4)
    {
        _data = .;
        *(vtable)
        *(.data*)
        _edata = .;
    } > SRAM AT > FLASH
    _ldata = LOADADDR(.data);

    .gpram : ALIGN(4)
    { 
        _gpram = .;
        *(.gpram*)
        _egpram = .;
    } > GPRAM AT > FLASH
    _lgpram = LOADADDR(.gpram);

    /* This section is replaced by a generated NULL-terminated version string,
     * see Makefile.main.
     *
     * Put all sections that uses flash memory before `.appversion` section
     * to avoid overwriting them by the generated version string. */
    .appversion : ALIGN(1)
    {
        KEEP(*(.appversion))
    } > FLASH

    .flog : ALIGN(1)
    {
        _flog = .;
        . = . + LENGTH(FLASH_FLOG);
        _eflog = .;
    } > FLASH_FLOG = 0

    .heap (NOLOAD) : ALIGN(1)
    {
        . = ALIGN(4);
        _heap = .;
        KEEP(*(.heap*))
        _eheap = .;
    } > SRAM

    /* A dummy section, used to check that there is at least _Min_Stack_Size
       bytes of SRAM left */
    .minstack (NOLOAD) :
    {
        . = ALIGN(4);
        _stack = .;
        . = . + _Min_Stack_Size;
        . = ALIGN(4);
    } > SRAM

    .bootloader :
    {
        _bootloader = .;
        bootloader_entry = .;
        . = . + LENGTH(FLASH_BL);
        _ebootloader = .;
    } > FLASH_BL = 0

    .ccfg :
    { 
        KEEP(*(.ccfg*))
    } > FLASH_CCFG
}
