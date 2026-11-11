
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Returns names of blocked details for the BSP details blocking mechanism
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("PropertyAccounting");
	Result.Add("StocktakingRecord");
	Result.Add("AccountingForIndividuals");
	Result.Add("ServiceLife");
	Result.Add("AccountAsGroupFA");
	Result.Add("MethodOfRepaymentOfCostOfAC");
	Result.Add("MethodOfRepaymentOfCostTA");

	Return Result;
	
EndFunction

#EndRegion

#Region Other

// Fills in the details of the expense account settings that affect the setup
// 	with the corresponding names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	Return;
	
EndProcedure

// Fills in the service details in the table based on the selected category of operation.
//
// Parameters:
// 	FormTable - FormDataCollection - The form table for which the attributes are filled in.
// 	FillParameters - See InventoryInOperationClientServer.ParametersForFillingInOperationCategoryAttributes
//
Procedure FillInCategoryAttributes(FormTable, FillParameters = Undefined) Export
	
	If FormTable.Count() = 0 Then
		Return;
	EndIf;
	
	If FillParameters = Undefined Then
		FillParameters = InventoryInOperationClientServer.ParametersForFillingInOperationCategoryAttributes();
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryText =
	"SELECT
	|	CAST(Table.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(Table.OperationCategory AS Catalog.OperationCategories) AS OperationCategory
	|INTO Table
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber - 1 AS RowIndex,
	|	ISNULL(Table.OperationCategory.StocktakingRecord, FALSE) AS StocktakingRecord,
	|	ISNULL(Table.OperationCategory.AccountingForIndividuals, FALSE) AS AccountingForIndividuals,
	|	ISNULL(Table.OperationCategory.AccountAsGroupFA, FALSE) AS AccountAsGroupFA,
	|	ISNULL(Table.OperationCategory.MethodOfRepaymentOfCostOfAC, VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)) AS MethodOfRepaymentOfCostOfAC,
	|	ISNULL(Table.OperationCategory.ServiceLife, 0) AS ServiceLife
	|FROM
	|	Table AS Table";
	
	Query = New Query(QueryText);
	Query.SetParameter("Table", FormTable.Unload(,"LineNumber, OperationCategory"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Signs = New Structure("StocktakingRecord,AccountingForIndividuals,AccountAsGroupFA,MethodOfRepaymentOfCostOfAC");
			
		If FillParameters.FillInServiceLife Then
			Signs.Insert("ServiceLife");
		EndIf;
		
		FillPropertyValues(Signs, Selection);
		FillPropertyValues(FormTable[Selection.RowIndex], Signs);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion
	
// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.OperationCategories);
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.OperationCategories.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a99afde1-7432-40d5-afde-c5b0e220856f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.OperationCategories.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Thể loại sử dụng"":';
								|ru = 'Обновление справочника ""Категории эксплуатации"":';
								|en = 'Update the ""Operation categories"" catalog:'; fa = 'Update the ""Operation categories"" catalog:';
								|it = 'Update the ""Operation categories"" catalog:';
								|pl = 'Update the ""Operation categories"" catalog:';
								|tr = '""Kullanım kategorileri"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.OperationCategories.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.OperationCategories.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.OperationCategories.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
		
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OperationCategories.Ref AS Ref
	|FROM
	|	Catalog.OperationCategories AS OperationCategories
	|WHERE
	|	NOT OperationCategories.Description = """"
	|	AND OperationCategories.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	OperationCategories.Ref AS Ref
	|FROM
	|	Catalog.OperationCategories AS OperationCategories
	|WHERE
	|	NOT OperationCategories.Description = """"
	|	AND OperationCategories.DescriptionLanguage2 = """"";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Thể loại sử dụng"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Категории эксплуатации"" по обработчику:';
								|en = 'Cannot process the ""Operation categories"" catalog by the handler:'; fa = 'Cannot process the ""Operation categories"" catalog by the handler:';
								|it = 'Cannot process the ""Operation categories"" catalog by the handler:';
								|pl = 'Cannot process the ""Operation categories"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Kullanım kategorileri"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	OperationCategories.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.OperationCategories AS OperationCategories
	|		ON TT.Ref = OperationCategories.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
					
					CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
					
				EndIf;
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
					
					CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
