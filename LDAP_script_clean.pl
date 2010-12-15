#!/iiidb/software/tpp/perl/bin/perl -w


use Net::LDAP;
use Net::LDAPS;
use strict;
use CGI qw(unescape);
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);

#
#-----------------------------------------------------------------------
# This perl script is provided as an example for libraries that want to
# employ Innovative's "plugin" model for External Patron Verification.
#
# The example script queries multiple LDAP servers depending on the type 
# of user, e.g. staff/faculty vs. student; campus1 vs. campus2; etc.
#
# This script is not intended to be "standalone" but is instead called by 
# the Innovative checkLDAP script.
#
# Innovative provides this example script as a courtesy to libraries that
# have multiple LDAP servers.  The library is responsible for customizing 
# this script with local values, enhanced functionality, etc. 
#-----------------------------------------------------------------------
#

my $debug = "yes";

open (DEBUG, ">>/tmp/checkLDAP_dlevy.log") if ($debug eq "yes");

#Variables to make them work outside of subroutines


my @m_sLDAPServer = ("","");
my @m_nPort = ("","");
my @m_bUseLDAPS = (0,0);
my @m_sBindBase = ("","");
my @m_sBindPassword = ("","");
my @m_sBindUser = ("","");
my @m_bUseOneBind = (0,0);
my @m_sSearchAttribute = ("","");
my @m_sSearchBase = ("","");
my @m_sIDAttribute = ("","");

my $m_bUseLDAPPassword = 1;
my $m_bTryMillenniumAfterBadVerify = 0;

my @m_nTimeOut = (3,3);
my $m_sLDAPVersion = 3;

#
#
# Input variables are stored in the following variables
#
my $m_sUserName = "";
my $m_sUserId = "";
my $m_sPassword = "";
my $m_sServer= "";

my $m_hLDAP;
my $m_whichServer = 0; #Identifies which server to query by index, either 0 or 1
my $m_hSearchMessage;
my $m_bVerbose = 0;
#my $m_bVerbose = 1;
my $m_nTimeOut = 3;


my $m_sOriginalUserId;
my $m_sResult = "Failed";
my $m_sLogMessage = "";
my $m_sIIIDB = "";


#
# LDAP connection information is stored in arrays of size 2.
# The script assumes that the first location (0) in the array 
# contains the connection information for the student LDAP server, 
# i.e. the input extpatserver = student, if  extpatserver = staff the
# script uses the connection information from the second location (1)
# in the following arrays.
# If there is no value in extpatserver, the script queryies the student
# LDAP server.
# These arrays should be initialized here with the real values.
# To customize this script for you system, configure the following 
# arrays:
#
# m_sLDAPServer : contains the host domain name of the LDAP servers.
#
# m_nPort :  specifies the port used to connect to the LDAP server.
#
# m_bUseLDAPS : set to 1 if you use a secure connection i.e. port 636, 
# 		set to 0 if you use a non-secure connection.
# m_sBindBase : contains a string that defines which database to use 
# 		on the LDAP server on the first bind command; 
#		if empty use anonymous bind.
#
# m_sBindPassword : contains the password of the administrator account 
#	      	   you use to bind. Set the password unencrypted, 
#		   i.e. use the string you received from the LDAP 
#		   adminstartor as it is.  
# m_sBindUser : set the login of the administartor account, or an empty string
#
# m_bUseOneBind: set to 1 if you use user's credentials to bind.
#
# m_sSearchAttribute : contains the primary search attribute to be used 
#		   (university ID, for example) when searching for 
#		   a given patron on the LDAP server.
#
# m_sSearchBase : contains the search DN used to retrieve user records.
#
# m_sIDAttribute : contains the attribute in the data returned by the LDAP
#                  server which is used as the patron search key on the
#		   Millennium server.	
#



sub domain {

if ($campus = param('campus') =~ m/domain/) 
{

&LDAP_CCSU;

	
} 

elsif ($campus = param('campus') =~ m/domain/) 
{


&LDAP_ECSU;

}

elsif ($campus = param('campus') =~ m/domain/) 
{


&LDAP_WCSU;


}

elsif ($campus = param('campus') =~ m/domain/) 
{


&LDAP_SCSU;


}

else {

print "Not a valid domain \n.";

}

}

sub LDAP_CCSU {
 @m_sLDAPServer = ("","");
 @m_nPort = ("","");
 @m_bUseLDAPS = ("1","");
 @m_sBindBase = ("","");
 @m_sBindPassword = ("","");
 @m_sBindUser = ("","");
 @m_bUseOneBind = ("1");
 @m_sSearchAttribute = ("","");
 @m_sSearchBase = ("search_base =, DC=,DC=","");
 @m_sIDAttribute = ("","");

}

sub LDAP_ECSU {
 @m_sLDAPServer = ("","");
 @m_nPort = ("","");
 @m_bUseLDAPS = ("1","");
 @m_sBindBase = ("BIND_BASE= dn=,dc=","");
 @m_sBindPassword = ("","");
 @m_sBindUser = ("","");
 @m_bUseOneBind = ("1");
 @m_sSearchAttribute = ("","");
 @m_sSearchBase = ("search_base =, DC=,DC=edu","");
 @m_sIDAttribute = ("","");

}

sub LDAP_WCSU {


 @m_sLDAPServer = ("","");
 @m_nPort = ("","");
 @m_bUseLDAPS = ("1","");
 @m_sBindBase = ("BIND_BASE= ","");
 @m_sBindPassword = ("","");
 @m_sBindUser = ("","");
 @m_bUseOneBind = ("1");
 @m_sSearchAttribute = ("","");
 @m_sSearchBase = ("","");
 @m_sIDAttribute = ("","");
}



sub LDAP_SCSU {

 @m_sLDAPServer = ("","");
 @m_nPort = ("","");
 @m_bUseLDAPS = ("1","");
 @m_sBindBase = ("BIND_BASE= ","");
 @m_sBindPassword = ("","");
 @m_sBindUser = ("","");
 @m_bUseOneBind = ("1");
 @m_sSearchAttribute = ("","");
 @m_sSearchBase = ("","");
 @m_sIDAttribute = ("","");
}




my $m_bUseLDAPPassword = 1;
my $m_bTryMillenniumAfterBadVerify = 0;

my @m_nTimeOut = (3,3);
my $m_sLDAPVersion = 3;




#------------------------------------------------------------
# log a message for each verification to $IIIDB/errlog/ldap.log
# append if is used to wrap log so it doesn't grow to big
#------------------------------------------------------------
sub logger
{
my $sMessage = shift;

my $sOutName = $m_sIIIDB . "/errlog/ldap.log";

if( ( -e "$sOutName" ) && ( -s "$sOutName" ) > 100000 )
    {
    rename( "$sOutName", "$sOutName.old" );
    system( "touch $sOutName" );
    }

open( OUT, ">>$sOutName" ) ||
    die( "Cannot appendf $sOutName\n" );

my ($nSec,$nMin,$nHr,$nDay,$nMonth,$nYear,$sRest) = localtime();

my $sDenseTime = sprintf "%4.4d%2.2d%2.2d%2.2d%2.2d%2.2d",
                $nYear + 1900, $nMonth + 1, $nDay, $nHr, $nMin, $nSec;
print OUT "$sDenseTime:$m_sOriginalUserId:$m_sUserId" .
          ":$m_sLogMessage:$sMessage\n";
if( $m_bVerbose )
    {
    print "$sDenseTime:$m_sOriginalUserId:$m_sUserId" .
              ":$m_sLogMessage:$sMessage\n";
    }
close( OUT );
}
#----------------------------------------------------------------
#
# Innovative checkLDAP script
# The Innovative Perl script sends the following name/value pairs
# via STDIN to this plugin script:
#
#    extpatid= is the patron ID number.
#
#    extpatpw= is the patron password.
#
#    extpatserver= indicates the patron's choice of 
#    "student" or "staff"
#
#----------------------------------------------------------------
sub parseInput
{
while( <> )
        {
        chomp;

        for( split /\&/ )
                {
                if( /^extpatname=(.*)/ )
                        {
                        $m_sUserName = unescape($1);
                        }
                elsif( /^extpatid=(.*)/ )
                        {
                        $m_sUserId = unescape($1);
                        }
                elsif( /^extpatpw=(.*)/ )
                        {
                        $m_sPassword = unescape($1);
                        }
                elsif( /^extpatserver=(.*)/ )
                        {
                        $m_sServer= unescape($1);
                        }
                elsif( /^campus=(.*)/ )
						{
    					$campus = unescape($1);
    					domain($campus);
						}
                }
        }
}
#---------------------------------------------------------------
#
# Open a connection to the LDAP server.
#
#---------------------------------------------------------------
sub doConnect
{
my      @aLDAPArgs;

push( @aLDAPArgs, $m_sLDAPServer[$m_whichServer] );
push( @aLDAPArgs, port => $m_nPort[$m_whichServer] );


if( $m_bUseLDAPS[$m_whichServer] )
    {
      $m_hLDAP = new Net::LDAPS( @aLDAPArgs ) ||
                 systemError( "Cannot create session, args=@aLDAPArgs" );
     }

else
    {

    $m_hLDAP = Net::LDAP->new( @aLDAPArgs ) ||
               systemError( "Cannot create session, args=@aLDAPArgs" );
     }

if( ! defined( $m_hLDAP ) )
     {
       systemError( "Bad return from LDAP->new with args=@aLDAPArgs" );
      }

if( $m_bVerbose )
        {
        print "LDAP connection established args=@aLDAPArgs\n";
        }

return 1;
}
#------------------------------------------------------------
sub doBind
{
#expects the following parameters
my $sBindBase = shift;
my $sBindUser = shift;
my $sBindPassword = shift;
my $sMessage = shift;
my $bReturnOnVerifyError = shift;

my @aBindArgs;
my $mesg;

if( $sBindBase ne "" )
    {
    push( @aBindArgs, dn => $sBindBase ) ;
    }
if( $sBindPassword ne "" )
    {
    push( @aBindArgs, password => $sBindPassword );
    }
if( $m_sLDAPVersion ne "" )
    {
    push( @aBindArgs, version => $m_sLDAPVersion );
    }

$mesg = $m_hLDAP->bind( @aBindArgs ) ||
     systemError("Failed to bind args=dn $sBindBase version $m_sLDAPVersion");

if( $m_bVerbose )
    {
    print "Bindargs = @aBindArgs\n";
    }

if( $mesg->code() )
    {
    if( $bReturnOnVerifyError )
        {
        return( 0 );
        }
    else
        {
        verifyError( "$sMessage:bind failed:mesg=" .
          "(". $mesg->code() . "),args=dn $sBindBase version $m_sLDAPVersion" );
        exit( 0 );
        }
    }
if( $m_bVerbose )
    {
    print "Bind succeeded\n";
    }
return( 1 );
}

#------------------------------------------------------------
# performs a search, if the count is not 1 and there exists
# a fallback search method try that.
#------------------------------------------------------------

sub doSearch
{
my @aSearchArgs;

push( @aSearchArgs, base => $m_sSearchBase[$m_whichServer] );
my $sFilter = "$m_sSearchAttribute[$m_whichServer]=$m_sUserId";
push( @aSearchArgs, filter => "$sFilter" );

alarm $m_nTimeOut;

$m_hSearchMessage = $m_hLDAP->search( @aSearchArgs ) ||
                     systemError ("Failed on search args=@aSearchArgs");


alarm 0;

if( $m_hSearchMessage->code() )
    {
    verifyError( "search failed mesg=" .
                 "(". $m_hSearchMessage->code() . "),args=@aSearchArgs" );
    return 0;
    }

if( $m_bVerbose )
    {
    printf( "Search done: args=@aSearchArgs\n" );
    }

my @aList = $m_hSearchMessage->all_entries;

my $nCount = $#aList + 1;

if( $m_bVerbose ) { print "Search found $nCount matching patrons\n"; }

return $nCount;
}

#------------------------------------------------------------
sub checkPassword
{
my $hEntry = shift;

if( $m_bUseLDAPPassword == 0 ) { return 1; }

my $sVerifyUserName = $m_sUserId;

if( ! doBind( $hEntry->dn(),
        $sVerifyUserName,
        $m_sPassword,
        "Bad password",
         $m_bTryMillenniumAfterBadVerify ) )
    {
    return( 0 );
    }

$m_sLogMessage .= "good password ";

if( $m_bVerbose )
    {
    print "Password check succeeded\n";
    }
return( 1 );
}

#------------------------------------------------------------
# verification has failed log and exit with string Error
#------------------------------------------------------------
sub verifyError
{
my $sMessage = shift;

$m_sUserId = "Error"; # this is the string we will return to the webpac
if( defined $m_hLDAP )
    {
    $m_hLDAP->unbind;
    }
logger( $sMessage );

print "extvererr=$sMessage\n";
}

#------------------------------------------------------------
# log an error message to the syserr file
#------------------------------------------------------------
sub logError
{
my $sMessage = shift;
my $sSyserr = $m_sIIIDB . "/errlog/syserr";
if( open( SYSERR, ">>$sSyserr" ) )
    {
    print SYSERR "$sMessage\n";
    close( SYSERR );
    }
}

#------------------------------------------------------------
# log an error message to the syserr file and exit with Error
#------------------------------------------------------------
sub systemError
{
my $sMessage = shift;

$m_sUserId = "Error"; # this is the string we will return to the webpac
if( defined $m_hLDAP )
    {
    $m_hLDAP->unbind;
    }
logger( "$sMessage ($!)" );
logError( "$sMessage ($!)" );

print "extsyserr=$sMessage\n";
exit 1;
}


#---------------------------------------------------------------
sub cleanUpAndExit
{
$m_hLDAP->unbind; # take down session
exit 0;
}
#---------------------------------------------------------------

sub notFound
{
my $sMessage = shift;

if( ! defined( $sMessage ) ) { $sMessage = "no message"; }
print "extvererr=$sMessage\n";
cleanUpAndExit();
}

#------------------------------------------------------------
# catches alarm, we set alarm so we don't wait forever for the ldap server
#------------------------------------------------------------
sub catchAlarm
{
logError( "Timeout occurred" );
}

#------------------------------------------------------------
#
#   main() starts here
#
# it is CRITICAL that nothing read stdin that will be done by
# parseInput after the globals are loaded and a user script
# has been ruled out
#
#------------------------------------------------------------
$SIG{ALRM} = \&catchAlarm;

parseInput();

 print DEBUG "The userID entered is: $m_sUserId\n" if ($debug eq "yes");


$m_sOriginalUserId = $m_sUserId;
if( $m_sPassword eq "" )
        {
        verifyError( "password not specified" );
        exit( 0 );
        }

if( $m_sUserId eq "" )
        {
        verifyError( "got empty lookup field" );
        exit( 0 );
        }

if( $m_sServer eq "staff" )
    {
	$m_whichServer = 1;
    }
else
	{
	$m_whichServer = 0;
	}

if( ! doConnect() )
    {
    exit 0;
    }

if( $m_bUseOneBind[$m_whichServer] )
    {
    my $sTempUserName = $m_sUserId;
	}


if( ! doBind($m_sBindBase[$m_whichServer], $m_sBindUser[$m_whichServer], 
     $m_sBindPassword[$m_whichServer] ,"",$m_bUseOneBind[$m_whichServer] ))
    {
    notFound( "no bind" );
    }

my $nMatchCount = doSearch();

if( $nMatchCount == 0 )
    {
    $m_sLogMessage .= "not on LDAP, ";
    notFound( "not found" );
    }
elsif( $nMatchCount == 1 )
    {
    $m_sLogMessage .= "on LDAP ";

    my @aList = $m_hSearchMessage->all_entries;
    my $hEntry = pop @aList;

    if( $m_bVerbose )
        {
        print "Entry dn= " . $hEntry->dn() . "\n";
        $hEntry->dump;
        }

    if( ! $m_bUseOneBind[$m_whichServer] && ! checkPassword( $hEntry ) )
        {
        $m_sLogMessage .= "failed password on LDAP, ";
        notFound( "failed password" );
        }
    else
        {
        my @sID = $hEntry->get_value( $m_sIDAttribute[$m_whichServer] );
        my $sID;

        if( ! @sID )
        {
        verifyError("Could not find attribute $m_sIDAttribute[$m_whichServer]");
            notFound( "no attribute" );
        }

        $sID = $sID[0];
        if( ! defined( $sID ) || $sID eq "" )
        {
        verifyError("Could not get attribute $m_sIDAttribute[$m_whichServer]");
            notFound( "no attribute" );
        }

        $m_sUserId = $sID;
        }
    }
else
    {
    $m_sLogMessage .= "many on LDAP ";

    verifyError( "$m_sUserId had $nMatchCount matches on LDAP server" );
    }

logger( "OK" );

print "extid=$m_sUserId\n";

cleanUpAndExit();

1;
