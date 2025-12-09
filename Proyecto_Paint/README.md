# Proyecto Paint - FPGA

Sistema de pintado usando un mouse PS/2 conectado a un Arduino que envía datos por UART a una FPGA Tang Primer 25K, la cual controla un panel LED RGB de 64x64.

## Conexiones Físicas

El camino de las conexiones físicas se presentan a continuación:

<img width="1035" height="362" alt="image" src="https://github.com/user-attachments/assets/ee028650-b43a-44d6-98da-35575289e94c" />

Las pines de conexión para cada parte se presentan en las siguiente tablas:

### Conexión PS2 Mouse - ARDUINO UNO

Esta sección establece la interfaz de comunicación bidireccional entre el mouse PS/2 (utilizando el protocolo PS/2) y el microcontrolador Arduino. El Arduino leerá el movimiento y el estado de los botones del mouse. Para esto se usó el proyecto [rucek/arduino-ps2-mouse](https://github.com/rucek/arduino-ps2-mouse) |

| PS2 pin | ARDUINO pin |
| :--- | :--- |
| DATA | 5 |
| CLK | 6 |
| VCC | 5V |
| GND | GND |

### Conexión UART: ARDUINO UNO (TX) a FPGA (RX)

| ARDUINO UNO TX pin | FPGA RX pin |
| :---: | :---: |
| 7 | B2 |
| GND | GND |

### Conexión: FPGA a Panel LED

| FPGA Pin | Panel LED Pin | Descripción |
| :---: | :---: | :--- |
| G10 | R0 | Fila 0 - Rojo |
| G11 | G0 | Fila 0 - Verde |
| D10 | B0 | Fila 0 - Azul |
| B10 | R1 | Fila 1 - Rojo |
| B11 | G1 | Fila 1 - Verde |
| C10 | B1 | Fila 1 - Azul |
| A10 | A | Dirección Fila A (Fila Select) |
| A11 | B | Dirección Fila B (Fila Select) |
| E10 | C | Dirección Fila C (Fila Select) |
| E11 | D | Dirección Fila D (Fila Select) |
| C11 | E | Dirección Fila E (Fila Select) |
| L11 | CLK | Señal de Reloj (Shift Clock) |
| K11 | LATCH | Señal Latch (Strobe) |
| K5 | OE | Output Enable (Control de Brillo) |
| GND | GND | Tierra |
| GND | N | (GND o Pin sin uso) |


## Estructura

```
Proyecto_Paint/
├── main/           # Código Verilog para la FPGA
├── arduino/        # Firmware del Arduino
└── README.md
```

## Cómo usar

1. Programar el Arduino con `arduino/mouse_uart.ino`
2. Sintetizar y programar la FPGA con los archivos en `main/`
3. Conectar:
   - Mouse PS/2 al Arduino (CLK=pin6, DATA=pin5)
   - Arduino TX (pin7) al UART RX de la FPGA (pin B2)
   - Panel LED a los pines definidos en `constraints/tang_primer_25k.cst`

## Funcionamiento

- El cursor se mueve siguiendo el mouse
- Click izquierdo: pinta en rojo
- El panel muestra una imagen de fondo cargada desde archivos .hex
