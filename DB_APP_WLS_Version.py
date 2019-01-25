#!/usr/bin/python

# ------------------------------------------------------------------
# author : arun.rb@oracle.com
# Version : v1.0
# Purpose : Factorizing the application specific data.
# ------------------------------------------------------------------

try:
    import platform
    import pwd
    import re,sys,os
    from subprocess import PIPE, Popen
    from datetime import datetime
except:
    print("APP_DB_VERSION_INFO=module_import_error")
    sys.exit()

# Variables
#-------------------------------
MTAB_FILE="/etc/mtab"

PASSWD_FILE="/etc/passwd"

osversion = list(platform.dist())[-2]

py_version = platform.sys.version_info[0]

host=platform.node()

orig_env_copy = os.environ.copy()
#--------------------------------

def Get_DB_Version(ORACLE_HOME):
        print("Inside DB")
        OPATCH_PATCH_DIR=ORACLE_HOME+"/Opatch/"
        OPATCH_FILE=OPATCH_PATCH_DIR+"opatch"
        if os.path.isdir(OPATCH_PATCH_DIR):
            os.chdir(OPATCH_PATCH_DIR)
            if os.path.isfile(OPATCH_FILE):
                patch_args = [OPATCH_FILE, 'lspatches']
                grep_args = ['grep', 'Database']
                process = Popen(patch_args,stdout=PIPE,stderr=PIPE)
                grep_process = Popen(grep_args, stdin=process.stdout,stdout=PIPE)
                out=grep_process.communicate()[0].strip().lstrip()
                if len(out) == 0:
                    print("APP_DB_VERSION_INFO=No Main Patch Set")
                    sys.exit(1)
                else:
                    
            else:
                print("APP_DB_VERSION_INFO=OPATCH_FILE_NOT_FOUND")    
                sys.exit(1)
        else:
            print("APP_DB_VERSION_INFO=OPATCH_DIR_NOT_FOUND")
            sys.exit(1)

def GET_APP_JDK_WLS_Version():
        print("Inside APP")

def Set_HOME(VM_TYPE,APP_SID):
    
    if VM_TYPE == "DB":
        if APP_SID.startswith( 'tz' ) or APP_SID.startswith( 'sz' ) or APP_SID.startswith( 'dz' ) or APP_SID.startswith( 'uz' ) or APP_SID.startswith( 'vz' ):
            # setting environment variable based on above environment type
            ORACLE_HOME="/"+APP_SID+"/oracle/app/or"+APP_SID+"/product/11.2.0/dbhome_1"
            if not os.path.exists(ORACLE_HOME):
                ORACLE_HOME="/"+APP_SID+"/oracle/product/11204"
                 
            if os.path.exists(ORACLE_HOME):
                return ORACLE_HOME
            else:
                return None
            
        elif APP_SID.startswith( 'pz' ):
            # setting environment variable based on above environment type
            ORACLE_HOME="/"+APP_SID+"/oracle/product/11204"
            
            if not os.path.exists(ORACLE_HOME):
                ORACLE_HOME="/"+APP_SID+"/oracle/app/or"+APP_SID+"/product/11.2.0/dbhome_1"
            
            if os.path.exists(ORACLE_HOME):
                return ORACLE_HOME        
            else:
                return None
            
def check_vm_type():

        APP_SID=""
        box_type=""
        if os.path.exists(MTAB_FILE) and os.path.isfile(MTAB_FILE):
            try:
                with open(MTAB_FILE, 'rb') as file:
                    list_of_mounts = '|'.join(line.strip().split(' ')[1] for line in file)

                    #string_list_of_list = '|'.join(list_of_list)

                    pattern = re.compile(r"[\/.*|]+\/.*0c0\/(oradata).*", re.IGNORECASE)

                    tenantID_pattern = re.compile(r"^.*/(.*0c0)/.*$" , re.IGNORECASE)

                    if py_version == 2:
                    
                        new_list = pattern.match(list_of_mounts)
                        if new_list == None:
                            pattern = re.compile(r"[\/.*|]+\/.*0c0\/(fmw).*", re.IGNORECASE)
                                                
                        APP_SID = tenantID_pattern.match(list_of_mounts)
                        
                    elif py_version == 3:
                        
                        new_list = list(filter(pattern.search, list_of_mounts))
                        
                        if new_list == None:
                            pattern = re.compile(r"[\/.*|]+\/.*0c0\/(fmw).*", re.IGNORECASE)
                            
                        APP_SID = list(filter(tenantID_pattern.search, list_of_mounts))
                        
                    if new_list != None:  # ( If specified pattern matches list of mounts and if oradata is present it is DB box)
                        
                        VM_TYPE = new_list.group(1).lower().strip()
                        list_count = len(VM_TYPE)
                        if list_count != 0:
                                box_type = "DB"
                                
                    else: # ( it could be app server since the pattern does not match server mounts so earlier new_list is empty)
                        if py_version == 2:
                            
                            new_list = pattern.match(list_of_mounts)
                        elif py_version == 3:                            
                            new_list = list(filter(pattern.search, list_of_mounts))
                            
                        if new_list != None:
                            VM_TYPE = new_list.group(1).lower().strip()
                            list_count = len(VM_TYPE)
                            if list_count != 0:                            
                                box_type = "APP"
                        else:
                            print("APP_DB_VERSION_INFO=Could_not_identify_vm_type")
                            sys.exit(1)

                    if APP_SID != None:
                        SID = APP_SID.group(1).lower().strip()
                        list_count = len(SID)
                        if list_count != 0:
                            return [SID,box_type]
                    else:
                        print("APP_DB_VERSION_INFO=SID_IS_INVALID")
                        sys.exit(1)
                        
            except IOError:
                print("APP_DB_VERSION_INFO=Cannot_Open_Mtab_File")
                sys.exit(1)
        else:
            print("APP_DB_VERSION_INFO=NO_MTAB_FILE")
            sys.exit(1)

if __name__ == "__main__":

    z = re.match(r'^vmatgz\w+',host)
    if z:
        APP_SID,vm_type = check_vm_type()       
        if APP_SID != None and vm_type != None:
            if vm_type == "DB":
                try:
                    ORACLE_HOME=orig_env_copy['ORACLE_HOME']
                    # Double check to see if the value is not null and it is a valid directory
                    if ORACLE_HOME is not None and os.path.isdir(ORACLE_HOME)
                        retValue = Get_DB_Version(ORACLE_HOME)
                        print(retValue)
                    elif ORACLE_HOME is None:
                        # Call a function to manually set ORACLE_HOME and see if it works
                        ORACLE_HOME=Set_HOME(vm_type,APP_SID)
                        if ORACLE_HOME is not None:
                            retValue = Get_DB_Version(ORACLE_HOME)
                            print(retValue)
                        else:
                            print("APP_DB_VERSION_INFO=ORACLE_HOME_SET_NOT_SET")
                            sys.exit(1)                       
                    elif not os.path.isdir(ORACLE_HOME)
                        #What if some one sets a wrong path for ORACLE_HOME , so we again manually set and see if it works
                        ORACLE_HOME=Set_HOME(vm_type,APP_SID)
                        if ORACLE_HOME is not None:
                            retValue = Get_DB_Version(ORACLE_HOME)
                            print(retValue)
                        else:
                            print("APP_DB_VERSION_INFO=ORACLE_HOME_SET_NOT_SET")
                            sys.exit(1)
                except KeyError:
                    # ORACLE_HOME is not set as environment variable
                    # Call a function to manually set ORACLE_HOME and see if it works
                    ORACLE_HOME=Set_HOME(vm_type,APP_SID)
                    if ORACLE_HOME is not None:
                        retValue = Get_DB_Version(ORACLE_HOME)
                        print(retValue)
                    else:
                        print("APP_DB_VERSION_INFO=ENV_VAR_NOT_SET_AND_ORACLE_HOME_SET_NOT_VALID")
                        sys.exit(1)
                    
            if vm_type == "APP":
                MW_HOME=orig_env_copy['MW_HOME']
                GET_APP_JDK_WLS_Version()
    else:
        print("NOT IN")
        print("Sample Change")
