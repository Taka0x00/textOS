void systemInit(void)
{
    unsigned char *vram = (unsigned char *)0xb8000;

    vram[0] = 'C';
    vram[1] = 0x07;

    while (1)
    {
        __asm__("hlt");
    }
}
