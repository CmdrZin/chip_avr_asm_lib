/*
 * sysdefs.h
 *
 * Created: 5/18/2015 10:04:44 PM
 *  Author: Chip
 */ 


#ifndef SYSDEFS_H_
#define SYSDEFS_H_

#ifndef FALSE
#define FALSE (0)
#endif

#ifndef TRUE
#define TRUE (1)
#endif


/* General purpose struct for init() and service(), neither return values. */
/* Access only puts data into the output fifo to be read. Does not return data. */
typedef struct
{
	const uint16_t	id;
	void		(*function)();
} DEV_FUNCTION_ENTRY;

typedef struct
{
	const uint16_t	command;
	const uint16_t	size;			// number of bytes in command message.
} DEV_COMMAND_SIZE;

typedef struct
{
	const uint16_t	id;
	const DEV_FUNCTION_ENTRY*	cmd_table;		// address of the command table for the device ID.
	const DEV_COMMAND_SIZE*		size_table;		// number of bytes in the command message.
} DEV_ACCESS_ENTRY;


#endif /* SYSDEFS_H_ */