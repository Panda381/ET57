
#include <stdio.h>
#include <Windows.h>

// main function
int main(int argc, char* argv[])
{
	if (argc != 2)
	{
		printf("Syntax: Enter calculator name\n");
		return 2;
	}

	SYSTEMTIME st;
	GetLocalTime(&st);
	printf("; %s build version, auto generated, do not modify!\n\n"
			"\t.text\n\n"
			".global Build\n"
			"Build:	.asciz\t\"%s %02d%02d%02d\"\n"
			"\t.balign\t2\n", argv[1], argv[1], st.wYear-2000, st.wMonth, st.wDay);
	return 0;
}

