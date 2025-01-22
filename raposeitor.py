import sys

if len(sys.argv) != 2:
    print("Uso: $ python3", sys.argv[0], "[programa.rap]");
    exit()

f = open(sys.argv[1], 'r')
prog = f.read().split("\n")
f.close()

r = [-1 for i in range(2048)]
t = [-2 for i in range(2048)]

def getval(op):
    if op[0]=='%' and op[1]=='r':
        return r[ int(op.split("r")[1]) ]
    elif op[0]=='%' and op[1]=='t':
        return t[ int(op.split("t")[1]) ]
    else:
        return int(op)

def atribui(rdest, val):
    if rdest[0]=='%' and rdest[1]=='r':
        r[ int(rdest.split("r")[1]) ] = val
    elif rdest[0]=='%' and rdest[1]=='t':
        t[ int(rdest.split("t")[1]) ] = val
    else:
        print("ERRO ERRO ERRO ERRO!!!11!!")

def poslabel(rotulo):
    i = 0
    while i < len(prog):
        if prog[i].split(" ")[0] == "label" and prog[i].split(" ")[1] == rotulo:
            return i
        i = i + 1
    return -1 # erro

def equal(rdest, op1, op2):
    if getval(op1) == getval(op2):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def diff(rdest, op1, op2):
    if getval(op1) != getval(op2):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def less(rdest, op1, op2):
    if getval(op1) < getval(op2):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def lesseq(rdest, op1, op2):
    if getval(op1) <= getval(op2):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def greater(rdest, op1, op2):
    if getval(op1) > getval(op2):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def greatereq(rdest, op1, op2):
    if getval(op1) >= getval(op2):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def nega(rdest, op):
    if (getval(op) == 0):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def ora(rdest, op1, op2):
    if (getval(op1) != 0 or getval(op2) != 0):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def anda(rdest, op1, op2):
    if (getval(op1) != 0 and getval(op2) != 0):
        atribui(rdest, 1)
    else:
        atribui(rdest, 0)

def imprimir(s):
    ini=0
    fim=0
    for i in range(len(s)):
        if s[i]=='"':
            ini=i+1
            break
    for j in range(ini, len(s)):
        if (s[j]=='"' and s[j-1]!='\\'):
            fim=j-1
            break
    i = ini
    while i <= fim:
        if (s[i]=='\\' and s[i+1]=='n'):
            print()
            i = i + 2
        elif (s[i]=='\\' and s[i+1]=='"'):
            print("\"", end="")
            i = i + 2
        else:
            print(s[i], end="")
            i = i + 1

pc = 0
while pc < len(prog):
    linha = prog[pc].strip().split(" ")
    while len(linha) < 4:
        linha.append("nop")
    instr = linha[0]
    rdest = linha[1].split(",")[0]
    op1 = linha[2].split(",")[0]
    op2 = linha[3].split(",")[0]

    if instr == ";" or instr == "":
        pc = pc + 1 #ignora
    elif instr == "printf":
        imprimir(prog[pc].strip());
        pc = pc + 1
    elif instr == "printv":
        print(getval(rdest),end="")
        pc = pc + 1
    elif instr == "read":
        atribui(rdest, int(input()))
        pc = pc + 1
    elif instr == "mov":
        atribui(rdest, getval(op1))
        pc = pc + 1
    elif instr == "add":
        atribui(rdest, getval(op1) + getval(op2))
        pc = pc + 1
    elif instr == "sub":
        atribui(rdest, getval(op1) - getval(op2))
        pc = pc + 1
    elif instr == "mult":
        atribui(rdest, getval(op1) * getval(op2))
        pc = pc + 1
    elif instr == "div":
        atribui(rdest, getval(op1) // getval(op2))
        pc = pc + 1
    elif instr == "mod":
        atribui(rdest, getval(op1) % getval(op2))
        pc = pc + 1
    elif instr == "not":
        nega(rdest, op1)
        pc = pc + 1
    elif instr == "or":
        ora(rdest, op1, op2)
        pc = pc + 1
    elif instr == "and":
        anda(rdest, op1, op2)
        pc = pc + 1
    elif instr == "equal":
        equal(rdest, op1, op2)
        pc = pc + 1
    elif instr == "diff":
        diff(rdest, op1, op2)
        pc = pc + 1
    elif instr == "less":
        less(rdest, op1, op2)
        pc = pc + 1
    elif instr == "lesseq":
        lesseq(rdest, op1, op2)
        pc = pc + 1
    elif instr == "greater":
        greater(rdest, op1, op2)
        pc = pc + 1
    elif instr == "greatereq":
        greatereq(rdest, op1, op2)
        pc = pc + 1
    elif instr == "load":
        atribui(rdest, r[ getval(op1.split("(")[0]) + getval(op1.split("(")[1].split(")")[0]) ])
        pc = pc + 1
    elif instr == "store":
        r[ getval(op1.split("(")[0]) + getval(op1.split("(")[1].split(")")[0]) ] = getval(rdest)
        pc = pc + 1
    elif instr == "label":
        pc = pc + 1
    elif instr == "jf":
        if getval(rdest) == 0:
            pc = poslabel(op1)
        else:
            pc = pc + 1
    elif instr == "jt":
        if getval(rdest) != 0:
            pc = poslabel(op1)
        else:
            pc = pc + 1
    elif instr == "jump":
        pc = poslabel(rdest)
    else:
        break
