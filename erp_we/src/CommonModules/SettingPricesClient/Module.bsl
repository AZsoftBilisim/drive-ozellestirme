#If Not MobileClient Then

#Region Public

// Uploads the price tree to Excel on the WEB client side
//
// Parameters:
//  Form - ClientApplicationForm - , where you need to calculate prices
//  PrintParameters - Structure - the print settings used in the formation of the printing plate.
//
Procedure UploadToExcelWithoutWEBLink(Form, PrintParameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("AdditionalColumnName", Form.AdditionalColumnName);
	AdditionalParameters.Insert("UsePriceManagementSystem25", Form.UsePriceManagementSystem25);
	AdditionalParameters.Insert("PrintParameters", PrintParameters);
	AdditionalParameters.Insert("UUID", Form.UUID);
	
	FileAddressInTempStorage = PriceSetupServerCall.UploadToExcelWithoutWEBLink(
		PredefinedValue("Document.PriceSetup.EmptyRef"),
		AdditionalParameters);
		
	FilesToObtain = New Array;
	FilesToObtain.Add(New TransferableFileDescription(,FileAddressInTempStorage));
	
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.DefaultExt = "xls";
	
	BeginGettingFiles(
		New CallbackDescription("UploadToExcelWithoutLinkStartReceivingFilesEndWEB", SettingPricesClient, AdditionalParameters),
		FilesToObtain,
		FileDialog,
		True);
	
EndProcedure

// Loads data from Excel into the form price tree on the WEB client side
//
// Parameters:
//  Form - ClientApplicationForm - to which you need to load data from Excel.
//
Procedure DownloadFromExcelWithoutWEBLink(Form) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("UsePriceManagementSystem25", Form.UsePriceManagementSystem25);
	AdditionalParameters.Insert("UUID", Form.UUID);
	
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Show(
			New CallbackDescription("DownloadFromExcelWithoutLinkFileSelectionDialogEndWEB",
			SettingPricesClient,
			AdditionalParameters));
	
EndProcedure

// Checks whether the required parameters of the data layout schemes
// used for calculating prices are filled in.
//
// Parameters:
//  Form - See SettingPricesServer.BuildPriceTree.Form
//
// Returns:
//  Boolean - Indicates the presence of errors.
//
Function RequiredDataLayoutSchemaParametersFilledIn(Form) Export
	
	TypesOfPrices = New Array;
	For Each PriceTypeLine In Form.SelectedPrices Do
		If PriceTypeLine.Selected_5 And PriceTypeLine.RequiredParametersAreFound Then
			TypesOfPrices.Add(PriceTypeLine.Ref);
		EndIf;
	EndDo;
	
	Errors = PriceSetupServerCall.CheckWhetherRequiredDataLayoutSchemaParametersAreFull(
		TypesOfPrices,
		Form.StorageAddressDataLayoutSettings,
		Form.AddressOfTheStorageOfLayoutSchemeParametersByPriceType);
		
	For Each ErrorStructure In Errors Do
		PriceTypeLine = SettingPricesClientServer.FindPriceTypeString(Form.SelectedPrices, ErrorStructure.PriceKind);
		If TMCommonUseClientServer.HasObjectAttribute(Form.Object, "Ref") Then
			CommonClientServer.MessageToUser(
				ErrorStructure.LongDesc,
				Form.Object.Ref,
				"SelectedPrices[" + Form.SelectedPrices.IndexOf(PriceTypeLine) + "].Parameters");
		Else
			CommonClientServer.MessageToUser(
				ErrorStructure.LongDesc,
				,
				"SelectedPrices[" + Form.SelectedPrices.IndexOf(PriceTypeLine) + "].Parameters");
		EndIf;
	EndDo;
	
	Return Errors.Count() = 0;
	
EndFunction

// Loads the price tree in Excel
//
// Parameters:
//  Form - See SettingPricesServer.BuildPriceTree.Form
//  PrintParameters - Structure - the printing parameters used in the formation of the printing form.
//
// The result:
//  File, the result of uploading.
//
Procedure ExportToExcel(Form, PrintParameters) Export
	
	Try
		COMObject = New COMObject("Excel.Application");
		COMObject = 0;
	Except
		ErrorMessage = NStr("vi = 'Không thể kết xuất đơn giá vào Excel.
		                               |Hãy chắc chắn rằng, trong máy tính có cài đặt chương trình Microsoft Excel.
		                               |Chi tiết:';
		                               |ru = 'Не удалось выгрузить цены в Excel.
		                               |Убедитесь, что на компьютере установлена программа Microsoft Excel.
		                               |Подробности:';
		                               |en = 'Cannot export prices to Excel.
		                               |Make sure Microsoft Excel is installed on your computer.
		                               |More information:'; fa = 'Cannot export prices to Excel.
		                               |Make sure Microsoft Excel is installed on your computer.
		                               |More information:';
		                               |it = 'Non è stato possibile caricare i prezzi su Excel. 
		                               | Verificare che il programma sia installato sul computer.
		                               | Dettagli:';
		                               |pl = 'Nie udało się zładować ceny do programu Excel.
		                               |Upewnij się, że na komputerze jest zainstalowany program Microsoft Excel. 
		                               |Szczegóły:';
		                               |tr = 'Fiyatlar Excel''e yüklenemedi.
		                               |Bilgisayarda Microsoft Excel''in yüklü olduğundan emin ol.
		                               |Detaylar:'") + " "
		                  + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	OutputCodes = ?(ValueIsFilled(Form.AdditionalColumnName), True, False);
	
	DocumentsArray = New Array;
	If SelectGoodsClientServer.ThisIsPriceListForm(Form.FormCode) Then
		For Each TSRow In Form.SavedDocuments Do
			DocumentsArray.Add(TSRow.Ref);
		EndDo;
	Else
		DocumentsArray.Add(Form.Object.Ref);
	EndIf;
	
	ArrayOfInformation = PriceSetupServerCall.ExportToExcel(
		DocumentsArray,
		Form.UUID,
		PrintParameters);
		
	If ArrayOfInformation = Undefined Then
		ErrorMessage = NStr("vi = 'Không thể kết xuất đơn giá ra Excel.';
							|ru = 'Не удалось выгрузить цены в Excel.';
							|en = 'Cannot export prices to Excel.'; fa = 'Cannot export prices to Excel.';
							|it = 'Non è stato possibile caricare i prezzi su Excel.';
							|pl = 'Nie udało się zładować ceny do programu Excel.';
							|tr = 'Fiyatlar Excel''e yüklenemedi.'");
		Raise ErrorMessage;
	EndIf;
	
	AdditionalParameters = 
		New Structure("Form, PrintParameters, OutputCodes", Form, PrintParameters, OutputCodes);
		
	For Each Information In ArrayOfInformation Do
	
		AdditionalParameters.Insert("Information", Information);
		
		Notification = New CallbackDescription(
			"UploadToExcel",
			ThisObject,
			AdditionalParameters);
		
		FilesOperationsClient.GetAttachedFile(
			Notification,
			Information.File,
			Form.UUID,
			New Structure("FileData, ForEditing", Information.FileData, True));
		
	EndDo;
		
EndProcedure

// Loads data from Excel to the form's price tree
//
// Parameters:
//  Form - ClientApplicationForm - Form to upload data from Excel to
//  AttachedFile - DefinedType.AttachedFile - link to the directory element with the file..
//
Procedure ImportFromExcel(Form, AttachedFile) Export
	
	FileData = FilesOperationsClient.FileData(
		AttachedFile,
		Form.UUID);
	
	AdditionalParameters = 
		New Structure("Form, AttachedFile", Form, AttachedFile);
	
	If Not FileData.CurrentUserEditsFile Then
		
		Notification = New CallbackDescription(
			"DownloadFromExcel",
			ThisObject,
			AdditionalParameters);
		
		FilesOperationsClient.GetAttachedFile(
			Notification,
			AttachedFile,
			Form.UUID,
			New Structure("FileData, ForEditing", FileData, False));
		
	Else
		
		// No need to get the file to disk so as not to erase unsaved changes
		UserWorkingDirectory = FilesOperationsInternalClient.UserWorkingDirectory();
		TempFileName         = UserWorkingDirectory + FileData.RelativePath + FileData.FileName;
		
		DownloadFromExcel(
			New Structure("ErrorDescription, FullFileName", "", TempFileName),
			AdditionalParameters);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Items - FormItems - Elements of the Form being processed. Must include:
// 	* PriceTree - ValueTree, FormTable, FormDataTreeItem, FormDataTree - the main element of the form with the price tree
// 	SelectedPrices - ValueTable - 
// 	ValidPriceDate - Date
// 	CurrentDate - Date
// 	UseItemVariants - Boolean
// 	DonTUseFormulas - Boolean
// Returns:
// 	FormattedString, String - 
Function CurLineInformation(Items,
	                            SelectedPrices,
	                            ValidPriceDate,
	                            CurrentDate,
	                            UseItemVariants,
	                            DonTUseFormulas = False) Export
	
	Item = Items.PriceTree;
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Or
		Item  = Undefined Then
		Return "";
	EndIf;
	
	StringProducts_ = String(CurrentData.Products)
	                    + ?(UseItemVariants,
	                      ?(ValueIsFilled(CurrentData.Characteristic), " (" + String(CurrentData.Characteristic) + ")", ""), "");
	
	FormattedStringProductList = New FormattedString(StringProducts_, New Font(,,True));
	FormattedStringPriceView = "";
	FormattedStringOldPrice = "";
	FormattedStringPercentageOfChange = "";
	FormattedStringAmountOfChange = "";
	FormattedStringPrice = "";
	FormattedStringAdditionalInformation = "";
	
	If Item.CurrentItem = Undefined Then
		SubstringPosition = 0;
	Else
		SubstringPosition = StrFind(Item.CurrentItem.Name, "PriceKind");
	EndIf;
	
	
	If SubstringPosition <> 0 Then

		ColumnName = Right(Item.CurrentItem.Name, StrLen(Item.CurrentItem.Name) - SubstringPosition + 1);
			
		GroupOfPrices = Items.Find("PriceTree" + "GroupPrices" + ColumnName);
		
		If GroupOfPrices <> Undefined Then
		 	If CurrentData.Property("Currency" + ColumnName) Then
				NameOfCurrency = " " + String(CurrentData["Currency" + ColumnName]);
			Else	
				NameOfCurrency = Right(GroupOfPrices.Title, 4);
			EndIf;
			NameOfPriceType = Left(GroupOfPrices.Title, StrLen(GroupOfPrices.Title) - 5);
		EndIf;
		
		If DonTUseFormulas Then
			
			FormattedStringPriceView = New FormattedString(" | ", NameOfPriceType);
			
		Else
	
				StructurePriceGroup = New Structure("PriceGroup", CurrentData.PriceGroup);	
				
				PriceViewFormula = "";
				
				If CurrentData.Property("Formula" + ColumnName) Then
					PriceViewFormula = CurrentData["Formula" + ColumnName];
				EndIf;
				
				If Not ValueIsFilled(PriceViewFormula) Then					
					FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
					If FoundTypesOfPrices.Count() = 1 Then
						PriceKind = FoundTypesOfPrices[0];
						If PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.CalculateUsingFormulasOfOtherPriceTypes") Then
						
							PriceViewFormula = PriceKind.Formula;
							PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
											
							If PriceGroupsOfAlgorithms.Count() > 0 Then
								PriceViewFormula = PriceGroupsOfAlgorithms[0].Formula;
							EndIf;
									
						ElsIf PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.AnotherPriceTypeMarkup") Then
							
							PriceViewFormula = "[" + PriceKind.BasicPriceType + "]*" + Format(((PriceKind.Markup/100)+1),"NDS=.; NG=0");
							PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
											
							If PriceGroupsOfAlgorithms.Count() > 0 Then
								
								PriceViewFormula = "[" + PriceGroupsOfAlgorithms[0].BasicPriceType + "]*" + Format(((PriceGroupsOfAlgorithms[0].Markup/100)+1),"NDS=.; NG=0");
								
							EndIf;		
		
						ElsIf PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnPurchasingPrice")
						 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.MarkupOnOBEntryPrice") 
						 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByCompetitors") 
						 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillInByInfobaseDataByVendors") 
						 	Or PriceKind.PricingMethod = PredefinedValue("Enum.PriceSettingMethods.FillByInfobaseDataByCost") Then
							
							PriceViewFormula = "[" + PriceKind.Ref + "]*" + Format(((PriceKind.Markup/100)+1),"NDS=.; NG=0");
							PriceGroupsOfAlgorithms = PriceKind.PriceGroups.FindRows(StructurePriceGroup);
											
							If PriceGroupsOfAlgorithms.Count() > 0 Then
								
								PriceViewFormula = "[" + PriceKind.Ref + "]*" + Format(((PriceGroupsOfAlgorithms[0].Markup/100)+1),"NDS=.; NG=0");
								
							EndIf;		
		
						EndIf;
					EndIf;
					
				EndIf;

				If ValueIsFilled(PriceViewFormula) Then
					
					If PriceGroupsOfAlgorithms <> Undefined And PriceGroupsOfAlgorithms.Count() > 0 Then
							
						PriceViewFormula = " <" + PriceGroupsOfAlgorithms[0].PriceGroup + "> = " + PriceViewFormula;
						
					Else
						
						PriceViewFormula = " = " + PriceViewFormula;
								
					EndIf;	
				EndIf;
				
				#If WebClient Then
				FormattedStringPriceView = New FormattedString(" | ", NameOfPriceType + PriceViewFormula);
				#Else
				FormattedStringPriceView = New FormattedString(" | ", GroupOfPrices.HeaderPicture, " ", NameOfPriceType + PriceViewFormula);
				#EndIf
		
		EndIf;
		
		If ValueIsFilled(ValidPriceDate) Then
			PriceDate = ValidPriceDate;
		Else
			PriceDate = BegOfDay(CurrentDate)-1;
		EndIf;
			
		If CurrentData["OldPrice" + ColumnName] = CurrentData[ColumnName]
			And CurrentData[ColumnName] <> 0 Then
			
			FormattedStringOldPrice = New FormattedString(" | ", NStr("vi = '<Giá không thay đổi>';
																		|ru = '<Цена не изменилась>';
																		|en = '<Price has not changed>'; fa = '<Price has not changed>';
																		|it = '<Prezzo invariato>';
																		|pl = '<Cena się nie zmieniła>';
																		|tr = '<Fiyat değişmedi>'"));
			
		ElsIf CurrentData["OldPrice" + ColumnName] <> 0 Then
				
			OldPriceLine = New FormattedString(Format(CurrentData["OldPrice" + ColumnName], "NFD=2"));
			
			
			CurrentPriceDateLine = Format(PriceDate, "DLF=D");
			
			CurrentPriceDateLine = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đơn giá %1:';
					|ru = 'Цена на %1:';
					|en = 'Price as of %1:'; fa = 'Price as of %1:';
					|it = 'Prezzo di %1:';
					|pl = 'Cena na %1:';
					|tr = '%1 fiyatı:'"),
				CurrentPriceDateLine);
				
			FormattedStringOldPrice = New FormattedString(" | ", CurrentPriceDateLine, " ", OldPriceLine, NameOfCurrency);
			
		EndIf;
		
		If CurrentData["ChangePercentage" + ColumnName] <> 0 Then
			
			LinePercentageOfChange = New FormattedString(Format(CurrentData["ChangePercentage" + ColumnName], "ND=5; NFD=2"), New Font(,,True));
			FormattedStringPercentageOfChange = New FormattedString(" ", LinePercentageOfChange, "%");
			
		EndIf;

		If CurrentData["AmountOfChange" + ColumnName] <> 0 Then
			
			LineAmountOfChange = New FormattedString(Format(CurrentData["AmountOfChange" + ColumnName], "NFD=2"), New Font(,,True));
			
			If CurrentData["AmountOfChange" + ColumnName] > 0 Then
				#If WebClient Then
				ChangeString = New FormattedString(" | ");
				#Else
				ChangeString = New FormattedString(" | ", PictureLib.TrendIconGrowthInARange, " ");
				#EndIf
			Else
				#If WebClient Then
				ChangeString = New FormattedString(" | ");
				#Else
				ChangeString = New FormattedString(" | ", PictureLib.TrendIconDeclineIsImproving, " ");
				#EndIf
			EndIf;
			
			FormattedStringAmountOfChange = New FormattedString(ChangeString, LineAmountOfChange, NameOfCurrency);
			
		EndIf;
		
		If CurrentData[ColumnName] <> 0 Then
			
			If CurrentData[ColumnName] > CurrentData["OldPrice" + ColumnName] Then
				PriceLine = New FormattedString(Format(CurrentData[ColumnName], "NFD=2"), New Font(,,True), WebColors.DarkBlue);
			ElsIf CurrentData[ColumnName] < CurrentData["OldPrice" + ColumnName] Then
				PriceLine = New FormattedString(Format(CurrentData[ColumnName], "NFD=2"), New Font(,,True), WebColors.DarkGreen);
			Else
				PriceLine = New FormattedString(Format(CurrentData[ColumnName], "NFD=2"), New Font(,,True));
			EndIf;
					
			PriceChanged_ = CurrentData["ChangedManually" + ColumnName];
			
			If PriceChanged_ Then
				PicturePriceChanged = PictureLib.Change;
				#If WebClient Then
				FormattedStringPrice = New FormattedString(" | ", PriceLine, NameOfCurrency);
				#Else
				FormattedStringPrice = New FormattedString(" | ", PicturePriceChanged, PriceLine, NameOfCurrency);
				#EndIf
			Else
				FormattedStringPrice = New FormattedString(" | ", PriceLine, NameOfCurrency);
			EndIf;
			
		EndIf;
		
		// for the layout
		// layout of the set price display
		If FoundTypesOfPrices = Undefined Then
			FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
		EndIf;
		If FoundTypesOfPrices.Count() = 1 And FoundTypesOfPrices[0].Property("DateOfTheLastPriceSetting") Then
			DateOfTheLastPriceSetting = FoundTypesOfPrices[0].DateOfTheLastPriceSetting;
			
			If DateOfTheLastPriceSetting > PriceDate Then 
				DateWhenFSPriceWasLastSet = Format(DateOfTheLastPriceSetting, "DLF=D;");
				StringSobschenie = " On view_ prices_ use price future by_date - " + DateWhenFSPriceWasLastSet;
				#If WebClient Then
				FormattedStringAdditionalInformation = New FormattedString(New FormattedString(" | ", " ! ", StringSobschenie),,WebColors.Red);
				#Else
				FormattedStringAdditionalInformation = New FormattedString(New FormattedString(" | ", PictureLib.Attention16, StringSobschenie),,WebColors.Red);
				#EndIf
			EndIf;
		EndIf;
		
	EndIf;
	
	Return New FormattedString(
		FormattedStringProductList,
		FormattedStringPriceView,
		FormattedStringOldPrice,
		FormattedStringAmountOfChange,
		FormattedStringPercentageOfChange,
		FormattedStringPrice,
		FormattedStringAdditionalInformation);
	
EndFunction


// Parameters:
// 	Items - FormItems
// 	SelectedPrices - ValueTable - 
// 	ValidPriceDate - Date
// 	CurrentDate - Date
// 	UseItemVariants - Boolean
// 	The current Marketing operation is a Reference link.Marketing activities
// 	ThereIsPriceSetByFutureDate - Boolean
// 	PriceKind - CatalogRef.TypesOfPrices
// Returns:
// 	FormattedString, String - LongDesc
Function GetInformationStringForCell(Items,
	                            SelectedPrices,
	                            ValidPriceDate,
	                            CurrentDate,
	                            UseItemVariants,
	                            ThereIsPriceSetByFutureDate,
								PriceKind = Undefined) Export
	
	Item = Items.PriceTree;//FormTable
	
	CurrentData = Items.PriceTree.CurrentData;
	If CurrentData = Undefined Or
		Item  = Undefined Then
		Return "";
	EndIf;
	
	FormattedStringPriceView = "";
	FormattedStringOldPrice = "";
	FormattedStringPercentageOfChange = "";
	FormattedStringAmountOfChange = "";
	FormattedStringPrice = "";
	FormattedStringAdditionalInformation = "";
	
	If Item.CurrentItem = Undefined Then
		SubstringPosition = 0;
	Else
		SubstringPosition = StrFind(Item.CurrentItem.Name, "PriceKind");
	EndIf;
	
	If SubstringPosition <> 0 Then

		ColumnName = Right(Item.CurrentItem.Name, StrLen(Item.CurrentItem.Name) - SubstringPosition + 1);
			
		GroupOfPrices = Items.Find("PriceTree" + "GroupPrices" + ColumnName);
		
		If GroupOfPrices <> Undefined Then
		 	If CurrentData.Property("Currency" + ColumnName) Then
				NameOfCurrency = New FormattedString( " " + String(CurrentData["Currency" + ColumnName]),New Font(,,True));
			Else	
				NameOfCurrency = New FormattedString(Right(GroupOfPrices.Title, 4),New Font(,,True));
			EndIf;
			NameOfPriceType = Left(GroupOfPrices.Title, StrLen(GroupOfPrices.Title) - 5);
		EndIf;
		
		If PriceKind = Undefined Then
			FoundTypesOfPrices = SelectedPrices.FindRows(New Structure("ColumnName", ColumnName));
			If FoundTypesOfPrices.Count() = 1 Then
				PriceKind = FoundTypesOfPrices[0];
			EndIf;		
		EndIf;
		
		StringFormatPriceTypeName = New FormattedString(NameOfPriceType, New Font(,,True),,,GetURL(PriceKind.Ref));
		
		#If WebClient Then
			FormattedStringPriceView = New FormattedString("  ", StringFormatPriceTypeName);
		#Else
			FormattedStringPriceView = New FormattedString("  ", GroupOfPrices.HeaderPicture, " ", StringFormatPriceTypeName);
		#EndIf
				
		If CurrentData["ChangePercentage" + ColumnName] <> 0 Then
			
			LinePercentageOfChange = New FormattedString(Format(CurrentData["ChangePercentage" + ColumnName], "ND=5; NFD=2"), New Font(,,True));
			FormattedStringPercentageOfChange = New FormattedString(" (", LinePercentageOfChange, "%)");
			
		EndIf;

		If CurrentData["AmountOfChange" + ColumnName] <> 0 Then
			
			LineAmountOfChange = New FormattedString(Format(CurrentData["AmountOfChange" + ColumnName], "NFD=2"), New Font(,,True));
			
			If CurrentData["AmountOfChange" + ColumnName] > 0 Then
				#If WebClient Then
				ChangeString = New FormattedString("  ");
				#Else
				ChangeString = New FormattedString("  ", PictureLib.TrendIconGrowthInARange, " ");
				#EndIf
			Else
				#If WebClient Then
				ChangeString = New FormattedString("  ");
				#Else
				ChangeString = New FormattedString("  ", PictureLib.TrendIconDeclineIsImproving, " ");
				#EndIf
			EndIf;
			
			FormattedStringAmountOfChange = New FormattedString(ChangeString, LineAmountOfChange, NameOfCurrency);
			
		EndIf;
		
		If CurrentData[ColumnName] <> 0 Then
			
			If CurrentData[ColumnName] > CurrentData["OldPrice" + ColumnName] Then
				PriceLine = New FormattedString(Format(CurrentData[ColumnName], "NFD=2"), New Font(,,True), WebColors.DarkBlue);
			ElsIf CurrentData[ColumnName] < CurrentData["OldPrice" + ColumnName] Then
				PriceLine = New FormattedString(Format(CurrentData[ColumnName], "NFD=2"), New Font(,,True), WebColors.DarkGreen);
			Else
				PriceLine = New FormattedString(Format(CurrentData[ColumnName], "NFD=2"), New Font(,,True));
			EndIf;
					
			PriceChanged_ = CurrentData["ChangedManually" + ColumnName];
			
			If PriceChanged_ Then
				PicturePriceChanged = PictureLib.Change;
				#If WebClient Then
				FormattedStringPrice = New FormattedString(" = ", PriceLine, NameOfCurrency);
				#Else
				FormattedStringPrice = New FormattedString(" = ", PicturePriceChanged, PriceLine, NameOfCurrency);
				#EndIf
			Else
				FormattedStringPrice = New FormattedString(" = ", PriceLine, NameOfCurrency);
			EndIf;
			
		EndIf;
				
		FormattedStringIndent = New FormattedString("  ");
		FormattedPriceChangeHistory = New FormattedString(NStr("vi = 'lịch sử';
																|ru = 'история';
																|en = 'history'; fa = 'history';
																|it = 'cronologia';
																|pl = 'historia';
																|tr = 'geçmiş'"),New Font(,,True),,,"LinkToPriceHistory");
			
		If ThereIsPriceSetByFutureDate Then 

			#If WebClient Then
				FormattedStringAdditionalInformation = New FormattedString(New FormattedString("  ", " ! ",),,WebColors.Red);
			#Else
				FormattedStringAdditionalInformation = New FormattedString("  ", PictureLib.Attention16, "  ");
			#EndIf
		EndIf;
	EndIf;
		
	Return New FormattedString(
	    "",
		FormattedStringPriceView,
		FormattedStringPrice,
		FormattedStringAmountOfChange,
		FormattedStringPercentageOfChange,
		FormattedStringIndent,
		FormattedPriceChangeHistory,
		FormattedStringAdditionalInformation);
	
EndFunction
	

// Generates information lines for the history of changes in the price type
// 
// Parameters:
// 	Parameters - Structure:
// 	 * PreviousCurrency - CatalogRef.Currencies
// Returns:
// 	Structure - LongDesc:
// * FormattedStringTrendIcon - FormattedString -
// * FormattedSpeakerString - FormattedString -
// * FormattedHistoryString - FormattedString -
Function GetHistoryInformationLine(Parameters) Export
	
	DatePriceLine = NStr("vi = 'Đơn giá %1';
						|ru = 'Цена на %1';
						|en = 'Price as of %1'; fa = 'Price as of %1';
						|it = 'Prezzo di %1';
						|pl = 'Cena na %1';
						|tr = '%1 fiyatı'") + " ";
	DatePriceLine = StringFunctionsClientServer.SubstituteParametersToString(DatePriceLine, Format(Parameters.Period,"DLF=D;"));
	PriceValueString =  StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = ' %2 %3';
																						|ru = ' %2 %3';
																						|en = ' %2 %3'; fa = ' %2 %3';
																						|it = ' %2 %3';
																						|pl = ' %2 %3';
																						|tr = ' %2 %3'"),,Format(Parameters.Price,"NFD=2"), Parameters.Currency); 
	FormattedStringTrendIcon = New FormattedString(" ");
	FormattedStringIndent = New FormattedString(" ");
	If Parameters.PriceChanged_ Then
		#If WebClient Then
			FormattedStringStartOfString = New FormattedString(New FormattedString("", " V ",""),New Font(,,True),,);
		#Else
			FormattedStringStartOfString = New FormattedString("",PictureLib.Change, "");
		#EndIf		
	ElsIf Parameters.Period > CurrentDate() Then
		#If WebClient Then
			FormattedStringStartOfString = New FormattedString(New FormattedString("", " ! ",""),,WebColors.Red);
		#Else
			FormattedStringStartOfString = New FormattedString("", PictureLib.Attention16, "");
		#EndIf 	
	Else
		FormattedStringStartOfString = New FormattedString("    ");
	EndIf;
	
	PriceValueString = New FormattedString(PriceValueString,New Font(,,True));
	
	FormattedStringPriceAsOfDate = New FormattedString(DatePriceLine,FormattedStringIndent,PriceValueString); 
	
	If Parameters.Property("PreviousPrice") And Parameters.PreviousPrice<>0 Then
			PriceChange_ = Parameters.Price - Parameters.PreviousPrice;
			ChangePercentage = Parameters.Price/(Parameters.PreviousPrice/100)-100; 
			PriceChangeLine = New FormattedString("",Format(PriceChange_,"NFD=2"));
			PriceChangeCurrencyString = New FormattedString(" ",Parameters.PreviousCurrency["Description"]," ");
			PercentageChangeString = New FormattedString(" (",Format(ChangePercentage,"NFD=2"),"%) ");	
		If PriceChange_ > 0 Then
			#If Not WebClient Then
				FormattedStringTrendIcon = New FormattedString("", PictureLib.TrendIconGrowthInARange,"");
			#EndIf				
		ElsIf  PriceChange_ < 0 Then 
			#If Not WebClient Then
				FormattedStringTrendIcon = New FormattedString("", PictureLib.TrendIconDeclineIsImproving,"");
			#EndIf	
		Else
			 FormattedStringTrendIcon = New FormattedString("");
		EndIf;
		
		FormattedStringUpdate = New FormattedString(PriceChangeLine,PriceChangeCurrencyString, PercentageChangeString);
	Else 
		FormattedStringUpdate = New FormattedString("  ");
	EndIf;		
	
	If Parameters.Property("MarketingActivity") And ValueIsFilled(Parameters.MarketingActivity) Then
		FormattedStringMarketingEvent = New FormattedString("on stocks",New Font(,,True),WebColors.Coral,,GetURL(Parameters.MarketingActivity));
	Else
		FormattedStringMarketingEvent = " ";
	EndIf;		
	
	FormattedHistoryString = New FormattedString(
						FormattedStringIndent,
						FormattedStringPriceAsOfDate);
						
	FormattedSpeakerString = New FormattedString(
						FormattedStringUpdate);
												
	FormattedSpeakerString = New FormattedString(FormattedSpeakerString,New Font(,,True),,);
	FormattedHistoryString = New FormattedString(FormattedHistoryString,New Font(,,True),,);

	
	If Not Parameters.ThisIsCurPrice Then 
		FormattedHistoryString = New FormattedString(FormattedHistoryString,New Font(,,True),WebColors.Gray);
		FormattedSpeakerString = New FormattedString(FormattedSpeakerString,New Font(,,True),WebColors.Gray);	
	EndIf;					
						
	HistoryStringStructure = New Structure();
	HistoryStringStructure.Insert("FormattedHistoryString",FormattedHistoryString);
	HistoryStringStructure.Insert("FormattedSpeakerString",FormattedSpeakerString);
	HistoryStringStructure.Insert("FormattedStringTrendIcon",FormattedStringTrendIcon);
	HistoryStringStructure.Insert("FormattedStringStartOfString",FormattedStringStartOfString);
	HistoryStringStructure.Insert("FormattedStringByStock",FormattedStringMarketingEvent);
	
	Return HistoryStringStructure;
						
EndFunction

#If Not WebClient Then

// Loads the price tree in Excel
//
// Parameters:
//  Form - ClientApplicationForm - , where you need to calculate prices
//  PrintParameters - Structure - the print settings used in the formation of the printing plate.
//
Procedure UploadToExcelWithoutLink(Form, PrintParameters) Export
	
	Try
		COMObject = New COMObject("Excel.Application");
	Except
		ErrorMessage = NStr("vi = 'Không thể kết xuất đơn giá vào Excel.
		                               |Hãy chắc chắn rằng, trong máy tính có cài đặt chương trình Microsoft Excel.
		                               |Chi tiết:';
		                               |ru = 'Не удалось выгрузить цены в Excel.
		                               |Убедитесь, что на компьютере установлена программа Microsoft Excel.
		                               |Подробности:';
		                               |en = 'Cannot export prices to Excel.
		                               |Make sure Microsoft Excel is installed on your computer.
		                               |More information:'; fa = 'Cannot export prices to Excel.
		                               |Make sure Microsoft Excel is installed on your computer.
		                               |More information:';
		                               |it = 'Non è stato possibile caricare i prezzi su Excel. 
		                               | Verificare che il programma sia installato sul computer.
		                               | Dettagli:';
		                               |pl = 'Nie udało się zładować ceny do programu Excel.
		                               |Upewnij się, że na komputerze jest zainstalowany program Microsoft Excel. 
		                               |Szczegóły:';
		                               |tr = 'Fiyatlar Excel''e yüklenemedi.
		                               |Bilgisayarda Microsoft Excel''in yüklü olduğundan emin ol.
		                               |Detaylar:'") + " "
		                  + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	FileAddressInTempStorage = PriceSetupServerCall.UploadToExcelWithoutLink(
		PredefinedValue("Document.PriceSetup.EmptyRef"),
		Form.UUID,
		PrintParameters);
		
	FilesToObtain = New Array;
	FilesToObtain.Add(New TransferableFileDescription(,FileAddressInTempStorage));
	
	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.DefaultExt = "xls";
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("PrintParameters", PrintParameters);
	AdditionalParameters.Insert("COMObject", COMObject);
	BeginGettingFiles(
		New CallbackDescription("UploadToExcelWithoutStartReceivingFilesLink", SettingPricesClient, AdditionalParameters),
		FilesToObtain,
		FileDialog,
		True);
	
EndProcedure

// Loads data from Excel to the form's price tree
//
// Parameters:
//  Form - ClientApplicationForm - to which you need to load data from Excel.
//
Procedure DownloadFromExcelWithoutLink(Form) Export
	
	Try
		COMObject = New COMObject("Excel.Application");
	Except
		ErrorMessage = NStr("vi = 'Không thể kết nhập đơn giá từ tệp Excel.
		                               |Hãy chắc chắn là trong Server có cài đặt chương trình Microsoft Excel.
		                               |Chi tiết:';
		                               |ru = 'Не удалось загрузить цены из файла Excel.
		                               |Убедитесь, что на сервере установлена программа Microsoft Excel.
		                               |Подробности:';
		                               |en = 'Cannot import prices from Excel file.
		                               |Make sure Microsoft Excel is installed on the server. 
		                               |More information:'; fa = 'Cannot import prices from Excel file.
		                               |Make sure Microsoft Excel is installed on the server. 
		                               |More information:';
		                               |it = 'Non è stato possibile scaricare i prezzi su Excel. 
		                               | Verificare che il programma sia installato sul computer.
		                               | Dettagli:';
		                               |pl = 'Nie udało się pobrać ceny z pliku Excel.
		                               |Upewnij się, że na serwerze jest zainstalowany program Microsoft Excel. 
		                               |Szczegóły:';
		                               |tr = 'Excel dosyasından fiyatlar yüklenemedi.
		                               |Sunucuda Microsoft Excel''in kurulu olduğundan emin ol.
		                               |Ayrıntılar:'")
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("COMObject", COMObject);
	
	TempFileName = Undefined;
	FileDialog = New FileDialog(FileDialogMode.Open);
	FileDialog.Show(
			New CallbackDescription("DownloadFromExcelWithoutLinkFileSelectionDialog",
			SettingPricesClient,
			AdditionalParameters));
	
EndProcedure

#EndIf

#EndRegion

#Region Private

Procedure DownloadFromExcel(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	Try
		COMObject = New COMObject("Excel.Application");
	Except
		ErrorMessage = NStr("vi = 'Không thể kết nhập đơn giá từ tệp Excel.
		                               |Hãy chắc chắn là trong Server có cài đặt chương trình Microsoft Excel.
		                               |Chi tiết:';
		                               |ru = 'Не удалось загрузить цены из файла Excel.
		                               |Убедитесь, что на сервере установлена программа Microsoft Excel.
		                               |Подробности:';
		                               |en = 'Cannot import prices from Excel file.
		                               |Make sure Microsoft Excel is installed on the server. 
		                               |More information:'; fa = 'Cannot import prices from Excel file.
		                               |Make sure Microsoft Excel is installed on the server. 
		                               |More information:';
		                               |it = 'Non è stato possibile scaricare i prezzi su Excel. 
		                               | Verificare che il programma sia installato sul computer.
		                               | Dettagli:';
		                               |pl = 'Nie udało się pobrać ceny z pliku Excel.
		                               |Upewnij się, że na serwerze jest zainstalowany program Microsoft Excel. 
		                               |Szczegóły:';
		                               |tr = 'Excel dosyasından fiyatlar yüklenemedi.
		                               |Sunucuda Microsoft Excel''in kurulu olduğundan emin ol.
		                               |Ayrıntılar:'")
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	TempFileName = Result.FullFileName;
	Form              = AdditionalParameters.Form;
	AttachedFile = AdditionalParameters.AttachedFile;
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	Try
		COMObject.AutomationSecurity = 3; // msoAutomationSecurityForceDisable = 3
		Workbook      = COMObject.Workbooks.Open(TempFileName,,True,,,,,,,,False);
		SettingsSheet = Workbook.Worksheets(1);
		Sheet         = Workbook.Worksheets(2);
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = NStr("vi = 'Không thể kết nhập tệp.
		                               |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".';
		                               |ru = 'Файл не может быть загружен.
		                               |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".';
		                               |en = 'The file cannot be imported.
		                               |You may only import the files exported with command ""Excel -> Export..."".'; fa = 'The file cannot be imported.
		                               |You may only import the files exported with command ""Excel -> Export..."".';
		                               |it = 'Impossibile scaricare il file.
		                               | Possono essere scaricati solo i file caricati tramite il comando ""Excel -> carica...""';
		                               |pl = 'Plik nie może być załadowany.
		                               |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".';
		                               |tr = 'Dosya yüklenemez.
		                               |Sadece ""Excel -> Yükle..."" komutu kullanılarak yüklenen dosyalar yüklenebilir.'");
		Raise ErrorMessage;
	EndTry;
	
	// Arrays of structures
	ArrayOfStructuresTypesOfPrices = New Array;
	ArrayOfDataStructures  = New Array;
	
	ThereIsAdditionalColumn = False;
	
	// Data loading
	Try
		
		// Loading the service table
		LineNumber = 2;
		While ValueIsFilled(SettingsSheet.Cells(LineNumber, 1).Value) Do
			
			NewRow = New Structure("PriceTypeId, ColumnNumberPrice, ColumnNumberPackaging");
			NewRow.PriceTypeId = SettingsSheet.Cells(LineNumber, 1).Value;
			NewRow.ColumnNumberPrice     = SettingsSheet.Cells(LineNumber, 5).Value;
			NewRow.ColumnNumberPackaging = SettingsSheet.Cells(LineNumber, 7).Value;
			ArrayOfStructuresTypesOfPrices.Add(NewRow);
			
			LineNumber = LineNumber + 1;
		EndDo;
		
		If ArrayOfStructuresTypesOfPrices.Count() > 0 Then
			
			// Loading item prices
			LineNumber = 3;
			ThereIsAdditionalColumn = (StrLen(Sheet.Cells(LineNumber, 2).Value) <> 36);
			While ValueIsFilled(Sheet.Cells(LineNumber, 2 + ?(ThereIsAdditionalColumn,1,0)).Value) Do
				
				For Each TSRow In ArrayOfStructuresTypesOfPrices Do
					
					NewRow = New Structure(
						"ProductID_,
						|IdentifierCharacteristic,
						|IDSeriesOfDataCenters,
						|IDOfCentralDataCenter,
						|PackageIdentifier,
						|PriceTypeId,
						|Price");
					NewRow.ProductID_   = Sheet.Cells(LineNumber, 2 + ?(ThereIsAdditionalColumn,1,0)).Value;
					NewRow.IdentifierCharacteristic = Sheet.Cells(LineNumber, 3 + ?(ThereIsAdditionalColumn,1,0)).Value;
					If UsePriceManagementSystem25 Then
						NewRow.IDSeriesOfDataCenters        = Sheet.Cells(LineNumber, 4 + ?(ThereIsAdditionalColumn,1,0)).Value;
						NewRow.IDOfCentralDataCenter     = Sheet.Cells(LineNumber, 5 + ?(ThereIsAdditionalColumn,1,0)).Value;
					EndIf;
					NewRow.PackageIdentifier       = Sheet.Cells(LineNumber, TSRow.ColumnNumberPackaging).Value;
					NewRow.PriceTypeId        = TSRow.PriceTypeId;
					NewRow.Price                        = Sheet.Cells(LineNumber, TSRow.ColumnNumberPrice).Value;
					ArrayOfDataStructures.Add(NewRow);
					
				EndDo;
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
		EndIf;
		
		Workbook.Close(0);
		
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể kết nhập tệp.
			           |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".
			           |Chi tiết: %1';
			           |ru = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |en = 'The file cannot be imported.
			           |You may only import the files exported with the ""Excel -> Export..."" command.
			           |Details: %1'; fa = 'The file cannot be imported.
			           |You may only import the files exported with the ""Excel -> Export..."" command.
			           |Details: %1';
			           |it = 'Impossibile scaricare il file.
			           | Possono essere scaricati solo i file caricati tramite il comando ""Excel -> carica..."".
			           |Dettagli: %1';
			           |pl = 'Plik nie może być załadowany.
			           |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".
			           |Szczegóły:%1';
			           |tr = 'Dosya yüklenemez.
			           |Sadece ""Excel -> Yükle..."" komutuyla yüklenen dosyalar yüklenebilir.
			           |Detaylar: %1'"), BriefErrorDescription(ErrorInfo()));
		Raise ErrorMessage;
	EndTry;
	
	COMObject.Quit();
	COMObject = 0;
	
	Data = New Structure(
		"OwnerForm, TypesOfPrices, Goods", 
		Form.UUID, ArrayOfStructuresTypesOfPrices, ArrayOfDataStructures);
	
	Notify("ImportFromExcel", Data);
	
EndProcedure

Procedure UploadToExcel(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	Try
		COMObject = New COMObject("Excel.Application");
	Except
		ErrorMessage = NStr("vi = 'Không thể kết xuất đơn giá vào Excel.
		                               |Hãy chắc chắn rằng, trong máy tính có cài đặt chương trình Microsoft Excel.
		                               |Chi tiết:';
		                               |ru = 'Не удалось выгрузить цены в Excel.
		                               |Убедитесь, что на компьютере установлена программа Microsoft Excel.
		                               |Подробности:';
		                               |en = 'Cannot export prices to Excel.
		                               |Make sure Microsoft Excel is installed on your computer.
		                               |More information:'; fa = 'Cannot export prices to Excel.
		                               |Make sure Microsoft Excel is installed on your computer.
		                               |More information:';
		                               |it = 'Non è stato possibile caricare i prezzi su Excel. 
		                               | Verificare che il programma sia installato sul computer.
		                               | Dettagli:';
		                               |pl = 'Nie udało się zładować ceny do programu Excel.
		                               |Upewnij się, że na komputerze jest zainstalowany program Microsoft Excel. 
		                               |Szczegóły:';
		                               |tr = 'Fiyatlar Excel''e yüklenemedi.
		                               |Bilgisayarda Microsoft Excel''in yüklü olduğundan emin ol.
		                               |Detaylar:'") + " "
		                  + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
	TempFileName = Result.FullFileName;
	Form              = AdditionalParameters.Form;
	PrintParameters    = AdditionalParameters.PrintParameters;
	OutputCodes       = AdditionalParameters.OutputCodes;
	Information         = AdditionalParameters.Information;
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	Try
		
		COMObject.AutomationSecurity = 3; // msoAutomationSecurityForceDisable = 3
		
		ColumnNumber = ?(UsePriceManagementSystem25, 7, 5) + ?(OutputCodes,1,0);
		LineNumber  = 1;
		
		Workbook = COMObject.Workbooks.Open(TempFileName);
		Sheet = Workbook.Worksheets(1);
		
		// Installing an autofilter on price columns
		Sheet.Range(Sheet.Cells(2, 1), Sheet.Cells(2, 256)).AutoFilter();
		
		// Hiding columns with nomenclature and characteristics identifiers
		Sheet.Columns(2 + ?(OutputCodes,1,0)).Hidden = True;
		Sheet.Columns(3 + ?(OutputCodes,1,0)).Hidden = True;
		If UsePriceManagementSystem25 Then
			Sheet.Columns(4 + ?(OutputCodes,1,0)).Hidden = True;
			Sheet.Columns(5 + ?(OutputCodes,1,0)).Hidden = True;
		EndIf;
		
		// Creating a service table for backloading
		SettingsSheet = Workbook.Worksheets.Add();
		SettingsSheet.Cells(LineNumber, 1).Value = NStr("vi = 'Mã định danh duy nhất';
														|ru = 'Уникальный идентификатор';
														|en = 'UUID'; fa = 'UUID';
														|it = 'Identificatore univoco';
														|pl = 'Unikalny identyfikator';
														|tr = 'Benzersiz tanımlayıcı'");
		SettingsSheet.Cells(LineNumber, 2).Value = NStr("vi = 'Dạng giá';
														|ru = 'Вид цены';
														|en = 'Price type'; fa = 'نوع قیمت';
														|it = 'Tipo di prezzo';
														|pl = 'Rodzaj ceny';
														|tr = 'Fiyat türü'");
		SettingsSheet.Cells(LineNumber, 3).Value = NStr("vi = 'Số cột ""Đơn giá trước đây""';
														|ru = 'Номер колонки ""Старая цена""';
														|en = 'The ""Old price"" column number'; fa = 'The ""Old price"" column number';
														|it = 'Numero colonna ""Prezzo precedente""';
														|pl = 'Numer kolumny ""Stara cena""';
														|tr = '""Eski fiyat"" sütun numarası'");
		SettingsSheet.Cells(LineNumber, 4).Value = NStr("vi = 'Số cột ""Phần trăm thay đổi""';
														|ru = 'Номер колонки ""Процент изменения""';
														|en = 'The ""Change percent"" column number'; fa = 'The ""Change percent"" column number';
														|it = 'Numero colonna ""Percentuale di modifica""';
														|pl = 'Numer kolumny ""Zmiana procentowa""';
														|tr = '""Yüzde değişimi"" sütun numarası'");
		SettingsSheet.Cells(LineNumber, 5).Value = NStr("vi = 'Số cột ""Đơn giá""';
														|ru = 'Номер колонки ""Цена""';
														|en = '""Price"" column number'; fa = '""Price"" column number';
														|it = 'Numero colonna ""Prezzo""';
														|pl = 'Numer kolumny ""Cena""';
														|tr = '""Fiyat"" sütun numarası'");
		SettingsSheet.Cells(LineNumber, 6).Value = NStr("vi = 'Số cột ""Đơn vị tính""';
														|ru = 'Номер колонки ""Единица измерения""';
														|en = 'The ""Unit of measure"" column number'; fa = 'The ""Unit of measure"" column number';
														|it = 'Numero colonna ""Unità di misura""';
														|pl = 'Numer kolumny ""Jednostka miary""';
														|tr = '""Ölçü birimi"" sütun numarası'");
		SettingsSheet.Cells(LineNumber, 7).Value = NStr("vi = 'Số cột ""Tên đơn trị""';
														|ru = 'Номер колонки ""Уникальный идентификатор""';
														|en = 'The ""Unique ID"" column number'; fa = 'The ""Unique ID"" column number';
														|it = 'Numero colonna ""Identificatore unico""';
														|pl = 'Numer kolumny ""Unikalny identyfikator""';
														|tr = '""UUID"" sütun numarası'");
		
		TypesOfPrices = New Array;
		
		LineNumber = LineNumber + 1;
		SettingsTree = GetFromTempStorage(PrintParameters.SettingsTreeForClient);
		For Each PriceKind In SettingsTree.Rows Do
			If PriceKind.Print Then

				PriceTypeParameters = New Structure();
				PriceTypeParameters.Insert("ColumnNumberOldPrice", 0);
				PriceTypeParameters.Insert("ColumnNumberPercentageOfChange", 0);
				PriceTypeParameters.Insert("ColumnNumberPrice", 0);

				DisplayOldPrice       = False;
				DisplayPercentageOfChange = False;
				WithdrawAmountOfChange   = False;
				For Each Column In PriceKind.Rows Do
					If Column.Parameter = "OldPrice" And Column.Print Then
						DisplayOldPrice = True;
					EndIf;
					If Column.Parameter = "ChangePercentage" And Column.Print Then
						DisplayPercentageOfChange = True;
					EndIf;
					If Column.Parameter = "AmountOfChange" And Column.Print Then
						WithdrawAmountOfChange = True;
					EndIf;
				EndDo;
				
				SettingsSheet.Cells(LineNumber, 1).Value = String(PriceKind.Parameter.UUID());
				SettingsSheet.Cells(LineNumber, 2).Value = String(PriceKind.Parameter); // Name of the type of price
				
				If DisplayOldPrice Then
					SettingsSheet.Cells(LineNumber, 3).Value = ColumnNumber; // Old price
					PriceTypeParameters.ColumnNumberOldPrice = ColumnNumber;
					ColumnNumber = ColumnNumber + 1;
				Else
					SettingsSheet.Cells(LineNumber, 3).Value = 0;
				EndIf;
				
				If WithdrawAmountOfChange Then
					SettingsSheet.Cells(LineNumber, 4).Value = ColumnNumber; // Amount of change
					ColumnNumber = ColumnNumber + 1;
				Else
					SettingsSheet.Cells(LineNumber, 4).Value = 0;
				EndIf;
				
				If DisplayPercentageOfChange Then
					SettingsSheet.Cells(LineNumber, 4).Value = ColumnNumber; // Percentage of change
					PriceTypeParameters.ColumnNumberPercentageOfChange = ColumnNumber;
					ColumnNumber = ColumnNumber + 1;
				Else
					SettingsSheet.Cells(LineNumber, 4).Value = 0;
				EndIf;
				
				SettingsSheet.Cells(LineNumber, 5).Value = ColumnNumber; // Price
				PriceTypeParameters.ColumnNumberPrice = ColumnNumber;
				ColumnNumber = ColumnNumber + 1;
				
				SettingsSheet.Cells(LineNumber, 6).Value = ColumnNumber; // Unit
				ColumnNumber = ColumnNumber + 1;
				
				Sheet.Columns(ColumnNumber).Hidden = True;
				SettingsSheet.Cells(LineNumber, 7).Value = ColumnNumber; // Unique identifier of the package
				ColumnNumber = ColumnNumber + 1;
				
				LineNumber = LineNumber + 1;

				TypesOfPrices.Add(PriceTypeParameters);

			EndIf;
		EndDo;

		// Setting formulas

		FormulaTemplate = "=IF(RC[OldPr]<>0,ROUND((RC[ColumnNumberPrice]-RC[OldPr])/RC[OldPr]*100,2),0)";
		
		If TypesOfPrices.Count() > 0 Then
			
			LineNumber = 3;
			While ValueIsFilled(Sheet.Cells(LineNumber, 3).Value) Do
				
				For Each TSRow In TypesOfPrices Do
					
					If TSRow.ColumnNumberOldPrice <> 0
						And TSRow.ColumnNumberPercentageOfChange <> 0
						And TSRow.ColumnNumberPrice <> 0 Then
						
						Formula = StrReplace(FormulaTemplate, "[OldPr]", TSRow.ColumnNumberOldPrice);
						Formula = StrReplace(Formula, "[ColumnNumberPrice]", TSRow.ColumnNumberPrice);
						
						Sheet.Cells(LineNumber, TSRow.ColumnNumberPercentageOfChange).Formula = Formula;
						
					EndIf;
					
				EndDo;
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
		EndIf;
		
		// Installing protection on cells
		Sheet.Protection.AllowEditRanges.Add(
			NStr("vi = 'Đơn giá mặt hàng';
				|ru = 'Цены номенклатуры';
				|en = 'Item prices'; fa = 'قیمت‌های قلم';
				|it = 'Prezzi degli articoli';
				|pl = 'Ceny towarów';
				|tr = 'Ürün fiyatları'"),                                           // Title
			Sheet.Range(Sheet.Cells(3, 1), Sheet.Cells(LineNumber-1, ColumnNumber-1)), // Range
			                                                                            // Password
		);
		
		Sheet.Protect(,//Password
				False,  //DrawingObjects
				True,//Contents
				True,//Scenarios
				False,  //UserInterfaceOnly
				True,//AllowFormattingCells
				True,//AllowFormattingColumns
				True,//AllowFormattingRows
				False,  //AllowInsertingColumns
				False,  //AllowInsertingRows
				True,//AllowInsertingHyperlinks
				False,  //AllowDeletingColumns
				False,  //AllowDeletingRows
				True,//AllowSorting
				True,//AllowFiltering
				True); //AllowUsingPivotTables
		
		SettingsSheet.Visible = False;
		Workbook.Save();
		Workbook.Close(0);
		
		COMObject.Quit();
		COMObject = 0;
		
		Notification = New CallbackDescription(
			"UploadEndToExcel",
			ThisObject,
			AdditionalParameters);
		
		FilesOperationsClient.PutAttachedFile(
			Notification,
			Information.File,
			Form.UUID);
		
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = NStr("vi = 'Không thể ghi lại dữ liệu vào tệp. Chi tiết:';
							|ru = 'Не удалось записать данные в файл. Подробности:';
							|en = 'Cannot save data to file. More information:'; fa = 'Cannot save data to file. More information:';
							|it = 'Non è stato possibile registrare i dati nel file. Dettagli:';
							|pl = 'Nie udało się zapisać danych do pliku. Szczegóły:';
							|tr = 'Dosyaya veriler kaydedilmedi. Ayrıntılar:'") + " "
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

Procedure UploadEndToExcel(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorDescription) Then
		Raise Result.ErrorDescription;
	EndIf;
	
	Information = AdditionalParameters.Information;
	
	FilesOperationsClient.OpenFileForm(Information.File);
	
EndProcedure

// Change parameters in the price tree element.
// 
// Parameters:
//  ExecutionOption -String - Execution option
// 
// Returns:
//  Structure - Change Parameters In The Price Tree Element:
// * ExecutionOption - String
// * ColumnNamePackaging - String
// * NameOfEditBanColumn - String
// * ComplianceOfFactorsOfPackagesOfProductRange - Undefined
// * CurPackingValue - Undefined
// * CurrentValue - Undefined
// * SourcePricePackingRatio - Number
// * CurColumnName - String
// * NewFormula - String
// * ChangePercentage - Number
// * AmountOfChange - Number
// * ChangedPercentage - Boolean
// * ChangedFormula - Boolean
// * AmountChanged_ - Boolean
// * Products - CatalogRef.Products, Undefined -
// * UseItemPackages - Boolean
Function ChangeParametersInPriceTreeElement(ExecutionOption) Export
	CallParameters = New Structure();
	CallParameters.Insert("ExecutionOption", ExecutionOption);
	CallParameters.Insert("ColumnNamePackaging", "");
	CallParameters.Insert("NameOfEditBanColumn", "");
	
	If ExecutionOption = "FillOutProductPackaging" Then
		CallParameters.Insert("ArrayOfProductPackagingStructures", Undefined);
	ElsIf ExecutionOption = "ChangePackingInPriceTreeRow"
			Or CallParameters.ExecutionOption = "ChangeCurrencyInPriceTreeLine"
			Or CallParameters.ExecutionOption = "ChangePersonalIncomeTaxRateInLineOfPriceTree" Then
		CallParameters.Insert("CurrentValue", Undefined);
		CallParameters.Insert("CurColumnName", "");
	ElsIf ExecutionOption = "ChangeDataInPriceTreeRow" Then
		CallParameters.Insert("ComplianceOfFactorsOfPackagesOfProductRange", Undefined);
		CallParameters.Insert("CurPackingValue", Undefined);
		CallParameters.Insert("CurrentValue", Undefined);
		CallParameters.Insert("SourcePricePackingRatio", 0);
		CallParameters.Insert("CurColumnName", "");
		CallParameters.Insert("NewFormula", "");
		CallParameters.Insert("ChangePercentage", 0);
		CallParameters.Insert("AmountOfChange", 0);
		CallParameters.Insert("ChangedPercentage", False);
		CallParameters.Insert("ChangedFormula", False);
		CallParameters.Insert("AmountChanged_", False);
		CallParameters.Insert("Products", Undefined);
		CallParameters.Insert("UseItemPackages", False);
	EndIf;
	
	Return CallParameters;
EndFunction

Procedure ApplyChangesToPriceTree(PriceTreeElement, CallParameters) Export

	PriceTreeElementsCur = PriceTreeElement.GetItems();
	
	For Each PriceTreeElementCur In PriceTreeElementsCur Do
		
		If PriceTreeElementCur[CallParameters.NameOfEditBanColumn] Then
			Continue;
		EndIf;

		If CallParameters.ExecutionOption = "FillOutProductPackaging" Then
			FillOutProductPackaging(PriceTreeElementCur, CallParameters);
		ElsIf CallParameters.ExecutionOption = "ChangeDataInPriceTreeRow" Then 
			ChangeDataInPriceTreeRow(PriceTreeElementCur, CallParameters);
		ElsIf CallParameters.ExecutionOption = "ChangePackingInPriceTreeRow"
				Or CallParameters.ExecutionOption = "ChangeCurrencyInPriceTreeLine" Then
			CurColumnName 	= CallParameters.CurColumnName;
			CurrentValue 	= CallParameters.CurrentValue;
			
			PriceTreeElementCur[CurColumnName] = CurrentValue;
		
		ElsIf CallParameters.ExecutionOption = "ChangePersonalIncomeTaxRateInLineOfPriceTree" Then
			
			CurColumnName 	= CallParameters.CurColumnName;
			CurrentValue 	= CallParameters.CurrentValue;
			PriceTreeElementCur[CurColumnName] = CurrentValue;
			
			PriceTreeElementCur["ChangedManually" + CurColumnName] = 
					PriceTreeElementCur[CurColumnName] <> PriceTreeElementCur["Original" + CurColumnName];
			PriceTreeElementCur["ChangedAutomatically" + CurColumnName] = False;
	
		EndIf;
		
		ApplyChangesToPriceTree(PriceTreeElementCur, CallParameters);
		
	EndDo;
	
EndProcedure

// Parameters:
// 	CurPriceTreeElement - FormField
// 	CallParameters - Structure - Where:
//   * ArrayOfProductPackagingStructures - Array - array of packages.
Procedure FillOutProductPackaging(CurPriceTreeElement, CallParameters)
	ColumnValuePackaging = CurPriceTreeElement[CallParameters.ColumnNamePackaging];
	If ValueIsFilled(ColumnValuePackaging) 
		And SettingPricesClientServer.FindProductPackingStructureInArray(CallParameters.ArrayOfProductPackagingStructures, 
																				CurPriceTreeElement.Products, 
																				ColumnValuePackaging) = Undefined Then
		Structure = SettingPricesClientServer.InitializeProductPackagingDescription();
		Structure.Products = CurPriceTreeElement.Products;
		Structure.Package = ColumnValuePackaging;
		CallParameters.ArrayOfProductPackagingStructures.Add(Structure)
	EndIf;
EndProcedure

Procedure ChangeDataInPriceTreeRow(CurPriceTreeElement, Val CallParameters)

	CurColumnName 	= CallParameters.CurColumnName;
	CurrentValue 	= CallParameters.CurrentValue;
	SourcePricePackingRatio 				= CallParameters.SourcePricePackingRatio;
	ComplianceOfFactorsOfPackagesOfProductRange 	= CallParameters.ComplianceOfFactorsOfPackagesOfProductRange;
	
	If CallParameters.UseItemPackages Then
		
		ColumnValuePackaging = CurPriceTreeElement[CallParameters.ColumnNamePackaging];
		If CallParameters.CurPackingValue = ColumnValuePackaging
			And CurPriceTreeElement[CurColumnName] <> CurrentValue Then
			
			If CallParameters.ChangedPercentage Then
				
				If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = CallParameters.ChangePercentage;
					CurPriceTreeElement[CurColumnName] = Round(
						CurPriceTreeElement["OldPrice" + CurColumnName] * ((CurPriceTreeElement["ChangePercentage"+CurColumnName] / 100) + 1), 15, 2);
				Else
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
					CurPriceTreeElement[CurColumnName] = 0;
				EndIf;
			ElsIf CallParameters.ChangedFormula Then
				 	
				CurPriceTreeElement["Formula"+CurColumnName] = CallParameters.NewFormula;
				// we calculate using the formula
				// fill in the deviations 
				If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
						100 * (CurPriceTreeElement[CurColumnName]
						     - CurPriceTreeElement["OldPrice"+CurColumnName]) / CurPriceTreeElement["OldPrice"+CurColumnName], 5, 2);
				Else
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
				EndIf;
			ElsIf CallParameters.AmountChanged_ Then
			
				CurPriceTreeElement[CurColumnName] = CurPriceTreeElement["OldPrice" + CurColumnName] 
														+CurPriceTreeElement["AmountOfChange"+CurColumnName];
				
				If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
						100 * (CurPriceTreeElement[CurColumnName]
						       - CurPriceTreeElement["OldPrice"+CurColumnName]) / CurPriceTreeElement["OldPrice" + CurColumnName],
						5,
						2);
				Else
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
				EndIf;
			Else
				CurPriceTreeElement[CurColumnName] = CurrentValue;
				If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
						100 * (CurPriceTreeElement[CurColumnName]
													- CurPriceTreeElement["OldPrice"+CurColumnName]) 
													/ CurPriceTreeElement["OldPrice"+CurColumnName], 5, 2);
				Else
					CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
				EndIf;
			EndIf;
			CurPriceTreeElement["AmountOfChange"+CurColumnName] = 
			CurPriceTreeElement[CurColumnName] - CurPriceTreeElement["OldPrice"+CurColumnName];
			
			CurPriceTreeElement["ChangedManually"       + CurColumnName] = 
													(CurPriceTreeElement["AmountOfChange"+CurColumnName] <> 0);
			CurPriceTreeElement["ChangedAutomatically" + CurColumnName] = False;
			
		Else
			
			// Let's determine the packing coefficient of the influencing price
			DestinationPricePackingRatio = 1;
			
			If ValueIsFilled(ColumnValuePackaging) And ComplianceOfFactorsOfPackagesOfProductRange <> Undefined Then
				SearchResult = SettingPricesClientServer.GetProductPackingRatio(ComplianceOfFactorsOfPackagesOfProductRange, 
																							CallParameters.Products, 
																							ColumnValuePackaging);
				If SearchResult <> Undefined Then
					DestinationPricePackingRatio = SearchResult;
				EndIf;
			EndIf;
			
			If SourcePricePackingRatio = DestinationPricePackingRatio Then
				NewPrice = CurrentValue;
			Else
				NewPrice = CurrentValue / SourcePricePackingRatio * DestinationPricePackingRatio;
			EndIf;
			
			If CurPriceTreeElement[CurColumnName] <> NewPrice Or CallParameters.ChangedFormula Then
				
				If CallParameters.ChangedPercentage Then
					 
					If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = CallParameters.ChangePercentage;
						CurPriceTreeElement[CurColumnName] = Round(
							CurPriceTreeElement["OldPrice" + CurColumnName] 
							* ((CurPriceTreeElement["ChangePercentage"+CurColumnName] / 100) + 1), 15, 2);
					Else
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
						CurPriceTreeElement[CurColumnName] = 0;
					EndIf;
				
				ElsIf CallParameters.ChangedFormula Then
					 	
					CurPriceTreeElement["Formula"+CurColumnName] = CallParameters.NewFormula;
					// filling in the deviations 
					If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
							100 * (CurPriceTreeElement[CurColumnName]
							       - CurPriceTreeElement["OldPrice"+CurColumnName]) 
							       / CurPriceTreeElement["OldPrice" + CurColumnName],
							5,
							2);
					Else
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
					EndIf;
					
				ElsIf CallParameters.AmountChanged_ Then
				
					CurPriceTreeElement[CurColumnName] = 
											CurPriceTreeElement["OldPrice" + CurColumnName] 
											+ CurPriceTreeElement["AmountOfChange"+CurColumnName];
					
					If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
							100 * (CurPriceTreeElement[CurColumnName]
							       - CurPriceTreeElement["OldPrice"+CurColumnName]) / CurPriceTreeElement["OldPrice" + CurColumnName],
							5,
							2);
					Else
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
					EndIf;
					
				Else
					
					CurPriceTreeElement[CurColumnName] = NewPrice;
					
					If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
							100 * (CurPriceTreeElement[CurColumnName]
							       - CurPriceTreeElement["OldPrice"+CurColumnName]) 
							       / CurPriceTreeElement["OldPrice" + CurColumnName],
							5,
							2);
					Else
						CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
					EndIf;
					
				EndIf;
				
				CurPriceTreeElement["AmountOfChange"+CurColumnName] = 
					CurPriceTreeElement[CurColumnName]-CurPriceTreeElement["OldPrice"+CurColumnName];
				CurPriceTreeElement["ChangedManually"       + CurColumnName] = 
													(CurPriceTreeElement["AmountOfChange"+CurColumnName] <> 0);
				CurPriceTreeElement["ChangedAutomatically" + CurColumnName] = False;
				
			EndIf;
			
		EndIf;
		
	Else
		
		NewPrice = CurrentValue;
		
		If CallParameters.ChangedFormula Then
			
			CurPriceTreeElement["Formula"+CurColumnName] = CallParameters.NewFormula;
		
		EndIf;	
		
		If CurPriceTreeElement[CurColumnName] <> NewPrice Or CallParameters.ChangedFormula Then
					
			CurPriceTreeElement[CurColumnName] = NewPrice;
			CurPriceTreeElement["ChangedManually"       + CurColumnName] = 
													(CurPriceTreeElement[CurColumnName] 
													- CurPriceTreeElement["OldPrice" + CurColumnName] <> 0);
			CurPriceTreeElement["ChangedAutomatically" + CurColumnName] = False;
			
			If CurPriceTreeElement["OldPrice"+CurColumnName] <> 0 Then
				CurPriceTreeElement["ChangePercentage"+CurColumnName] = Round(
					100 * (CurPriceTreeElement[CurColumnName]
					 - CurPriceTreeElement["OldPrice"+CurColumnName])/CurPriceTreeElement["OldPrice"+CurColumnName],
					5,
					2);
				CurPriceTreeElement["AmountOfChange"+CurColumnName] = CurPriceTreeElement[CurColumnName]-CurPriceTreeElement["OldPrice"+CurColumnName];
			Else
				CurPriceTreeElement["ChangePercentage"+CurColumnName] = 0;
				CurPriceTreeElement["AmountOfChange"+CurColumnName] = 0;
			EndIf;
		EndIf;
		
	EndIf;
EndProcedure

// Parameters:
// 	ObtainedFiles - Array of TransferableFileDescription - 
// 	AdditionalParameters - Structure - Additional parameters
Procedure UploadToExcelWithoutLinkStartReceivingFilesEndWEB(ObtainedFiles, AdditionalParameters) Export
	
	If ObtainedFiles = Undefined Then
		Return;
	EndIf;
	
	FullName = ObtainedFiles[0].FullName;

	RunAppAsync(FullName);	
	
EndProcedure

Procedure DownloadFromExcelWithoutLinkFileSelectionDialogEndWEB(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	FullName = SelectedFiles[0];
	
	CallbackOnCompletion = New CallbackDescription("DownloadFromExcelProcessFileOnServerEnd", ThisObject, AdditionalParameters);

	BeginPutFileToServer(CallbackOnCompletion, , , ,FullName, AdditionalParameters.UUID);	
	
EndProcedure

Procedure DownloadFromExcelProcessFileOnServerEnd(StoredFileDescription, AdditionalParameters) Export

	Data = PriceSetupServerCall.ProcessDownloadFromExcelPriceListOnServer(StoredFileDescription.Address, AdditionalParameters);
	
	Notify("ImportFromExcel", Data);		

EndProcedure

Procedure OpenVATRatesForm(Form, Date) Export
	
	ClearMessages();
	
	Items = Form["Items"];
	
	CompletionProcedureName = "SettingsForFillingInVATRatesEnd";
	
	ArrayOfPriceTypes = New Array();
	For Each LineTypesOfPrice In Form.SelectedPrices Do
		
		If Not (LineTypesOfPrice.Selected_5 And LineTypesOfPrice.Edit) Then
			Continue;
		EndIf;
		
		If LineTypesOfPrice.OptionForSpecifyingVATRates =
				PredefinedValue("Enum.OptionsForSpecifyingVATRatesInPriceList.SpecifiedVATRatesLineByLine") Then
			
			ArrayOfPriceTypes.Add(New Structure("PriceKind, Country",	LineTypesOfPrice.Ref, 
																		LineTypesOfPrice.Country));
		EndIf;
			
	EndDo;
	
	If Not ValueIsFilled(ArrayOfPriceTypes) Then
		MessageText = NStr("ru = 'В прайс-листе отсутствуют виды цен с построчным заполнением ""Ставки НДС.""';
							|vi = 'The price list does not contain price types with line-by-line filling of the ""VAT rate.""';
							|en = 'The price list does not contain price types with line-by-line filling of the ""VAT rate.""'; fa = 'The price list does not contain price types with line-by-line filling of the ""VAT rate.""';
							|it = 'The price list does not contain price types with line-by-line filling of the ""VAT rate.""';
							|pl = 'The price list does not contain price types with line-by-line filling of the ""VAT rate.""';
							|tr = 'Fiyat listesinde satır başına ""KDV oranı"" doldurulan fiyat türleri bulunmamaktadır.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	OnlySelectedItems = Items.PriceTree.SelectedRows.Count() > 1;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ArrayOfPriceTypes", ArrayOfPriceTypes);
	OpeningParameters.Insert("OnlySelectedItems", OnlySelectedItems);
	OpeningParameters.Insert("ValidityDate", Date);
	
	OpenForm(
		"DataProcessor.PriceList.Form.SettingsForFillingInVATRatesForm",
		OpeningParameters,
		ThisObject,,,, New CallbackDescription(CompletionProcedureName, Form), FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#If Not WebClient Then

// Parameters:
// 	ObtainedFiles - Array of TransferableFileDescription - 
// 	AdditionalParameters - Structure - Additional parameters
Procedure UploadToExcelWithoutStartReceivingFilesLink(ObtainedFiles, AdditionalParameters) Export
	
	If ObtainedFiles = Undefined Then
		Return;
	EndIf;
	
	Form           = AdditionalParameters.Form;
	PrintParameters = AdditionalParameters.PrintParameters;
	COMObject       = AdditionalParameters.COMObject;
	
	OutputCodes = ?(ValueIsFilled(Form.AdditionalColumnName), True, False);
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	Try
		
		ColumnNumber = ?(UsePriceManagementSystem25, 7, 5) + ?(OutputCodes,1,0);
		LineNumber  = 1;
		
		COMObject.AutomationSecurity = 3; // msoAutomationSecurityForceDisable = 3
		
		Workbook = COMObject.Workbooks.Open(ObtainedFiles[0].FullName);
		Sheet = Workbook.Worksheets(1);
		Sheet.name = NStr("vi = 'Bảng giá';
							|ru = 'Прайс-лист';
							|en = 'Price list'; fa = 'فهرست قیمت';
							|it = 'Прайс-лист';
							|pl = 'Price list';
							|tr = 'Fiyat listesi'");
		
		// Installing an autofilter on price columns
		Sheet.Range(Sheet.Cells(2, 1), Sheet.Cells(2, 256)).AutoFilter();
		
		// Hiding columns with nomenclature and characteristics identifiers
		Sheet.Columns(2 + ?(OutputCodes,1,0)).Hidden = True;
		Sheet.Columns(3 + ?(OutputCodes,1,0)).Hidden = True;
		
		If UsePriceManagementSystem25 Then
			Sheet.Columns(4 + ?(OutputCodes,1,0)).Hidden = True;
			Sheet.Columns(5 + ?(OutputCodes,1,0)).Hidden = True;
		EndIf;
		
		LastSheetNumber = Workbook.WorkSheets.Count;		
		
		// Creating a service table for backloading
		SettingsSheet = Workbook.Worksheets.Add(, Workbook.WorkSheets(LastSheetNumber));
		SettingsSheet.name = " ";
		SettingsSheet.Cells(LineNumber, 1).Value = NStr("vi = 'Mã định danh duy nhất';
														|ru = 'Уникальный идентификатор';
														|en = 'UUID'; fa = 'UUID';
														|it = 'Identificatore univoco';
														|pl = 'Unikalny identyfikator';
														|tr = 'Benzersiz tanımlayıcı'");
		SettingsSheet.Columns(1).Hidden = True;
		SettingsSheet.Cells(LineNumber, 2).Value = NStr("vi = 'Dạng giá';
														|ru = 'Вид цены';
														|en = 'Price type'; fa = 'نوع قیمت';
														|it = 'Tipo di prezzo';
														|pl = 'Rodzaj ceny';
														|tr = 'Fiyat türü'");
		SettingsSheet.Columns(2).Hidden = True;
		SettingsSheet.Cells(LineNumber, 3).Value = NStr("vi = 'Số cột ""Đơn giá trước đây""';
														|ru = 'Номер колонки ""Старая цена""';
														|en = 'The ""Old price"" column number'; fa = 'The ""Old price"" column number';
														|it = 'Numero colonna ""Prezzo precedente""';
														|pl = 'Numer kolumny ""Stara cena""';
														|tr = '""Eski fiyat"" sütun numarası'");
		SettingsSheet.Columns(3).Hidden = True;
		SettingsSheet.Cells(LineNumber, 4).Value = NStr("vi = 'Số cột ""Phần trăm thay đổi""';
														|ru = 'Номер колонки ""Процент изменения""';
														|en = 'The ""Change percent"" column number'; fa = 'The ""Change percent"" column number';
														|it = 'Numero colonna ""Percentuale di modifica""';
														|pl = 'Numer kolumny ""Zmiana procentowa""';
														|tr = '""Yüzde değişimi"" sütun numarası'");
		SettingsSheet.Columns(4).Hidden = True;
		SettingsSheet.Cells(LineNumber, 5).Value = NStr("vi = 'Số cột ""Đơn giá""';
														|ru = 'Номер колонки ""Цена""';
														|en = '""Price"" column number'; fa = '""Price"" column number';
														|it = 'Numero colonna ""Prezzo""';
														|pl = 'Numer kolumny ""Cena""';
														|tr = '""Fiyat"" sütun numarası'");
		SettingsSheet.Columns(5).Hidden = True;
		SettingsSheet.Cells(LineNumber, 6).Value = NStr("vi = 'Số cột ""Đơn vị tính""';
														|ru = 'Номер колонки ""Единица измерения""';
														|en = 'The ""Unit of measure"" column number'; fa = 'The ""Unit of measure"" column number';
														|it = 'Numero colonna ""Unità di misura""';
														|pl = 'Numer kolumny ""Jednostka miary""';
														|tr = '""Ölçü birimi"" sütun numarası'");
		SettingsSheet.Columns(6).Hidden = True;
		SettingsSheet.Cells(LineNumber, 7).Value = NStr("vi = 'Số cột ""Tên đơn trị""';
														|ru = 'Номер колонки ""Уникальный идентификатор""';
														|en = 'The ""Unique ID"" column number'; fa = 'The ""Unique ID"" column number';
														|it = 'Numero colonna ""Identificatore unico""';
														|pl = 'Numer kolumny ""Unikalny identyfikator""';
														|tr = '""UUID"" sütun numarası'");
		SettingsSheet.Columns(7).Hidden = True;
		
		LineNumber = LineNumber + 1;
		SettingsTree = GetFromTempStorage(PrintParameters.SettingsTreeForClient);
		For Each PriceKind In SettingsTree.Rows Do
			If PriceKind.Print Then
				
				DisplayOldPrice       = False;
				DisplayPercentageOfChange = False;
				WithdrawAmountOfChange   = False;
				For Each Column In PriceKind.Rows Do
					If Column.Parameter = "OldPrice" And Column.Print Then
						DisplayOldPrice = True;
					EndIf;
					If Column.Parameter = "ChangePercentage" And Column.Print Then
						DisplayPercentageOfChange = True;
					EndIf;
					If Column.Parameter = "AmountOfChange" And Column.Print Then
						WithdrawAmountOfChange = True;
					EndIf;
				EndDo;
				
				SettingsSheet.Cells(LineNumber, 1).Value = String(PriceKind.Parameter.UUID());
				SettingsSheet.Cells(LineNumber, 2).Value = String(PriceKind.Parameter); // Name of the type of price
				
				If DisplayOldPrice Then
					SettingsSheet.Cells(LineNumber, 3).Value = ColumnNumber; // Old price
					ColumnNumber = ColumnNumber + 1;
				Else
					SettingsSheet.Cells(LineNumber, 3).Value = 0;
				EndIf;
				
				If WithdrawAmountOfChange Then
					SettingsSheet.Cells(LineNumber, 4).Value = ColumnNumber; // Amount of change
					ColumnNumber = ColumnNumber + 1;
				Else
					SettingsSheet.Cells(LineNumber, 4).Value = 0;
				EndIf;
				
				If DisplayPercentageOfChange Then
					SettingsSheet.Cells(LineNumber, 4).Value = ColumnNumber; // Percentage of change
					ColumnNumber = ColumnNumber + 1;
				Else
					SettingsSheet.Cells(LineNumber, 4).Value = 0;
				EndIf;
				
				SettingsSheet.Cells(LineNumber, 5).Value = ColumnNumber; // Price
				ColumnNumber = ColumnNumber + 1;
				
				SettingsSheet.Cells(LineNumber, 6).Value = ColumnNumber; // Unit
				ColumnNumber = ColumnNumber + 1;
				
				Sheet.Columns(ColumnNumber).Hidden = True;
				SettingsSheet.Cells(LineNumber, 7).Value = ColumnNumber; // Unique identifier of the package
				ColumnNumber = ColumnNumber + 1;
				
				LineNumber = LineNumber + 1;
				
			EndIf;
		EndDo;
		
		TypesOfPrices = New Array;
		
		// Loading the service table
		LineNumber = 2;
		While ValueIsFilled(SettingsSheet.Cells(LineNumber, 1).Value) Do
			
			NewRow = New Structure("ColumnNumberOldPrice, ColumnNumberPercentageOfChange, ColumnNumberPrice");
			NewRow.ColumnNumberOldPrice       = SettingsSheet.Cells(LineNumber, 3).Value;
			NewRow.ColumnNumberPercentageOfChange = SettingsSheet.Cells(LineNumber, 4).Value;
			NewRow.ColumnNumberPrice             = SettingsSheet.Cells(LineNumber, 5).Value;
			TypesOfPrices.Add(NewRow);
			
			LineNumber = LineNumber + 1;
			
		EndDo;
		
		FormulaTemplate = "=IF(RC[OldPr]<>0,ROUND((RC[ColumnNumberPrice]-RC[OldPr])/RC[OldPr]*100,2),0)";
		
		If TypesOfPrices.Count() > 0 Then
			
			LineNumber = 3;
			While ValueIsFilled(Sheet.Cells(LineNumber, 3).Value) Do
				
				For Each TSRow In TypesOfPrices Do
					
					If TSRow.ColumnNumberOldPrice <> 0
						And TSRow.ColumnNumberPercentageOfChange <> 0
						And TSRow.ColumnNumberPrice <> 0 Then
						
						Formula = StrReplace(FormulaTemplate, "[OldPr]", TSRow.ColumnNumberOldPrice);
						Formula = StrReplace(Formula, "[ColumnNumberPrice]", TSRow.ColumnNumberPrice);
						
						Sheet.Cells(LineNumber, TSRow.ColumnNumberPercentageOfChange).Formula = Formula;
						
					EndIf;
					
				EndDo;
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
		EndIf;
		
		// Installing protection on cells
		Sheet.Protection.AllowEditRanges.Add(
			NStr("vi = 'Đơn giá mặt hàng';
				|ru = 'Цены номенклатуры';
				|en = 'Item prices'; fa = 'قیمت‌های قلم';
				|it = 'Prezzi degli articoli';
				|pl = 'Ceny towarów';
				|tr = 'Ürün fiyatları'"),                                           // Title
			Sheet.Range(Sheet.Cells(3, 1), Sheet.Cells(LineNumber-1, ColumnNumber-1)), // Range
			                                                                            // Password
		);
		
		Sheet.Protect(,//Password
				False,  //DrawingObjects
				True,//Contents
				True,//Scenarios
				False,  //UserInterfaceOnly
				True,//AllowFormattingCells
				True,//AllowFormattingColumns
				True,//AllowFormattingRows
				False,  //AllowInsertingColumns
				False,  //AllowInsertingRows
				True,//AllowInsertingHyperlinks
				False,  //AllowDeletingColumns
				False,  //AllowDeletingRows
				True,//AllowSorting
				True,//AllowFiltering
				True); //AllowUsingPivotTables
		
		Workbook.Worksheets(1).Activate();
		Workbook.Save();
		
		COMObject.Application.Visible = True;
		Workbook.Activate();
		
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = NStr("vi = 'Không thể ghi lại dữ liệu vào tệp. Chi tiết:';
							|ru = 'Не удалось записать данные в файл. Подробности:';
							|en = 'Cannot save data to file. More information:'; fa = 'Cannot save data to file. More information:';
							|it = 'Non è stato possibile registrare i dati nel file. Dettagli:';
							|pl = 'Nie udało się zapisać danych do pliku. Szczegóły:';
							|tr = 'Dosyaya veriler kaydedilmedi. Ayrıntılar:'") + " "
		                    + BriefErrorDescription(ErrorInfo());
		Raise ErrorMessage;
	EndTry;
	
EndProcedure

Procedure DownloadFromExcelWithoutLinkFileSelectionDialog(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	Form           = AdditionalParameters.Form;
	COMObject       = AdditionalParameters.COMObject;
	UsePriceManagementSystem25 = Form.UsePriceManagementSystem25;
	
	Try
		COMObject.AutomationSecurity = 3; // msoAutomationSecurityForceDisable = 3
		Workbook      = COMObject.Workbooks.Open(SelectedFiles[0],,True,,,,,,,,False);
		Sheet         = Workbook.Worksheets(1);
		SettingsSheet = Workbook.Worksheets(2);
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể kết nhập tệp.
			           |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".
			           |Chi tiết: %1';
			           |ru = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |en = 'The file cannot be imported.
			           |You may only import the files exported with the ""Excel -> Export..."" command.
			           |Details: %1'; fa = 'The file cannot be imported.
			           |You may only import the files exported with the ""Excel -> Export..."" command.
			           |Details: %1';
			           |it = 'Impossibile scaricare il file.
			           | Possono essere scaricati solo i file caricati tramite il comando ""Excel -> carica..."".
			           |Dettagli: %1';
			           |pl = 'Plik nie może być załadowany.
			           |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".
			           |Szczegóły:%1';
			           |tr = 'Dosya yüklenemez.
			           |Sadece ""Excel -> Yükle..."" komutuyla yüklenen dosyalar yüklenebilir.
			           |Detaylar: %1'"), BriefErrorDescription(ErrorInfo()));
		Raise ErrorMessage;
	EndTry;
	
	// Arrays of structures
	ArrayOfStructuresTypesOfPrices = New Array;
	ArrayOfDataStructures  = New Array;
	
	ThereIsAdditionalColumn = False;
	
	// Data loading
	Try
		
		// Loading the service table
		LineNumber = 2;
		While ValueIsFilled(SettingsSheet.Cells(LineNumber, 1).Value) Do
			
			NewRow = New Structure("PriceTypeId, ColumnNumberPrice, ColumnNumberPackaging");
			NewRow.PriceTypeId = SettingsSheet.Cells(LineNumber, 1).Value;
			NewRow.ColumnNumberPrice     = SettingsSheet.Cells(LineNumber, 5).Value;
			NewRow.ColumnNumberPackaging = SettingsSheet.Cells(LineNumber, 7).Value;
			ArrayOfStructuresTypesOfPrices.Add(NewRow);
			
			LineNumber = LineNumber + 1;
		EndDo;
		
		If ArrayOfStructuresTypesOfPrices.Count() > 0 Then
			
			// Loading item prices
			LineNumber = 3;
			ThereIsAdditionalColumn = (StrLen(Sheet.Cells(LineNumber, 2).Value) <> 36);
			While ValueIsFilled(Sheet.Cells(LineNumber, 2 + ?(ThereIsAdditionalColumn,1,0)).Value) Do
				
				For Each TSRow In ArrayOfStructuresTypesOfPrices Do
					
					NewRow = New Structure(
						"ProductID_,
						|IdentifierCharacteristic,
						|IDSeriesOfDataCenters,
						|IDOfCentralDataCenter,
						|PackageIdentifier,
						|PriceTypeId,
						|Price");
					NewRow.ProductID_   = Sheet.Cells(LineNumber, 2 + ?(ThereIsAdditionalColumn,1,0)).Value;
					NewRow.IdentifierCharacteristic = Sheet.Cells(LineNumber, 3 + ?(ThereIsAdditionalColumn,1,0)).Value;
					If UsePriceManagementSystem25 Then
						NewRow.IDSeriesOfDataCenters        = Sheet.Cells(LineNumber, 4 + ?(ThereIsAdditionalColumn,1,0)).Value;
						NewRow.IDOfCentralDataCenter     = Sheet.Cells(LineNumber, 5 + ?(ThereIsAdditionalColumn,1,0)).Value;
					EndIf;
					NewRow.PackageIdentifier       = Sheet.Cells(LineNumber, TSRow.ColumnNumberPackaging).Value;
					NewRow.PriceTypeId        = TSRow.PriceTypeId;
					NewRow.Price                        = Sheet.Cells(LineNumber, TSRow.ColumnNumberPrice).Value;
					ArrayOfDataStructures.Add(NewRow);
					
				EndDo;
				
				LineNumber = LineNumber + 1;
				
			EndDo;
			
		EndIf;
		
		Workbook.Close(0);
		
	Except
		COMObject.Quit();
		COMObject = 0;
		ErrorMessage = StrTemplate(
			NStr("vi = 'Không thể kết nhập tệp.
			           |Chỉ có thể kết nhập các tệp đã kết xuất thông qua lệnh ""Exel -> Kết xuất..."".
			           |Chi tiết: %1';
			           |ru = 'Файл не может быть загружен.
			           |Загружаться могут только файлы, выгруженные с помощью команды ""Excel -> Выгрузить..."".
			           |Подробности: %1';
			           |en = 'The file cannot be imported.
			           |You may only import the files exported with the ""Excel -> Export..."" command.
			           |Details: %1'; fa = 'The file cannot be imported.
			           |You may only import the files exported with the ""Excel -> Export..."" command.
			           |Details: %1';
			           |it = 'Impossibile scaricare il file.
			           | Possono essere scaricati solo i file caricati tramite il comando ""Excel -> carica..."".
			           |Dettagli: %1';
			           |pl = 'Plik nie może być załadowany.
			           |Ładować można tylko pliki, przekazane za pomocą polecenia ""Excel -> Wyślij..."".
			           |Szczegóły:%1';
			           |tr = 'Dosya yüklenemez.
			           |Sadece ""Excel -> Yükle..."" komutuyla yüklenen dosyalar yüklenebilir.
			           |Detaylar: %1'"), BriefErrorDescription(ErrorInfo()));
		Raise ErrorMessage;
	EndTry;
	
	COMObject.Quit();
	COMObject = 0;
	
	Data = New Structure(
		"OwnerForm, TypesOfPrices, Goods", 
		Form.UUID, ArrayOfStructuresTypesOfPrices, ArrayOfDataStructures);
	
	Notify("ImportFromExcel", Data);
	
EndProcedure

#EndIf

#EndRegion

#EndIf
