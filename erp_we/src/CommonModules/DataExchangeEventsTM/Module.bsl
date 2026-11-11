
#Region Public

#Region ExchangeViaUniversalFormat

// The procedure is an event handler "before recording" reference data types (except documents) for the mechanism of registering objects on nodes.
//
// Parameters:
//  Source - CatalogObject
//           - DocumentObject
//           - ChartOfCharacteristicTypesObject- event source, except for the document object type
//  Cancel    - Boolean - flag for refusing to execute the handler.
// 
Procedure DataSynchronizationViaUniversalFormatBeforeWrite(Source, Cancel) Export
	
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWrite("DataSynchronizationViaUniversalFormat", Source, Cancel);
	
EndProcedure

// Procedure-handler of the event" before Writing " documents for the mechanism for registering objects on nodes.
//
// Parameters:
//  Source        - DocumentObject - event source.
//  Cancel           - Boolean - flag for refusing to execute the handler.
//  WriteMode     - DocumentWriteMode - see the Document Recording Mode in the Syntax assistant.
//  PostingMode - DocumentPostingMode - see the Document Execution Mode in the Syntax Helper.
// 
Procedure SynchronizeDataViaUniversalFormatBeforeWritingDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteDocument("DataSynchronizationViaUniversalFormat", Source, Cancel, WriteMode, PostingMode);
	
EndProcedure

// Procedure-handler for the "pre-Deletion" event of reference data types for the mechanism for registering objects on nodes.
//
// Parameters:
//  Source - CatalogObject
//           - DocumentObject
//           - ChartOfCharacteristicTypesObject - Event source
//  Cancel    - Boolean - flag for refusing to execute the handler.
// 
Procedure SyncDataViaUniversalFormatBeforeDeleting(Source, Cancel) Export
	
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeDelete("DataSynchronizationViaUniversalFormat", Source, Cancel);
	
EndProcedure

// Procedure-event handler for" pre-Writing " registers for the mechanism for registering objects on nodes.
//
// Parameters:
//  Source       - InformationRegisterRecordSet - event source.
//  Cancel          - Boolean - flag for refusing to execute the handler.
//  Replacing      - Boolean - indicates whether an existing record set is being replaced.
// 
Procedure SyncDataViaUniversalFormatBeforeWritingRecordset(Source, Cancel, Replacing) Export
	
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister("DataSynchronizationViaUniversalFormat", Source, Cancel, Replacing);
	
EndProcedure

#EndRegion

#Region RegistrationRuleHandlers

// Parameters of the handlers of the registration rules "Onboarding" and "Onboarding Additional"
//

// Initialize the parameters of the PRO processing.
// 
// Returns:
//  Structure:
// * AccountingSectionsByLine - String - Comma-separated list of accounting sections to filter by
// * QueryText - String - The text of the request to the IB for calculating the array of recipient nodes
// * QueryOptions - Structure - A structure with filled-in information security request parameters for calculating recipient nodes:
//      **Query - String
// * UseCache - Boolean - Cache usage flag
// * Cancel - Boolean - flag for refusing to execute the handler
// * Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet 
//          - Undefined- The object for which the registration rules are executed
// * Upload0 - Boolean - - Flag that determines whether an object is being recorded or unloaded
Function InitializeDataProcessingParameters() Export
	
	ProcessingParameters = New Structure();
	ProcessingParameters.Insert("AccountingSectionsByLine", 			 "");
	ProcessingParameters.Insert("QueryText",       			 "");
	ProcessingParameters.Insert("QueryOptions",   			 New Structure());
	ProcessingParameters.Insert("UseCache",     			 False);
	ProcessingParameters.Insert("Cancel",               			 False);
	ProcessingParameters.Insert("Object",              			 Undefined);
	ProcessingParameters.Insert("Upload0",           			 False);
	ProcessingParameters.Insert("UseDocumentSelection", False);
	Return ProcessingParameters;
	
EndFunction

// The procedure is the handler of the "Preprocessing" event.
// Called from the rules of registration of the synchronization exchange plan of the above-mentioned Universal format.

// When processing PRO.
// 
// Parameters:
//  DataProcessingParameters - See InitializeDataProcessingParameters
// 
// Returns:
// 	See InitializeDataProcessingParameters
//
Function WhenProcessingData(DataProcessingParameters) Export
	
	// We adapt the text of the request taking into account the accounting sections.
	SubqueryAccountingSections = "";
	ArrayOfAccountingSections   = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataProcessingParameters.AccountingSectionsByLine,,True);
	
	DataProcessingParameters.UseCache = False;
	QueryText                          = DataProcessingParameters.QueryText;
	
	If Not ArrayOfAccountingSections.Count() = 0 Then
		
		SectionNumber = 1;
		For Each AccountingSection In ArrayOfAccountingSections Do
			
			DataProcessingParameters.QueryOptions.Insert("AccountingSection"+SectionNumber, TrimAll(AccountingSection));
			SubqueryAccountingSections = SubqueryAccountingSections + ?(SubqueryAccountingSections = "", "", Chars.LF + "OR ")
			+ "ExchangePlanAccountingSections.AccountingSection = &ObjectProperty1_AccountingSection" + SectionNumber;
			SectionNumber = SectionNumber + 1;
			
		EndDo;
		
		If ArrayOfAccountingSections.Count() > 1 Then
			SubqueryAccountingSections = "(" + SubqueryAccountingSections + ")";
		EndIf;
		
		LeftConnectionText = "AS ExchangePlanMainTable
		|LEFT JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.AccountingSections AS ExchangePlanAccountingSections
		|ON ExchangePlanMainTable.Ref = ExchangePlanAccountingSections.Ref
		|	AND " + SubqueryAccountingSections + "
		|	AND ExchangePlanAccountingSections.ToExport";
		
		TextOfConditionsForAccountingSections = "	AND ISNULL(ExchangePlanAccountingSections.ToExport, FALSE)
		|[MandatoryConditions]";
	EndIf; 
	
	QueryText = StrReplace(QueryText, "AS ExchangePlanMainTable", LeftConnectionText);
		
	MetadataObject = Metadata.FindByType(TypeOf(DataProcessingParameters.Object));
	If Not Common.IsDocument(MetadataObject) Then
	     Return DataProcessingParameters;
	EndIf;
	MetaExchangePlan = Metadata.ExchangePlans.DataSynchronizationViaUniversalFormat;
	UseFilterByAccountingSectionAndDocument = MetaExchangePlan.Attributes.Find("UseFilterByAccountingSectionAndDocument");
			
	RegistrationObject = DataProcessingParameters.Object;
	DataProcessingParameters.QueryOptions.Insert("MetadataObjectName", RegistrationObject.Metadata().Name);
	LeftConnectionText = "AS ExchangePlanMainTable  
	    |LEFT JOIN ExchangePlan.DataSynchronizationViaUniversalFormat.DocumentsKinds AS DataSynchronizationViaUniversalDocumentTypesFormat
		|	ON DataSynchronizationViaUniversalDocumentTypesFormat.Ref = ExchangePlanMainTable.Ref
		|"; 
		
	TextOfSelectionConditionsForDocuments = "AND CASE
		|		WHEN ExchangePlanMainTable.UseFilterByAccountingSectionAndDocument
		|			THEN DataSynchronizationViaUniversalDocumentTypesFormat.MetadataObjectName = &ObjectProperty1_MetadataObjectName
		|		WHEN NOT ExchangePlanMainTable.UseFilterByAccountingSectionAndDocument  THEN
	    |	      TRUE
		|	END
		|[MandatoryConditions]";
	
	QueryText = StrReplace(QueryText, "AS ExchangePlanMainTable", LeftConnectionText); 
	QueryText = StrReplace(QueryText, "[MandatoryConditions]", TextOfSelectionConditionsForDocuments);
    If Not ArrayOfAccountingSections.Count() = 0 Then
	     QueryText = StrReplace(QueryText, "[MandatoryConditions]", TextOfConditionsForAccountingSections);
	EndIf;
		
	DataProcessingParameters.QueryText = QueryText;
	
	Return DataProcessingParameters;
	
EndFunction

Procedure DocumentAdvanceReportBeforeProcessingPro(Object, Cancel) Export
	
	If Object.PaymentToVendors.Count() = 0 
		And Object.OtherExpenses.Count() = 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

// The method performs the registration of the Debt offset document after the ABM handlers are executed.
//
// Parameters:
//  Object - DocumentObject.ARAPSettlement - the registered object.
//  Upload0 - Boolean - Flag indicating that the object is being unloaded.
//  Recipients - Array of ExchangePlanRef - Array of links to exchange plan nodes where the object needs to be registered
//  ExchangePlanName - String - The name of the exchange plan for which the PRO is being performed.
//
Procedure DocumentDebtOffsetAfterProcessing(Object, Upload0, Recipients, ExchangePlanName) Export
	
	If Upload0 Or Recipients.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query("SELECT 
		|RelatedDocuments.Ref AS Ref
		|FROM
		|	FilterCriterion.RelatedDocuments(&FilterCriteriaValue) AS RelatedDocuments
		|WHERE
		|	VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.IssuedTaxInvoicePrepayment)
		|	OR VALUETYPE(RelatedDocuments.Ref) = TYPE(Document.ReceivedTaxInvoicePrepayment)");
		
	Query.SetParameter("FilterCriteriaValue",Object.Ref);
	
	Result = Query.Execute().Select();
	While Result.Next() Do
		TaxInvoice = Result.Ref.GetObject();
		DataExchangeEvents.ExecuteRegistrationRulesForObject(TaxInvoice, ExchangePlanName, Undefined);
	EndDo;
	
EndProcedure
Procedure DocumentInvoiceReceivedBeforeProcessingPro(Object, Cancel) Export
	AcceptableTypesOfFoundationDocuments = New Array;
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.VendorInvoice"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.ReturnOfGoodsFromCustomer"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.ReturnOfGoodsToVendor"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.ConsignmentReportFromCustomer"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.ConsignmentReportToVendor"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.SubcontractorReport2_5"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.RedemptionOfGoodsFromStorage"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.PurchaseAdjustment"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.CustomerInvoiceIntercompany"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.IntercompanyGoodsReturn"));
	AcceptableTypesOfFoundationDocuments.Add(Type("DocumentRef.CommissionReportIntercompany"));

	DocumentIsNotCorrect = False;
	For Each String In Object.BasisDocuments Do
		
		DocumentBasis = String.DocumentBasis;
		
		If Not ValueIsFilled(DocumentBasis)
			Or Not DocumentBasis.Posted Then
			Continue;
		EndIf;
		
		If AcceptableTypesOfFoundationDocuments.Find(TypeOf(DocumentBasis)) = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportFromCustomer")
			Or TypeOf(DocumentBasis) = Type("DocumentRef.ConsignmentReportToVendor")
			Or TypeOf(DocumentBasis) = Type("DocumentRef.CommissionReportIntercompany") Then
			If Common.ObjectAttributeValue(DocumentBasis, "DocumentAmount") <= 0 Then
				Continue;
			EndIf;
			ThereAreProducts_ = False;
			GoodsOfFoundationDocument = Common.ObjectAttributeValue(DocumentBasis, "Goods");
			GoodsOfFoundationDocument = GoodsOfFoundationDocument.Unload();
			For Each LineProducts_ In GoodsOfFoundationDocument Do
				
				ItemsType = Undefined;
				If ValueIsFilled(LineProducts_.Products) Then
					ItemsType = Common.ObjectAttributeValue(LineProducts_.Products, "ItemsType");
				Else
					Continue;
				EndIf;
				
				If ItemsType = Enums.ItemsTypes.OwnGoods Then
					ThereAreProducts_ = True;
					Break;
				EndIf;
			EndDo;
			If Not ThereAreProducts_ Then
				Continue;
			EndIf;
		ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
				Continue;
		EndIf;
		DocumentIsNotCorrect = True;
		Break;
		
	EndDo;
	If Not DocumentIsNotCorrect Then
		Cancel = True;
	EndIf;
EndProcedure

Procedure DocumentReportOfCommissionAgentToCommitteeWhenProcessingPro(Object, Cancel) Export
	ThereAreProducts_ = False;
	For Each LineProducts_ In Object.Goods Do
		
		ItemsType = Undefined;
		If ValueIsFilled(LineProducts_.Products) Then
			ItemsType = Common.ObjectAttributeValue(LineProducts_.Products, "ItemsType");
		Else
			Continue;
		EndIf;
		
		If (ItemsType = Enums.ItemsTypes.OwnGoods 
				And LineProducts_.Count <> 0) Then
			ThereAreProducts_ = True;
			Break;
		EndIf;
		
	EndDo;
	If Not ThereAreProducts_ Then
		Cancel = True;
	EndIf;
EndProcedure
Procedure DocumentARAPSettlementBeforeProcessingORR(Object, Cancel) Export 
	CounterOffsetOfDebtOfOrganizations = (Object.OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies);
	
	ManyToManySettlement = (Object.OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies  
	Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies);
	If ManyToManySettlement Or CounterOffsetOfDebtOfOrganizations Then
		Cancel = True;
	EndIf;
EndProcedure
Procedure DocumentBackflushedProductionBeforeProcessingPRO(Object, Cancel) Export 
	If Not Object.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	COUNT(BackflushProductionManufacturedProducts.Products) AS RowsCount
		|FROM
		|	Document.BackflushProduction.ManufacturedProducts AS BackflushProductionManufacturedProducts
		|WHERE
		|	BackflushProductionManufacturedProducts.Ref = &Ref
		|	AND BackflushProductionManufacturedProducts.InternalSubcontracting
		|";
		
		Query.SetParameter("Ref", Object.Ref);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Return
		Else	
			SelectionDetailRecords = QueryResult.Select();   
			If SelectionDetailRecords.Next() Then
				NumberOfLinesOfInternalProcessing = SelectionDetailRecords.RowsCount;
				If Object.ManufacturedProducts.Count() = NumberOfLinesOfInternalProcessing Then
					Cancel = True;
				EndIf;	
			EndIf;
		EndIf;
		
	EndIf;
EndProcedure
// Document "Reverse" event "Before processing PRO"
// 
// Parameters:
//  Object - DocumentObject.ReversingEntry - Registered object
//  Cancel - Boolean - Flag indicating whether it is necessary to refuse to unload the object
//
Procedure DocumentIsStornoBeforeProcessingABOUT(Object, Cancel) Export
	
	Cancel = True;
	
	UnsupportedDocumentTypes = New Array;
	
	UnsupportedDocumentTypes.Add(Type("DocumentRef.CustomerInvoiceIntercompany"));
	UnsupportedDocumentTypes.Add(Type("DocumentRef.IntercompanyGoodsReturn"));
	UnsupportedDocumentTypes.Add(Type("DocumentRef.CommissionReportIntercompany"));
	UnsupportedDocumentTypes.Add(Type("DocumentRef.CommissionWriteOffReportIntercompany"));
	UnsupportedDocumentTypes.Add(Type("DocumentRef.GoodsShipmentToCustomer"));
	
	ExchangePlanContent = Metadata.ExchangePlans.DataSynchronizationViaUniversalFormat.Content;
	
	If Common.RefExists(Object.ReversedDocument) 
		And UnsupportedDocumentTypes.Find(TypeOf(Object.ReversedDocument)) = Undefined
		And ExchangePlanContent.Find(Object.ReversedDocument.Metadata()) <> Undefined Then
		
		Cancel = False;
		
	EndIf;
	
EndProcedure
#EndRegion

#EndRegion