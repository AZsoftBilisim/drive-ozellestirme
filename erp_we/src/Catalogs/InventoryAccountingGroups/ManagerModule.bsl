#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function defines the default financial accounting group.
// Returns the financial accounting group if one element of the reference list is found.
// Returns an empty Link otherwise.
//
// Returns:
//	CatalogRef.InventoryAccountingGroups - fin group. accounting by default.
//
Function GetDefaultFinancialAccountingGroup() Export
	
	Query = New Query("
	|SELECT ALLOWED TOP 2
	|	CatalogData.Ref AS FinancialAccountingGroup
	|FROM
	|	Catalog.InventoryAccountingGroups AS CatalogData
	|WHERE
	|	NOT CatalogData.DeletionMark
	|	AND NOT CatalogData.IsFolder
	|");
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		FinancialAccountingGroup = Selection.FinancialAccountingGroup;
	Else
		FinancialAccountingGroup = Catalogs.InventoryAccountingGroups.EmptyRef();
	EndIf;
	
	Return FinancialAccountingGroup;

EndFunction

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#Region InterfaceImplementation

// Fills in the details of the item's invoice settings (including the transferred item) that affect the setting,
// 	corresponding to the names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	Return;
	
EndProcedure

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.InventoryAccountingGroups);
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.InventoryAccountingGroups.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("4be92e65-6976-4967-a4f3-96c459082303");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.InventoryAccountingGroups.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Nhóm tùy chỉnh kế toán tài chính mặt hàng"":';
								|ru = 'Обновление справочника ""Группы настроек фин. учета номенклатуры"":';
								|en = 'Update the ""Financial accounting groups"" catalog:'; fa = 'Update the ""Financial accounting groups"" catalog:';
								|it = 'Update the ""Financial accounting groups"" catalog:';
								|pl = 'Update the ""Financial accounting groups"" catalog:';
								|tr = '""Öğe finansal muhasebesi ayar grupları"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.InventoryAccountingGroups.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.InventoryAccountingGroups.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.InventoryAccountingGroups.FullName());
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
	|	InventoryAccountingGroups.Ref AS Ref
	|FROM
	|	Catalog.InventoryAccountingGroups AS InventoryAccountingGroups
	|WHERE
	|	NOT InventoryAccountingGroups.Description = """"
	|	AND InventoryAccountingGroups.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	InventoryAccountingGroups.Ref AS Ref
	|FROM
	|	Catalog.InventoryAccountingGroups AS InventoryAccountingGroups
	|WHERE
	|	NOT InventoryAccountingGroups.Description = """"
	|	AND InventoryAccountingGroups.DescriptionLanguage2 = """"";
	
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Nhóm tùy chỉnh kế toán tài chính mặt hàng"" theo hàm sự kiện';
								|ru = 'Не удалось обработать справочник ""Группы настроек фин. учета номенклатуры"" по обработчику:';
								|en = 'Cannot process the ""Financial accounting groups"" catalog by the handler:'; fa = 'Cannot process the ""Financial accounting groups"" catalog by the handler:';
								|it = 'Cannot process the ""Financial accounting groups"" catalog by the handler:';
								|pl = 'Cannot process the ""Financial accounting groups"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Öğe finansal muhasebesi ayar grupları"" kataloğu işlenemedi:'"));
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
	|	InventoryAccountingGroups.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.InventoryAccountingGroups AS InventoryAccountingGroups
	|		ON TT.Ref = InventoryAccountingGroups.Ref";
	
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

