def execCommand(command, arguments)
    index = CmdNames.find_index(command)
    if index == nil
        puts("The command #{command} is not implemented (yet).")
        return "<!--You tried to execute #{command} here. Command not found!-->\n"
    else
        if CmdArgc[index] != arguments.size() && CmdArgc[index] > -1
            puts("Wrong number of arguments for #{CmdNames[index]}.\n  I expected #{CmdArgc[index] } but got #{arguments.size()} instead.")
        else
            return CmdMethods[index].call(arguments)
        end
    end
end

def splitArguments(args)
        argc = 0
        argv = []

        #count open rect brackets to use whole string
        openBrackets = 0
        args.each_char{|c|
            if c == "["
                openBrackets += 1
            end
            if c == "]"
                openBrackets -= 1
                if openBrackets == 0
                    return argv
                end
            end

            #collect only arguments of first order
            if (c == "[" || c == ",") && openBrackets == 1
                argv.insert(-1,"")
                argc += 1
            else
                argv[argc-1] += c
            end
        }
        if openBrackets != 0
            puts("Syntax error!")
            return []
        end
end

def processArguments(args)
    out = []
    args.each{|a|
        if a.include?("$")
            command = (a.scan(/\$[a-zA-Z]*/)[0]).delete("$")
            arguments = splitArguments((a.scan(/[\[].*[\]]/))[0])
            arguments = processArguments(arguments)
            res = execCommand(command,arguments)
            out.concat(res)
        else
            out.insert(-1,a)
        end
    }
    puts(out)
    return out
end

def parseFile(configFileName)
    outPut = " "
    File.open(configFileName,'r') do |rF_h|
        while rF_l = rF_h.gets()
            #check if line contains a RubySow command
            if rF_l.include?("$")
                #extract the command - regexes return arrays
                command = (rF_l.scan(/\$[a-zA-Z]*/)[0]).delete("$")
                puts(command)
                arguments = splitArguments((rF_l.scan(/[\[].*[\]]/))[0])
                arguments = processArguments(arguments)
                outPut = outPut + execCommand(command,arguments)

            else
                outPut = outPut + rF_l
            end
        end
    end
    return outPut
end
