Use Windows.pkg
Use DFClient.pkg
Use File_dlg.pkg
Use cTextEdit.pkg

Use DFSecurity_CNG.pkg
Use DFSecurity_LibSodium.pkg
Use DFSecurity.pkg

Open PwnedPasswords

Deferred_View Activate_oPasscodePlayground for ;
Object oPasscodePlayground is a View

    Set Border_Style to Border_Thick
    Set Size to 122 395
    Set Location to 2 2
    Set Label to "Play with passcodes"
    Set pbDisableSaveEnvironment to True

    Object oNewPasscodeForm is a Form
        Set Size to 13 240
        Set Location to 5 65
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "New passcode:"
        Set FontPointHeight to 12
    End_Object

    Object oGenerateButton is a Button
        Set Size to 14 70
        Set Location to 25 156
        Set Label to 'StorageString'

        Procedure OnClick
            Send GenerateStorageString
        End_Procedure
    End_Object

    Object oCheckPwnedListButton is a Button
        Set Size to 14 70
        Set Location to 25 230
        Set Label to 'HaveIBeenPwned?'
        Set Visible_State to False

        Procedure OnClick
            Send CheckPwnedPasscode
        End_Procedure
    End_Object

    Object oPwnedFeedback is a cTextEdit
        Set Size to 14 50
        Set Location to 25 305
        Set TextColor to clWhite
        Set Visible_state to False
    End_Object

    Object oStorageStringForm is a Form
        Set Size to 13 240
        Set Location to 44 65
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "StorageString:"
        Set FontPointHeight to 12
    End_Object

    Object oVerifyPasscodeForm is a Form
        Set Size to 13 240
        Set Location to 63 65
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "Passcode to verify:"
        Set FontPointHeight to 12
    End_Object

    Object oVerifyButton is a Button
        Set Size to 14 50
        Set Location to 83 200
        Set Label to 'Verify'

        Procedure OnClick
            Send VerifyPasscode
        End_Procedure
    End_Object

    Object oVerifyFeedback is a cTextEdit
        Set Size to 14 50
        Set Location to 101 200
    End_Object

    Procedure GenerateData
    	Set Value of oNewPasscodeForm to "password"
    	Set Value of oStorageStringForm to ""
    	Set Value of oVerifyPasscodeForm to ""
    End_Procedure

    Procedure GenerateStorageString
		Handle  hoMethod
		String  sPlaintext
		String  sStorageString
		UChar[] ucaHash
		UChar[] ucaPasscode

		Get Value of oNewPasscodeForm to sPlaintext
		Move (StringToUCharArray(sPlaintext)) to ucaPasscode
		Send SecureStringOverwrite of ghoSecurity (&sPlaintext)

		Get CreateNamed (RefClass(cSecurePasscodeStorageMethod)) "MyMethod" to hoMethod
		Set piPasscodeHashImplementation of hoMethod to C_SEC_PWHASH_LIBSODIUM_ARGON2ID
		Set piOpsLimit of hoMethod to 3					// secure default
		Set piMemLimit of hoMethod to (64*1024*1024)	// 64 MiB
		Send Initialize of hoMethod

		Get StorageString of hoMethod (&ucaPasscode) to sStorageString
		Send Destroy of hoMethod

		Set Value of oStorageStringForm to sStorageString
    End_Procedure

    Object oSha1 is a cSecureHash
        Set piHashImplementation to C_SEC_HASH_CNG_SHA1
        Send Initialize
    End_Object

	Procedure CheckPwnedPasscode
		Integer iFrequency

		// ToDo: find passcode SHA1 in PwnedPasswords and set iFrequency

		Set Value of oPwnedFeedback to (If(iFrequency > 0, String(iFrequency), ""))
		Set Color of oPwnedFeedback to (If(iFrequency > 0, clRed, clLime))
 	End_Procedure

    Procedure VerifyPasscode
    	Boolean bIsValid
    	String  sPlaintext
    	String  sStorageString
    	UChar[] ucaPasscode

		Get Value of oVerifyPasscodeForm to sPlaintext
		Move (StringToUCharArray(sPlaintext)) to ucaPasscode
		Send SecureStringOverwrite of ghoSecurity (&sPlaintext)

		Get Value of oStorageStringForm to sStorageString

    	Get VerifyPasscode of ghoSecurity (&ucaPasscode) sStorageString to bIsValid
		Set Color of oVerifyFeedback to (If(bIsValid, clLime, clRed))
    End_Procedure

    Procedure Activating
        Forward Send Activating
        Send GenerateData
    End_Procedure

Cd_End_Object
