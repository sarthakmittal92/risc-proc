import re
import sys

def assemble (inputFile):
        
    NONE = "none"
    ERROR = "error"
    OP_CODE = "op_code"
    REGISTER = "register_code"
    COMMA = "comma"
    VALUE = "bin/hex_value"
    VALUE_6 = "6_bit_value"
    VALUE_9 = "9_bit_value"
    VALUE_8 = "8_bit_value"
    MEMORY = "memory_address"
    BINARY = 2
    HEX = 16
    DECIMAL = 10

    instrTypes = {
        'add': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'adc': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'adz': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'adl': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'adi': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'ndu': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'ndc': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'ndz': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'lhi': (OP_CODE, VALUE, COMMA, VALUE),
        'lli': (OP_CODE, VALUE, COMMA, VALUE),
        'lw' : (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'sw' : (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'lm' : (OP_CODE, VALUE, COMMA, VALUE),
        'sm' : (OP_CODE, VALUE, COMMA, VALUE),
        'beq': (OP_CODE, VALUE, COMMA, VALUE, COMMA, VALUE),
        'jal': (OP_CODE, VALUE, COMMA, VALUE),
        'jlr': (OP_CODE, VALUE, COMMA, VALUE),
        'jri': (OP_CODE, VALUE, COMMA, VALUE),
    }
    
    permutation = {
        'add': ((1,3),(3,5)),
        'adc': ((1,3),(3,5)),
        'adz': ((1,3),(3,5)),
        'adl': ((1,3),(3,5)),
        'ndu': ((1,3),(3,5)),
        'ndz': ((1,3),(3,5)),
        'ndc': ((1,3),(3,5)),
        'adi': ((1,3),)
    }
    
    instrSet = {
        'add': ("0001", REGISTER, REGISTER, REGISTER, "000\n"),
        'adc': ("0001", REGISTER, REGISTER, REGISTER, "010\n"),
        'adz': ("0001", REGISTER, REGISTER, REGISTER, "001\n"),
        'adl': ("0001", REGISTER, REGISTER, REGISTER, "011\n"),
        'adi': ("0000", REGISTER, REGISTER, VALUE_6, "\n"),
        'ndu': ("0010", REGISTER, REGISTER, REGISTER, "000\n"),
        'ndc': ("0010", REGISTER, REGISTER, REGISTER, "010\n"),
        'ndz': ("0010", REGISTER, REGISTER, REGISTER, "001\n"),
        'lhi': ("0011", REGISTER, VALUE_9, "\n"),
        'lli': ("1111", REGISTER, VALUE_9, "\n"),
        'lw' : ("0101", REGISTER, REGISTER, VALUE_6, "\n"),
        'sw' : ("0111", REGISTER, REGISTER, VALUE_6, "\n"),
        'lm' : ("1101", REGISTER, "0", VALUE_8, "\n"),
        'sm' : ("1100", REGISTER, "0", VALUE_8, "\n"),
        'beq': ("1000", REGISTER, REGISTER, VALUE_6, "\n"),
        'jal': ("1001", REGISTER, VALUE_9, "\n"),
        'jlr': ("1010", REGISTER, REGISTER, "000000\n"),
        'jri': ("1011", REGISTER, VALUE_9, "\n"),
    }
    
    exprToType = (
        (r'^\,$', COMMA, NONE),
        (r'^0b[0-1] + $', VALUE, BINARY),
        (r'^0x[0-9a-f] + $', VALUE, HEX),
        (r'^[0-9] + $', VALUE, DECIMAL),
        (r'^r[0-7]$', VALUE, REGISTER)
    )

    def rearrange (instrs):
        for i in range(0, len(instrs)):
            if instrs[i][1] in permutation:
                swaps = permutation[instrs[i][1]]
                for swap in swaps:
                    if i + swap[0] >= len(instrs) or i + swap[1] >= len(instrs):
                        return
                    else:
                        instrs[i + swap[0]], instrs[i + swap[1]] = instrs[i + swap[1]], instrs[i + swap[0]]
                        
    def binaryToHexa (binary):
        dec = 0;
        for bit in range(len(binary)):
            if binary[bit] == "1":
                dec += int(2 ** ((len(binary) - bit - 1)))   
        return decToHexa(dec,4)
            
    def hexaToDec (inp):
        hex = "0123456789ABCDEF";
        dec = 0;
        for i in range(len(inp)):
            if not inp[i] == "0":
                dec = dec + int((16 ** ((len(inp) - i - 1))) * hex.index(inp[i]))
        return dec
        
    def decToHexa (decimal, length):
        out = []
        hex = "0123456789ABCDEF";
        for i in range(length):
            out.insert(0,hex[int(decimal % 16)])
            decimal //= 16;
        return "".join(out)
    
    def hexaToUint8 (hex):
        uint8 = []
        for i in range(0,len(hex),2):
            if i+1==len(hex):
                print("Invalid HEX String.")
                return []
            uint8.append(hexaToDec(hex[i:i+2]))
        return uint8
            
    def appendConst (binaryFormat, ptr):
        peripherals = []
        BLACKLIST = [REGISTER, VALUE_6, VALUE_8, VALUE_9, MEMORY]
        while ptr < len(binaryFormat) and binaryFormat[ptr] not in BLACKLIST:
            peripherals.append(binaryFormat[ptr])
            ptr +=  1
        return peripherals

    def conditionalBinary (instr, nextType):
        currType = DECIMAL
        value = 0
        for data in exprToType:
            regex = re.compile(data[0])
            if regex.search(instr[1]) != None:
                currType = data[2]
        if currType == BINARY:
            value = int(instr[1][2:], 2)
        elif currType == DECIMAL:
            value = int(instr[1], 10)
        elif currType == HEX:
            value = int(instr[1][2:], 16)
        elif currType == REGISTER:
            value = int(instr[1][1:], 10)
        else:
            return 0
        if nextType == REGISTER:
            if value >= 2 ** 3 or value < 0:
                print ("Register out of bounds in " + instr[1] + " of line " + str(instr[2]))
                sys.exit(0)
            return '{:03b}'.format(value)
        elif nextType == VALUE_6:
            if (value >= 2 ** 6 or value < 0):
                print ("6 bit value out of bounds in " + instr[1] + " of line " + str(instr[2]))
                sys.exit(0)
            return '{:06b}'.format(value)
        elif nextType == VALUE_8:
            if (value >= 2 ** 8 or value < 0):
                print ("8 bit value out of bounds in " + instr[1] + " of line " + str(instr[2]))
                sys.exit(0)
            return '{:08b}'.format(value)
        elif nextType == VALUE_9:
            if (value >= 2 ** 9 or value < 0):
                print ("9 bit value out of bounds in " + instr[1] + " of line " + str(instr[2]))
                sys.exit(0)
            return '{:09b}'.format(value)
        elif nextType == MEMORY:
            if (value >= 2 ** 16 or value < 0):
                print ("Memory value out of bounds in " + instr[1] + " of line " + str(instr[2]))
                sys.exit(0)
            return '{:016b}'.format(value)

    def instrToInstrType(instr=""):
        if instr == '':
            return NONE
        if instr in instrTypes:
            return OP_CODE
        else:
            for data in exprToType:
                regex = re.compile(data[0])
                if regex.search(instr) != None:
                    return data[1]
            return ERROR


    def wordToInstrs(word="", number=0):
        instrs = []
        adl_args = []
        jri_args = []
        adl_bool = False
        jri_bool = False
        sequence = word.split(",")
        for s in sequence:
            currInstrType = instrToInstrType(s)
            if currInstrType == ERROR:
                print ("instr " + s + " couldn't be identified in line " + str(number))
                sys.exit(0)
            if currInstrType != NONE:
                if currInstrType == OP_CODE:
                    if adl_args != []:
                        instrs.append((instrToInstrType('add'),'add',number))
                        instrs.append((COMMA, ",", number))
                        instrs.extend(adl_args) # rc,ra,rb
                        instrs.append((instrToInstrType('add'),'add',number))
                        instrs.append((COMMA, ",", number))
                        adl_args[2] = adl_args[0] # ra = rc
                        instrs.extend(adl_args) # rc,rc,rb
                        adl_args    = []
                    elif jri_args != []:
                        l = ['r0','r1','r2','r3','r4','r5','r6']
                        l.remove(jri_args[0][1]) # ra
                        instrs.append((instrToInstrType('lli'),'lli',number))
                        instrs.append((COMMA, ",", number))
                        instrs.append((instrToInstrType(l[-1]),l[-1],number))
                        instrs.append((COMMA, ",", number))
                        instrs.append(jri_args[2]) # imm
                        instrs.append((COMMA, ",", number))
                        instrs.append((instrToInstrType('add'),'add',number))
                        instrs.append((COMMA, ",", number))
                        instrs.append((instrToInstrType(l[-1]),l[-1],number))
                        instrs.append((COMMA, ",", number))
                        instrs.append(jri_args[0]) # ra
                        instrs.append((COMMA, ",", number))
                        instrs.append((instrToInstrType(l[-1]),l[-1],number))
                        instrs.append((COMMA, ",", number))
                        instrs.append((instrToInstrType('jlr'),'jlr',number))
                        instrs.append((COMMA, ",", number))
                        instrs.append(jri_args[0]) # ra
                        instrs.append((COMMA, ",", number))
                        instrs.append((instrToInstrType(l[-1]),l[-1],number))
                        instrs.append((COMMA, ",", number))
                        jri_args = []
                    if s == 'adl':
                        adl_bool = True
                    elif s == 'jri':
                        jri_bool = True
                    else:
                        adl_bool = False
                        jri_bool = False
                        instrs.append((currInstrType, s, number))
                        instrs.append((COMMA, ",", number))
                else:
                    if adl_bool:
                        adl_args.append((currInstrType, s, number))
                        adl_args.append((COMMA, ",", number))
                    elif jri_bool:
                        jri_args.append((currInstrType, s, number))
                        jri_args.append((COMMA, ",", number))
                    else:
                        instrs.append((currInstrType, s, number))
                        instrs.append((COMMA, ",", number))
        instrs.pop()
        return instrs

    file = inputFile
    with open(file, 'r') as f:
        instrs = []
        for number, line in enumerate(f):
            words = line.split()
            if ((not words == []) and (words[0][0] == ";")):
                continue
            for word in words:
                listOfInstrs = wordToInstrs(word.lower(), number + 1)
                instrs.extend(listOfInstrs)
    rearrange(instrs)

    nextExp = OP_CODE
    instruction = ()
    binaryFormat = ()
    ptr = 0
    instrPtr = 0
    output = ""
    
    for _, instr in enumerate(instrs):
        if instr[0] != nextExp:
            print ("Expected " +  nextExp + " but found " + instr[0] + " in " + instr[1] + " of line " + str(instr[2]))
        if instr[0] == OP_CODE:
            instruction = instrTypes[instr[1]]
            binaryFormat = instrSet[instr[1]]
            instrPtr = 1
            ptr = 1
            output += binaryFormat[0]
        elif instr[0] == VALUE:
            output += conditionalBinary(instr, binaryFormat[ptr])
            ptr += 1
        peripherals = appendConst(binaryFormat, ptr)
        for p in peripherals:
            output += p
            ptr += 1
        if instrPtr == len(instruction):
            nextExp = OP_CODE
            instrPtr = 0
        else:
            nextExp = instruction[instrPtr]
            instrPtr += 1
    
    hexOut = [binaryToHexa(i) for i in output[:len(output)-1].split("\n")]
    address = 0
    hexFile = ""
    
    while hexOut:
        if("FFFF" in hexOut):
            branch = hexOut.index("FFFF")
        else:
            branch = len(hexOut)
        line = ""
        if(branch + 1>32):
            line += decToHexa(64 / 2,2) + decToHexa(address,4) + "".join(hexOut[0:32])
            hexOut = hexOut[32:]
            address += 32;
        else:    
            line += decToHexa((branch),2) + decToHexa(address,4) + "".join(hexOut[0:branch])
            hexOut = hexOut[branch + 1:]
            if(hexOut):
                address = hexaToDec(hexOut[0])
                del hexOut[0]
        hexFile += line;
    
    hexFile += "00";
    print(len(hexFile))
    bootFile = [];
    for i in range(0, len(hexFile), 2):
        print(i," ",hexaToDec(hexFile[i:i + 2]))
        bootFile.append(hexaToDec(hexFile[i:i + 2]))
    f.close()
    return bootFile