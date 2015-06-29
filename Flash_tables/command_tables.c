/*
 * Slave Command Project
 *
 * org: 05/14/2015
 * rev: 06/23/2015
 * author: Nels "Chip" Pearson
 *
 * Target: ATtiny84, 8Mhz, USI I2C Slave
 *
 * Device tables generated from parameter file.
 *
 * Dependent on:
 *	device files
 */ 

#include <avr/io.h>
#include <avr/pgmspace.h>

#include "sysdefs.h"

// Device prototypes
#include "dev_period_counter.h"
#include "dev_solenoid.h"
#include "debugAT84.h"


/* *** Call Tables for INIT, SERVICE, and ACCESS *** */
/* These tables are placed here to insure that the upper byte is 0x00 to simplify look-up. */
/* A 0 command can be used, but it MUST be the first command in the table, else it will be seen
 * as a termination value. */

/*
 * This table is auto-generated from the configuration file.
 * Used by intialize.c :: init_all()
 * Format:
 *  struct {
 *	  uint16_t	id;
 *	  void		(*function)();
 *	}
 */
const DEV_FUNCTION_ENTRY dev_init_table[] PROGMEM =
{
	{ DEV_PERIOD_COUNTER_ID, dev_period_counter_init },
	{ DEV_SOLENOID_1_ID, dev_solenoid_init },
	{ DEV_DEBUG_ID, dev_debug_init },
	{ 0, 0}
};

/*
 * This table is auto-generated from the configuration file.
 * Used by service.c :: service_all()
 */
const DEV_FUNCTION_ENTRY dev_service_table[] PROGMEM =
{
	{ DEV_PERIOD_COUNTER_ID, dev_period_counter_service },
	{ DEV_SOLENOID_1_ID, dev_solenoid_service },
	{ DEV_SOLENOID_2_ID, dev_solenoid_service },
	{ DEV_DEBUG_ID, dev_debug_service },
	{ 0, 0}
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by dev_access.c :: access_all() for access functions specific to this device.
 * NOTE: This array has to be before the access table.
 */
const DEV_FUNCTION_ENTRY dev_period_counter_access[] PROGMEM =
{
	{ 0x01, dev_period_counter_get },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by core_utilities.c :: get_dev_cmd_numBytes() for the size of the command message.
 */
const DEV_COMMAND_SIZE dev_period_counter_cmd_size[] PROGMEM =
{
	{ 0x01, 2 },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by dev_access.c :: access_all() for access functions specific to this device.
 * NOTE: This array has to be before the access table.
 */
const DEV_FUNCTION_ENTRY dev_solenoid_1_access[] PROGMEM =
{
	{ 0x01, dev_solenoid_1_pulse },
	{ 0x02, dev_solenoid_1_toggle_swap },
	{ 0x03, dev_solenoid_1_set_pulse },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by core_utilities.c :: get_dev_cmd_numBytes() for the size of the command message.
 */
const DEV_COMMAND_SIZE dev_solenoid_1_cmd_size[] PROGMEM =
{
	{ 0x01, 2 },
	{ 0x02, 2 },
	{ 0x03, 3 },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by dev_access.c :: access_all() for access functions specific to this device.
 * NOTE: This array has to be before the access table.
 */
const DEV_FUNCTION_ENTRY dev_solenoid_2_access[] PROGMEM =
{
	{ 0x01, dev_solenoid_2_pulse },
	{ 0x02, dev_solenoid_2_toggle_swap },
	{ 0x03, dev_solenoid_2_set_pulse },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by core_utilities.c :: get_dev_cmd_numBytes() for the size of the command message.
 */
const DEV_COMMAND_SIZE dev_solenoid_2_cmd_size[] PROGMEM =
{
	{ 0x01, 2 },
	{ 0x02, 2 },
	{ 0x03, 3 },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by dev_access.c :: access_all() for access functions specific to this device.
 * NOTE: This array has to be before the access table.
 */
const DEV_FUNCTION_ENTRY dev_debug_access[] PROGMEM =
{
	{ 0x30, dev_debug_read_pin },
	{ 0x40, dev_debug_set_pin_low },
	{ 0x41, dev_debug_set_pin_high },
	{ 0x70, dev_debug_get_adc0 },
	{ 0x71, dev_debug_get_adc1 },
	{ 0x72, dev_debug_get_adc2 },
	{ 0x73, dev_debug_get_adc3 },
	{ 0x75, dev_debug_get_adc5 },
	{ 0x77, dev_debug_get_adc7 },
	{ 0x78, dev_debug_set_vref_vcc },
	{ 0x79, dev_debug_set_vref_1_1 },
	{ 0x7A, dev_debug_set_vref_ext },
	{ 0xA1, dev_debug_pulse_pin1 },
	{ 0xA2, dev_debug_pulse_pin2 },
	{ 0xA3, dev_debug_pulse_pin3 },
	{ 0xA4, dev_debug_pulse_pin4 },
	{ 0xA5, dev_debug_pulse_pin5 },
	{ 0xA6, dev_debug_pulse_pin6 },
	{ 0xA7, dev_debug_pulse_pin7 },
	{ 0xA8, dev_debug_pulse_pin8 },
	{ 0xA9, dev_debug_pulse_pin9 },
	{ 0, 0 }
};

/*
 * This table is pre-generated for the device selected and copied into the code.
 * Used by core_utilities.c :: get_dev_cmd_numBytes() for the size of the command message.
 */
const DEV_COMMAND_SIZE dev_debug_cmd_size[] PROGMEM =
{
	{ 0x30, 3 },
	{ 0x40, 3 },
	{ 0x41, 3 },
	{ 0x70, 2 },
	{ 0x71, 2 },
	{ 0x72, 2 },
	{ 0x73, 2 },
	{ 0x75, 2 },
	{ 0x77, 2 },
	{ 0x78, 2 },
	{ 0x79, 2 },
	{ 0x7A, 2 },
	{ 0xA1, 3 },
	{ 0xA2, 3 },
	{ 0xA3, 3 },
	{ 0xA4, 3 },
	{ 0xA5, 3 },
	{ 0xA6, 3 },
	{ 0xA7, 3 },
	{ 0xA8, 3 },
	{ 0xA9, 3 },
	{ 0, 0 }
};

/*
 * This table is auto-generated from the configuration file.
 * Used by access.c :: access_all()
 */
const DEV_ACCESS_ENTRY dev_access_table[] PROGMEM =
{
	{ DEV_PERIOD_COUNTER_ID, dev_period_counter_access, dev_period_counter_cmd_size },	// table to all functions supported by device period counter.
	{ DEV_SOLENOID_1_ID, dev_solenoid_1_access, dev_solenoid_1_cmd_size },	// table to all functions supported by device solenoid.
	{ DEV_SOLENOID_2_ID, dev_solenoid_2_access, dev_solenoid_2_cmd_size },	// table to all functions supported by device solenoid.
	{ DEV_DEBUG_ID, dev_debug_access, dev_debug_cmd_size },	// table to all functions supported by device debug.
	{ 0, 0 }
};
