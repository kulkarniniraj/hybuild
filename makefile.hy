
(QUOTE-RULE #[[
OBJS = \
	bio.o\
	console.o\
	exec.o\
	file.o\
	fs.o\
	ide.o\
	ioapic.o\
	kalloc.o\
	kbd.o\
	lapic.o\
	log.o\
	main.o\
	mp.o\
	picirq.o\
	pipe.o\
	proc.o\
	sleeplock.o\
	spinlock.o\
	string.o\
	swtch.o\
	syscall.o\
	sysfile.o\
	sysproc.o\
	trapasm.o\
	trap.o\
	uart.o\
	vectors.o\
	vm.o\
]])

(SET "OBJS" [
	"bio.o"
	"console.o"
	"exec.o"
	"file.o"
	"fs.o"
	"ide.o"
	"ioapic.o"
	"kalloc.o"
	"kbd.o"
	"lapic.o"
	"log.o"
	"main.o"
	"mp.o"
	"picirq.o"
	"pipe.o"
	"proc.o"
	"sleeplock.o"
	"spinlock.o"
	"string.o"
	"swtch.o"
	"syscall.o"
	"sysfile.o"
	"sysproc.o"
	"trapasm.o"
	"trap.o"
	"uart.o"
	"vectors.o"
	"vm.o" ])

#[[
# Cross-compiling (e.g., on Mac OS X)
# TOOLPREFIX = i386-jos-elf

# Using native tools (e.g., on X86 Linux)
#TOOLPREFIX = 
]]

(if (IS-NOT-SET "TOOLPREFIX")
	(QUOTE-RULE #[[
# Try to infer the correct TOOLPREFIX if not set
TOOLPREFIX := $(shell if i386-jos-elf-objdump -i 2>&1 | grep '^elf32-i386$$' >/dev/null 2>&1; \
	then echo 'i386-jos-elf-'; \
	elif objdump -i 2>&1 | grep 'elf32-i386' >/dev/null 2>&1; \
	then echo ''; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find an i386-*-elf version of GCC/binutils." 1>&2; \
	echo "*** Is the directory with i386-jos-elf-gcc in your PATH?" 1>&2; \
	echo "*** If your i386-*-elf toolchain is installed with a command" 1>&2; \
	echo "*** prefix other than 'i386-jos-elf-', set your TOOLPREFIX" 1>&2; \
	echo "*** environment variable to that prefix and run 'make' again." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
]])
	None
)

(QUOTE-RULE #[[
# If the makefile can't find QEMU, specify its path here
# QEMU = qemu-system-i386

# Try to infer the correct QEMU
ifndef QEMU
QEMU = $(shell if which qemu > /dev/null; \
	then echo qemu; exit; \
	elif which qemu-system-i386 > /dev/null; \
	then echo qemu-system-i386; exit; \
	elif which qemu-system-x86_64 > /dev/null; \
	then echo qemu-system-x86_64; exit; \
	else \
	qemu=/Applications/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu; \
	if test -x $$qemu; then echo $$qemu; exit; fi; fi; \
	echo "***" 1>&2; \
	echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
	echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
	echo "*** or have you tried setting the QEMU variable in Makefile?" 1>&2; \
	echo "***" 1>&2; exit 1)
endif
]])

(QUOTE-RULE #[[
CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb -m32 -Werror -fno-omit-frame-pointer
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
# FreeBSD ld wants ``elf_i386_fbsd''
LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null | head -n 1)

# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif
]])

(SET "CC" "gcc")
(SET "CFLAGS" (+ "-fno-pic -static -fno-builtin -fno-strict-aliasing " 
		"-O2 -Wall -MD -ggdb -m32 -Werror -fno-omit-frame-pointer " 
		"-fno-stack-protector -fno-pie -no-pie "))
(SET "LD" "ld")
(SET "LDFLAGS" "-m elf_i386")
(SET "OBJDUMP" "objdump")
(SET "OBJCOPY" "objcopy")

(RULE 
	:target "xv6.img" 
	:deps ["bootblock" "kernel"] 
	:recipes ["dd if=/dev/zero of=xv6.img count=10000" 
	"dd if=bootblock of=xv6.img conv=notrunc"
	"dd if=kernel of=xv6.img seek=1 conv=notrunc"])

(RULE 
	:target "xv6memfs.img" 
	:deps ["bootblock" "kernelmemfs"] 
	:recipes [
		"dd if=/dev/zero of=xv6memfs.img count=10000"
		"dd if=bootblock of=xv6memfs.img conv=notrunc"
		"dd if=kernelmemfs of=xv6memfs.img seek=1 conv=notrunc"
	])

(RULE
	:target "bootblock"
	:deps ["bootasm.S" "bootmain.c"]
	:recipes [
		["$CC" "$CFLAGS" "-fno-pic -O -nostdinc -I. -c bootmain.c"]
		["$CC" "$CFLAGS" "-fno-pic -nostdinc -I. -c bootasm.S"]
		["$LD" "$LDFLAGS" "-N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o"]
		["$OBJDUMP" "-S bootblock.o > bootblock.asm"]
		["$OBJCOPY" "-S -O binary -j .text bootblock.o bootblock"]
		"./sign.pl bootblock"
	])

(RULE
	:target "entryother"
	:deps ["entryother.S"]
	:recipes [
		"$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c entryother.S"
		"$(LD) $(LDFLAGS) -N -e start -Ttext 0x7000 -o bootblockother.o entryother.o"
		"$(OBJCOPY) -S -O binary -j .text bootblockother.o entryother"
		"$(OBJDUMP) -S bootblockother.o > entryother.asm"])

(RULE
	:target "initcode"
	:deps ["initcode.S"]
	:recipes [
		"$(CC) $(CFLAGS) -nostdinc -I. -c initcode.S"
		"$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o initcode.out initcode.o"
		"$(OBJCOPY) -S -O binary initcode.out initcode"
		"$(OBJDUMP) -S initcode.o > initcode.asm"])

(RULE
	:target "kernel"
	:deps ["$(OBJS)" "entry.o" "entryother" "initcode" "kernel.ld"]
	:recipes [
		"$(LD) $(LDFLAGS) -T kernel.ld -o kernel entry.o $(OBJS) -b binary initcode entryother"
		" $(OBJDUMP) -S kernel > kernel.asm "
		" $(OBJDUMP) -t kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym "
	])

(let [NEWOBJS (+ (list (filter (fn [x] (!= x "ide.o"))
					 (GET "OBJS"))) ["memide.o"])]
	(RULE
		:target "kernelmemfs" 
		:deps (+ NEWOBJS ["entry.o" "entryother" "initcode" "kernel.ld" "fs.img"])
		:recipes [
			(+ ["$LD" "$LDFLAGS" "-T kernel.ld -o kernelmemfs entry.o"]  NEWOBJS ["-b binary initcode entryother fs.img"])
			["$OBJDUMP" "-S kernelmemfs > kernelmemfs.asm"]
			["$OBJDUMP" "-t kernelmemfs | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernelmemfs.sym"] ]))

(RULE
	:target "tags"
	:deps (+ (GET "OBJS") ["entryother.S" "_init"])
	:recipes [
		"etags *.S *.c"
	])

(RULE
	:target "vectors.S"
	:deps ["vectors.pl"]
	:recipes [
		"./vectors.pl > vectors.S"	
	])

(SET "ULIB" ["ulib.o" "usys.o" "printf.o" "umalloc.o"])

(RULE
	:target "_%" 
	:deps (+ ["%.o"]  (GET "ULIB"))
	:recipes [
		["$LD" "$LDFLAGS" "-N -e main -Ttext 0 -o $@ $^"]
		["$OBJDUMP" "-S $@ > $*.asm"]
		["$OBJDUMP" "-t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $*.sym"] ])

(RULE
	:target "_forktest" 
	:deps (+ ["forktest.o"] (GET "ULIB"))
	:recipes [
		["$LD" "$LDFLAGS" "-N -e main -Ttext 0 -o _forktest forktest.o ulib.o usys.o"]
		["$OBJDUMP" "-S _forktest > forktest.asm"]
	])

(RULE 
	:target "mkfs"
	:deps ["mkfs.c" "fs.h"]
	:recipes [
		"gcc -Werror -Wall -o mkfs mkfs.c"	
	])

(QUOTE-RULE #[[
# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o
]])

(SET "UPROGS" [
	"_cat"
	"_echo"
	"_forktest"
	"_grep"
	"_init"
	"_kill"
	"_ln"
	"_ls"
	"_mkdir"
	"_rm"
	"_sh"
	"_stressfs"
	"_usertests"
	"_wc"
	"_zombie"])

(RULE 
	:target "fs.img"
	:deps (+ ["mkfs" "README"] (GET "UPROGS"))
	:recipes [
		(+ "./mkfs fs.img README "	
		   (.join " " (GET "UPROGS")))
	])

(QUOTE-RULE #[[
-include *.d
]])

(RULE
	:target "clean"
	:recipes [
		"rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg"
		"rm -f *.o *.d *.asm *.sym vectors.S bootblock entryother"
		"rm -f initcode initcode.out kernel xv6.img fs.img kernelmemfs"
		"rm -f xv6memfs.img mkfs .gdbinit"
		"rm -f $(UPROGS)"])

(defn not-empty [lst] 
	(list (filter (fn [x] (!= x "")) lst)))

(defn split [txt] (.split txt "\n"))

(SET "FILES" (not-empty (split (RUN "grep -v '^\\#' ./xv6-public/runoff.list"))))

(SET "PRINT" 
 	 (+ ["runoff.list" "runoff.spec" "README" "toc.hdr" "toc.ftr"] 
 	 	(GET "FILES")))

(RULE
	:target "xv6.pdf"
	:deps (GET "PRINT")
	:recipes [
		"./runoff"
		"ls -l xv6.pdf"])

(RULE
	:target "print"
	:deps ["xv6.pdf"])

(RULE
	:target "bochs "
	:deps ["fs.img" "xv6.img"]
	:recipes [
		"if [ ! -e .bochsrc ]; then ln -s dot-bochsrc .bochsrc; fi"
		"bochs -q"])

(defn is-valid-cmd [cmd]
	(let [val (RUN-SAFE (+ "which " cmd))]
		(if (!= val "")
			True
			False)))

(SET "QEMU" (cond 
	(is-valid-cmd "qemu") "qemu"
	(is-valid-cmd "qemu-system-i386") "qemu-system-i386"
	(is-valid-cmd "qemu-system-x86_64") "qemu-system-x86_64"))

(SET "GDBPORT" (+ (% (int (RUN "id -u")) 5000) 25000))
(SET "QEMUGDB" 
	(if (!= 
			(RUN (+ 
					(GET-STR "QEMU") 
					" -help | grep -q '^-gdb'"))
			"")
		(+ "-gdb tcp::" (GET-STR "GDBPORT"))
		(+ "-s -p " (GET-STR "GDBPORT"))))

(SET "CPUS" 2)
(SET "QEMUOPTS"  
	 (+ "-drive file=fs.img,index=1,media=disk,format=raw -drive "
	 	"file=xv6.img,index=0,media=disk,format=raw -smp "
		(GET-STR "CPUS")
		" -m 512 " 
		(GET-STR "QEMUEXTRA")))

(RULE 
	:target "qemu"
	:deps ["fs.img" "xv6.img"]
	:recipes [
		["$QEMU" "-serial mon:stdio" "$QEMUOPTS"]
	])

(RULE
	:target "qemu-memfs"
	:deps ["xv6memfs.img"]
	:recipes [
		["$QEMU" "-drive file=xv6memfs.img,index=0,media=disk,format=raw -smp" "$CPUS" "-m 256"]
	])

(RULE
	:target "qemu-nox"
	:deps ["fs.img" "xv6.img"]
	:recipes [
		["$QEMU" "-nographic" "$QEMUOPTS"]
	])

(RULE 
	:target ".gdbinit" 
	:deps [".gdbinit.tmpl"]
	:recipes [
		(+ "sed \"s/localhost:1234/localhost:" (GET-STR "GDBPORT") "/\" < $^ > $@")
	])

(RULE
	:target "qemu-gdb"
	:deps ["fs.img" "xv6.img" ".gdbinit"]
	:recipes [
		"@echo \"*** Now run 'gdb'.\" 1>&2"
		["$QEMU" "-serial mon:stdio" "$QEMUOPTS" "-S" "$QEMUGDB"]
	])

(RULE
	:target "qemu-nox-gdb"
	:deps ["fs.img" "xv6.img" ".gdbinit"]
	:recipes [
		"@echo \"*** Now run 'gdb'.\" 1>&2"
		["$QEMU" "-nographic" "$QEMUOPTS" "-S" "$QEMUGDB"]	
	])

(SET "EXTRA" [
	"mkfs.c ulib.c user.h cat.c echo.c forktest.c grep.c kill.c"
	"ln.c ls.c mkdir.c rm.c stressfs.c usertests.c wc.c zombie.c"
	"printf.c umalloc.c"
	"README dot-bochsrc *.pl toc.* runoff runoff1 runoff.list"
	".gdbinit.tmpl gdbutil" ])

(RULE
	:target "dist"
	:phony True
	:recipes [	
		"rm -rf dist"
		"mkdir dist"
		"for i in $(FILES); \\"
		"do \\"
		"	grep -v PAGEBREAK $$i >dist/$$i; \\"
		"done"
		"sed '/CUT HERE/,$$d' Makefile >dist/Makefile"
		"echo >dist/runoff.spec"
		["cp" "$EXTRA" "dist"] ])

(RULE
	:target "dist-test"
	:phony True
	:recipes [
		"rm -rf dist"
		"make dist"
		"rm -rf dist-test"
		"mkdir dist-test"
		"cp dist/* dist-test"
		"cd dist-test; $(MAKE) print"
		"cd dist-test; $(MAKE) bochs || true"
		"cd dist-test; $(MAKE) qemu"		
	])

(RULE
	:target "tar"
	:recipes [
		"rm -rf /tmp/xv6"
		"mkdir -p /tmp/xv6"
		"cp dist/* dist/.gdbinit.tmpl /tmp/xv6"
		"(cd /tmp; tar cf - xv6) | gzip >xv6-rev10.tar.gz "
	])
