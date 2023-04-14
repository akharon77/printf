extern void printfWrapper(const char *str, ...);

int main()
{
    printfWrapper("%p %e %d %s %x %d%%%c%b hehehe %s %n0%f\n", -1ll, "Love", 3802, 100, 33, 127, "Love");
    return 0;
}
