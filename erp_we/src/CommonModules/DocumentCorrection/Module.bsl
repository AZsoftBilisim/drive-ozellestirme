#Region Public

// Adds the Fix command to the list of creation commands based on.
// 
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 	MetadataObject - MetadataObjectDocument - The metadata object to add commands to.
// 
// Returns:
//  - Undefined - if there is no access right to correct or edit the document, as well as if the document does not contain the Correction Attribute
//  - ValueTableRow - information about the Command properties
//
Function AddCorrectionCommand(GenerationCommands, MetadataObject) Export
	
	CreateFixCommand = Undefined;
	
	If GetFunctionalOption("UseDocumentCorrection")
	   And AccessRight("Edit", MetadataObject)
	   And Common.HasObjectAttribute("Patch", MetadataObject) 
	   And Not Users.IsExternalUserSession() Then
		
		CreateFixCommand = GenerationCommands.Add();
		CreateFixCommand.Manager = MetadataObject.FullName();
		CreateFixCommand.Presentation = NStr("vi = 'Chỉnh sửa';
											|ru = 'Исправление';
											|en = 'Correction'; fa = 'اصلاح';
											|it = 'Исправление';
											|pl = 'Correction';
											|tr = 'Düzeltme'");
		CreateFixCommand.WriteMode = "Post";
		CreateFixCommand.Order = 1000;
		
	EndIf;
	
	Return CreateFixCommand;
	
EndFunction

// Adds the Reverse command to the list of creation commands based on.
// 
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 	MetadataObject - MetadataObjectDocument - The metadata object to add commands to.
// 
// Returns:
//  - Undefined - if there is no right of access to correct or edit the document
//  - ValueTableRow - information about the Command properties
//
Function AddReverseCommand(GenerationCommands, MetadataObject) Export
	
	CreateStornoCommand = Undefined;
	
	If GetFunctionalOption("UseDocumentCorrection")
	   And AccessRight("Edit", MetadataObject)
	   And Not Users.IsExternalUserSession() Then
		
		CreateStornoCommand = GenerationCommands.Add();
		CreateStornoCommand.Manager = Metadata.Documents.ReversingEntry.FullName();
		CreateStornoCommand.Presentation = NStr("vi = 'Đảo ngược';
												|ru = 'Сторно';
												|en = 'Storno'; fa = 'استورنو';
												|it = 'Сторно';
												|pl = 'Storno';
												|tr = 'İptal'");
		CreateStornoCommand.WriteMode = "Post";
		CreateStornoCommand.Order = 1001;
		
	EndIf;
	
	Return CreateStornoCommand;
	
EndFunction

// Fills in the correction document based on the corrected document.
// 
// Parameters:
// 	DocumentObject - DocumentObject, DocumentObject.InventoryTransfer - Correction document
// 	CorrectedDocument - DocumentRef, DocumentRef.InventoryTransfer - Document being corrected
//
Procedure FillInCorrection(DocumentObject, CorrectedDocument) Export
	
	If Not RegistrationStornoIsAllowed(CorrectedDocument) Then
		Raise NStr("ru = 'Регистрация исправления недоступна';
					|vi = 'Cannot register the correction';
					|en = 'Cannot register the correction'; fa = 'Cannot register the correction';
					|it = 'Cannot register the correction';
					|pl = 'Cannot register the correction';
					|tr = 'Düzeltme kaydı yapılamaz'");
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref AS Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.ReversedDocument = &ReversedDocument
	|	AND DocumentsRegistry.Posted";
	Query.SetParameter("RefType", Common.MetadataObjectID(DocumentObject.Metadata().FullName()));
	Query.SetParameter("ReversedDocument", CorrectedDocument);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		If TypeOf(Selection.Ref) = Type("DocumentRef.ReversingEntry") Then
			MessageText = NStr("vi = 'Trên cơ sở có nhập chứng từ ""Đảo ngược"".
			                            |Không thể chỉnh sửa chứng từ.';
			                            |ru = 'На основании введен документ ""Сторно"".
			                            |Исправление документа невозможно.';
			                            |en = 'The ""Storno"" document is entered using base document.
			                            |Document correction is not available.'; fa = 'The ""Storno"" document is entered using base document.
			                            |Document correction is not available.';
			                            |it = 'Sulla base di questo documento è stato inserito il documento ""Storno"". 
			                            |Impossibile correggere il documento.';
			                            |pl = 'Na podstawie wprowadzono dokument ""Storno"".
			                            |Korekta dokumentu jest niemożliwa.';
			                            |tr = 'Esasında ""İptal"" belgesi girildi.
			                            |Belgeyi düzeltmek mümkün değil.'");
		Else
			MessageText = NStr("vi = 'Trên cơ sở đã nhập chứng từ chỉnh sửa.
			                            |Chỉ có thể chỉnh sửa trên cơ sở chứng từ chỉnh sửa gần nhất.';
			                            |ru = 'На основании уже введен исправительный документ.
			                            |Исправление может быть введено только на основании последнего исправительного документа.';
			                            |en = 'The correction document is already entered using base document.
			                            |The correction may only be entered based on the last correction document.'; fa = 'The correction document is already entered using base document.
			                            |The correction may only be entered based on the last correction document.';
			                            |it = 'Sulla base di questo documento è già stato inserito un documento di correzione.
			                            | La correzione può essere inserita solo sulla base dell''ultimo documento di correzione.';
			                            |pl = 'Na podstawie już jest wprowadzony dokument korygujący.
			                            |Korekta może być wprowadzona tylko na podstawie ostatniego dokumentu korygującego.';
			                            |tr = 'Esasa göre zaten bir düzeltme belgesi girilmiştir.
			                            |Düzeltme sadece son düzeltme belgesine göre girilebilir.'");
		EndIf;
		Raise MessageText;
	EndIf;
	
	ObjectDocumentBeingCorrected = CorrectedDocument.GetObject();
	
	ObjectMetadata = ObjectDocumentBeingCorrected.Metadata();
	ArrayOfExcludedDetails = New Array;
	ArrayOfExcludedDetails.Add("Number");
	ArrayOfExcludedDetails.Add("Date");
	ArrayOfExcludedDetails.Add("Posted");
	ArrayOfExcludedDetails.Add("DeletionMark");
	ArrayOfExcludedDetails.Add("Ref");
	If ObjectMetadata.Attributes.Find("Author") <> Undefined Then
		ArrayOfExcludedDetails.Add("Author");
	EndIf;
	If ObjectMetadata.Attributes.Find("EmployeeResponsible") <> Undefined Then
		ArrayOfExcludedDetails.Add("EmployeeResponsible");
	EndIf;
	
	FillPropertyValues(DocumentObject, ObjectDocumentBeingCorrected, , StrConcat(ArrayOfExcludedDetails, ","));
	For Each TabularSection In DocumentObject.Metadata().TabularSections Do
		DocumentObject[TabularSection.Name].Load(ObjectDocumentBeingCorrected[TabularSection.Name].Unload());
	EndDo;
	
	DocumentObject.Patch = True;
	DocumentObject.ReversedDocument = Common.ObjectAttributeValue(CorrectedDocument, "Ref");
	If Not ValueIsFilled(DocumentObject.CorrectedDocument) Then
		DocumentObject.CorrectedDocument = DocumentObject.ReversedDocument;
	EndIf;
	
EndProcedure

// Clears the correction details when copying the document.
// 
// Parameters:
// 	DocumentObject - DocumentObject, DocumentObject.InventoryTransfer - Object that was created by copying
// 	CopiedObject - DocumentObject, DocumentObject.InventoryTransfer - Link to the document that is being copied
//
Procedure OnCopy(DocumentObject, CopiedObject) Export
	
	DocumentObject.Patch = False;
	DocumentObject.ReversedDocument = Undefined;
	DocumentObject.CorrectedDocument = Undefined;
	
EndProcedure

// Checks whether the object can be written.
// 
// Parameters:
// 	DocumentObject - DocumentObject, DocumentObject.InventoryTransfer - The object that is being recorded.
// 	Cancel - Boolean - Write failure flag.
// 	WriteMode - DocumentWriteMode - the recording mode of the document.
// 	PostingMode - DocumentPostingMode - the mode of the document.
//
Procedure BeforeWrite(DocumentObject, Cancel, WriteMode, PostingMode) Export
	
	If Not GetFunctionalOption("UseDocumentCorrection") Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(DocumentObject.Ref) Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref AS Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.ReversedDocument = &Ref
	|	AND DocumentsRegistry.Posted
	|";
	Query.SetParameter("RefType", Common.MetadataObjectID(DocumentObject.Metadata().FullName()));
	Query.SetParameter("Ref", DocumentObject.Ref);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		If TypeOf(Selection.Ref) = Type("DocumentRef.ReversingEntry") Then
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập chứng từ ""Đảo ngược"".
				                        |Không thể ghi lại chứng từ.';
				                        |ru = 'На основании документа введен документ ""Сторно"".
				                        |Запись документа невозможна.';
				                        |en = 'The ""Storno"" document is entered based on the document.
				                        |Cannot save document.'; fa = 'The ""Storno"" document is entered based on the document.
				                        |Cannot save document.';
				                        |it = 'Sulla base di questo documento è stato inserito il documento ""Storno"". 
				                        |Impossibile salvare il documento.';
				                        |pl = 'Na podstawie dokumentu wprowadzono dokument ""Storno"".
				                        |Zapis dokumentu jest niemożliwa.';
				                        |tr = 'Belgeye istinaden ""İptal"" belgesi girildi.
				                        |Belge kaydı mümkün değil.'");
		Else
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập chỉnh sửa.
				                        |Không thể ghi lại chứng từ.';
				                        |ru = 'На основании документа введено исправление.
				                        |Запись документа невозможна.';
				                        |en = 'The correction is entered based on the document.
				                        |Cannot save document.'; fa = 'The correction is entered based on the document.
				                        |Cannot save document.';
				                        |it = 'Sulla base di questo documento è stata inserita una correzione. 
				                        | Impossibile salvare il documento.';
				                        |pl = 'Na podstawie dokumentu została wprowadzona korekta.
				                        |Zapis dokumentu jest niemożliwy.';
				                        |tr = 'Belgeye istinaden düzeltme yapılmıştır.
				                        |Belge kaydı mümkün değil.'");
		EndIf;
		Common.MessageToUser(MessageText, , , , Cancel);
	EndIf;
	
EndProcedure

// Verifies that the correction document is filled in correctly.
// 
// Parameters:
// 	DocumentObject -  DocumentObject, DocumentObject.InventoryTransfer - The object to check for completion.
// 	Cancel - Boolean - Write failure flag.
// 	CheckedAttributes - Array of String - Array of verified Bank details.
//
Procedure FillCheckProcessing(DocumentObject, Cancel, CheckedAttributes) Export
	
	AttributesNotToCheck = New Array;
	
	If DocumentObject.Patch Then
		CheckCompletionOfCorrectionDocument(DocumentObject, Cancel);
	Else
		AttributesNotToCheck.Add("ReversedDocument");
		AttributesNotToCheck.Add("CorrectedDocument");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

// Checks whether the Storno is filled in correctly.
// 
// Parameters:
// 	DocumentObject -  DocumentObject.ReversingEntry - The object to check for completion.
// 	Cancel - Boolean - Write failure flag.
// 	CheckedAttributes - Array of String - Array of verified Bank details.
//
Procedure CheckFillingOfStorno(DocumentObject, Cancel, CheckedAttributes) Export
	
	CheckCompletionOfCorrectionDocument(DocumentObject, Cancel);
	
EndProcedure

// Generates a string with information about the correction.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document:
// 		* Object - FormDataCollection - The document object:
// 			* Ref - DocumentRef -
// 	ElementCorrection - FormField - Field with information about the correction.
//
Procedure OnCreateAtServer(Form, ElementCorrection) Export
	
	If Not GetFunctionalOption("UseDocumentCorrection") Then
		ElementCorrection.Visible = False;
		Return;
	EndIf;
	
	If ValueIsFilled(Form.Object.Ref) Then
		Return;
	EndIf;
	
	OnReadCreateAtServer(Form, ElementCorrection)
	
EndProcedure

// Generates a string with information about the correction.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	ElementCorrection - FormField - Field with information about the correction.
//
Procedure OnReadAtServer(Form, ElementCorrection) Export
	
	If Not GetFunctionalOption("UseDocumentCorrection") Then
		Return;
	EndIf;
	
	OnReadCreateAtServer(Form, ElementCorrection);
	
EndProcedure

// Sets the number of the correction document, for those document types for which it is important
// to keep the sequential numbering of the corrected documents.
// 
// Parameters:
// 	DocumentObject - DocumentObject - Correction document
// 	StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
// 	Prefix - String - The prefix that will be used to generate the number.
Procedure OnSetNewNumber(DocumentObject, StandardProcessing, Prefix) Export
	
	If DocumentObject.Patch Then
		Prefix = NStr("vi = 'VÀ';
						|ru = 'И';
						|en = 'C'; fa = 'C';
						|it = 'C';
						|pl = 'K';
						|tr = 'VE'", Common.DefaultLanguageCode());;
		StandardProcessing = True;
	EndIf;
	
EndProcedure

// Returns True if the document is a correction.
//
// Parameters:
// 	DocumentObject - DocumentObject - The document for which you want to perform validation
//
// Returns:
//	Boolean - 
Function ThisIsCorrectiveDocument(DocumentObject) Export
	
	Result = False;
	If TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry") Then
		Result = True;
	ElsIf Common.HasObjectAttribute("Patch", DocumentObject.Metadata()) Then
		Result = DocumentObject.Patch;		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a flag indicating that a corrective (reversal) document can be registered.
// If the correction (reversal) cannot be performed, a message is issued.
// 
// Parameters:
// 	ReversedDocument - DocumentObject - Corrective (reversal) document.
// 	
// Returns:
// 	Boolean - 
Function RegistrationStornoIsAllowed(ReversedDocument) Export
	
	Cancel = False;
	
	// If the document is entered in the period of using batch accounting 2.1, then corrections are not supported.
	DateOfDocumentBeingCorrected = Common.ObjectAttributeValue(ReversedDocument, "Date");
	ManagerOfDocument = Common.ObjectManagerByRef(ReversedDocument);
	AccountingMechanisms = DocumentsPosting.DocumentAccountingMechanisms(ManagerOfDocument);
	If AccountingMechanisms.Find("CostAndBatchAccounting") <> Undefined
		 Or AccountingMechanisms.Find("AccountingOfIncomeExpenses") <> Undefined Then
		CostsServer.CheckUseOfBatchAccounting22(ReversedDocument, DateOfDocumentBeingCorrected, Cancel);
	EndIf;
	
	CheckEndOfUpdate(ReversedDocument, Cancel);
	
	Return Not Cancel;
	
EndFunction

// Returns True if the document has been corrected or reversed.
//
// Parameters:
//	Document - DocumentRef - The document for which you want to perform validation
//
// Returns:
// 	Boolean - Test result
Function IsThereFixOrReverse(Document) Export
	
	If Not Metadata.DefinedTypes.CorrectedDocuments.Type.ContainsType(TypeOf(Document)) Then
		Return False;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.ReversedDocument  = &Document
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND DocumentsRegistry.Posted";
	Query.SetParameter("RefType", Common.MetadataObjectID(Document.Metadata().FullName()));
	Query.SetParameter("Document", Document);
	
	SetPrivilegedMode(True);
	If Not Query.Execute().IsEmpty() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns a link to the reversing document.
//
// Parameters:
//	Document - DocumentRef - The document for which you need to find the reverse
//
// Returns:
// 	Boolean - Document Link, Undefined
Function ReverseDocument(Document) Export
	
	If Not Metadata.DefinedTypes.CorrectedDocuments.Type.ContainsType(TypeOf(Document)) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	DocumentsRegistry.Ref AS Ref
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.ReversedDocument  = &Document
	|	AND DocumentsRegistry.ReverseTransactionCorrection
	|	AND DocumentsRegistry.Posted";
	Query.SetParameter("RefType", Common.MetadataObjectID(Document.Metadata().FullName()));
	Query.SetParameter("Document", Document);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns the reversing documents
//
// Parameters:
//	ReversedDocuments - Array of DocumentRef - Documents for which you need to find the reverse
//
// Returns:
// 	ValueTable - Reversing documents:
// 		* Ref - DocumentRef - 
// 		* ReversedDocument - DocumentRef - 
Function StornoDocuments(ReversedDocuments) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref AS Ref,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.ReversedDocument IN (&ReversedDocuments)
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|";
	Query.SetParameter("ReversedDocuments", ReversedDocuments);
	
	Return Query.Execute().Unload();

EndFunction

// Returns the document to be corrected (the first document in the chain) by correction
//
//	Parameters:
//		Patch - DocumentRef - Patch
//	
//	Returns:
//		DocumentRef -
//
Function CorrectedDocument(Val Patch) Export

	SetPrivilegedMode(True);
	
	Return InformationRegisters.DocumentCorrections.CorrectedDocument(Patch);

EndFunction

#Region DocumentCorrection

// Returns document corrections
//
// Parameters:
//	CorrectedDocument - DocumentRef - The document for which corrections are required
//
// Returns:
// 	Array of DocumentRef - Array of document corrections.
//
Function CorrectionsOfDocument(Val CorrectedDocument) Export
	
	SetPrivilegedMode(True);

	Return InformationRegisters.DocumentCorrections.CorrectionsOfDocument(CorrectedDocument);	

EndFunction	

// Returns document corrections by correction document type
//
// Parameters:
//	CorrectedDocuments - Array of DocumentRef - documents that require corrections
//	CorrectionType - String - type of correction document
//	
// Returns:
// 	Array of DocumentRef - An array of document corrections.
//
Function CorrectionsOfDocumentsByTypeOfCorrection(Val CorrectedDocuments, Val CorrectionType) Export
		
	SetPrivilegedMode(True);

	Return InformationRegisters.DocumentCorrections.CorrectionsOfDocumentsByTypeOfCorrection(CorrectedDocuments, CorrectionType);	
	
EndFunction

// Returns the document view
//
// Parameters:
//	CorrectedDocument - DocumentRef - The document for which Presentation is required
//
// Returns:
// 	String - Presentation Of The Corrected Document
//
Function PresentationOfCorrectedDocument(Val CorrectedDocument) Export
	
	PresentationOfCorrectedDocument = "";		
	
	If Not ValueIsFilled(CorrectedDocument) Then
		Return PresentationOfCorrectedDocument;		
	EndIf;	
	
	DataOfDocumentBeingCorrected = Common.ObjectAttributesValues(CorrectedDocument, 
		"Date, Number");	
		
	NumberOfDocumentBeingCorrected = ObjectsPrefixesClientServer.NumberForPrinting(DataOfDocumentBeingCorrected.Number);
	DateOfDocumentBeingCorrected = Format(DataOfDocumentBeingCorrected.Date, "DLF=D;");
	
	TemplateOfPresentation = NStr("vi = '%1 ngày %2';
									|ru = '%1 от %2';
									|en = '%1 dated %2'; fa = '%1 dated %2';
									|it = '%1 del %2';
									|pl = '%1 z dn. %2';
									|tr = '%2 itibarıyla %1'"); 

	PresentationOfCorrectedDocument = StrTemplate(TemplateOfPresentation, 
		NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected);		
	
	Return PresentationOfCorrectedDocument;
	
EndFunction

// Checks whether the Recorders parameters have changed relative to the stored entries in the Document Correction register.
//
// Parameters:
//  CheckParameters - See InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters
// 
// Returns:
//  Boolean - True - the parameters have changed, False - not.
//
Function ParametersForCorrectingDocumentsHaveChanged(CheckParameters) Export
	
	Return InformationRegisters.DocumentCorrections.ParametersForCorrectingDocumentsHaveChanged(CheckParameters);
	
EndFunction

// Returns the correction document after the date of the document being checked.
//
// Parameters:
//  CheckParameters - See InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters
// 
// Returns:
//  DocumentRef, Undefined - Recorders of the register of Register entries.Correctedocuments
//
Function CorrectionAfterDocumentDate(CheckParameters) Export
	
	Return InformationRegisters.DocumentCorrections.CorrectionAfterDocumentDate(CheckParameters);
	
EndFunction

// Returns an indication of whether the document has current corrections as of the date 
//
// Parameters:
//	CorrectedDocument - DocumentRef - Document being corrected
//	ReversedDocument - DocumentRef - the document being cancelled
//	Date - Date - Date of verification
//
// Returns:
// 	Boolean - If True, there are actual corrections for the document being canceled
//
Function AvailabilityOfCorrectionsAsOfDocumentDate(CorrectedDocument, ReversedDocument, Date) Export
	
	Return InformationRegisters.DocumentCorrections.AvailabilityOfCorrectionsAsOfDocumentDate(CorrectedDocument, ReversedDocument, Date);
	
EndFunction

#EndRegion

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
// 	MetadataOfDocument - MetadataObjectDocument - Metadata object of the document that is being held
//
Procedure AddRequestTexts(Query, QueryTexts, Registers, MetadataOfDocument) Export

	QueryTextTableDocumentCorrections(Query, QueryTexts, Registers, MetadataOfDocument);
		
EndProcedure

// Function-constructor of parameters of the accounting mechanism.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.DocumentCorrections);
		
	EndIf;	
	
	Return Parameters;	
		
EndFunction

// Loads data for writing to a set of document movement records in the specified case.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "DocumentCorrections");
	
EndProcedure

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	Document - DocumentRef - link to the document
//	TempTablesManager - TempTablesManager - Manager temporary tables in the document
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure WriteData(TablesForRegisteredRecords, Document, TempTablesManager, Cancel) Export
		
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CheckCompletionOfCorrectionDocument(DocumentObject, Cancel)
	
	ThisIsReverseTransaction = TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry");
	If ThisIsReverseTransaction Then
		ThisIsFirstFix = False;
	Else
		ThisIsFirstFix = (DocumentObject.ReversedDocument = DocumentObject.CorrectedDocument);
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.Posted AS Posted,
	|	DocumentsRegistry.Organization AS Organization
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.Ref = &ReversedDocument
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|;
	|
	|////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsRegistry.Ref,
	|	DocumentsRegistry.IBDocumentDate AS Date,
	|	DocumentsRegistry.IBDocumentNumber AS Number,
	|	DocumentsRegistry.Posted AS Posted
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.ReversedDocument = &ReversedDocument
	|	AND DocumentsRegistry.Ref <> &Ref
	|	AND DocumentsRegistry.Posted
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|;
	|
	|////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ARAPAccounting.Period) AS Period
	|FROM
	|	(SELECT
	|		CustomersARAPAccounting.Period
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|	WHERE
	|		CustomersARAPAccounting.Recorder = &ReversedDocument
	|		AND CustomersARAPAccounting.Sum <> 0 
	|
	|	UNION ALL
	|
	|	SELECT
	|		VendorsARAPAccounting.Period
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|	WHERE
	|		VendorsARAPAccounting.Recorder = &ReversedDocument
	|		AND VendorsARAPAccounting.Sum <> 0 
	|	) AS ARAPAccounting
	|";
	
	Query.SetParameter("RefType", Common.MetadataObjectID(DocumentObject.ReversedDocument.Metadata().FullName()));
	Query.SetParameter("ReversedDocument", DocumentObject.ReversedDocument);
	Query.SetParameter("Ref", DocumentObject.Ref);
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	DetailsOfCancelledDocument = QueryResults[0].Select();
	If Not DetailsOfCancelledDocument.Next() Then
		Raise StrTemplate(NStr("vi = 'Theo chứng từ %1 không có dữ liệu trong sổ chứng từ.';
								|ru = 'По документу %1 нет данных в реестре документов.';
								|en = 'The document registry contains no data for document %1.'; fa = 'The document registry contains no data for document %1.';
								|it = 'Per il documento %1 non esistono dati nel registro dei documenti.';
								|pl = 'Brak danych wg dokumentu%1 w rejestrze dokumentów.';
								|tr = '%1 belgesinde belge kayıt defterinde veri yok.'"), DocumentObject.ReversedDocument);
	Else
		If CommonClientServer.HasAttributeOrObjectProperty(DocumentObject, "Organization")
			And DetailsOfCancelledDocument.Organization <> DocumentObject.Organization Then
			MessageText = NStr("vi = 'При исправлении организация не может быть изменена, следует выполнить сторнирование и регистрацию нового документа.';
								|ru = 'При исправлении организация не может быть изменена, следует выполнить сторнирование и регистрацию нового документа.';
								|en = 'Cannot change the company when correcting the document. Reverse the previous document and register a new one.'; fa = 'Cannot change the company when correcting the document. Reverse the previous document and register a new one.';
								|it = 'При исправлении организация не может быть изменена, следует выполнить сторнирование и регистрацию нового документа.';
								|pl = 'Cannot change the company when correcting the document. Reverse the previous document and register a new one.';
								|tr = 'При исправлении организация не может быть изменена, следует выполнить сторнирование и регистрацию нового документа.'");
			Common.MessageToUser(MessageText, DocumentObject, "Organization", , Cancel);
		EndIf;
	EndIf;
	
	OtherFixes = QueryResults[1].Select();
	If OtherFixes.Next() Then
		If TypeOf(OtherFixes.Ref) = Type("DocumentRef.ReversingEntry") Then
			If ThisIsReverseTransaction Then
				MessageText =StrTemplate(NStr("vi = 'Đã nhập chứng từ ""Đảo ngược"" trên cơ sở ""%1"".';
												|ru = 'На основании ""%1"" уже введен документ ""Сторно"".';
												|en = 'The ""Storno"" document is already entered based on ""%1"".'; fa = 'The ""Storno"" document is already entered based on ""%1"".';
												|it = 'The ""Storno"" document is already entered based on ""%1"".';
												|pl = 'The ""Storno"" document is already entered based on ""%1"".';
												|tr = '""%1"" gerekçesine dayalı, ""İptal"" belgesi artık girildi.'"),
											DocumentObject.ReversedDocument);
			Else
				MessageText = StrTemplate(NStr("vi = 'Trên cơ sở ""%1"" đã nhập chứng từ ""Đảo ngược"".
					                       |Không thể nhập chứng từ chỉnh sửa.';
					                       |ru = 'На основании ""%1"" введен документ ""Сторно"".
					                       |Ввод исправительного документа невозможен.';
					                       |en = 'The ""Storno"" document is entered based on ""%1"".
					                       |Entering correction document is not available.'; fa = 'The ""Storno"" document is entered based on ""%1"".
					                       |Entering correction document is not available.';
					                       |it = 'Sulla base del ""%1"" è stato inserito il documento ""Storno"". 
					                       | Impossibile inserire un documento di correzione.';
					                       |pl = 'Na podstawie ""%1"" został wprowadzony dokument ""Storno"".
					                       |Wprowadzenie dokumentu korygującego jest niemożliwe.';
					                       |tr = '""%1"" istinaden ""İptal"" belgesi girildi.
					                       |Düzeltme belgesi girilemiyor.'"),
					                       DocumentObject.ReversedDocument);
			EndIf;
		Else
			If ThisIsReverseTransaction Then
				MessageText = StrTemplate(NStr("vi = 'Trên cơ sở ""%1"" đã nhập chứng từ chỉnh sửa.
				                       |Chỉ có thể nhập chứng từ đảo ngược trên cơ sở chứng từ chỉnh sửa gần nhất.';
				                       |ru = 'На основании ""%1"" введен исправительный документ.
				                       |Ввод сторно возможен только на основании последнего исправительного документа.';
				                       |en = 'The correction document is entered based on ""%1"".
				                       |The storno document may only be entered based on the last correction document.'; fa = 'The correction document is entered based on ""%1"".
				                       |The storno document may only be entered based on the last correction document.';
				                       |it = 'The correction document is entered based on ""%1"".
				                       |The storno document may only be entered based on the last correction document.';
				                       |pl = 'The correction document is entered based on ""%1"".
				                       |The storno document may only be entered based on the last correction document.';
				                       |tr = '""%1"" temelinde düzeltici belge girilmiştir.
				                       |Geri dönük giriş sadece en son düzeltici belgeye dayanarak mümkündür.'"),
				                       DocumentObject.ReversedDocument);
			Else
				MessageText = StrTemplate(NStr("vi = 'Trên cơ sở ""%1"" đã nhập chứng từ chỉnh sửa.
				                       |Chỉ có thể nhập chứng từ mới trên cơ sở chứng từ chỉnh sửa đã cập nhật.';
				                       |ru = 'На основании ""%1"" уже введен исправительный документ.
				                       |Ввод нового документа возможен только на основании актуального исправительного документа.';
				                       |en = 'The correction document is already entered based on ""%1"".
				                       |Entering the new document is only possible based on the effective correction document.'; fa = 'The correction document is already entered based on ""%1"".
				                       |Entering the new document is only possible based on the effective correction document.';
				                       |it = 'Sulla base del ""%1"" è stato inserito un documento di correzione. 
				                       | Un nuovo documento può essere inserito solo sulla base del documento di correzione corrente.';
				                       |pl = 'Na podstawie ""%1"" już został wprowadzony dokument korygujący.
				                       |Wprowadzenie nowego dokumentu jest możliwe tylko na podstawie aktualnego dokumentu korygującego.';
				                       |tr = '""%1"" istinaden zaten bir düzeltme belgesi girildi.
				                       |Yeni bir belge yalnızca geçerli bir düzeltme belgesi esas alınarak girilebilir.'"),
				                       DocumentObject.ReversedDocument);
			EndIf;
		EndIf;
		Common.MessageToUser(MessageText, DocumentObject, , , Cancel);
	EndIf;
	
	If Not Cancel And Not DetailsOfCancelledDocument.Posted Then
		If ThisIsReverseTransaction Then
			MessageText = NStr("vi = 'Chưa kết chuyển chứng từ bị đảo ngược.';
								|ru = 'Сторнируемый документ не проведен.';
								|en = 'Reversed document is not posted.'; fa = 'Reversed document is not posted.';
								|it = 'Il documento da stornare non è stato elaborato.';
								|pl = 'Dokument stornowany nie jest zatwierdzony.';
								|tr = 'Tersine çevrilen belge kaydedilmedi'");
		ElsIf ThisIsFirstFix Then
			MessageText = NStr("vi = 'Chưa kết chuyển chứng từ được chỉnh sửa.';
								|ru = 'Исправляемый документ не проведен.';
								|en = 'Corrected document is not posted.'; fa = 'Corrected document is not posted.';
								|it = 'Il documento da correggere non è stato elaborato.';
								|pl = 'Nie zatwierdzono dokumentu korygującego.';
								|tr = 'Düzeltme belgesi kaydedilmedi.'");
		Else
			MessageText = NStr("vi = 'Chưa kết chuyển chứng từ được điều chỉnh lần trước.';
								|ru = 'Предыдущий исправительный документ не проведен.';
								|en = 'Previous correction document is not posted.'; fa = 'Previous correction document is not posted.';
								|it = 'Il documento di correzione precedente non è stato elaborato.';
								|pl = 'Nie zatwierdzono poprzedniego dokumentu korygującego.';
								|tr = 'Önceki düzeltilen belge kaydedilmedi.'");
		EndIf;
		Common.MessageToUser(MessageText, DocumentObject, , , Cancel);
	EndIf;
	
	DateAndTimeOfCorrectionForVerification = DocumentObject.Date;
	If DocumentObject.IsNew()
		And DocumentObject.Metadata().RealTimePosting = Metadata.ObjectProperties.RealTimePosting.Allow
		And DateAndTimeOfCorrectionForVerification = BegOfDay(CurrentSessionDate()) Then
		DateAndTimeOfCorrectionForVerification = EndOfDay(DateAndTimeOfCorrectionForVerification);
	EndIf;
	
	If Not Cancel And DetailsOfCancelledDocument.Date >= DateAndTimeOfCorrectionForVerification Then
		If ThisIsReverseTransaction Then
			MessageText = NStr("vi = 'Ngày giờ đảo ngược phải lớn hơn ngày giờ trong chứng từ đảo ngược';
								|ru = 'Дата и время сторно должны быть больше, чем у сторнируемого документа';
								|en = 'The storno date and time must be later than the date and time of the document to reverse'; fa = 'The storno date and time must be later than the date and time of the document to reverse';
								|it = 'The storno date and time must be later than the date and time of the document to reverse';
								|pl = 'The storno date and time must be later than the date and time of the document to reverse';
								|tr = 'İptal işleminin tarih ve saati, iptal edilen belgenin tarih ve saatinden daha ileri olmalıdır'");
		ElsIf ThisIsFirstFix Then
			MessageText = NStr("vi = 'Ngày giờ chỉnh sửa phải lớn hơn ngày giờ trong chứng từ chỉnh sửa';
								|ru = 'Дата и время исправления должны быть больше, чем у исправляемого документа';
								|en = 'The correction date and time must be later than the date and time of the document to correct'; fa = 'The correction date and time must be later than the date and time of the document to correct';
								|it = 'The correction date and time must be later than the date and time of the document to correct';
								|pl = 'The correction date and time must be later than the date and time of the document to correct';
								|tr = 'Düzeltmenin tarih ve saati, düzeltilen belgenin tarih ve saatinden daha ileri olmalıdır'");
		Else
			MessageText = NStr("vi = 'Ngày giờ chỉnh sửa phải lớn hơn ngày giờ trong chứng từ chỉnh sửa trước đó';
								|ru = 'Дата и время исправления должны быть больше, чем у предыдущего исправления документа';
								|en = 'The correction date and time must be later than the date and time of the last document correction'; fa = 'The correction date and time must be later than the date and time of the last document correction';
								|it = 'The correction date and time must be later than the date and time of the last document correction';
								|pl = 'The correction date and time must be later than the date and time of the last document correction';
								|tr = 'Düzeltmenin tarih ve saati, belgenin daha önce düzeltildiği tarihten ve saatten daha ileri olmalıdır'");
		EndIf;
		Common.MessageToUser(MessageText, DocumentObject, "Date", , Cancel);
	EndIf;
	
	RegisteredRecordsOfMutualSettlements = QueryResults[2].Select();
	If RegisteredRecordsOfMutualSettlements.Next() And ValueIsFilled(RegisteredRecordsOfMutualSettlements.Period) Then
		If Not Cancel And RegisteredRecordsOfMutualSettlements.Period >= DateAndTimeOfCorrectionForVerification Then
			If ThisIsReverseTransaction Then
				MessageText = NStr("vi = 'Ngày giờ đảo ngược phải lớn hơn kỳ biến động hạch toán công nợ trong chứng từ đảo ngược.';
									|ru = 'Дата и время сторно должны быть больше, чем период движения взаиморасчетов сторнируемого документа.';
									|en = 'The storno date and time must be later than the AR/AP period of the document to reverse.'; fa = 'The storno date and time must be later than the AR/AP period of the document to reverse.';
									|it = 'The storno date and time must be later than the AR/AP period of the document to reverse.';
									|pl = 'The storno date and time must be later than the AR/AP period of the document to reverse.';
									|tr = 'İptal işleminin tarih ve saati, iptal edilen belgenin mutabakat süresinden daha ileri olmalıdır.'");
			ElsIf ThisIsFirstFix Then
				MessageText = NStr("vi = 'Ngày giờ chỉnh sửa phải lớn hơn kỳ biến động hạch toán công nợ trong chứng từ chỉnh sửa.';
									|ru = 'Дата и время исправления должны быть больше, чем период движения взаиморасчетов исправляемого документа.';
									|en = 'The correction date and time must be later than the AR/AP period of the document to correct.'; fa = 'The correction date and time must be later than the AR/AP period of the document to correct.';
									|it = 'The correction date and time must be later than the AR/AP period of the document to correct.';
									|pl = 'The correction date and time must be later than the AR/AP period of the document to correct.';
									|tr = 'Düzeltmenin tarih ve saati, düzeltilen belgenin mutabakatlarının hareket süresinden daha ileri olmalıdır.'");
			Else
				MessageText = NStr("vi = 'Ngày giờ chỉnh sửa phải lớn hơn kỳ biến động hạch toán công nợ trong chứng từ chỉnh sửa trước đó.';
									|ru = 'Дата и время исправления должны быть больше, чем период движения взаиморасчетов предыдущего исправления документа.';
									|en = 'The correction date and time must be later than the AR/AP period of the last document correction.'; fa = 'The correction date and time must be later than the AR/AP period of the last document correction.';
									|it = 'The correction date and time must be later than the AR/AP period of the last document correction.';
									|pl = 'The correction date and time must be later than the AR/AP period of the last document correction.';
									|tr = 'Düzeltmenin tarih ve saati, belgenin önceki düzeltmesinin mutabakatlarının hareket süresinden daha ileri olmalıdır.'");
			EndIf;
			Common.MessageToUser(MessageText, DocumentObject, "Date", , Cancel);
		EndIf;
	EndIf;
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	ElementCorrection - FormField - 
Procedure OnReadCreateAtServer(Form, ElementCorrection)
	
	Object = Form.Object;
	
	BuiltInFix = 
		CommonClientServer.HasAttributeOrObjectProperty(Object, "Patch")
		And CommonClientServer.HasAttributeOrObjectProperty(Object, "CorrectedDocument");
	
	If BuiltInFix And Object.Patch Then
		CorrectedDocument = Object.CorrectedDocument;
	Else
		CorrectedDocument = Object.Ref;
	EndIf;
	
	CorrectiveDocument = LastCorrectiveDocument(CorrectedDocument);
	
	If (Not BuiltInFix Or Not Object.Patch) And CorrectiveDocument <> Undefined Then
		
		Form[ElementCorrection.DataPath] = DocumentCorrectionHyperlink(CorrectedDocument, CorrectiveDocument);
		ElementCorrection.Visible = True;
		Form.ReadOnly = Object.Posted;
		
	ElsIf BuiltInFix And Object.Patch Then
		
		DetailsOfCorrectedDocument = Common.ObjectAttributesValues(Object.CorrectedDocument, "Number, Date");
		
		SubstringsArray = New Array;
		SubstringsArray.Add(
			           StringFunctions.FormattedString(NStr("vi = 'Chỉnh sửa chứng từ <a href=""%1"">%2 ngày %3</a>';
															|ru = 'Исправление документа <a href=""%1"">%2 от %3</a>';
															|en = 'Correction of document <a href=""%1"">%2 dated %3</a>'; fa = 'Correction of document <a href=""%1"">%2 dated %3</a>';
															|it = 'Исправление документа <a href=""%1"">%2 от %3</a>';
															|pl = 'Correction of document <a href=""%1"">%2 dated %3</a>';
															|tr = 'Belge düzeltme <a href=""%1"">%2 %3</a>''dan'"),
			           GetURL(Object.CorrectedDocument),
			           DetailsOfCorrectedDocument.Number,
			           Format(DetailsOfCorrectedDocument.Date, "DLF=DT")));
		
		OtherDocumentCorrections = OtherDocumentCorrections(CorrectedDocument, Object.Ref);
		If OtherDocumentCorrections.Count() > 0 Then
			SubstringsArray.Add(" ");
			SubstringsArray.Add(
				StringFunctions.FormattedString(
				                 NStr("vi = '(Xem <a href=""%1"">tất cả chỉnh sửa</a> của chứng từ)';
										|ru = '(См. <a href=""%1"">все исправления</a> документа)';
										|en = '(See <a href=""%1"">all corrections</a> of document)'; fa = '(See <a href=""%1"">all corrections</a> of document)';
										|it = '(См. <a href=""%1"">все исправления</a> документа)';
										|pl = '(See <a href=""%1"">all corrections</a> of document)';
										|tr = '(Bk. <a href=""%1"">tüm belge düzeltmeleri</a>)'"),
				                 "OpenListOfCorrectiveDocuments"));
		EndIf;
		
		If ValueIsFilled(Object.Ref) 
			And CorrectiveDocument <> Undefined
			And Object.Ref <> CorrectiveDocument.Ref Then
			Form.ReadOnly = Object.Posted;
		EndIf;
		
		Form[ElementCorrection.DataPath] = New FormattedString(SubstringsArray);
		ElementCorrection.Visible = True;
		
		// In the correction, we block changes to the organization.
		// If it is necessary to change the organization, you should cancel and register a new document.
		If CommonClientServer.HasAttributeOrObjectProperty(Form.Items, "Organization") Then
			Form.Items.Organization.ReadOnly = True;
		EndIf;
	
	Else
		ElementCorrection.Visible = False;
	EndIf;
	
EndProcedure

// Returns the text of the hyperlink to the document corrections for output in the form.
// 
// Parameters:
//  CorrectedDocument - DocumentRef - Document being corrected
//  CorrectiveDocument - Undefined, Structure - Correction document:
// 
// Returns:
//  Undefined, FormattedString - Document Correction Hyperlink
Function DocumentCorrectionHyperlink(CorrectedDocument, CorrectiveDocument = Undefined) Export
	
		If CorrectiveDocument = Undefined Then
			CorrectiveDocument = LastCorrectiveDocument(CorrectedDocument);
		EndIf;
		
		RowsArray = New Array;
		
		If Not CorrectiveDocument = Undefined Then
		
			If TypeOf(CorrectiveDocument.Ref) = Type("DocumentRef.ReversingEntry") Then
				RowsArray.Add(
					StringFunctions.FormattedString(
					                 NStr("vi = 'Đã nhập đảo ngược <a href=""%1"">%2 ngày %3</a>';
											|ru = 'Введено сторно <a href=""%1"">%2 от %3</a>';
											|en = 'Entered storno <a href=""%1"">%2 dated %3</a>'; fa = 'Entered storno <a href=""%1"">%2 dated %3</a>';
											|it = 'Введено сторно <a href=""%1"">%2 от %3</a>';
											|pl = 'Entered storno <a href=""%1"">%2 dated %3</a>';
											|tr = 'İptal girildi <a href=""%1"">%2 %3</a>''dan'"),
					                 GetURL(CorrectiveDocument.Ref),
					                 CorrectiveDocument.Number,
					                 Format(CorrectiveDocument.Date, "DLF=DT")));
			Else
				RowsArray.Add(
					StringFunctions.FormattedString(
					                 NStr("vi = 'Đã nhập chỉnh sửa <a href=""%1"">%2 ngày %3</a>';
											|ru = 'Введено исправление <a href=""%1"">%2 от %3</a>';
											|en = 'Entered correction <a href=""%1"">%2 dated %3</a>'; fa = 'Entered correction <a href=""%1"">%2 dated %3</a>';
											|it = 'Введено исправление <a href=""%1"">%2 от %3</a>';
											|pl = 'Entered correction <a href=""%1"">%2 dated %3</a>';
											|tr = 'Düzeltme girildi <a href=""%1"">%2 %3</a>''dan'"),
					                 GetURL(CorrectiveDocument.Ref),
					                 CorrectiveDocument.Number,
					                 Format(CorrectiveDocument.Date, "DLF=DT")));
				
			EndIf;
			
			If CommonClientServer.HasAttributeOrObjectProperty(CorrectiveDocument, "ReversedDocument")
				And CorrectedDocument <> CorrectiveDocument.ReversedDocument Then
				
				RowsArray.Add(" ");
				RowsArray.Add(
					StringFunctions.FormattedString(
					                 NStr("vi = '(Xem <a href=""%1"">tất cả chỉnh sửa</a> của chứng từ)';
											|ru = '(См. <a href=""%1"">все исправления</a> документа)';
											|en = '(See <a href=""%1"">all corrections</a> of document)'; fa = '(See <a href=""%1"">all corrections</a> of document)';
											|it = '(См. <a href=""%1"">все исправления</a> документа)';
											|pl = '(See <a href=""%1"">all corrections</a> of document)';
											|tr = '(Bk. <a href=""%1"">tüm belge düzeltmeleri</a>)'"),
					                 "OpenListOfCorrectiveDocuments"));
			EndIf;
			
		EndIf;
		
		Return ?(RowsArray.Count(), New FormattedString(RowsArray), Undefined);
	
EndFunction

// Returns the last correction document.
// 
// Parameters:
//  CorrectedDocument - DocumentRef - Document being corrected
// 
// Returns:
//  Undefined, Structure - The Last Corrective Document:
// 	* Ref - DocumentRef - link to the document
// 	* Number  - String - document number
// 	* Date - Date - Document date 
// 	* ReversedDocument - DocumentRef - Link to the document being cancelled
Function LastCorrectiveDocument(CorrectedDocument) Export
	
	Result = Undefined;
	If Not ValueIsFilled(CorrectedDocument) Then
		Return Result;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref                AS Ref,
	|	DocumentsRegistry.IBDocumentNumber      AS Number,
	|	DocumentsRegistry.IBDocumentDate       AS Date,
	|	DocumentsRegistry.ReversedDocument  AS ReversedDocument
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsSubsequentCorrections
	|	ON
	|		DocumentsRegistry.RefType = RegisterOfDocumentsSubsequentCorrections.RefType
	|		AND DocumentsRegistry.CorrectedDocument = RegisterOfDocumentsSubsequentCorrections.CorrectedDocument
	|		AND DocumentsRegistry.Ref = RegisterOfDocumentsSubsequentCorrections.ReversedDocument
	|		AND NOT RegisterOfDocumentsSubsequentCorrections.AdditionalRecord
	|		AND RegisterOfDocumentsSubsequentCorrections.Posted
	|		AND RegisterOfDocumentsSubsequentCorrections.IBDocumentDate > DocumentsRegistry.IBDocumentDate
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.CorrectedDocument = &CorrectedDocument
	|	AND RegisterOfDocumentsSubsequentCorrections.Ref IS NULL
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|
	|UNION
	|
	|SELECT
	|	DocumentsRegistry.Ref,
	|	DocumentsRegistry.IBDocumentNumber,
	|	DocumentsRegistry.IBDocumentDate,
	|	DocumentsRegistry.ReversedDocument
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS RegisterOfDocumentsSubsequentCorrections
	|	ON
	|		DocumentsRegistry.RefType = RegisterOfDocumentsSubsequentCorrections.RefType
	|		AND DocumentsRegistry.CorrectedDocument = RegisterOfDocumentsSubsequentCorrections.CorrectedDocument
	|		AND DocumentsRegistry.Ref = RegisterOfDocumentsSubsequentCorrections.ReversedDocument
	|		AND NOT RegisterOfDocumentsSubsequentCorrections.AdditionalRecord
	|		AND RegisterOfDocumentsSubsequentCorrections.Posted
	|		AND RegisterOfDocumentsSubsequentCorrections.IBDocumentDate > DocumentsRegistry.IBDocumentDate
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.ReversedDocument = &CorrectedDocument
	|	AND RegisterOfDocumentsSubsequentCorrections.Ref IS NULL
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|";
	Query.SetParameter("RefType", Common.MetadataObjectID(CorrectedDocument.Metadata().FullName()));
	Query.SetParameter("CorrectedDocument", CorrectedDocument);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		Result = New Structure;
		Result.Insert("Ref", Selection.Ref);
		Result.Insert("Number",  Selection.Number);
		Result.Insert("Date",   Selection.Date);
		Result.Insert("ReversedDocument",   Selection.ReversedDocument);
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	CorrectedDocument - DocumentRef -
// 	CorrectiveDocument - DocumentRef -
// Returns:
// 	ValueTable - table with columns:
// 		* Ref - DocumentRef -
// 		* Number - String -
// 		* Date - Date -
// 		* ReversedDocument - DocumentRef -
Function OtherDocumentCorrections(CorrectedDocument, CorrectiveDocument)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsRegistry.Ref                AS Ref,
	|	DocumentsRegistry.IBDocumentNumber      AS Number,
	|	DocumentsRegistry.IBDocumentDate       AS Date,
	|	DocumentsRegistry.ReversedDocument  AS ReversedDocument
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.RefType = &RefType
	|	AND DocumentsRegistry.CorrectedDocument = &CorrectedDocument
	|	AND DocumentsRegistry.Ref <> &CorrectiveDocument
	|	AND NOT DocumentsRegistry.AdditionalRecord
	|	AND DocumentsRegistry.Posted
	|";
	Query.SetParameter("RefType", Common.MetadataObjectID(CorrectedDocument.Metadata().FullName()));
	Query.SetParameter("CorrectedDocument", CorrectedDocument);
	Query.SetParameter("CorrectiveDocument", CorrectiveDocument);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
// 	MetadataOfDocument - MetadataObjectDocument - Metadata object of the document that is being held
//
Procedure QueryTextTableDocumentCorrections(Query, QueryTexts, Registers, MetadataOfDocument)
	
	RegisterName = "DocumentCorrections";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	DocumentName = MetadataOfDocument.Name;

	// In the first correction, the document being reversed = the document being corrected	
	QueryText =
	"SELECT TOP 1
	|	Document.Date AS Period,
	|	Document.CorrectedDocument AS CorrectedDocument,
	|	CASE
	|		WHEN Document.ReversedDocument = Document.CorrectedDocument
	|			THEN UNDEFINED
	|		ELSE Document.ReversedDocument
	|	END AS PreviousCorrection,
	|	&Ref AS LastChainDocument,
	|	FALSE AS DocumentToCorrectIsReversed,
	|	TRUE AS CorrectionMethodStorno
	|FROM
	|	&DocumentName AS Document
	|WHERE
	|	Document.Ref IN (&Ref)
	|	AND Document.Patch";
	
	QueryText = StrReplace(QueryText, "&DocumentName", "Document." + DocumentName);
		
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure CheckEndOfUpdate(ReversedDocument, Cancel)
	
	If InfobaseUpdate.DeferredUpdateCompleted() Then
		Return;
	EndIf;
	
	CheckResult = InfobaseUpdate.ObjectProcessed(ReversedDocument);
	
	If Not CheckResult.Processed Then
		CommonClientServer.MessageToUser(
			NStr("ru = 'Обновление документа еще не завершено.';
				|vi = 'The document is not updated yet.';
				|en = 'The document is not updated yet.'; fa = 'The document is not updated yet.';
				|it = 'The document is not updated yet.';
				|pl = 'The document is not updated yet.';
				|tr = 'Belge güncellemesi henüz tamamlanmadı.'"),,,,Cancel);
		Return;
	EndIf;
	
	DocumentType = TypeOf(ReversedDocument);
	DocumentMetadata = Metadata.FindByType(DocumentType);
	
	For Each MetadataRegister In DocumentMetadata.RegisterRecords Do
		
		RecordSet = Common.ObjectManagerByFullName(MetadataRegister.FullName()).CreateRecordSet();
		RecordSet.Filter.Recorder.Set(ReversedDocument);
		
		ResultOfRegisteredRecordsCheck = InfobaseUpdate.ObjectProcessed(RecordSet);
		
		If Not ResultOfRegisteredRecordsCheck.Processed Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Обновление движений документа по регистру ""%1"" еще не завершено.';
					|vi = 'The document ""%1"" register records are not updated yet.';
					|en = 'The document ""%1"" register records are not updated yet.'; fa = 'The document ""%1"" register records are not updated yet.';
					|it = 'The document ""%1"" register records are not updated yet.';
					|pl = 'The document ""%1"" register records are not updated yet.';
					|tr = 'Belge hareketlerinin ""%1"" siciline göre güncellemesi henüz tamamlanmadı.'"),
				MetadataRegister.Presentation());
			CommonClientServer.MessageToUser(
				MessageText,,,,Cancel);
			Return;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion
