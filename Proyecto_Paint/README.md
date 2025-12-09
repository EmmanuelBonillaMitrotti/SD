# Proyecto Paint - FPGA

Sistema de pintado usando un mouse PS/2 conectado a un Arduino que envía datos por UART a una FPGA Tang Primer 25K, la cual controla un panel LED RGB de 64x64.

##Conexiones Físicas

El camino de las conexiones físicas se presentan a continuación:

<img width="1035" height="362" alt="image" src="https://github.com/user-attachments/assets/ee028650-b43a-44d6-98da-35575289e94c" />

Las pines de conexión para cada parte se presentan en las siguiente tablas:

### Conexión PS2 Mouse - ARDUINO UNO

| PS2 pin | ARDUINO pin |
| :--- | :--- |
| DATA | 5 |
| CLK | 6 |
| VCC | 5V |
| GND | GND |

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
