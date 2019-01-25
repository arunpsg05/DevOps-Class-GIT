#!/bin/bash

#'''
#
#   Gets App, JDK, WLS, DB Version & Release date Factor Sript
#   version v1.0
#   Author : arun.rb@oracle.com
#   Date: 1/17vma/2019
#
#'''

##################  VARIABLE DECLARATION #############################

    DB_SID=`cat /etc/passwd | grep Database | awk -F: '{print $1}' | sed 's|or\(.*\)|\1|'`
  DB_SID_U=`cat /etc/passwd | grep Database | awk -F: '{print toupper($1)}' | sed 's|\(.*\)|\1|' | cut -c 3-`
   APP_SID=`cat /etc/passwd | grep fmw | grep ia | awk -F: '{print $1}' | sed 's|ia\(.*\)|\1|'`
  APP_USER=`cat /etc/passwd | grep fmw | grep ia | awk -F: '{print $1}'`
APP_PREFIX=`cat /etc/passwd | grep fmw | grep ia | awk -F: '{print $1}' | sed 's|ia[a-z]\(.*\)0c0|\1|'`

##################  VARIABLE DECLARATION #############################

function Get_DB_Version(){

    DB_SID=`cat /etc/passwd | grep Database | awk -F: '{print $1}' | sed 's|or\(.*\)|\1|'`
    DB_SID_U=`cat /etc/passwd | grep Database | awk -F: '{print toupper($1)}' | sed 's|\(.*\)|\1|' | cut -c 3-`
    
    if [ -f /$DB_SID/oracle/.profile ]; then
        source ~/.profile 2> /dev/null
    elif [ -f /$DB_SID/oracle/.bashrc ]; then
        source ~/.bashrc  2> /dev/null  
    fi
    
    if [[ "$DB_SID" =~  ^"tz"* || "$DB_SID" =~  ^"sz"* || "$DB_SID" =~  ^"dz"* || "$DB_SID" =~  ^"uz"* || "$DB_SID" =~  ^"vz"* ]] ; then
        
        #DB_Version="echo $(basename /$DB_SID/oracle/app/"or$DB_SID"/product/)"
        DB_HOME="/$DB_SID/oracle/app/"or$DB_SID"/product/11.2.0/dbhome_1"
        if [ ! -d "$DB_HOME" ]; then
            DB_HOME="/$DB_SID/oracle/product/11204"
        fi
    else    
        DB_HOME="/$DB_SID/oracle/product/11204"
        if [ ! -d "$DB_HOME" ]; then
           DB_HOME="/$DB_SID/oracle/app/"or$DB_SID"/product/11.2.0/dbhome_1"
        fi        
    fi

    if [ -z "$ORACLE_HOME" ]; then
          export ORACLE_HOME=$DB_HOME
          export ORACLE_SID=$DB_SID
          export PATH=$ORACLE_HOME/bin:$PATH
          export ORACLE_LIB=$ORACLE_HOME/lib
    fi
    
    if [ -f "$ORACLE_HOME/OPatch/opatch" ]; then
    
        PATCH_ID=`$ORACLE_HOME/OPatch/opatch lspatches | grep "Database" | awk -F\; '{print $2}' | awk -F: '{print $2}' | sed 's/^[ \t\r]*//' | sed 's/[ \t\r]*$//' | sed '/^\s*$/d' | awk '{print $2}' | sed 's|(\(.*\))|\1|'`

        PATCH_DATE_VERSION=`$ORACLE_HOME/OPatch/opatch lspatches | grep "Database" | awk -F\; '{print $2}' | awk -F: '{print $2}' | sed 's|<.*\ host="\(.*\)"\ \/>|\1|' | sed 's/^[ \t\r]*//' | sed 's/[ \t\r]*$//' | sed '/^\s*$/d' | awk '{print $1}'`
    else
        PATCH_ID=""
        PATCH_DATE_VERSION=""
    fi

    if [ ! -z "$PATCH_DATE_VERSION" ] && [ ! -z "$PATCH_ID" ]; then

            PATCH_DATE=`echo ${PATCH_DATE_VERSION//*.}`
            PATCH_DATE=`date -d $PATCH_DATE +%b%Y`

            DB_PATCH_REL_DATE=$PATCH_DATE" PSU"
            PATCH_VERSION=`echo ${PATCH_DATE_VERSION%.*}`
            DB_PATCH_VERSION="Patch ID:"$PATCH_ID";DB Version:"$PATCH_VERSION
    else
            DB_PATCH_VERSION="NA"
            DB_PATCH_REL_DATE="NA"
    fi
    
    echo -e "APP_DB_VERSION_INFO={ 'AppVersion': 'NA', 'JDKVersion': 'NA', 'WLSPatchVersion': 'NA', 'WLSPatchRel': 'NA', 'DB_Version': '$DB_PATCH_VERSION', 'DBPatchRel': '$DB_PATCH_REL_DATE' }"
        
}

function GET_APP_JDK_WLS_Version(){   #APP HOST
        
       APP_SID=`cat /etc/passwd | grep fmw | grep ia | awk -F: '{print $1}' | sed 's|ia\(.*\)|\1|'`
      APP_USER=`cat /etc/passwd | grep fmw | grep ia | awk -F: '{print $1}'`
    APP_PREFIX=`cat /etc/passwd | grep fmw | grep ia | awk -F: '{print $1}' | sed 's|ia[a-z]\(.*\)0c0|\1|'`
    
    if [ -f /$APP_SID/fmw/.bashrc ]; then
        source ~/.bashrc
    else
        exit 1
    fi

    if [ -h "/$APP_SID/fmw/java" ]; then
       jdk_version=`java -version 2>&1|awk '/version/ {gsub("\"","") ; print $3}'`
    else
       jdk_version="NA"
    fi

    # Weblogic Latest Patch & Version

    #machine_to_run=`cat $BIN_PATH/environment-config.xml | grep "weblogic-admin-server" | sed 's|<.*\ host="\(.*\)"\ \/>|\1|' | sed 's/^[ \t\r]*//' | sed 's/[ \t\r]*$//' | sed '/^\s*$/d'`

    if [[ "$APP_SID" =~  ^"tz"* || "$APP_SID" =~  ^"sz"* || "$APP_SID" =~  ^"dz"* || "$APP_SID" =~  ^"uz"* || "$APP_SID" =~  ^"vz"* ]] ; then
        if [ "$APP_SID" == "szdta0c0" ]; then
            storeInstance="stage_store1a"
        else
            storeInstance="test_store1b"
        fi
    else
        storeInstance="prod1a"
    fi

    APP_VERSION=`grep -Po "oracleCommerceCloudVersion=.*" /$APP_SID/admin/user_projects/occsdomain/servers/$storeInstance/stage/current/CloudCommerce-Store-Weblogic.ear/atg_bootstrap.war/WEB-INF/ATG-INF/CC/config/atg/dynamo/service/VersionService.properties | awk -F= '{print $2}'` 2> /dev/null

    if [ -z "$APP_VERSION" ]; then
        APP_VERSION="NA"
    fi

    # check if Middleware is set
    IS_MW_HOME_SET=`printenv | grep MW_HOME | wc -l`
    
    if [ $IS_MW_HOME_SET -gt 0 ]; then
      if [ -d "$MW_HOME" ]; then
         if [ -f "$MW_HOME/OPatch/opatch" ]; then
            wls_patch_count=`$MW_HOME/OPatch/opatch lspatches | grep "WLS PATCH SET UPDATE" | wc -l`
            if [ $wls_patch_count -gt 0 ]; then
                wls_patch=`$MW_HOME/OPatch/opatch lspatches | grep "WLS PATCH SET UPDATE"`
                patch_date=`echo ${wls_patch//*.}`
                patch_date=`date -d $patch_date +%b%Y`
                patch_date=$patch_date" CPU"
            else
                wls_patch="NoMain-Patch-listed-but-installed-with-several-One-off-patches"
                patch_date="NA"
            fi
         else
            wls_patch="NA-(No opatch file)"
            patch_date="NA"
         fi        
         #echo -e "$APP_SID,$host,$APP_VERSION,$jdk_version,$wls_patch,$patch_date,,"
         echo -e "APP_DB_VERSION_INFO={ 'AppVersion': '$APP_VERSION', 'JDKVersion': '$jdk_version', 'WLSPatchVersion': '$wls_patch', 'WLSPatchRel': '$patch_date', 'DB_Version': 'NA', 'DBPatchRel': 'NA' }"
      else
         #echo -e "$APP_SID,$host,$APP_VERSION,$jdk_version,NA,NA,,"
         echo -e "APP_DB_VERSION_INFO={ 'AppVersion': '$APP_VERSION', 'JDKVersion': '$jdk_version', 'WLSPatchVersion': 'NA', 'WSLPatchRel': 'NA', 'DB_Version': 'NA', 'DBPatchRel': 'NA' }"
      fi
    else
        #echo -e "$APP_SID,$host,$APP_VERSION,$jdk_version,NA,NA,,"
        echo -e "APP_DB_VERSION_INFO={ 'AppVersion': '$APP_VERSION', 'JDKVersion': '$jdk_version', 'WLSPatchVersion': 'NA', 'WSLPatchRel': 'NA', 'DB_Version': 'NA', 'DBPatchRel': 'NA' }"
    fi
}

# Check if more than one script is running 

host=`uname -n`

if [[ "$host" =~ ^"vmatgz".* ]]; then
    if [ -f /etc/mtab ]; then
    
        IS_DB_MOUNT=`cat /etc/mtab | awk '{print $2}' | grep -E '(oracle|oradata|arch)' | wc -l`

        if [ $IS_DB_MOUNT -gt 0 ]; then  # It is DB BOX

            running_count=`ps -ef | grep -v grep | grep Get_DB_Version | wc -l`

            if [ $running_count -eq 0 ] ; then
                export -f Get_DB_Version    # Export function globally so other users can use
                timeout 120 su -s /bin/bash "or$DB_SID" -c Get_DB_Version 2> /dev/null
                RET_VAL=$?
                if [ $RET_VAL -ne 0 ]; then
                    if [ $RET_VAL -eq 124 ]; then
                        echo -e "APP_DB_VERSION_INFO=Script_TimedOut"
                        exit 1
                    else
                        echo -e "APP_DB_VERSION_INFO=Script_Failed_For_Possible_Reason_Like_CommandsFailure"
                        exit 1                
                    fi
                fi
            else
                exit 0
            fi
        else
            running_count=`ps -ef | grep -v grep | grep GET_APP_JDK_WLS_Version | wc -l`
            if [ $running_count -eq 0 ] ; then
                export -f GET_APP_JDK_WLS_Version   # Export function globally so other users can use
                timeout 120 su -s /bin/bash "ia$APP_SID" -c GET_APP_JDK_WLS_Version 2> /dev/null
                RET_VAL=$?
                if [ $RET_VAL -ne 0 ]; then
                    if [ $RET_VAL -eq 124 ]; then
                        echo -e "APP_DB_VERSION_INFO=Script_TimedOut"
                        exit 1
                    elif [ $RET_VAL -eq 1 ]; then
                        echo -e "APP_DB_VERSION_INFO=NO_BASH_PROFILE"
                        exit 1
                    else
                        echo -e "APP_DB_VERSION_INFO=Script_Failed_For_Possible_Reason_Like_CommandsFailure"
                        exit 1            
                    fi
                fi
            else
                exit 0
            fi
        fi
    else
        echo -e "APP_DB_VERSION_INFO=No-Mount-File"
        exit 1
    fi
else
    exit 0
fi