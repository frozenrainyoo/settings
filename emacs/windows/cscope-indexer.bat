@echo off
echo Creating list of files to index ...
dir *.h *.hxx *.c *.cpp *.cxx *.java *.rb *.m *.mm /b/s > cscope.files
echo Creating list of files to index ... done
echo Indexing files ...
cscope -b
echo Indexing files ... done
