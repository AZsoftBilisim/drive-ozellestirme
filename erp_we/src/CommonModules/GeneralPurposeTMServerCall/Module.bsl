
#Region Public

#Region ProceduresAndFunctionsForSettingStatusesForArrayOfDocuments

// Sets the status for the list of documents
//
// Parameters:
// 		DocumentsArray - Array - array of documents
// 		NewStatus - String - Name of the new status for documents
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Number - The number of documents whose Status has been changed.
//
// IMPORTANT. When using the procedure, functions must be declared for each document type from the array:
// In the module of the document manager:
// 		The function to generate a query for the Changestatus(Document array, New Status, additional parameters) Export
// 		The function of checking before changing the status (Check selection, New status, additional parameters) Export
// In the document object module:
// 		Set Status function(New Status, additional parameters) Export
//
Function SetStatusOfDocuments(Val DocumentsArray, Val NewStatus, Val AdditionalParameters=Undefined) Export
	
	// Getting Standard Error Message Templates
	ErrorPatternStatusMatches   = NStr("vi = 'Chứng từ %Document% đã được gán trạng thái ""%Status%""';
										|ru = 'Документу %Document% уже присвоен статус ""%Status%""';
										|en = 'The ""%Status%"" status has already been assigned to the %Document% document'; fa = 'The ""%Status%"" status has already been assigned to the %Document% document';
										|it = 'Al documento %Document% è stato già assegnato lo stato ""%Status%""';
										|pl = 'Dokumentowi %Document% już został nadany status ""%Status%""';
										|tr = '%Document% belgesine artık ""%Status%"" durumu atandı'");
	ErrorPatternNotHeld        = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Không thể thay đổi trạng thái';
										|ru = 'Документ %Document% не проведен. Невозможно изменить статус';
										|en = 'Document %Document% is not posted. Cannot change the status'; fa = 'Document %Document% is not posted. Cannot change the status';
										|it = 'Documento %Document% non eseguito. Impossibile cambiare stato';
										|pl = 'Dokument %Document% nie jest zaksięgowany. Nie można zmienić status';
										|tr = '%Document% belgesi kaydedilmedi. Durum değiştirilemiyor'");
	ErrorPatternMarkedForDeletion = NStr("vi = 'Chứng từ %Document% đã đặt dấu xóa. Không thể thay đổi trạng thái';
										|ru = 'Документ %Document% помечен на удаление. Невозможно изменить статус';
										|en = 'Document %Document% is marked for deletion. Cannot change the status'; fa = 'Document %Document% is marked for deletion. Cannot change the status';
										|it = 'Documento %Document% contrassegnato per l''eliminazione. Impossibile cambiare stato';
										|pl = 'Dokument %Document% jest zaznaczony do usunięcia. Nie można zmienić status';
										|tr = '%Document% belgesi silinmek üzere işaretlendi. Durum değiştirilemiyor'");
	BlockErrorTemplate     = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
									|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
									|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
									|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
									|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
									|tr = '%Document% engellenemedi. %ErrorDescription%'");
	WriteErrorTemplate          = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
										|ru = 'Не удалось записать %Document%. %ErrorDescription%';
										|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
										|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
										|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
										|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
	
	// Getting excluded types
	ArrayOfExcludedTypes = New Array;
	If AdditionalParameters <> Undefined 
		And AdditionalParameters.Property("TypesToExclude") Then
		
		ArrayOfExcludedTypes = AdditionalParameters.TypesToExclude;
		
	EndIf;
	
	// Getting matching document types from an array of documents of different types
	MapTypes = TMCommonUse.DecomposeArrayOfReferencesByType(DocumentsArray);
	
	ProcessedItemsCount = 0;
	For Each DocumentsComposition In MapTypes Do
		
		// Skipping documents of the excluded type
		If ArrayOfExcludedTypes.Find(DocumentsComposition.Key) <> Undefined Then
			Continue;
		EndIf;
		
		// Getting a document manager of this type
		MetaDocument       = Metadata.FindByType(DocumentsComposition.Key);
		ManagerOfDocuments = Documents[MetaDocument.Name];
		
		// Getting an array of links of documents of this type
		ReferencesArrray = DocumentsComposition.Value;
		
		// Request formation
		Query = ManagerOfDocuments.GenerateVerificationRequestWhenStatusChanges(ReferencesArrray, NewStatus, AdditionalParameters);
		SetPrivilegedMode(True);
		Result = Query.Execute();
		SetPrivilegedMode(False);
		If Result.IsEmpty() Then
			Return 0;
		EndIf;
		
		// Sample traversal cycle
		Selection = Result.Select();
		While Selection.Next() Do
			
			// Universal checks
			If Selection.DeletionMark Then
				CommonClientServer.MessageToUser(StrReplace(ErrorPatternMarkedForDeletion, "%Document%", Selection.Presentation), Selection.Ref);
				Continue;
			EndIf;

			If Not Selection.Posted Then
				CommonClientServer.MessageToUser(StrReplace(ErrorPatternNotHeld, "%Document%", Selection.Presentation), Selection.Ref);
				Continue;
			EndIf;

			If Selection.StatusMatches Then

				ErrorText = StrReplace(ErrorPatternStatusMatches, "%Document%", Selection.Presentation);
				ErrorText = StrReplace(ErrorText, "%Status%", Selection.PresentationOfNewStatus);
				CommonClientServer.MessageToUser(ErrorText, Selection.Ref);
				Continue;

			EndIf;
			
			// The checks are unique for each of the document types
			If Not ManagerOfDocuments.CheckingBeforeChangingStatus(Selection, NewStatus, AdditionalParameters) Then
				Continue;
			EndIf;
			
			BeginTransaction();
			
			Try
				
				CurrentErrorTemplate = BlockErrorTemplate;
				
				Block = New DataLock;
				
				LockItem = Block.Add(Selection.Ref.Metadata().FullName());
				LockItem.SetValue("Ref", Selection.Ref);
				LockItem.Mode = DataLockMode.Exclusive;
				
				Block.Lock();
				
				LockDataForEdit(Selection.Ref);
				
				CurrentErrorTemplate = WriteErrorTemplate;
				
				Object = Selection.Ref.GetObject(); // DocumentObject
				If Object.SetStatus(NewStatus, AdditionalParameters) Then
					
					Object.Write(?(Selection.Recording,
						DocumentWriteMode.Posting,
						DocumentWriteMode.Write));
					
					ProcessedItemsCount = ProcessedItemsCount + 1;
					
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorInfo = ErrorInfo();
				
				ErrorText = StrReplace(CurrentErrorTemplate,
					"%Document%",
					Selection.Presentation);
				
				ErrorTextIsShort = StrReplace(ErrorText,
					"%ErrorDescription%",
					ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
				ErrorTextDetailed = StrReplace(ErrorText,
					"%ErrorDescription%",
					ErrorProcessing.DetailErrorDescription(ErrorInfo));
				
				CommonClientServer.MessageToUser(ErrorTextIsShort, Selection.Ref);
				
				WriteLogEvent(
					NStr("vi = 'Đặt trạng thái chứng từ.';
						|ru = 'Установка статуса документа.';
						|en = 'Set a document status.'; fa = 'Set a document status.';
						|it = 'Установка статуса документа.';
						|pl = 'Set a document status.';
						|tr = 'Belgenin durumunun yapılandırılması.'"),
					EventLogLevel.Error,
					MetaDocument,
					Selection.Ref,
					ErrorTextDetailed);
				
			EndTry;
			
		EndDo; // selections of documents of this type
		
	EndDo; // type matching bypass
	
	Return ProcessedItemsCount;
	
EndFunction // Set the status of documents()

#EndRegion

// Returns a structure containing an array of links to documents to be marked for deletion
// or unchecked, as well as the flag for deleting documents.
//
// Parameters:
// 		SelectedRows - Array - an array of documents to a dynamic list,
// 		LinkPath - String - name of the document's link details.
//
// Returns:
// 		Structure - contains an array of links to documents and a flag for deleting documents.
//
Function ReferencesToObjectsMarkedForDeletion(SelectedRows, LinkPath = "") Export
	
	If Not IsBlankString(LinkPath) Then
		ReferencesArrray = New Array;
		For Each String In SelectedRows Do
			ReferencesArrray.Add(String[LinkPath]);
		EndDo;
	Else
		ReferencesArrray = SelectedRows;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ReferencesArrray", ReferencesArrray);
	Result.Insert("ThereAreLinesMarkedForDeletion", False);
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ReferencesArrray);
	
	QueryTemplate = 
	"SELECT TOP 1
	|	DocumentTable.Ref AS Ref
	|FROM
	|	&DocumentName AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN(&References)
	|	AND DocumentTable.DeletionMark";	
	
	Query = New Query;
	QueryTextArray = New Array;
	Counter = 0;
	
	For Each RefType In StructureOfTypes Do
		
		QueryText = StrReplace(QueryTemplate, "&DocumentName", RefType.Key); 
		QueryText = StrReplace(QueryText, "&References", "&References" +  Format(Counter,"NG=0")); 
		
		Query.SetParameter("References" +  Format(Counter,"NG=0"), RefType.Value);
		Counter = Counter + 1;
		
		QueryTextArray.Add(QueryText);
	EndDo;
	
	Separator = "
	|
	|UNION ALL
	|";
	
	
	Query.Text = StrConcat(QueryTextArray, Separator);
	
	Result.ThereAreLinesMarkedForDeletion = Not Query.Execute().IsEmpty();
	
	Return Result;
	
EndFunction

// Performs marking for deletion or removing the mark from deletion of documents.
//
// Parameters:
// 		ReferencesArrray - Array - array of links to documents,
// 		MarkToDelete - Boolean - The need to set a mark to delete the document.
//
Procedure SetDeletionMarkCompletionServer(ReferencesArrray, MarkToDelete) Export
	
	For Each Ref In ReferencesArrray Do
		
		DocumentObject = Ref.GetObject();
		
		If DocumentObject = Undefined Then
			Continue;
		EndIf;
		
		Try
			// Write only those objects whose deletion tag value changes
			If MarkToDelete
				And Not DocumentObject.DeletionMark Then
				
				DocumentObject.DeletionMark = True;
				
				If DocumentObject.Posted Then
					DocumentObject.Write(DocumentWriteMode.UndoPosting);
				Else
					DocumentObject.Write(DocumentWriteMode.Write);
				EndIf;
				
			ElsIf Not MarkToDelete
				And DocumentObject.DeletionMark Then
				
				DocumentObject.DeletionMark = False;
				DocumentObject.Write(DocumentWriteMode.Write);
				
			EndIf;
		Except
			MessageText = ?(Not MarkToDelete
					And DocumentObject.DeletionMark,
				NStr("vi = 'Không thể xóa dấu xóa khỏi chứng từ: %Ref% vì lý do: %Cause%';
					|ru = 'Не удалось снять пометку удаления с документа: %Ref% по причине: %Cause%';
					|en = 'Cannot clear deletion mark from document: %Ref%. Reason: %Cause%'; fa = 'Cannot clear deletion mark from document: %Ref%. Reason: %Cause%';
					|it = 'Non è stato possibile togliere i contrassegno per l''eliminazione dal documento %Ref% a causa di: %Cause%';
					|pl = 'Nie udało się zdjąć zaznaczenie usuwania z dokumentu: %Ref% z powodu: %Cause%';
					|tr = '%Cause% nedeniyle belgeden silme işareti kaldırılamadı: %Ref% '"),
				NStr("vi = 'Không thể đặt dấu xóa: %Ref% vì lý do: %Cause%';
					|ru = 'Не удалось установить пометку удаления на документ: %Ref% по причине: %Cause%';
					|en = 'Cannot mark document %Ref% for deletion. Reason: %Cause%'; fa = 'Cannot mark document %Ref% for deletion. Reason: %Cause%';
					|it = 'Non è stato possibile impostare il contrassegno per l''eliminazione al documento %Ref% a causa di: %Cause%';
					|pl = 'Nie udało się ustawić zaznaczenie usuwania na dokument: %Ref% z powodu: %Cause%';
					|tr = '%Cause% nedeniyle belgede silme işareti ayarlanamadı: %Ref%'"));
			MessageText = StrReplace(MessageText, "%Ref%", Ref);
			MessageText = StrReplace(MessageText, "%Cause%", BriefErrorDescription(ErrorInfo()));
			
			CommonClientServer.MessageToUser(MessageText);
		EndTry;
		
	EndDo;
	
EndProcedure

// Returns an array of links to documents in the dynamic list.
//
// Parameters:
// 	SelectedRows - Array of FormDataStructure - Where:
// 		* Ref - DocumentRef -
//
// Returns:
// 	Array of DocumentRef - contains an array of links to documents and a flag for deleting documents.
//
Function DynamicListDocumentLinks(SelectedRows) Export
	
	ReferencesArrray = New Array;
	
	For Each String In SelectedRows Do
		ReferencesArrray.Add(String.Ref);
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

// Checks whether passed objects are filled in
//
// Parameters:
// 	SelectedRows - Array of FormDataStructure - Where:
// 		* Ref - DocumentRef -
// 
// Returns:
// 	Structure - Contains:
// 		* ReferencesArrray - Array of DocumentRef -
//		* YouCanSpend - Boolean -
//		* HasItemsMarkedForDeletion - Boolean -
//
Function LinksOfDocumentsForConducting(SelectedRows) Export

	ReferencesArrray = DynamicListDocumentLinks(SelectedRows);
	
	YouCanSpend = True;
	HasItemsMarkedForDeletion = False;
	For Each ObjectReference In ReferencesArrray Do
		Data_Object = ObjectReference.GetObject();
		If Data_Object.DeletionMark Then
			HasItemsMarkedForDeletion = True;
		Else
			YouCanSpend = Data_Object.CheckFilling() And YouCanSpend;
		EndIf; 
	EndDo;
	
	Result = New Structure;
	Result.Insert("ReferencesArrray", ReferencesArrray);
	Result.Insert("YouCanSpend", YouCanSpend);
	Result.Insert("HasItemsMarkedForDeletion", HasItemsMarkedForDeletion);
	
	Return Result;

EndFunction

// Attempts to cancel the documents and returns a collection containing information about the documents for which
// the cancellation was not completed.
//
// Parameters:
//	ReferencesArrray - Array of DocumentRef - array of document links.
//
// Returns:
//	Array of Structure - a collection containing information about documents for which cancellation has not been completed:
//		* Ref - DocumentRef - the document for which it was not possible to cancel the event.
//		* ErrorDescription - String - text describing the error that caused the cancellation to fail.
//									A missing error description means that the document was not carried out earlier.
//
Function CancellationOfDocuments(ReferencesArrray) Export
	
	UnverifiedDocuments	= New Array;
	UnpostedDocuments		= Common.CheckDocumentsPosting(ReferencesArrray);
	UnsolicitedDocuments		= CommonClientServer.ArraysDifference(ReferencesArrray, UnpostedDocuments);
	
	For Each Ref In UnpostedDocuments Do
		UnverifiedDocuments.Add(New Structure("Ref, ErrorDescription", Ref, ""));
	EndDo;
	
	For Each Ref In UnsolicitedDocuments Do
		BeginTransaction();
		
		Try
			DocumentName = Ref.Metadata().FullName();
			
			DataLock = New DataLock;
			
			DataLockItem = DataLock.Add(DocumentName);
			DataLockItem.SetValue("Ref", Ref);
			DataLockItem.Mode = DataLockMode.Exclusive;
			
			DataLock.Lock();
			
			DocumentObject = Ref.GetObject(); // DocumentObject - 
			
			DocumentObject.Lock();
			DocumentObject.Write(DocumentWriteMode.UndoPosting);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			UnverifiedDocuments.Add(New Structure("Ref, ErrorDescription", Ref, ErrorDescription));
		EndTry;
	EndDo;
	
	Return UnverifiedDocuments;
	
EndFunction

// Returns the organization's Bank account, if there is one in the IB.
//
// Returns:
// 	CatalogRef.CompaniesBankAccounts -
Function OrganizationSDefaultBankAccount() Export
	
	Return CashServer.GetOrganizationSDefaultBankAccount();
	
EndFunction

// Returns the organization's cash register if it is the only one in the IB.
//
// Returns:
// 	CatalogRef.CashAccounts -
Function OrganizationSDefaultSalesRegister() Export
	
	Return SettingsValueCached.GetOrganizationSDefaultSalesRegister();
	
EndFunction

// Returns the version of the classification by default.
//
// Returns:
// 	CatalogRef.TimeBucketsForAgingAnalysis -
Function DefaultDebtClassificationOption(OnlyIfOne = False) Export
	
	Return SettingsValueCached.DefaultDebtClassificationOption(OnlyIfOne);
	
EndFunction

// Returns the full name of the object's main form.
//
// Parameters:
//  Ref	 - 	AnyRef - object reference. For example, document Link or reference Link.
// 
// Returns:
//  String - the full name of the main form of the object.
//
Function FullNameOfObjectForm(Ref) Export
	
	FormName = "";
	MetadataObject = Ref.Metadata();
	
	If Common.IsDocument(MetadataObject) Then
		FormName = MetadataObject.FullName() + ".ObjectForm";
	ElsIf Common.IsCatalog(MetadataObject) Then
		FormName = MetadataObject.Forms.ItemForm.FullName();
	EndIf;
		
	Return FormName;
	
EndFunction

// Checks the status of the background task by the specified ID.
// 
// Parameters:
//  JobID - UUID - ID of the background task.
// Returns: 
//  Structure - Contains the statuses of the background task being checked.
Function CheckBackgroundTask(Val JobID) Export
	
	Result = New Structure();
	Result.Insert("CancelledOrNotFound", False);
	Result.Insert("CompletedSuccessfully1", False);
	Result.Insert("StillRunning", False);
	Result.Insert("DoneWithErrors", False);
	Result.Insert("ErrorText", "");
	Result.Insert("Begin", "");
	Result.Insert("End", "");
	
	Filter = New Structure();
	Filter.Insert("UUID", JobID);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If ActiveTasks.Count() = 0 Then
		Result.CancelledOrNotFound = True;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Active Then
		Result.StillRunning = True;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Completed Then
		Result.CompletedSuccessfully1 = True;
		Result.Begin = ActiveTasks[0].Begin;
		Result.End = ActiveTasks[0].End;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Failed Then
		Result.DoneWithErrors = True;
		Result.ErrorText = DetailErrorDescription(ActiveTasks[0].ErrorInfo);
		Result.Begin = ActiveTasks[0].Begin;
		Result.End = ActiveTasks[0].End;
	ElsIf ActiveTasks[0].State = BackgroundJobState.Canceled Then
		Result.CancelledOrNotFound = True;
	EndIf;
	
	Return Result;
EndFunction

// Cancels the background task based on the passed ID.
// 
// Parameters:
//  JobID - String - the key of the background task. 
// 
Procedure CancelJobExecution(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	Filter = New Structure();
	Filter.Insert("UUID", JobID);
	
	ActiveTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	If ActiveTasks.Count() = 0
		Or ActiveTasks[0].State <> BackgroundJobState.Active
	Then
		Return;
	EndIf;
	
	Try
		ScheduledJobsInternal.CancelBackgroundJob(ActiveTasks[0].UUID);
	Except
		// Perhaps the task has just ended at this moment and there is no error.
		WriteLogEvent(
			NStr("vi = 'Hủy nhiệm vụ nền';
				|ru = 'Отмена выполнения фонового задания';
				|en = 'Cancel background job'; fa = 'لغو کار پس‌زمینه';
				|it = 'Annullamento del Task di background';
				|pl = 'Anulowanie wykonywania zadania w tle';
				|tr = 'Arka plan işinin gerçekleştirilmesinin iptali'",
			Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.CommonModules.GeneralPurposeTMServerCall,
			,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Returns the value of a functional option by name
//
// Parameters:
// 	Name - String - Name of the function option
// 
// Returns:
//	Arbitrary - Value of the functional option
// 
Function ValueOfFunctionOption(Name) Export
	Return GetFunctionalOption(Name);	
EndFunction

// Returns the value of a constant by name
//
// Parameters:
// 	Name - String - Name of the constant
// 
// Returns:
//	Arbitrary - The value of the constant
// 
Function ConstantValue(Name) Export
	Return Constants[Name].Get();
EndFunction

// Returns the value of a constant by name
//
// Parameters:
// 	DocumentNameOrID - String -
// 					- CatalogRef.MetadataObjectIDs -
// 					- CatalogRef.ExtensionObjectIDs - The name or identifier of the document metadata.
// 
// Returns:
//	String - Document synonym
// 
Function DocumentSynonym(DocumentNameOrID) Export
	
	Result = "";
	If TypeOf(DocumentNameOrID) = Type("String") Then
		MetadataObject = Metadata.Documents[DocumentNameOrID];
	ElsIf TypeOf(DocumentNameOrID) = Type("CatalogRef.MetadataObjectIDs")
		Or TypeOf(DocumentNameOrID) = Type("CatalogRef.ExtensionObjectIDs") Then
		MetadataObject = Common.MetadataObjectByID(DocumentNameOrID);
	EndIf;
	
	If ValueIsFilled(MetadataObject.ObjectPresentation) Then
		Result = MetadataObject.ObjectPresentation;
	Else
		Result = MetadataObject.Synonym;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a flag indicating that the user has set the interface language
// corresponding to the main language of the information base.
//
// Returns:
//  Boolean
//
Function IsMainLanguage() Export
	
	Return Common.IsMainLanguage();
	
EndFunction

// Write to the Log to inform the user about the results of the event or cancellation of the event.
//
// Parameters:
//	UnpostedDocumentsData - See Common.PostDocuments.
//	Posting - Boolean - indicates the document recording mode. If the value is True, then
//							information about the results of the documents is recorded in the Log.
//
// Returns:
//	Array of DocumentRef - collection of links to documents for which it was not possible to complete or cancel
//								the event. The collection does not include links to documents for which there is no
//								description of the error.
//
Function WriteToLogToInformUserAboutResultsOfCancellationOfEvent(UnpostedDocumentsData,
																					Posting = True) Export
	
	If Posting Then
		MessageTemplate = NStr("vi = 'Chứng từ %1 chưa kết chuyển. %2';
								|ru = 'Документ %1 не проведен. %2';
								|en = 'The %1 document is not posted: %2'; fa = 'The %1 document is not posted: %2';
								|it = 'The %1 document is not posted: %2';
								|pl = 'The %1 document is not posted: %2';
								|tr = '%1 belgesi kaydedilmedi. %2'");
	Else
		MessageTemplate = NStr("vi = 'Đối với chứng từ %1 chưa hủy kết chuyển. %2';
								|ru = 'Для документа %1 не выполнена отмена проведения. %2';
								|en = 'The %1 document posting is not canceled: %2'; fa = 'The %1 document posting is not canceled: %2';
								|it = 'The %1 document posting is not canceled: %2';
								|pl = 'The %1 document posting is not canceled: %2';
								|tr = '%1 belgesinde kayıt iptali gerçekleştirilemedi. %2'");
	EndIf;
	
	UnpostedDocuments = New Array;
	
	LogParameters = New Structure;
	LogParameters.Insert("EventGroup_",NStr("vi = 'Lỗi thực hiện';
											|ru = 'Ошибка выполнения';
											|en = 'Runtime error'; fa = 'خطای زمان اجرا';
											|it = 'Errore nell''esecuzione';
											|pl = 'Błąd wykonania';
											|tr = 'Uygulama hatası'"));
	
	For Each DocumentInformation In UnpostedDocumentsData Do
		If IsBlankString(DocumentInformation.ErrorDescription) Then
			UnpostedDocuments.Add(DocumentInformation.Ref);
			
			Continue;
		EndIf;
		
		LogParameters.Insert("Metadata", DocumentInformation.Ref.Metadata());
		LogParameters.Insert("Data", DocumentInformation.Ref);
		
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				String(DocumentInformation.Ref),
				DocumentInformation.ErrorDescription);
		
		TMCommonUse.LogReportToUser(
			LogParameters,
			EventLogLevel.Error,
			"",
			,
			ErrorDescription);
		
		UnpostedDocuments.Add(DocumentInformation.Ref);
	EndDo;
	
	Return UnpostedDocuments;
	
EndFunction

#EndRegion

#Region Private

#Region ObjectAttributes

// Returns a structure containing the details values read from the information base by reference to the object.
// It is recommended to use it instead of accessing the object's details through a dot from the object reference
// to quickly read individual object details from the database.
//
// If you need to read the details regardless of the current user's rights,
// you should use the pre - transition to privileged mode.
//
// Parameters:
//  Ref    - AnyRef - the object whose details are to be retrieved.
//            - String      - the full name of the predefined element, the values of the details of which must be obtained.
//  Attributes - String - names of details, separated by commas, in the format
//                       of requirements for structure properties.
//                       For Example, "Code, Name, Parent".
//            - Structure
//            - FixedStructure - the
//                       alias of the field for the returned structure with the result is passed as the key
//                       , and the actual name of the field in the table is passed as the value (optional).
//                       If the key is set, but the value is not defined, then the field name is taken from the key.
//                       It is allowed to specify the field name separated by a dot, but the Language code parameter for such a field
//                       will not be taken into account.
//            - Array
//            - FixedArray - the names of the details in the format of the requirements
//                       for the properties of the structure.
//  Select Resolved - Boolean - if True, the request to the object is executed taking into account the user's rights;
//                                if there is a restriction at the record level, then all the details will be returned with 
//                                the value Undefined; if there are no rights to work with the table, an exception will occur;
//                                if False, an exception will occur if there are no rights to the table 
//                                or any of the details.
//  Language Code - String - language code for multilingual props.
//
// Returns:
//  Structure - 
Function ObjectAttributesValues(Ref, Attributes) Export
	
	Return Common.ObjectAttributesValues(Ref, Attributes);
	
EndFunction

// Outdated.
// Returns the values of the props read from the information base by reference to the object.
// It is recommended to use instead of accessing the object details through a dot from the object reference
// to quickly read individual object details from the database.
//
// If you need to read the details regardless of the rights of the current user,
// you should use the pre-transition to privileged mode.
//
// Parameters:
//  Ref    - AnyRef - the object whose details are to be retrieved.
//            - String      - the full name of the predefined element, the values of the details of which must be obtained.
//  AttributeName       - String - the name of the bank account to receive.
//                                It is allowed to specify the name of a prop separated by a dot, but the language code parameter for
//                                such a prop will not be taken into account.
//  Select Allowed-Boolean - if true, the request to the object is executed with the user's rights taken into account;
//                                if there is a record-level constraint, it is returned Undefined;
//                                if you do not have the rights to work with the table, an exception will occur;
//                                if False, an exception will occur if there are no rights to the table
//                                or any of the details.
//  Language code-String - the language code for the multilingual props.
//
// Returns:
//  Arbitrary - 
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	Return Common.ObjectAttributeValue(Ref, AttributeName);
	
EndFunction

// Outdated.
// Returns the values of the details read from the information base for several objects.
// It is recommended to use instead of accessing the object details through a dot from the object reference
// to quickly read individual object details from the database.
//
// If you need to read the details regardless of the rights of the current user,
// you should use the pre-transition to privileged mode.
//
// Parameters:
//  ReferencesArrray - Array
//         - FixedArray - references to objects.
//                    If the array is empty, the result will be an empty match.
//  AttributesNames - String - the names of the details are separated by commas, in the format of requirements for
//                       the structure properties. For Example, "Code, Name, Parent".
//            - Array
//            - FixedArray - the names of the details in the format of the requirements
//                       for the properties of the structure.
//  SelectAllowedItems - Boolean - if True, then the request to the objects is executed taking into account the user's rights;
//                                if any object is excluded from the selection by rights, then this object
//                                will be excluded from the result as well;
//                                if False, an exception will occur if there are no rights to the table
//                                or any of the details.
//  Language Code-String - The language code for the multilingual props.
//
// Returns:
//  Map of KeyAndValue - list of objects and the values of their Attributes:
//   * Key - AnyRef - object reference;
//   * Value - Structure:
//    ** Key - String - the name of the props;
//    ** Value - Arbitrary - the value of the props.
// 
Function ObjectsAttributesValues(ReferencesArrray, AttributesNames, SelectAllowedItems = False) Export
	
	Return Common.ObjectsAttributesValues(ReferencesArrray, AttributesNames, SelectAllowedItems);
	
EndFunction

// Outdated.
// Returns the values of the props read from the information base for several objects.
// It is recommended to use instead of accessing the object details through a dot from the object reference
// to quickly read individual object details from the database.
//
// If you need to read the details regardless of the rights of the current user,
// you should use the pre-transition to privileged mode.
//
// Parameters:
//  ReferencesArrray       - Array - array of object references.
//  AttributeName       - String - for example, "Code".
//  SelectAllowedItems - Boolean - if True, then the request to the objects is executed taking into account the user's rights;
//                                if any object is excluded from the selection by rights, then this object
//                                will be excluded from the result as well;
//                                if False, an exception will occur if there are no rights to the table
//                                or any of the details.
//  Language Code-String - The language code for the multilingual props.
//
// Returns:
//  Map -
// 
Function ObjectsAttributeValue(ReferencesArrray, AttributeName, SelectAllowedItems = False) Export
	
	Return Common.ObjectsAttributeValue(ReferencesArrray, AttributeName, SelectAllowedItems);
	
EndFunction

#EndRegion

#Region UsersRights

Function IsFullUser(User = Undefined,
                                    CheckSystemAdministrationRights = False,
                                    ForPrivilegedMode = True) Export
	
	Return Users.IsFullUser(
		User,
		CheckSystemAdministrationRights,
		ForPrivilegedMode);
	
EndFunction

#EndRegion

#Region ContactInformation

// Updates the values of the CI fields from its representation.
//
//  Parameters:
//		Presentation - String - Ki representation
//		FieldValues - String - service information, values of CI fields
//		CIType - EnumRef.ContactInformationTypes - type of contact information.
//
Procedure FillInValuesOfCIFieldsOnPresentation(Presentation, FieldValues, CIType = Undefined) Export
	
	TMCommonUse.FillInValuesOfCIFieldsOnPresentation(Presentation, FieldValues, CIType);
	
EndProcedure

#EndRegion

#Region FullTextSearch

// Determines whether to use full-text search, based on the value of the passed FO
// and the usage settings for the database as a whole.
//
// Parameters:
//	NameOfFOOfUseOfPPD - String - the name of the function option to consider.
//
// Returns:
//	Boolean - True if used, False otherwise.
//
Function FullTextSearchIsUsed(NameOfFOOfUseOfPPD) Export
	
	Return GetFunctionalOption(NameOfFOOfUseOfPPD)
		And FullTextSearch.GetFullTextSearchMode() = FullTextSearchMode.Enable;
	
EndFunction

#EndRegion

#Region SelectionLists

Procedure SelectableEnumerationValues(EnumerationName, ChoiceData, Parameters, ExcludedValues) Export
	
	TMCommonUse.SelectableEnumerationValues(
			EnumerationName,
			ChoiceData,
			Parameters,
			ExcludedValues);
			
EndProcedure

// See TMCommonUse.AvailableBusinessTransactions.
Function AvailableBusinessTransactions(TableName) Export
	
	Return TMCommonUse.AvailableBusinessTransactions(TableName);
	
EndFunction

Function SessionDate() Export
	Return CurrentSessionDate();
EndFunction

#EndRegion

#Region DocumentFulfillmentStatus

Function CheckListOfDocuments(DocumentsArray) Export 
	
	MapTypes = TMCommonUse.MatchingArraysByObjectType(DocumentsArray);
	Return MapTypes.Count() = 1;
	
EndFunction

#EndRegion

#Region CompareSchedulesOfPaymentsAndAccrualsOfCreditDepositLoanContracts

Function ScheduleOwner(ScheduleOption) Export
	
	Return ScheduleOption.Owner;
	
EndFunction

#EndRegion

#Region IBUpdate

// Returns the structure of parameters required when starting the configuration.
//
// Parameters:
//   Parameters - Structure - (return value) structure of program parameters at startup.
//
Procedure ClientParametersOnStart(Parameters) Export
	
	// To prohibit updates from unsupported versions
	Parameters.Insert("DataVersion", InfobaseUpdateInternal.IBVersion(Metadata.Name, True)); 
	Parameters.Insert("MetadataVersion", TrimAll(Metadata.Version));
	Parameters.Insert("AskQuestionAboutSwitchingToOnlineSettlements", False);
	Parameters.Insert("OpenNotificationAboutOutdatedFunctionality", False);
	
	If Common.DataSeparationEnabled()
		And Not Common.SeparatedDataUsageAvailable() Then
		Return; // if the area is zero, then we exit
	EndIf;
	
	If GetFunctionalOption("BaseVersion") And Users.IsFullUser() Then
		YouCanAskAboutTransition = Not Constants.DoNotAskAboutSwitchingToOnlineARAPAccounting.Get();
		Parameters.AskQuestionAboutSwitchingToOnlineSettlements = Not Constants.NewOnlineARAPAccounting.Get()
			And Constants.DeferredUpdateCompletedSuccessfully.Get()
			And YouCanAskAboutTransition;
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
		Parameters.OpenNotificationAboutOutdatedFunctionality =
			Users.IsFullUser() 
			And Constants.NotifyAboutOutdatedFunctionality.Get() 
			And DataProcessors.TransitionReadiness26.CheckUseOfOutdatedFunctionality();
	EndIf;
	
	Parameters.Insert("ServiceSubsystems_ObjectsOfTMCAERP_InitialProgramSetupForm",
		OpenFormsOnApplicationStartServerCall.InitialProgramSetupForm());
		
	Parameters.Insert("ServiceSubsystems_ObjectsOfUTKAUP_OfSMPExchangeComponent", Undefined);
	
EndProcedure

#EndRegion

#Region Subsystems

Function NameOfSchedulingSubsystem() Export
	If GetFunctionalOption("TradeManagement") Then
		NameOfSchedulingSubsystem = "Planning";
	Else
		
		NameOfSchedulingSubsystem = "BudgetingAndPlanning";
		
	EndIf;
	Return NameOfSchedulingSubsystem;
	
EndFunction

#EndRegion

#Region Other

Procedure CheckItemDetailsParameters(ItemDetailsParameters) Export

	If ItemDetailsParameters.Count() = 0 Then
		Return;
	EndIf; 
	
	ParametersOfItemDetailsTable = New ValueTable;
	ParametersOfItemDetailsTable.Columns.Add("AttributeName");
	ParametersOfItemDetailsTable.Columns.Add("TagName");
	ParametersOfItemDetailsTable.Columns.Add("Property");
	ParametersOfItemDetailsTable.Columns.Add("Count");
	
	CommonClientServer.SupplementTable(ItemDetailsParameters, ParametersOfItemDetailsTable);
	
	ParametersOfItemDetailsTable.FillValues(1, "Count");
	ParametersOfItemDetailsTable.GroupBy("AttributeName,TagName,Property", "Count");
	ParametersOfItemDetailsTable.Sort("AttributeName,Property");
	
	For Each AttributeParameters In ParametersOfItemDetailsTable Do
		If AttributeParameters.Count > 1 And AttributeParameters.AttributeName <> "" Then
			MessageText = NStr("ru = 'Отладка: для реквизита ""%1"" свойство ""%2"" определяется несколько раз.';
								|vi = 'Debug: For the ""%1"" attribute, the ""%2"" property is determined several times.';
								|en = 'Debug: For the ""%1"" attribute, the ""%2"" property is determined several times.'; fa = 'Debug: For the ""%1"" attribute, the ""%2"" property is determined several times.';
								|it = 'Debug: For the ""%1"" attribute, the ""%2"" property is determined several times.';
								|pl = 'Debug: For the ""%1"" attribute, the ""%2"" property is determined several times.';
								|tr = 'Hata ayıklama: ""%1"" özniteliği için ""%2"" özelliği birden fazla kez tanımlandı.'");
			MessageText = StrTemplate(MessageText,
										?(ValueIsFilled(AttributeParameters.AttributeName), AttributeParameters.AttributeName, AttributeParameters.TagName), 
										AttributeParameters.Property);
										
			CommonClientServer.MessageToUser(MessageText); 
		EndIf; 
	EndDo; 
	
EndProcedure

#EndRegion

#EndRegion
