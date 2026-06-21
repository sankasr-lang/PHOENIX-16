# Opcode table
opcode = {
    "MOVSGPR"    : 0b000000,
    "MOV"        : 0b000001,
    "ADD"        : 0b000010,
    "SUB"        : 0b000011,
    "MUL"        : 0b000100,
    "ROR"        : 0b000101,
    "RAND"       : 0b000110,
    "RXOR"       : 0b000111,
    "RXNOR"      : 0b001000,
    "RNAND"      : 0b001001,
    "RNOR"       : 0b001010,
    "RNOT"       : 0b001011,
    "STOREREG"   : 0b001101,
    "STOREDIN"   : 0b001110,
    "SENDDOUT"   : 0b001111,
    "SENDREG"    : 0b010001,
    "JUMP"       : 0b010010,
    "JCARRY"     : 0b010011,
    "JNOCARRY"   : 0b010100,
    "JSIGN"      : 0b010101,
    "JNOSIGN"    : 0b010110,
    "JZERO"      : 0b010111,
    "JNOZERO"    : 0b011000,
    "JOVERFLOW"  : 0b011001,
    "JNOOVERFLOW": 0b011010,
    "HALT"       : 0b011011,
    "SETCTRL"    : 0b011100,
    "SELECT"     : 0b011101,
    "CALL"       : 0b011110,
    "RET"        : 0b011111,
    "NOP"        : 0b100000,
    "PUSH"       : 0b100001,
    "POP"        : 0b100010,
    "SHL"        : 0b100011,
    "SHR"        : 0b100100,
    "SAR"        : 0b100101,
    "CMP"        : 0b100110,
    "INC"        : 0b101000,
    "DEC"        : 0b101001,
    "RORR"       : 0b101010,
    "ROLL"       : 0b101011,
    "CLR"        : 0b101100
}

# Register table
registers = {
    "R0":0, "R1":1, "R2":2, "R3":3,
    "R4":4, "R5":5, "R6":6, "R7":7,
    "R8":8, "R9":9, "R10":10, "R11":11,
    "R12":12, "R13":13, "R14":14, "R15":15,
    "R16":16, "R17":17, "R18":18, "R19":19,
    "R20":20, "R21":21, "R22":22, "R23":23,
    "R24":24, "R25":25, "R26":26, "R27":27,
    "R28":28, "R29":29, "R30":30, "R31":31,
}

# Instruction format table
instr_type = {
# RR or RI
"MOV":"RR/RI",

# RRR or RRI
"ADD":"RRR/RRI",
"SUB":"RRR/RRI",
"MUL":"RRR/RRI",
"ROR":"RRR/RRI",
"RAND":"RRR/RRI",
"RXOR":"RRR/RRI",
"RXNOR":"RRR/RRI",
"RNAND":"RRR/RRI",
"RNOR":"RRR/RRI",
"CMP":"RRR/RRI",

# R or RI
"RNOT":"R/RI",

# Single register
"INC":"R",
"DEC":"R",
"RORR":"R",
"ROLL":"R",
"CLR":"R",
"PUSH":"R",
"SELECT":"R",

# Register + shift amount
"SHL":"RSI",
"SHR":"RSI",
"SAR":"RSI",

# memory
"STOREDIN":"S",
"STOREREG":"RS",
"SENDDOUT":"S",
"SENDREG":"RDI",

# branches
"JUMP":"SI",
"JCARRY":"SI",
"JNOCARRY":"SI",
"JSIGN":"SI",
"JNOSIGN":"SI",
"JZERO":"SI",
"JNOZERO":"SI",
"JOVERFLOW":"SI",
"JNOOVERFLOW":"SI",
"CALL":"SI",

# special
"POP":"RD",
"MOVSGPR":"RD",

# no operand
"RET":"N",
"NOP":"N",
"HALT":"N",

# immediate only
"SETCTRL":"SI"
}

def encode_R(inst, rd, rs1, rs2):
    code = (opcode[inst] << 26) | (rd << 21) | (rs1 << 16) | (rs2 << 11)
    return f"{code:032b}"

def encode_I(inst, rd, rs1, imm):
    code = ((opcode[inst] << 26) |
            (rd << 22) |
            (rs1 << 17) |
            (imm << 1) |
            1)
    return f"{code:032b}"


with open("program.asm") as f:
    lines = f.readlines()

machine_code = []

for line in lines:

    line = line.strip()
    if line == "":
        continue

    parts = line.replace(',', ' ').split()
    inst = parts[0]
    fmt = instr_type[inst]
    if inst == "CMP":

     rs1 = registers[parts[1]]

     if parts[2].startswith('R'):
        rs2 = registers[parts[2]]
        machine_code.append(
            encode_R(inst, 0, rs1, rs2)
        )
     else:
        imm = int(parts[2])
        machine_code.append(
            encode_I(inst, 0, rs1, imm)
        )

     continue



    # ADD R1,R2,R3  or ADD R1,R2,10
    if fmt == "RRR/RRI":

        rd = registers[parts[1]]
        rs1 = registers[parts[2]]

        if parts[3].startswith('R'):
            rs2 = registers[parts[3]]
            machine_code.append(
                encode_R(inst, rd, rs1, rs2)
            )
        else:
            imm = int(parts[3])
            machine_code.append(
                encode_I(inst, rd, rs1, imm)
            )

    # MOV R1,R2 or MOV R1,10
    elif fmt == "RR/RI":

        rd = registers[parts[1]]

        if parts[2].startswith('R'):
            rs1 = registers[parts[2]]
            machine_code.append(
                encode_R(inst, rd, rs1, 0)
            )
        else:
            imm = int(parts[2])
            machine_code.append(
                encode_I(inst, rd, 0, imm)
            )
    elif fmt == "R/RI":

       rd = registers[parts[1]]

       if parts[2].startswith('R'):
         rs1 = registers[parts[2]]

         machine_code.append(
             encode_R(inst, rd, rs1, 0)
        )

       else:
        imm = int(parts[2])

        machine_code.append(
            encode_I(inst, rd, 0, imm)
        )

    # INC R5
    elif fmt == "R":

        rs1 = registers[parts[1]]

        machine_code.append(
            encode_R(inst, 0, rs1, 0)
        )

    # SHL R5,3
    elif fmt == "RSI":

        rs1 = registers[parts[1]]
        imm = int(parts[2])

        machine_code.append(
            encode_I(inst, 0, rs1, imm)
        )

    # JUMP 100
    elif fmt == "SI":

        imm = int(parts[1])

        machine_code.append(
            encode_I(inst, 0, 0, imm)
        )

    # STOREDIN 10
    elif fmt == "S":

        imm = int(parts[1])

        machine_code.append(
            encode_I(inst, 0, 0, imm)
        )

    # STOREREG R1,10
    elif fmt == "RS":

        rs1 = registers[parts[1]]
        imm = int(parts[2])

        machine_code.append(
            encode_I(inst, 0, rs1, imm)
        )

    # SENDREG R1,10
    elif fmt == "RDI":

        rd = registers[parts[1]]
        imm = int(parts[2])

        machine_code.append(
            encode_I(inst, rd, 0, imm)
        )

    # POP R5
    elif fmt == "RD":

        rd = registers[parts[1]]

        machine_code.append(
            encode_R(inst, rd, 0, 0)
        )

    # HALT, RET, NOP
    elif fmt == "N":

        code = opcode[inst] << 26

        machine_code.append(
            f"{code:032b}"
        )

with open("inst_data.mem","w") as f:
    for code in machine_code:
        f.write(code+"\n")