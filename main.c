extern void printfWrapper(const char *str, ...);

int main()
{
    printfWrapper("%d %s %x %d%%%c%b\n", -1ll, "Love", 3802, 100, 33, 127);
    return 0;
}
