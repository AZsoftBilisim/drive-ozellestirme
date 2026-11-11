#Region Public

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

// The function finds applications for the import of goods of a given document-the basis.
//
// Parameters:
//	DocumentBasis - DocumentRef - The document for which it is necessary to find an application for the import of goods.
//	Organization - CatalogRef.Companies - The organization for which the application for the import of goods is formed.
//	Posted - Boolean - A sign that it is necessary to obtain the completed documents.
//
// Returns:
//	ValueTable - The table of found applications for the import of goods contains columns:
//		* Ref - DocumentRef.ApplicationForImportationOfGoods - link to the document application for the import of goods.
//		* Posted - Boolean - indicates whether the document is complete. 
//		* Number - String - the document number of the application for the import of goods.
//		* Date - Date - date of the application document for the import of goods.
//		* Organization - CatalogRef.Companies - organization of the application for the import of goods.
//		* Counterparty - CatalogRef.Counterparties - the counterparty of the application for the import of goods.
//		* DateOfPaymentConfirmation - Date - the date when the payment of the tax on this application was confirmed.
//		* DocumentBasis - DocumentRef.SigningOfLeaseContract, DocumentRef.SubcontractorReport2_5, DocumentRef.VendorInvoice, DocumentRef.VendorInvoiceServicesAndAssets - the document of receipt of goods.
//
Function ApplicationsForImportOfGoodsOnBasisOf(DocumentBasis, Organization = Undefined, Posted = True) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Operation.Ref                                  AS Ref,
	|	Operation.Posted                                AS Posted,
	|	Operation.Number                                   AS Number,
	|	Operation.Date                                    AS Date,
	|	Operation.Organization                             AS Organization,
	|	Operation.Counterparty                              AS Counterparty,
	|	ApplicationForImportationOfGoodsGoods.DocumentInflow AS DocumentBasis
	|FROM
	|	Document.ApplicationForImportationOfGoods.Goods AS ApplicationForImportationOfGoodsGoods
	|	INNER JOIN 
	|		Document.ApplicationForImportationOfGoods AS Operation
	|	ON
	|		ApplicationForImportationOfGoodsGoods.Ref = Operation.Ref
	|		AND Operation.DeletionMark = FALSE
	|		AND (Operation.Organization = &Organization
	|			OR &Organization = UNDEFINED)
	|WHERE
	|	ApplicationForImportationOfGoodsGoods.DocumentInflow = &DocumentBasis
	|";
	
	If Posted Then
		Query.Text = StrReplace(Query.Text, "DeletionMark = FALSE", "Posted");
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then 
		Query.SetParameter("DocumentBasis", Common.ObjectAttributeValue(DocumentBasis, "DocumentInflow"));
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.PurchaseAdjustment") Then
		Query.SetParameter("DocumentBasis", Common.ObjectAttributeValue(DocumentBasis, "DocumentBasis"));
	Else
		Query.SetParameter("DocumentBasis", DocumentBasis);
	EndIf;
	Query.SetParameter("Organization",       Organization);
	
	SetPrivilegedMode(True);
	TableOfStatements = Query.Execute().Unload();
	
	Return TableOfStatements;
	
EndFunction

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Adds a document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array of DocumentRef.ApplicationForImportationOfGoods   - references to the objects that you want to print.
//  PrintParameters - Structure - additional print settings.
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList of DocumentRef.ApplicationForImportationOfGoods - value - the object reference;
//                                            view - name of the area where the object was output (output parameter).
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure


#EndRegion

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

// The procedure recalculates the values of the rows of the table of values to round the total sum of the column by whole units.
//
// Parameters:
//  Table - ValueTable - A table for rounding columns by whole units:
//	* ColumnDescription - Number - the column whose total value should be rounded to whole units.
//  ColumnDescription - String - The name of the column in the table, the total amount of which must be rounded to whole units.
//  RowsCount - Number - The number of rows in the table.
//
Procedure RecalculateTableRowsToRoundTotalAmountByColumn(Table, ColumnDescription, RowsCount) Export
	
	ResultingValue = Table.Total(ColumnDescription);
	RoundedTotalValue = Round(ResultingValue);
			
	If RoundedTotalValue > 0 
		And RoundedTotalValue <> ResultingValue Then
		
		ArrayOfCoefficients = Table.UnloadColumn(ColumnDescription);
		ArrayOfAmounts = CommonClientServer.DistributeAmountInProportionToCoefficients(
		RoundedTotalValue, ArrayOfCoefficients);
		For LineNumber = 0 To RowsCount - 1 Do
			Table[LineNumber][ColumnDescription] = ArrayOfAmounts[LineNumber];
		EndDo;
		
	EndIf;
			
EndProcedure

// Reshapes movements in the journal of accounting of products without re-checking the document.
// Generates a task to be reflected in the purchase book.
// Resets the reflection Status in Local accounting.
//
// Parameters:
//	ArrayOfLoggers - Array of DocumentRef.ApplicationForImportationOfGoods - Documents whose movements need to be updated.
//	CancellationFlag - Boolean - A sign that it is necessary to reformulate the movement due to the cancellation of the document.
//
Procedure GenerateRegisteredRecordsInInvoiceLog(ArrayOfLoggers, CancellationFlag = False) Export
	
	
EndProcedure

// Makes a temporary table of the import declaration of goods, taking into account the rounding of VAT and excise amounts.
//
// Parameters:
//	Query - Query - a request for the generation of Registered Records of an application for the import of goods from the EAEU.
//	QueryTexts - ValueList of String - list of Query Texts.
//
Procedure QueryTextTTGoodsImportApplications(Query, QueryTexts) Export
	
	
EndProcedure

#EndRegion
#Region RegAccountingTransactions

// Generates the request text to reflect the document in the regulated accounting.
//
// Parameters:
//	QueryText - String - Text of the transaction generation request
//
Procedure GenerateReflectionTextInLocalAccounting(QueryText) Export
	

EndProcedure

// Generates the Query Text of additional temporary tables required for reflection in regulated accounting.
// 
// Parameters:
//  QueryText - String - the generated request text.
Procedure GenerateRequestTextTTForReflectionInLocalAccounting(QueryText) Export
	
	
EndProcedure

#EndRegion

#Region UploadingInElectronicForm

// Generates an xml representation of the printed form "Application for import of goods and payment of indirect taxes" and returns the properties of the upload file.
//
// Parameters:
// UUID - UUID - Unique identifier of the form of the application being uploaded. 
//	Object 			- DocumentRef.ApplicationForImportationOfGoods - Link to the document being uploaded.
//	IsCheckOnly - Boolean - the upload flag (= False) / verification of the upload option (= True).
//
// Returns:
//	- Undefined - if the upload file could not be generated.
//	- Array of Structure - structures with data of upload files, contains:
//		* UploadFileAddress - String - the address of the binary data of the upload file in the temporary storage (except for the document verification mode only).
//		* UploadFileName - String - the short name of the upload file (with the extension).
//
Function UploadApplicationForImportOfGoods(UUID, Object, IsCheckOnly = False) Export
		
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

// Generates an xml representation of the printed form "Statistical form of accounting for the movement of goods" and returns the properties of the upload file.
//
// Parameters:
// UUID - UUID - ID of the application form to upload. 
//	Object - DocumentRef.ApplicationForImportationOfGoods - Link to the document being uploaded.
//	IsCheckOnly - Boolean -  the upload flag (= False) / verification of the upload option (= True).
//
// Returns:
//	- Undefined - if the upload file could not be generated.
//	- Array of Structure - structures with data of upload files, contains:
//		* UploadFileAddress - String - the address of the binary data of the upload file in the temporary storage (except for the document verification mode only).
//		* UploadFileName - String - the short name of the upload file (with the extension).
//
Function UploadTrackingOfMovementOfGoods(UUID, Object, IsCheckOnly = False) Export
	
	Result = Undefined;
	
	
	Return Result;
	
EndFunction

// Forms the composition of the parameters for unloading the electronic submission of the application.
//
// Parameters:
// ExportAttributeStructure - Structure - The structure of the upload parameters that needs to be updated.
//
Procedure UpdateStructureOfUploadAttributes(ExportAttributeStructure) Export
	
	
EndProcedure

// Updates the data of the Attributes of unloading the import application.
//
// Parameters:
//	StructureOfApplicationDetails	- Structure - the structure of the Attributes of the original statement contains:
//		* Ref		 - DocumentRef.ApplicationForImportationOfGoods - Link to the document being uploaded.
//		* Date		 	 - Date - date of application.
//		* Organization	 - CatalogRef.Companies - organization of the application.
//		* ExportAttributeStructure - Structure - Attributes of the importation application form.
//
// Returns:
//	- Structure - data of the upload Attributes.
//
Function UpdateDataOfUploadAttributes(StructureOfApplicationDetails) Export
	
	ExportingParameters = New Structure;
	

	Return ExportingParameters;
	
EndFunction

#EndRegion

// Fills in the relevant Attributes of the Application form with a previously saved regulated report.
//
// Parameters:
// 	ApplicationForm			- ClientApplicationForm - the form from which the procedure is called from the event handler.
//
Procedure FillInVFTSReports(ApplicationForm) Export
	
	
EndProcedure

// The procedure is called when initializing the regulated report Form.
//
// Parameters:
// 	ApplicationForm			- ClientApplicationForm - the form from which the procedure is called from the event handler.
//
Procedure InitializeRegulatedReportForm(ApplicationForm) Export
	
	
EndProcedure

#EndRegion

