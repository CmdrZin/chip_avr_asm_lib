@ECHO OFF
"D:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "C:\Data\EmbeddedSystems\I2C_Slave_Project\I2C_Slave_Code_Dev\I2C_Slave_lib\asm\labels.tmp" -fI -W+ie -C V2E -o "C:\Data\EmbeddedSystems\I2C_Slave_Project\I2C_Slave_Code_Dev\I2C_Slave_lib\asm\I2C_Slave_lib.hex" -d "C:\Data\EmbeddedSystems\I2C_Slave_Project\I2C_Slave_Code_Dev\I2C_Slave_lib\asm\I2C_Slave_lib.obj" -e "C:\Data\EmbeddedSystems\I2C_Slave_Project\I2C_Slave_Code_Dev\I2C_Slave_lib\asm\I2C_Slave_lib.eep" -m "C:\Data\EmbeddedSystems\I2C_Slave_Project\I2C_Slave_Code_Dev\I2C_Slave_lib\asm\I2C_Slave_lib.map" "C:\Data\EmbeddedSystems\I2C_Slave_Project\I2C_Slave_Code_Dev\I2C_Slave_lib\asm\src\main.asm"