# See the file LICENSE for redistribution information.
#
# Copyright (c) 2005, 2013 Oracle and/or its affiliates.  All rights reserved.
#
# $Id$
#
# TEST	test114
# TEST	Test database compaction with overflows.
# TEST
# TEST	Populate a database.  Remove a high proportion of entries.
# TEST	Dump and save contents.  Compact the database, dump again,
# TEST	and make sure we still have the same contents.
# TEST  Add back some entries, delete more entries (this time by
# TEST	cursor), dump, compact, and do the before/after check again.

proc test114 { method {nentries 10000} {tnum "114"} args } {
	source ./include.tcl
	global alphabet

	# Compaction is an option for btree, recno, and hash databases.
        if { [is_queue $method] == 1 || [is_heap $method] == 1 } {
		puts "Skipping compaction test$tnum for method $method."
		return
	}

	# Skip for fixed-length methods because we won't encounter 
	# overflows. 
	if { [is_fixed_length $method] == 1 } {
		puts "Skipping test$tnum for fixed-length method $method."
		return
	}

	# We run with a small page size to force overflows.  Skip
	# testing for specified page size.
	set pgindex [lsearch -exact $args "-pagesize"]
	if { $pgindex != -1 } {
		puts "Test$tnum: Skipping for specific pagesize."
		return
	}

	set args [convert_args $method $args]
	set omethod [convert_method $method]
	if  { [is_partition_callback $args] == 1 } {
		set nodump 1
	} else {
		set nodump 0
	}

	# If we are using an env, then testfile should just be the db name.
	# Otherwise it is the test directory and the name.
	set txnenv 0
	set eindex [lsearch -exact $args "-env"]
	if { $eindex == -1 } {
		set basename $testdir/test$tnum
		set env NULL
		append args " -cachesize { 0 500000 0 }"
	} else {
		set basename test$tnum
		incr eindex
		set env [lindex $args $eindex]
		set txnenv [is_txnenv $env]
		if { $txnenv == 1 } {
			append args " -auto_commit"
		}
		set testdir [get_home $env]
	}

	puts "Test$tnum: ($method $args) Database compaction with overflows."
	set t1 $testdir/t1
	set t2 $testdir/t2
	set splitopts { "" "-revsplitoff" }
	set txn ""

	if { [is_record_based $method] == 1 } {
		set checkfunc test001_recno.check
	} else {
		set checkfunc test001.check
	}

	cleanup $testdir $env
	foreach splitopt $splitopts {
		set testfile $basename.db
		if { $splitopt == "-revsplitoff" } {
			set testfile $basename.rev.db
			if { [is_record_based $method] == 1 } {
				puts "Skipping\
				    -revsplitoff option for method $method."
				continue
			}
		}
		set did [open $dict]
		if { $env != "NULL" } {
			set testdir [get_home $env]
		}

		puts "\tTest$tnum.a: Create and populate database ($splitopt)."
		set pagesize 512
		set db [eval {berkdb_open -create -pagesize $pagesize \
		    -mode 0644} $splitopt $args $omethod $testfile]
		error_check_good dbopen [is_valid_db $db] TRUE

		set count 0
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		while { [gets $did str] != -1 && $count < $nentries } {
			if { [is_record_based $method] == 1 } {
				set key [expr $count + 1]
			} else {
				set key $str
			}
			set str [repeat $alphabet 100]

			set ret [eval \
			    {$db put} $txn {$key [chop_data $method $str]}]
			error_check_good put $ret 0
			incr count

		}
		if { $txnenv == 1 } {
			error_check_good txn_commit [$t commit] 0
		}
		close $did
		error_check_good db_sync [$db sync] 0

		if { $env != "NULL" } {
			set testdir [get_home $env]
			set filename $testdir/$testfile
		} else {
			set filename $testfile
		}
		set size1 [file size $filename]
		set count1 [stat_field $db stat "Page count"]

		puts "\tTest$tnum.b: Delete most entries from database."
		set did [open $dict]
		set count [expr $nentries - 1]
		set n 57

		# Leave every nth item.  Since rrecno renumbers, we
		# delete starting at nentries and working down to 0.
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		while { [gets $did str] != -1 && $count > 0 } {
			if { [is_record_based $method] == 1 } {
				set key [expr $count + 1]
			} else {
				set key $str
			}

			if { [expr $count % $n] != 0 } {
				set ret [eval {$db del} $txn {$key}]
				error_check_good del $ret 0
			}
			incr count -1
		}
		if { $txnenv == 1 } {
			error_check_good t_commit [$t commit] 0
		}
		error_check_good db_sync [$db sync] 0

		# Now that the delete is done we ought to have a 
		# lot of pages on the free list.
		if { [is_hash $method] == 1 } { 
			set free1 [stat_field $db stat "Free pages"]
		} else {
			set free1 [stat_field $db stat "Pages on freelist"]
		}

		puts "\tTest$tnum.c: Do a dump_file on contents."
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		dump_file $db $txn $t1
		if { $txnenv == 1 } {
			error_check_good txn_commit [$t commit] 0
		}

		puts "\tTest$tnum.d: Compact and verify database."
		for {set commit 0} {$commit <= $txnenv} {incr commit} {
			if { $txnenv == 1 } {
				set t [$env txn]
				error_check_good txn [is_valid_txn $t $env] TRUE
				set txn "-txn $t"
			}
			if {[catch {eval {$db compact} $txn {-freespace}} ret] } {
				error "FAIL: db compact: $ret"
			}
			if { $txnenv == 1 } {
				if { $commit == 0 } {
					puts "\tTest$tnum.d: Aborting."
					error_check_good txn_abort [$t abort] 0
				} else {
					puts "\tTest$tnum.d: Committing."
					error_check_good txn_commit [$t commit] 0
				}
			}
			error_check_good db_sync [$db sync] 0
			error_check_good verify_dir \
			    [ verify_dir $testdir "" 0 0 $nodump] 0
		}

		set size2 [file size $filename]
		set count2 [stat_field $db stat "Page count"]
		if { [is_hash $method] == 1 } { 
			set free2 [stat_field $db stat "Free pages"]
		} else {
			set free2 [stat_field $db stat "Pages on freelist"]
		}

		# Reduction in on-disk size should be substantial.
#### We should look at the partitioned files #####
if { [is_partitioned $args] == 0 } {
		set reduction .80
		error_check_good \
		    file_size [expr [expr $size1 * $reduction] > $size2] 1
}

		# The number of free pages should be reduced
		# now that we've compacted with -freespace.
		error_check_good pages_returned [expr $free1 > $free2] 1

		# Page count should be reduced for all methods except maybe
		# record-based non-queue methods.  Even with recno, the
		# page count may not increase.
		error_check_good page_count_reduced [expr $count1 > $count2] 1

		puts "\tTest$tnum.e: Contents are the same after compaction."
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		dump_file $db $txn $t2
		if { $txnenv == 1 } {
			error_check_good txn_commit [$t commit] 0
		}

		if { [is_hash $method]  != 0 } {
			filesort $t1 $t1.sort
			filesort $t2 $t2.sort
			error_check_good filecmp [filecmp $t1.sort $t2.sort] 0
		} else {
			error_check_good filecmp [filecmp $t1 $t2] 0
		}

		puts "\tTest$tnum.f: Add more entries to database."
		# Use integers as keys instead of strings, just to mix it up
		# a little.
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		for { set i 1 } { $i < $nentries } { incr i } {
			set key $i
			set str [repeat $alphabet 100]
			set ret [eval \
			    {$db put} $txn {$key [chop_data $method $str]}]
			error_check_good put $ret 0
		}
		if { $txnenv == 1 } {
			error_check_good t_commit [$t commit] 0
		}
		error_check_good db_sync [$db sync] 0

		set size3 [file size $filename]
		set count3 [stat_field $db stat "Page count"]

		puts "\tTest$tnum.g: Remove more entries, this time by cursor."
		set count 0
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		set dbc [eval {$db cursor} $txn]

		# Leave every nth item.
		for { set dbt [$dbc get -first] } { [llength $dbt] > 0 }\
		    { set dbt [$dbc get -next] ; incr count } {
			if { [expr $count % $n] != 0 } {
				error_check_good dbc_del [$dbc del] 0
			}
		}

		error_check_good cursor_close [$dbc close] 0
		if { $txnenv == 1 } {
			error_check_good t_commit [$t commit] 0
		}
		error_check_good db_sync [$db sync] 0
		if { [is_hash $method] == 1 } { 
			set free3 [stat_field $db stat "Free pages"]
		} else {
			set free3 [stat_field $db stat "Pages on freelist"]
		}

		puts "\tTest$tnum.h: Save contents."
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		dump_file $db $txn $t1
		if { $txnenv == 1 } {
			error_check_good t_commit [$t commit] 0
		}

		puts "\tTest$tnum.i: Compact and verify database again."
		for {set commit 0} {$commit <= $txnenv} {incr commit} {
			if { $txnenv == 1 } {
				set t [$env txn]
				error_check_good txn [is_valid_txn $t $env] TRUE
				set txn "-txn $t"
			}
			if {[catch {eval {$db compact} $txn {-freespace}} ret] } {
				error "FAIL: db compact: $ret"
			}
			if { $txnenv == 1 } {
				if { $commit == 0 } {
					puts "\tTest$tnum.i: Aborting."
					error_check_good txn_abort [$t abort] 0
				} else {
					puts "\tTest$tnum.i: Committing."
					error_check_good txn_commit [$t commit] 0
				}
			}
			error_check_good db_sync [$db sync] 0
			error_check_good verify_dir \
			    [ verify_dir $testdir "" 0 0 $nodump] 0
		}

		set size4 [file size $filename]
		set count4 [stat_field $db stat "Page count"]
		if { [is_hash $method] == 1 } { 
			set free4 [stat_field $db stat "Free pages"]
		} else {
			set free4 [stat_field $db stat "Pages on freelist"]
		}

#### We should look at the partitioned files #####
if { [is_partitioned $args] == 0 } {
		error_check_good \
		    file_size [expr [expr $size3 * $reduction] > $size4] 1
}

		error_check_good pages_returned [expr $free3 > $free4] 1
		error_check_good \
		    page_count_reduced [expr $count3 > $count4] 1
		puts "\tTest$tnum.j: Contents are the same after compaction."
		if { $txnenv == 1 } {
			set t [$env txn]
			error_check_good txn [is_valid_txn $t $env] TRUE
			set txn "-txn $t"
		}
		dump_file $db $txn $t2
		if { $txnenv == 1 } {
			error_check_good t_commit [$t commit] 0
		}
		if { [is_hash $method]  != 0 } {
			filesort $t1 $t1.sort
			filesort $t2 $t2.sort
			error_check_good filecmp [filecmp $t1.sort $t2.sort] 0
		} else {
			error_check_good filecmp [filecmp $t1 $t2] 0
		}

		error_check_good db_close [$db close] 0
		close $did
	}
}
