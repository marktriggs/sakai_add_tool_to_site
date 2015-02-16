#!/bin/bash
#
# Download dependencies

sakai_url="$1"

if [ "$sakai_url" = "" ]; then
    echo "Usage: $0 <sakai url>"
    echo
    echo "E.g: $0 http://localhost:8080/"

    exit
fi


cd "`dirname "$0"`"

mkdir -p lib dist

jruby="https://s3.amazonaws.com/jruby.org/downloads/1.7.19/jruby-complete-1.7.19.jar"

if [ ! -e dist/`basename "$jruby"` ]; then
    if (which curl &>/dev/null); then
        curl "$jruby" --output dist/`basename "$jruby"`
    elif (which wget &>/dev/null); then
        wget "$jruby" --output-document dist/`basename "$jruby"`    
    else
        echo "Need either curl or wget installed"
        exit
    fi
fi

rm -rf src

# Generate SOAP client stubs
java -cp 'lib/*' org.apache.axis.wsdl.WSDL2Java "$sakai_url/sakai-axis/SakaiLogin.jws?wsdl"  -p sakai.cle -o src
java -cp 'lib/*' org.apache.axis.wsdl.WSDL2Java "$sakai_url/sakai-axis/SakaiScript.jws?wsdl" -p sakai.cle -o src

rm -rf build
mkdir -p build

javac -cp 'lib/*' -d build -sourcepath src `find src -name "*.java"`

jar cvf dist/sakai-cle-ws.jar -C build .

rm -rf build src
