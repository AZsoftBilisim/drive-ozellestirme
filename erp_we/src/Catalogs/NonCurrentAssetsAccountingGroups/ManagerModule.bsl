#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

Function DefaultValue(AssetKind) Export

	QueryText = 
	"SELECT ALLOWED TOP 2
	|	NonCurrentAssetsAccountingGroups.Ref
	|FROM
	|	Catalog.NonCurrentAssetsAccountingGroups AS NonCurrentAssetsAccountingGroups
	|WHERE
	|	NonCurrentAssetsAccountingGroups.AssetKind = &AssetKind
	|	AND NOT NonCurrentAssetsAccountingGroups.DeletionMark";
	
	Query = New Query(QueryText);
	Query.SetParameter("AssetKind", AssetKind);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Catalogs.NonCurrentAssetsAccountingGroups.EmptyRef();
	EndIf;
	Selection = Result.Select();
	If Selection.Count() = 1 Then
		Selection.Next();
		Return Selection.Ref;
	Else
		Return Catalogs.NonCurrentAssetsAccountingGroups.EmptyRef();
	EndIf; 

EndFunction

#Region InterfaceImplementation

// Fills in the details of the non-current asset accounting settings that affect the setting
// 	with the corresponding names of the accounting Analytics details.
//
// Parameters:
// 	MatchingNames - Map - the key is the name of the account that is used in setting up accounting accounts
// 		. the value is the corresponding name of the accounting Analytics account.
// 
Procedure FillInMatchingAccountSettingsDetails(MatchingNames) Export
	
	MatchingNames.AssetKind = "AssetKind";
	
EndProcedure

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
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.NonCurrentAssetsAccountingGroups);
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.NonCurrentAssetsAccountingGroups.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("f7067b58-260f-42d6-8a42-b5521c6cfe85");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.NonCurrentAssetsAccountingGroups.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Nhóm kế toán tài chính tài sản dài hạn"":';
								|ru = 'Обновление справочника ""Группы финансового учета внеоборотных активов"":';
								|en = 'Update the ""Fixed/Intangible assets accounting groups"" catalog:'; fa = 'Update the ""Fixed/Intangible assets accounting groups"" catalog:';
								|it = 'Update the ""Fixed/Intangible assets accounting groups"" catalog:';
								|pl = 'Update the ""Fixed/Intangible assets accounting groups"" catalog:';
								|tr = '""Duran varlıklar muhasebe grupları"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.NonCurrentAssetsAccountingGroups.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.NonCurrentAssetsAccountingGroups.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.NonCurrentAssetsAccountingGroups.FullName());
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
	|	NonCurrentAssetsAccountingGroups.Ref AS Ref
	|FROM
	|	Catalog.NonCurrentAssetsAccountingGroups AS NonCurrentAssetsAccountingGroups
	|WHERE
	|	NOT NonCurrentAssetsAccountingGroups.Description = """"
	|	AND NonCurrentAssetsAccountingGroups.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	NonCurrentAssetsAccountingGroups.Ref AS Ref
	|FROM
	|	Catalog.NonCurrentAssetsAccountingGroups AS NonCurrentAssetsAccountingGroups
	|WHERE
	|	NOT NonCurrentAssetsAccountingGroups.Description = """"
	|	AND NonCurrentAssetsAccountingGroups.DescriptionLanguage2 = """"
	|";
	
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Nhóm kế toán tài chính tài sản dài hạn"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Группы финансового учета внеоборотных активов"" по обработчику:';
								|en = 'Cannot process the ""Fixed/Intangible assets accounting groups"" catalog by the handler:'; fa = 'Cannot process the ""Fixed/Intangible assets accounting groups"" catalog by the handler:';
								|it = 'Cannot process the ""Fixed/Intangible assets accounting groups"" catalog by the handler:';
								|pl = 'Cannot process the ""Fixed/Intangible assets accounting groups"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Duran varlıklar muhasebe grupları"" kataloğu işlenemedi:'"));
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
	|	NonCurrentAssetsAccountingGroups.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.NonCurrentAssetsAccountingGroups AS NonCurrentAssetsAccountingGroups
	|		ON TT.Ref = NonCurrentAssetsAccountingGroups.Ref";
	
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
