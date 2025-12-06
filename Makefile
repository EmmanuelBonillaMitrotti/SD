# Makefile para Mouse UART Receiver - Tang Primer 25K
# Basado en el Makefile de digital_UN_reference

TARGET = mouse_uart_top
TOP    = mouse_uart_top

# Archivos fuente Verilog
VERILOG_FILES = mouse_uart_top.v \
                mouse_uart_receiver.v \
                uart.v

# Archivo de constraints
CST_FILE = mouse_uart.cst

# Configuración del dispositivo
GOWIN_BOARD = primer_25k

ifeq ($(GOWIN_BOARD),nano_20k)
    DEVICE = GW2AR-LV18QN88C8/I7
    FAMILY = GW2AR-18C
else ifeq ($(GOWIN_BOARD),primer_25k)
    DEVICE = GW5A-LV25MG121NC1/I0
    FAMILY = GW5A-25A
else
    $(error GOWIN_BOARD=$(GOWIN_BOARD) no válido. Usa: nano_20k o primer_25k)
endif

# Script TCL generado automáticamente
TCL_SCRIPT = auto_generated.tcl

#==============================================================================
# Targets principales
#==============================================================================

.PHONY: all build program clean help del_tcl_script clean_gowin

all: configure_tang_primer_25k

#==============================================================================
# Generación del script TCL
#==============================================================================

del_tcl_script:
	rm -rf $(TCL_SCRIPT)

$(TCL_SCRIPT): del_tcl_script
	@echo "# Script TCL generado automáticamente desde Makefile" > $@
	@echo "# Fecha: $$(date)" >> $@
	@echo "" >> $@
	@echo "# Configurar dispositivo" >> $@
	@echo "set_device -name $(FAMILY) $(DEVICE)" >> $@
	@echo "" >> $@
	@echo "# Agregar archivo de constraints" >> $@
	@echo "add_file $(CST_FILE)" >> $@
	@echo "" >> $@
	@echo "# Agregar archivos fuente Verilog" >> $@
	@for file in $(VERILOG_FILES); do \
		echo "add_file -type verilog $$file" >> $@; \
	done
	@echo "" >> $@
	@echo "# Configurar opciones del proyecto" >> $@
	@echo "set_option -top_module $(TOP)" >> $@
	@echo "set_option -use_mspi_as_gpio 1" >> $@
ifeq ($(GOWIN_BOARD),nano_20k)
	@echo "set_option -use_sspi_as_gpio 1" >> $@
else ifeq ($(GOWIN_BOARD),primer_25k)
	@echo "set_option -use_i2c_as_gpio 1" >> $@
endif
	@echo "set_option -use_ready_as_gpio 1" >> $@
	@echo "set_option -use_done_as_gpio 1" >> $@
ifeq ($(GOWIN_BOARD),primer_25k)
	@echo "set_option -use_cpu_as_gpio 1" >> $@
endif
	@echo "set_option -rw_check_on_ram 1" >> $@
	@echo "run all" >> $@
	@echo "Script TCL generado: $@"

#==============================================================================
# Targets para Tang Primer 25K
#==============================================================================

configure_tang_primer_25k: clean_gowin $(TCL_SCRIPT)
	gw_sh $(TCL_SCRIPT)
	openFPGALoader --cable ft2232 --bitstream ./impl/pnr/project.fs

# Solo sintetizar (sin programar)
build: clean_gowin $(TCL_SCRIPT)
	gw_sh $(TCL_SCRIPT)
	@echo ""
	@echo "========================================="
	@echo "  Build completado!"
	@echo "  Bitstream: impl/pnr/project.fs"
	@echo "========================================="

# Programar en Flash (persistente)
program_flash: build
	openFPGALoader --cable ft2232 --bitstream ./impl/pnr/project.fs --write-flash

#==============================================================================
# Targets para Tang Nano 20K
#==============================================================================

configure_tang_nano_20k: clean_gowin $(TCL_SCRIPT)
	gw_sh $(TCL_SCRIPT)
	openFPGALoader --cable ft2232 --bitstream ./impl/pnr/project.fs

#==============================================================================
# Limpieza
#==============================================================================

clean_gowin:
	rm -rf impl

clean: clean_gowin
	rm -rf $(TCL_SCRIPT) *.log *.rpt *.json

#==============================================================================
# Ayuda
#==============================================================================

help:
	@echo ""
	@echo "=== Mouse UART Receiver - Makefile ==="
	@echo ""
	@echo "Uso:"
	@echo "  make GOWIN_BOARD=primer_25k configure_tang_primer_25k"
	@echo "  make GOWIN_BOARD=nano_20k configure_tang_nano_20k"
	@echo ""
	@echo "Targets disponibles:"
	@echo "  make configure_tang_primer_25k - Build y programar Tang Primer 25K"
	@echo "  make configure_tang_nano_20k   - Build y programar Tang Nano 20K"
	@echo "  make build                     - Solo sintetizar (sin programar)"
	@echo "  make program_flash             - Programar en Flash (persistente)"
	@echo "  make clean                     - Limpiar archivos generados"
	@echo "  make help                      - Mostrar esta ayuda"
	@echo ""
