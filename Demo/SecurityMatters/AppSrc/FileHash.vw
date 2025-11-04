Use Windows.pkg
Use DFClient.pkg
Use File_dlg.pkg
Use cCJGrid.pkg

Use GenerateFileHash.bp

Deferred_View Activate_oFileHash for ;
Object oFileHash is a View

    Object oFileOpenDialog is an OpenDialog
    End_Object

    Set Border_Style to Border_Thick
    Set Size to 200 300
    Set Location to 2 2
    Set Label to "Generate file hash"
    Set Maximize_Icon to True
    Set piMinSize to 200 300

    Object oFileForm is a Form
        Set Size to 13 235
        Set Location to 5 5
        Set Prompt_Button_Mode to PB_PromptOn
        Set peAnchors to anTopLeftRight

        Procedure Prompt
            Boolean  bOpen
            String[] sSelectedFiles

            Get Show_Dialog of oFileOpenDialog to bOpen
            If bOpen Begin
                Get Selected_Files of oFileOpenDialog to sSelectedFiles
                Set Value to sSelectedFiles[0]
            End
        End_Procedure
    End_Object

    Object oHashButton is a Button
        Set Location to 5 245
        Set Label to 'Generate'
        Set peAnchors to anTopRight

        Procedure OnClick
            String sFile

            Delegate Set Enabled_State to False
            Get Value of oFileForm to sFile
            Send ClearResults of oHashGrid

            Set phoResultObject of oGenerateFileHash to (oHashGrid(Self))
            Set psFileName of oGenerateFileHash to sFile
            Send DoProcess of oGenerateFileHash

            Delegate Set Enabled_State to True
        End_Procedure
    End_Object

    Object oHashGrid is a cCJGrid
        Set Size to 172 290
        Set Location to 23 5
        Set peAnchors to anAll

        Object oAlgorithm is a cCJGridColumn
            Set piWidth to 100
            Set psCaption to "Algorithm"
            Set pbResizable to False
        End_Object

        Object oHashValue is a cCJGridColumn
            Set piWidth to 250
            Set psCaption to "Hash"

            Procedure OnSetDisplayMetrics Handle hoGridItemMetrics Integer iRow String ByRef sValue
                Variant vFont
                Handle hoFont

                Get Create (RefClass(cComStdFont)) to hoFont
                Get ComFont of hoGridItemMetrics to vFont
                Set pvComObject of hoFont to vFont
                Set ComName of hoFont to "Consolas"
                Send Destroy of hoFont
            End_Procedure
        End_Object

        Procedure ClearResults
            tDataSourceRow[] data
            Send InitializeData data
        End_Procedure

        // Compare results with the following command:
        //      c:\>certutil -hashfile "<filename>" SHA256
        Procedure AddHash String sAlg String sHash
            Handle hoDataSource
            Integer iAlg iHash
            Integer iRows
            tDataSourceRow[] data

            Get piColumnId of oAlgorithm to iAlg
            Get piColumnId of oHashValue to iHash

            Get phoDataSource to hoDataSource
            Get DataSource of hoDataSource to data

            Move (SizeOfArray(data)) to iRows
            Move sAlg to data[iRows].sValue[iAlg]
            Move sHash to data[iRows].sValue[iHash]

            Send InitializeData data
            Send MovetoFirstRow
        End_Procedure
    End_Object

Cd_End_Object
