#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	SeriesUseSettings        = CheckParameters.SeriesUseSettings;
	OnlyQuantityEditing     = CheckParameters.OnlyQuantityEditing;
	ConnectionFieldValues                 = CheckParameters.ConnectionFieldValues;
	
	NotCheckedAttributeArray = New Array;
	
	
	CheckTable = SetOfSeries.Unload();
	CheckTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	CheckTable.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	CheckTable.FillValues(ConnectionFieldValues.Products, "Products");
	CheckTable.FillValues(CheckParameters.Package, "Package");
	
	QuantityVerificationParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	QuantityVerificationParameters.TSName = "SetOfSeries";
	QuantityVerificationParameters.TableToCheck = CheckTable;
	
	If OnlyQuantityEditing Then
		NotCheckedAttributeArray.Add("SetOfSeries.Count");
		NotCheckedAttributeArray.Add("SetOfSeries.NumberOfPackages");
	Else
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters);
	EndIf;
	
	KeyAttributes          = New Array;
	UseRFIDTags = False;
	UniquenessIsControlledByOneDetail = False;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		
		If LongDesc.SettingName <> "UseRFIDTags" Then
			If LongDesc.Use Then
				
				If Not LongDesc.CheckFilling Then			
					NotCheckedAttributeArray.Add("SetOfSeries." + LongDesc.AttributeName);
				ElsIf LongDesc.CheckUniquenessOfValue Then
					If Not SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
						TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject,"SetOfSeries", LongDesc.AttributeName, Cancel);
						UniquenessIsControlledByOneDetail = True;	
					EndIf;
				Else
					KeyAttributes.Add(LongDesc.AttributeName);	
				EndIf;
				
			Else
				NotCheckedAttributeArray.Add("SetOfSeries." + LongDesc.AttributeName);	
			EndIf;
		Else
			If LongDesc.Use Then
				UseRFIDTags = True;
			EndIf;
		EndIf;
		
	EndDo;
	
	If Not SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch
		And Not UniquenessIsControlledByOneDetail
		And KeyAttributes.Count() > 0 Then
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject,"SetOfSeries", KeyAttributes, Cancel);
	EndIf;
	
	If UseRFIDTags Then
		
		For Each RowOfTables In SetOfSeries Do
			
			If RowOfTables.RFIDTIDFilledIn
				And RowOfTables.YouNeedToSaveMark Then
				
				MessageText = NStr("vi = 'Cần phải ghi thẻ RFID mà thông tin về thẻ có trong dòng %LineNumber%.';
									|ru = 'Требуется записать RFID-метку, информация о которой содержится в строке %LineNumber%.';
									|en = 'Save RFID tag specified in line %LineNumber%.'; fa = 'Save RFID tag specified in line %LineNumber%.';
									|it = 'È necessario scrivere il tag RFID, le informazioni su cui è contenuto la riga %LineNumber%.';
									|pl = 'Należy zapisać znacznik RFID, informacje o którym jest w wierszu %LineNumber%.';
									|tr = 'Bilgileri %LineNumber% kataloğunda bulunan bir RFID etiketi kaydetmek gerekir.'");
				
				MessageText = StrReplace(MessageText, "%LineNumber%", String(RowOfTables.LineNumber));
				Field = CommonClientServer.PathToTabularSection("SetOfSeries", RowOfTables.LineNumber, "RFIDOperationStatus");
				
				CommonClientServer.MessageToUser(MessageText,,Field,"Object",Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ProductsLocalization.CheckFillingInDetailsOfSeries(ThisObject,
																NotCheckedAttributeArray,
																CheckParameters,
																Cancel); 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf