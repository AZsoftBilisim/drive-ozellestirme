//////////////////////////////////////////////////////////////////////////////////////////////
// Document verification: Server-side methods.
//
//////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region FormsEventHandlers

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler;
//  Cancel					- Boolean - flag for refusing to create a form;
//  StandardProcessing	- Boolean - indicates whether standard (system) event processing is performed;
//  AdditionalParameters	- Structure - advanced setting.
//
Procedure WhenCreatingFormOnServer(Form, Cancel, StandardProcessing, AdditionalParameters = Undefined) Export
	
	If VerificationCommandIsAddedToDocumentForm(Form) Then
		
		AddVerificationDetailsToForm(Form);
		
		FormCommand = AddValidationCommandToForm(Form);
		
		If FormCommand <> Undefined Then
			UpdateDocumentVerificationDataOnForm(Form);
		EndIf;
		
	EndIf;
	
	If ChangeVerificationImageOnListForm(Form, AdditionalParameters) Then
		// By default, a lock is displayed on the list form, in case of document verification, but if the list looks with the rights
		// to change the verification status, then it is more expedient for it to set a green check mark (as done in the document form).
		
		SetPropertiesOfVerificationImageOnListForm(Form, AdditionalParameters);
		
	EndIf;
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//	Form					- ClientApplicationForm - the form from which the procedure is called from the event handler;
//	CurrentObject			- DocumentObject - the object being processed to be read.
//
Procedure WhenReadingFormOnServer(Form, CurrentObject) Export
	
	If TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_DocumentVerified") Then
		// The form is verifiable, so it contains all the necessary details and commands.
		
		CheckData = InformationRegisters.StatusOfDocumentVerification.GetDocumentVerificationData(CurrentObject.Ref);
		UpdateDocumentVerificationDataOnForm(Form, CheckData);
		
	EndIf;
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//	Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//	CurrentObject			- DocumentObject - the object being recorded.
//	WriteParameters			- Structure - additional recording parameters.
//
Procedure AfterWriteAtServer(Form,  CurrentObject, WriteParameters) Export
	
	If VerificationCommandIsAddedToDocumentForm(Form) Then
		
		If Not TMCommonUseClientServer.HasObjectAttribute(Form, "DocumentVerification_DocumentVerified") Then
			// Validation properties were not initialized on the form earlier. We are initializing them now.
			AddVerificationDetailsToForm(Form);
			AddValidationCommandToForm(Form);
		EndIf;
			
		UpdateDocumentVerificationDataOnForm(Form);
		
	EndIf;
	
EndProcedure

// In the case of using the inspection of documents at reg. adds a dynamic list of the document log to the request,
//	a conditional connection to the "Statusproverkidocuments" information register, and replaces template parameters with expressions.
//
//	Parameters:
//		QueryText - String - dynamic list request text to process;
//		NameOfMainTable - String - it is used to determine the substitution of a conditional connection and to determine the connection condition.
//
Procedure ModifyDynamicDocumentLogListRequest(QueryText, NameOfMainTable) Export
	
	LinkSubstitutionText = "LEFT JOIN InformationRegister.StatusOfDocumentVerification AS VerificationStatuses
		|	ON ";
	
	If StrFind(QueryText, LinkSubstitutionText) = 0 Then // Checking that the request has not been finalized before
		
		TextOfTermsOfCommunication = New Array;
		TextOfTermsOfCommunication.Add(NameOfMainTable + ".Organization = VerificationStatuses.Organization");
		TextOfTermsOfCommunication.Add(NameOfMainTable + ".Ref = VerificationStatuses.Document");
		If GetFunctionalOption("UseFinancialDocumentVerification") Then
			For Each TypeToExclude In ExcludedTypesToCheck() Do
				TextOfTermsOfCommunication.Add("VALUETYPE(VerificationStatuses.Document) <> TYPE(Document." + Metadata.FindByType(TypeToExclude).Name + ")");
			EndDo;
		EndIf;
		LinkSubstitutionText = LinkSubstitutionText + StrConcat(TextOfTermsOfCommunication, Chars.LF + Chars.Tab + Chars.Tab + "And ");
			
		If StrFind(QueryText, "{LEFT JOIN") = 0 Then
			QueryText = StrReplace(QueryText, "AS " + NameOfMainTable,
				"AS " + NameOfMainTable + Chars.LF + Chars.Tab + "{" + LinkSubstitutionText + "}" + Chars.LF);
		Else
			QueryText = StrReplace(QueryText, "{LEFT JOIN", "{" + LinkSubstitutionText + Chars.LF + Chars.Tab + "LEFT JOIN");
		EndIf;
		
		TextOfVerificationStatusDefinition = "ISNULL(VerificationStatuses.CheckStatus, VALUE(Enum.StatusOfFinancialDocumentVerification.EmptyRef))";
		QueryText = StrReplace(QueryText, "&CheckStatus", TextOfVerificationStatusDefinition);
		
		If GetFunctionalOption("UseFinancialDocumentVerification") Then
			QueryText = StrReplace(QueryText, "&CheckingIndicator",
				TextOfVerificationStatusDefinition + " = VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)");
		Else
			// Removing the definition line of the "Verification indicator" field from the query:
			DefinitionOfIndicatorField = "AS CheckingIndicator";
			DefiningStatusField = "AS CheckStatus";
			PositionOfIndicatorField = StrFind(QueryText, DefinitionOfIndicatorField);
			PositionOfStatusField = StrFind(QueryText, DefiningStatusField);
			StartOfDeletion = PositionOfStatusField + StrLen(DefiningStatusField);
			If PositionOfIndicatorField > PositionOfStatusField Then
				TextToDelete = Mid(QueryText, StartOfDeletion, PositionOfIndicatorField - StartOfDeletion + StrLen(DefinitionOfIndicatorField));
				QueryText = StrReplace(QueryText, TextToDelete, "");
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventsSubscriptionsHandlers

// The procedure that is called when a subscription to the "Before recording" event is triggered (see subscribing to the "Document verifiingdocument" event).
// Checks whether the document can be recorded (refuses to record if the document has been checked and there is a hard
// lock on the object during verification).
//	
//	Parameters:
//		Source - DocumentObject - see subscribing to the event "Document verifiingdocument";
//		Cancel - Boolean - a parameter that determines whether an object will be written;
//		WriteMode - Boolean - document recording mode;
//		PostingMode - Boolean - the mode of the document.
//
Procedure BeforeWritingDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	BeforeChangingDocument(Source, Cancel);
	
EndProcedure

// Determines the need to refuse to change the object (the refusal will be triggered if the document has been checked and there is
// a ban on editing the checked ones).
//	
//	Parameters:
//		Source - DocumentObject - the document that is being modified;
//		Cancel - Boolean - a parameter that determines whether an object will be written;
//		Delete - Boolean - indicates that the document is being deleted.
//
Procedure BeforeChangingDocument(Source, Cancel, Delete = False) Export
	
	If Cancel Or Source.DataExchange.Load
		Or (Not GetFunctionalOption("UseFinancialDocumentVerification") And Not Delete)
		Or Not ThisTypeOfDocumentShouldBeChecked(TypeOf(Source.Ref))
		Or InfobaseUpdate.InfobaseUpdateInProgress() Then
		Return;
	EndIf;
	
	DoNotCheckDocument = Undefined;
	Source.AdditionalProperties.Property("DocumentVerification_Disable", DoNotCheckDocument);
	If DoNotCheckDocument = True Then
		Return;
	EndIf;
	
	CheckData = InformationRegisters.StatusOfDocumentVerification.GetDocumentVerificationData(Source.Ref);
	ChangingVerified = CheckData.NotificationCheck;
	
	Source.AdditionalProperties.Insert("DocumentVerification_VerificationData", CheckData);
	
	If CheckData.Verified And Not ChangingVerified Then
		Cancel = True;
		ErrorMessage = NStr("vi = 'Chứng từ %Document% đã được kiểm tra. Không thể thay đổi chứng từ đã kiểm tra.';
							|ru = 'Документ %Document% проверен. Нельзя изменять проверенные документы.';
							|en = 'Document %Document% is checked. Cannot change checked documents.'; fa = 'Document %Document% is checked. Cannot change checked documents.';
							|it = 'Documento %Document% verificato. Impossibile modificare i documenti verificati.';
							|pl = 'Dokument %Document% został sprawdzony. Nie można zmienić sprawdzonych dokumentów.';
							|tr = 'Belge %Document% kontrol edildi. Kontrol edilen belgeler değiştirilemez.'");
		ErrorMessage = StrReplace(ErrorMessage, "%Document%", Source.Ref);
		WriteLogEvent(NStr("vi = 'Chưa thực hiện giao dịch.';
							|ru = 'Операция не выполнена.';
							|en = 'Operation failed.'; fa = 'Operation failed.';
							|it = 'Operazione non è eseguita.';
							|pl = 'Operacja nie powiodła się.';
							|tr = 'İşlem tamamlanmadı.'", Common.DefaultLanguageCode()), EventLogLevel.Error, Source.Metadata(), Source.Ref, ErrorMessage);
		Common.MessageToUser(ErrorMessage, Source.Ref);
	ElsIf CheckData.Verified And Source.DeletionMark Then
		Cancel = True;
		ErrorMessage = NStr("vi = 'Chứng từ %Document% đã được kiểm tra. Trước khi đặt dấu xóa, cần hủy kiểm tra chứng từ.';
							|ru = 'Документ %Document% проверен. Перед пометкой на удаление, необходимо отменить проверку документа.';
							|en = 'Document %Document% is checked. Cancel the document check before marking it for deletion.  '; fa = 'Document %Document% is checked. Cancel the document check before marking it for deletion.  ';
							|it = 'Documento %Document% verificato. Prima di contrassegnare per l''eliminazione, è necessario annullare la verifica del documento.';
							|pl = 'Dokument %Document% został sprawdzony. Przed zaznaczeniem do usunięcia należy anulować sprawdzenie dokumentu.';
							|tr = 'Belge %Document% kontrol edildi. Silinmek üzere işaretlemeden önce belgenin işareti kaldırılmalı.'");
		ErrorMessage = StrReplace(ErrorMessage, "%Document%", Source.Ref);
		WriteLogEvent(NStr("vi = 'Chưa thực hiện giao dịch.';
							|ru = 'Операция не выполнена.';
							|en = 'Operation failed.'; fa = 'Operation failed.';
							|it = 'Operazione non è eseguita.';
							|pl = 'Operacja nie powiodła się.';
							|tr = 'İşlem tamamlanmadı.'", Common.DefaultLanguageCode()), EventLogLevel.Error, Source.Metadata(), Source.Ref, ErrorMessage);
		Common.MessageToUser(ErrorMessage, Source.Ref);
	ElsIf Delete And Not CheckData.CheckStatus.IsEmpty() Then
		// Clearing links for unverified documents marked for deletion:
		InformationRegisters.StatusOfDocumentVerification.SetDocumentVerificationStatusWhenRecording(Source.Ref, Source.Date, New Array, New Structure);
	EndIf;
	
EndProcedure

// The procedure that is called when a subscription to the event "Event processing" is triggered (see subscribing to the event "Document verificationprocessing of a document").
// Sets THE Status of document verification to "Unchecked".
//	
//	Parameters:
//		Source - DocumentObject - see the subscription to the event "Document Verificationprocessing of a document";
//		Cancel - Boolean - a parameter that determines whether an object will be held;
//		PostingMode - Boolean - the mode of the document.
//
Procedure WhenCarryingOutDocument(Source, Cancel, PostingMode) Export
	
	WhenChangingDocument(Source, Cancel);
	
EndProcedure

// The procedure that is called when a subscription to the event "Event Deletion processing" is triggered (see subscribing to the event "Document verifiingdocumentation processing").
// Sets THE Status of document verification to "Unchecked".
//	
//	Parameters:
//		Source - DocumentObject - see the subscription to the event "Document Verifiingprocessing of document deletions";
//		Cancel - Boolean - a parameter that determines whether the object will be decomposed;
//
Procedure WhenCancelingDocument(Source, Cancel) Export
	
	WhenChangingDocument(Source, Cancel);
	
EndProcedure

// Changes the document verification status to "Unchecked", provided that this type of document is checked and
// the document verification FO is enabled.
//	
//	Parameters:
//		Source - DocumentObject - the document that is being modified;
//		Cancel - Boolean - a parameter that determines whether the object will be held (unrolled).
//
Procedure WhenChangingDocument(Source, Cancel) Export
	
	If Source.DataExchange.Load Or Cancel
		Or CommonClientServer.StructureProperty(Source.AdditionalProperties, "DocumentVerification_Disable", False)
		Or Not GetFunctionalOption("UseFinancialDocumentVerification")
		Or Not ThisTypeOfDocumentShouldBeChecked(TypeOf(Source.Ref))
		Or InfobaseUpdate.InfobaseUpdateInProgress() Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);

	If DocumentsPosting.DocumentProperties(Source).WriteMode = DocumentWriteMode.UndoPosting Then
		
		InformationRegisters.StatusOfDocumentVerification.SetDocumentVerificationStatusWhenRecording(Source.Ref, Source.Date, New Array, New Structure);
		Return;
		
	EndIf;

	If TypeOf(Source.Ref) = Type("DocumentRef.OtherGoodsRecordingAsReceived") Then
		AdditionalVerificationParameters_ = New Structure;
		AdditionalVerificationParameters_.Insert("BusinessOperation", Source.BusinessOperation);
	Else
		AdditionalVerificationParameters_ = Undefined;
	EndIf;
	
	If Source.AdditionalProperties.Property("DocumentVerification_VerificationData") Then
		CheckData = Source.AdditionalProperties.DocumentVerification_VerificationData;
	Else
		CheckData = InformationRegisters.StatusOfDocumentVerification.GetDocumentVerificationData(Source.Ref);
	EndIf;
	
	If CheckData.NotificationCheck And CheckData.Verified Or Not CheckData.Verified Then
		
		CompanyArray = ArrayOfDocumentOrganizations(Source);
		InformationRegisters.StatusOfDocumentVerification.SetDocumentVerificationStatusWhenRecording(
			Source.Ref, Source.Date, CompanyArray, CheckData, AdditionalVerificationParameters_);
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Other

//	Updates the form depending on the document verification data.
//
//	Parameters:
//		Form - ClientApplicationForm - The Form that needs to be updated:
//			* Object - FormDataCollection - Object:
//				** Ref - DocumentRef -
//		CheckData - See InformationRegisters.StatusOfDocumentVerification.InitializeDocumentVerificationData.
//
Procedure UpdateDocumentVerificationDataOnForm(Form, CheckData = Undefined) Export
	
	If CheckData = Undefined Then
		CheckData = InformationRegisters.StatusOfDocumentVerification.GetDocumentVerificationData(Form.Object.Ref);
	EndIf;
	
	Form.DocumentVerification_DocumentVerified = CheckData.Verified;

	DefinePropertiesOfDataValidationButton(Form, CheckData);
	
	If CheckData.NotificationCheck Then
		Form.DocumentVerification_RecordConfirmation = True;
	Else
		FormBlocking(Form, CheckData.Verified);
	EndIf;
	
EndProcedure

//	Determines whether a document of this type is being checked,
//	is determined based on the presence of this document in the dimension of the register of "Status checks of documents").
//
//	Parameters:
//		DocumentType - Type - the type being checked.
//
//	Returns:
//		Boolean - True if the document should be checked.
//
Function ThisTypeOfDocumentShouldBeChecked(DocumentType) Export
	
	Return TypesOfDocumentsToBeChecked().Find(DocumentType) <> Undefined;
	
EndFunction

// Returns an array of document types that are involved in the verification.
//
// Returns:
//	Array of Type - Types of values to be checked
Function TypesOfDocumentsToBeChecked() Export
	
	ListOfTypesToBeChecked = Metadata.InformationRegisters["StatusOfDocumentVerification"].Dimensions.Document.Type.Types();
	ListOfTypesToBeChecked = CommonClientServer.ArraysDifference(ListOfTypesToBeChecked, ExcludedTypesToCheck());
	Return ListOfTypesToBeChecked;
	
EndFunction

// Receives documents that should not be counted as verifiable. According to them, data can be stored in the inf. the database, but
// they are no longer taken into account.
//
// Returns:
//	Array of Type - Value types that should not be checked.
//
Function ExcludedTypesToCheck() Export
	
	Return InformationRegisters.SettingsOfDocumentCheckExceptions.ExcludedTypesOfDocumentsForVerification();
	
EndFunction

#EndRegion

#Region RedefiningQueryTexts

// Returns an enumeration of the types of unverifiable documents as a string
//
//	Parameters:
// 		OnlyWithoutPossibilityOfChange - Boolean - provided that it is necessary to return only those documents
// 			for which the settings are not set manually by the user (it is necessary when the result of the function is used in a query
// 			with a separate receipt of data from the exception table). The default value is False.
//		Separator - String - the separator that will be used to separate the types.
//			Default value: "," + Characters.PS + Symbols.Tab + Symbols.Tab.
//			
//	Returns:
//		String - Type string(First document)<Separator >...<Delimiter>Type(Last document).
//
Function TypesOfUnverifiableDocumentsByString(OnlyWithoutPossibilityOfChange = False, Separator = Undefined) Export
	
	ArrayOfStringsOfExcludedTypes = New Array;
	
	ExcludedDocuments = InformationRegisters.SettingsOfDocumentCheckExceptions.ExcludedDocumentsForVerification(OnlyWithoutPossibilityOfChange);
	For Each NameOfExcludedDocument In ExcludedDocuments Do
		ArrayOfStringsOfExcludedTypes.Add("TYPE(Document." + NameOfExcludedDocument + ")");
	EndDo;
	
	Separator = ?(Separator = Undefined, "," + Chars.LF + Chars.Tab + Chars.Tab, Separator);
	
	ReturnString = StrConcat(ArrayOfStringsOfExcludedTypes, Separator);
	
	Return ReturnString;
	
EndFunction

// Overrides access to the temporary table "Document verifiing" to access the registers of verification information
// (Document verification statuses and settings for Document verification exceptions) with selection only for those documents that should
// be checked (based on predefined types of unverifiable documents and documents added to exceptions by the user).
//
//	Parameters:
//		QueryText - String - the text of the query that contains a call to the table that needs to be redefined.
//			Below are the mandatory conditions imposed on the request text for correct redefinition.
//			1) In the text of the query there should be only one reference to the table "Document verifiing", otherwise the text must be divided.
//			2) in the text of the request, all measurements of the register of information Status of document verification should be listed, access to measurements should be on the right, for example:
//					, "And document verifiing is undefined.Document = Alias of the Link table.The name of the communication document".
//		PathToRecorder - String - the text of the appeal to the registrar of the form "pseudonymtablecommunication.The "Link DocumentName" for communicating with exception settings.
//
Procedure OverrideVerificationStatusInRequestTextTakingIntoAccountExceptions(QueryText, PathToRecorder) Export
	
	//We are looking for a reference to the table being redefined:
	SearchString = "DocumentVerificationOverridable AS DocumentVerificationOverridable";
	PositionOfTableDefinitionInQuery = StrFind(QueryText, SearchString);
	If PositionOfTableDefinitionInQuery = 0 Then
		// There are no references to document verification Statuses in the request text. We are not redefining the request text.
		Return;
	EndIf;
	
	SubstitutionPosition = StrFind(Left(QueryText, PositionOfTableDefinitionInQuery), Chars.LF, SearchDirection.FromEnd);
	
	SubstitutionText = "
	|		LEFT JOIN InformationRegister.SettingsOfDocumentCheckExceptions AS ExceptionsInternal
	|		ON VALUETYPE(&OverridingLogger) = VALUETYPE(ExceptionsInternal.DocumentKind.EmptyRefValue)
	|			AND NOT ExceptionsInternal.IsChecked";
	SubstitutionText = StrReplace(SubstitutionText, "&OverridingLogger", PathToRecorder);
	
	//We divide it into halves: before the substitution of the connection with the exception register and after.
	PartBefore = Left(QueryText, SubstitutionPosition-1);
	PartAfter = Right(QueryText, StrLen(QueryText) - SubstitutionPosition + 1);
	
	SearchString = "DocumentVerificationOverridable.Document";
	SubstitutionPosition = StrFind(PartAfter, SearchString); //Looking for a position. where the document is accessed
	SubstitutionPosition = StrFind(PartAfter, Chars.LF,, SubstitutionPosition);
	
	TextOfConditionSubstitution = "
	|		AND ExceptionsInternal.DocumentKind IS NULL AND NOT VALUETYPE(DocumentVerificationOverridable.Document) IN (&TypesOfAttributesThatCannotBeVerified)";
	TextOfConditionSubstitution = StrReplace(TextOfConditionSubstitution, "&TypesOfAttributesThatCannotBeVerified", TypesOfUnverifiableDocumentsByString(True));
	
	PartAfter = Left(PartAfter, SubstitutionPosition-1) + TextOfConditionSubstitution + Right(PartAfter, StrLen(PartAfter) - SubstitutionPosition + 1);
	
	QueryText = PartBefore + SubstitutionText + PartAfter;
	
	QueryText = StrReplace(QueryText, "DocumentVerificationOverridable AS", "InformationRegister.StatusOfDocumentVerification AS");
	
EndProcedure

// Overrides access to the temporary table "Document verifiing" to access the registers of verification information
// (Status of verification of documents and settings of exclusion of verification of documents) with selection only for those documents that should
// be checked (based on predefined types of unverifiable documents and documents added to exceptions by the user),
// as well as for those documents for which there is a condition for blocking verified ones (based on the general FO and documents added to exceptions by the user).
//
//	Parameters:
//		QueryText - String - the text of the query that contains a call to the table that needs to be redefined.
//			Below are the mandatory conditions imposed on the request text for correct redefinition.
//			1) In the text of the query there should be only one reference to the table "Document verifiing", otherwise the text must be divided.
//			2) in the text of the request, all measurements of the register of information Status of document verification should be listed, access to measurements should be on the right, for example:
//					, "And document verifiing is undefined.Document = Alias of the Link table.The name of the communication document".
//		PathToRecorder - String - the text of the appeal to the registrar of the form "pseudonymtablecommunication.The "Link DocumentName" for communicating with exception settings.
//
Procedure OverrideVerificationStatusesInRequestTextTakingIntoAccountLocks(QueryText, PathToRecorder) Export
	
	//We are looking for a reference to the table being redefined:
	SearchString = "DocumentVerificationOverridable AS DocumentVerificationOverridable";
	PositionOfTableDefinitionInQuery = StrFind(QueryText, SearchString);
	If PositionOfTableDefinitionInQuery = 0 Then
		// There are no references to document verification Statuses in the request text. We are not redefining the request text.
		Return;
	EndIf;
	
	SubstitutionPosition = StrFind(Left(QueryText, PositionOfTableDefinitionInQuery), Chars.LF, SearchDirection.FromEnd);
	
	SubstitutionText = "
	|		LEFT JOIN Constants AS Constants
	|			ON Constants.AllowModificationOfAuditedFinancialDocuments
	|	LEFT JOIN InformationRegister.SettingsOfDocumentCheckExceptions AS ExceptionsInternal
	|			ON VALUETYPE(&OverridingLogger) = VALUETYPE(ExceptionsInternal.DocumentKind.EmptyRefValue)
	|				AND ExceptionsInternal.IsChecked";
	SubstitutionText = StrReplace(SubstitutionText, "&OverridingLogger", PathToRecorder);
	
	//We divide it into halves: before the substitution of the connection with the exception register and after.
	PartBefore = Left(QueryText, SubstitutionPosition-1);
	PartAfter = Right(QueryText, StrLen(QueryText) - SubstitutionPosition + 1);
	
	SearchString = "DocumentVerificationOverridable.Document";
	SubstitutionPosition = StrFind(PartAfter, SearchString); //Looking for a position. where the document is accessed
	SubstitutionPosition = StrFind(PartAfter, Chars.LF,, SubstitutionPosition);
	
	TextOfConditionSubstitution = "
	|		AND NOT ExceptionsInternal.DocumentKind IS NULL AND NOT VALUETYPE(DocumentVerificationOverridable.Document) IN (&TypesOfAttributesThatCannotBeVerified)
	|		AND NOT ISNULL(ExceptionsInternal.NotificationCheck, ISNULL(Constants.AllowModificationOfAuditedFinancialDocuments, FALSE))";
	TextOfConditionSubstitution = StrReplace(TextOfConditionSubstitution, "&TypesOfAttributesThatCannotBeVerified", TypesOfUnverifiableDocumentsByString(True));
	
	PartAfter = Left(PartAfter, SubstitutionPosition-1) + TextOfConditionSubstitution + Right(PartAfter, StrLen(PartAfter) - SubstitutionPosition + 1);
	
	QueryText = PartBefore + SubstitutionText + PartAfter;
	
	QueryText = StrReplace(QueryText, "DocumentVerificationOverridable AS", "InformationRegister.StatusOfDocumentVerification AS");
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure AddVerificationDetailsToForm(Form)
	
	AttributesToAddArray = New Array;
	
	AttributesToAddArray.Add(New FormAttribute("DocumentVerification_DocumentVerified", New TypeDescription("Boolean")));
	AttributesToAddArray.Add(New FormAttribute("DocumentVerification_FormBlocking", New TypeDescription("Boolean")));
	AttributesToAddArray.Add(New FormAttribute("DocumentVerification_RecordConfirmation", New TypeDescription("Boolean")));
	
	Form.ChangeAttributes(AttributesToAddArray);
	
EndProcedure

Function VerificationCommandIsAddedToDocumentForm(Form)
	
	// We control the check only when the corresponding functional option is enabled.
	If Not GetFunctionalOption("UseFinancialDocumentVerification") Then
		Return False;
	EndIf;
	
	// We manage the verification only when there is a "Facility" prop.
	If Not TMCommonUseClientServer.HasObjectAttribute(Form, "Object") Then
		Return False;
	EndIf;
	
	// We manage verification only when the form is a document form and it is possible to set
	// verification statuses for this document.
	If Not FormIsFormOfDocumentThatIsBeingVerified(Form) Then
		Return False;
	EndIf;
	
	// We manage the verification only when there are entries for the document in the RS "Document verification statuses".
	If ValueIsFilled(Form.Object.Ref)
		And Not ThereIsEntryInCheckStatusRegister(Form.Object.Ref) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function FormIsFormOfDocumentThatIsBeingVerified(Form)
	
	CheckResult = False;
	FullFormName = Form.FormName;
	
	FormNameArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullFormName, ".");
	
	If FormNameArray1.Get(0) = "Document" Then
		FormDocumentType = Type("DocumentRef."+FormNameArray1.Get(1));
		
		ThisIsFormOfDocument = False;
		FormAttributes = Form.GetAttributes();
		
		For Each FormAttribute In FormAttributes Do
			If FormAttribute.Name = "Object"
				And TypeOf(Form.Object.Ref) = Type("DocumentRef."+FormNameArray1.Get(1)) Then
					ThisIsFormOfDocument = True;
					Break;
			EndIf;
		EndDo;
		
		If ThisTypeOfDocumentShouldBeChecked(FormDocumentType) And ThisIsFormOfDocument Then
			CheckResult = True;
		EndIf;
		
	EndIf;
	
	Return CheckResult;
	
EndFunction

Function AddValidationCommandToForm(Form)
	
	TeamPlacement = DeterminePlacementOfValidationCommand(Form);
	
	If TeamPlacement.FormGroup = Undefined Then
		Return Undefined;
	EndIf;
	
	CommandName = "DocumentVerification_CommandToChangeDocumentVerificationStatus";
	
	FormCommand = Form.Commands.Add(CommandName);
	FormCommand.Action = "Attachable_ExecuteOverridableCommand"; // universal handler
	FormCommand.Title = NStr("vi = 'Đã kiểm tra';
							|ru = 'Проверено';
							|en = 'Checked'; fa = 'بررسی‌شده';
							|it = 'Verificato';
							|pl = 'Checked';
							|tr = 'Kontrol edildi'");
	FormCommand.ModifiesStoredData = False;
	
	FormCommandElement = Form.Items.Insert(CommandName, Type("FormButton"), TeamPlacement.FormGroup, TeamPlacement.Item);
	FormCommandElement.Type = FormButtonType.CommandBarButton;
	FormCommandElement.CommandName = CommandName;
	
	Return FormCommand;
	
EndFunction

Function DeterminePlacementOfValidationCommand(Form)
	
	TeamPlacement = New Structure("FormGroup, Item");
	
	LocalBillingEntriesButton =
		Form.Items.Find("FormProcessingReflectionOfDocumentsInReglAccountingPostingReglAccounting");
	InternationalAccountingEntriesButton =
		Form.Items.Find("FormProcessingReflectionOfDocumentsInInternationalAccountingEntriesOfDocumentOfOperationalAccounting");
	
	If LocalBillingEntriesButton <> Undefined Then
		TeamPlacement.FormGroup = LocalBillingEntriesButton.Parent;
	ElsIf InternationalAccountingEntriesButton <> Undefined Then
		TeamPlacement.FormGroup = InternationalAccountingEntriesButton.Parent;
	Else
		For Each FormItem In Form.Items Do
			If TypeOf(FormItem) <> Type("FormButton")
				Or StrFind(Upper(FormItem.Name), "HELP") = 0
				Or FormItem.Parent = Undefined Then
				Continue;
			EndIf;
			TeamPlacement.FormGroup = FormItem.Parent;
		EndDo;
	EndIf;
	
	If TeamPlacement.FormGroup = Undefined Then
		Return TeamPlacement;
	EndIf;
	
	ButtonIndex = 0;
	ChildItems = TeamPlacement.FormGroup.ChildItems; // FormItems - Collection Of Subordinate Elements
	
	If LocalBillingEntriesButton <> Undefined Then
		ButtonIndex = Max(ChildItems.IndexOf(LocalBillingEntriesButton), ButtonIndex);
	EndIf;
	
	If InternationalAccountingEntriesButton <> Undefined Then
		ButtonIndex = Max(ChildItems.IndexOf(InternationalAccountingEntriesButton), ButtonIndex);
	EndIf;
	
	If ButtonIndex > 0 Then
		TeamPlacement.Item = ChildItems.Get(ButtonIndex + 1);
	EndIf;
	
	Return TeamPlacement;
	
EndFunction

// Define the properties of the data validation button.
// 
// Parameters:
//  Form - ClientApplicationForm - Form:
// 		* Object - FormDataCollection -:
// 			** Ref - DocumentRef -
//  CheckData - See InformationRegisters.StatusOfDocumentVerification.InitializeDocumentVerificationData
Procedure DefinePropertiesOfDataValidationButton(Form, CheckData)
	
	VerificationTeam = Form.Commands.Find("DocumentVerification_CommandToChangeDocumentVerificationStatus");
	If VerificationTeam = Undefined Then
		Return;
	EndIf;

	ButtonPicture = PictureLib.StatusDocumentIsChecked;
	
	ThereIsRightToChangeVerificationStatus = AccessRight("Update", Metadata.InformationRegisters.StatusOfDocumentVerification);
	
	If CheckData.CheckStatus.IsEmpty() And Form.Object.Ref.IsEmpty() Then
		ButtonHint = NStr("vi = 'Chỉ có thể kiểm tra chứng từ sau khi ghi lại chứng từ';
							|ru = 'Проверка документа возможна только после записи документа';
							|en = 'Document check is available only after you post the document'; fa = 'Document check is available only after you post the document';
							|it = 'La verifica del documento è possibile solo dopo il suo salvataggio';
							|pl = 'Sprawdzenie dokumentu jest możliwe tylko po zapisie dokumentu';
							|tr = 'Belgeyi kontrol etmek ancak belge kaydından sonra mümkündür'");
	Else
		If ThereIsRightToChangeVerificationStatus Then
			ButtonHint = NStr("vi = 'Thay đổi trạng thái kiểm tra chứng từ.';
								|ru = 'Изменение статуса проверки документа.';
								|en = 'Change document check status.'; fa = 'Change document check status.';
								|it = 'Modifica dello stato di verifica del documento.';
								|pl = 'Zmiana statusu sprawdzenia dokumentu.';
								|tr = 'Belge doğrulama durumunun değişimi.'");
		Else
			If CheckData.Verified Then
				If CheckData.NotificationCheck Then
					Comment = NStr("vi = 'không nên thay đổi.';
									|ru = 'изменения не рекомендуются.';
									|en = 'changes are not recommended.'; fa = 'changes are not recommended.';
									|it = 'non è consigliata la modifica.';
									|pl = 'zmiany nie są zalecane.';
									|tr = 'düzenleme önerilmiyor.'");
				Else
					Comment = NStr("vi = 'không thể thay đổi.';
									|ru = 'изменение невозможно.';
									|en = 'cannot change.'; fa = 'cannot change.';
									|it = 'impossibile modificare.';
									|pl = 'zmiana jest niemożliwa.';
									|tr = 'düzenleme mümkün değildir.'");
				EndIf;
				ButtonHint = NStr("vi = 'Đã kiểm tra chứng từ';
									|ru = 'Документ проверен';
									|en = 'Document checked'; fa = 'Document checked';
									|it = 'Documento verificato';
									|pl = 'Dokument został sprawdzony';
									|tr = 'Belge kontrol edildi'") + ", " + Comment;
				ButtonPicture = PictureLib.ExcludeFromPostingGenerationSetting;
			Else
				ButtonHint = NStr("vi = 'Chưa kiểm tra chứng từ.';
									|ru = 'Документ не проверен.';
									|en = 'The document is not checked.'; fa = 'The document is not checked.';
									|it = 'Documento non verificato.';
									|pl = 'Dokument nie jest sprawdzony.';
									|tr = 'Belge kontrol edilmedi'");
				ButtonPicture = PictureLib.IncludeInPostingGenerationSetting;
			EndIf;
		EndIf;		
	EndIf;
	
	If CheckData.Verified Then
		ExplanationOfVerification = Chars.LF + NStr("vi = 'Người kiểm tra: %WhoChecked%, Ngày: %CheckDate%';
													|ru = 'Проверил: %WhoChecked%, Дата: %CheckDate%';
													|en = 'Checked by: %WhoChecked%, Date: %CheckDate%'; fa = 'Checked by: %WhoChecked%, Date: %CheckDate%';
													|it = 'Verificato: %WhoChecked%, data: %CheckDate%';
													|pl = 'Sprawdził: %WhoChecked%, Data: %CheckDate%';
													|tr = 'Kontrol etti: %WhoChecked%, Tarih: %CheckDate%'");
		ExplanationOfVerification = StrReplace(ExplanationOfVerification, "%WhoChecked%", CheckData.WhoChecked);
		ExplanationOfVerification = StrReplace(ExplanationOfVerification, "%CheckDate%", CheckData.CheckDate);
		ButtonHint = ButtonHint + ExplanationOfVerification;
	EndIf;
	
	VerificationTeam.ToolTip = ButtonHint;
	VerificationTeam.Picture = ButtonPicture;
	
	FormCommandElement = Form.Items.Find("DocumentVerification_CommandToChangeDocumentVerificationStatus");
	If Not FormCommandElement = Undefined Then
		FormCommandElement.Check = Form.DocumentVerification_DocumentVerified;
	EndIf;
	
EndProcedure

Procedure FormBlocking(Form, DocumentVerified)
	
	If DocumentVerified Then
		// The form must be blocked because the document has been verified and it is forbidden to change the verified documents.
		
		If Form.ReadOnly Then
			// The form is already blocked, but not as a result of checking the document, we will make the appropriate note.
			Form.DocumentVerification_FormBlocking = False;
		Else
			// The form is not blocked, we will block it and make the appropriate note.
			Form.ReadOnly = True;
			Form.DocumentVerification_FormBlocking = True;
		EndIf;
		
	Else
		// The form does not need to be blocked, since the document has not been verified or the modification of the verified documents is allowed.
		
		If Form.DocumentVerification_FormBlocking Then
			// The form was previously blocked as a result of the previous verification of documents - we will unlock the form and remove the mark about blocking.
			Form.ReadOnly = False;
			Form.DocumentVerification_FormBlocking = False;
		EndIf;
		
	EndIf;
	
EndProcedure

Function ChangeVerificationImageOnListForm(Form, AdditionalParameters)
	
	// We control the check only when the corresponding functional option is enabled.
	If Not GetFunctionalOption("UseFinancialDocumentVerification") Then
		Return False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.InformationRegisters.StatusOfDocumentVerification) Then
		Return False;
	EndIf;
	
	// We control the verification only when the property "Placementdannyhproverkiregl" is set in the additional parameters:
	//	this means that the necessary fields have already been added to the corresponding list, and the "Indicator Verification" element has been added to the form.
	If AdditionalParameters = Undefined Or Not AdditionalParameters.Property("LocationOfLocalValidationData") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Procedure SetPropertiesOfVerificationImageOnListForm(Form, AdditionalParameters)
	
	VerificationGroupElement = AdditionalParameters.LocationOfLocalValidationData; // FormGroup -
	For Each CheckItems In VerificationGroupElement.ChildItems Do
		If Not StrFind(CheckItems.Name, "CheckingIndicator", SearchDirection.FromEnd) = 0 Then
			CheckItems.ValuesPicture = PictureLib.StatusDocumentIsChecked;
		EndIf
	EndDo;
	
EndProcedure

// Gets an array of details with the "Organization" type from the passed object (link).
//
//	Parameters:
//		DocumentSource - DocumentRef, DocumentObject - the object whose Attributes need to be analyzed for compliance with the "Organization" type.
//			If an object is passed, the Attributes are read directly from it.
//			If a link is passed, a request is made to the database data.
//		TakeIntoAccountManagementOrganization - Boolean - a flag that determines whether there should be a management organization among the returned array.
// 			The default value is true.
//
//	Returns:
//	 Array of CatalogRef.Companies - array of found Organizations in the document. 
//	            If no props with the value type "Organization" are found in the document, an array with a link to an empty organization will be returned.
//
Function ArrayOfDocumentOrganizations(DocumentSource, TakeIntoAccountManagementOrganization = False) Export
	
	CompanyArray = New Array;
	IsObject = Not Common.IsReference(TypeOf(DocumentSource));
	
	MetadataOfDocument = DocumentSource.Metadata();
	
	NamesOfBusinessDetails = NamesOfBusinessDetails(MetadataOfDocument);
	NamesOfDetailsOfOrganizationsTabularParts = NamesOfDetailsOfOrganizationsTabularParts(MetadataOfDocument);
	
	If Catalogs.Companies.MultipleOrganizationsAreUsed() Then
		
		If IsObject Then
			
			For Each AttributeName In NamesOfBusinessDetails Do
					
				CurrentCompany = DocumentSource[AttributeName];
				If ValueIsFilled(CurrentCompany) 
					And TypeOf(CurrentCompany) = Type("CatalogRef.Companies")
					And CompanyArray.Find(CurrentCompany) = Undefined Then
					
					If AttributeName = "Organization" Then
						CompanyArray.Insert(0, CurrentCompany);
					Else
						CompanyArray.Add(CurrentCompany);
					EndIf;
					
				EndIf;
			EndDo;
			
			For Each KeyAndValue In NamesOfDetailsOfOrganizationsTabularParts Do
				
				TabularSectionName = KeyAndValue.Key;
				NamesOfBusinessDetails = KeyAndValue.Value;
				
				For Each LineOfATabularSection In DocumentSource[TabularSectionName] Do
					
					For Each AttributeName In NamesOfBusinessDetails Do
							
						CurrentCompany = LineOfATabularSection[AttributeName];
						If ValueIsFilled(CurrentCompany)
							And TypeOf(CurrentCompany) = Type("CatalogRef.Companies")
							And CompanyArray.Find(CurrentCompany) = Undefined Then
							CompanyArray.Add(CurrentCompany);
						EndIf;
						
					EndDo;
					
				EndDo;
				
			EndDo;
			
			If CompanyArray.Count() = 0 Then
				CompanyArray.Add(Catalogs.Companies.EmptyRef());
			EndIf;
			
		Else
			
			RequestTemplateForProps =
			"SELECT
			|	&Attribute AS Organization
			|FROM
			|	&FullObjectName AS TableName
			|WHERE
			|	TableName.Ref = &Ref
			|	AND &AttributeTypeCondition";
			
			QueriesTexts = New Array;
			
			For Each AttributeName In NamesOfBusinessDetails Do
				
				QueryText = StrReplace(RequestTemplateForProps, "&FullObjectName", MetadataOfDocument.FullName());
				QueryText = StrReplace(QueryText, "&AttributeTypeCondition", "VALUETYPE(TableName.&Attribute) = TYPE(Catalog.Companies)");
				QueryText = StrReplace(QueryText, "&Attribute", AttributeName);
				
				QueriesTexts.Add(QueryText);
				
			EndDo;
			
			For Each KeyAndValue In NamesOfDetailsOfOrganizationsTabularParts Do
				TabularSectionName = KeyAndValue.Key;
				NamesOfBusinessDetails = KeyAndValue.Value;
				For Each AttributeName In NamesOfBusinessDetails Do
					
					QueryText = StrReplace(RequestTemplateForProps, "&FullObjectName", MetadataOfDocument.FullName() + "." + TabularSectionName);
					QueryText = StrReplace(QueryText, "&AttributeTypeCondition", "VALUETYPE(TableName.&Attribute) = TYPE(Catalog.Companies)");
					QueryText = StrReplace(QueryText, "&Attribute", AttributeName);
					
					QueriesTexts.Add(QueryText);
					
				EndDo;
			EndDo;
			
			Query = New Query;
			Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin(True));
			Query.SetParameter("Ref", DocumentSource);
			
			CompanyArray = Query.Execute().Unload().UnloadColumn("Organization");
			
		EndIf;
		
		DocumentVerificationLocalization.AddArrayOfOrganizationsToDocument(CompanyArray, DocumentSource, TakeIntoAccountManagementOrganization);
		
	Else
		
		If IsObject And TMCommonUseClientServer.HasObjectAttribute(DocumentSource, "Organization") Then
			CompanyArray.Add(DocumentSource["Organization"]);
		ElsIf Not IsObject And Common.HasObjectAttribute("Organization", MetadataOfDocument) Then
			CompanyArray.Add(Common.ObjectAttributeValue(DocumentSource, "Organization"));
		Else
			CompanyArray.Add(Catalogs.Companies.EmptyRef());
		EndIf;
		
	EndIf;
	
	If Not TakeIntoAccountManagementOrganization Then
		IndexOfManagementOrganizationInArray = CompanyArray.Find(Catalogs.Companies.ManagementCompany);
		If Not IndexOfManagementOrganizationInArray = Undefined Then
			CompanyArray.Delete(IndexOfManagementOrganizationInArray);
		EndIf;
	EndIf;
	
	Return CompanyArray;
	
EndFunction

Function NamesOfBusinessDetails(MetadataObject)
	
	Result = New Array;
	
	TypeOrganization = Type("CatalogRef.Companies");
	For Each Attribute In MetadataObject.Attributes Do
		If Attribute.Type.ContainsType(TypeOrganization) Then
			Result.Add(Attribute.Name);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function NamesOfDetailsOfOrganizationsTabularParts(MetadataObject)
	
	Result = New Structure;
	
	TypeOrganization = Type("CatalogRef.Companies");
	For Each TabularSection In MetadataObject.TabularSections Do
		
		AttributesArray = New Array;
		For Each Attribute In TabularSection.Attributes Do
			If Attribute.Type.ContainsType(TypeOrganization) Then
				AttributesArray.Add(Attribute.Name);
			EndIf;
		EndDo;
		
		If AttributesArray.Count() > 0 Then
			Result.Insert(TabularSection.Name, AttributesArray);
		EndIf;
		
	EndDo;
		
	Return Result;
	
EndFunction 

Function ThereIsEntryInCheckStatusRegister(Ref)
	
	SetOfPCRecords = InformationRegisters.StatusOfDocumentVerification.CreateRecordSet();
	SetOfPCRecords.Filter.Document.Set(Ref);
	SetOfPCRecords.Read();
	
	Return SetOfPCRecords.Count() > 0;
	
EndFunction

#EndRegion
