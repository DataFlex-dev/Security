Use Windows.pkg
Use DFClient.pkg
Use File_dlg.pkg
Use cTextEdit.pkg

Use DFSecurity_CNG.pkg

#IFNDEF C_CRLF
Define C_CRLF for (Character(13)+Character(10))
#ENDIF

Deferred_View Activate_oSymKeyEncrypt for ;
Object oSymKeyEncrypt is a View

    Set Border_Style to Border_Normal
    Set Size to 284 407
    Set Location to 2 2
    Set Label to "Symmetric-key encryption"
    Set pbDisableSaveEnvironment to True

    Object oFileOpenDialog is an OpenDialog
    End_Object

    Object oPlainTextEdit is a cTextEdit
        Set Size to 62 397
        Set Location to 5 5
        Set peAnchors to anTopLeftRight
        Set piMaxChars to 4096
        Set psTypeFace to "Consolas"
        Set pbWrap to False
        Set piFontSize to (12*20)
    End_Object

    Object oKeyForm is a Form
        Set Size to 13 283
        Set Location to 71 25
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "Key:"
        Set Label_Col_Offset to 20
        Set FontPointHeight to 12
    End_Object

    Object oIVForm is a Form
        Set Size to 13 250
        Set Location to 92 25
        Set peAnchors to anTopLeftRight
        Set Typeface to "Consolas"
        Set Label to "IV:"
        Set Label_Col_Offset to 20
        Set FontPointHeight to 12
    End_Object

    Object oFixIVCheckBox is a CheckBox
        Set Size to 10 50
        Set Location to 95 380
        Set Label to 'Fix'
        Set Checked_State to True
    End_Object

    Object oEncryptButton is a Button
        Set Size to 14 50
        Set Location to 113 200
        Set Label to 'Encrypt'

        Procedure OnClick
            Send EncryptFile
        End_Procedure
    End_Object

    Object oCipherTextEdit is a cTextEdit
        Set Size to 62 397
        Set Location to 131 5
        Set peAnchors to anTopLeftRight
        Set piMaxChars to 4096
        Set psTypeFace to "Consolas"
        Set piFontSize to (12*20)
    End_Object

    Object oDecryptButton is a Button
        Set Size to 14 50
        Set Location to 197 200
        Set Label to 'Decrypt'

        Procedure OnClick
            Send DecryptFile
        End_Procedure
    End_Object

    Object oDecryptedTextEdit is a cTextEdit
        Set Size to 62 397
        Set Location to 216 5
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

        Get RandomData of ghoSecurity (MinimumKeyBytes(ghoSecurity, piEncryptImplementation(oSimpleSymKeyEnc))) to ucaKey
        Get Bin2HexBlocks ucaKey to sHexKey
        Set Value of oKeyForm to sHexKey
        Send SecureUCharArrayOverwrite of ghoSecurity (&ucaKey)
        Send SecureStringOverwrite of ghoSecurity (&sHexKey)
    End_Procedure

    Object oSimpleSymKeyEnc is a cSecureSymmetricKeyEncryptionMethod
        Set piEncryptImplementation to C_SEC_SYMENC_CNG_AES128_CBC
    End_Object

    Procedure EncryptFile
        Boolean bFixedIV
        Handle  hoMethod
        Handle  hoEnc
        String  sHexCipher
        String  sHexIV
        String  sHexKey
        String  sHexPlain
        UChar[] ucaCipher
        UChar[] ucaIV
        UChar[] ucaKey
        UChar[] ucaPlain

        Get Value of oKeyForm to sHexKey
        Get HexBlocks2Bin sHexKey to ucaKey
        Send SecureStringOverwrite of ghoSecurity (&sHexKey)

        Get Value of oPlainTextEdit to sHexPlain
        Get HexBlocks2Bin sHexPlain to ucaPlain

        Get Checked_State of oFixIVCheckBox to bFixedIV
        Get Value of oIVForm to sHexIV
        If bFixedIV Move (sHexIV <> '') to bFixedIV
        If bFixedIV Begin
            Get HexBlocks2Bin sHexIV to ucaIV
        End

        // create method
        Get CreateNamed (RefClass(cSecureSymmetricKeyEncryptionMethod)) "hoMethod" to hoMethod
        Set piEncryptImplementation of hoMethod to (piEncryptImplementation(oSimpleSymKeyEnc))
        Send Initialize of hoMethod (&ucaKey)

        // encrypt
        Get NewEncryptor of hoMethod to hoEnc
        If not bFixedIV ;
            Get pucaIV of hoEnc to ucaIV
        Else ;
            Set pucaIV of hoEnc to ucaIV
        Get EncryptChunk of hoEnc ucaPlain to ucaCipher
        Send Destroy of hoEnc

        Get Bin2HexBlocks ucaCipher to sHexCipher
        Set Value of oCipherTextEdit to sHexCipher

        If not bFixedIV Begin
            Get Bin2HexBlocks ucaIV to sHexIV
            Set Value of oIVForm to sHexIV
        End

        Send Destroy of hoMethod
    End_Procedure

    Procedure DecryptFile
        Handle  hoDec
        Handle  hoMethod
        String  sHexCipher
        String  sHexIV
        String  sHexKey
        String  sHexPlain
        UChar[] ucaCipher
        UChar[] ucaIV
        UChar[] ucaKey
        UChar[] ucaPlain

        Get Value of oKeyForm to sHexKey
        Get HexBlocks2Bin sHexKey to ucaKey
        Send SecureStringOverwrite of ghoSecurity (&sHexKey)

        Get Value of oCipherTextEdit to sHexCipher
        Get HexBlocks2Bin sHexCipher to ucaCipher

        Get Value of oIVForm to sHexIV
        Get HexBlocks2Bin sHexIV to ucaIV

        // create method
        Get CreateNamed (RefClass(cSecureSymmetricKeyEncryptionMethod)) "hoMethod" to hoMethod
        Set piEncryptImplementation of hoMethod to (piEncryptImplementation(oSimpleSymKeyEnc))
        Send Initialize of hoMethod (&ucaKey)

        // decrypt
        Get NewDecryptor of hoMethod ucaIV to hoDec
        Get DecryptChunk of hoDec ucaCipher to ucaPlain
        Send Destroy of hoDec

        Get Bin2HexBlocks ucaPlain to sHexPlain
        Set Value of oDecryptedTextEdit to sHexPlain

        Send Destroy of hoMethod
    End_Procedure

    Procedure Activating
        Forward Send Activating
        Send GenerateData
    End_Procedure

Cd_End_Object
