def sowToFile(argv)
    inName = argv[0]
    outName = argv[1]
    outFile = File.open(outName,'w')
    outFile.write(parseFile(inName))
    outFile.close()
    return " "
end

def patchIn(argv)
    name = argv[0]
    puts("Including #{name} ...")
    return(parseFile(name))
end

def fetchCSS(argv)
        out = ""
        argv.each{|p|
            out = out + "<link rel=\"stylesheet\" type=\"text/css\" href=#{p}>"
        }
        return(out)
end

CmdNames = [
    'sowToFile',
    'patchIn',
    'fetchCSS'
]
CmdMethods = [
    method(:sowToFile),
    method(:patchIn),
    method(:fetchCSS)
]
CmdArgc = [
    2,
    1,
    -1
]
