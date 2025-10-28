Use Windows.pkg
Use DFClient.pkg
Use File_dlg.pkg
Use cTextEdit.pkg

Use DFSecurity_CNG.pkg

#IFNDEF C_CRLF
Define C_CRLF for (Character(13)+Character(10))
#ENDIF

Deferred_View Activate_oAuthEncrypt for ;
Object oAuthEncrypt is a View

    Set Border_Style to Border_Normal
    Set Size to 319 415
    Set Location to 2 2
    Set Label to "Authenticated encryption"
    Set pbDisableSaveEnvironment to True

    Object oFileOpenDialog is an OpenDialog
    End_Object

    Object oPlainTextEdit is a cTextEdit
        Set Size to 62 405
        Set Location to 5 5
        Set peAnchors to anTopLeftRight
        Set piMaxChars to 4096
        Set psTypeFace to "Consolas"
        Set pbWrap to False
        Set piFontSize to (12*20)
    End_Object

    Object oKeyForm is a Form
        Set Size to 13 283
        Set Location to 70 34
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "Key:"
        Set Label_Col_Offset to 20
        Set FontPointHeight to 12
    End_Object

    Object oNonceForm is a Form
        Set Size to 13 250
        Set Location to 92 34
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "Nonce:"
        Set Label_Col_Offset to 30
        Set FontPointHeight to 12
    End_Object

    Object oFixNonceCheckBox is a CheckBox
        Set Size to 10 50
        Set Location to 96 388
        Set Label to 'Fix'
        Set Checked_State to True
    End_Object

    Object oAADForm is a Form
        Set Size to 13 283
        Set Location to 112 34
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "AAD:"
        Set Label_Col_Offset to 25
        Set FontPointHeight to 12
    End_Object

    Object oEncryptButton is a Button
        Set Size to 14 50
        Set Location to 130 200
        Set Label to 'Encrypt'

        Procedure OnClick
            Send EncryptFile
        End_Procedure
    End_Object

    Object oTagForm is a Form
        Set Size to 13 283
        Set Location to 148 34
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "Tag:"
        Set Label_Col_Offset to 20
        Set FontPointHeight to 12
    End_Object

    Object oCipherTextEdit is a cTextEdit
        Set Size to 62 405
        Set Location to 169 5
        Set peAnchors to anTopLeftRight
        Set piMaxChars to 4096
        Set psTypeFace to "Consolas"
        Set piFontSize to (12*20)
    End_Object

    Object oDecryptButton is a Button
        Set Size to 14 50
        Set Location to 235 200
        Set Label to 'Decrypt'

        Procedure OnClick
            Send DecryptFile
        End_Procedure
    End_Object

    Object oDecryptedTextEdit is a cTextEdit
        Set Size to 62 405
        Set Location to 252 5
        Set peAnchors to anTopLeftRight
        Set Read_Only_State to True
        Set piMaxChars to 4096
        Set psTypeFace to "Consolas"
        Set piFontSize to (12*20)
    End_Object

    Function Bin2HexBlocks UChar[] ucaData Returns String
        Integer iPos i
        String  sHexData
        String  sResult

        Get Bin2Hex of ghoSecurity ucaData to sHexData
        Move 1 to iPos
        While (iPos < Length(sHexData))
            If (iPos > 1) Add C_CRLF to sResult
            For i from 0 to 15
                If (i > 0) Add ' ' to sResult
                Add (Mid(sHexData, 2, iPos)) to sResult
                Add 2 to iPos
            Loop
        Loop

        Function_Return sResult
    End_Function

    Function HexBlocks2Bin String sHexData Returns UChar[]
        UChar[] ucaData

        Move (Replaces(' ', sHexData, '')) to sHexData
        Move (Replaces(C_CRLF, sHexData, '')) to sHexData
        Get Hex2Bin of ghoSecurity sHexData to ucaData

        Function_Return ucaData
    End_Function

    Procedure GenerateData
        String  sHexData
        String  sHexKey
        UChar[] ucaData
        UChar[] ucaKey

        Get RandomData of ghoSecurity (16 * 4) to ucaData
        Get Bin2HexBlocks ucaData to sHexData
        Set Value of oPlainTextEdit to sHexData

        Get RandomData of ghoSecurity (MinimumKeyBytes(ghoSecurity, piEncryptImplementation(oSimpleAuthEnc))) to ucaKey
        Get Bin2HexBlocks ucaKey to sHexKey
        Set Value of oKeyForm to sHexKey
        Send SecureUCharArrayOverwrite of ghoSecurity (&ucaKey)
        Send SecureStringOverwrite of ghoSecurity (&sHexKey)
    End_Procedure

    Object oSimpleAuthEnc is a cSecureAuthenticatedEncryptionMethod
        Set piEncryptImplementation to C_SEC_AUTHENC_CNG_AES128_GCM
    End_Object

    Procedure EncryptFile
        Boolean bFixedNonce
        Handle  hoMethod
        Handle  hoEnc
        String  sHexAAD
        String  sHexCipher
        String  sHexNonce
        String  sHexKey
        String  sHexPlain
        String  sHexTag
        UChar[] ucaAAD
        UChar[] ucaCipher
        UChar[] ucaNonce
        UChar[] ucaKey
        UChar[] ucaPlain
        UChar[] ucaTag

        Get Value of oKeyForm to sHexKey
        Get HexBlocks2Bin sHexKey to ucaKey
        Send SecureStringOverwrite of ghoSecurity (&sHexKey)

        Get Value of oPlainTextEdit to sHexPlain
        Get HexBlocks2Bin sHexPlain to ucaPlain

        Get Checked_State of oFixNonceCheckBox to bFixedNonce
        Get Value of oNonceForm to sHexNonce
        If bFixedNonce Move (sHexNonce <> '') to bFixedNonce
        If bFixedNonce Begin
            Get HexBlocks2Bin sHexNonce to ucaNonce
        End

        Get Value of oAADForm to sHexAAD
  	    Get HexBlocks2Bin sHexAAD to ucaAAD

        // create method
        Get CreateNamed (RefClass(cSecureAuthenticatedEncryptionMethod)) "hoMethod" to hoMethod
        Set piEncryptImplementation of hoMethod to (piEncryptImplementation(oSimpleAuthEnc))
        Send Initialize of hoMethod (&ucaKey)

        // encrypt
        Get NewEncryptor of hoMethod ucaAAD to hoEnc
        If not bFixedNonce ;
            Get pucaNonce of hoEnc to ucaNonce
        Else ;
            Set pucaNonce of hoEnc to ucaNonce
        Set pucaAAD of hoEnc to ucaAAD
        Get EncryptLastChunk of hoEnc ucaPlain to ucaCipher
        Get AuthenticationTag of hoEnc to ucaTag
        Send Destroy of hoEnc

        Get Bin2HexBlocks ucaCipher to sHexCipher
        Set Value of oCipherTextEdit to sHexCipher

        If not bFixedNonce Begin
            Get Bin2HexBlocks ucaNonce to sHexNonce
            Set Value of oNonceForm to sHexNonce
        End

        Get Bin2HexBlocks ucaTag to sHexTag
        Set Value of oTagForm to sHexTag

        Send Destroy of hoMethod
    End_Procedure

    Procedure DecryptFile
    	Boolean bIsAuthentic
        Handle  hoDec
        Handle  hoMethod
        String  sHexAAD
        String  sHexCipher
        String  sHexNonce
        String  sHexKey
        String  sHexPlain
        String  sHexTag
        UChar[] ucaAAD
        UChar[] ucaChunk
        UChar[] ucaCipher
        UChar[] ucaNonce
        UChar[] ucaKey
        UChar[] ucaPlain
        UChar[] ucaTag

        Get Value of oKeyForm to sHexKey
        Get HexBlocks2Bin sHexKey to ucaKey
        Send SecureStringOverwrite of ghoSecurity (&sHexKey)

        Get Value of oCipherTextEdit to sHexCipher
        Get HexBlocks2Bin sHexCipher to ucaCipher

        Get Value of oNonceForm to sHexNonce
    	Get HexBlocks2Bin sHexNonce to ucaNonce

        Get Value of oTagForm to sHexTag
    	Get HexBlocks2Bin sHexTag to ucaTag

        Get Value of oAADForm to sHexAAD
   	    Get HexBlocks2Bin sHexAAD to ucaAAD

        // create method
        Get CreateNamed (RefClass(cSecureAuthenticatedEncryptionMethod)) "hoMethod" to hoMethod
        Set piEncryptImplementation of hoMethod to (piEncryptImplementation(oSimpleAuthEnc))
        Send Initialize of hoMethod (&ucaKey)

        // decrypt
        Get NewDecryptor of hoMethod ucaNonce ucaTag ucaAAD to hoDec
        Get DecryptChunk of hoDec (CopyArray(ucaCipher, 0, 47)) to ucaPlain
        Get DecryptLastChunk of hoDec (CopyArray(ucaCipher, 48, 63)) to ucaChunk
        Move (AppendArray(ucaPlain, ucaChunk)) to ucaPlain
        Get IsAuthentic of hoDec to bIsAuthentic
        Send Destroy of hoDec

        Get Bin2HexBlocks ucaPlain to sHexPlain
        Set Value of oDecryptedTextEdit to sHexPlain

		Set Color of oDecryptedTextEdit to (If(bIsAuthentic, clLime, clRed))

        Send Destroy of hoMethod
    End_Procedure

    Procedure Activating
        Forward Send Activating
        Send GenerateData
    End_Procedure

Cd_End_Object
