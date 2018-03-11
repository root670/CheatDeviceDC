/*
 * Cheat engine for CheatDeviceDC
 * Based on CodeBreaker/Xploder engine
 */

#define MAX_CODES 100

.global CodeEngineStart
.global CodeListStart

.text
.align 2

CodeEngineStart:
    stc.l   sr, @-r15   ! Push sr, r0-r14 onto stack
    mov.l	r1, @-r15
    mov.l	r2, @-r15
    mov.l	r3, @-r15
    mov.l	r4, @-r15
    mov.l	r5, @-r15
    mov.l	r6, @-r15
    mov.l	r7, @-r15
    mov.l	r8, @-r15
    mov.l	r9, @-r15
    mov.l	r10, @-r15
    mov.l	r11, @-r15
    mov.l	r12, @-r15
    mov.l	r13, @-r15
    mov.l	r14, @-r15

    mov.l   CodeListStart, r0   !r0 = CodeListStart
    mov     r0, r4              !r4 = CodePointer

NextCode:
    mov.l	@r4+, r0            ! Get code from	code list and increment CodePointer.
    nop
    ! if(code != NULL) {
    !   goto CodeHandler;
    ! } else {
    !   goto CodeEngineEnd;
    ! }
    cmp/eq	#0, r0
    bf	CodeHandler
    bra	CodeEngineEnd
    nop

CodeHandler:
    mov	#0xFFFFFF8C, r8
    shll16	r8
    shll8	r8
    mov	r0, r1
    shll8	r1		    ! remove code type byte	from code
    shlr8	r1
    or	r1, r8		    ! r8 = code address
    shlr16	r0
    shlr8	r0
    and	#0xF, r0        ! r0 = code type
    mov.l	@r4+, r9    ! r9 = code value

! Handle each supported code type
ProcessCode:
    cmp/eq	#0, r0
    bt	Write8
    cmp/eq	#1, r0
    bt	Write16
    cmp/eq	#2, r0
    bt	Write32
    cmp/eq	#3, r0
    bt	WriteArray
    cmp/eq	#4, r0
    bt	SerialWrite
    cmp/eq	#5, r0
    bt	CopyBytes
    cmp/eq	#8, r0
    bt	CodeType8
    cmp/eq	#0xD, r0
    bt	Compare
    bra	Write32         ! 6, 9, a
    nop

/*
 * ==================
 * Code-type Handlers
 * ==================
 */

/*
 * 8-bit constant write
 * 00aaaaaa
 * 000000vv
 * Constantly writes the 8-bit value @v to address @a.
 */
Write8:
    bra	NextCode
    mov.b	r9, @r8         ! *r8 =	(uint8)r9

/*
 * 16-bit constant write
 * 01aaaaaa
 * 0000vvvv
 * Constantly writes the 16-bit value @v to address @a.
 */
Write16:
    bra	NextCode
    mov.w	r9, @r8         ! *r8 =	(uint16)r9

/*
 * 32-bit constant write
 * 02aaaaaa
 * vvvvvvvv
 * Constantly writes the 32-bit value @v to address @a.
 */
Write32:
    bra	NextCode
    mov.l	r9, @r8         ! *r8 =	r9

/*
 * 32-bit constant array write
 * 0300nnnn
 * aaaaaaaa
 * vvvvvvvv <- value 1
 * vvvvvvvv <- value 2
 * ...
 * vvvvvvvv <- value n
 * Constantly writes @n 32-bit values starting at address @a. Values are in
 * @n subsequent code lines.
 */
WriteArray:
    extu.w	r8, r8

WriteArray_Loop:
    dt	r8		            ! r8 -=	1
    mov.l	@r4+, r0	    ! get next code
    mov.l	r0, @r9
    bf/s	WriteArray_Loop	! if(r8	> 0) WriteArray_Loop()
    add	#4, r9		        ! increase destination address
    bra	NextCode	        ! done writing array
    nop

/*
 * 32-bit constant serial write
 * 04aaaaaa
 * nnnnssss
 * vvvvvvvv
 * a = starting address
 * n = number of times to write (16 bits)
 * s = size of address step (divided by 4) (16 bits)
 * v = start value (32 bits)
 * Starting at address @a, write the 32-bit value @v to (@n * address). In each
 * cycle, the address is incremented by (@s * 4).
 */
SerialWrite:
    mov.l	@r4+, r0	! r0 = value to	write
    mov	r9, r1
    shlr16	r1		    ! r1 = number of times to write
    extu.w	r9, r9		! r9 = increment amount
    shll2	r9

SerialWrite_Loop:
    dt	r1		                ! r1 -=	1
    mov.l	r0, @r8
    bf/s	SerialWrite_Loop
    add	r9, r8		            ! increase destination address
    bra	NextCode
    nop

/*
 * Copy bytes
 * 05ssssss
 * dddddddd
 * nnnnnnnn
 * Copy @n bytes from source address @s to destination address @d.
 */
CopyBytes:
    mov.l	@r4+, r1	! r1 = number of bytes to copy

CopyBytes_Loop:
    dt	r1	            ! r1 -=	1
    mov.b	@r8+, r0	! get destination address
    mov.b	r0, @r9
    bf/s	CopyBytes_Loop
    add	#1, r9
    bra	NextCode
    nop

/*
 * Pointer write
 * 08aaaaaa & w
 * vvvvvvvv
 * iiiiiiii
 * a = address to load 32-bit base address (21 bits)
 * i = 32-bit offset to be added to base
 * v = 8/16/32-bit value to be written to (base + offset)
 * w = Bit-width of @v to write (0 = 8-bit, 1 = 16-bit, 2 = 32-bit)
 */
CodeType8:
    mov.l	@r4+, r1	! r1 = next code line
    mov	r8, r0
    and	#3, r0		    ! set next code type to 0, 1, or 2
    shlr2	r8		    ! align to 32-bit boundary
    shll2	r8
    mov.l	@r8, r8		! get 32-bit value at address
    add	r1, r8		    ! r8 +=	r1
                        ! base address + offset
    mov	r8, r2		    ! r2 = r8
    shlr16	r2
    shlr8	r2
    mov	#0xFFFFFF8C, r1
    cmp/eq	r1, r2      ! is address in cached memory?
    bt/s	ProcessCode	! yes, continue with pointer write
    mov	#0xFFFFFFAC, r1
    cmp/eq	r1, r2      ! is address in uncached memory?
    bt	ProcessCode	    ! yes, continue with pointer write
    mov	#0xC, r1
    cmp/eq	r1, r2      ! is address in MMU-controlled memory?
    bt	ProcessCode     ! yes, continue with pointer write
    bra	NextCode
    nop

/*
 * 16-bit multi-line conditional
 * 0Daaaaaa
 * nnttvvvv
 * Compare the value at address @a to value @v, and execute the next @n code
 * lines iff the test condition @t is true.
 * 0 = Equal
 * 1 = Not Equal
 * 2 = Less Than
 * 3 = Greater than
 * Note:
 * When the launcher processes the code list it will:
 *   1. Convert E-type codes to D-type
 *   2. Set @n to 2 for existing D-type codes
 */
Compare:
    mov.w	@r8, r1
    extu.w	r1, r1
    mov	r9, r3
    shlr16	r3
    shlr8	r3
    shll2	r3
    mov	r9, r0
    shlr16	r0
    extu.b	r0, r0
    extu.w	r9, r9
    cmp/eq	#0, r0
    bt	Compare_Eq
    cmp/eq	#1, r0
    bt	Compare_Neq
    cmp/eq	#2, r0
    bt	Compare_Lt
    cmp/eq	#3, r0
    bt	Compare_Gt

Compare_Eq:
    cmp/eq	r1, r9
    bt	NextCode        ! Test condition true, continue processing codes
    bf/s	NextCode    ! Test condition false, skip over @n code lines
    add	r3, r4

Compare_Neq:
    cmp/eq	r1, r9
    bf	NextCode
    bt/s	NextCode
    add	r3, r4

Compare_Lt:
    cmp/hs	r9, r1
    bf	NextCode
    bt/s	NextCode
    add	r3, r4

Compare_Gt:
    cmp/hi	r9, r1
    bt	NextCode
    bf/s	NextCode
    add	r3, r4

    /*
     * Not sure what the following code lines do. I don't think they're ever
     * executed.
     */
    add	#-4, r8
    extu.w	r8, r8
    shll2	r8
    bra	NextCode
    add	r8, r4
    nop

CodeEngineEnd:
    mov.l	@r15+, r14      ! Restore r14-r0, sr from stack
    mov.l	@r15+, r13
    mov.l	@r15+, r12
    mov.l	@r15+, r11
    mov.l	@r15+, r10
    mov.l	@r15+, r9
    mov.l	@r15+, r8
    mov.l	@r15+, r7
    mov.l	@r15+, r6
    mov.l	@r15+, r5
    mov.l	@r15+, r4
    mov.l	@r15+, r3
    mov.l	@r15+, r2
    mov.l	@r15+, r1
    ldc.l	@r15+, sr

    mov.l	@r15+, r8       ! Original function start
    mov.l	@r15+, r9
    mov.l	@r15+, r10
    mov.l	@r15+, r11
    mov.l	@r15+, r12
    mov.l	@r15+, r13
    mov.l	@r15+, r14
    lds.l	@r15+, macl
    lds.l	@r15+, mach
    lds.l	@r15+, pr
    mov.l	h8C001994, r0
    mov     #0, r2
    mov.l	r2, @r0
    rts
    nop                     ! Original function end

h8C001994:
    .long   0x8C001994

CodeListStart:
    .space  (MAX_CODES*4)
