/*
 * service.c
 *
 * Created: 5/19/2015 5:47:14 PM
 *  Author: Chip
 */ 

#include <avr/io.h>

#include "command_tables.h"

#include "flash_table.h"

/*
 * Calls each service using a look-up branch table.
 * The service checks its associated TIC bit and calls its service function if its bit is set.
 * The TIC bits are defined in the sysTimer.h file.
 */

void service_all()
{
	int	index = 0;
	uint16_t deviceID;
	void (*func)();

	while(1) {
//		deviceID = dev_service_table[index].id;			// Does not generate correct code.
		deviceID = flash_get_access_cmd(index, (DEV_FUNCTION_ENTRY*)dev_service_table);
//		func = dev_service_table[index].function;		// Does not generate correct code.
		func = (void (*)())flash_get_access_func(index, (DEV_FUNCTION_ENTRY*)dev_service_table);

		if(deviceID != 0) {
			func();
			} else {
			break;
		}
		++index;
	}
}