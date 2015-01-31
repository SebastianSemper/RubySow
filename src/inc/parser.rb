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
        argv = ["",]
        ind = 0
        args.each_char{|c|
            if c == "[" || c==","
                argv[argc] = ""
                argc = argc + 1
            elsif c == "]"
                return argv
            else
                argv[argc-1] = argv[argc-1]+c
            end
        }
end

def parseFile(configFileName)
    outPut = " "
    File.open(configFileName,'r') do |rF_h|
        while rF_l = rF_h.gets()
            #check if line contains a RubySow command
            if rF_l.include?("$")
                #extract the command - regexes return arrays
                command = (rF_l.scan(/\$[a-zA-Z]*/)[0]).delete("$")
                arguments = splitArguments((rF_l.scan(/[\[].*[\]]/))[0])
                outPut = outPut + execCommand(command,arguments)
            else
                outPut = outPut + rF_l
            end
        end
    end
    return outPut
end
