#include <stdio.h>
#include <stdint.h>
#include <unistd.h>

int main(){
	ssize_t i, l;
	uint32_t value;
	uint8_t buffer[24];
	int started, index;
	started = index = 0;
	while(1){
		l = read(0, buffer, 24);
		if(l < 1)break;
		if(started)printf("\n");
		started = 1;
		printf("\t");
		for(i = 0; i < l; i += 4){
			value = ((uint32_t)buffer[i + 0] << 0) | ((uint32_t)buffer[i + 1] << 8) | ((uint32_t)buffer[i + 2] << 16) | ((uint32_t)buffer[i + 3] << 24);
			if(i)printf(" ");
			printf("%d 0x%08X", index++, (unsigned int)value);
		}
	}
	printf("\n");
}

