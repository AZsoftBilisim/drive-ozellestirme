#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning


// Gets contacts for interaction documents according to the list of participants 
//
// Parameters:
//  Ref  - CatalogRef.Complaints - the claim for which contacts are received.
//
// Returns:
//   Array   - an array containing contacts.
//
Function GetContacts(Ref) Export
	
	Return SalesOpportunitiesServer.GetParticipantsOnTabularPartOfSubjectOfInteraction(Ref);
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.Projects);
	
EndProcedure

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.Projects.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("ac698457-db9a-4444-9175-ccbc2086675c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.Projects.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Dự án"":';
								|ru = 'Обновление справочника ""Проекты"":';
								|en = 'Update the ""Projects"" catalog:'; fa = 'Update the ""Projects"" catalog:';
								|it = 'Update the ""Projects"" catalog:';
								|pl = 'Update the ""Projects"" catalog:';
								|tr = '""Projeler"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.Projects.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.Projects.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.Projects.FullName());
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
	|	Projects.Ref AS Ref
	|FROM
	|	Catalog.Projects AS Projects
	|WHERE
	|	NOT Projects.Description = """"
	|	AND Projects.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	Projects.Ref AS Ref
	|FROM
	|	Catalog.Projects AS Projects
	|WHERE
	|	NOT Projects.Description = """"
	|	AND Projects.DescriptionLanguage2 = """"
	|	
	|UNION 
	|
	|SELECT
	|	Projects.Ref AS Ref
	|FROM
	|	Catalog.Projects AS Projects
	|WHERE
	|	NOT CAST(Projects.Comment AS STRING(150)) = """"
	|	AND CAST(Projects.CommentLanguage1 AS STRING(150)) = """"
	|	
	|UNION 
	|
	|SELECT
	|	Projects.Ref AS Ref
	|FROM
	|	Catalog.Projects AS Projects
	|WHERE
	|	NOT CAST(Projects.Comment AS STRING(150)) = """"
	|	AND CAST(Projects.CommentLanguage2 AS STRING(150)) = """"";
	
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
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Dự án"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Проекты"" по обработчику:';
								|en = 'Cannot process the ""Projects"" catalog by the handler:'; fa = 'Cannot process the ""Projects"" catalog by the handler:';
								|it = 'Cannot process the ""Projects"" catalog by the handler:';
								|pl = 'Cannot process the ""Projects"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Projeler"" kataloğu işlenemedi:'"));
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
	|	Projects.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.Projects AS Projects
	|		ON TT.Ref = Projects.Ref";
	
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
				
				If ValueIsFilled(CatalogObject.Description) Then
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
						
						CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
						
					EndIf;
					
					If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
						
						CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
						
					EndIf;
					
				EndIf;
				
				If ValueIsFilled(CatalogObject.Comment) Then
					
					If Not ValueIsFilled(CatalogObject.CommentLanguage1) Then
						
						CatalogObject.CommentLanguage1 = CatalogObject.Comment;
						
					EndIf;
					
					If Not ValueIsFilled(CatalogObject.CommentLanguage2) Then
						
						CatalogObject.CommentLanguage2 = CatalogObject.Comment;
						
					EndIf;
					
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
