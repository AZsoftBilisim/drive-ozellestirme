#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Marks the change in the document verification status.
// 
// Parameters:
//	DocumentsArray - Array of DocumentRef - a reference to a document or an array of documents
//		that is a dimension of the register "Document verification Statuses" (see the dimension "Document" of this register) .
//	ErrorData_ - Map of KeyAndValue:
//		* Key - DocumentRef - link to the document whose Status was set with an error.
//		* Value - String - description of the error.
//		Compliance of error descriptions with documents (if not specified, error data is not recorded).
//	DocumentVerified - Boolean - True if it is marked that the document has been verified and false otherwise.
//	 		If you need to change the current status, you can omit the value of this parameter.
//
Procedure SetStatusOfDocumentVerification(Val DocumentsArray, ErrorData_ = Undefined, DocumentVerified = Undefined) Export
	
	ToFixErrors = Not ErrorData_ = Undefined;
	
	If Not TypeOf(DocumentsArray) = Type("Array") Then
		Document = DocumentsArray;
		DocumentsArray = New Array;
		DocumentsArray.Add(Document);
	EndIf;
	
	If Not AccessRight("Update", Metadata.InformationRegisters.StatusOfDocumentVerification) Then
		If ToFixErrors Then
			ErrorData_.Insert(DocumentsArray.Get(0), NStr("vi = 'Người sử dụng không đủ quyền để thay đổi dữ liệu kiểm tra chứng từ';
															|ru = 'У пользователя не достаточно прав для изменения данных о проверке документов';
															|en = 'User is not authorized to change the document check data'; fa = 'User is not authorized to change the document check data';
															|it = 'L''utente non ha abbastanza diritti per modificare i dati sulla verifica dei documenti';
															|pl = 'Użytkownik nie ma wystarczających praw do zmiany danych o sprawdzeniu dokumentów';
															|tr = 'Kullanıcı belge kontrolü verilerini değiştirmek için yeterli erişim haklarına sahip değil'"));
		EndIf;
		Return;
	EndIf;
	
	TextOfDocumentError = NStr("vi = 'Không thể thay đổi trạng thái kiểm tra chứng từ %1.
		|Có thể là có người sử dụng khác đang làm việc với chứng từ.';
		|ru = 'Недоступно изменение статуса проверки документа %1.
		|Возможно с документом работают другие пользователи.';
		|en = 'Cannot change the %1 document check status.
		|Other users may be working with the document.'; fa = 'Cannot change the %1 document check status.
		|Other users may be working with the document.';
		|it = 'Non è disponibile la modifica dello stato di verifica del documento %1.
		|Probabilmente altri utenti lavorano con il documento.';
		|pl = 'Jest niedostępna zmiana statusu sprawdzenia dokumentu  %1.
		|Możliwe, że z dokumentem pracują inni użytkownicy.';
		|tr = 'Belge kontrol durumunu değiştirmek mevcut değil%1.
		|Belge üzerinde başka kullanıcılar çalışıyor olabilir.'");
	
	DocumentsTable = InformationRegisters.StatusOfDocumentVerification.CreateRecordSet().UnloadColumns("Document");
	CommonClientServer.SupplementTableFromArray(DocumentsTable, DocumentsArray, "Document");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentsTable.Document AS Document
	|INTO DocumentsTable
	|FROM
	|	&DocumentsTable AS DocumentsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Document AS Document,
	|	DocumentVerificationOverridable.Period,
	|	DocumentVerificationOverridable.Organization,
	|	DocumentVerificationOverridable.CheckStatus AS VerificationStatusIsOld,
	|	CASE
	|		WHEN NewVerificationStatus.Ref = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
	|		THEN &CurrentUser
	|		ELSE DocumentVerificationOverridable.WhoChecked
	|	END AS WhoChecked,
	|	CASE
	|		WHEN NewVerificationStatus.Ref = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
	|		THEN &CurrentDate
	|		ELSE DocumentVerificationOverridable.CheckDate
	|	END AS CheckDate,
	|	CASE
	|		WHEN NewVerificationStatus.Ref = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
	|		THEN DocumentVerificationOverridable.ChangedBy
	|		ELSE &CurrentUser
	|	END AS ChangedBy,
	|	CASE
	|		WHEN NewVerificationStatus.Ref = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
	|		THEN DocumentVerificationOverridable.ChangeDate
	|		ELSE &CurrentDate
	|	END AS ChangeDate,
	|	NewVerificationStatus.Ref AS CheckStatus
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN DocumentVerificationOverridable AS DocumentVerificationOverridable
	|		ON DocumentsTable.Document = DocumentVerificationOverridable.Document
	|		INNER JOIN Enum.StatusOfFinancialDocumentVerification AS NewVerificationStatus
	|		ON NewVerificationStatus.Ref = CASE
	|			WHEN &NewVerificationStatus = UNDEFINED AND DocumentVerificationOverridable.CheckStatus <> VALUE(Enum.StatusOfFinancialDocumentVerification.Verified) OR &NewVerificationStatus = TRUE
	|			THEN VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
	|			WHEN &NewVerificationStatus = FALSE AND DocumentVerificationOverridable.CheckStatus = VALUE(Enum.StatusOfFinancialDocumentVerification.NotVerified)
	|			THEN VALUE(Enum.StatusOfFinancialDocumentVerification.NotVerified)
	|			ELSE VALUE(Enum.StatusOfFinancialDocumentVerification.ToReCheck)
	|		END
	|TOTALS BY
	|	Document";
	
	// Explanation of the request:
	//	Checked and data checks - are filled in by the Cur user when the new verification Status becomes "Verified";
	//	I also changed the date of the change - on the contrary, when the Status of the check changes the Status to "Unchecked" or to "Repeated check";
	//	newstatescheck:
	//		1) If the parameter is not specified, then we should simply change the Cur Status of the document verification
	//		to the opposite. Thus, if there was a check mark earlier, then there should be a "Re-check",
	//		and if the document was previously not checked (or re-checked), then it should become verified.
	//		2) If the parameter is true (the document becomes verified), specify the Status "Verified".
	//		3) If the parameter is false (the document should become unverified) - we indicate the Status "Not verified" when the document
	//		has never been checked before, otherwise - "K-check again".
	
	Query.SetParameter("DocumentsTable", DocumentsTable);
	Query.SetParameter("NewVerificationStatus", DocumentVerified);
	Query.SetParameter("CurrentUser", Users.CurrentUser());
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	DocumentVerificationServer.OverrideVerificationStatusInRequestTextTakingIntoAccountExceptions(Query.Text, "DocumentsTable.Document");
	
	Result = Query.Execute();
	
	DocumentVerificationStatuses = InformationRegisters.StatusOfDocumentVerification.CreateRecordSet();
	LockParameters	= New Structure("TableType, TableName", "InformationRegister", "StatusOfDocumentVerification");
	
	// Let's write down the changes for documents whose data was previously entered in the register:	
	SelectionByDocuments = Result.Select(QueryResultIteration.ByGroups);
	
	While SelectionByDocuments.Next() Do
		
		BeginTransaction();
		
		Try
					
			LockValues	= New Structure("Document", SelectionByDocuments.Document);
			TMCommonUse.SetManagedLock(LockParameters, LockValues);
			
			LockDataForEdit(SelectionByDocuments.Document);
			
			DocumentVerificationStatuses.Clear();
			DocumentVerificationStatuses.Filter.Document.Set(SelectionByDocuments.Document);
			
			Selection = SelectionByDocuments.Select();
			
			While Selection.Next() Do
				
				RegisterRecord = DocumentVerificationStatuses.Add();
				FillPropertyValues(RegisterRecord, Selection);
				
			EndDo;
			
			DocumentVerificationStatuses.Write();
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			If ToFixErrors Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextOfDocumentError, SelectionByDocuments.Document);
				ErrorData_.Insert(SelectionByDocuments.Document, ErrorText);
			EndIf;
			
		EndTry;
		
		UnlockDataForEdit(SelectionByDocuments.Document);
		
	EndDo;
	
EndProcedure

// Receives data about document verification.
//
//	Parameters:
//		DocumentRef - DocumentRef - a link to the document for which verification data should be obtained (see the Dimension "Document" of this register).
//
//	Returns:
//		Structure - contains the following data:
//			* CheckStatus - EnumRef.StatusOfFinancialDocumentVerification - current status of document verification
//			* Verified - Boolean - a sign of document verification, if there is no data on the verification of this document in the database, returns False;
//			* WhoChecked - CatalogRef.Users - the last user who checked the document, if no one checked, is an empty link;
//			* CheckDate - Date - date and time of the last document check.
//			* HasBeenVerified - Boolean - Indicates that the document has been previously checked.
//			* NotificationCheck - Boolean - blocks the document form if it is verified. By default, it is equal to the "Allow to change verified Financial documents".
//
Function GetDocumentVerificationData(DocumentRef) Export
	
	ReturnStructure = InitializeDocumentVerificationData();
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT TOP 1
	|	StatusOfDocumentVerification.Organization AS Organization,
	|	StatusOfDocumentVerification.Document AS Document,
	|	StatusOfDocumentVerification.WhoChecked AS WhoChecked,
	|	StatusOfDocumentVerification.CheckDate AS CheckDate,
	|	StatusOfDocumentVerification.CheckStatus AS CheckStatus,
	|	ISNULL(Exceptions.NotificationCheck, Constants.AllowModificationOfAuditedFinancialDocuments) AS NotificationCheck,
	|	StatusOfDocumentVerification.CheckStatus = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified) AS Verified,
	|	StatusOfDocumentVerification.CheckStatus = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)
	|		OR StatusOfDocumentVerification.CheckStatus = VALUE(Enum.StatusOfFinancialDocumentVerification.ToReCheck) AS HasBeenVerified
	|FROM
	|	InformationRegister.StatusOfDocumentVerification AS StatusOfDocumentVerification
	|		INNER JOIN Constants AS Constants
	|		ON TRUE
	|		LEFT JOIN InformationRegister.SettingsOfDocumentCheckExceptions AS Exceptions
	|		ON VALUETYPE(StatusOfDocumentVerification.Document) = VALUETYPE(Exceptions.DocumentKind.EmptyRefValue)
	|WHERE
	|	StatusOfDocumentVerification.Document = &Document
	|
	|ORDER BY
	|	Verified DESC";
	Query.SetParameter("Document", DocumentRef);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		FillPropertyValues(ReturnStructure, Selection);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Sets the status "Not verified" for new documents or cancels the document verification if the document was previously modified.
//
//	Parameters:
//		DocumentRef - DocumentRef - a link to the document for which the Status is being recorded (see the Dimension "Document" of this register) ;
//		DocumentDate - Date - Document date
//		Companies - Array of CatalogRef - array of organizations for which it is necessary to reflect the record of document verification in the register
//		CheckData - See GetDocumentVerificationData
//		AddlParameters - Structure - It can contain the following properties:
//			* BusinessOperation - EnumRef.BusinessTransactions - if "Return to operation" is passed, then the verification status
//										is forcibly set to an empty link, since such documents should not be checked.
//
Procedure SetDocumentVerificationStatusWhenRecording(DocumentRef,  DocumentDate, Companies, CheckData, AddlParameters = Undefined) Export
	
	DocumentVerification = InformationRegisters.StatusOfDocumentVerification.CreateRecordSet();
	DocumentVerification.Filter.Document.Set(DocumentRef);
	DocumentVerification.Clear();
	
	CheckStatus = Enums.StatusOfFinancialDocumentVerification.NotVerified;
	If CheckData.Property("HasBeenVerified") And CheckData.HasBeenVerified Then
		CheckStatus = Enums.StatusOfFinancialDocumentVerification.ToReCheck;
	EndIf;
	If AddlParameters <> Undefined Then
		If AddlParameters.Property("BusinessOperation") And AddlParameters.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
			CheckStatus = Enums.StatusOfFinancialDocumentVerification.EmptyRef();
		EndIf;
	EndIf;
	
	For Each Organization In Companies Do
		
		RecordingVerificationStatus = DocumentVerification.Add();
	
		RecordingVerificationStatus.Document = DocumentRef;
		RecordingVerificationStatus.Period = DocumentDate;
		RecordingVerificationStatus.Organization = Organization;
		
		RecordingVerificationStatus.ChangeDate = CurrentSessionDate();
		RecordingVerificationStatus.ChangedBy = Users.CurrentUser();
		RecordingVerificationStatus.CheckStatus = CheckStatus;
		RecordingVerificationStatus.WhoChecked = CheckData.WhoChecked;
		RecordingVerificationStatus.CheckDate = CheckData.CheckDate;
		
	EndDo;
	
	DocumentVerification.Write();
	
EndProcedure

// Receives data about document verification.
//
//	Returns:
//		Structure - contains the following data:
//			* CheckStatus - EnumRef.StatusOfFinancialDocumentVerification - current status of document verification
//			* Verified - Boolean - a sign of document verification, if there is no data on the verification of this document in the database, returns False;
//			* WhoChecked - CatalogRef.Users - the last user who checked the document, if no one checked, is an empty link;
//			* CheckDate - Date - date and time of the last document check.
//			* HasBeenVerified - Boolean - Indicates that the document has been previously checked.
//			* NotificationCheck - Boolean - blocks the document form if it is verified. By default, it is equal to the "Allow to change verified Financial documents".
//
Function InitializeDocumentVerificationData() Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Verified", False);
	ReturnStructure.Insert("WhoChecked", Catalogs.Users.EmptyRef());
	ReturnStructure.Insert("CheckDate", Date(1,1,1));
	ReturnStructure.Insert("CheckStatus", Enums.StatusOfFinancialDocumentVerification.EmptyRef());
	ReturnStructure.Insert("HasBeenVerified", False);
	ReturnStructure.Insert("NotificationCheck", GetFunctionalOption("AllowModificationOfAuditedFinancialDocuments"));
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

#EndIf
