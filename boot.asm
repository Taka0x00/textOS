org 0x7c00

start:
    cli ;割り込みの禁止

    xor ax, ax ;axレジスタに0を代入
    mov ds, ax ;data segmentに直接0を代入できないので、axレジスタを介して代入
    mov ss, ax 
    mov sp, 0x7c00 ;文字列の先頭アドレスをsource indexレジスタに代入

    mov [bootDrive], dl ;BIOSが起動したドライブ番号を指定

    ;BIOSにディスクを読み込ませるとき、メモリのどこにデータを並べたらいいかをes:bxで指定
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02    ;BIOSに対してディスクからセクタを読み込め(0x02)と命令
    mov al, 5       ;ディスクっから5セクタ分を読み込めと指定

    ;CHSアドレス指定
    mov ch, 0       ;シリンダ番号=0
    mov cl, 2       ;ディスクの2番目のセクタから読み込めと指示
    mov dh, 0       ;ヘッド番号=0

    mov dl, [bootDrive]    ;ドライブ番号を指定。0x00は初めのフロッピーディスクドライブ。0x80にすれば、USBメモリやハードディスクから起動できる

    int 0x13        ;BIOSの割り込みを実行
    jc diskError   ;上手く読み込めなかったらエラー処理を回す(jump if carry)

    jmp 0x1000:0x0000

diskError:
    jmp diskError

bootDrive: db 0

times 510-($-$$) db 0   ;0埋め
dw 0xaa55               ;これがブートプログラムであることを示す魔法
