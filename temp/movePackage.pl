#!/usr/bin/perl
# This file created by cvte_zxl to package images.
use File::Copy;
use File::Path;
use File::Find;
use Cwd;
#use strict;

my $cur_dir = getcwd;
$ini = "${cur_dir}/makeMtk.ini";
$project = "";
$build_mode = "error"; #added by cvte_zxl

print "********************************************\n";
print "Package Images\n";
print "********************************************\n";

if (-e $ini) {
	open (FILE_HANDLE, "<$ini") or die "cannot open $ini\n";
	while (<FILE_HANDLE>) {
		if (/^(\S+)\s*=\s*(\S+)/) {
			if ($1 eq "project") {
				$project = $2;
			}
#added by cvte_zxl
			elsif ($1 eq "build_mode") {
				$build_mode = $2;
			}
#end by cvte_zxl
		}
	}
	close FILE_HANDLE;
	$project = lc($project);
	print "This project is $project\n";
}
else
{
	print "Please make project first!"
}

if ($project ne "") {
#	$preloader_bin = "out/target/product/$project/preloader_$project.bin";
#	$MBR = "out/target/product/$project/MBR";
#	$EBR1 = "out/target/product/$project/EBR1";
#	$EBR2 = "out/target/product/$project/EBR2";
#	$lk_bin = "out/target/product/$project/lk.bin";
    ($sec,$min,$hour,$day,$mon,$year,$weekday,$yeardate,$savinglightday) = (localtime(time));
    $sec = ($sec < 10)? "0$sec":$sec;
    $min = ($min < 10)? "0$min":$min;
    $hour = ($hour < 10)? "0$hour":$hour;
    $day = ($day < 10)? "0$day":$day;
    $mon = ($mon < 9)? "0".($mon+1):($mon+1);
    $year += 1900;
    if ($ARGV[0] ne "") {
	    $destDir = $ARGV[0];
    } else  {
	    $destDir = "dirImgPackage/${project}_${build_mode}_${year}-${mon}-${day}"; #modified by cvte_zxl, change destDir
    }
	$outDir = "${cur_dir}/out/target/product/$project";
	$scatter = "MT6582_Android_scatter.txt";

	if (!-d $destDir) {
		mkpath ("$destDir", 0, 0777) || die "Cannot mkpath $destDir";
		print "mkpath $destDir\n";
	}
	#copy scatter file
	if (-e "$outDir/$scatter") {
		print "copy $outDir/$scatter\n";
		copy ("$outDir/$scatter", "$destDir/$scatter") || die "Cannot copy file : $outDir/$scatter\n";
	}
	#copy images
	open (FILE_HANDLE, "<$outDir/$scatter") or die "Cannot open $outDir/$scatter!\n";
	while (<FILE_HANDLE>) {
		if (/file_name: (\S+)/) {
			if (-e "$outDir/$1") {
				print "copy $outDir/$1\n";
				copy ("$outDir/$1", "$destDir/$1") || die "Cannot copy file : $1\n";
			}
		}
	}

	$project_config = "${cur_dir}/out/target/product/$project/obj/CUSTGEN/config/ProjectConfig.mk"; #modified by cvte_zxl, change ProjectConfigt.mk path
	open (FILE_HANDLE, "<$project_config") or die "cannot open $project_config\n";
	while (<FILE_HANDLE>) {
        if (/MTK_PLATFORM\s*=\s*(\S+)\s*/) {
            $MTK_PLATFORM=$1;
        }
        if (/MTK_CHIP_VER\s*=\s*(\S+)\s*/) {
            $MTK_CHIP_VER=$1;
        }
        if (/MTK_BRANCH\s*=\s*(\S+)\s*/) {
            $MTK_BRANCH=$1;
        }
        if (/MTK_WEEK_NO\s*=\s*(\S+)\s*/) {
            $MTK_WEEK_NO=$1;
        }
        if (/MTK_TB_WIFI_3G_MODE\s*=\s*(\S+)/) {
            $MTK_TB_WIFI_3G_MODE=$1;
        }
	}
    if ("WIFI_ONLY" ne $MTK_TB_WIFI_3G_MODE) {
        $MTK_CGEN_AP_Editor_DB_File = "${cur_dir}/out/target/product/$project/obj/CODEGEN/cgen/APDB_${MTK_PLATFORM}_${MTK_CHIP_VER}_${MTK_BRANCH}_${MTK_WEEK_NO}";
        print "copy $MTK_CGEN_AP_Editor_DB_File\n";
        copy ("$MTK_CGEN_AP_Editor_DB_File", "$destDir") || die "Cannot copy file : $MTK_CGEN_AP_Editor_DB_File\n";

        $MTK_MODEM_SRC_MDDB_DIR = "${cur_dir}/out/target/product/$project/obj/CUSTGEN/custom/modem/";
        opendir(DIR,"$MTK_MODEM_SRC_MDDB_DIR"|| die "can't open this $MTK_MODEM_SRC_MDDB_DIR");
        local @files =readdir(DIR);
        closedir(DIR);
        for $file (@files){
            next if($file=~m/\.$/ || $file =~m/\.\.$/);
            if ($file =~/^BPLGUInfoCustomAppSrcP.*/i){
                print "copy $MTK_MODEM_SRC_MDDB_DIR\/$file\n";
                copy ("$MTK_MODEM_SRC_MDDB_DIR\/$file", "$destDir") || die "Cannot copy file : $MTK_MODEM_SRC_MDDB_DIR\/$file\n";
            }
        }
    }
    # added by cvte_zxl
    else {
        $MTK_CGEN_AP_Editor_DB_File = "${cur_dir}/out/target/product/$project/obj/CODEGEN/cgen/APDB_${MTK_PLATFORM}_${MTK_CHIP_VER}_${MTK_BRANCH}_${MTK_WEEK_NO}";
        print "copy $MTK_CGEN_AP_Editor_DB_File\n";
        copy ("$MTK_CGEN_AP_Editor_DB_File", "$destDir") || die "Cannot copy file : $MTK_CGEN_AP_Editor_DB_File\n";
    }
    # end by cvte_zxl
}

print "********************************************\n";
print "Copy images finish!\n";
print "********************************************\n";
