// func one() (ret int64)
TEXT main·one(SB),4,$8 // NOSPLIT=4
    MOVQ    $1, AX
    MOVQ    AX, ret+0(FP)
    RET

TEXT main·foosum(SB),$8
    MOVQ $0, AX
    RET
