all: ass3


ass3: main.o drone.o printer.o scheduler.o target.o
	gcc -m32 -g -Wall -o ass3 drone.o main.o printer.o scheduler.o target.o
	rm *.o


main.o: main.s
	nasm -g -f elf -c -w+all -o main.o main.s
target.o: target.s
	nasm -g -f elf -w+all -o target.o target.s
drone.o: drone.s
	nasm -g -f elf -w+all -o drone.o drone.s
printer.o: printer.s
	nasm -g -f elf -w+all -o printer.o printer.s
scheduler.o: scheduler.s
	nasm -g -f elf -w+all -o scheduler.o scheduler.s


.PHONY: clean
clean:
	rm -f *.o ass3