#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// It is used as a background task for loading process description data into an information database.
// Parameters:
//  GenerationParameters  - Structure - 
//  StorageAddress         - String - the address of the temporary storage where the upload result will be placed
//
Procedure UploadProcessDescriptionsToInformationDatabase(GenerationParameters, StorageAddress) Export
	
	ImportResult1 = ResultOfUploadingDataToInformationDatabase(GenerationParameters);
	
	PutToTempStorage(ImportResult1, StorageAddress);
	
EndProcedure 

// Uploads process description and glossary data to the information database
//
// Parameters:
//  GenerationParameters  - Structure - 
//
// Returns:
//   Structure  - Contains:
//     * Success               - Boolean - indicates that the report was generated successfully.
//     * ErrorsMessages    - Array of String - error messages in case the data preparation failed.
//     * DownloadData        - Structure -
//
Function ResultOfUploadingDataToInformationDatabase(GenerationParameters) Export
	
	ImportResult1 = New Structure;
	ImportResult1.Insert("Success",                True);
	ImportResult1.Insert("ErrorsMessages",     New Array);
	ImportResult1.Insert("DownloadData",         NewQuantitativeDownloadResults());
	ImportResult1.Insert("FoundMappings", NewFoundMappingsWhenLoading());
	
	ImportDataToInfobase(ImportResult1, 
	                                   GenerationParameters.ProcessDescriptionTree, 
	                                   GenerationParameters.Glossary, 
	                                   MatchingScreenshotsByTable(GenerationParameters.Screenshots),
	                                   GenerationParameters.SupportPlacementParameters);
	
	Return ImportResult1;
	
EndFunction

// Used by the background job of reading the archive file for uploading process descriptions.
// Parameters:
//  GenerationParameters  - Structure - 
//  StorageAddress         - String - the address of the temporary storage where the upload result will be placed
//
Procedure ReadDownloadFileData(GenerationParameters, StorageAddress) Export
	
	ImportResult1 = ResultOfReadingDownloadArchiveFile(GenerationParameters);
	
	PutToTempStorage(ImportResult1, StorageAddress);
	
EndProcedure 

// Uploads data from the upload file to the Attributes of the upload processing forms
//
// Parameters:
//  GenerationParameters  - Structure - 
//
// Returns:
//   Structure  - Contains:
//     * Success               - Boolean - indicates that the report was generated successfully.
//     * ErrorsMessages    - Array of String - error messages in case the data preparation failed.
//     * DownloadData        - Structure -
//
Function ResultOfReadingDownloadArchiveFile(GenerationParameters) Export
	
	ImportResult1 = New Structure;
	ImportResult1.Insert("Success",                True);
	ImportResult1.Insert("ErrorsMessages",     New Array);
	ImportResult1.Insert("DownloadData",         New Structure);
	
	ReadDataOfDownloadArchiveFile(ImportResult1, 
	                                   GenerationParameters);
	
	Return ImportResult1;
	
EndFunction

#EndRegion

#Region Private

Function NewQuantitativeDownloadResults()
	
	DownloadResults = New Structure;
	DownloadResults.Insert("LoadedScripts", 0);
	DownloadResults.Insert("UpdatedScripts", 0);
	DownloadResults.Insert("DeletedScripts",   0);
	DownloadResults.Insert("UploadedGlossary", 0);
	DownloadResults.Insert("UpdatedGlossary", 0);
	DownloadResults.Insert("GlossaryRemoved",   0);
	
	Return DownloadResults;
	
EndFunction

Function NewFoundMappingsWhenLoading()
	
	FoundMappings = New Structure; 
	
	FoundMappings.Insert("MetadataObjects",  New Map);
	FoundMappings.Insert("AccessGroupProfiles",New Map);
	FoundMappings.Insert("BudgetingScenarios",           New Map); 
	
	Return FoundMappings;
	
EndFunction

Procedure ImportDataToInfobase(ImportResult1, ProcessDescriptionTree, Glossary, Screenshots, SupportPlacementParameters)
	
	For Each TreeRow In ProcessDescriptionTree.Rows Do
		
		LoadProcessDescriptionsByTreeLine(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	EndDo;
	
	For Each TreeRow In Glossary.Rows Do
		
		DownloadGlossaryByTreeLine(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	EndDo;
	
	If SupportPlacementParameters.OptionOfSettingUpForSupport = 0
		And Not SupportPlacementParameters.ThisIsPartialUpload Then
		
		CompleteStatementForSupport(ProcessDescriptionTree, Glossary, SupportPlacementParameters);
		
	EndIf;
	
EndProcedure

Function MatchingScreenshotsByTable(TableScreenshots) 
	
	MatchingScreenshotsByTable = New Map;
	
	For Each TableRow In TableScreenshots Do
		
		MatchingScreenshotsByTable.Insert(TableRow.ScreenshotID, TableRow.BinaryData);
		
	EndDo;
	
	Return MatchingScreenshotsByTable
	
EndFunction

#Region GlossaryDownload

#Region LoadingGlossaryCatalogItem

Procedure DownloadGlossaryByTreeLine(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters) 
	
	If TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.ToImport
		Or TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Union Then
		
		DownloadGlossary(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	ElsIf TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Delete Then
		
		DeleteGlossary(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		DownloadGlossaryByTreeLine(SubordinateRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters)
		
	EndDo; 
	
EndProcedure

Procedure DeleteGlossary(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters)
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(TreeRow.Glossary.FullName());
		LockItem.SetValue("Ref", TreeRow.Glossary);
		Block.Lock();
	
		ObjectGlossary = TreeRow.Glossary.GetObject();
		
		If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
			
			ObjectGlossary.SetDeletionMark(True);
			ImportResult1.DownloadData.GlossaryRemoved = ImportResult1.DownloadData.GlossaryRemoved + 1;
			TreeRow.ProcessingIsTakenIntoAccount = True;
			
		ElsIf TreeRow.TypeOfUploadSettingsLine = "LongDesc" Then 
			
			SearchParameters = New Structure;
			SearchParameters.Insert("LanguageCode", TreeRow.LanguageCode);
			
			FoundRows = ObjectGlossary.GlossaryDetails.FindRows(SearchParameters);
			For Each FoundRow In FoundRows Do
				
				ObjectGlossary.GlossaryDetails.Delete(FoundRow);
				
			EndDo;
			
			ObjectGlossary.Write();
			
			ParentString = TreeRow.Parent;
			If Not ParentString.ProcessingIsTakenIntoAccount Then
				ImportResult1.DownloadData.GlossaryRemoved = ImportResult1.DownloadData.GlossaryRemoved + 1;
				ParentString.ProcessingIsTakenIntoAccount = True;
			EndIf;
			
		EndIf;
	
	Except
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Procedure DownloadGlossary(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters)
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
		
		DownloadGlossaryCatalogItem(TreeRow, ImportResult1, SupportPlacementParameters); 
		
	ElsIf TreeRow.TypeOfUploadSettingsLine = "LongDesc" Then 
		
		DownloadGlossaryDescriptionInLanguage(TreeRow, ImportResult1, Screenshots, SupportPlacementParameters);
		
	EndIf;
	
EndProcedure

Procedure DownloadGlossaryDescriptionInLanguage(TreeRow, ImportResult1, Screenshots, SupportPlacementParameters)
	
	If TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Union Then
		DataToImport = TreeRow.MergeResult;
	Else
		DataToImport = TreeRow.FileData;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(TreeRow.Parent.Glossary.Metadata().FullName());
		LockItem.SetValue("Ref",  TreeRow.Parent.Glossary);
		Block.Lock();
	
		ObjectGlossary = TreeRow.Parent.Glossary.GetObject(); // CatalogObject.Glossary
		
		SearchParameters = New Structure;
		SearchParameters.Insert("LanguageCode", TreeRow.LanguageCode);
		
		FoundRows = ObjectGlossary.GlossaryDetails.FindRows(SearchParameters); 
		
		If FoundRows.Count() > 0 Then
			
			IsUpdate = True;
			StringWithDescription = FoundRows[0];
			
		Else
			
			IsUpdate     = False;
			StringWithDescription  = ObjectGlossary.GlossaryDetails.Add();
			StringWithDescription.LanguageCode = TreeRow.LanguageCode;
			
		EndIf;
		
		FormattedDescriptionDocument = DemoScenariosClientServer.FormattedDocumentFromHTMLData(DataToImport, New Structure);
		StringWithDescription.LongDesc       = New ValueStorage(FormattedDescriptionDocument);
		
		If SupportPlacementParameters.OptionOfSettingUpForSupport = 0
			And Not SupportPlacementParameters.ThisIsPartialUpload Then
			
			StringWithDescription.VendorDataHash = TreeRow.HashDataOfFile;
			
		EndIf;
		
		ObjectGlossary.Write();
		
		ParentString = TreeRow.Parent;
		
		If Not ParentString.ProcessingIsTakenIntoAccount Then
		
			If IsUpdate Then
				ImportResult1.DownloadData.UpdatedGlossary = ImportResult1.DownloadData.UpdatedGlossary + 1;
			Else
				ImportResult1.DownloadData.UploadedGlossary = ImportResult1.DownloadData.UploadedGlossary + 1;
			EndIf;
			
			ParentString.ProcessingIsTakenIntoAccount = True;
		
		EndIf;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Procedure DownloadGlossaryCatalogItem(TreeRow, ImportResult1, SupportPlacementParameters) 
	
	ErrorText = NStr("vi = 'Lỗi khi đọc tệp mục tin mô tả kịch bản';
					|ru = 'Ошибка при чтении файла реквизитов описания сценария';
					|en = 'An error occurred when reading the file of scenario details attributes'; fa = 'An error occurred when reading the file of scenario details attributes';
					|it = 'Ошибка при чтении файла реквизитов описания сценария';
					|pl = 'An error occurred when reading the file of scenario details attributes';
					|tr = 'Senaryo ayrıntılarının öznitelikler dosyası okunurken hata oluştu'");
	
	If TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Union Then
		DataToImport = TreeRow.MergeResult;
	Else
		DataToImport = TreeRow.FileData;
	EndIf;
	
	ReadingResult = DemoScenarios.ResultOfReadingJSONString(DataToImport, ErrorText);
	
	If Not ReadingResult.Success Then
		Return;
	EndIf;
	
	JSONData    = ReadingResult.Data;
	IsUpdate = False;
	
	BeginTransaction();
	
	Try
	
		If ValueIsFilled(TreeRow.Glossary)
			And TreeRow.RefExists Then
			
			Block = New DataLock;
			LockItem = Block.Add(TreeRow.Glossary.Metadata().FullName());
			LockItem.SetValue("Ref", TreeRow.Glossary);
			Block.Lock();
			
			ObjectGlossary = TreeRow.Glossary.GetObject();
			IsUpdate   = True;
			
		Else
			
			Try
				
				LinkID = New UUID(JSONData.UUID);
				
			Except
				
				Return;
				
			EndTry;
			
			ObjectGlossary = Catalogs.Glossary.CreateItem();
			
			ObjectGlossary.SetNewObjectRef(Catalogs.Glossary.GetRef(LinkID));
			
		EndIf;
		
		FillInCatalogObjectGlossaryAccordingToJSONData(ObjectGlossary, JSONData, ImportResult1);
		
		If SupportPlacementParameters.OptionOfSettingUpForSupport = 0
			And Not SupportPlacementParameters.ThisIsPartialUpload Then
			
			ObjectGlossary.VendorDataHash = TreeRow.HashDataOfFile;
			
		EndIf;
		
		ObjectGlossary.Write();
		
		If IsUpdate Then
			ImportResult1.DownloadData.UpdatedGlossary = ImportResult1.DownloadData.UpdatedGlossary + 1;
		Else
			ImportResult1.DownloadData.UploadedGlossary = ImportResult1.DownloadData.UploadedGlossary + 1;
		EndIf;
		
		TreeRow.ProcessingIsTakenIntoAccount = True;
		
		CommitTransaction();
	
	Except 
		
		RollbackTransaction();
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
	
	EndTry;
	
	
EndProcedure 

Procedure FillInCatalogObjectGlossaryAccordingToJSONData(ObjectGlossary, JSONData, ImportResult1) 
	
	ObjectGlossary.Description      = JSONData.Name;
	ObjectGlossary.DescriptionLanguage1 = JSONData.NameLanguage1;
	ObjectGlossary.DescriptionLanguage2 = JSONData.NameLanguage2;
	ObjectGlossary.Code               = JSONData.Code;
	
	If ObjectGlossary.DeletionMark <> JSONData.DeletionMark Then
		ObjectGlossary.SetDeletionMark(JSONData.DeletionMark)
	EndIf;
	
	AddRowOfTablePartById(ObjectGlossary, 
	                                             "ConfigurationObjects", 
	                                             "ConfigurationObject", 
	                                             JSONData.ObjectsOfMetadata, 
	                                             "MetadataObjectIDs", 
	                                             ImportResult1.FoundMappings.MetadataObjects); 
	
EndProcedure

#EndRegion

#EndRegion

#Region ProcessDetailsImport

#Region LoadingCatalogItemProcessDescription

Procedure LoadProcessDescriptionsByTreeLine(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters) 
	
	
	If TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.ToImport
		Or TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Union Then
		
		UploadProcessDescription(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	ElsIf TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Delete Then
		
		DeleteProcessDescription(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		LoadProcessDescriptionsByTreeLine(SubordinateRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters);
		
	EndDo;
	
EndProcedure

Procedure DeleteProcessDescription(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters)
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(TreeRow.Scenario.Metadata().FullName());
		LockItem.SetValue("Ref", TreeRow.Scenario);
		Block.Lock();
	
		ScenarioObject = TreeRow.Scenario.GetObject();
	
		If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
			
			ScenarioObject.SetDeletionMark(True);
			ImportResult1.DownloadData.DeletedScripts = ImportResult1.DownloadData.DeletedScripts + 1;
			TreeRow.ProcessingIsTakenIntoAccount = True;
			
		ElsIf TreeRow.TypeOfUploadSettingsLine = "LongDesc" Then 
			
			SearchParameters = New Structure;
			SearchParameters.Insert("LanguageCode", TreeRow.LanguageCode);
			
			FoundRows = ScenarioObject.ScenarioDescriptions.FindRows(SearchParameters);
			For Each FoundRow In FoundRows Do
				
				If ValueIsFilled(TreeRow.AttachedFile) Then
					AttachedFileObject = TreeRow.AttachedFile.GetObject();
					AttachedFileObject.SetDeletionMark(True);
				EndIf;
				
				ScenarioObject.ScenarioDescriptions.Delete(FoundRow);
				
			EndDo;
			
			ScenarioObject.Write();
			
			ParentString = TreeRow.Parent;
			If Not ParentString.ProcessingIsTakenIntoAccount Then
				ImportResult1.DownloadData.DeletedScripts = ImportResult1.DownloadData.DeletedScripts + 1;
				ParentString.ProcessingIsTakenIntoAccount = True;
			EndIf;
			
		EndIf;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
		
EndProcedure

Procedure UploadProcessDescription(TreeRow, ImportResult1, Glossary, Screenshots, SupportPlacementParameters)
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
		
		LoadCatalogItemProcessDescription(TreeRow, ImportResult1, SupportPlacementParameters); 
		
	ElsIf TreeRow.TypeOfUploadSettingsLine = "LongDesc" Then 
		
		UploadDescriptionOfProcessInLanguage(TreeRow, ImportResult1, Screenshots, SupportPlacementParameters);
		
	EndIf;
	
EndProcedure

Procedure LoadCatalogItemProcessDescription (TreeRow, ImportResult1, SupportPlacementParameters)
	
	ErrorText = NStr("vi = 'Lỗi khi đọc tệp mục tin mô tả kịch bản';
					|ru = 'Ошибка при чтении файла реквизитов описания сценария';
					|en = 'An error occurred when reading the file of scenario details attributes'; fa = 'An error occurred when reading the file of scenario details attributes';
					|it = 'Ошибка при чтении файла реквизитов описания сценария';
					|pl = 'An error occurred when reading the file of scenario details attributes';
					|tr = 'Senaryo ayrıntılarının öznitelikler dosyası okunurken hata oluştu'");
	
	If TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Union Then
		DataToImport = TreeRow.MergeResult;
	Else
		DataToImport = TreeRow.FileData;
	EndIf;
	
	ReadingResult = DemoScenarios.ResultOfReadingJSONString(DataToImport, ErrorText);
	
	If Not ReadingResult.Success Then
		Return;
	EndIf;
	
	JSONData    = ReadingResult.Data;
	IsUpdate = False;
	
	BeginTransaction();
	
	Try
		
		If ValueIsFilled(TreeRow.Scenario)
			And TreeRow.RefExists Then
			
			Block = New DataLock;
			LockItem = Block.Add(TreeRow.Scenario.Metadata().FullName());
			LockItem.SetValue("Ref", TreeRow.Scenario);
			Block.Lock();
			
			ScenarioObject = TreeRow.Scenario.GetObject();
			IsUpdate  = True;
			
		Else
				
			Try
				
				LinkID = New UUID(JSONData.UUID);
				
			Except
				
				Return;
				
			EndTry;
			
			If JSONData.IsGroup Then
				
				ScenarioObject = Catalogs.DemoScenarios.CreateFolder()
				
			Else
				
				ScenarioObject = Catalogs.DemoScenarios.CreateItem();
				
			EndIf; 
			
			ScenarioObject.SetNewObjectRef(Catalogs.DemoScenarios.GetRef(LinkID));
			
		EndIf;
		
		FillInCatalogObjectDescriptionOfProcessesAccordingToJSONData(ScenarioObject, JSONData, ImportResult1);
		
		If SupportPlacementParameters.OptionOfSettingUpForSupport = 0
			And Not SupportPlacementParameters.ThisIsPartialUpload Then
			
			ScenarioObject.VendorDataHash = TreeRow.HashDataOfFile;
			
		EndIf;
		
		ScenarioObject.AdditionalProperties.Insert("NotRecalculateFullCatalogCode", True);
		ScenarioObject.Write(); 
		
		If ScenarioObject.DeletionMark <> JSONData.DeletionMark Then
			ScenarioObject.SetDeletionMark(JSONData.DeletionMark);
		EndIf;
		
		If IsUpdate Then
			ImportResult1.DownloadData.UpdatedScripts = ImportResult1.DownloadData.UpdatedScripts + 1;
		Else
			ImportResult1.DownloadData.LoadedScripts = ImportResult1.DownloadData.LoadedScripts + 1;
		EndIf;
		
		TreeRow.ProcessingIsTakenIntoAccount = True;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Procedure FillInCatalogObjectDescriptionOfProcessesAccordingToJSONData(ScenarioObject, JSONData, ImportResult1);
	
	ScenarioObject.Description      = JSONData.Name;
	ScenarioObject.DescriptionLanguage1 = JSONData.NameLanguage1;
	ScenarioObject.DescriptionLanguage2 = JSONData.NameLanguage2;

	ScenarioObject.Code          = JSONData.Code;
	ScenarioObject.Comment  = JSONData.Comment;
	ScenarioObject.FullCode    = JSONData.FullCode;
	ScenarioObject.Status       = Enums.ProcessDetailsStatuses.Get(JSONData.Status);
	ScenarioObject.Parent     = ParentOfCatalogElement(ScenarioObject, JSONData.Parent, "DemoScenarios");
	
	If JSONData.IsGroup 
		And ScenarioObject.IsFolder Then
		
		ScenarioObject.GroupType = Enums.TypesOfProcessDetailsGroups.Get(JSONData.KindOfGroup); 
		
	EndIf;
	
	If Not ScenarioObject.IsFolder Then
	
		AddRowOfTablePartById(ScenarioObject, 
		                                             "AccessGroupProfiles", 
		                                             "Profile", 
		                                             JSONData.AccessGroupProfiles, 
		                                             "AccessGroupProfiles", 
		                                             ImportResult1.FoundMappings.AccessGroupProfiles);
		
		AddRowOfTablePartById(ScenarioObject, 
		                                             "ConfigurationObjects", 
		                                             "ConfigurationObject", 
		                                             JSONData.ObjectsOfMetadata, 
		                                             "MetadataObjectIDs", 
		                                             ImportResult1.FoundMappings.MetadataObjects); 
	
	EndIf;
	
EndProcedure 

Procedure AddRowOfTablePartById(ScenarioObject, TabularSectionName, AttributeName, ArrayOfIdentifiers, CatalogName, MatchingWhatWasFound)
	
	ScenarioObject[TabularSectionName].Clear();
	
	For Each CatalogID In ArrayOfIdentifiers Do
		
		LinkToCatalog = MatchingWhatWasFound.Get(CatalogID);
		
		If LinkToCatalog = Undefined Then
		
			Result = ResultOfGettingLinkToCatalogByUniqueIdentifier(CatalogID, CatalogName);
			If Result.Success Then
				
				LinkToCatalog = Result.Ref;
				
			Else
				
				LinkToCatalog = "";
				
			EndIf;
			
			MatchingWhatWasFound.Insert(CatalogID, LinkToCatalog);
			
		EndIf;
		
		If ValueIsFilled(LinkToCatalog) Then
			
			NewRow = ScenarioObject[TabularSectionName].Add();
			NewRow[AttributeName] = LinkToCatalog;
			
		EndIf;
		
	EndDo;
	
EndProcedure 

Function ParentOfCatalogElement(CatalogObject, IDAsString, CatalogName)
	
	ResultOfGettingLink = ResultOfGettingLinkToCatalogByUniqueIdentifier(IDAsString, CatalogName);
	 
	If ResultOfGettingLink.Success Then
		
		Return ResultOfGettingLink.Ref;
		
	Else
		
		Return Catalogs[CatalogName].EmptyRef();
		
	EndIf;
	
	
EndFunction

Function ResultOfGettingLinkToCatalogByUniqueIdentifier(IDAsString, CatalogName)
	
	Result = New Structure;
	Result.Insert("Success",           False);
	Result.Insert("ErrorMessage", "");
	Result.Insert("Ref",            Undefined); 
	
	If IsBlankString(IDAsString) Then
		
		Result.ErrorMessage = NStr("vi = 'Không tìm thấy liên kết đến phần tử danh mục ""%1"" theo tên định danh """"';
									|ru = 'Ссылка на элемент справочника ""%1"" по  идентификатору """"не найдена';
									|en = 'The reference to the %1 catalog item by the ID is not found'; fa = 'The reference to the %1 catalog item by the ID is not found';
									|it = 'Ссылка на элемент справочника ""%1"" по  идентификатору """"не найдена';
									|pl = 'The reference to the %1 catalog item by the ID is not found';
									|tr = '"""" kimliğine göre ""%1"" kataloğunun öğesine bağlantı bulunamadı'");
		Return Result;
		
	EndIf;
	
	Try
		
		ObjectID = New UUID(IDAsString);
		
	Except
		
		Result.ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Return Result;
		
	EndTry;
	
	LinkToCatalog = Catalogs[CatalogName].GetRef(ObjectID);
	
	If Common.ObjectAttributeValue(LinkToCatalog, "Ref") = Undefined Then
		
		Result.ErrorMessage = NStr("vi = 'Không tìm thấy liên kết đến phần tử danh mục ""%1"" theo tên định danh ""%2""';
									|ru = 'Ссылка на элемент справочника ""%1"" по  идентификатору ""%2""не найдена';
									|en = 'The reference to the %1 catalog item by ID %2 is not found'; fa = 'The reference to the %1 catalog item by ID %2 is not found';
									|it = 'Ссылка на элемент справочника ""%1"" по  идентификатору ""%2""не найдена';
									|pl = 'The reference to the %1 catalog item by ID %2 is not found';
									|tr = '""%2"" kimliğine göre ""%1"" kataloğunun öğesine bağlantı bulunamadı'");
		
	Else
		
		Result.Success = True;
		Result.Ref  = LinkToCatalog;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion 

#Region UploadingProcessDescriptionInLanguage

Procedure UploadDescriptionOfProcessInLanguage(TreeRow, ImportResult1, Screenshots, SupportPlacementParameters)
	
	If TreeRow.WhatToDo = Enums.ActionOptionsWhileImportingProcessDetails.Union Then
		DataToImport = TreeRow.MergeResult;
	Else
		DataToImport = TreeRow.FileData;
	EndIf;
	
	ParentString = TreeRow.Parent;
	
	If ValueIsFilled(TreeRow.AttachedFile) Then
		
		ResultOfUpdatingDescriptionFile(TreeRow.AttachedFile, DataToImport);
		If Not ParentString.ProcessingIsTakenIntoAccount Then
			ImportResult1.DownloadData.UpdatedScripts = ImportResult1.DownloadData.UpdatedScripts + 1;
			ParentString.ProcessingIsTakenIntoAccount = True;
		EndIf;
		
		If SupportPlacementParameters.OptionOfSettingUpForSupport = 0
				And Not SupportPlacementParameters.ThisIsPartialUpload Then
				
			BeginTransaction();
				
			Try
		
				Block = New DataLock;
				LockItem = Block.Add(ParentString.Scenario.Metadata().FullName());
				LockItem.SetValue("Ref", ParentString.Scenario);
				Block.Lock();
				
				ScenarioObject = ParentString.Scenario.GetObject();
				
				ScreenshotsOfDescriptionToBeAdded = ScreenshotsOfDescriptionToBeAdded(TreeRow.FileData, Screenshots);
				AddScreenshotFilesForDescription(ScenarioObject, ScreenshotsOfDescriptionToBeAdded);
				
				SearchParameters = New Structure;
				SearchParameters.Insert("AttachedFile", TreeRow.AttachedFile); 
				
				FoundRows = ScenarioObject.ScenarioDescriptions.FindRows(SearchParameters);
				If FoundRows.Count() > 1 Then
					FoundRows[0].VendorDataHash = TreeRow.HashDataOfFile;
					ScenarioObject.Write();
				EndIf;
				
				CommitTransaction();
			
			Except
				
				RollbackTransaction();
				
				Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
			EndTry;
		
		EndIf;
		
	Else
		
		CreationResult = ResultOfCreatingDescriptionFile(ParentString.Scenario, ParentString.FullCode, TreeRow.LanguageCode, TreeRow.FileData);
		
		If CreationResult.Success Then
			
			TreeRow.AttachedFile = CreationResult.AttachedFile;
			
			BeginTransaction();
			
			Try
		
				Block = New DataLock;
				LockItem = Block.Add(ParentString.Scenario.Metadata().FullName());
				LockItem.SetValue("Ref", ParentString.Scenario);
				Block.Lock();
			
				ScenarioObject = ParentString.Scenario.GetObject();
				If ScenarioObject.DeletionMark Then
					ScenarioObject.SetDeletionMark(False);
				EndIf;
				NewDescriptionLine  = ScenarioObject.ScenarioDescriptions.Add();
				NewDescriptionLine.LanguageCode           = TreeRow.LanguageCode;
				NewDescriptionLine.AttachedFile = CreationResult.AttachedFile;
				
				If SupportPlacementParameters.OptionOfSettingUpForSupport = 0
					And Not SupportPlacementParameters.ThisIsPartialUpload Then
			
					NewDescriptionLine.VendorDataHash = TreeRow.HashDataOfFile;
			
				EndIf;
				
				ScreenshotsOfDescriptionToBeAdded = ScreenshotsOfDescriptionToBeAdded(TreeRow.FileData, Screenshots);
				AddScreenshotFilesForDescription(ScenarioObject, ScreenshotsOfDescriptionToBeAdded);
				
				ScenarioObject.AdditionalProperties.Insert("NotRecalculateFullCatalogCode", True);
				ScenarioObject.Write();
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
		
				Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
			EndTry
			
		EndIf;
		
		If Not ParentString.ProcessingIsTakenIntoAccount Then
			
			ImportResult1.DownloadData.LoadedScripts = ImportResult1.DownloadData.LoadedScripts + 1;
			ParentString.ProcessingIsTakenIntoAccount = True; 
			
		EndIf;
		
	EndIf;

EndProcedure

Function ScreenshotsOfDescriptionToBeAdded(DetailsText, Screenshots)
	
	ScreenshotsOfDescription               = New Array;
	
	If Screenshots.Count() = 0 Then
		Return ScreenshotsOfDescription;
	EndIf;
	
	PrefixOfAttachedFileLink = DemoScenariosClientServer.PrefixOfAttachedFileLink();
	PrefixLength                   = StrLen(PrefixOfAttachedFileLink);
	
	UniqueRefs = DemoScenarios.UniqueLinksInHTML5Document(DetailsText);
	
	For Each UniqueLink In UniqueRefs Do 
	
	PositionOfFound = StrFind(UniqueLink, PrefixOfAttachedFileLink);
	
		If PositionOfFound <> 0 Then
			
			ScreenshotID = Right(UniqueLink, StrLen(UniqueLink) - PositionOfFound -  PrefixLength + 1);
			BinaryData = Screenshots.Get(ScreenshotID); 
			If BinaryData = Undefined Then
				Continue;
			EndIf;
			
			ScreenshotData = New Structure;
			ScreenshotData.Insert("ScreenshotID", ScreenshotID);
			ScreenshotData.Insert("BinaryData",         BinaryData);
			
			ScreenshotsOfDescription.Add(ScreenshotData);
			
		EndIf;
	
	EndDo;
	
	Return ScreenshotsOfDescription; 
	
EndFunction

Procedure AddScreenshotFilesForDescription(ScenarioObject, ScreenshotsOfDescriptionToBeAdded)
	
	For Each ScreenshotData In ScreenshotsOfDescriptionToBeAdded Do
		
		SearchParameters = New Structure;
		SearchParameters.Insert("ScreenshotID", ScreenshotData.ScreenshotID);
		FoundRows = ScenarioObject.IDsOfScreenshotFiles.FindRows(SearchParameters);
		
		If FoundRows.Count() > 0 Then
			
			DemoScenarios.ResultOfUpdatingAttachedFile(FoundRows[0].AttachedFile, Undefined, ScreenshotData.BinaryData);
			
		Else
			
			CreationResult = ResultOfCreatingAttachedFile(ScenarioObject.Ref, 
			                                                          ScreenshotData.ScreenshotID, 
			                                                          "png", 
			                                                          ScreenshotData.BinaryData);
			
			If CreationResult.Success Then 
				
				NewRow = ScenarioObject.IDsOfScreenshotFiles.Add();
				NewRow.ScreenshotID = ScreenshotData.ScreenshotID;
				NewRow.AttachedFile     = CreationResult.AttachedFile;
				
			EndIf;
			
		EndIf
		
	EndDo;
	
EndProcedure

Function ResultOfCreatingDescriptionFile(FileOwner, FullCode, LanguageCode, NTMLText)
	
	FileBinaryData = GetBinaryDataFromString(NTMLText);
	FileName = DemoScenariosClientServer.NameOfScriptDescriptionFile(FullCode,LanguageCode);
	
	Return ResultOfCreatingAttachedFile(FileOwner, FileName, "html", FileBinaryData);
	
EndFunction

Function ResultOfUpdatingDescriptionFile(AttachedFile, NTMLText)
	
	FileBinaryData = GetBinaryDataFromString(NTMLText);
	
	Return DemoScenarios.ResultOfUpdatingAttachedFile(AttachedFile, Undefined, FileBinaryData); 
	
EndFunction

Function ResultOfCreatingAttachedFile(FileOwner, FileNameWithoutExtension, Extension, FileBinaryData)
	
	CreationResult = New Structure;
	CreationResult.Insert("Success",            False);
	CreationResult.Insert("AttachedFile", Undefined);
	CreationResult.Insert("ErrorText",        "");
	
	AddressInTempStorage = PutToTempStorage(FileBinaryData);
	
	FileRecordingOptions = FilesOperations.FileAddingOptions(); 
	FileRecordingOptions.FilesOwner              = FileOwner;
	FileRecordingOptions.BaseName            = FileNameWithoutExtension;
	FileRecordingOptions.ExtensionWithoutPoint          = Extension;
	FileRecordingOptions.ModificationTimeUniversal = Undefined;
	
	Try
	
		CreatedAttachedFile = FilesOperations.AppendFile(
		                                    FileRecordingOptions,
		                                    AddressInTempStorage,
		                                    "");
	
	Except
		
		CreationResult.ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return CreationResult;
		
	EndTry;
	
	CreationResult.Success            = True;
	CreationResult.AttachedFile = CreatedAttachedFile;
	
	Return CreationResult;
	
EndFunction

#EndRegion

#EndRegion

#Region SettingUpForSupport

Procedure CompleteStatementForSupport(ProcessDescriptionTree, Glossary, SupportPlacementParameters)
	
	BeginTransaction();
	
	Try
	
		SetUpToSupportDescriptionOfProcesses(ProcessDescriptionTree);
	
		SubmitGlossaryForSupport(Glossary);
	
		DemoScenarios.SetProcessDescriptionConstantOnSupport(SupportPlacementParameters.DescriptionOfLoadedDelivery, SupportPlacementParameters.VendorOfDownloadableDelivery);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
	
	EndTry;	
	
EndProcedure

Procedure SubmitGlossaryForSupport(Glossary)
	
	If Glossary.Rows.Count() = 0 Then
		Return;
	EndIf;
	
	GlossaryTableForSupportApplications = New ValueTable;
	GlossaryTableForSupportApplications.Columns.Add("Glossary",           New TypeDescription("CatalogRef.Glossary"));
	GlossaryTableForSupportApplications.Columns.Add("VendorDataHash", Common.TypeDescriptionNumber(10, 0));
	
	TableOfDescriptionsInLanguageForSupport = New ValueTable;
	TableOfDescriptionsInLanguageForSupport.Columns.Add("Glossary",           New TypeDescription("CatalogRef.Glossary"));
	TableOfDescriptionsInLanguageForSupport.Columns.Add("LanguageCode",            Common.StringTypeDetails(2));
	TableOfDescriptionsInLanguageForSupport.Columns.Add("VendorDataHash", Common.TypeDescriptionNumber(10, 0)); 
	
	For Each TreeRow In Glossary.Rows Do
		
		ProcessGlossaryTreeRowForSupportStatementTable(TreeRow, GlossaryTableForSupportApplications, TableOfDescriptionsInLanguageForSupport);
		
	EndDo;
	
	Query = New Query;
	Query.Text = QueryTextSupportForGlossary();
	
	Query.SetParameter("Glossary",        GlossaryTableForSupportApplications);
	Query.SetParameter("DescriptionsInLanguage",  TableOfDescriptionsInLanguageForSupport);
	
	QueryResult = Query.Execute();
	
	RefsSelection = QueryResult.Select(QueryResultIteration.ByGroups);
	
	RecordRequiredVendorHashesGlossary(RefsSelection);
	
EndProcedure

Procedure RecordRequiredVendorHashesGlossary(RefsSelection)
	
	While RefsSelection.Next() Do
		
		Try
		
			Block = New DataLock;
			LockItem = Block.Add(RefsSelection.Glossary.Metadata().FullName());
			LockItem.SetValue("Ref", RefsSelection.Glossary);
			Block.Lock();
		
			ObjectGlossary = RefsSelection.Glossary.GetObject();
			
			SelectionOfUpdatedHashes = RefsSelection.Select();
			
			While SelectionOfUpdatedHashes.Next() Do
				
				If SelectionOfUpdatedHashes.ThisIsDescriptionStringInLanguage Then
					
					SearchParameters = New Structure;
					SearchParameters.Insert("LineNumber", SelectionOfUpdatedHashes.LineNumber);
					SearchParameters.Insert("LanguageCode",    SelectionOfUpdatedHashes.LanguageCode);
					
					FoundRows = ObjectGlossary.GlossaryDetails.FindRows(SearchParameters);
					
					For Each FoundRow In FoundRows Do
						
						 FoundRow.VendorDataHash = SelectionOfUpdatedHashes.VendorDataHash;
						
					EndDo;
					
				Else
					
					ObjectGlossary.VendorDataHash = SelectionOfUpdatedHashes.VendorDataHash;
					
				EndIf;
				
			EndDo; 
			
			ObjectGlossary.Write();
		
		Except
		
			Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		EndTry;
		
	EndDo;
	
EndProcedure

Function QueryTextSupportForGlossary()
	
	Return "
	|SELECT
	|	GlossaryData.Glossary           AS Glossary,
	|	GlossaryData.VendorDataHash AS VendorDataHash
	|INTO GlossaryOfVendorHashes
	|FROM
	|	&Glossary AS GlossaryData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DescriptionsInLanguage.Glossary           AS Glossary,
	|	DescriptionsInLanguage.LanguageCode            AS LanguageCode,
	|	DescriptionsInLanguage.VendorDataHash AS VendorDataHash
	|INTO DescriptionsInVendorHashLanguages
	|FROM
	|	&DescriptionsInLanguage AS DescriptionsInLanguage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogGlossary.Ref                               AS Glossary,
	|	ISNULL(GlossaryOfVendorHashes.VendorDataHash, 0) AS VendorDataHash
	|INTO AttributesNeedToBeUpdated
	|FROM
	|	Catalog.Glossary AS CatalogGlossary
	|		LEFT JOIN GlossaryOfVendorHashes AS GlossaryOfVendorHashes
	|		ON CatalogGlossary.Ref = GlossaryOfVendorHashes.Glossary
	|WHERE 
	|	CatalogGlossary.VendorDataHash <> ISNULL(GlossaryOfVendorHashes.VendorDataHash, 0)
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GlossaryGlossaryDetails.Ref                               AS Glossary,
	|	GlossaryGlossaryDetails.LineNumber                          AS LineNumber,
	|	GlossaryGlossaryDetails.LanguageCode                             AS LanguageCode,
	|	ISNULL(DescriptionsInVendorHashLanguages.VendorDataHash, 0) AS VendorDataHash
	|INTO DescriptionLinesInLanguageNeedToBeUpdated
	|FROM
	|	Catalog.Glossary.GlossaryDetails AS GlossaryGlossaryDetails
	|		LEFT JOIN DescriptionsInVendorHashLanguages AS DescriptionsInVendorHashLanguages
	|		ON GlossaryGlossaryDetails.Ref = DescriptionsInVendorHashLanguages.Glossary
	|			AND GlossaryGlossaryDetails.LanguageCode = DescriptionsInVendorHashLanguages.LanguageCode
	|WHERE 
	|	GlossaryGlossaryDetails.VendorDataHash <> ISNULL(DescriptionsInVendorHashLanguages.VendorDataHash, 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Glossary                AS Glossary,
	|	NestedQuery.LineNumber              AS LineNumber,
	|	NestedQuery.LanguageCode                 AS LanguageCode,
	|	NestedQuery.VendorDataHash      AS VendorDataHash,
	|	NestedQuery.ThisIsDescriptionStringInLanguage AS ThisIsDescriptionStringInLanguage
	|FROM
	|	(SELECT
	|		DescriptionLinesInLanguageNeedToBeUpdated.Glossary           AS Glossary,
	|		DescriptionLinesInLanguageNeedToBeUpdated.LineNumber         AS LineNumber,
	|		DescriptionLinesInLanguageNeedToBeUpdated.LanguageCode            AS LanguageCode,
	|		DescriptionLinesInLanguageNeedToBeUpdated.VendorDataHash AS VendorDataHash,
	|		TRUE                                                     AS ThisIsDescriptionStringInLanguage
	|	FROM
	|		DescriptionLinesInLanguageNeedToBeUpdated AS DescriptionLinesInLanguageNeedToBeUpdated
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AttributesNeedToBeUpdated.Glossary,
	|		0,
	|		"""",
	|		AttributesNeedToBeUpdated.VendorDataHash,
	|		FALSE
	|	FROM
	|		AttributesNeedToBeUpdated AS AttributesNeedToBeUpdated) AS NestedQuery
	|TOTALS BY
	|	Glossary";
	
EndFunction
	
Procedure ProcessGlossaryTreeRowForSupportStatementTable(TreeRow, GlossaryTableForSupportApplications, TableOfDescriptionsInLanguageForSupport)
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
		
		NewRow = GlossaryTableForSupportApplications.Add();
		NewRow.Glossary            = TreeRow.Glossary;
		NewRow.VendorDataHash  = TreeRow.HashDataOfFile;
		
	ElsIf TreeRow.TypeOfUploadSettingsLine = "LongDesc" Then 
		
		NewRow = TableOfDescriptionsInLanguageForSupport.Add();
		NewRow.Glossary            = TreeRow.Parent.Glossary;
		NewRow.LanguageCode             = TreeRow.LanguageCode;
		NewRow.VendorDataHash  = TreeRow.HashDataOfFile;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		ProcessGlossaryTreeRowForSupportStatementTable(SubordinateRow, GlossaryTableForSupportApplications, TableOfDescriptionsInLanguageForSupport);
		
	EndDo;
	
EndProcedure 

Procedure SetUpToSupportDescriptionOfProcesses(ProcessDescriptionTree)
	
	If ProcessDescriptionTree.Rows.Count() = 0 Then
		Return;
	EndIf;
	
	TableOfDescriptionsForSupportApplications = New ValueTable;
	TableOfDescriptionsForSupportApplications.Columns.Add("Scenario",            New TypeDescription("CatalogRef.DemoScenarios"));
	TableOfDescriptionsForSupportApplications.Columns.Add("VendorDataHash", Common.TypeDescriptionNumber(10, 0));
	
	TableOfDescriptionsInLanguageForSupport = New ValueTable;
	TableOfDescriptionsInLanguageForSupport.Columns.Add("Scenario",            New TypeDescription("CatalogRef.DemoScenarios"));
	TableOfDescriptionsInLanguageForSupport.Columns.Add("LanguageCode",            Common.StringTypeDetails(2));
	TableOfDescriptionsInLanguageForSupport.Columns.Add("VendorDataHash", Common.TypeDescriptionNumber(10, 0));
	
	For Each TreeRow In ProcessDescriptionTree.Rows Do
		
		ProcessDescriptionTreeLineForSupportStatementTable(TreeRow, TableOfDescriptionsForSupportApplications, TableOfDescriptionsInLanguageForSupport);
		
	EndDo;
	
	Query = New Query;
	Query.Text = QueryTextSettingUpToSupportDescriptionOfProcesses();
	
	Query.SetParameter("ProcessDescriptions", TableOfDescriptionsForSupportApplications);
	Query.SetParameter("DescriptionsInLanguage",   TableOfDescriptionsInLanguageForSupport);
	
	QueryResult = Query.Execute();
	
	RefsSelection = QueryResult.Select(QueryResultIteration.ByGroups);
	
	RecordRequiredVendorHashesBasedOnProcessDescriptionSelection(RefsSelection);
	
EndProcedure

Procedure RecordRequiredVendorHashesBasedOnProcessDescriptionSelection(RefsSelection)
	
	While RefsSelection.Next() Do
		
		Try
		
			Block = New DataLock;
			LockItem = Block.Add(RefsSelection.Scenario.Metadata().FullName());
			LockItem.SetValue("Ref", RefsSelection.Scenario);
			Block.Lock();
		
			ScenarioObject = RefsSelection.Scenario.GetObject();
			
			SelectionOfUpdatedHashes = RefsSelection.Select();
			
			While SelectionOfUpdatedHashes.Next() Do
				
				If SelectionOfUpdatedHashes.ThisIsDescriptionStringInLanguage Then
					
					SearchParameters = New Structure;
					SearchParameters.Insert("LineNumber", SelectionOfUpdatedHashes.LineNumber);
					SearchParameters.Insert("LanguageCode",    SelectionOfUpdatedHashes.LanguageCode);
					
					FoundRows = ScenarioObject.ScenarioDescriptions.FindRows(SearchParameters);
					
					For Each FoundRow In FoundRows Do
						
						 FoundRow.VendorDataHash = SelectionOfUpdatedHashes.VendorDataHash;
						
					EndDo;
					
				Else
					
					ScenarioObject.VendorDataHash = SelectionOfUpdatedHashes.VendorDataHash;
					
				EndIf;
				
			EndDo; 
			
			ScenarioObject.Write(); 
		
		Except
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		EndTry;
		
	EndDo;
	
EndProcedure

Function QueryTextSettingUpToSupportDescriptionOfProcesses()
	
	Return "
	|SELECT
	|	ProcessDescriptions.Scenario            AS Scenario,
	|	ProcessDescriptions.VendorDataHash AS VendorDataHash
	|INTO ProcessDescriptionsVendorHashes
	|FROM
	|	&ProcessDescriptions AS ProcessDescriptions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DescriptionsInLanguage.Scenario AS Scenario,
	|	DescriptionsInLanguage.LanguageCode AS LanguageCode,
	|	DescriptionsInLanguage.VendorDataHash AS VendorDataHash
	|INTO DescriptionsInVendorHashLanguages
	|FROM
	|	&DescriptionsInLanguage AS DescriptionsInLanguage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DemoScenarios.Ref                                  AS Scenario,
	|	ISNULL(ProcessDescriptionsVendorHashes.VendorDataHash, 0) AS VendorDataHash
	|INTO AttributesNeedToBeUpdated
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|		LEFT JOIN ProcessDescriptionsVendorHashes AS ProcessDescriptionsVendorHashes
	|		ON DemoScenarios.Ref = ProcessDescriptionsVendorHashes.Scenario
	|WHERE 
	|	DemoScenarios.VendorDataHash <> ISNULL(ProcessDescriptionsVendorHashes.VendorDataHash, 0)
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DemoScenariosScenarioDescriptions.Ref                 AS Scenario,
	|	DemoScenariosScenarioDescriptions.LineNumber            AS LineNumber,
	|	DemoScenariosScenarioDescriptions.LanguageCode               AS LanguageCode,
	|	ISNULL(DescriptionsInVendorHashLanguages.VendorDataHash, 0) AS VendorDataHash
	|INTO DescriptionLinesInLanguageNeedToBeUpdated
	|FROM
	|	Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
	|		LEFT JOIN DescriptionsInVendorHashLanguages AS DescriptionsInVendorHashLanguages
	|		ON DemoScenariosScenarioDescriptions.Ref = DescriptionsInVendorHashLanguages.Scenario
	|			AND DemoScenariosScenarioDescriptions.LanguageCode = DescriptionsInVendorHashLanguages.LanguageCode
	|WHERE 
	|	DemoScenariosScenarioDescriptions.VendorDataHash <> ISNULL(DescriptionsInVendorHashLanguages.VendorDataHash, 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Scenario                 AS Scenario,
	|	NestedQuery.LineNumber              AS LineNumber,
	|	NestedQuery.LanguageCode                 AS LanguageCode,
	|	NestedQuery.VendorDataHash      AS VendorDataHash,
	|	NestedQuery.ThisIsDescriptionStringInLanguage AS ThisIsDescriptionStringInLanguage
	|FROM
	|	(SELECT
	|		DescriptionLinesInLanguageNeedToBeUpdated.Scenario            AS Scenario,
	|		DescriptionLinesInLanguageNeedToBeUpdated.LineNumber         AS LineNumber,
	|		DescriptionLinesInLanguageNeedToBeUpdated.LanguageCode            AS LanguageCode,
	|		DescriptionLinesInLanguageNeedToBeUpdated.VendorDataHash AS VendorDataHash,
	|		TRUE                                                     AS ThisIsDescriptionStringInLanguage
	|	FROM
	|		DescriptionLinesInLanguageNeedToBeUpdated AS DescriptionLinesInLanguageNeedToBeUpdated
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AttributesNeedToBeUpdated.Scenario,
	|		0,
	|		"""",
	|		AttributesNeedToBeUpdated.VendorDataHash,
	|		FALSE
	|	FROM
	|		AttributesNeedToBeUpdated AS AttributesNeedToBeUpdated) AS NestedQuery
	|TOTALS BY
	|	Scenario";
	
	
EndFunction

Procedure ProcessDescriptionTreeLineForSupportStatementTable(TreeRow, TableOfDescriptionsForSupportApplications, TableOfDescriptionsInLanguageForSupport)
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
		
		NewRow = TableOfDescriptionsForSupportApplications.Add();
		NewRow.Scenario            = TreeRow.Scenario;
		NewRow.VendorDataHash = TreeRow.HashDataOfFile;
		
	ElsIf TreeRow.TypeOfUploadSettingsLine = "LongDesc" Then 
		
		NewRow = TableOfDescriptionsInLanguageForSupport.Add();
		NewRow.Scenario            = TreeRow.Parent.Scenario;
		NewRow.LanguageCode            = TreeRow.LanguageCode;
		NewRow.VendorDataHash = TreeRow.HashDataOfFile;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		ProcessDescriptionTreeLineForSupportStatementTable(SubordinateRow, TableOfDescriptionsForSupportApplications, TableOfDescriptionsInLanguageForSupport);
		
	EndDo;
	
EndProcedure 

#EndRegion

#Region ReadingArchiveFiles

Procedure ReadDataOfDownloadArchiveFile(ImportResult1, GenerationParameters)
	
	GenerationParameters.ProcessDescriptionTree.Rows.Clear();
	GenerationParameters.Glossary.Rows.Clear();
	GenerationParameters.Screenshots.Clear();
	
	ObjectReading = New ZipFileReader(DemoScenarios.InMemoryStreamOfBinaryData(GenerationParameters.BinaryDataOfDownloadFile));
	If ObjectReading.Items.Count() =  0 Then
		Return;
	EndIf;
	
	ResultOfCreatingFolder = DemoScenarios.ResultOfCreatingDirectoryForUnzippingUploading(); 
	
	If Not ResultOfCreatingFolder.Success Then
		Return;
	EndIf;
	
	DirectoryOfUnzippedFiles = ResultOfCreatingFolder.DirectoryName;
	
	ObjectReading.ExtractAll(DirectoryOfUnzippedFiles, ZIPRestoreFilePathsMode.Restore);

	FillInUploadedDataForForm(ImportResult1, GenerationParameters, DirectoryOfUnzippedFiles);
	
EndProcedure

Procedure FillInUploadedDataForForm(ImportResult1, GenerationParameters, DirectoryOfUnzippedFiles)
	
	FillInProcessDescriptionTree(GenerationParameters, ImportResult1, DirectoryOfUnzippedFiles, GenerationParameters.ProcessDescriptionTree);
	FillInGlossaryTree(GenerationParameters, ImportResult1, DirectoryOfUnzippedFiles, GenerationParameters.Glossary);
	FillInScreenshotTable(DirectoryOfUnzippedFiles, GenerationParameters.Screenshots);
	
	DeleteFiles(DirectoryOfUnzippedFiles, GetServerAllFilesMask());
	
	ImportResult1.DownloadData.Insert("LoadingSettingsProcessDescriptions", GenerationParameters.ProcessDescriptionTree);
	ImportResult1.DownloadData.Insert("Screenshots",                          GenerationParameters.Screenshots);
	ImportResult1.DownloadData.Insert("DownloadSettingsGlossary",         GenerationParameters.Glossary);
	
EndProcedure 

#Region ParsingGlossary

Procedure FillInGlossaryTree(GenerationParameters, ImportResult1, DirectoryOfUnzippedFiles, DownloadSettingsGlossary)
	
	TreeRowIds = New Map;
	
	DirectoryName = DirectoryOfUnzippedFiles 
	              + DemoScenariosClientServer.NameOfGlossaryCatalog() 
	              + GetPathSeparator();
	
	AddFilesTreeGlossaryByDirectory(DownloadSettingsGlossary.Rows, DirectoryName, TreeRowIds);
	FillInAdditionalDataOfGlossaryTreeOnServer(GenerationParameters, DownloadSettingsGlossary, TreeRowIds);
	
EndProcedure

Procedure GetGlossaryAttributes(TreeStringGlossaries, GlossariesForObtainingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Glossary.Ref              AS LinkGlossary,
	|	Glossary.DeletionMark     AS DeletionMark,
	|	Glossary.Code                 AS Code,
	|	Glossary.Description        AS Description,
	|	Glossary.VendorDataHash AS VendorDataHash,
	|	Glossary.DescriptionLanguage1   AS DescriptionLanguage1,
	|	Glossary.DescriptionLanguage2   AS DescriptionLanguage2,
	|	Glossary.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	) AS ConfigurationObjects
	|FROM
	|	Catalog.Glossary AS Glossary
	|WHERE
	|	Glossary.Ref IN (&ArrayOfGlossaries)";
	
	Query.SetParameter("ArrayOfGlossaries", GlossariesForObtainingData);
	
	Result = Query.Execute();
	SelectionLinkGlossary = Result.Select();
	
	While SelectionLinkGlossary.Next() Do
		
		AttributeDataGlossary = DemoScenarios.NewAttributeDataGlossary();
		
		FillPropertyValues(AttributeDataGlossary, SelectionLinkGlossary, , "ConfigurationObjects");
		
		AttributeDataGlossary.Ref              = SelectionLinkGlossary.LinkGlossary;
		AttributeDataGlossary.ConfigurationObjects = SelectionLinkGlossary.ConfigurationObjects.Unload();
		
		JSONTextAttributesGlossary = DemoScenarios.TextOfGlossarySJSONAttributes(AttributeDataGlossary); 
		
		TreeRow = TreeStringGlossaries.Get(SelectionLinkGlossary.LinkGlossary);
		If TreeRow <> Undefined Then
			TreeRow.DatabaseData          = JSONTextAttributesGlossary;
			TreeRow.HashDatabaseData       = DemoScenarios.TextHash(JSONTextAttributesGlossary);
			TreeRow.Code                 = SelectionLinkGlossary.Code; 
			TreeRow.VendorDataHash = SelectionLinkGlossary.VendorDataHash;
			TreeRow.RefExists    = True;
		EndIf;
		
	EndDo;
	
EndProcedure 

Procedure GetDataFromGlossaryDescriptions(TreeStringGlossaries, GlossariesForObtainingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	GlossaryGlossaryDetails.Ref   AS Ref,
	|	GlossaryGlossaryDetails.LanguageCode AS LanguageCode,
	|	GlossaryGlossaryDetails.LongDesc AS LongDesc
	|FROM
	|	Catalog.Glossary.GlossaryDetails AS GlossaryGlossaryDetails
	|WHERE
	|	GlossaryGlossaryDetails.Ref IN (&ArrayOfGlossaries)";
	
	Query.SetParameter("ArrayOfGlossaries", GlossariesForObtainingData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Attachments = New Structure;
		HTMLText = "";
		FormattedDescriptionDocument = Selection.LongDesc.Get();
		FormattedDescriptionDocument.GetHTML(HTMLText, Attachments);
		
		TreeRow = TreeStringGlossaries.Get(Selection.Ref);
		If TreeRow <> Undefined Then
			
			SearchParameters = New Structure;
			SearchParameters.Insert("LanguageCode", Selection.LanguageCode);
			
			FoundRows = TreeRow.Rows.FindRows(SearchParameters);
			
			If FoundRows.Count() = 0 Then

				StringWithDescription = TreeRow.Rows.Insert(0);
				StringWithDescription.LanguageCode                   = Selection.LanguageCode;
				StringWithDescription.Presentation              = Selection.LanguageCode;
				StringWithDescription.TypeOfUploadSettingsLine = "LongDesc";
				StringWithDescription.StatusOfFiles               = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
				
			Else
				
				StringWithDescription = FoundRows[0];
				
			EndIf;
			
			StringWithDescription.DatabaseData         = HTMLText;
			StringWithDescription.HashDatabaseData      = DemoScenarios.TextHash(HTMLText);
			StringWithDescription.Glossary          = Selection.Ref;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddMissingGlossariesInTreeRowUpload(DownloadSettingsGlossary, TreeRow, TreeStringGlossaries, TreeRowGlossaryParent)
	
	GlossaryTreeLineIsCurCurrent = TreeStringGlossaries.Get(TreeRow.LinkGlossary);
	
	If GlossaryTreeLineIsCurCurrent = Undefined Then
		
		If TreeRowGlossaryParent = Undefined Then
			
			RowsCollection = DownloadSettingsGlossary.Rows;
			
		Else
			
			RowsCollection = TreeRowGlossaryParent.Rows;
			
		EndIf;
		
		GlossaryTreeLineIsCurCurrent = RowsCollection.Add();
		
		AttributeDataGlossary = DemoScenarios.NewAttributeDataGlossary();
		
		FillPropertyValues(AttributeDataGlossary, TreeRow, , "ConfigurationObjects");
		
		SubordinateLineAttributes = Undefined;
		For Each SubordinateRow In TreeRow.Rows Do
			
			If SubordinateRow.LinkGlossary = TreeRow.LinkGlossary Then
				SubordinateLineAttributes = SubordinateRow;
			EndIf;
			
		EndDo;
		
		AttributeDataGlossary.Ref              = TreeRow.LinkGlossary;
		AttributeDataGlossary.ConfigurationObjects = SubordinateLineAttributes.ConfigurationObjects;
		
		JSONTextAttributesGlossary = DemoScenarios.TextOfGlossarySJSONAttributes(AttributeDataGlossary); 
		
		If TreeRow <> Undefined Then
			
			GlossaryTreeLineIsCurCurrent.DatabaseData                 = JSONTextAttributesGlossary;
			GlossaryTreeLineIsCurCurrent.HashDatabaseData              = DemoScenarios.TextHash(JSONTextAttributesGlossary);
			GlossaryTreeLineIsCurCurrent.Code                        = TreeRow.Code;
			GlossaryTreeLineIsCurCurrent.Glossary                  = TreeRow.LinkGlossary;
			GlossaryTreeLineIsCurCurrent.TypeOfUploadSettingsLine = "Scenario";
			GlossaryTreeLineIsCurCurrent.Presentation              = TreeRow.Description;
			GlossaryTreeLineIsCurCurrent.StatusOfFiles               = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
			GlossaryTreeLineIsCurCurrent.WhatToDo                  = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
			
		EndIf; 
		
		TreeStringGlossaries.Insert(GlossaryTreeLineIsCurCurrent.Glossary, GlossaryTreeLineIsCurCurrent);
		
		For Each ScriptDescriptionString In SubordinateLineAttributes.GlossaryDetails Do
			
			Attachments = New Structure;
			HTMLText = "";
			FormattedDescriptionDocument = ScriptDescriptionString.LongDesc.Get();
			FormattedDescriptionDocument.GetHTML(HTMLText, Attachments);
			
			StringWithDescription = GlossaryTreeLineIsCurCurrent.Rows.Insert(0);
			StringWithDescription.LanguageCode                   = ScriptDescriptionString.LanguageCode;
			StringWithDescription.Presentation              = ScriptDescriptionString.LanguageCode;
			StringWithDescription.TypeOfUploadSettingsLine = "LongDesc";
			StringWithDescription.StatusOfFiles  = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
			
			StringWithDescription.DatabaseData      = HTMLText;
			StringWithDescription.HashDatabaseData   = DemoScenarios.TextHash(HTMLText);
			StringWithDescription.Glossary       = GlossaryTreeLineIsCurCurrent.Glossary;
			
		EndDo;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		AddMissingGlossariesInTreeRowUpload(DownloadSettingsGlossary, SubordinateRow, TreeStringGlossaries, TreeRowGlossaryParent)
		
	EndDo;
	
EndProcedure

Procedure AddDataMissingFromGlossaries(GenerationParameters, TreeStringGlossaries, GlossariesForObtainingData)
	
	If GenerationParameters.ThisIsPartialUpload Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Glossary.Ref              AS LinkGlossary,
	|	Glossary.DeletionMark     AS DeletionMark,
	|	Glossary.Code                 AS Code,
	|	Glossary.Description        AS Description,
	|	Glossary.VendorDataHash AS VendorDataHash,
	|	Glossary.DescriptionLanguage1   AS DescriptionLanguage1,
	|	Glossary.DescriptionLanguage2   AS DescriptionLanguage2,
	|	Glossary.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	) AS ConfigurationObjects,
	|	Glossary.GlossaryDetails.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		LanguageCode AS LanguageCode,
	|		LongDesc AS LongDesc,
	|		VendorDataHash AS VendorDataHash
	|	) AS GlossaryDetails
	|FROM
	|	Catalog.Glossary AS Glossary
	|WHERE
	|	Glossary.Ref NOT IN (&ArrayOfGlossaries)
	|ORDER BY
	|	Code
	|TOTALS BY
	|	LinkGlossary HIERARCHY";
	
	Query.SetParameter("ArrayOfGlossaries", GlossariesForObtainingData);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	DataTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);

	For Each TreeRow In DataTree.Rows Do
		
		AddMissingGlossariesInTreeRowUpload(GenerationParameters.Glossary, TreeRow, TreeStringGlossaries, Undefined);
		
	EndDo;
	
EndProcedure

Procedure GetDataFromExistingGlossaries(GenerationParameters, TreeStringGlossaries)
	
	GlossariesForObtainingData = New Array;
	
	For Each MapItem In TreeStringGlossaries Do
		
		GlossariesForObtainingData.Add(MapItem.Key);
		
	EndDo;
	
	GetGlossaryAttributes(TreeStringGlossaries, GlossariesForObtainingData);
	AddDataMissingFromGlossaries(GenerationParameters, TreeStringGlossaries, GlossariesForObtainingData);
	GetDataFromGlossaryDescriptions(TreeStringGlossaries, GlossariesForObtainingData);
	
EndProcedure

Procedure AddFilesTreeGlossaryByDirectory(ItemsCollection, DirectoryWithFiles, TreeRowIds);

	FilesInDirectory = FindFiles(DirectoryWithFiles, GetServerAllFilesMask(), False);
	
	FileDataInDirectory = FileDataInDirectory(FilesInDirectory);
	
	CurElementString = Undefined;
	
	If FileDataInDirectory.Attributes <> Undefined Then
		
		NewRow = ItemsCollection.Add();
		NewRow.GlossaryId      = FileDataInDirectory.Attributes.ItemID;
		NewRow.FileData                 = FileDataInDirectory.Attributes.DataAttributes;
		NewRow.TypeOfUploadSettingsLine  = "Scenario";
		
		CurElementString = NewRow;
		
		TreeRowIds.Insert(NewRow.GlossaryId, CurElementString);
		
	EndIf;
	
	If CurElementString <> Undefined Then
		
		CollectionOfSubordinates = CurElementString.Rows;
		
		For Each DescriptionData In FileDataInDirectory.DetailsList1 Do
			
			DetailsString = CurElementString.Rows.Add();
			DetailsString.LanguageCode                   = DescriptionData.LanguageCode;
			DetailsString.FileData                = DescriptionData.HTMLText;
			DetailsString.Presentation              = DetailsString.LanguageCode;
			DetailsString.TypeOfUploadSettingsLine = "LongDesc";
			
		EndDo;
		
	Else
		
		CollectionOfSubordinates =  ItemsCollection;
	
	EndIf;
	
	For Each DirectoryName In FileDataInDirectory.Directories Do
		
		AddFilesTreeGlossaryByDirectory(CollectionOfSubordinates, DirectoryName, TreeRowIds);
		
	EndDo;
	
EndProcedure

Procedure FillInAdditionalDataOfGlossaryTreeOnServer(GenerationParameters, DownloadSettingsGlossary, TreeRowIds)
	
	TreeStringGlossaries = New Map;
	
	For Each KeyAndValue In TreeRowIds Do
		
		FoundGlossary = Catalogs.Glossary.GetRef(KeyAndValue.Key);
		TreeRow = KeyAndValue.Value;
		
		If TreeRow <> Undefined Then
			
			TreeRow.Glossary = FoundGlossary;
			
			JSONReader = New JSONReader;
			JSONReader.SetString(TreeRow.FileData);
			
			Result = ReadJSON(JSONReader);
			
			JSONReader.Close();
			
			TreeRow.Code           = Result.Code;
			TreeRow.Presentation = StrTemplate("(%1) %2", Result.Code, Result.Name);
			
			If Not FoundGlossary.IsEmpty() Then
			
				TreeStringGlossaries.Insert(FoundGlossary, TreeRow);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	GetDataFromExistingGlossaries(GenerationParameters, TreeStringGlossaries);
	CompareDatabaseAndFileData(GenerationParameters, DownloadSettingsGlossary);

EndProcedure

#EndRegion

#Region AnalysisOfProcessDescriptions

Procedure FillInProcessDescriptionTree(GenerationParameters, ImportResult1, DirectoryOfUnzippedFiles, LoadingSettingsProcessDescriptions)
	
	TreeRowIds = New Map;
	
	DirectoryName = DirectoryOfUnzippedFiles 
	              + DemoScenariosClientServer.NameOfProcessDescriptionUploadDirectory() 
	              + GetPathSeparator();
	
	AddDescriptionTreeFilesByDirectory(LoadingSettingsProcessDescriptions.Rows, DirectoryName, TreeRowIds);
	FillInAdditionalDataForDownloadDescriptionTree(GenerationParameters, LoadingSettingsProcessDescriptions, TreeRowIds);
	
EndProcedure

Procedure FillInAdditionalDataForDownloadDescriptionTree(GenerationParameters, LoadingSettingsProcessDescriptions, TreeRowIds)
	
	TreeLineScripts = New Map;
	
	For Each KeyAndValue In TreeRowIds Do
		
		FoundScenario = Catalogs.DemoScenarios.GetRef(KeyAndValue.Key);
		TreeRow      = KeyAndValue.Value;
		
		If TreeRow <> Undefined Then
			
			TreeRow.Scenario = FoundScenario;
			
			JSONReader = New JSONReader;
			JSONReader.SetString(TreeRow.FileData);
			
			Result = ReadJSON(JSONReader);
			
			JSONReader.Close();
			
			TreeRow.FullCode     = Result.FullCode;
			TreeRow.Presentation = StrTemplate("(%1) %2", Result.FullCode, Result.Name);
			
			If Not FoundScenario.IsEmpty() Then
			
				TreeLineScripts.Insert(FoundScenario, TreeRow);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	GetDataFromExistingScenarios(GenerationParameters, TreeLineScripts);
	CompareDatabaseAndFileData(GenerationParameters, LoadingSettingsProcessDescriptions);

EndProcedure

Procedure CompareDatabaseAndFileData(GenerationParameters, DataTree)
	
	For Each TreeRow In DataTree.Rows Do
		
		CompareDatabaseAndFileDataByTreeLine(GenerationParameters, TreeRow);
		
	EndDo;
	
EndProcedure

Procedure CompareDatabaseAndFileDataByTreeLine(GenerationParameters, TreeRow)

	If Not IsBlankString(TreeRow.FileData) Then
		
		TreeRow.HashDataOfFile = DemoScenarios.TextHash(TreeRow.FileData);
		
	EndIf;
	
	If TreeRow.StatusOfFiles = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport Then
		
		TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
		
	ElsIf TreeRow.HashDatabaseData = 0 Then
		
		TreeRow.StatusOfFiles = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase;
		TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
		
	ElsIf TreeRow.HashDataOfFile <> TreeRow.HashDatabaseData Then
		
		If GenerationParameters.OptionOfSettingUpForSupport = 0 Then 
			If TreeRow.HashDataOfFile = TreeRow.VendorDataHash Then
				TreeRow.StatusOfFiles = Enums.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyInInfobase;
				TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.NotToImport;
			ElsIf TreeRow.HashDatabaseData = TreeRow.VendorDataHash Then
				TreeRow.StatusOfFiles = Enums.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyByVendor;
				TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
			Else
				TreeRow.StatusOfFiles = Enums.ComparisonStatusesOfProcessDetailsFiles.ChangedByVendorAndInInfobase;
				TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.Union;
			EndIf;
		Else
			TreeRow.StatusOfFiles = Enums.ComparisonStatusesOfProcessDetailsFiles.HasChanges;
			TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
		EndIf;
		
	Else
		
		TreeRow.StatusOfFiles =  Enums.ComparisonStatusesOfProcessDetailsFiles.NoChanges;
		TreeRow.WhatToDo    = Enums.ActionOptionsWhileImportingProcessDetails.NotToImport;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		CompareDatabaseAndFileDataByTreeLine(GenerationParameters, SubordinateRow);
		
	EndDo;

EndProcedure

Procedure GetDataFromScenarioDescriptions(GenerationParameters, TreeLineScripts, ScenariosForGettingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DemoScenariosScenarioDescriptions.Ref             AS Ref,
	|	DemoScenariosScenarioDescriptions.LanguageCode           AS LanguageCode,
	|	DemoScenariosScenarioDescriptions.AttachedFile AS AttachedFile
	|FROM
	|	Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
	|		INNER JOIN Catalog.DemoScenariosAttachedFiles AS DemoScenariosAttachedFiles
	|		ON DemoScenariosScenarioDescriptions.AttachedFile = DemoScenariosAttachedFiles.Ref
	|WHERE
	|	(NOT DemoScenariosAttachedFiles.DeletionMark)
	|	AND DemoScenariosScenarioDescriptions.Ref IN (&ArrayOfScenarios)";
	
	Query.SetParameter("ArrayOfScenarios", ScenariosForGettingData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		FileData   = FilesOperations.FileData(Selection.AttachedFile);
		DetailsText = DemoScenarios.HTMLTextBasedOnAttachedFileData(FileData);
		
		TreeRow = TreeLineScripts.Get(Selection.Ref);
		If TreeRow <> Undefined Then
			
			SearchParameters = New Structure;
			SearchParameters.Insert("LanguageCode", Selection.LanguageCode);
			
			FoundRows = TreeRow.Rows.FindRows(SearchParameters);
			
			If FoundRows.Count() = 0 Then
				
				StringWithDescription = TreeRow.Rows.Insert(0);
				StringWithDescription.LanguageCode                   = Selection.LanguageCode;
				StringWithDescription.Presentation              = Selection.LanguageCode;
				StringWithDescription.TypeOfUploadSettingsLine = "LongDesc";
				StringWithDescription.StatusOfFiles  = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
				
			Else
				
				StringWithDescription = FoundRows[0];
				
			EndIf;
			
			StringWithDescription.DatabaseData         = DetailsText;
			StringWithDescription.HashDatabaseData      = DemoScenarios.TextHash(DetailsText);
			StringWithDescription.AttachedFile = Selection.AttachedFile;
			StringWithDescription.Scenario           = Selection.Ref;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure GetDataFromExistingScenarios(GenerationParameters, TreeLineScripts)
	
	ScenariosForGettingData = New Array;
	
	For Each MapItem In TreeLineScripts Do
		
		ScenariosForGettingData.Add(MapItem.Key);
		
	EndDo;
	
	GetScriptAttributeData(TreeLineScripts, ScenariosForGettingData);
	AddDataForMissingScriptsInUpload(GenerationParameters, TreeLineScripts, ScenariosForGettingData);
	GetDataFromScenarioDescriptions(GenerationParameters, TreeLineScripts, ScenariosForGettingData);
	
EndProcedure

Procedure AddDataForMissingScriptsInUpload(GenerationParameters, TreeLineScripts, ScenariosForGettingData)
	
	If GenerationParameters.ThisIsPartialUpload Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DemoScenarios.Ref              AS LinkDescriptionOfProcesses,
	|	DemoScenarios.DeletionMark     AS DeletionMark,
	|	DemoScenarios.Parent            AS Parent,
	|	DemoScenarios.IsFolder           AS IsFolder,
	|	DemoScenarios.Code                 AS Code,
	|	DemoScenarios.Description        AS Description,
	|	DemoScenarios.FullCode           AS FullCode,
	|	DemoScenarios.Status              AS Status,
	|	DemoScenarios.Comment         AS Comment,
	|	DemoScenarios.VendorDataHash AS VendorDataHash,
	|	DemoScenarios.GroupType           AS GroupType,
	|	DemoScenarios.DescriptionLanguage1   AS DescriptionLanguage1,
	|	DemoScenarios.DescriptionLanguage2   AS DescriptionLanguage2,
	|	DemoScenarios.AccessGroupProfiles.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Profile AS Profile
	|	) AS AccessGroupProfiles,
	|	DemoScenarios.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	) AS ConfigurationObjects,
	|	DemoScenarios.ScenarioDescriptions.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		LanguageCode AS LanguageCode,
	|		AttachedFile AS AttachedFile,
	|		VendorDataHash AS VendorDataHash
	|	) AS ScenarioDescriptions
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|WHERE
	|	DemoScenarios.Ref NOT IN (&ArrayOfScenarios)
	|ORDER BY
	|	FullCode
	|TOTALS BY
	|	LinkDescriptionOfProcesses HIERARCHY";
	
	Query.SetParameter("ArrayOfScenarios", ScenariosForGettingData);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	DataTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);

	For Each TreeRow In DataTree.Rows Do
		
		AddMissingScriptsInTreeRowUpload(GenerationParameters.ProcessDescriptionTree, TreeRow, TreeLineScripts, Undefined);
		
	EndDo;
	
EndProcedure

Procedure AddMissingScriptsInTreeRowUpload(LoadingSettingsProcessDescriptions, TreeRow, TreeLineScripts, DescriptionTreeStringParent)
	
	DescriptionTreeLineIsCur = TreeLineScripts.Get(TreeRow.LinkDescriptionOfProcesses);
	
	If DescriptionTreeLineIsCur = Undefined Then
		
		If DescriptionTreeStringParent = Undefined Then
			
			RowsCollection = LoadingSettingsProcessDescriptions.Rows;
			
		Else
			
			RowsCollection = DescriptionTreeStringParent.Rows;
			
		EndIf;
		
		DescriptionTreeLineIsCur = RowsCollection.Add();
		
		DescriptionAttributesData = DemoScenarios.NewAttributeDataDescriptionOfProcesses();
		
		FillPropertyValues(DescriptionAttributesData, TreeRow, , "AccessGroupProfiles, ConfigurationObjects");
		
		SubordinateLineAttributes = Undefined;
		For Each SubordinateRow In TreeRow.Rows Do
			
			If SubordinateRow.LinkDescriptionOfProcesses = TreeRow.LinkDescriptionOfProcesses Then
				SubordinateLineAttributes = SubordinateRow;
			EndIf;
			
		EndDo;
		
		DescriptionAttributesData.Ref              = TreeRow.LinkDescriptionOfProcesses;
		DescriptionAttributesData.AccessGroupProfiles = SubordinateLineAttributes.AccessGroupProfiles;
		DescriptionAttributesData.ConfigurationObjects = SubordinateLineAttributes.ConfigurationObjects;
		
		JSONTextAttributesDescriptionOfProcesses = DemoScenarios.JSONTextAttributesDescriptionOfProcesses(DescriptionAttributesData); 
		
		If TreeRow <> Undefined Then
			
			DescriptionTreeLineIsCur.DatabaseData                 = JSONTextAttributesDescriptionOfProcesses;
			DescriptionTreeLineIsCur.HashDatabaseData              = DemoScenarios.TextHash(JSONTextAttributesDescriptionOfProcesses);
			DescriptionTreeLineIsCur.FullCode                  = TreeRow.FullCode;
			DescriptionTreeLineIsCur.Scenario                   = TreeRow.LinkDescriptionOfProcesses;
			DescriptionTreeLineIsCur.TypeOfUploadSettingsLine = "Scenario";
			DescriptionTreeLineIsCur.Presentation              = TreeRow.Description;
			DescriptionTreeLineIsCur.StatusOfFiles               = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
			DescriptionTreeLineIsCur.WhatToDo                  = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
			
		EndIf; 
		
		TreeLineScripts.Insert(DescriptionTreeLineIsCur.Scenario, DescriptionTreeLineIsCur);
		
		For Each ScriptDescriptionString In SubordinateLineAttributes.ScenarioDescriptions Do
			
			Try
				FileData   = FilesOperations.FileData(ScriptDescriptionString.AttachedFile);
				DetailsText = DemoScenarios.HTMLTextBasedOnAttachedFileData(FileData);
			Except
				DetailsText = "";
			EndTry;
		
			StringWithDescription = DescriptionTreeLineIsCur.Rows.Insert(0);
			StringWithDescription.LanguageCode                   = ScriptDescriptionString.LanguageCode;
			StringWithDescription.Presentation              = ScriptDescriptionString.LanguageCode;
			StringWithDescription.TypeOfUploadSettingsLine = "LongDesc";
			StringWithDescription.StatusOfFiles  = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
			
			StringWithDescription.DatabaseData         = DetailsText;
			StringWithDescription.HashDatabaseData      = DemoScenarios.TextHash(DetailsText);
			StringWithDescription.AttachedFile = ScriptDescriptionString.AttachedFile;
			StringWithDescription.Scenario           = DescriptionTreeLineIsCur.Scenario;
			
		EndDo;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		AddMissingScriptsInTreeRowUpload(LoadingSettingsProcessDescriptions, SubordinateRow, TreeLineScripts, DescriptionTreeLineIsCur)
		
	EndDo;
	
EndProcedure

Procedure GetScriptAttributeData(TreeLineScripts, ScenariosForGettingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DemoScenarios.Ref              AS LinkDescriptionOfProcesses,
	|	DemoScenarios.DeletionMark     AS DeletionMark,
	|	DemoScenarios.Parent            AS Parent,
	|	DemoScenarios.IsFolder           AS IsFolder,
	|	DemoScenarios.Code                 AS Code,
	|	DemoScenarios.Description        AS Description,
	|	DemoScenarios.FullCode           AS FullCode,
	|	DemoScenarios.Status              AS Status,
	|	DemoScenarios.Comment         AS Comment,
	|	DemoScenarios.VendorDataHash AS VendorDataHash,
	|	DemoScenarios.GroupType           AS GroupType,
	|	DemoScenarios.DescriptionLanguage1   AS DescriptionLanguage1,
	|	DemoScenarios.DescriptionLanguage2   AS DescriptionLanguage2,
	|	DemoScenarios.AccessGroupProfiles.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Profile AS Profile
	|	) AS AccessGroupProfiles,
	|	DemoScenarios.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	) AS ConfigurationObjects
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|WHERE
	|	DemoScenarios.Ref IN (&ArrayOfScenarios)";
	
	Query.SetParameter("ArrayOfScenarios", ScenariosForGettingData);
	
	Result = Query.Execute();
	SelectionLinkDescriptionOfProcesses = Result.Select();
	
	While SelectionLinkDescriptionOfProcesses.Next() Do
		
		DescriptionAttributesData = DemoScenarios.NewAttributeDataDescriptionOfProcesses();
		
		FillPropertyValues(DescriptionAttributesData, SelectionLinkDescriptionOfProcesses, , "AccessGroupProfiles, ConfigurationObjects");
		
		DescriptionAttributesData.Ref              = SelectionLinkDescriptionOfProcesses.LinkDescriptionOfProcesses;
		DescriptionAttributesData.AccessGroupProfiles = SelectionLinkDescriptionOfProcesses.AccessGroupProfiles.Unload();
		DescriptionAttributesData.ConfigurationObjects = SelectionLinkDescriptionOfProcesses.ConfigurationObjects.Unload();
		
		JSONTextAttributesDescriptionOfProcesses = DemoScenarios.JSONTextAttributesDescriptionOfProcesses(DescriptionAttributesData); 
		
		TreeRow = TreeLineScripts.Get(SelectionLinkDescriptionOfProcesses.LinkDescriptionOfProcesses);
		If TreeRow <> Undefined Then
			TreeRow.DatabaseData          = JSONTextAttributesDescriptionOfProcesses;
			TreeRow.HashDatabaseData       = DemoScenarios.TextHash(JSONTextAttributesDescriptionOfProcesses);
			TreeRow.FullCode           = SelectionLinkDescriptionOfProcesses.FullCode; 
			TreeRow.VendorDataHash = SelectionLinkDescriptionOfProcesses.VendorDataHash;
			TreeRow.RefExists    = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddDescriptionTreeFilesByDirectory(ItemsCollection, DirectoryWithFiles, TreeRowIds);

	FilesInDirectory = FindFiles(DirectoryWithFiles, GetServerAllFilesMask(), False);
	
	FileDataInDirectory = FileDataInDirectory(FilesInDirectory);
	
	CurElementString = Undefined;
	
	If FileDataInDirectory.Attributes <> Undefined Then
		
		NewRow = ItemsCollection.Add();
		NewRow.ScriptID      = FileDataInDirectory.Attributes.ItemID;
		NewRow.FileData                = FileDataInDirectory.Attributes.DataAttributes;
		NewRow.TypeOfUploadSettingsLine = "Scenario";
		
		CurElementString = NewRow;
		
		TreeRowIds.Insert(NewRow.ScriptID, CurElementString);
		
	EndIf;
	
	If CurElementString <> Undefined Then
		
		CollectionOfSubordinates = CurElementString.Rows;
		
		For Each DescriptionData In FileDataInDirectory.DetailsList1 Do
			
			DetailsString = CurElementString.Rows.Add();
			DetailsString.LanguageCode                   = DescriptionData.LanguageCode;
			DetailsString.FileData                = DescriptionData.HTMLText;
			DetailsString.Presentation              = DetailsString.LanguageCode;
			DetailsString.TypeOfUploadSettingsLine = "LongDesc";
			
		EndDo;
		
	Else
		
		CollectionOfSubordinates =  ItemsCollection;
		
	EndIf;
	
	For Each DirectoryName In FileDataInDirectory.Directories Do
		
		AddDescriptionTreeFilesByDirectory(CollectionOfSubordinates, DirectoryName, TreeRowIds);
		
	EndDo;
	
EndProcedure

#EndRegion

// File data in the directory.
// 
// Parameters:
//  FilesInDirectory - Array of File - Files in the directory
// 
// Returns:
//  Structure - File Data In The Directory:
// * Directories - Array of String - 
// * DetailsList1 - Array of Structure - 
// * Attributes - Undefined - 
Function FileDataInDirectory(FilesInDirectory)
	
	FileDataInDirectory = New Structure;
	FileDataInDirectory.Insert("Directories",   New Array);
	FileDataInDirectory.Insert("DetailsList1",   New Array);
	FileDataInDirectory.Insert("Attributes ", Undefined);
	
	For Each FileData In FilesInDirectory Do
		
		If IsBlankString(FileData.Extension) Then
			
			FileDataInDirectory.Directories.Add(FileData.FullName);
			
		ElsIf Lower(FileData.Extension) = ".html" Then
			
			DataByFileName = DemoScenariosClientServer.LanguageCodeIdFromDescriptionFileName(FileData.BaseName);
		
			TextReader = New TextReader(FileData.FullName, , , , False);
			HTMLText    = TrimAll(TextReader.Read());
			TextReader.Close();
		
			FileData = New Structure;
		
			FileData.Insert("HTMLText", HTMLText);
			FileData.Insert("LanguageCode",  DataByFileName.LanguageCode);
			
			FileDataInDirectory.DetailsList1.Add(FileData);
			
		ElsIf Lower(FileData.Extension) = ".json" Then
			
			ItemID = DemoScenariosClientServer.IdFromFileNameAttributes(FileData.BaseName);
			
			TextReader = New TextReader(FileData.FullName, , , , False);
			TextAttributes    = TrimAll(TextReader.Read());
			TextReader.Close();
			
			FileData = New Structure;
		
			FileData.Insert("DataAttributes",       TextAttributes);
			FileData.Insert("ItemID", ItemID);
			
			FileDataInDirectory.Attributes = FileData;
			
		EndIf;
		
	EndDo;
	
	Return FileDataInDirectory;
	
EndFunction 

Procedure FillInScreenshotTable(DirectoryOfUnzippedFiles, Screenshots) 
	
	DirectoryName = DirectoryOfUnzippedFiles 
	              + DemoScenariosClientServer.NameOfUploadFolderScreenshots() 
	              + GetPathSeparator();
	
	FilesInDirectory = FindFiles(DirectoryName, "*.png", False);
	
	For Each FileInfo In FilesInDirectory Do
		 AddLineOfInformationAboutScreenshotFile(Screenshots, FileInfo);
	EndDo;
	
EndProcedure


// Add a line of information about the screenshot file.
// 
// Parameters:
//  Screenshots - ValueTable - contains columns:
//  	* ScreenshotID - String -
//  	* BinaryData         - BinaryData -
//  FileInfo - File - information about the screenshot file
Procedure AddLineOfInformationAboutScreenshotFile(Screenshots, FileInfo) 
	
	NewRow = Screenshots.Add();
	NewRow.ScreenshotID = FileInfo.BaseName;
	NewRow.BinaryData         = New BinaryData(FileInfo.FullName);
	
EndProcedure


#EndRegion

#EndRegion

#EndIf