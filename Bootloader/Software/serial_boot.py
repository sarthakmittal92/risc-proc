# serial docs
# https://buildmedia.readthedocs.org/media/pdf/pyserial/latest/pyserial.pdf

import serial
import serial.tools.list_ports
import assembler

ports = serial.tools.list_ports.comports();

if (len(ports) == 0):
    raise Exception("No COM Ports Found. Ensure that a device is connected!")
print("Available COM Ports:\nIndex\tPort\n");

for i in range(len(ports)):
    print(i,"\t",ports[i],"\n");

index = input("Select the port you wish to use (enter the index): ")
index = int(index)

if ((index < 0) or (index >= len(ports))):
    raise Exception("Invalid choice of COM Port");

dump_port = serial.Serial(ports[index][0],9600,8,serial.PARITY_NONE,serial.STOPBITS_TWO)
print("Successfully opened specified COM Port containing ",ports[index][1])

file_name = input("Enter assembly file name: ");
data = assembler.assemble(file_name)

for i in data:
    dump_port.write(bytes([i]))
dump_port.close()