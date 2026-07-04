org 0x7c00 ;originに0x7c00を指定

start:
    mov ax, 0 ;axレジスタに0を代入
    mov ds, ax ;data segmentに直接0を代入できないので、axレジスタを介して代入
    mov es, ax ;extra segmentに直接0を代入できないので、axレジスタを介して代入
    mov si, msgTextOS ;文字列の先頭アドレスをsource indexレジスタに代入

putLoop:
    mov al, [si] ;source indexレジスタの指すメモリから1byteだけ読み取り、alに代入
    cmp al, 0 ;先程読み取った文字が0(null終端文字)と等しいか比較(CoMPare)
    je infLoop ;もし等しいなら(Jump if Equal)infLoopに飛ぶ
    
    mov ah, 0x0e ;ahレジスタに0x0e(1文字表示モード)を代入
    int 0x10 ;0x10の割り込み(INTerrupt)を呼び出し。これでBIOSの画面出力プログラムを呼び出して描画が出来る

    inc si ;source indexの指すメモリをインクリメント
    jmp putLoop ;ループの先頭に戻る

infLoop:
    hlt ;ハルト(cpuを省電力の待機状態にする命令)
    jmp infLoop ;待機状態から何かしらの命令で復帰したとき再びinfLoopに戻して無限ループさせる

msgTextOS: db "welcome to textOS",0x0d, 0x0a, "type your code here...",0

times 510 - ($ - $$) db 0 ;残りを0埋め
dw 0xaa55 ;最後の2byteだけ、このファイルが正しいOSであることを示す魔法を書く
