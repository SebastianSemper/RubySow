#Copyright (C) 2015  Sebastian Semper

#This program is free software: you can redistribute it and/or modify it under
#the terms of the GNU General Public License as published by the Free Software
#Foundation, either version 3 of the License, or (at your option) any later
#version.

#This program is distributed in the hope that it will be useful, but WITHOUT ANY
#WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#PARTICULAR PURPOSE.  See the GNU General Public License for more details.

#You should have received a copy of the GNU General Public License along with
#this program.  If not, see <http://www.gnu.org/licenses/>

#separator of the arguments - internal!
ArgSep = "%#,#%"

#executes command[string] with arguments[Array<string>]
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
    return args.split(ArgSep)
end

def processArguments(args)
    part = args.partition(/\$[a-zA-Z]*\[/)
    if part[1].size() > 0
        out = part[0]
        args = part[1] + part[2]

        #start with the match, starts like $command[
        command = part[1]
        i = command.size()

        #add symbols as long as brackets dont match
        while command.count("[") != command.count("]")
            command += args[i]
            i += 1
        end
        #we are done and can process the command at hand
        #extract the function
        fun = command.scan(/\$[a-zA-Z]*\[/)[0].chop()[1..-1]
        #extract the arguments
        arg = command.scan(/\[.*\]/)[0].chop()[1..-1]
        #check if argument contains more commands
        if (args[i..-1].size() > 0)
            out += execCommand(fun,splitArguments(processArguments(arg))) + ArgSep + processArguments(args[(i+ArgSep.size())..-1])
        else
            out += execCommand(fun,splitArguments(processArguments(arg)))
        end
        return out
    else
        #if no command is in, we just return the arguments as they are
        return args
    end
end

#takes a line that contains at leat one command
def parseLine(line)
    #get rid of the beginning but add it to output
    part = line.partition(/\$[a-zA-Z]*\[/)
    out = part[0]

    #rest of the line
    line = part[1] + part[2]

    #start with the match, starts like $command[
    command = part[1]
    i = command.size()

    #add symbols as long as brackets dont match
    while command.count("[") != command.count("]")
        command += line[i]
        i += 1
    end

    #we are done and can process the command at hand
    #extract the function
    fun = command.scan(/\$[a-zA-Z]*\[/)[0].chop()[1..-1]
    #extract the arguments
    args = command.scan(/\[.*\]/)[0].chop()[1..-1]
    args = args.split(',').join(ArgSep)
    #puts("Processing the function #{fun} with argument(s) #{args}.")
    args = processArguments(args)
    out += execCommand(fun,splitArguments(args))

    #if there are still commands continue with the rest
    if line[i..-1].partition(/\$[a-zA-Z]*\[/)[1].size() > 0
        out += parseLine(line[i..-1])
    else
        #if not just push out the rest of the text
        out += line[i..-1]
    end
    return out
end

def parseFile(fileName)
    out = ""

    #check if file exists
    if (File.exists?(fileName))
        #open it
        fileHandle = File.open(fileName,'r')

        #go through each line
        fileHandle.each_line{|line|

            #allow out commented lines
            next if line.strip()[0] == "#"

            #check if any command is in the line
            if line.scan(/\$[a-zA-Z]*\[.*\]/).size() > 0
                out += parseLine(line)
            else
                #no command found we just write it out
                out += line
            end
        }
        return out
    else
        puts("Could not open #{fileName} for parsing! Aborting!")
        return ""
    end
end
