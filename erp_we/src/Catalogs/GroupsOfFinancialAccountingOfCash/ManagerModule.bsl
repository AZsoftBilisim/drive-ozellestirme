#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.GroupsOfFinancialAccountingOfCash);
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.GroupsOfFinancialAccountingOfCash.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("949f1e24-2f87-47cf-9b1f-bde9daa608f8");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.GroupsOfFinancialAccountingOfCash.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Nhóm tùy chỉnh kế toán tài chính vốn bằng tiền"":';
								|ru = 'Обновление справочника ""Группы настроек финансового учета денежных средств"":';
								|en = 'Update the ""Cash accounting groups"" catalog:'; fa = 'Update the ""Cash accounting groups"" catalog:';
								|it = 'Update the ""Cash accounting groups"" catalog:';
								|pl = 'Update the ""Cash accounting groups"" catalog:';
								|tr = '""Nakit muhasebesi grupları"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.GroupsOfFinancialAccountingOfCash.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.GroupsOfFinancialAccountingOfCash.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.GroupsOfFinancialAccountingOfCash.FullName());
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
	|	GroupsOfFinancialAccountingOfCash.Ref AS Ref
	|FROM
	|	Catalog.GroupsOfFinancialAccountingOfCash AS GroupsOfFinancialAccountingOfCash
	|WHERE
	|	NOT GroupsOfFinancialAccountingOfCash.Description = """"
	|	AND GroupsOfFinancialAccountingOfCash.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	GroupsOfFinancialAccountingOfCash.Ref AS Ref
	|FROM
	|	Catalog.GroupsOfFinancialAccountingOfCash AS GroupsOfFinancialAccountingOfCash
	|WHERE
	|	NOT GroupsOfFinancialAccountingOfCash.Description = """"
	|	AND GroupsOfFinancialAccountingOfCash.DescriptionLanguage2 = """"
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Nhóm kế toán tài chính vốn bằng tiền"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Группы настроек финансового учета денежных средств"" по обработчику:';
								|en = 'Cannot process the ""Cash accounting groups"" catalog by the handler:'; fa = 'Cannot process the ""Cash accounting groups"" catalog by the handler:';
								|it = 'Cannot process the ""Cash accounting groups"" catalog by the handler:';
								|pl = 'Cannot process the ""Cash accounting groups"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Nakit muhasebesi grupları"" kataloğunu işlenemedi:'"));
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
	|	GroupsOfFinancialAccountingOfCash.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.GroupsOfFinancialAccountingOfCash AS GroupsOfFinancialAccountingOfCash
	|		ON TT.Ref = GroupsOfFinancialAccountingOfCash.Ref";
	
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