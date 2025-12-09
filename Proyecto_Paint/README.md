# Proyecto Paint - FPGA

Sistema de pintado usando un mouse PS/2 conectado a un Arduino que envía datos por UART a una FPGA Tang Primer 25K, la cual controla un panel LED RGB de 64x64.

## Conexiones Físicas

El camino de las conexiones físicas se presentan a continuación:

<img width="1035" height="362" alt="image" src="https://github.com/user-attachments/assets/ee028650-b43a-44d6-98da-35575289e94c" />

A continuación, se describen los pines clave para la interconexión de los tres componentes principales del sistema (Mouse PS/2, Arduino, FPGA y Panel LED).

### Conexión PS2 Mouse - ARDUINO UNO

Esta sección establece la interfaz de comunicación bidireccional entre el mouse PS/2 (utilizando el protocolo PS/2) y el microcontrolador Arduino. El Arduino leerá el movimiento y el estado de los botones del mouse. Para realizar la conexion del Mouse PS2 al arduino UNO se usó el proyecto [rucek/arduino-ps2-mouse](https://github.com/rucek/arduino-ps2-mouse)

| PS2 pin | ARDUINO pin |
| :--- | :--- |
| DATA | 5 |
| CLK | 6 |
| VCC | 5V |
| GND | GND |

### Conexión UART: ARDUINO UNO (TX) a FPGA (RX)

Esta sección define el canal de comunicación serial unidireccional por UART, utilizado para enviar los datos procesados del mouse (movimiento y botones) desde el Arduino (Transmisor) hacia el módulo UART Receptor implementado en la FPGA.

| ARDUINO UNO TX pin | FPGA RX pin |
| :---: | :---: |
| 7 | B2 |
| GND | GND |

### Conexión: FPGA a Panel LED

Esta es la interfaz de hardware donde la FPGA actúa como el controlador de video, generando las señales de tiempo y datos para mostrar la imagen de 64x64 píxeles y el cursor del "Paint".

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

Esta sección detalla el funcionamiento interno de los módulos lógicos y protocolos utilizados en el proyecto.

### 1. Protocolo PS/2 (Mouse)
El protocolo PS/2 utiliza dos líneas (Clock y Data) para la transmisión serial síncrona de datos desde el dispositivo (Mouse) hacia el host (Arduino). El host lee los datos en el flanco de bajada del reloj.

![Diagrama Protocolo PS2]((assets/Potocolo PS2_page-0001.png)
)
*Diagrama de flujo del funcionamiento del protocolo PS/2 implementado en el firmware.*

### 2. Protocolo UART (Módulo Genérico)
El módulo UART en la FPGA se encarga de deserializar los datos entrantes. Utiliza un sobremuestreo (16 veces la tasa de baudios) para detectar el bit de inicio y muestrear los datos en el centro del periodo de cada bit, garantizando la integridad de la recepción.

* **Diagrama de Flujo:** Muestra la máquina de estados de recepción (Detección de Start Bit -> Muestreo de Bits 0-7 -> Stop Bit).
* **Camino de Datos:** Ilustra los registros de desplazamiento y contadores utilizados.

| Diagrama de Flujo UART | Camino de Datos UART |
| :---: | :---: |
| ![Flujo UART](assets/Protocolo_UART_Flujo.png) | ![Data Path UART](assets/Data_Path_UART.png) |

### 3. Interfaz UART: Arduino a FPGA
Este módulo superior gestiona la recepción de paquetes completos de 3 bytes provenientes del Arduino. La máquina de estados asegura que los datos se interpreten en el orden correcto: `[Byte 1: Botones]` -> `[Byte 2: Movimiento X]` -> `[Byte 3: Movimiento Y]`.

* **Diagrama de Flujo:** Describe la FSM que espera secuencialmente los 3 bytes y valida la integridad del paquete.
* **Camino de Datos:** Muestra el buffer de 3 posiciones y cómo se asignan a las señales de salida (`btn`, `delta_x`, `delta_y`).

| Flujo Arduino-FPGA | Datapath Arduino-FPGA |
| :---: | :---: |
| ![Flujo Arduino FPGA](assets/UART_ARDUINO_FPGA.png) | ![Data Path Arduino FPGA](assets/Data_Path_UART_ARDUINO_FPGA.png) |

### 4. Controlador FPGA a Pantalla (Lógica de Pintado)
Este es el núcleo del proyecto (`PS2_TO_SCREEN`). Recibe las coordenadas del mouse, calcula la posición de memoria correspondiente en la matriz de 64x64, y actualiza el color del píxel si se detecta un clic ("Pintar"). También maneja la lógica de lectura de memoria para refrescar el panel LED continuamente.

* **Diagrama de Flujo:** Detalla el algoritmo para limitar las coordenadas (0-63), calcular la dirección de memoria (`Address = Y*64 + X`) y la lógica de escritura/lectura.
* **Camino de Datos:** Muestra los comparadores (para límites de pantalla), sumadores (para movimiento relativo) y la interfaz con la memoria de video.

| Flujo Lógica de Pantalla | Datapath Lógica de Pantalla |
| :---: | :---: |
| ![Flujo PS2 to Screen](assets/PS2_to_Screen.png) | ![Data Path PS2 to Screen](assets/Data_Path_PS2_TO_SCREEN.png) |

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
