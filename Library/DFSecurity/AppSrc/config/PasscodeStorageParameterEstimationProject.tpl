//************************************************************************************************//
//* Tool for determining optimal passcode storage parameters.
//************************************************************************************************//
Use cApplication.pkg
Use GlobalFunctionsProcedures.pkg
Use Dfpanel.pkg
Use Dfspnfrm.pkg
Use cCJGrid.pkg

Object oApplication is a cApplication
    Set pbPreserveEnvironment to False
    Set peHelpType to htNoHelp
End_Object

// Disable any of the lines below if the library is not used in your workspace.
//Use DFSecurity_CNG.pkg
Use DFSecurity_LibSodium.pkg

#IFNDEF C_MiB
Define C_MiB for (1024*1024)
#ENDIF

{ ClassType=Abstract }
{ Visibility=Private }
Class cPwhashParamOptimizer is a cObject

    Procedure Construct_Object
        Forward Send Construct_Object

        Property Handle  phoLogObject
        Property Integer piHashImplementation
    End_Procedure

    { Visibility=Private }
    Function HashTime Integer iOps Integer iMemBytes Returns Integer
        Handle  hoPasscodeStore
        Integer iMilliSecs iMSStart iMSEnd
        String  sResult
        UChar[] ucaPasscode

        Move (StringToUCharArray("Correct Horse Battery Staple")) to ucaPasscode

        Get Create (RefClass(cSecurePasscodeStorageMethod)) to hoPasscodeStore
        Set piPasscodeHashImplementation of hoPasscodeStore to (piHashImplementation(Self))
        Set piMemLimit of hoPasscodeStore to iMemBytes
        Set piOpsLimit of hoPasscodeStore to iOps
        Send Initialize of hoPasscodeStore

        Move (GetTickCount()) to iMSStart
        Get StorageString of hoPasscodeStore (&ucaPasscode) to sResult
        Move (GetTickCount()) to iMSEnd

        Move (iMSEnd - iMSStart) to iMilliSecs
        Send Log iOps iMemBytes iMilliSecs

        Function_Return iMilliSecs
    End_Function

    { Visibility=Private }
    Procedure Log Integer iOps Integer iMemBytes Integer iMilliSecs
        Handle hoLog
        Get phoLogObject to hoLog
        If (hoLog <> 0) Send Log of hoLog iOps iMemBytes iMilliSecs
    End_Procedure

    { MethodType=Event }
    Procedure OnFinished Integer iOps Integer iMemBytes
    End_Procedure

    { Visibility=Private }
    Procedure Reset
    End_Procedure

    { Visibility=Private }
    Function AdjustParams Integer ByRef iOps Integer ByRef iMemBytes Integer iMilliSecs Integer iTargetMilliSecs Returns Boolean
        Function_Return False
    End_Function

    Procedure Start Integer iMemLimit Integer iTargetMilliSecs
        Boolean bAdjusted
        Integer iMemBytes
        Integer iMilliSecs
        Integer iOps

        Send Reset

        Move iMemLimit to iMemBytes
        Get InitialOpsLimit iMemBytes to iOps

        Move True to bAdjusted
        While (bAdjusted and iMilliSecs <> iTargetMilliSecs)
            Get HashTime iOps iMemBytes to iMilliSecs
            Get AdjustParams (&iOps) (&iMemBytes) iMilliSecs iTargetMilliSecs to bAdjusted
        Loop

        Send OnFinished iOps iMemBytes
    End_Procedure

End_Class

Class cPwhashParamOptimizerArgon2i is a cPwhashParamOptimizer

    Procedure Construct_Object
        Forward Send Construct_Object

        Property Integer piPhase 0
        Property Integer piDiffMem 0

        Set piHashImplementation to C_SEC_PWHASH_LIBSODIUM_ARGON2I
    End_Procedure

    Procedure Reset
        Set piPhase to 0
    End_Procedure

    Function InitialOpsLimit Integer iMemBytes Returns Integer
        Function_Return 3
    End_Function

    Function AdjustParams Integer ByRef iOps Integer ByRef iMemBytes Integer iMilliSecs Integer iTargetMilliSecs Returns Boolean
        Boolean bAdjusted
        Integer iDiffMem
        Integer iNewMem
        Integer iNewOps
        Integer iPhase

        Get piPhase to iPhase
        If (iPhase = 0) Begin
            Move (If(iMilliSecs < iTargetMilliSecs, 1, 2)) to iPhase
            Set piPhase to iPhase
        End

        If (iPhase = 1) Begin
            // increase opslimit - one-time estimate
            If (iMilliSecs < iTargetMilliSecs and (Number(iTargetMilliSecs) / Number(iMilliSecs) > 1.05)) Begin
                Move True to bAdjusted
                Move (Number(iTargetMilliSecs) / Number(iMilliSecs) * iOps) to iNewOps
                If (iNewOps <= iOps) Increment iOps
                Else Move iNewOps to iOps
            End
            Else Begin
                Move 2 to iPhase
                Set piPhase to iPhase
            End
        End

        If (iPhase = 2) Begin
            // increase opslimit
            If (iMilliSecs < iTargetMilliSecs) Begin
                Move True to bAdjusted
                Increment iOps
            End
            Else Begin
                Move 3 to iPhase
                Set piPhase to iPhase
            End
        End

        If (iPhase = 3) Begin
            // adjust iMemBytes - we use MiB units here
            Move (iMemBytes / C_MiB) to iNewMem

            Move (Number(iTargetMilliSecs) / Number(iMilliSecs) * iNewMem) to iNewMem
            Move (iNewMem - iMemBytes) to iDiffMem
            Set piDiffMem to iDiffMem

            Move (iNewMem * C_MiB) to iNewMem

            If (iDiffMem <> 0) Begin
                Move True to bAdjusted
                Move iNewMem to iMemBytes
            End
        End

        Function_Return bAdjusted
    End_Function

End_Class

Class cPwhashParamOptimizerSCrypt is a cPwhashParamOptimizer

    Procedure Construct_Object
        Forward Send Construct_Object

        Set piHashImplementation to C_SEC_PWHASH_LIBSODIUM_SCRYPT
    End_Procedure

    Procedure Reset
    End_Procedure

    Function InitialOpsLimit Integer iMemBytes Returns Integer
        Function_Return (iMemBytes / 32)
    End_Function

    Function AdjustParams Integer ByRef iOps Integer ByRef iMemBytes Integer iMilliSecs Integer iTargetMilliSecs Returns Boolean
        Boolean bAdjusted

        Function_Return bAdjusted
    End_Function

End_Class

//Class cPwhashParamOptimizerPbkdf2sha1 is a cPwhashParamOptimizer
//
//    Procedure Construct_Object
//        Forward Send Construct_Object
//
//        Set piHashImplementation to C_SEC_PWHASH_CNG_PBKDF2_SHA1
//    End_Procedure
//
//    Procedure Reset
//    End_Procedure
//
//    Function InitialOpsLimit Integer iMemBytes Returns Integer
//        Function_Return (iMemBytes / 32)
//    End_Function
//
//    Function AdjustParams Integer ByRef iOps Integer ByRef iMemBytes Integer iMilliSecs Integer iTargetMilliSecs Returns Boolean
//        Boolean bAdjusted
//
//        Function_Return bAdjusted
//    End_Function
//
//End_Class

//Class cPwhashParamOptimizerPbkdf2sha256 is a cPwhashParamOptimizer
//
//    Procedure Construct_Object
//        Forward Send Construct_Object
//
//        Set piHashImplementation to C_SEC_PWHASH_CNG_PBKDF2_SHA256
//    End_Procedure
//
//    Procedure Reset
//    End_Procedure
//
//    Function InitialOpsLimit Integer iMemBytes Returns Integer
//        Function_Return (iMemBytes / 32)
//    End_Function
//
//    Function AdjustParams Integer ByRef iOps Integer ByRef iMemBytes Integer iMilliSecs Integer iTargetMilliSecs Returns Boolean
//        Boolean bAdjusted
//
//        Function_Return bAdjusted
//    End_Function
//
//End_Class

Struct tMEMORYSTATUSEX
    UInteger dwLength
    UInteger dwMemoryLoad
    UBigInt  ullTotalPhys
    UBigInt  ullAvailPhys
    UBigInt  ullTotalPageFile
    UBigInt  ullAvailPageFile
    UBigInt  ullTotalVirtual
    UBigInt  ullAvailVirtual
    UBigInt  ullAvailExtendedVirtual
End_Struct

Struct tSYSTEM_INFO
//  union {
//    DWORD  dwOemId;
//    Struct {
    UShort  wProcessorArchitecture
    UShort  wReserved
//    };
//  };
    UInteger dwPageSize
    Pointer  lpMinimumApplicationAddress
    Pointer  lpMaximumApplicationAddress
    ULongptr dwActiveProcessorMask
    UInteger dwNumberOfProcessors
    UInteger dwProcessorType
    UInteger dwAllocationGranularity
    UShort   wProcessorLevel
    UShort   wProcessorRevision
End_Struct

External_Function GetSystemInfo "GetSystemInfo" kernel32.dll;
    Pointer lpSystemInfo;
    Returns Void_Type

External_Function GlobalMemoryStatusEx "GlobalMemoryStatusEx" kernel32.dll;
    Pointer lpBuffer;
    Returns Boolean

// Trick DataFlex Studio to allow placement of controls on a panel.
{ DesignerClass = cDTView }
Class cMainPanel is a Panel
End_Class

// Panel for the application which is an SDI style application
Object oMain is a cMainPanel
    Set Label to "Determine optimal passcode storage parameters"
    Set Location to 4 3
    Set Size to 300 275
    Set piMaxSize to 750 275
    Set piMinSize to 250 275

    Object oTabs is a TabDialog
        Set Location to 0 0
        Set Size to 280 265

        Object oTabPageArgon2i is a TabPage
            Set Label to "Argon2i"

            Object oMemLimitStart is a SpinForm
                Set Location to 5 155
                Set Size to 13 100
                Set Label to "Max. memory per call (MiB):"
                Set Label_Col_Offset to 150
                Set peAnchors to anTopLeftRight
                Set Minimum_Position to 1               // less than 1 MiB is undesirable
                Set Maximum_Position to (1024 * 1024)   // 1 GiB is a reasonable maximum for 32-bits DataFlex...
                Set Value to (crypto_pwhash_argon2i_MEMLIMIT_MODERATE / C_MiB)
            End_Object

            Object oHashTimeTarget is a SpinForm
                Set Location to 23 155
                Set Size to 13 100
                Set Label to "Desired time (10th of sec):"
                Set Label_Col_Offset to 150
                Set peAnchors to anTopLeftRight
                Set Minimum_Position to 5       // less than 0.5 second is undesirable
                Set Maximum_Position to 600     // 1 minute should always be enough - if not, change this and recompile...
                Set Value to 10
            End_Object

            Object oCalculateButton is a Button
                Set Location to 41 155
                Set Size to 14 100
                Set Label to "Determine parameters"
                Set peAnchors to anTopLeftRight

                Procedure OnClick
                    Integer iMem
                    Integer iTime

                    Set Enabled_State to False
                    Send ClearGrid of oLog

                    Get Value of oMemLimitStart to iMem
                    Get Value of oHashTimeTarget to iTime
                    Send Start of oOptimizer (iMem * C_MiB) (iTime * 100)
                End_Procedure
            End_Object

            Object oLog is a cCJGrid
                Set Location to 60 5
                Set Size to 200 250
                Set peAnchors to anAll
                Set pbRestoreLayout to False
                Set pbAllowInsertRow to False
                Set pbAllowAppendRow to False
                Set pbAllowColumnRemove to False
                Set pbAllowColumnReorder to False
                Set pbAllowDeleteRow to False
                Set pbAutoColumnSizing to True

                Object oCol1 is a cCJGridColumn
                    Set piWidth to 70
                    Set psCaption to "ops"
                    Set peTextAlignment to xtpAlignmentRight
                    Set peDataType to Mask_Numeric_Window
                    Set psMask to "0*"
                    Set pbEditable to False
                End_Object
                
                Object oCol2 is a cCJGridColumn
                    Set piWidth to 75
                    Set psCaption to "mem (MiB)"
                    Set peTextAlignment to xtpAlignmentRight
                    Set peDataType to Mask_Numeric_Window
                    Set psMask to "0*"
                    Set pbEditable to False
                End_Object

                Object oCol3 is a cCJGridColumn
                    Set piWidth to 75
                    Set psCaption to "time (s)"
                    Set peTextAlignment to xtpAlignmentRight
                    Set peDataType to Mask_Numeric_Window
                    Set psMask to "0*.000"
                    Set pbEditable to False
                End_Object

                Procedure Log Integer iOps Integer iMemBytes Integer iMilliSecs
                    tDataSourceRow[] tGridData
                    Handle  hoDataSource
                    Integer iRows
                    
                    Get phoDataSource to hoDataSource
                    Get DataSource of hoDataSource to tGridData
                    Move (SizeOfArray(tGridData)) to iRows

                    Move iOps to tGridData[iRows].sValue[0]
                    Move (iMemBytes / C_MiB) to tGridData[iRows].sValue[1]
                    Move (iMilliSecs / 1000.) to tGridData[iRows].sValue[2]

                    Send InitializeData tGridData
                    Send MoveToFirstRow
                End_Procedure
                
                Procedure ClearGrid
                    tDataSourceRow[] tGridData
                    Send InitializeData tGridData
                End_Procedure
            End_Object

            Object oOptimizer is a cPwhashParamOptimizerArgon2i
                Set phoLogObject to oLog

                Procedure OnFinished Integer iOps Integer iMemBytes
                    Set Enabled_State of oCalculateButton to True
                    Send Info_Box "Done"
                End_Procedure
            End_Object

            Procedure Initialize
                Integer iCores
                Integer iRAM
                tMEMORYSTATUSEX memstatus
                tSYSTEM_INFO info

                Move (SizeOfType(tMEMORYSTATUSEX)) to memstatus.dwLength

                Move (GetSystemInfo(AddressOf(info))) to gVoid
                Move (ShowLastError()) to gVoid
                Move (GlobalMemoryStatusEx(AddressOf(memstatus))) to gVoid
                Move (ShowLastError()) to gVoid

                Move info.dwNumberOfProcessors to iCores

                Move ((memstatus.ullAvailPhys / 1024 / 1024)) to iRAM

                // use the smallest value of (RAM/cores) and 1GiB
                If (gVoid = NO_ERROR) Set Value of oMemLimitStart to ((iRAM / iCores) min 1024)
            End_Procedure

            Send Initialize
        End_Object

        Object oTabPageSCrypt is a TabPage
            Set Label to "SCrypt"

            Object oMemLimitStart is a SpinForm
                Set Location to 5 155
                Set Size to 13 100
                Set Label to "Max. memory per call (MiB):"
                Set Label_Col_Offset to 150
                Set peAnchors to anTopLeftRight
                Set Minimum_Position to crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN
                Set Maximum_Position to (1024 * 1024)   // 1 GiB is a reasonable maximum for 32-bits DataFlex...
                Set Value to (crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE / C_MiB)
            End_Object

            Object oHashTimeTarget is a SpinForm
                Set Location to 23 155
                Set Size to 13 100
                Set Label to "Desired time (10th of sec):"
                Set Label_Col_Offset to 150
                Set peAnchors to anTopLeftRight
                Set Minimum_Position to 5       // less than 0.5 second is undesirable
                Set Maximum_Position to 600     // 1 minute should always be enough - if not, change this and recompile...
                Set Value to 10
            End_Object

            Object oCalculateButton is a Button
                Set Location to 41 155
                Set Size to 14 100
                Set Label to "Determine parameters"
                Set peAnchors to anTopLeftRight

                Procedure OnClick
                    Integer iMem
                    Integer iTime

                    Set Enabled_State to False
                    Send ClearGrid of oLog

                    Get Value of oMemLimitStart to iMem
                    Get Value of oHashTimeTarget to iTime
                    Send Start of oOptimizer (iMem * C_MiB) (iTime * 100)
                End_Procedure
            End_Object

            Object oLog is a cCJGrid
                Set Location to 60 5
                Set Size to 200 250
                Set peAnchors to anAll
                Set pbRestoreLayout to False
                Set pbAllowInsertRow to False
                Set pbAllowAppendRow to False
                Set pbAllowColumnRemove to False
                Set pbAllowColumnReorder to False
                Set pbAllowDeleteRow to False
                Set pbAutoColumnSizing to True

                Object oCol1 is a cCJGridColumn
                    Set piWidth to 70
                    Set psCaption to "ops"
                    Set peTextAlignment to xtpAlignmentRight
                    Set peDataType to Mask_Numeric_Window
                    Set psMask to "0*"
                    Set pbEditable to False
                End_Object
                
                Object oCol2 is a cCJGridColumn
                    Set piWidth to 75
                    Set psCaption to "mem (MiB)"
                    Set peTextAlignment to xtpAlignmentRight
                    Set peDataType to Mask_Numeric_Window
                    Set psMask to "0*"
                    Set pbEditable to False
                End_Object

                Object oCol3 is a cCJGridColumn
                    Set piWidth to 75
                    Set psCaption to "time (s)"
                    Set peTextAlignment to xtpAlignmentRight
                    Set peDataType to Mask_Numeric_Window
                    Set psMask to "0*.000"
                    Set pbEditable to False
                End_Object

                Procedure Log Integer iOps Integer iMemBytes Integer iMilliSecs
                    tDataSourceRow[] tGridData
                    Handle  hoDataSource
                    Integer iRows
                    
                    Get phoDataSource to hoDataSource
                    Get DataSource of hoDataSource to tGridData
                    Move (SizeOfArray(tGridData)) to iRows

                    Move iOps to tGridData[iRows].sValue[0]
                    Move (iMemBytes / C_MiB) to tGridData[iRows].sValue[1]
                    Move (iMilliSecs / 1000.) to tGridData[iRows].sValue[2]

                    Send InitializeData tGridData
                    Send MoveToFirstRow
                End_Procedure
                
                Procedure ClearGrid
                    tDataSourceRow[] tGridData
                    Send InitializeData tGridData
                End_Procedure
                
            End_Object

            Object oOptimizer is a cPwhashParamOptimizerSCrypt
                Set phoLogObject to oLog

                Procedure OnFinished Integer iOps Integer iMemBytes
                    Set Enabled_State of oCalculateButton to True
                    Send Info_Box "Done"
                End_Procedure
            End_Object

            Procedure Initialize
                Integer iCores
                Integer iRAM
                tMEMORYSTATUSEX memstatus
                tSYSTEM_INFO info

                Move (SizeOfType(tMEMORYSTATUSEX)) to memstatus.dwLength

                Move (GetSystemInfo(AddressOf(info))) to gVoid
                Move (ShowLastError()) to gVoid
                Move (GlobalMemoryStatusEx(AddressOf(memstatus))) to gVoid
                Move (ShowLastError()) to gVoid

                Move info.dwNumberOfProcessors to iCores

                Move ((memstatus.ullAvailPhys / 1024 / 1024)) to iRAM

                // use the smallest value of (RAM/cores) and 1GiB
                If (gVoid = NO_ERROR) Set Value of oMemLimitStart to ((iRAM / iCores) min 1024)
            End_Procedure

            Send Initialize
        End_Object
    End_Object

End_Object

Start_UI
