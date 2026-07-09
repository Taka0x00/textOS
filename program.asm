org 0x0000  ;プログラムを置くオフセット

;定数宣言
VGA_GRAPHIC_MODE equ    0x13
VRAM_SEGMENT     equ    0xa000
SCREEN_SIZE      equ    64000
COLOR_BLACK      equ    0x00
COLOR_SNAKE      equ    10
Y_LINE_OFFSET    equ    6400

;キーボードスキャンコード
KEY_UP      equ 0x48
KEY_DOWN    equ 0x50
KEY_LEFT    equ 0x4b
KEY_RIGHT   equ 0x4d

;蛇の方向定義
DIR_NONE    equ 0x00
DIR_UP      equ 0x01
DIR_DOWN    equ 0x02
DIR_LEFT    equ 0x03
DIR_RIGHT   equ 0x04

;蛇関連の定数宣言
MAX_SNAKE_LENGTH equ 50

programStart:

    mov ah, 0x00    ;画面をテキスト表示モードからグラフィックモードに切り替える
    mov al, VGA_GRAPHIC_MODE    ;VGAグラフィックモード(320*200pixel,256色)
    int 0x10        ;画面、ビデオ出力のためのソフトウェア割込み

    mov ax, 0x1000
    mov ds, ax  ;data Segmentに0x1000を代入

gameLoop:

    ;stosb(Store String Byte : 1byte保存しろ)の命令書
    mov ax, VRAM_SEGMENT  ;0xa000はビデオメモリのセグメント
    mov es, ax      ;書き込み先のセグメント指定
    xor di, di      ;書き込み先のオフセット指定
    mov al, COLOR_BLACK    ;色番号(黒に相当)
    mov cx, SCREEN_SIZE   ;カウンタレジスタを320*200に
    rep stosb       ;Strong String Byte(alレジスタの値をdiレジスタが指すメモリ番地に1byte書き込み、diを1進める命令)をcxレジスタが0になるまで繰り返す

    xor ax, ax
    mov es, ax      ;セグメントレジスタのリセット
    xor bl, bl      ;一つ前のキー入力の削除
    jmp .inputLoop

.inputLoop:
    ;step1 : 入力の受け取り
    mov ah, 0x01    ;キー入力状態の確認モード(プログラムは動き続ける)
    int 0x16        ;キーボードからの入力を制御するBIOSの割込み
    jz .inputEnd    ;バッファが空になったらループを抜ける
    
    ;バッファが空でなければ、それを読み込む(キーボードバッファはFIFO)
    mov ah, 0x00    ;キー入力の読み込みモード
    int 0x16        ;ahにスキャンコードが,alにアスキーコードが入力される
    mov bl, ah      ;blにスキャンコードを代入

.inputEnd:

    cmp bl, 0       ;ループを抜けた時点でblには一番最後に押されたキーが代入されている。もし0ならこのターンには何も入力されていなかったことになる
    je .noInput

    ;押されたキーに応じて背景色を変更する
    cmp bl, KEY_UP      ;上矢印キー
    je .keyUp
    cmp bl, KEY_DOWN    ;下矢印
    je .keyDown
    cmp bl, KEY_LEFT    ;左矢印
    je .keyLeft
    cmp bl, KEY_RIGHT   ;右矢印
    je .keyRight

    jmp .noInput    ;どの矢印でもなければ、処理を飛ばす

.keyUp:
    cmp byte [snakeDir], DIR_DOWN   ;もし既に下を向ていいたら
    je .noInput                     ;処理を飛ばす

    mov byte [snakeDir], DIR_UP     ;上向き
    jmp .noInput

.keyDown:
    cmp byte [snakeDir], DIR_UP     ;既に上を向いていたら
    je .noInput                     ;処理を飛ばす

    mov byte [snakeDir], DIR_DOWN   ;下向き
    jmp .noInput

.keyLeft:
    cmp byte [snakeDir], DIR_RIGHT  ;既に右を向いていたら
    je .noInput                     ;処理を飛ばす

    mov byte [snakeDir], DIR_LEFT   ;左向き
    jmp .noInput

.keyRight:
    cmp byte [snakeDir], DIR_LEFT   ;既に左を向いていたら
    je .noInput                     ;処理を飛ばす

    mov byte [snakeDir], DIR_RIGHT ;右向き
    jmp .noInput

.noInput:
;step2 状態の更新(蛇の座標の計算とか)

    mov al, [snakeDir]

    cmp al, DIR_UP
    je .moveUp
    cmp al, DIR_DOWN
    je .moveDown
    cmp al, DIR_LEFT
    je .moveLeft
    cmp al, DIR_RIGHT
    je .moveRight

    jmp render

.moveUp:
    dec byte [snakeY]
    jmp render
.moveDown:
    inc byte [snakeY]
    jmp render
.moveLeft:
    dec byte [snakeX]
    jmp render
.moveRight:
    inc byte [snakeX]
    jmp render

render:
    call drawSnakeHead
    call drawApple

    ;cpuは爆速なので、FPSの調整を行う
    mov ah, 0x86    ;指定した時間プログラムの実行を止めるモード。単位はマイクロ秒。上位16bitと下位16bitに分割してセット
    mov cx, 0x0003  ;上位16bit
    mov dx, 0x0090  ;下位16bit
    int 0x15        ;呼び出し

    jmp gameLoop

drawSnakeHead:
    ;VRAMのセグメントをセット
    mov al, [snakeX]
    mov cl, [snakeY]
    call getOffset  ;座標に対応したオフセットがbxに代入される

    mov ax, VRAM_SEGMENT
    mov es, ax

    mov ch, 20  ;縦のカウンター

.drawRow:
    mov cl, 20  ;横のカウンター
    mov di, bx  ;destination indexにデータの書き込み先のアドレス(オフセット)を代入

.drawPixel:
    mov byte [es:di], COLOR_SNAKE    ;緑色
    inc di  ;オフセットをインクリメント
    dec cl  ;横のカウンターをデクリメント
    jnz .drawPixel          ;clが0でなければ繰り返す
    add bx, 320 ;オフセットを1行分進める
    dec ch      ;縦のカウンターを減らす
    jnz .drawRow;二重ループみたいなことしてるね

    ret ;関数をcallされたらretで帰ってくる

drawApple:
    mov al, [appleX]
    mov cl, [appleY]
    call getOffset  ;座標に対応したオフセットがbxに代入される

    mov ax, VRAM_SEGMENT
    mov es, ax

    mov si, appleSprite

    mov ch, 20
.drawRow:
    mov cl, 20
    mov di, bx

.drawPixel:
    lodsb

    cmp al,255
    je .skipPixel

    mov [es:di], al

.skipPixel:
    inc di
    dec cl
    jnz .drawPixel

    add bx, 320
    dec ch
    jnz .drawRow

    ret

;alにX座標を、clにY座標をあらかじめ代入してから使うこと
getOffset:
    push ax
    push dx

    ; Y * 6400
    mov al, cl
    xor ah, ah
    mov cx, 6400
    mul cx              ; DX:AX = Y * 6400
    mov bx, ax

    ; X を復元
    pop dx              ; 捨てる（push dx と対応）
    pop ax              ; AX = 元のX

    mov dx, ax
    shl ax, 4           ; X * 16
    shl dx, 2           ; X * 4
    add ax, dx          ; X * 20

    add bx, ax

    ret

snakeX db 0
snakeY db 0
snakeDir db 0   ;蛇の方向(1:up 2:down 3:left 4:right)
snakeLength db 1;
bodyX times MAX_SNAKE_LENGTH db 0
bodyY times MAX_SNAKE_LENGTH db 0

appleX db 5
appleY db 8

appleSprite:
;葉っぱと茎
    db 255,255,255,255,255,255,255,255, 2 , 2 , 2 ,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255, 2 , 2 , 2 , 2 , 2 , 2 ,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255, 6 ,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255, 6 ,255,255,255,255,255,255,255,255,255,255
;実の最上部
    db 255,255,255,255, 1 , 1 , 1 , 1 ,255,255, 6 ,255, 1 , 1 , 1 , 1 ,255,255,255,255
    db 255,255,255, 1 , 4 , 4 , 4 , 4 , 1 , 1 , 6 , 4 , 4 , 4 , 4 , 4 , 1 ,255,255,255
    db 255,255, 1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255,255
    db 255, 1 , 4 , 4 ,12 ,12 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255
;実の中央
    db 255, 1 , 4 ,12 ,12 ,12 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255
    db  1 , 4 , 4 ,12 ,12 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 
    db  1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 
    db  1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 
;実の真ん中
    db 255, 1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255
    db 255, 1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255
    db 255,255, 1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255,255
    db 255,255,255, 1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255,255,255
;実の最下部
    db 255,255,255,255, 1 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 4 , 1 ,255,255,255,255
    db 255,255,255,255,255, 1 , 4 , 4 , 4 , 1 , 1 , 4 , 4 , 4 , 1 ,255,255,255,255,255
    db 255,255,255,255,255,255, 1 , 1 , 1 ,255,255, 1 , 1 , 1 ,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
