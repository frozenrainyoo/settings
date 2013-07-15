# set disassembly-flavor intel
set print pretty on

define pr
  if $argc == 1
  	print (int)[$arg0 retainCount]
  end
  if $argc == 2
  	print (int)[$arg0 $arg1 retainCount]
  end
  if $argc == 3
  	print (int)[$arg0 $arg1 $arg2 retainCount]
  end
  if $argc == 4
  	print (int)[$arg0 $arg1 $arg2 $arg3 retainCount]
  end
  if $argc == 5
  	print (int)[$arg0 $arg1 $arg2 $arg3 $arg4 retainCount]
  end
end

document pr
Ask an objective-C object to print its retainCount
end

define prpv
  if $argc == 1
	set $view = $arg0
	while $view != 0
	  po $view
	  set $view = [$view superview]
	end
  end
end

document prpv
Ask an UIView object to print its parent view stack
end

# define bpsave
#   shell rm -f ~/.gdb-breakpoints.log
#   set logging file ~/.gdb-breakpoints.log
#   set logging on
#   info break
#   set logging off
#   # reformat on-the-fly to a valid gdb command file
#   if $argc == 1
# 	shell perl -ne 'print "break $1\n" if /^\d+.+?(\S+)$/g' ~/.gdb-breakpoints.log > $arg0
#   else
# 	shell perl -ne 'print "break $1\n" if /^\d+.+?(\S+)$/g' ~/.gdb-breakpoints.log > ~/.gdb-breakpoints
#   end
# end

define bpsave
  if $argc == 1
	save breakpoints $arg0
  else
	save breakpoints ~/.gdb-breakpoints
  end
end

document bpsave
store actual breakpoints
end

define bprestore
  if $argc == 1
	source $arg0
  else
	source ~/.gdb-breakpoints
  end
end


document bprestore
restore breakpoints saved by bpsave
end
