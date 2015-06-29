/*
 * flash_table.h
 *
 * Created: 6/27/2015 7:03:09 PM
 *  Author: Chip
 */ 


#ifndef FLASH_TABLE_H_
#define FLASH_TABLE_H_


uint8_t flash_get_dev_access_id(uint8_t index);
DEV_FUNCTION_ENTRY* flash_get_dev_function_table(uint8_t index);
uint16_t* flash_get_dev_size_table(uint8_t index);


uint16_t flash_get_size_cmd(uint8_t index, DEV_COMMAND_SIZE* table);
uint8_t flash_get_size_nbytes(uint8_t index, DEV_COMMAND_SIZE* table);

uint16_t flash_get_access_cmd(uint8_t index, DEV_FUNCTION_ENTRY* table);
uint16_t flash_get_access_func(uint8_t index, DEV_FUNCTION_ENTRY* table);


#endif /* FLASH_TABLE_H_ */