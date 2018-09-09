@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S "%0" %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
#below code handles inappropriate buffering hence optimises realtime STDOUT prints.
$| = 1;
#!perl
#line 14

#===========================================================================================
# DATE		MAINTENANCES
#===========================================================================================
# 15/12/06	- Better detection of procedure (there is no always a space before the word
#						- We must distinguish a SQL SELECT from a case SELECT (level calculation)
#						- It is possible to have a DO without an END. It is terminated by a ';'.
#						  We can not distinguish them so we generate an error.
#						- We can find a keyword in a literal. So literal are managed as comment.
#						- An embedded comment can end on the same line than a single line comment
#						  We can not managed this.
#-------------------------------------------------------------------------------------------
# 04/05/07	- Pattern matching must be case insensitive (ex: $MyLine =~ /BLABLA/i )
#-------------------------------------------------------------------------------------------
# 11/05/07	- Add a new function to separate the PLI and PLC files into the output dir.
#-------------------------------------------------------------------------------------------
# 29/06/07	- Take into account short comment such as /**/
#						- Take into account $START statement as a PROC statement
#						- I found a SELECT in a line containing several literals
#-------------------------------------------------------------------------------------------
# 25/09/08	- Adding the pipe (|) character to the list of characters that can be found
#						  in a comment.
#-------------------------------------------------------------------------------------------
# 29/09/08	- Adding another character in the comment detection regex. It would be interesting to 
#			  review the comment detection function.
#			- Replacing statements "system(mkdir $MySubDirPL[IC]);" by "mkdir ($MySubDirPL[IC]);"
#			  in order to avoid echos on the console.
#===========================================================================================
# 23/07/13	-  Duplicate files are getting checked and marked as Unchanged accordingly. 
#			-  Checking the files without extension for Added/Removed condition.
#===========================================================================================
# 05/08/13	- Issue Fix - File Count difference in source and in App_Compare   
#===========================================================================================
# 05/09/13	- Enhancement - add DB artifact detection functionality
#===========================================================================================
# 05/10/25	- Enhancement - cloc functionality to add comment lines,code lines and blank lines
#===========================================================================================

## Test of debug mode
if (@ARGV >= 1 && $ARGV[0] eq "DEBUG")
{
	$Debug = 1;
	shift(@ARGV);
}
else
{ $Debug = 0; }

## Program name and description
my $progName = "CAST Source Compare V1.0";
my $progDesc = "CAST Source Compare Pre-processor";

## Test the command line
my $MySyntax = "Syntax:\n$progName\n\t<source path>\n\t<target path>\n\t<report file>\n\t<Clean Margins (0=No, 1=Yes)>\n\t<Force Main procedure (0=No, 1=Yes)>\n\t<Separate Output Files (0=No, 1=Yes)>";

#standard parameters
$loggerFrequency=100; #prints a message after <n> number of files processed

$isATT = "False";
#my $clocexename = "I:\\TEMP\\LKS\\working_SOURCE\\CLOC\\cloc-1.58.exe";
#my $clocResultFile = "I:\\TEMP\\LKS\\working_SOURCE\\CLOC\\results.txt";
#my $clocResultFileV1 = "I:\\TEMP\\LKS\\working_SOURCE\\CLOC\\resultsV1.txt";

die( "\nError with parameters.\n$MySyntax\n" ) unless (  @ARGV == 13 );

## Input parameters
$Version2_Path			= $ARGV[0];
$Version1_Path			= $ARGV[1];
$Report_FullFileName	= $ARGV[2];
$Results_FullFileName	= $ARGV[3];
$App_Version			= $ARGV[4];
$App_Name				= $ARGV[5];
$User					= $ARGV[6];
$CLOCEXE				= $ARGV[7];
$CLOCRESULTS 			= $ARGV[8];

# ADDED VERSION FOR DATABASE TO REFLECT WHAT DATABASE EXTRACT IS USED
$AIPVersionDB			= $ARGV[9];
$ClientDBSetting 		= $ARGV[10];
$Version2_DBPath		= $ARGV[11];
$Version1_DBPath		= $ARGV[12];

# TEMP SETTING
#$AIPVersionDB 			= 'V73';
#$ClientDBSetting 		= 'nonATT';
#$Version1_DBPath		= 'C:\\CAST_AUTOMATION\\R\\US\\VOLTAGE\\SOURCE_ANALYZED\\DB\\V0';
#$Version2_DBPath		= 'C:\\CAST_AUTOMATION\\S\\DB\\VOLTAGE';




####################################################################################################

## Write the beginning banner on the screen
&Header;

## Openning the report file
die( "Unable to create file '$Report_FullFileName'\n" )
	unless( open(REPORT_OUT_FILE,">$Report_FullFileName") );


## Global variables
@V1Artifacts = ();
@V2Artifacts = ();
#@V1LOCDetails = ();
@V2LOCDetails = ();


## Files processing
&ComputeFiles;
&Splitter($Results_FullFileName);
## Close the report file
close(REPORT_OUT_FILE);


## Write the end banner on the screen
&Footer;

####################################################################################################
####################################################################################################

sub Header
{
	print "\n";
	print "==================================================\n";
	print " $progName\n";
	print "==================================================\n";
	print "    - Source directory : $Source_Path\n";
	print "    - Target directory : $Target_Path\n";
	print "    - Report file      : $Report_FullFileName\n";
	print "==================================================\n";
	print "\n";
}

####################################################################################################

sub ComputeFiles
{
	
	# Instantiate common variables....
	my @InstanceBody = ();
	my $Full_Record_report ="";
	
	my $V1_TOTAL_LOC = 0;
	my $V2_TOTAL_LOC = 0;
	

	# Input files list
	@V2files = ();
	&BuildFileList($Version2_Path, ".*", \@V2files, 1 );
	
	my $V2_NumberJSP = grep(/[a-zA-Z0-9_]+[\.]jsp/i, @V2files);
	&REPORT( 1,"Version 2: Number of JSP = '$V2_NumberJSP' total" );
	
	my $V2_NumberJava = grep(/[a-zA-Z0-9_]+[\.]java/i, @V2files);
	&REPORT( 1,"Version 2: Number of Java = '$V2_NumberJava' total" );
	
	
	my $V2_NumberXML = grep(/[a-zA-Z0-9_]+[\.]xml/i, @V2files);
	&REPORT( 1,"Version 2: Number of XML = '$V2_NumberXML' total" );
	
	
	my $V2_NumberHTML = grep(/[a-zA-Z0-9_]+[\.]html?/i, @V2files);
	&REPORT( 1,"Version 2: Number of Java = '$V2_NumberHTML' total" );
	
	my $V2_NumberJS = grep(/[a-zA-Z0-9_]+[\.]js/i, @V2files);
	&REPORT( 1,"Version 2: Number of JS files = '$V2_NumberJS' total" );
	
	my $V2_NumberJAR = grep(/[a-zA-Z0-9_]+[\.]jar/i, @V2files);
	&REPORT( 1,"Version 2: Number of JAR files = '$V2_NumberJAR' total" );
	
	my $V2_NumberUAX = grep(/[a-zA-Z0-9_]+[\.]uax/i, @V2files);
	&REPORT( 1,"Version 2: Number of UAX = '$V2_NumberUAX' total" );
	
	my $V2_NumberUAXDIR = grep(/[a-zA-Z0-9_]+[\.]uaxdirectory/i, @V2files);
	&REPORT( 1,"Version 2: Number of UAX Directory = '$V2_NumberUAXDIR' total" );
	
	

	@V1files = ();
	&BuildFileList($Version1_Path, ".*", \@V1files, 1 );
	
	my $V1_NumberJSP = grep(/[a-zA-Z0-9_]+[\.]jsp/i, @V1files);
	&REPORT( 1,"Version 1: Number of JSP = '$V1_NumberJSP' total" );
	
	my $V1_NumberJava = grep(/[a-zA-Z0-9_]+[\.]java/i, @V1files);
	&REPORT( 1,"Version 1: Number of Java = '$V1_NumberJava' total" );
	
	
	my $V1_NumberXML = grep(/[a-zA-Z0-9_]+[\.]xml/i, @V1files);
	&REPORT( 1,"Version 1: Number of XML = '$V1_NumberXML' total" );
	
	
	my $V1_NumberHTML = grep(/[a-zA-Z0-9_]+[\.]html?/i, @V1files);
	&REPORT( 1,"Version 1: Number of Java = '$V1_NumberHTML' total" );
	
	my $V1_NumberJS = grep(/[a-zA-Z0-9_]+[\.]js/i, @V1files);
	&REPORT( 1,"Version 1: Number of JS files = '$V1_NumberJS' total" );
	
	my $V1_NumberJAR = grep(/[a-zA-Z0-9_]+[\.]jar/i, @V1files);
	&REPORT( 1,"Version 1: Number of JAR files = '$V1_NumberJAR' total" );
	
	my $V1_NumberUAX = grep(/[a-zA-Z0-9_]+[\.]uax/i, @V1files);
	&REPORT( 1,"Version 1: Number of UAX = '$V1_NumberUAX' total" );
	
	my $V1_NumberUAXDIR = grep(/[a-zA-Z0-9_]+[\.]uaxdirectory/i, @V1files);
	&REPORT( 1,"Version 1: Number of UAX Directory = '$V1_NumberUAXDIR' total" );
	
	@V2DBfiles = ();
	@V1DBfiles = ();
	
	if ($ClientDBSetting eq 'ATT') 
	{
		
		#ATT SPECIFIC CHANGES
		#$Version2_DBPath 	=~  s/Sources\\/Sources\\DB\\/g;
		#$SOURCE_ANALYZED	= "SOURCE_ANALYZED";
		#$DB_ANALYZED		= "DB_ANALYZED";
		#$Version1_DBPath	=~ s/\\/\\\\/g;
		
		#$Version1_DBPath	=~  s/$SOURCE_ANALYZED/$DB_ANALYZED/g;	
		#$Version1_DBPath	=~ s/\\\\/\\/g;
		
		# Input DB files list#
		&BuildFileList($Version2_DBPath, ".*", \@V2DBfiles, 1 );
		&BuildFileList($Version1_DBPath, ".*", \@V1DBfiles, 1 );
	}
	else
	{
		$Version2_DBPath		= "NON_ATT";
		$Version1_DBPath		= "NON_ATT";

	}
	
	&REPORT("Content V2 Database files '@V2DBfiles'" );
	&REPORT("Content V1 Database files '@V1DBfiles'" );
	
	&REPORT( "$progDesc\n\nBeginning of process..." );


	## Open target file
	die( "Unable to create  file '$Results_FullFileName'\n" )
			unless( open( TARGET_OUT_FILE,">$Results_FullFileName" ) );
		
	#$Full_Record_report = "APP_VERSION".", "."FILE_FULLNAME".","."APP_NAME".","."V1_Path".",".","."V2_Path".","."FILE_NAME".", "."STATUS".", "."STATUS".", "."LoC V2".", "."LoC V1";



	print TARGET_OUT_FILE "$Full_Record_report\n";	
	
		
	my $MyFileCounter = @V2files + 0;
	my $MyMaxFileCounter = $MyFileCounter;

	&ReadLOCbyCloc($Version2_Path);
	
	#$Version2_DBPath		= "NON_ATT";
	#&BuildFileList($Version2_DBPath, ".*", \@V2DBfiles, 1 );
	#&BuildFileList($Version1_DBPath, ".*", \@V1DBfiles, 1 );
	
	

	&REPORT("ComputeFiles Begin: **time= ".(localtime));
	print "The files not read by CLOC and size greater than 100 MB will be flagged -1 in APP_Compare Table \n List of files not read by APP Compare is jpg,dat,exe,gif,bmp,png,xls,xlsx,doc,docx,jar,dll,classpath,project,cbm,placeholder,class" ;
	print "\nComputeFiles Begin: **time= ".(localtime)."\n";

	
	&REPORT("Content V1 Source files '@V1files'" );
	# Loop on each source file
	foreach $Source_FullFileName(@V2files)
	{
		if ($debug)
		{
			print $MyFileCounter."/".$MyMaxFileCounter." ";
		}
		else
		{
			if (($MyFileCounter == $MyMaxFileCounter) || ($MyFileCounter % $loggerFrequency) == 0)
			{
				#print "File Counter: ".$MyFileCounter."/".$MyMaxFileCounter."\n";
				#print "***\n";
				#print " **Time= ".(localtime)."\n";
			}
		}
		$MyFileCounter--;
		#print "\n File begins: **time= ".($Source_FullFileName)."\n";
		&ComputeFileCHANGED($Source_FullFileName);
	
	}
	
	foreach $Source_FullFileName(@V1files)
	{
		if ($debug)
		{
			print $MyFileCounter."/".$MyMaxFileCounter." ";
		}
		else
		{
			if (($MyFileCounter == $MyMaxFileCounter) || ($MyFileCounter % $loggerFrequency) == 0)
			{
				#print "File Counter: ".$MyFileCounter."/".$MyMaxFileCounter."\n";
				#print " **Time= ".(localtime)."\n";
			}
		}
		$MyFileCounter--;
		&ComputeFileREMOVED($Source_FullFileName);
	
	}
	
	foreach $MySource_FullFileName(@V2DBfiles)
	{
		if ( -z $MySource_FullFileName )
	{
		&REPORT( 1,"File '$MySource_FullFileName' is empty." );
	}
	else
	{
			
			
			my $V2_MyPath;
			my $V2_MyFileName;
			my $V2_MyExtension;
			&FullFileNameToPathFileNameAndExtension( $MySource_FullFileName, \$V2_MyPath, \$V2_MyFileName, \$V2_MyExtension );
			if($V2_MyFileName."\.".$V2_MyExtension eq 'DatabaseExtraction.uaxdirectory' )
			{
			my $Filetype = "V2DBArtifact";
			&ArtifactsLoad($MySource_FullFileName,$Filetype);
			}
			
			

	}
	}
	
	foreach $MySource_FullFileName(@V1DBfiles)
	{
		if ( -z $MySource_FullFileName )
	{
		&REPORT( 1,"File '$MySource_FullFileName' is empty." );
	}
	else
	{
			my $V1_MyPath;
			my $V1_MyFileName;
			my $V1_MyExtension;
			&FullFileNameToPathFileNameAndExtension( $MySource_FullFileName, \$V1_MyPath, \$V1_MyFileName, \$V1_MyExtension );
			if($V1_MyFileName."\.".$V1_MyExtension eq 'DatabaseExtraction.uaxdirectory' )
			{
			my $Filetype = "V1DBArtifact";
			&ArtifactsLoad($MySource_FullFileName,$Filetype);
			}

	}
	}
	
	&DBArtifactsEntry();


	&REPORT( 1,"Version 1: Lines of code TOTAL = '$V1_TOTAL_LOC'" );
	&REPORT( 1,"Version 2: Lines of code TOTAL = '$V2_TOTAL_LOC'" );

	&REPORT("ComputeFiles End: **time= ".(localtime));
	print "ComputeFiles End: **time= ".(localtime)."\n";
	
	close(TARGET_OUT_FILE);
	
	
	&REPORT( "\nEnd of process." );
}

####################################################################################################

sub ComputeFileCHANGED
{
	# Parameters
	my( $MySource_FullFileName ) = @_;
	
	if ($Debug)
	{
		#print "- Processing file '$MySource_FullFileName'\n";
	}
	&REPORT( "\n- ComputeFileCHANGED: Processing file '$MySource_FullFileName'" );
	
	# Test if input file is not empty
	if ( -z $MySource_FullFileName )
	{
		&REPORT( 1,"File '$MySource_FullFileName' is empty." );
	}
	else
	{
		# Open source file
		if( open( SOURCE_IN_FILE,"<$MySource_FullFileName" ) )
		{
			

			my $MyClassFileFound = "FALSE";
			
			my @V1_PresenceCheck =();
			
			
			#Split the file name in chunks
			my $V2_MyPath;
			my $V2_MyFileName;
			my $V2_MyExtension;
			&FullFileNameToPathFileNameAndExtension( $MySource_FullFileName, \$V2_MyPath, \$V2_MyFileName, \$V2_MyExtension );
			if ($V2_MyExtension eq "dat" || $V2_MyExtension eq "jpg" || $V2_MyExtension eq "gif" || $V2_MyExtension eq "bmp"
					|| $V2_MyExtension eq "png"   || $V2_MyExtension eq "xls" || $V2_MyExtension eq "doc" || $V2_MyExtension eq "docx" 
					|| $V2_MyExtension eq "jar" || $V2_MyExtension eq "dll" || $V2_MyExtension eq "classpath" || $V2_MyExtension eq "project"
					|| $V2_MyExtension eq "cbm" || $V2_MyExtension eq "xlsx"  || $V2_MyExtension eq "exe"  
					|| $V2_MyExtension eq "placeholder"  || $V2_MyExtension eq "class" || $V2_MyExtension eq "uax" || $V2_MyExtension eq "src")
			{
				&REPORT( 2,"File Ignored '$MySource_FullFileName'." );
			}
			else
			{
			if($V2_MyFileName.".".$V2_MyExtension eq 'DatabaseExtraction.uaxdirectory' )
			{
				&REPORT( 2,"Checking database '$MySource_FullFileName'." );
				my $Filetype = "V2DBArtifact";
				&ArtifactsLoad($MySource_FullFileName,$Filetype);
				$MyClassFileFound = "TRUE";
				}
			
			if($V2_MyFileName =~ /VAST/i ||  $V2_MyFileName =~ /exportResults/i ||  $V2_MyFileName =~ /p_Instance/i ||  $V2_MyFileName =~ /p_Schema/i ||  $V2_MyFileName =~ /p_Server/i)
			{
				$MyClassFileFound = "TRUE";
			}
			if($MyClassFileFound eq 'FALSE' )
			{
			#if ($Version2_DBPath ne "NON_ATT")
			#{
			#$V2_MyPath =~ s/[a-zA-Z0-9:_ \\\-]+\\SOURCE[\\]?/\\/;
			#}
			#else
			#{
			#$V2_MyPath =~ s/[a-zA-Z0-9:_ \\\-]+\\Analyzed[\\]?/\\/;
			#}


			# PUT LIMIT ON EXTENSIONS
			#if ( 	$V2_MyExtension eq "java"
			#	|| $V2_MyExtension eq "xml"
			#	|| $V2_MyExtension eq "jar"
			#	|| $V2_MyExtension eq "jsp"
			#	|| $V2_MyExtension eq "html"
			#	|| $V2_MyExtension eq "js"
			#	|| $V2_MyExtension eq "css"
			#	|| $V2_MyExtension eq "properties"
			#	|| $V2_MyExtension eq "fla"
			#	|| $V2_MyExtension eq "swf"
			#	|| $V2_MyExtension eq "sql"
			#	|| $V2_MyExtension eq "db"
			#	|| $V2_MyExtension eq "sql"
			#	)
			
			#{	
					
				#######################################################################################################		
				# First check if the file exists in the V1 previous version array
				#my $V2_FileNameCheck = $V2_MyPath."\\".$V2_MyFileName;
				my $V2_FileNameCheck = '';
				
				if ( $V2_MyExtension ne "" )
				{
							
					$V2_FileNameCheck = $V2_MyFileName."\.".$V2_MyExtension;
				 	
				}			
				
				$V2_FileNameCheck =~ s/\\\\/\\/g;				
				
				#@V1_PresenceCheck = grep ($V2_FileNameCheck, @V1files);
				my @V1_PresenceCheck = grep( /\Q$V2_FileNameCheck\E$/, @V1files );
				
				
				#&REPORT( 1,"Verify file in V1 code '$V2_FileNameCheck' and '@V1_PresenceCheck'" );
				
				my $V1_PresenceCheck = @V1_PresenceCheck + 0;
				
				
				

				#Handling if not present in the previous version

				if ( $V1_PresenceCheck eq 0 )
				#if (exists($V1files{$V2_FileNameCheck}))
				{
					
					# Apparently the class file not found at all in the loop; therefore the conclusion is that it is an added artifact
					#&REPORT( 1,"File '$V2_FileNameCheck' doesn't exist in the previous version" );
						
							
					#my $BeginPosition = index($V1_MyPath, '\\', 2);
					#my $BeginPosition = $BeginPosition + 1;
							
					#my $EndPosition = index($V1_MyPath, '\\', 3);
					#my $EndPosition = $EndPosition + 1;
					#		
					#my $UDMmodule =  substr($V2_MyPath, $BeginPosition, $EndPosition);
					
							
					#&REPORT( 1,"CurrentUDM_Module = '$UDMmodule' and '$EndPosition' and '$BeginPosition' " );
					if ( $MySource_FullFileName =~ /\\COUK Clusters\\([a-zA-Z0-9_ ]+)\\/ )
					{
							 $UDMmodule =  $1;
							# &REPORT( 1,"New UDM_Module = '$UDMmodule' " );
					}
					#Calculate LoC Version 1				
				
					my $V1_FileLoC = 0;
					&ComputeLoC( $MyOutput, \$V1_FileLoC);
					
					$V2_MyPath =~ s/\\/\\\\/g;
					
					$V2_MyPath =~ s/'s/\\'s/g;
					$V2_MyFileName =~ s/'s/\\'s/g;
				
				
					#Calculate LoC Version 2				
					my $V2_FileLoC;
					&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
					$MySource_FullFileName =~ s/\\/\\\\/g;
					
					my @V2_CodeFile = grep{$_->[1]  =~ /\Q$MySource_FullFileName\E$/} @V2LOCDetails ;
					if ($V2_CodeFile[0][0] eq "") 
					{
						my $V2_FileLoC;
						$V2_CodeFile[0][0]="Read_APPCompare";
						&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
						$V2_CodeFile[0][4]= $V2_FileLoC;
					}
					#&REPORT( 1,"ADDDED V2 '$V2_CodeFile[0][0] ' '$V2_CodeFile[0][1] ' '$V2_CodeFile[0][2] ' '$V2_CodeFile[0][3] ' '$V2_CodeFile[0][4] ' ");
					
					$V2_TOTAL_LOC = $V2_TOTAL_LOC + $V2_CodeFile[0][4];
							
					my $FileNameSQL = $V2_MyFileName."\.".$V2_MyExtension;
					my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES, V2_COMMENT_LINES, V1_COMMENT_LINES, V2_BLANK_LINES, V1_BLANK_LINES, TECHNOLOGY) Values(";
					my $FlexLineSQL = "'".$App_Version."'".", "."'".$FileNameSQL."'".", "."'".$App_Name."'".", "."E'".$V1_MyPath."'".", "."E'".$V2_MyPath."'".", "."'"."ADDED"."'".", "."''".", "."'". $V2_CodeFile[0][4]."'".", "."'".$V1_FileLoC."'".", "."'". $V2_CodeFile[0][3]."'".", "."''".", "."'". $V2_CodeFile[0][2]."'".", "."''"." , "."'". $V2_CodeFile[0][0]."'".");";
		
					$Full_Record_report = $StartLineSQL.$FlexLineSQL;
					#&REPORT( 1,"File '$Full_Record_report' Written" );
					$MySource_FullFileName =~ s/\\\\/\\/g;
						
					$MyClassFileFound = "TRUE";

					print TARGET_OUT_FILE "$Full_Record_report\n";
					
				}
				####################################################################################################### 
			
			
				#Handling if  present in the previous version
				else
				{	
					
					
					
					#Calculate LoC Version 2				
					my $V2_FileLoC;
					&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
					#$V2_TOTAL_LOC = $V2_TOTAL_LOC + $V2_FileLoC;
				
					
					#Check V1 files
					my $MyInstanceSize_V1 = @V1files + 0;		
					for ( my $MyIt = 0 ; $MyIt < $MyInstanceSize_V1 ; $MyIt++ )
						{
							
								my $MyOutput = $V1files[$MyIt];
								
								#Split the file name in chunks
								my $V1_MyPath;
								my $V1_MyFileName;
								my $V1_MyExtension;
								
								&FullFileNameToPathFileNameAndExtension( $MyOutput, \$V1_MyPath, \$V1_MyFileName, \$V1_MyExtension );
								#&REPORT( 1,"My V1 files  '$MyOutput'" );
								#&REPORT( 1,"My V2 files  '$V2_MyFileName' and my V1_File is '$V1_MyFileName' " );
								
							
								#Clean up path names; remove input folder names
								if ($Version2_DBPath ne "NON_ATT")
								{
									#$V1_MyPath =~ s/[a-zA-Z0-9:_ \\\-]+\\ARCHIVE\\SOURCE_ANALYZED\\[a-zA-Z0-9_\.\-]*[\\]?/\\/;
													
								}
								else{
								#$V1_MyPath =~ s/\\/\\\\/g;
								#$V1_MyPath =~ s/[a-zA-Z0-9:_ \\]+\\Archive\\[a-zA-Z0-9_\. \\\-]+\\SOURCE_ANALYZED\\[\\][a-zA-Z0-9_\. ]+[\\]?/\\/;
								
								}
								$V1_MyPath =~ s/\\\\/\\/g;
								my $V2_FileNameDuplicateCheck = $V2_MyPath."\\".$V2_MyFileName;
								if ( $V2_MyExtension ne "" )
								{
								 $V2_FileNameDuplicateCheck = $V2_MyPath."\\".$V2_MyFileName."\.".$V2_MyExtension;
								}
								$V2_FileNameDuplicateCheck =~ s/\\\\/\\/g;
								#Check if name is the same but location appear as changed. 
								if ( $V2_MyFileName."\.".$V2_MyExtension eq $V1_MyFileName."\.".$V1_MyExtension &&  $V2_MyPath ne $V1_MyPath)
								{
								my @V2_PresenceCheck =();
								my @V2_PresenceCheck = grep( /\Q$V2_FileNameDuplicateCheck\E$/, @V1files );
								my $V2_PresenceCheck = @V2_PresenceCheck + 0;
									
								if ($V2_PresenceCheck )	
								{
								 #Ensure to leave the FOR LOOP now
								#$MyClassFileFound = "FALSE";
								}
								else
								{
								
									#Ok, so the file has really changed its location
									#$Full_Record_report = $V2_MyFileName.",".$V2_MyPath.",".",".$V1_MyPath.","."CHANGED LOCATION";
									
									#Calculate LoC Version 1				
									my $V1_FileLoC;
									&ComputeLoC( $MyOutput, \$V1_FileLoC);
									$MySource_FullFileName =~ s/\\/\\\\/g;
									#$MyOutput =~ s/\\/\\\\/g;
									my @V2_CodeFile = grep{$_->[1]  =~ /\Q$MySource_FullFileName\E$/} @V2LOCDetails ;
									if ($V2_CodeFile[0][0] eq "") 
									{
									my $V2_FileLoC;
									$V2_CodeFile[0][0]="Read_APPCompare";
									&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
									$V2_CodeFile[0][4]= $V2_FileLoC;
									}
									
									#my @V1_CodeFile = grep{$_->[1]  =~ /\Q$MyOutput\E$/} @V1LOCDetails ;
									$V2_TOTAL_LOC = $V2_TOTAL_LOC + $V2_CodeFile[0][4];
									#&REPORT( 1,"CHANGED V2  '$V2_CodeFile[0][0] ' '$V2_CodeFile[0][1] ' '$V2_CodeFile[0][2] ' '$V2_CodeFile[0][3] ' '$V2_CodeFile[0][4] ' ");						
									
									$V2_MyPath =~ s/\\/\\\\/g;
									
									
									$V1_MyPath =~ s/\\/\\\\/g;
									
									$V1_MyPath =~ s/'s/\\'s/g;
									$V1_MyFileName =~ s/'s/\\'s/g;
									$V2_MyPath =~ s/'s/\\'s/g;
									$V2_MyFileName =~ s/'s/\\'s/g;


									my $FileNameSQL = $V2_MyFileName."\.".$V2_MyExtension;
									my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES, V2_COMMENT_LINES, V1_COMMENT_LINES, V2_BLANK_LINES, V1_BLANK_LINES, TECHNOLOGY) Values(";
									#my $FlexLineSQL = "'".$FileNameSQL."'".", "."'".$UDMmodule."'".", "."'".$V1_MyPath."'".", "."'".$V2_MyPath."'".", "."'"."CHANGED LOCATION"."'".", "."'".$V2_MyFileName."'".");";
									my $FlexLineSQL = "'".$App_Version."'".", "."'".$FileNameSQL."'".", "."'".$App_Name."'".", "."E'".$V1_MyPath."'".", "."E'".$V2_MyPath."'".", "."'"."CHANGED LOCATION"."'".", "."''".", "."'".$V2_CodeFile[0][4]."'".", "."'".$V2_CodeFile[0][4]."'".", "."'". $V2_CodeFile[0][3]."'".", "."'". $V2_CodeFile[0][3]."'".", "."'". $V2_CodeFile[0][2]."'".", "."'". $V2_CodeFile[0][2]."'"." , "."'". $V2_CodeFile[0][0]."'".");";
									
									$Full_Record_report = $StartLineSQL.$FlexLineSQL;
									#&REPORT( 1,"File '$Full_Record_report' Written" );
									#&REPORT( 1,"Current record found = '$Full_Record_report'" );
									#&REPORT( 1,"My Filename is the same '$V1_MyFileName' " );
									
									print TARGET_OUT_FILE "$Full_Record_report\n";
									
									#Ensure to leave the FOR LOOP now
									$MyIt = $MyInstanceSize_V1;
									$MySource_FullFileName =~ s/\\\\/\\/g;
									#$MyOutput =~ s/\\\\/\\/g;
									
									$MyClassFileFound = "TRUE";
									}
								}
								
								elsif ( $V2_MyFileName."\.".$V2_MyExtension eq $V1_MyFileName."\.".$V1_MyExtension &&  $V2_MyPath eq $V1_MyPath)
								{
									#Ok, Location is UnChanged
									#$Full_Record_report = $V2_MyFileName.",".$V2_MyPath.",".",".$V1_MyPath.","."UNCHANGED";
				
									#Calculate LoC Version 1				
									my $V1_FileLoC;
									&ComputeLoC( $MyOutput, \$V1_FileLoC);
									$MySource_FullFileName =~ s/\\/\\\\/g;
									#$MyOutput =~ s/\\/\\\\/g;
									my @V2_CodeFile = grep{$_->[1]  =~ /\Q$MySource_FullFileName\E$/} @V2LOCDetails ;
									if ($V2_CodeFile[0][0] eq "") 
									{
									my $V2_FileLoC;
									$V2_CodeFile[0][0]="Read_APPCompare";
									&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
									$V2_CodeFile[0][4]= $V2_FileLoC;
									}
									#my @V1_CodeFile = grep{$_->[1]  =~ /\Q$MyOutput\E$/} @V1LOCDetails ;
									$V2_TOTAL_LOC = $V2_TOTAL_LOC + $V2_CodeFile[0][4];
									#&REPORT( 1,"UNCHANGED V2  '$V2_CodeFile[0][0] ' '$V2_CodeFile[0][1] ' '$V2_CodeFile[0][2] ' '$V2_CodeFile[0][3] ' '$V2_CodeFile[0][4] ' ");		
									
									$V2_MyPath =~ s/\\/\\\\/g;
									
									$V1_MyPath =~ s/\\/\\\\/g;
									

									$V1_MyPath =~ s/'s/\\'s/g;
									$V1_MyFileName =~ s/'s/\\'s/g;
									$V2_MyPath =~ s/'s/\\'s/g;
									$V2_MyFileName =~ s/'s/\\'s/g;

									my $FileNameSQL = $V2_MyFileName."\.".$V2_MyExtension;
									my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES, V2_COMMENT_LINES, V1_COMMENT_LINES, V2_BLANK_LINES, V1_BLANK_LINES, TECHNOLOGY) Values(";
									#my $FlexLineSQL = "'".$FileNameSQL."'".", "."'".$UDMmodule."'".", "."'".$V1_MyPath."'".", "."'"."UNCHANGED"."'".", "."'".$V2_MyFileName."'".")";
									#my $FlexLineSQL = "'".$FileNameSQL."'".", "."'".$UDMmodule."'".", "."'".$V1_MyPath."'".", "."'".$V2_MyPath."'".", "."'"."UNCHANGED"."'".", "."'".$V2_MyFileName."'".")";
									my $FlexLineSQL = "'".$App_Version."'".", "."'".$FileNameSQL."'".", "."'".$App_Name."'".", "."E'".$V1_MyPath."'".", "."E'".$V2_MyPath."'".", "."'"."UNCHANGED LOCATION"."'".", "."''".", "."'".$V2_CodeFile[0][4]."'".", "."'".$V2_CodeFile[0][4]."'".", "."'". $V2_CodeFile[0][3]."'".", "."'". $V2_CodeFile[0][3]."'".", "."'". $V2_CodeFile[0][2]."'".", "."'". $V2_CodeFile[0][2]."'"." , "."'". $V2_CodeFile[0][0]."'".");";
									
									$Full_Record_report = $StartLineSQL.$FlexLineSQL;
									#&REPORT( 1,"File '$Full_Record_report' Written" );
									#&REPORT( 1,"Current record found = '$Full_Record_report'" );
									#&REPORT( 1,"My Filename is the same '$V1_MyFileName' " );
									
									print TARGET_OUT_FILE "$Full_Record_report\n";
									
									#Ensure to leave the FOR LOOP now
									$MyIt = $MyInstanceSize_V1;
									$MySource_FullFileName =~ s/\\\\/\\/g;
									#$MyOutput =~ s/\\\\/\\/g;
									$MyClassFileFound = "TRUE";
								}
								
						}		# END FOR LOOP		
						
					} #END ELSE IF
					
			
		#	} # END LIMIT EXTENSIONS
			if ($MyClassFileFound eq "FALSE" )
			{
			$V2_MyPath =~ s/\\/\\\\/g;
			$V1_MyPath =~ s/\\/\\\\/g;
			my $V1_FileLoC = 0;
			$V2_MyPath =~ s/'s/\\'s/g;
			$V2_MyFileName =~ s/'s/\\'s/g;
				
			&REPORT( 1,"V2_MyPath '$V2_MyPath' " );
			#Calculate LoC Version 2				
			my $V2_FileLoC;
			&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
			$MySource_FullFileName =~ s/\\/\\\\/g;
			my @V2_CodeFile = grep{$_->[1]  =~ /\Q$MySource_FullFileName\E$/} @V2LOCDetails ;
			if ($V2_CodeFile[0][0] eq "") 
			{
			my $V2_FileLoC;
			$V2_CodeFile[0][0]="Read_APPCompare";
			&ComputeLoC( $MySource_FullFileName, \$V2_FileLoC);
			$V2_CodeFile[0][4]= $V2_FileLoC;
			}
			$V2_TOTAL_LOC = $V2_TOTAL_LOC + $V2_CodeFile[0][4];
							
			my $FileNameSQL = $V2_MyFileName."\.".$V2_MyExtension;
			my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES, V2_COMMENT_LINES, V1_COMMENT_LINES, V2_BLANK_LINES, V1_BLANK_LINES, TECHNOLOGY) Values(";
			my $FlexLineSQL = "'".$App_Version."'".", "."'".$FileNameSQL."'".", "."'".$App_Name."'".", "."E'".$V1_MyPath."'".", "."E'".$V2_MyPath."'".", "."'"."ADDED"."'".", "."''".", "."'". $V2_CodeFile[0][4]."'".", "."'".$V1_FileLoC."'".", "."'". $V2_CodeFile[0][3]."'".", "."''".", "."'". $V2_CodeFile[0][2]."'".", "."''"." , "."'". $V2_CodeFile[0][0]."'".");";
					
			$Full_Record_report = $StartLineSQL.$FlexLineSQL;
			#&REPORT( 1,"File '$Full_Record_report' Written" );
			$MySource_FullFileName =~ s/\\\\/\\/g;
			$MyClassFileFound = "TRUE";
			print TARGET_OUT_FILE "$Full_Record_report\n";
			}
		}
		}
		}
		else
		{
			&REPORT( 2,"Unable to open file '$MySource_FullFileName'." );
		}
	}
}

####################################################################################################

sub ComputeFileREMOVED
{
	# Parameters
	my( $MySource_FullFileName ) = @_;
	
	if ($Debug)
	{
		#print "- Processing file '$MySource_FullFileName'\n";
	}
	&REPORT( "\n- ComputeFileRemoved: Processing file '$MySource_FullFileName'" );
	
	# Test if input file is not empty
	if ( -z $MySource_FullFileName )
	{
		&REPORT( 1,"File '$MySource_FullFileName' is empty." );
	}
	else
	{
		# Open source file
		if( open( SOURCE_IN_FILE,"<$MySource_FullFileName" ) )
		{
			

			my $MyClassFileFound = "FALSE";
			
			my @V1_PresenceCheck =();
			
			
			#Split the file name in chunks
			my $V1_MyPath;
			my $V1_MyFileName;
			my $V1_MyExtension;
			&FullFileNameToPathFileNameAndExtension( $MySource_FullFileName, \$V1_MyPath, \$V1_MyFileName, \$V1_MyExtension );
			
			
			if($V1_MyFileName."\.".$V1_MyExtension eq 'DatabaseExtraction.uaxdirectory' )
			{
				my $Filetype = "V1DBArtifact";
				&ArtifactsLoad($MySource_FullFileName,$Filetype);
				 $MyClassFileFound = "TRUE";
			}
			if($V1_MyFileName =~ /VAST/i ||  $V1_MyFileName =~ /exportResults/i ||  $V1_MyFileName =~ /p_Instance/i ||  $V1_MyFileName =~ /p_Schema/i ||  $V1_MyFileName =~ /p_Server/i)
			{
				$MyClassFileFound = "TRUE";
			}
			if($MyClassFileFound eq 'FALSE' )
			{
		
			#Calculate LoC Version 1				
			my $V1_FileLoC = 0;
			&ComputeLoC( $MySource_FullFileName, \$V1_FileLoC);
				
			
			# PUT LIMIT ON EXTENSIONS
			#if ( 	$V1_MyExtension eq "java"
			#	|| $V1_MyExtension eq "xml"
			#	|| $V1_MyExtension eq "jar"
			#	|| $V1_MyExtension eq "jsp"
			#	|| $V1_MyExtension eq "html"
			#	|| $V1_MyExtension eq "js"
			#	|| $V1_MyExtension eq "css"
			#	|| $V1_MyExtension eq "properties"
			#	|| $V1_MyExtension eq "fla"
			#	|| $V1_MyExtension eq "swf"
			#	|| $V1_MyExtension eq "sql"
			#	)
			#	
			#{	
					
				#######################################################################################################		
				# First check if the file exists in the V1 previous version array
				#if ($Version2_DBPath ne "NON_ATT")
				#{
				#$V1_MyPath =~ s/[a-zA-Z0-9:_ \\\-]+\\ARCHIVE\\SOURCE_ANALYZED\\[a-zA-Z0-9_\.\-]*[\\]?/\\/;
				#}
				#else
				#{
			#		
				#$V1_MyPath =~ s/\\/\\\\/g;
				#$V1_MyPath =~ s/[a-zA-Z0-9:_ \\]+\\Archive\\[a-zA-Z0-9_\. \\\-]+\\SOURCE_ANALYZED\\[\\][a-zA-Z0-9_\. ]+[\\]?/\\/;
				#}
				$V1_MyPath =~ s/\\\\/\\/g;
				my $V1_FileNameCheck = $V1_MyPath."\\".$V1_MyFileName;
				

				
				if ( $V1_MyExtension ne "" )
				{
				$V1_FileNameCheck = $V1_MyPath."\\".$V1_MyFileName;
				
				$V1_FileNameCheck = $V1_FileNameCheck."\.".$V1_MyExtension;
				}
				$V1_FileNameCheck =~ s/\\\\/\\/g;
				my @V2_PresenceCheck = grep( /\Q$V1_FileNameCheck\E$/, @V2files );
				
				#&REPORT( 1,"Verify file in V2 code '$V1_FileNameCheck' and '@V2_PresenceCheck'" );
				
				my $V2_PresenceCheck = @V2_PresenceCheck + 0;
				if ( $V2_PresenceCheck eq 0 )
				#if (exists($V1files{$V2_FileNameCheck}))
				{
					if ($Version2_DBPath ne "NON_ATT")
					{
						#$V2_MyPath =~ s/[a-zA-Z0-9:_ \\]+\\SOURCE\\/\\/;
					}
					else
					{			
					#$V2_MyPath =~ s/[a-zA-Z0-9:_ \\\-]+\\Analyzed\\/\\/;
										}
					#$V1_MyPath =~ s/\\/\\\\/g;
					$V2_MyPath =~ s/\\/\\\\/g;
			
					# Apparently the class file not found at all in the loop; therefore the conclusion is that it is an added artifact
					#&REPORT( 1,"File '$V1_FileNameCheck' doesn't exist in the previous version" );
						
					#my $BeginPosition = index($V1_MyPath, '\\', 2);
					#my $BeginPosition = $BeginPosition + 1;
							
					#my $EndPosition = index($V1_MyPath, '\\', 3);
					#my $EndPosition = $EndPosition + 1;
					#		
					#my $UDMmodule =  substr($V2_MyPath, $BeginPosition, $EndPosition);
					
							
					#&REPORT( 1,"CurrentUDM_Module = '$UDMmodule' and '$EndPosition' and '$BeginPosition' " );
					if ( $MySource_FullFileName =~ /\\COUK Clusters\\([a-zA-Z0-9_ ]+)\\/ )
					{
							 $UDMmodule =  $1;
							# &REPORT( 1,"New UDM_Module = '$UDMmodule' " );
					}
								
					#Calculate LoC Version 1				
					my $V1_FileLoC;
					&ComputeLoC( $MyOutput, \$V1_FileLoC);
					my $V2_FileLoC = 0;
					#$MySource_FullFileName =~ s/\\/\\\\/g;
					#my @V1_CodeFile = grep{$_->[1]  =~ /\Q$MySource_FullFileName\E$/} @V1LOCDetails ;
					#$V1_TOTAL_LOC = $V1_TOTAL_LOC + $V1_CodeFile[0][4];
					
					$V1_MyPath =~ s/\\/\\\\/g;
					

					$V1_MyPath =~ s/'s/\\'s/g;
					$V1_MyFileName =~ s/'s/\\'s/g;

					my $FileNameSQL = $V1_MyFileName."\.".$V1_MyExtension;
					my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES, V2_COMMENT_LINES, V1_COMMENT_LINES, V2_BLANK_LINES, V1_BLANK_LINES, TECHNOLOGY) Values(";
					#my $FlexLineSQL = "'".$FileNameSQL."'".", "."'".$UDMmodule."'".", "."'".$V1_MyPath."'".", "."'"."REMOVED"."'".", "."'".$V1_MyFileName."'".")";
					#my $FlexLineSQL = "'".$FileNameSQL."'".", "."'".$UDMmodule."'".", "."'".$V1_MyPath."'".", "."'".$V2_MyPath."'".", "."'"."REMOVED"."'".", "."'".$V2_MyFileName."'".")";
					my $FlexLineSQL = "'".$App_Version."'".", "."'".$FileNameSQL."'".", "."'".$App_Name."'".", "."E'".$V1_MyPath."'".", "."E'".$V2_MyPath."'".", "."'"."REMOVED"."'".", "."''".", "."'". $V2_FileLoC."'".",  "."''".", "."''".",  "."''".", "."''"." ,  "."''".",  "."''".");";
					
					$Full_Record_report = $StartLineSQL.$FlexLineSQL;
					#&REPORT( 1,"File '$Full_Record_report' Written" );
					##'ChangePricePlan', '\Code\Source\EJBs\src\com\vodafone\wrp\ejbs\ecare\ChangePricePlanSessionBean.java', 'CHANGED', 'ChangePricePlanSessionBean')
					#$MySource_FullFileName =~ s/\\\\/\\/g;
					print TARGET_OUT_FILE "$Full_Record_report\n";
					
				}
				####################################################################################################### 
			
			
			
			#} # END LIMIT EXTENSIONS
			}
		}
		else
		{
			&REPORT( 2,"Unable to open file '$MySource_FullFileName'." );
		}
	}
}

sub ArtifactsLoad
{
				my ($MySource_FullFileName,$Filetype) = @_;
				
				
						# Handling DB Related Object Entry 
						#Addition of Oracle DB Objects
						if( open( SOURCE_IN_FILE,"<$MySource_FullFileName" ) )
						{
						#&REPORT( 1,"Entered DB " );
						my $MyLine=<SOURCE_IN_FILE>;
						my $LineNbr=1;
						my $Server;
						my $Instance;
						my $Schema;
						my $Artifact;
						my $Artifact_type;
							while ( defined( $MyLine ))
							{
							# Remove the '\n' from the input line
							chomp $MyLine;
							
							
							#<UAXFile path="p_Server.1.uax" name="jlti019" type="CAST_SQL_Machine">
							# <UAXFile path="p_Instance.1.uax" name="ctp02t" type="CAST_SQL_Instance">
							# <UAXFile path="p_Schema.1.uax" name="CTPADM" type="CAST_SQL_Schema">
							# <UAXFile path="VASTCreateTable.1.uax" name="AAA" type="CAST_Oracle_RelationalTable"/>
							if ($MyLine =~ /\<UAXFile[ \t]+path\=\"p_Server\.1\.uax\"[ \t]+name\=\"/i)
							{
								$MyLine =~ /\<UAXFile[ \t]+path\=\"p_Server\.1\.uax\"[ \t]+name\=\"([a-zA-Z0-9_\$\.]+)\"/i;
								$Server = $1;

							&REPORT( "Server \n '$Server'" );
							
							}
							if ($MyLine =~ /\<UAXFile[ \t]+path\=\"p_Instance\.1\.uax\"[ \t]+name\=\"/i)
							{
								$MyLine =~ /\<UAXFile[ \t]+path\=\"p_Instance\.1\.uax\"[ \t]+name\=\"([a-zA-Z0-9_\$\.]+)\"/i;
								$Instance = $1;
							&REPORT( "UAX line \n '$Instance'" );
							
							}
							if ($MyLine =~ /\<UAXFile[ \t]+path\=\"p_Schema\.1\.uax\"[ \t]+name\=\"/i)
							{
								$MyLine =~ /\<UAXFile[ \t]+path\=\"p_Schema\.1\.uax\"[ \t]+name\=\"([a-zA-Z0-9_\$\.]+)\"/i;
								$Schema = $1;
							&REPORT( "UAX line \n '$Schema'" );
							
							}
							if ($MyLine =~ /\<UAXFile[ \t]+path\=\"VAST[a-zA-Z0-9_\.\$]+\"[ \t]+name\=\"/i)
							{
								$MyLine =~ /\<UAXFile[ \t]+path\=\"VAST[a-zA-Z0-9_\.\$]+\"[ \t]+name\=\"([a-zA-Z0-9_\$\.]+)\"[ \t]+type\=\"([a-zA-Z0-9_\$\.]+)\"/i;
								$Artifact = $1;
								$Artifact_type = $2;
								&REPORT( "UAX line \n '$Schema   $Artifact  $Artifact_type'" );
							#insert here
							if ($Filetype eq 'V1DBArtifact')
							{
								&AddV1Artifacts($Server."\.".$Instance."\.".$Schema."\.".$Artifact."\.".$Artifact_type);
							}
							if ($Filetype eq 'V2DBArtifact')
							{
								&AddV2Artifacts($Server."\.".$Instance."\.".$Schema."\.".$Artifact."\.".$Artifact_type);
							}
							#&REPORT( "UAX line \n '$V1_MyPath   $Artifact  $Artifact_type'" );
							
							}
							$MyLine=<SOURCE_IN_FILE>;
							$LineNbr=$LineNbr+1;
							#</UAXFile>
							if ($MyLine =~ /\<\/UAXFile\>/i)
							{
							goto ExitDB;
							}
							}
							ExitDB:
							close( SOURCE_IN_FILE );
							#&REPORT( "V2Artifacts \n '@V2Artifacts'" );
							#&REPORT( "V1Artifacts \n '@V1Artifacts'" );
						}
						
						
						#Addition of Oracle DB Objects
					# Handling DB Related Object Entry
}

sub AddV1Artifacts
{
	my ($newArtifact) = @_;

	my $AvoidDuplicates = 'FALSE';
	foreach $Artifact(@V1Artifacts)
	{
		if ($Artifact eq $newArtifact) 
		{
			$AvoidDuplicates = 'TRUE';
		}
	}
	if ($AvoidDuplicates eq 'FALSE') 
	{
		push(@V1Artifacts, $newArtifact);
	}
}
sub AddV2Artifacts
{
	my ($newArtifact) = @_;

	my $AvoidDuplicates = 'FALSE';
	foreach $Artifact(@V2Artifacts)
	{
		if ($Artifact eq $newArtifact) 
		{
			$AvoidDuplicates = 'TRUE';
		}
	}
	if ($AvoidDuplicates eq 'FALSE') 
	{
		push(@V2Artifacts, $newArtifact);
	}
}
sub DBArtifactsEntry
				{
				my $DBArtifactName;
				my $DBArtifactFullName;
				my $DBArtifactType;
				foreach $DBV2Artifact(@V2Artifacts)
				{
					my @V2_DBArtifact=();
					my @V2_DBArtifact = grep( /\Q$DBV2Artifact\E$/, @V1Artifacts );
					
					&DBArtifactToNameFullNameType($DBV2Artifact, \$DBArtifactName, \$DBArtifactFullName, \$DBArtifactType);
					&REPORT( 1,"DBV2Artifact '$DBV2Artifact' " );
					&REPORT( "1234  \n '$DBArtifactFullName' '$DBArtifactName'  '$DBArtifactType' " );
					my $V2_DBArtifact = @V2_DBArtifact + 0;
					if ( $V2_DBArtifact eq 0)
					{
						$V1_MyPath= "";
						$V2_FileLoC="";
						$V1_FileLoC="";
						my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES) Values(";
						my $FlexLineSQL = "'".$App_Version."'".", "."'".$DBArtifactName."'".", "."'".$App_Name."'".", "."'".$V1_MyPath."'".", "."'".$DBArtifactFullName."'".", "."'"."ADDED DB ARTIFACT"."'".", "."'".$DBArtifactType."'".", "."'".$V2_FileLoC."'".", "."'".$V1_FileLoC."'".");";
							
						$Full_Record_report = $StartLineSQL.$FlexLineSQL;
						print TARGET_OUT_FILE "$Full_Record_report\n";
					}
					else
					{
						$V2_FileLoC="";
						$V1_FileLoC="";
						my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES) Values(";
						my $FlexLineSQL = "'".$App_Version."'".", "."'".$DBArtifactName."'".", "."'".$App_Name."'".", "."'".$DBArtifactFullName."'".", "."'".$DBArtifactFullName."'".", "."'"."UNCHANGED DB ARTIFACT"."'".", "."'".$DBArtifactType."'".", "."'".$V2_FileLoC."'".", "."'".$V1_FileLoC."'".");";
							
						$Full_Record_report = $StartLineSQL.$FlexLineSQL;
						print TARGET_OUT_FILE "$Full_Record_report\n";
					}
				}
	
				foreach $DBV1Artifact(@V1Artifacts)
				{
					my @V1_DBArtifact=();
					my @V1_DBArtifact = grep( /\Q$DBV1Artifact\E$/, @V2Artifacts );
					&DBArtifactToNameFullNameType( $DBV1Artifact, \$DBArtifactName, \$DBArtifactFullName, \$DBArtifactType);
					&REPORT( 1,"DBV1Artifact '$DBV1Artifact'" );
					&REPORT( "1234  \n '$DBArtifactFullName' '$DBArtifactName'  '$DBArtifactType' " );
					my $V1_DBArtifact = @V1_DBArtifact + 0;
					if ( $V1_DBArtifact eq 0)
					{
					$V2_MyPath= "";
					$V2_FileLoC="";
					$V1_FileLoC="";
					my $StartLineSQL = "Insert into ".$User.".APP_COMPARE(APP_VERSION, FILE_NAME, APP_NAME, OBJECT_FULLNAME_V1, OBJECT_FULLNAME_V2, LOCATION_STATUS, ARTIFACT_TYPE, V2_LINES, V1_LINES) Values(";
					my $FlexLineSQL = "'".$App_Version."'".", "."'".$DBArtifactName."'".", "."'".$App_Name."'".", "."'".$DBArtifactFullName."'".", "."'".$V2_MyPath."'".", "."'"."REMOVED DB ARTIFACT"."'".", "."'".$DBArtifactType."'".", "."'".$V2_FileLoC."'".", "."'".$V1_FileLoC."'".");";
						
					$Full_Record_report = $StartLineSQL.$FlexLineSQL;
					print TARGET_OUT_FILE "$Full_Record_report\n";
				}
				}
				
}

sub DBArtifactToNameFullNameType
{
	# Recuperation des parametres
	my ($DBArtifact,$DBArtifactName,$DBArtifactFullName,$DBArtifactType) = @_;
	#&REPORT( "MyDBArtifact \n '$DBArtifact'" );
	#jlti019.ctp02t.CTPADM.CTC_TEST_SCHEDULE_INSERT.CAST_Oracle_DML_Trigger
	# Calcul du nom des fichiers cibles
	
	
	
	if ($AIPVersionDB eq 'V70')
	{
		$DBArtifact =~ /([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)$/o;
		
		my $MyDBArtifactFullName = $1."\.".$2."\.".$3."\.".$4;
		my $MyDBArtifactType = $5;
		my $MyDBArtifactName = $4;
		$$DBArtifactFullName=$MyDBArtifactFullName ;
		$$DBArtifactName=$MyDBArtifactName ;
		$$DBArtifactType=$MyDBArtifactType ;
		#&REPORT( "123  \n '$DBArtifactFullName' '$DBArtifactName'  '$DBArtifactType' " );
	}
	else
	{
		$DBArtifact =~ /\.([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)\.([a-zA-Z0-9\_\$\.]+)$/o;
		my $MyDBArtifactFullName = $1."\.".$2."\.".$3;
		my $MyDBArtifactType = $4;
		my $MyDBArtifactName = $3;
		$$DBArtifactFullName=$MyDBArtifactFullName ;
		$$DBArtifactName=$MyDBArtifactName ;
		$$DBArtifactType=$MyDBArtifactType ;
	}
	
}	
####################################################################################################
sub ReadLOCbyCloc
{
	# Parameters
	my( $Version_Path ) = @_; 
	
	print "***\n";
	print "CLOC Begin: Path=$Version_Path  **Time= ".(localtime)."\n";

	&REPORT( "CLOC Begin: Path=$Version_Path  **Time= ".(localtime) );
	&REPORT( "CLOC Begin: Cloc Path=$CLOCRESULTS  **Time= ".(localtime) );
	
	system ("$CLOCEXE", "--progress-rate=0","--skip-uniqueness", "-csv", "--by-file", "$Version_Path", "--out=$CLOCRESULTS");
	
	die ("Could not open file open file '$CLOCRESULTS'") unless open( RESULT_FILE,"<$CLOCRESULTS" );
	
	my $myLine = "";
	my $clocHeader = 1;
	my $i=0;
	while(<RESULT_FILE>)
	{
		$myLine = $_;
		chomp($myLine);
		
		if($clocHeader){
			$clocHeader = 0;
		}
		else
		{
			$myLine  =~ s/\\/\\\\/g;
			#language,filename,blank,comment,code
			#$myLine =~ /([A-Za-z0-9\+\#\/\- ]+)[\,]([A-Za-z0-9\_\: \$\\\.\-#\=]+)[\,]([0-9]+)[\,]([0-9]+)[\,]([0-9]+)$/o;
			$myLine =~ /([A-Za-z0-9\+\#\/\- ]+)[\,]([A-Za-z0-9\_\: \$\=\@\$\^\&\*\~\`\"\;\?\#\\\.\-]+)[\,]([0-9]+)[\,]([0-9]+)[\,]([0-9]+)$/o;
			push @{$V2LOCDetails[$i]}, $1;
			push @{$V2LOCDetails[$i]}, $2;
			push @{$V2LOCDetails[$i]}, $3;
			push @{$V2LOCDetails[$i]}, $4;
			push @{$V2LOCDetails[$i]}, $5;
			$i=$i+1;
		}
	}
	close(RESULT_FILE);

	print "CLOC End: **Time= ".(localtime)."\n";
	print "***\n";
	&REPORT( "CLOC End: Finished Writing to $CLOCRESULTS  **Time= ".(localtime) );
}
sub executeCommand
{
  my $command = join ' ', @_;
  ($? >> 8, $_ = qx{$command 2>&1});
  
}
sub ComputeLoC
{
	# Parameters
	my( $MySource_FullFileName, $FileLoC ) = @_;
		
	# Test if input file is not empty
	if ( -z $MySource_FullFileName )
	{
		&REPORT( 1,"File '$MySource_FullFileName' is empty." );
	}
	else
	{
		my $size_in_mb = (-s $MySource_FullFileName) / (1024 * 1024);
		#&REPORT( "Size of $MySource_FullFileName is $size_in_mb" );
		if ($size_in_mb <  100 )
		{
		#&REPORT( "Size of $MySource_FullFileName is $size_in_mb" );
		# Open source file
		if( open( SOURCE_IN_FILE,"<$MySource_FullFileName" ) )
		{
			
			my $LinesCode = 0;
			my @InstanceBody = ();
			# Read the source file
			my $MyLine=<SOURCE_IN_FILE>;

			while ( defined( $MyLine ) )
			{
				# Remove the '\n' from the input line
				chomp $MyLine;
				
				if (!$MyLine =~ /^\s*$/) # the line should not be blank or only spaces
				{
					# Fill every non blank line in the array
					push( @InstanceBody, $MyLine );
				}
							
				######################
				# READ THE NEXT LINE
				######################
				$MyLine=<SOURCE_IN_FILE>;
				
			} #END WHILE	
			
			
			my $MyInstanceSize = @InstanceBody + 0;
			#&REPORT( "Line $.: End of instance  ==> $MyInstanceSize lines" );
			
			$$FileLoC = $MyInstanceSize;
	
			
			# Close the source file
			close( SOURCE_IN_FILE );
		}
		else
		{
			&REPORT( 2,"Unable to open file '$MySource_FullFileName'." );
		}
		}
		else
		{
		$$FileLoC = -1;
		}
	}
}

####################################################################################################

sub BuildFileList
{
	my( $path, $fPattern, $listPointer, $recursive ) = @_;
	my( $file );
	my( $fullName );
	my( $DIR );

	# Liste des fichiers du repertoire
	if ( opendir( $DIR, $path ) )
	{
		# Lecture du premier nom de fichier
		$file = readdir( $DIR );
		
		# Boucle tant que le nom de fichier est trouvé
		while( defined($file) )
		{
			# Calcul du nom complet
			$fullName = $path . "\\" . $file;
			
			# Test de validité
			if ( ( $fullName !~ /[\/\\]\.+$/o ) && ( -d $fullName || $file =~ /$fPattern/o ) && ($fullName !~ /\.[s][v][n]/io ))
			{
				# Test si c'est un repertoire ou un fichier
				if ( -f $fullName )
				{
					# Ajout a la liste
					push( @$listPointer, $fullName );
				}
				elsif ( -d $fullName && $recursive )
				{
					# Appel recursif sur le sous rep
					&BuildFileList( $fullName, $fPattern, $listPointer, $recursive );
				}
			}
			
			# Lecture du nom de fichier suivant
			$file = readdir( $DIR );
		}
	}
	else
	{
		&REPORT(3,"The directory '$path' does not exist!");
	}
	
	# Fermeture de la liste des fichiers du repertoire
	close( $DIR );
}

####################################################################################################

sub BuildPathList
{
	my( $path, $listPointer, ) = @_;
	my( $DIR );
	my $MyHaveFile = 0;
	
	# Liste des fichiers du repertoire
	if ( opendir( $DIR, $path ) )
	{
		# Lecture du premier nom de fichier
		$file = readdir( $DIR );
		
		# Boucle tant que le nom de fichier est trouvé
		while( defined($file) )
		{
			# Calcul du nom complet
			$fullName = $path . "\\" . $file;
			
			# Test de validité
			if ( $fullName !~ /[\/\\]\.+$/o )
			{
				# Test si c'est un repertoire ou un fichier
				if ( -f $fullName )
				{
					$MyHaveFile = 1;
				}
				elsif ( -d $fullName )
				{
					# Appel recursif sur le sous rep
					&BuildFullPathNameList( $fullName, $listPointer );
				}
			}
			
			# Lecture du nom de fichier suivant
			$file = readdir( $DIR );
		}
	}
	else
	{
		&REPORT(3,"the directory '$path' does not exist!");
	}
	
	if ($MyHaveFile)
	{
		push( @$listPointer, $path );
	}
	
	# Fermeture de la liste des fichiers du repertoire
	close( $DIR );
}

####################################################################################################

sub FullFileNameToPathFileNameAndExtension
{
	# Recuperation des parametres
	my ($MyFullFileName,$MyPath,$MyFileName,$MyExtension) = @_;

	# Calcul du nom des fichiers cibles
	$MyFullFileName =~ /^(.+)\\([^\\]+)$/o;
	my $MySource_Path = $1;
	my $MySource_FileName = $2;
	my $MySource_Extension = "";
	
	if ($MySource_FileName =~ /^(.+)\.([^\.]*)$/o)
	{
		$MySource_FileName = $1;
		$MySource_Extension = $2;
	}
	
	$$MyPath = $MySource_Path;
	$$MyFileName = $MySource_FileName;
	$$MyExtension = $MySource_Extension;
}

####################################################################################################

sub ExtractRelativePath
{
	# Recuperation des parametres
	my ($MyPath,$MyRootPath) = @_;

	# Calcul du chemin "Relatif" (sans le chemin racine)
	my $MyRelativePath = "";
	my $MyRootPath = uc($MyRootPath);
	my $MyQMRootPath = quotemeta($MyRootPath);
	if (uc($MyPath) =~ /$MyQMRootPath(.*)/g || uc($MyPath) =~ /$MyRootPath(.*)/g)
	{
		$MyRelativePath = $1;
	}
	else
	{
		$MyRelativePath = $MyPath;
		&REPORT(1,"Le chemin '$MyPath' ne contient pas la racine '$MyRootPath' (ni '$MyQMRootPath')");
	}
	
	# Renvoi du resultat
	return $MyRelativePath;
}

####################################################################################################

sub LTrim
{
# Retire les ' ' et <tab> en debut de chaine
	my ($MySource) = @_;
	$MySource =~ s/^[ \t]+//gio;
	return $MySource;
}

####################################################################################################

sub RTrim
{
# Retire les ' ' et <tab> en fin de chaine
	my ($MySource) = @_;
	$MySource =~ s/[ \t]+$//gio;
	return $MySource;
}

####################################################################################################

sub Trim
{
# Retire les ' ' et <tab> en debut et fin de chaine
	my ($MySource) = @_;
	return &LTrim(&RTrim($MySource));
}

####################################################################################################

sub NChar
{
# Renvoi une chaine de n fois le caractere C
	my ($MyChar,$MyNum) = @_;
	my $MyResult = "";
	
	my $i=1;
	while ($i <= $MyNum)
	{
		$MyResult = $MyResult.$MyChar;
		$i++
	}
	
	return $MyResult;
}

####################################################################################################

sub PTrim
{
# Retire les '\' et '/' en debut et fin de chaine
	my ($MyPath) = @_;
	$MyPath =~ s/^[\\\/]+//gio;
	$MyPath =~ s/[\\\/]+$//gio;
	return $MyPath;
}

####################################################################################################

sub Tokenize2
{
# Exemple :
#
#$Text = "Bonjour tout \(le \(monde\) du\) \(petit village\) dans les nuages";
#
#@Token_List = ();
#&Tokenize($Text, " ", "\(", "\)", \@Token_List);
#
#foreach $Token(@Token_List)
#{
#	print $Token."\n";
#}

	# Recuperation des parametres
	my ($MyText,$MySeparatorChar,$MyOpenChar,$MyCloseChar,$listPointer) = @_;
	
	my $S = index($MyText,$MySeparatorChar);
	my $O = index($MyText,$MyOpenChar);
	my $C = &CloseIndex($MyText,$O,$MyOpenChar,$MyCloseChar);

	my $i = 0;

	while ($S > -1 && $i < 10)
	{
		if ($S < $O && $S < $C)
		{
			$SubText = substr($MyText,0,$S);
			push(@$listPointer,$SubText);

			$MyText = substr($MyText,$S + 1);

			$S = index($MyText,$MySeparatorChar);
			$O = index($MyText,$MyOpenChar);
			$C = &CloseIndex($MyText,$O,$MyOpenChar,$MyCloseChar);
		}
		elsif ($S > $O && $S < $C)
		{
			$S = index($MyText,$MySeparatorChar,$S + 1);
		}
		elsif ($S > $O && $S > $C)
		{
			$SubText = substr($MyText,0,$S);
			push(@$listPointer,$SubText);

			$MyText = substr($MyText,$S + 1);

			$S = index($MyText,$MySeparatorChar);
			$O = index($MyText,$MyOpenChar);
			$C = &CloseIndex($MyText,$O,$MyOpenChar,$MyCloseChar);
		}
		
		$i++;
	}
	
	if (length($MyText) > 0)
	{
		$SubText = $MyText;
		push(@$listPointer,$SubText);
		
		$MyText="";
	}
}

####################################################################################################

sub CloseIndex
{
	my ($MyText,$MyOpenIndex,$MyOpenChar,$MyCloseChar) = @_;
	
	my $MyI=$MyOpenIndex;
	my $MyNb = 1;
	
	while ($MyI < length($MyText) && $MyNb > 0)
	{
		$MyI++;
		
		my $MyChar = substr($MyText,$MyI,1);
		
		if ($MyChar eq $MyOpenChar)
		{
			$MyNb++;
		}
		elsif ($MyChar eq $MyCloseChar)
		{
			$MyNb--;
		}
		
	}

	return $MyI;
}

####################################################################################################

sub REPORT
{
	if (@_ == 1)
	{
		my ($MyMessage) = @_;
		
		print REPORT_OUT_FILE "$MyMessage\n";
	}
	elsif (@_ == 2)
	{
		my ($MySeverity,$MyMessage) = @_;
		
		if ($MySeverity eq "D" && $Debug)
		{
			print REPORT_OUT_FILE "DBG : $MyMessage\n";
		}
		elsif ($MySeverity eq 0)
		{
			print REPORT_OUT_FILE "   $MyMessage\n";
		}
		elsif ($MySeverity eq 1)
		{
			print REPORT_OUT_FILE "--> WARNING : $MyMessage\n";
		}
		elsif ($MySeverity eq 2)
		{
			print REPORT_OUT_FILE "==> SEVERE WARNING : $MyMessage\n";
		}
		elsif ($MySeverity eq 3)
		{
			print REPORT_OUT_FILE ">>> ERROR : $MyMessage\n";
		}
		
	}
	else
	{
		my ($MyMessage) = @_;
		print REPORT_OUT_FILE ">>> ERROR : Bad parameters for REPORT function!\n";
		die();
	}
	
	
}

####################################################################################################

sub Footer
{
	print "\n";
	print "==================================================\n";
	print "End of process\n";
	print "==================================================\n";
	print "\n";
}

####################################################################################################
####################################################################################################
sub Splitter
{
	my ( $SplitFileName ) = @_;
	print "Split File Name $SplitFileName\n";
	open ORIGINAL_FILE, "<$SplitFileName" or die $!;
	
	$myFileLength = 0;
	$myFileSuffix  = 1;
	my $myCurrFileName = $SplitFileName.'_ComPart_'.$myFileSuffix  ;
	#print "Current File Name $myCurrFileName\n";
	open CURRENT_FILE , ">$myCurrFileName" or die $!;
	while(<ORIGINAL_FILE>)
	{
	if ($myFileLength<100)
	{
		$myFileLength = $myFileLength + 1;
		print CURRENT_FILE $_;
	}
	else
	{
	print CURRENT_FILE $_;
	$myFileLength = 0;		
	close CURRENT_FILE;
	$myFileSuffix = $myFileSuffix + 1;
	$myCurrFileName = $SplitFileName.'_ComPart_'.$myFileSuffix;

	open CURRENT_FILE, "+>$myCurrFileName" or die $!;
	#print "Current File Name $myCurrFileName\n";
	}
	}
	close CURRENT_FILE;
	close ORIGINAL_FILE;


}
__END__
:endofperl                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        