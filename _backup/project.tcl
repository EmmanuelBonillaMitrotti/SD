# Script TCL generado automáticamente
# Target: mouse_uart_top

# Configurar dispositivo
set_device -name GW5A-25A GW5A-LV25MG121NC1/I0

# Agregar archivo de constraints
add_file mouse_uart.cst

# Agregar archivos fuente Verilog
add_file -type verilog mouse_uart_top.v
add_file -type verilog mouse_uart_receiver.v
add_file -type verilog uart.v

# Configurar opciones
set_option -top_module mouse_uart_top
set_option -use_mspi_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_cpu_as_gpio 1
set_option -rw_check_on_ram 1

# Ejecutar síntesis, place & route
run all
