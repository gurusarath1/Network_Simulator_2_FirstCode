#ECEN 602
#Assignment 5


puts "\n\n----------- Network Assignment 5 -----------"

#Check input arguments
if {$argc < 2} {
	puts "\n\nFollow Format: ns <filename.tcl> <TCP version> <Case Number>"
	exit 1
}

set version [lindex $argv 0]
set testCase [lindex $argv 1]

if {$version != "VEGAS" && $version != "SACK"} {
	puts "\n\nInvalid Version (Try VEGAS or SACK)"
	exit 1
}

if {$testCase > 3 || $testCase < 1} {
	puts "\n\nInvalid Test Case (Try 1 to 3)"
	exit 1
}




#init output files
set ns [new Simulator]
set out1 [open out1.tr w]
set out2 [open out2.tr w]
set out3 [open out3.tr w]
set nf [open out.tr w]
$ns trace-all $nf
set namfile [open out.nam w]
$ns namtrace-all $namfile



#Create Nodes and set the shape and color
set R1 [$ns node]
set R2 [$ns node]
$R1 shape circle
$R2 shape circle
$R1 color black
$R2 color black
$ns duplex-link $R1 $R2 1Mb 5ms DropTail



set src1 [$ns node]
set src2 [$ns node]
$src1 color red
$src2 color red
set rcv1 [$ns node]
set rcv2 [$ns node]
$rcv1 color green
$rcv2 color green


#Get the delay value
if {$testCase == 1} {
	set delay "12.5ms"
}

if {$testCase == 2} {
	set delay "20ms"
}

if {$testCase == 3} {
	set delay "27.5ms"
}

#Create links
$ns duplex-link $src1 $R1 10Mb 5ms DropTail
$ns duplex-link $src2 $R1 10Mb $delay DropTail
$ns duplex-link $R2 $rcv1 10Mb 5ms DropTail
$ns duplex-link $R2 $rcv2 10Mb $delay DropTail


#Get the flavour of TCP
if {$version == "VEGAS"} {
	#Vegas version
	puts "Version - TCP VEGAS - Test Case - $testCase"
	set tcp1 [new Agent/TCP/Vegas]
	set tcp2 [new Agent/TCP/Vegas]
	$ns attach-agent $src1 $tcp1
	$ns attach-agent $src2 $tcp2
}

if {$version == "SACK"} {
	#SACK version
	puts "Version - TCP SACK - Test Case - $testCase"
	set tcp1 [new Agent/TCP/Sack1]
	set tcp2 [new Agent/TCP/Sack1]
	$ns attach-agent $src1 $tcp1
	$ns attach-agent $src2 $tcp2
}



set tcpSink1 [new Agent/TCPSink]
set tcpSink2 [new Agent/TCPSink]
$ns attach-agent $rcv1 $tcpSink1
$ns attach-agent $rcv2 $tcpSink2

$ns connect $tcp1 $tcpSink1
$ns connect $tcp2 $tcpSink2

$ns duplex-link-op $R1 $R2 orient right
$ns duplex-link-op $src1 $R1 orient right-down
$ns duplex-link-op $src2 $R1 orient right-up
$ns duplex-link-op $R2 $rcv1 orient right-up
$ns duplex-link-op $R2 $rcv2 orient right-down

set ftp1 [new Application/FTP]
set ftp2 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp2 attach-agent $tcp2


set sum_1 0
set sum_2 0
set i 0


#This function calculates throughput
proc throughputCalc {} {

	#puts "Calculating Throughput"

	global out1 out2 out3 sum_1 sum_2 i ns tcpSink1 tcpSink2

	set bw_1 [$tcpSink1 set bytes_]
	set bw_2 [$tcpSink2 set bytes_]


	set startTime 0.5

	set currentTime [$ns now]

	if {$currentTime == 100} {
		$tcpSink1 set bytes_ 0
		$tcpSink2 set bytes_ 0
	}

	if {$currentTime > 100 && $currentTime <= 400} {

		set throughput1 [expr $bw_1/$startTime *8/1000000]
		set throughput2 [expr $bw_2/$startTime *8/1000000]
		set sum_1 [expr $sum_1 + $throughput1]
		set sum_2 [expr $sum_2 + $throughput2]
		incr i
		set ratio [expr $throughput1/$throughput2]

		puts $out1 "$currentTime $throughput1"
		puts $out2 "$currentTime $throughput2"
		puts $out3 "$ratio"

		$tcpSink1 set bytes_ 0
		$tcpSink2 set bytes_ 0
	}


	if {$currentTime == 400.5} {

		set avg_throughput_1 [ expr $sum_1/$i]
		set avg_throughput_2 [ expr $sum_2/$i]
		puts "Average throughput for src1 : $avg_throughput_1 MBits/sec"
		puts "Average throughput for src2 : $avg_throughput_2 MBits/sec"
		set ratio [expr $avg_throughput_1/$avg_throughput_2]
		puts "Ratio of throughputs : $ratio"
	}

	$ns at [expr $currentTime + $startTime] "throughputCalc"



}


#Clean up function closes all files before exiting
proc CleanUp {} {
	global ns nf namfile
	$ns flush-trace
	close $nf
	close $namfile
	exit 0
}



#Set the sequence of operations
$ns at 0.5 "$ftp1 start"
$ns at 0.5 "$ftp2 start"
$ns at 100 "throughputCalc"
$ns at 401 "$ftp1 stop"
$ns at 401 "$ftp2 stop"
$ns at 405 "CleanUp"

#Start Execution
$ns run