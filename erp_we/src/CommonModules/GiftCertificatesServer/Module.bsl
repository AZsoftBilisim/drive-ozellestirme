
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	//Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GiftCertificates);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.GiftCardHistory);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.ActivatingGiftCertificates);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.GiftCertificates);
	EndIf;
			
	Return Parameters;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of KeyAndValue:
//		* Key - String
//		* Value - String - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableGiftCertificates", 
		AccumulationRegisters.GiftCertificates.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
//	Map of KeyAndValue:
//		* Key - String
//		* Value - String - Matching the full register name to the text of the reversal request.
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.GiftCertificates;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),	
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of gift certificates.
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
	
	#Region GiftCertificates
	
	TableName = "Table" + "GiftCertificates";
	
	If TablesForRegisteredRecords.Property(TableName)
		And ValueIsFilled(TablesForRegisteredRecords[TableName]) Then
		
		RegisterRecords.GiftCertificates.Write = True;
		RegisterRecords.GiftCertificates.Load(TablesForRegisteredRecords[TableName]);
		
	EndIf;
	
	#EndRegion
	
	#Region GiftCardHistory
	
	TableName = "Table" + "GiftCardHistory";
	
	If TablesForRegisteredRecords.Property(TableName)
		And ValueIsFilled(TablesForRegisteredRecords[TableName]) Then
		
		RegisterRecords.GiftCardHistory.Write = True;
		RegisterRecords.GiftCardHistory.Load(TablesForRegisteredRecords[TableName]);
		
	EndIf;
	
	#EndRegion
	
	#Region ActivatingGiftCertificates
	
	TableName = "Table" + "ActivatingGiftCertificates";
	
	If TablesForRegisteredRecords.Property(TableName)
		And ValueIsFilled(TablesForRegisteredRecords[TableName]) Then
		
		RegisterRecords.ActivatingGiftCertificates.Write = True;
		RegisterRecords.ActivatingGiftCertificates.Load(TablesForRegisteredRecords[TableName]);
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
EndProcedure

#EndRegion

// The procedure writes a gift certificate to the database based
// on the passed structure with the gift certificate data.
//
// Parameters:
//  GiftCertificateDataStructure - See GiftCertificatesServerCall.InitializeGiftCertificateDescription
//
// Returns:
//  CatalogRef.GiftCertificates - A registered gift certificate.
//
Function RegisterGiftCertificate(GiftCertificateDataStructure) Export
	
	SetPrivilegedMode(True);
	
	GiftCertificateObject = Catalogs.GiftCertificates.CreateItem();
	
	GiftCertificateObject.Barcode      = GiftCertificateDataStructure.Barcode;
	GiftCertificateObject.MagneticCode  = GiftCertificateDataStructure.MagneticCode;
		
	GiftCertificateObject.Owner      = GiftCertificateDataStructure.GiftCertificateKind;
	If ValueIsFilled(GiftCertificateDataStructure.SerialNumber) Then
		GiftCertificateObject.Code = GiftCertificateDataStructure.SerialNumber;
	EndIf;
	
	GiftCertificateObject.Description = String(GiftCertificateObject.Owner)
	                                        + ?(ValueIsFilled(GiftCertificateObject.Barcode), " " + String(GiftCertificateObject.Barcode), "")
	                                        + ?(ValueIsFilled(GiftCertificateObject.MagneticCode), " " + String(GiftCertificateObject.MagneticCode), "");
	GiftCertificateObject.Write();
	
	Return GiftCertificateObject.Ref;
	
EndFunction

// The function returns the gift certificate code type, if only it
// is used in gift certificate types.
//
// Returns:
//  EnumRef.CardCodeTypes, Undefined - The main type of gift certificate code.
//
Function GetBasicTypeOfGiftCertificateCode() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT DISTINCT
	|	GiftCertificateKinds.CardType AS CardType
	|FROM
	|	Catalog.GiftCertificateKinds AS GiftCertificateKinds");
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	Count = Selection.Count();
	If Count = 0 Then
		Return Undefined;
	ElsIf Count = 1 Then
		Selection.Next();
		If Selection.CardType = Enums.CardTypes.Barcode_ Then
			Return Enums.CardCodeTypes.Barcode;
		ElsIf Selection.CardType = Enums.CardTypes.Magnetic Then
			Return Enums.CardCodeTypes.MagneticCode;
		ElsIf Selection.CardType = Enums.CardTypes.Mixed Then
			Return Undefined;
		Else
			Return Undefined;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Procedure for checking the filling of gift certificates/settlement objects in the tabular parts of documents.
//
// Parameters:
//  Object - DocumentObject - Current document.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure FillCheckProcessing(Object, Cancel) Export
	
	ObjectReferenceType = TypeOf(Object.Ref); // DocumentObject
	If ObjectReferenceType = Type("DocumentRef.GiftCertificateSale")
		Or ObjectReferenceType = Type("DocumentRef.GiftCertificateCancellation")
		Or ObjectReferenceType = Type("DocumentRef.OBEntry") 
		Or ObjectReferenceType = Type("DocumentRef.OBEntrySalesForPastPeriods")
		Or ObjectReferenceType = Type("DocumentRef.ReturnOfGiftCards")
		Or ObjectReferenceType = Type("DocumentRef.CashRegisterReceipt")
		Or ObjectReferenceType = Type("DocumentRef.RetailSalesReport") Then
			
		CheckCompletionOfTablePartGiftCertificates(Object, Cancel);
		
	ElsIf ObjectReferenceType = Type("DocumentRef.OBEntryARAP") Then
		
		CheckCompletionOfTabularPartOfPaymentDecryption(Object, Cancel);
		
	ElsIf (ObjectReferenceType = Type("DocumentRef.CashAccountReceiptNote")
				Or ObjectReferenceType = Type("DocumentRef.BankAccountReceiptNote")
				Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction"))
			And Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
				
		CheckCompletionOfTabularPartOfPaymentDecryption(Object, Cancel);
		
	ElsIf (ObjectReferenceType = Type("DocumentRef.CashVoucher")
				Or ObjectReferenceType = Type("DocumentRef.BankAccountIssue")
				Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction")
				Or ObjectReferenceType = Type("DocumentRef.PaymentRequest"))
			And Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		
		CheckCompletionOfTabularPartOfPaymentDecryption(Object, Cancel);
		
	ElsIf ObjectReferenceType = Type("DocumentRef.ARAPSettlement") Then
		
		NumberOfGiftCards = CheckCompletionOfTabularPartOfPaymentDecryption(Object, Cancel);
		If NumberOfGiftCards Then
			If (Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties) Then
				If Not Object.CounterpartyDebtor = Catalogs.Counterparties.RetailCustomer Then

					ErrorText = NStr("vi = 'Khi bán phiếu quà tặng, khách hàng nhận quà phải ghi rõ là Khách lẻ';
									|ru = 'При продаже подарочного сертификата клиентом-получателем должен быть указан Розничный покупатель';
									|en = 'When selling a gift card, the recipient customer must be a retail customer'; fa = 'When selling a gift card, the recipient customer must be a retail customer';
									|it = 'When selling a gift card, the recipient customer must be a retail customer';
									|pl = 'When selling a gift card, the recipient customer must be a retail customer';
									|tr = 'Hediye çeki satışında müşteri-alıcı olarak Perakende alıcı belirtilmelidir.'");
					Common.MessageToUser(
							ErrorText,
							Object,
							"CounterpartyDebtor",
							,
							Cancel);
					
				EndIf;
			EndIf;
		EndIf;	
		
	EndIf;
	
EndProcedure

// The procedure performs filling in the "Summavalutesertificate" details in the table part of the gift Certificates.
//
// Parameters:
//	TabularSection - TabularSection - gift certificate.
//	Organization - CatalogRef.Companies - Organization of the document.
//	Date - Date - document date.
//	Currency - CatalogRef.Currencies - the currency of the document.
//
Procedure FillInAmountInCertificateCurrencyInTablePart(TabularSection, Organization, Date, Currency) Export
	
	Query = New Query("
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.Sum AS Sum,
	|	DocumentTable.AmountInCertificateCurrency AS AmountInCertificateCurrency,
	|	DocumentTable.GiftCertificate AS GiftCertificate
	|INTO DocumentTable
	|FROM
	|	&DocumentTable AS DocumentTable
	|WHERE
	|	DocumentTable.AmountInCertificateCurrency = 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|	
	|SELECT
	|	DocumentTable.LineNumber AS LineNumber,
	|
	|	CASE WHEN DocumentTable.AmountInCertificateCurrency = 0 THEN
	|		(DocumentTable.Sum *
	|		ISNULL(DocumentExchangeRates.CourseNumerator, 1) * 
	|		ISNULL(ExchangeRates.CourseDenominator, 1)
	|		) / (
	|		ISNULL(ExchangeRates.CourseNumerator, 1) * 
	|		ISNULL(DocumentExchangeRates.CourseDenominator, 1)
	|		)
	|	ELSE
	|		DocumentTable.AmountInCertificateCurrency
	|	END AS AmountInCertificateCurrency
	|FROM
	|	DocumentTable AS DocumentTable
	|	
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS DocumentExchangeRates
	|	ON
	|		TRUE
	|		
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Date, BaseCurrency = &BaseCurrency) AS ExchangeRates
	|	ON
	|		DocumentTable.GiftCertificate.Owner.Currency = ExchangeRates.Currency
	|
	|ORDER BY
	|	DocumentTable.LineNumber
	|;
	|");
	
	Query.Parameters.Insert("DocumentTable", TabularSection.Unload());
	Query.SetParameter("Date", Date);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	// We will get a table of the document with the calculated amount of mutual settlements.
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TableRow = TabularSection.Find(Selection.LineNumber, "LineNumber");
		FillPropertyValues(TableRow, Selection, ,"LineNumber");
		
	EndDo;
	
EndProcedure

// Process the gift certificate when selecting the Payment Decryption in the table part.
// Parameters:
//  GiftCertificate - CatalogRef.GiftCertificates - 
//  Form - ClientApplicationForm - 
// 
// Returns:
//	LineOfATabularSection, Undefined - 
//
Function AddGiftCertificateToTablePartOfPaymentDecryption(GiftCertificate, Form) Export
	
	FoundRow = Undefined;

	FormObjectReference = Form.Object.Ref; // DocumentRef
	TypeOfFormObjectReference = TypeOf(FormObjectReference);
	
	Processed_Types = New Array;
	Processed_Types.Add(Type("DocumentRef.CashAccountReceiptNote"));
	Processed_Types.Add(Type("DocumentRef.CashVoucher"));
	Processed_Types.Add(Type("DocumentRef.BankAccountReceiptNote"));
	Processed_Types.Add(Type("DocumentRef.BankAccountIssue"));
	Processed_Types.Add(Type("DocumentRef.PaymentCardTransaction"));
	Processed_Types.Add(Type("DocumentRef.PaymentRequest"));
	
	If Not Processed_Types.Find(TypeOfFormObjectReference) = Undefined Then
		 
		Query = New Query(
		"SELECT
		|	ARAPObjects.Ref                 AS ARAPObject,
		|	
		|	GiftCertificates.Owner.Currency  AS ARAPCurrency,
		|	GiftCertificates.Owner.Nominal AS AmountARAP,
		|	GiftCertificates.Owner.Nominal AS Sum,
		|	GiftCertificates.Owner.CashFlowItemSale AS CashFlowItemSale,
		|	GiftCertificates.Owner.CashFlowItemReturn AS CashFlowItemReturn
		|	
		|FROM
		|	Catalog.GiftCertificates AS GiftCertificates
		|
		|INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|	ON ARAPObjects.Object = GiftCertificates.Ref
		|
		|WHERE
		|	GiftCertificates.Ref = &Ref
		|");
		
		Query.SetParameter("Ref", GiftCertificate);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		TabularSection = Form.Object.ARAPDetails;
		If Selection.Next() Then
			
			FoundRows = TabularSection.FindRows(New Structure("ARAPObject", Selection.ARAPObject));
			If FoundRows.Count() = 0 Then
				If TabularSection.Count() = 1
					And Not ValueIsFilled(TabularSection[0].ARAPObject) Then
					FoundRow = TabularSection[0];
				Else
					FoundRow = TabularSection.Add();
					If TypeOfFormObjectReference = Type("DocumentRef.CashVoucher") 
						Or TypeOfFormObjectReference = Type("DocumentRef.PaymentRequest") Then
						FoundRow.VATTaxation = Form.Object.VATTaxation;
					EndIf;
				EndIf;
			Else
				FoundRow = FoundRows[0];
			EndIf;
			
			If Not TypeOfFormObjectReference = Type("DocumentRef.PaymentCardTransaction") Then
				FoundRow.Organization    = Form.Object.Organization;
			EndIf;
			FoundRow.Partner        = Catalogs.Partners.RetailCustomer;
			If ValueIsFilled(Form.Partner) Then
				// The Attribute of the Partner form is used, because the Attribute of the object in the documents of the processed types 
				// is filled in before recording (from the decryption of the payment or as the main partner of the counterparty).
				FoundRow.Partner    = Form.Partner;
			EndIf;
			FoundRow.ARAPObject = Selection.ARAPObject;
			FoundRow.Sum          = Selection.Sum;
			
			FoundRow.ARAPCurrency = Selection.ARAPCurrency;
			FoundRow.AmountARAP  = Selection.AmountARAP;
			
			FoundRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			FoundRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
			
			If Form.Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
				FoundRow.CashFlowItem = Selection.CashFlowItemSale;
			Else
				FoundRow.CashFlowItem = Selection.CashFlowItemReturn;
			EndIf;
			
			If TypeOfFormObjectReference = Type("DocumentRef.CashVoucher") 
				Or TypeOfFormObjectReference = Type("DocumentRef.PaymentRequest") Then
					
				If Not ValueIsFilled(FoundRow.VATRate) Then
					FoundRow.VATRate = VATAccountingERP.DefaultVATRate(Form.Object.Organization, Form.Object.Date, True);
					
					StructureOfActionParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Form.Object);
					StructureOfActions = New Structure;
					StructureOfActions.Insert("FillInVATRate", StructureOfActionParameters);
					BatchProcessingOfTablePartServer.ProcessTSString(FoundRow, StructureOfActions, Undefined);
				EndIf;
				
			ElsIf TypeOfFormObjectReference = Type("DocumentRef.PaymentCardTransaction") Then
				
				If Not ValueIsFilled(FoundRow.VATAmount) Then
					FoundRow.VATRate = VATAccountingERP.DefaultVATRate(Form.Object.Organization, Form.Object.Date, True);
					StructureOfRecalculationOfAmount = New Structure;
					StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					BatchProcessingOfTablePartServer.ProcessTSString(FoundRow, StructureOfActions, Undefined);
				EndIf;
				
			Else
				
				FoundRow.VATRate = VATAccountingERP.DefaultVATRate(Form.Object.Organization, Form.Object.Date, True);
				
			EndIf;
		EndIf;
	EndIf;
	
	Return FoundRow;
EndFunction

#Region SearchForGiftCertificates

// Searches for types of gift certificates that can have the specified code and code type.
//
// Parameters:
//  CardCode - String - Card code.
//  CodeType - EnumRef.CardCodeTypes - Type of map code.
//
// Returns:
//  Array of CatalogRef.GiftCertificateKinds - Links to the found types of gift certificates.
//
Function GetPossibleTypesOfGiftCertificatesByGiftCertificateCode(CardCode, CodeType) Export
	
	SetPrivilegedMode(True);
	
	GiftCertificateKinds = New Array;
	
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		Query = New Query(
		"SELECT
		|	GiftCertificateCodeTemplates.Ref AS GiftCertificateKind
		|FROM
		|	Catalog.GiftCertificateKinds.GiftCertificateCodeTemplates AS GiftCertificateCodeTemplates
		|WHERE
		|	  GiftCertificateCodeTemplates.StartOfMagneticCodeRange <= &CardCode
		|	AND GiftCertificateCodeTemplates.EndOfMagneticCodeRange  >= &CardCode
		|	AND GiftCertificateCodeTemplates.MagneticCodeLength = &CodeLength
		|
		|ORDER BY
		|	StartOfMagneticCodeRange");
	Else
		Query = New Query(
		"SELECT
		|	GiftCertificateCodeTemplates.Ref AS GiftCertificateKind
		|FROM
		|	Catalog.GiftCertificateKinds.GiftCertificateCodeTemplates AS GiftCertificateCodeTemplates
		|WHERE
		|	GiftCertificateCodeTemplates.StartOfBarcodeRange <= &CardCode
		|	AND GiftCertificateCodeTemplates.EndOfBarcodeRange >= &CardCode
		|	AND GiftCertificateCodeTemplates.BarcodeLength = &CodeLength
		|
		|ORDER BY
		|	GiftCertificateCodeTemplates.StartOfBarcodeRange");
	EndIf;

	Query.SetParameter("CardCode",  String(CardCode));
	Query.SetParameter("CodeLength", StrLen(String(CardCode)));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		GiftCertificateKinds.Add(Selection.GiftCertificateKind);
	EndDo;
	
	Return GiftCertificateKinds;
	
EndFunction

// Searches for gift certificates.
//
// Parameters:
//  CardCode - String - The card code of the gift certificate.
//  CodeType - EnumRef.CardCodeTypes - Type of gift certificate card code.
//  Filters - Structure - Additional selections for the search.
//
// Returns:
//  Structure - structure with properties:
//   * RegisteredGiftCertificates - Array of See GiftCertificatesServerCall.InitializeGiftCertificateDescription - 
//   * NotRegisteredGiftCertificates - Array of See GiftCertificatesServerCall.InitializeGiftCertificateDescription - 
//
Function FindGiftCertificates(CardCode, CodeType, Filters = Undefined) Export
	
	SetPrivilegedMode(True);
	
	RegisteredGiftCertificates = New Array;
	NotRegisteredGiftCertificates = New Array;
	
	Query = New Query(
	"SELECT DISTINCT
	|	GiftCertificateCodeTemplates.Ref                            AS Ref,
	|	GiftCertificateCodeTemplates.Ref.ActionPeriod             AS ActionPeriod,
	|	GiftCertificateCodeTemplates.Ref.NumberOfValidityPeriods AS NumberOfValidityPeriods,
	|	GiftCertificateCodeTemplates.Ref.Nominal                    AS Nominal,
	|	GiftCertificateCodeTemplates.Ref.Currency                     AS Currency,
	|	GiftCertificateCodeTemplates.Ref.CardType                   AS CardType,
	|	GiftCertificateCodeTemplates.Ref.ProductSegment        AS ProductSegment,
	|	GiftCertificateCodeTemplates.Ref.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificateCodeTemplates.Ref.PartialPayment            AS PartialPayment,
	|	GiftCertificateCodeTemplates.Ref.CashFlowItemSale AS CashFlowItemSale,
	|	GiftCertificateCodeTemplates.Ref.CashFlowItemReturn AS CashFlowItemReturn,
	|	GiftCertificateCodeTemplates.Ref.IncomeItem	AS IncomeItem,
	|	GiftCertificateCodeTemplates.Ref.DimensionOfRevenue	AS DimensionOfRevenue,
	|
	|	GiftCertificateCodeTemplates.Ref.Organization                AS Organization
	|INTO GiftCertificateKinds
	|FROM
	|	Catalog.GiftCertificateKinds.GiftCertificateCodeTemplates AS GiftCertificateCodeTemplates
	|WHERE
	|	&StartOfRangeCondition                    <= &CardCode
	|	AND &EndOfRangeCondition                   >= &CardCode
	|	AND &ConditionCodeLength                         = &CodeLength
	|	AND &SelectionConditionCurrency
	|	AND &SelectionConditionAccountingForGiftCertificates2_5
	|	AND GiftCertificateCodeTemplates.Ref.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref                AS Ref,
	|	GiftCertificates.Description          AS Description,
	|	GiftCertificates.MagneticCode          AS MagneticCode,
	|	GiftCertificates.Barcode              AS Barcode,
	|	GiftCertificates.Code                   AS SerialNumber,
	|	ISNULL(ARAPObjects.Ref, VALUE(Catalog.ARAPObjects.EmptyRef)) AS ARAPObject,
	|	ISNULL(ARAPObjects.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Partner,
	|	CASE
	|		WHEN GiftCertificateKinds.GiftCardAccounting25
	|			THEN VALUE(Enum.GiftCertificateStatuses.EmptyRef)
	|		ELSE ISNULL(GiftCardHistory.Status, VALUE(Enum.GiftCertificateStatuses.NotActivated))
	|	END AS StatusFromHistoryOfGiftCertificates,
	|	ISNULL(ActivatingGiftCertificates.Active, FALSE) AS ActivationStatus,

	|	GiftCertificateKinds.Ref                            AS GiftCertificateKind,
	|	GiftCertificateKinds.ActionPeriod                    AS ActionPeriod,
	|	GiftCertificateKinds.NumberOfValidityPeriods        AS NumberOfValidityPeriods,
	|	GiftCertificateKinds.Nominal                           AS Nominal,
	|	GiftCertificateKinds.Currency                            AS Currency,
	|	GiftCertificateKinds.CardType                          AS CardType,
	|	GiftCertificateKinds.ProductSegment               AS ProductSegment,
	|	GiftCertificateKinds.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificateKinds.PartialPayment AS PartialPayment,
	|	GiftCertificateKinds.CashFlowItemSale AS CashFlowItemSale,
	|	GiftCertificateKinds.CashFlowItemReturn AS CashFlowItemReturn,
	|	GiftCertificateKinds.IncomeItem AS IncomeItem,
	|	GiftCertificateKinds.DimensionOfRevenue AS DimensionOfRevenue,
	|	ISNULL(ActivatingGiftCertificates.Organization, CASE
	|			WHEN GiftCertificateKinds.GiftCardAccounting25
	|				THEN GiftCertificateKinds.Organization
	|			ELSE VALUE(Catalog.Companies.EmptyRef)
	|		END) AS Organization,
	|
	|	ISNULL(ActivatingGiftCertificates.ValidityStartDate, DATETIME(1,1,1)) AS ValidityStartDate,
	|	ISNULL(ActivatingGiftCertificates.ValidityEndDate, DATETIME(1,1,1)) AS ValidityEndDate
	|
	|INTO GiftCertificates
	|FROM
	|	Catalog.GiftCertificates AS GiftCertificates
	|
	|		INNER JOIN GiftCertificateKinds
	|		ON GiftCertificateKinds.Ref  = GiftCertificates.Owner
	|
	|		LEFT JOIN InformationRegister.ActivatingGiftCertificates AS ActivatingGiftCertificates
	|		ON ActivatingGiftCertificates.GiftCertificate = GiftCertificates.Ref	
	|		LEFT JOIN InformationRegister.GiftCardHistory.SliceLast(,) AS GiftCardHistory
	|		ON GiftCardHistory.GiftCertificate = GiftCertificates.Ref
	|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON (ARAPObjects.Object = GiftCertificates.Ref)
	|	
	|WHERE
	| TRUE
	| AND &NameOfMapCodeField = &CardCode
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.ARAPObject AS ARAPObject
	|INTO OldStyleGiftCertificates
	|FROM
	|	GiftCertificates AS GiftCertificates
	|WHERE
	|	NOT GiftCertificates.GiftCardAccounting25
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS Ref,
	|	GiftCertificates.ARAPObject AS ARAPObject
	|INTO NewStyleGiftCertificates
	|FROM
	|	GiftCertificates AS GiftCertificates
	|WHERE
	|	GiftCertificates.GiftCardAccounting25
	|	AND NOT GiftCertificates.ARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
	|
	|INDEX BY
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateBalances.GiftCertificate AS GiftCertificate,
	|	CertificateBalances.SumBalance
	|INTO BalanceOfGiftCertificates
	|FROM
	|	AccumulationRegister.GiftCertificates.Balance(
	|		,
	|		GiftCertificate IN
	|			(SELECT
	|				T.Ref
	|			FROM
	|				OldStyleGiftCertificates AS T)) AS CertificateBalances
	|
	|UNION ALL
	|
	|SELECT
	|	CertificateBalances.ARAPObject.Object AS GiftCertificate,
	|	CASE WHEN CertificateBalances.SumBalance < 0 
	|		THEN -CertificateBalances.SumBalance
	|		ELSE CertificateBalances.SumBalance
	|	END	
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|		,
	|		ARAPObject IN
	|			(SELECT
	|				T.ARAPObject
	|			FROM
	|				NewStyleGiftCertificates AS T)) AS CertificateBalances
	|
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	CASE WHEN (GiftCertificates.Ref, TRUE) 
	|		IN (SELECT TOP 1
	|				T.GiftCertificate, 
	|				TRUE 
	|			FROM AccumulationRegister.GiftCertificates AS T
	|			WHERE
	|				T.Recorder REFS Document.GiftCertificateCancellation
	|				AND T.Active
	|				AND T.GiftCertificate = GiftCertificates.Ref) THEN TRUE ELSE FALSE END AS Canceled_,
	|	CASE WHEN (GiftCertificates.Ref, TRUE) 
	|		IN (SELECT TOP 1
	|				T.GiftCertificate, 
	|				TRUE 
	|			FROM AccumulationRegister.GiftCertificates AS T
	|			WHERE
	|				T.Recorder REFS Document.ReturnOfGiftCards
	|				AND T.Active
	|				AND T.Sum <> 0
	|				AND T.GiftCertificate = GiftCertificates.Ref) THEN TRUE ELSE FALSE END AS RefundIssued
	|INTO StateOfGiftCertificates
	|FROM
	|	OldStyleGiftCertificates AS GiftCertificates
	|
	|UNION ALL
	|
	|SELECT
	|	GiftCertificates.Ref AS GiftCertificate,
	|	CASE WHEN (GiftCertificates.ARAPObject, TRUE) 
	|		IN (SELECT TOP 1
	|				T.ARAPObject, 
	|				TRUE 
	|			FROM AccumulationRegister.CustomersARAPAccounting AS T
	|			WHERE
	|				T.Recorder REFS Document.GiftCertificateCancellation
	|				AND T.Active
	|				AND T.ARAPObject = GiftCertificates.ARAPObject) THEN TRUE ELSE FALSE END AS Canceled_,
	|	CASE WHEN (GiftCertificates.ARAPObject, TRUE) 
	|		IN (SELECT TOP 1
	|				T.ARAPObject, 
	|				TRUE 
	|			FROM AccumulationRegister.CustomersARAPAccounting AS T
	|			WHERE
	|				(T.Recorder REFS Document.ReturnOfGiftCards
	|				OR T.Recorder REFS Document.CashVoucher
	|				OR T.Recorder REFS Document.BankAccountIssue
	|				OR T.Recorder REFS Document.PaymentCardTransaction
	|				OR T.Recorder REFS Document.PaymentRequest)
	|				AND T.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|											VALUE(Enum.BusinessTransactions.SettlementOfPrepayment))
	|				AND T.Active
	|				AND T.Sum <> 0
	|				AND T.ARAPObject = GiftCertificates.ARAPObject) THEN TRUE ELSE FALSE END AS RefundIssued
	|FROM
	|	NewStyleGiftCertificates AS GiftCertificates
	|
	|INDEX BY
	|	GiftCertificate
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1                                           AS Order,
	|	GiftCertificates.Ref                AS Ref,
	|	GiftCertificates.Description          AS Description,
	|	GiftCertificates.MagneticCode          AS MagneticCode,
	|	GiftCertificates.Barcode              AS Barcode,
	
	|	GiftCertificates.SerialNumber         AS SerialNumber,
	|	GiftCertificates.StatusFromHistoryOfGiftCertificates AS StatusFromHistoryOfGiftCertificates,
	|	GiftCertificates.ActivationStatus         AS ActivationStatus,
	|	ISNULL(CertificateBalances.SumBalance, 0) AS Balance,
	|	
	|	GiftCertificates.GiftCertificateKind         AS GiftCertificateKind,
	|	GiftCertificates.ActionPeriod                    AS ActionPeriod,
	|	GiftCertificates.NumberOfValidityPeriods        AS NumberOfValidityPeriods,
	|	GiftCertificates.Nominal                           AS Nominal,
	|	GiftCertificates.Currency                            AS Currency,
	|	GiftCertificates.CardType                          AS CardType,
	|	GiftCertificates.ProductSegment               AS ProductSegment,
	|	GiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.PartialPayment                   AS PartialPayment,
	|	GiftCertificates.ValidityStartDate                AS ValidityStartDate,
	|	GiftCertificates.ValidityEndDate             AS ValidityEndDate,
	|	GiftCertificates.ARAPObject 					AS ARAPObject,
	|	GiftCertificates.Partner 							AS Partner,
	|	GiftCertificates.CashFlowItemSale AS CashFlowItemSale,
	|	GiftCertificates.CashFlowItemReturn AS CashFlowItemReturn,
	|	GiftCertificates.IncomeItem	AS IncomeItem,
	|	GiftCertificates.DimensionOfRevenue	AS DimensionOfRevenue,
	
	|	GiftCertificates.Organization						AS Organization,
	|	ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) AS RefundIssued,
	|	ISNULL(StateOfGiftCertificates.Canceled_, FALSE) AS Canceled_
	|FROM
	|	GiftCertificates AS GiftCertificates
	|   LEFT JOIN BalanceOfGiftCertificates AS CertificateBalances
	|	ON CertificateBalances.GiftCertificate = GiftCertificates.Ref
	|	LEFT JOIN StateOfGiftCertificates AS StateOfGiftCertificates
	|	ON GiftCertificates.Ref = StateOfGiftCertificates.GiftCertificate
	|	
	|WHERE
	|	NOT GiftCertificates.GiftCardAccounting25
	|	AND &SelectionCriteriaOrganizationByTypeOfOperation
	|	AND &SelectionConditionStatusFromHistoryOfGiftCertificates
	|
	|UNION ALL
	|
	|SELECT
	|	1                                           AS Order,
	|	GiftCertificates.Ref                AS Ref,
	|	GiftCertificates.Description          AS Description,
	|	GiftCertificates.MagneticCode          AS MagneticCode,
	|	GiftCertificates.Barcode              AS Barcode,
	
	|	GiftCertificates.SerialNumber         AS SerialNumber,
	|	GiftCertificates.StatusFromHistoryOfGiftCertificates AS StatusFromHistoryOfGiftCertificates,
	|	GiftCertificates.ActivationStatus         AS ActivationStatus,
	|	ISNULL(CertificateBalances.SumBalance, 0) AS Balance,
	|	
	|	GiftCertificates.GiftCertificateKind         AS GiftCertificateKind,
	|	GiftCertificates.ActionPeriod                    AS ActionPeriod,
	|	GiftCertificates.NumberOfValidityPeriods        AS NumberOfValidityPeriods,
	|	GiftCertificates.Nominal                           AS Nominal,
	|	GiftCertificates.Currency                            AS Currency,
	|	GiftCertificates.CardType                          AS CardType,
	|	GiftCertificates.ProductSegment               AS ProductSegment,
	|	GiftCertificates.GiftCardAccounting25 AS GiftCardAccounting25,
	|	GiftCertificates.PartialPayment                   AS PartialPayment,
	|	GiftCertificates.ValidityStartDate                AS ValidityStartDate,
	|	GiftCertificates.ValidityEndDate             AS ValidityEndDate,
	|	GiftCertificates.ARAPObject 					AS ARAPObject,
	|	GiftCertificates.Partner 							AS Partner,
	|	GiftCertificates.CashFlowItemSale AS CashFlowItemSale,
	|	GiftCertificates.CashFlowItemReturn AS CashFlowItemReturn,
	|	GiftCertificates.IncomeItem	AS IncomeItem,
	|	GiftCertificates.DimensionOfRevenue	AS DimensionOfRevenue,
	
	|	GiftCertificates.Organization						AS Organization,
	|	ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) AS RefundIssued,
	|	ISNULL(StateOfGiftCertificates.Canceled_, FALSE) AS Canceled_
	|FROM
	|	GiftCertificates AS GiftCertificates
	|   LEFT JOIN BalanceOfGiftCertificates AS CertificateBalances
	|	ON CertificateBalances.GiftCertificate = GiftCertificates.Ref
	|	LEFT JOIN StateOfGiftCertificates AS StateOfGiftCertificates
	|	ON GiftCertificates.Ref = StateOfGiftCertificates.GiftCertificate
	|	
	|WHERE
	|	GiftCertificates.GiftCardAccounting25
	|	AND &SelectionConditionOrganization
	|	AND &SelectionCriteriaByTypeOfOperation
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                         AS Order,
	|	VALUE(Catalog.GiftCertificates.EmptyRef)   AS Ref,
	|	UNDEFINED                                              AS Description,
	|	&MagneticCode                                             AS MagneticCode,
	|	&Barcode                                                 AS Barcode,
	|	UNDEFINED                                                       AS SerialNumber,
	|	VALUE(Enum.GiftCertificateStatuses.NotActivated) AS StatusFromHistoryOfGiftCertificates,
	|	FALSE                                                               AS ActivationStatus,
	|	0                                                                  AS Balance,
	|	
	|	GiftCertificateKinds.Ref                            AS GiftCertificateKind,
	|	GiftCertificateKinds.ActionPeriod                    AS ActionPeriod,
	|	GiftCertificateKinds.NumberOfValidityPeriods        AS NumberOfValidityPeriods,
	|	GiftCertificateKinds.Nominal                           AS Nominal,
	|	GiftCertificateKinds.Currency                            AS Currency,
	|	GiftCertificateKinds.CardType                          AS CardType,
	|	GiftCertificateKinds.ProductSegment               AS ProductSegment,
	|	GiftCertificateKinds.GiftCardAccounting25     AS GiftCardAccounting25,
	|	GiftCertificateKinds.PartialPayment                   AS PartialPayment,
	|	
	|	&CurrentDate AS ValidityStartDate,
	|	CASE
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.DAY)
	|			THEN DATEADD(&CurrentDate, DAY, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.WEEK)
	|			THEN DATEADD(&CurrentDate, WEEK, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.MONTH)
	|			THEN DATEADD(&CurrentDate, MONTH, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.QUARTER)
	|			THEN DATEADD(&CurrentDate, QUARTER, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.YEAR)
	|			THEN DATEADD(&CurrentDate, YEAR, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.TENDAYS)
	|			THEN DATEADD(&CurrentDate, TENDAYS, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN DATEADD(&CurrentDate, HALFYEAR, GiftCertificateKinds.NumberOfValidityPeriods)
	|		ELSE &CurrentDate
	|	END AS ValidityEndDate,
	|	VALUE(Catalog.ARAPObjects.EmptyRef)	AS ARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)	AS Partner,
	|	GiftCertificateKinds.CashFlowItemSale	AS CashFlowItemSale,
	|	GiftCertificateKinds.CashFlowItemReturn	AS CashFlowItemReturn,
	|	GiftCertificateKinds.IncomeItem	AS IncomeItem,
	|	GiftCertificateKinds.DimensionOfRevenue	AS DimensionOfRevenue,
	|	ISNULL(Companies.Ref, GiftCertificateKinds.Organization) AS Organization,
	|	FALSE AS RefundIssued,
	|	FALSE AS Canceled_
	|FROM
	|	GiftCertificateKinds AS GiftCertificateKinds
	|	LEFT JOIN Catalog.Companies AS Companies
	|	ON &ConnectionConditionByOrganizationByTypeOfOperation
	|WHERE
	|	(NOT GiftCertificateKinds.Ref IN
	|				(SELECT DISTINCT
	|					T.GiftCertificateKind
	|				FROM
	|					GiftCertificates AS T))
	|	AND NOT GiftCertificateKinds.GiftCardAccounting25
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                         AS Order,
	|	VALUE(Catalog.GiftCertificates.EmptyRef)   AS Ref,
	|	UNDEFINED                                              AS Description,
	|	&MagneticCode                                             AS MagneticCode,
	|	&Barcode                                                 AS Barcode,
	|	UNDEFINED                                                       AS SerialNumber,
	|	VALUE(Enum.GiftCertificateStatuses.NotActivated) AS StatusFromHistoryOfGiftCertificates,
	|	FALSE                                                               AS ActivationStatus,
	|	0                                                                  AS Balance,
	|	
	|	GiftCertificateKinds.Ref                            AS GiftCertificateKind,
	|	GiftCertificateKinds.ActionPeriod                    AS ActionPeriod,
	|	GiftCertificateKinds.NumberOfValidityPeriods        AS NumberOfValidityPeriods,
	|	GiftCertificateKinds.Nominal                           AS Nominal,
	|	GiftCertificateKinds.Currency                            AS Currency,
	|	GiftCertificateKinds.CardType                          AS CardType,
	|	GiftCertificateKinds.ProductSegment               AS ProductSegment,
	|	GiftCertificateKinds.GiftCardAccounting25     AS GiftCardAccounting25,
	|	GiftCertificateKinds.PartialPayment                   AS PartialPayment,
	|	
	|	&CurrentDate AS ValidityStartDate,
	|	CASE
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.DAY)
	|			THEN DATEADD(&CurrentDate, DAY, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.WEEK)
	|			THEN DATEADD(&CurrentDate, WEEK, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.MONTH)
	|			THEN DATEADD(&CurrentDate, MONTH, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.QUARTER)
	|			THEN DATEADD(&CurrentDate, QUARTER, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.YEAR)
	|			THEN DATEADD(&CurrentDate, YEAR, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.TENDAYS)
	|			THEN DATEADD(&CurrentDate, TENDAYS, GiftCertificateKinds.NumberOfValidityPeriods)
	|		WHEN GiftCertificateKinds.ActionPeriod = VALUE(Enum.Periodicity.HALFYEAR)
	|			THEN DATEADD(&CurrentDate, HALFYEAR, GiftCertificateKinds.NumberOfValidityPeriods)
	|		ELSE &CurrentDate
	|	END AS ValidityEndDate,
	|	VALUE(Catalog.ARAPObjects.EmptyRef)	AS ARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)	AS Partner,
	|	GiftCertificateKinds.CashFlowItemSale	AS CashFlowItemSale,
	|	GiftCertificateKinds.CashFlowItemReturn	AS CashFlowItemReturn,
	|	GiftCertificateKinds.IncomeItem	AS IncomeItem,
	|	GiftCertificateKinds.DimensionOfRevenue	AS DimensionOfRevenue,
	|	GiftCertificateKinds.Organization AS Organization,
	|	FALSE AS RefundIssued,
	|	FALSE AS Canceled_
	|FROM
	|	GiftCertificateKinds AS GiftCertificateKinds
	|WHERE
	|	(NOT GiftCertificateKinds.Ref IN
	|				(SELECT DISTINCT
	|					T.GiftCertificateKind
	|				FROM
	|					GiftCertificates AS T))
	|	AND GiftCertificateKinds.GiftCardAccounting25
	|	AND &ConditionForSelectingTypeOfGiftCertificateForOrganization

	|
	|ORDER BY
	|	Order ASC
	|");
	
	If CodeType = Enums.CardCodeTypes.MagneticCode Then
		
		Query.Text = StrReplace(Query.Text,"&StartOfRangeCondition", "GiftCertificateCodeTemplates.StartOfMagneticCodeRange");
		Query.Text = StrReplace(Query.Text,"&EndOfRangeCondition",  "GiftCertificateCodeTemplates.EndOfMagneticCodeRange");
		Query.Text = StrReplace(Query.Text,"&ConditionCodeLength",       "GiftCertificateCodeTemplates.MagneticCodeLength");
		Query.Text = StrReplace(Query.Text,"&NameOfMapCodeField",        "GiftCertificates.MagneticCode");
		
		Query.SetParameter("Barcode",     "");
		Query.SetParameter("MagneticCode", CardCode);
		
	Else
		
		Query.Text = StrReplace(Query.Text,"&StartOfRangeCondition", "GiftCertificateCodeTemplates.StartOfBarcodeRange");
		Query.Text = StrReplace(Query.Text,"&EndOfRangeCondition",  "GiftCertificateCodeTemplates.EndOfBarcodeRange");
		Query.Text = StrReplace(Query.Text,"&ConditionCodeLength",       "GiftCertificateCodeTemplates.BarcodeLength");
		Query.Text = StrReplace(Query.Text,"&NameOfMapCodeField",        "GiftCertificates.Barcode");
		
		Query.SetParameter("Barcode",     CardCode);
		Query.SetParameter("MagneticCode", "");
		
	EndIf;
	
	Query.SetParameter("CardCode",    CardCode);
	Query.SetParameter("CodeLength",   StrLen(CardCode));
	
	FilterConditions = Filters;
	If Not TypeOf(Filters) = Type("Structure") Then
		FilterConditions = New Structure;
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	If FilterConditions.Property("Date") And ValueIsFilled(FilterConditions.Date) Then
		CurrentSessionDate = FilterConditions.Date;
	EndIf;
	Query.SetParameter("CurrentDate", CurrentSessionDate);
	
	ReplacementTextOfSelectionCriteriaByTypeOfOperation = "TRUE";
	If FilterConditions.Property("OperationType") Then
		If FilterConditions.OperationType = 1 Then
		// Sale
			ReplacementTextOfSelectionCriteriaByTypeOfOperation = "NOT GiftCertificates.ActivationStatus";
		ElsIf FilterConditions.OperationType = 2 Then
		// Return
			ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.ActivationStatus
			|	AND ISNULL(StateOfGiftCertificates.RefundIssued, FALSE) = FALSE
			|	AND GiftCertificates.ValidityEndDate >= &CurrentDate 
			|	AND ISNULL(CertificateBalances.SumBalance, 0) = GiftCertificates.Nominal";
		ElsIf FilterConditions.OperationType = 3 Then
		// Payment
			ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.ActivationStatus 
			|	AND GiftCertificates.ValidityStartDate <= &CurrentDate AND GiftCertificates.ValidityEndDate >= &CurrentDate 
			|	AND (ISNULL(CertificateBalances.SumBalance, 0) > 0 AND GiftCertificates.PartialPayment
			|		OR ISNULL(CertificateBalances.SumBalance, 0) = GiftCertificates.Nominal AND NOT GiftCertificates.PartialPayment)";
		ElsIf FilterConditions.OperationType = 4 Then
		// Cancellation
			ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.ActivationStatus
			|	AND ISNULL(CertificateBalances.SumBalance, 0) > 0
			|	AND (GiftCertificates.PartialPayment = FALSE AND 
			|			ISNULL(CertificateBalances.SumBalance, 0) <= GiftCertificates.Nominal
			|		OR GiftCertificates.PartialPayment = TRUE)";
		EndIf;
	EndIf;
	Query.Text = StrReplace(Query.Text,"&SelectionCriteriaByTypeOfOperation", ReplacementTextOfSelectionCriteriaByTypeOfOperation);
	
	ReplacementTextOfSelectionConditions = "TRUE";
	ReplacementTextOfSelectionCriteriaByTypeOfOperation = "TRUE";
	ReplacementTextForTypeSelectionCondition = "TRUE";
	TextOfConnectionConditionReplacementByTypeOfOperation = "FALSE";
	If FilterConditions.Property("Organization") Then
		ReplacementTextOfSelectionConditions = "GiftCertificates.Organization IN (&Organization)";
		ReplacementTextForTypeSelectionCondition = "GiftCertificateKinds.Organization IN (&Organization)";
		Query.SetParameter("Organization", FilterConditions.Organization);
		If FilterConditions.Property("OperationType") Then
			If FilterConditions.OperationType > 1 Then
				ReplacementTextOfSelectionCriteriaByTypeOfOperation = "GiftCertificates.Organization IN (&Organization)";
				TextOfConnectionConditionReplacementByTypeOfOperation = "Companies.Ref IN (&Organization)";
			EndIf;
		EndIf;
	EndIf;
	Query.Text = StrReplace(Query.Text,"&SelectionCriteriaOrganizationByTypeOfOperation", ReplacementTextOfSelectionCriteriaByTypeOfOperation);
	Query.Text = StrReplace(Query.Text,"&SelectionConditionOrganization", ReplacementTextOfSelectionConditions);
	Query.Text = StrReplace(Query.Text,"&ConnectionConditionByOrganizationByTypeOfOperation", TextOfConnectionConditionReplacementByTypeOfOperation);
	Query.Text = StrReplace(Query.Text,"&ConditionForSelectingTypeOfGiftCertificateForOrganization", ReplacementTextForTypeSelectionCondition);
	
	ReplacementTextOfSelectionConditions = "TRUE";
	If FilterConditions.Property("Currency") Then
		ReplacementTextOfSelectionConditions = "GiftCertificateCodeTemplates.Ref.Currency IN (&Currency)";
		Query.SetParameter("Currency", FilterConditions.Currency);
	EndIf;
	Query.Text = StrReplace(Query.Text,"&SelectionConditionCurrency", ReplacementTextOfSelectionConditions);
	
	ReplacementTextOfSelectionConditions = "TRUE";
	If FilterConditions.Property("GiftCardAccounting25") Then
		ReplacementTextOfSelectionConditions = "GiftCertificateCodeTemplates.Ref.GiftCardAccounting25 = &GiftCardAccounting25";
		Query.SetParameter("GiftCardAccounting25", FilterConditions.GiftCardAccounting25);
	EndIf;
	Query.Text = StrReplace(Query.Text,"&SelectionConditionAccountingForGiftCertificates2_5", ReplacementTextOfSelectionConditions);
	
	ReplacementTextOfSelectionConditions = "TRUE";
	If FilterConditions.Property("Status") Then
		ReplacementTextOfSelectionConditions = "GiftCertificates.StatusFromHistoryOfGiftCertificates IN (&Status)";
		Query.SetParameter("Status", FilterConditions.Status);
		If FilterConditions.Property("OperationType") Then
			If FilterConditions.OperationType = 3 Then
			// Payment
				ReplacementTextOfSelectionConditions = ReplacementTextOfSelectionConditions + " AND ISNULL(CertificateBalances.SumBalance, 0) > 0";
			ElsIf FilterConditions.OperationType = 4 Then
			// Cancellation
				// You cannot cancel a reusable gift certificate if it is partially redeemed and its Balance is zero.
				// The Cash Register Receipt document does not take into account the Balance of the gift certificate when calculating the Status.
				ReplacementTextOfSelectionConditions = ReplacementTextOfSelectionConditions + "
					|AND NOT (GiftCertificates.PartialPayment = TRUE 
					|		AND GiftCertificates.StatusFromHistoryOfGiftCertificates = VALUE(Enum.GiftCertificateStatuses.PartiallyRepaid) 
					|		AND ISNULL(CertificateBalances.SumBalance, 0) = 0)";
			EndIf;
		EndIf;
	EndIf;
	Query.Text = StrReplace(Query.Text,"&SelectionConditionStatusFromHistoryOfGiftCertificates", ReplacementTextOfSelectionConditions);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	Selection = Result.Select();
	While Selection.Next() Do
		
		NewRow = GiftCertificatesServerCall.InitializeGiftCertificateDescription();
		FillPropertyValues(NewRow, Selection);
		If ValueIsFilled(Selection.Ref) Then
			RegisteredGiftCertificates.Add(NewRow);
		Else
			NotRegisteredGiftCertificates.Add(NewRow);
		EndIf;
	
	EndDo;
	
	ReturnValue = New Structure("RegisteredGiftCertificates, NotRegisteredGiftCertificates");
	ReturnValue.RegisteredGiftCertificates   = RegisteredGiftCertificates;
	ReturnValue.NotRegisteredGiftCertificates = NotRegisteredGiftCertificates;
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region ReflectionOfRegisteredRecordsInRegisters

// Procedure for generating movements in the "movement of monetary means" Register
// for the documents "implementation of welding Certificates" and"return of welding Certificates".
// Determines which certificates are paid for by card
// (distributes the payment amount on the card according to the cost of certificates in the order of serifications).
//
// Parameters:
//  PaymentGiftCertificates - ValueTable
//  PaymentPaymentCards - ValueTable
//  
// Returns:
//  ValueTable - A table containing tables of movements.
// 
Function PrepareCashFlowTableCounterparty(PaymentGiftCertificates, PaymentPaymentCards) Export
	
	RegisterRecordTable = AccumulationRegisters.RecordsCashCounterparty.CreateRecordSet().UnloadColumns();
		
	AllPaymentsByPaymentCardsAreDistributed = False;
	For Each Certificate In PaymentGiftCertificates Do
		
		If Not AllPaymentsByPaymentCardsAreDistributed Then
			TheStructureOfTheSearch = New Structure("PaymentProcessed", False);
			PaymentsNotProcessedWithPaymentCards = PaymentPaymentCards.FindRows(TheStructureOfTheSearch);
			AllPaymentsByPaymentCardsAreDistributed = (PaymentsNotProcessedWithPaymentCards.Count() = 0);
			For Each PaymentLine_ In PaymentsNotProcessedWithPaymentCards Do
				
				Sum =     ARAPAccountingServer.DeductAmount(PaymentLine_.PaymentAmountPaymentCurrency, Certificate.PaymentAmountPaymentCurrency);
				SumMan =  ARAPAccountingServer.DeductAmount(PaymentLine_.PayAmount,               Certificate.PayAmount);
				SumCompl = ARAPAccountingServer.DeductAmount(PaymentLine_.PaymentAmountLocal,           Certificate.PaymentAmountLocal);
				
				// Part of the cost will be paid by card
				If Sum > 0 Then
					
					NewMovement = RegisterRecordTable.Add();
					FillPropertyValues(NewMovement, PaymentLine_);
					NewMovement.ARAPObject = Certificate.ARAPObject;
					
					NewMovement.PayAmount = SumMan;
					NewMovement.PaymentAmountLocal = SumCompl;
					NewMovement.PaymentAmountPaymentCurrency = Sum;
					NewMovement.PaymentAmountInTheSettlementCurrency = Sum;
					
					NewMovement.PrepaymentAmountMan = SumMan;
					NewMovement.PrepaymentAmountLocal = SumCompl;
					NewMovement.PrepaymentAmount = Sum;
					NewMovement.PrepaymentAmountInARAPCurrency = Sum;
					
				EndIf;	
				
				PaymentLine_.PaymentProcessed = (PaymentLine_.PaymentAmountPaymentCurrency = 0);
				
				If Certificate.PaymentAmountPaymentCurrency = 0 Then
					// We have fully covered the cost of the certificate, we are moving on to another one
					Break;
				EndIf;	
			EndDo;
		EndIf;	
			
		// We will cover the remaining cost of the certificate in cash
		If Certificate.PaymentAmountPaymentCurrency > 0 Then
			
			NewMovement = RegisterRecordTable.Add();
			FillPropertyValues(NewMovement, Certificate);
			
			NewMovement.PaymentAmountInTheSettlementCurrency = NewMovement.PaymentAmountPaymentCurrency;
			
			NewMovement.PrepaymentAmountMan = NewMovement.PayAmount;
			NewMovement.PrepaymentAmountLocal = NewMovement.PaymentAmountLocal;
			NewMovement.PrepaymentAmount = NewMovement.PaymentAmountPaymentCurrency;
			NewMovement.PrepaymentAmountInARAPCurrency = NewMovement.PaymentAmountInTheSettlementCurrency;
			
		EndIf;
		
	EndDo;	
		
	Return RegisterRecordTable;
	
EndFunction

#EndRegion

//Checks that the passed link type is included in the allowed types for crediting payments with gift certificates.
//
// Parameters:
//  RefType - Type - The type of link to check.
//
// Returns:
//  Boolean - 
//
Function TypeIsAllowedForCreditingPaymentsWithGiftCertificates(RefType) Export
	
	Allowed_Types = New Array;
	Allowed_Types.Add(Type("CatalogRef.CounterpartyContracts"));
	Allowed_Types.Add(Type("DocumentRef.CustomerInvoiceServices"));
	Allowed_Types.Add(Type("DocumentRef.ReturnablePackagingRedemptionByCustomer"));
	Allowed_Types.Add(Type("DocumentRef.RedemptionOfGoodsByCustodian"));
	Allowed_Types.Add(Type("DocumentRef.SalesOrder"));
	Allowed_Types.Add(Type("DocumentRef.CustomerInvoice"));
	Allowed_Types.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	
	GiftCertificatesLocalization.AddAllowedTypesForCreditingPaymentsWithGiftCertificates(Allowed_Types);
	
	Result = Not (Allowed_Types.Find(RefType) = Undefined);
	Return Result;
	
EndFunction

//Returns a table of values with document data for analyzing the possibility of paying with gift certificates.
//
// Parameters:
//  Ref - DocumentRef, CatalogRef - 
//
// Returns:
//  ValueTable -Table of values with document data for analysis:
//   * Products - CatalogRef.Products -
//   * Characteristic - CatalogRef.ItemsCharacteristics -
//   * Sum - Number - 
//  ,Undefined
Function ProductsForAnalyzingPossibilityOfPayingWithGiftCertificates(Ref) Export
	
	ProductsForAnalysis = Undefined;
	
	ObjectReferenceType = TypeOf(Ref);
	ReferencesArrray = New Array();
	If ObjectReferenceType = Type("DocumentRef.ARAPSettlement") Then
		QueryText = "SELECT DISTINCT
		|	AccountsReceivable.ARAPObject.Object AS Ref
		|FROM
		|	Document.ARAPSettlement.AccountsReceivable AS AccountsReceivable
		|WHERE
		|	AccountsReceivable.Ref = &Ref";
		Query = New Query(QueryText);
		Query.SetParameter("Ref", Ref);
		ObjectsOfAccountsReceivable = Query.Execute().Unload();
		If ObjectsOfAccountsReceivable.Count() Then
			ReferencesArrray = ObjectsOfAccountsReceivable.UnloadColumn("Ref");
		EndIf;
	Else
		ReferencesArrray.Add(Ref)
	EndIf;
	
	If ReferencesArrray.Count() Then
		Query = New Query;
		
		RequestTemplateText = "SELECT
		|	ProductsForAnalysis.Products AS Products,
		|	ProductsForAnalysis.Characteristic AS Characteristic,
		|	SUM(ProductsForAnalysis.Sum) AS Sum
		|FROM
		|	&QueryingTableParts AS ProductsForAnalysis
		|GROUP BY
		|	Products,
		|	CHARACTERISTIC";
		
		TextOfRequestTemplateForTabularPartCashRegisterReceipt = "
		|SELECT
		|		TabularSection.Products AS Products,
		|		TabularSection.Characteristic AS Characteristic,
		|		TabularSection.Sum AS Sum
		|	FROM
		|		&TabularSection AS TabularSection
		|	WHERE
		|		TabularSection.Ref IN (&ReferencesArrray)
		|		AND TabularSection.Ref.Posted
		|";
		
		TextOfQueryTemplateOfTablePartIsUniversal = "
		|SELECT
		|		TabularSection.Products AS Products,
		|		TabularSection.Characteristic AS Characteristic,
		|		TabularSection.AmountIncludingVAT AS Sum
		|	FROM
		|		&TabularSection AS TabularSection
		|	WHERE
		|		TabularSection.Ref IN (&ReferencesArrray)
		|		AND TabularSection.Ref.Posted
		|";
		
		TextOfRequestTemplateForTablePartReturnOfGoodsFromClient = "
		|SELECT
		|		TabularSection.Products AS Products,
		|		TabularSection.Characteristic AS Characteristic,
		|		-TabularSection.AmountIncludingVAT AS Sum
		|	FROM
		|		Document.ReturnOfGoodsFromCustomer.Goods AS TabularSection
		|	WHERE
		|		TabularSection.Ref.DocumentSalesOfGoodsAndServices IN (&ReferencesArrray)
		|		AND TabularSection.Ref.Posted
		|";
		
		TextOfQueryTemplateForTablePartOfImplementationAdjustment = "
		|SELECT
		|		TabularSection.Products AS Products,
		|		TabularSection.Characteristic AS Characteristic,
		|		TabularSection.AmountIncludingVAT AS Sum
		|	FROM
		|		Document.SaleAdjustment.Discrepancies AS TabularSection
		|	WHERE
		|		TabularSection.Ref.DocumentBasis IN (&ReferencesArrray)
		|		AND TabularSection.Ref.Posted
		|";

		TextOfQueryTemplateForTablePart = TextOfQueryTemplateOfTablePartIsUniversal;
		
		RefsByTypes = New Map;
		For Each Ref In ReferencesArrray Do
			If Not ValueIsFilled(Ref) Then
				Continue;
			EndIf;
			Type = TypeOf(Ref);
			If RefsByTypes[Type] = Undefined Then
				RefsByTypes[Type] = New Array;
			EndIf;
			ItemByType = RefsByTypes[Type]; // Array
			ItemByType.Add(Ref);
		EndDo;
		
		QueryTextArray = New Array;
		For Each KeyValue In RefsByTypes Do
			// There is always at least one element of the array.
			RefMetadata = KeyValue.Value[0].Metadata(); // MetadataObject
			NameOfRequestParameter = "ReferencesArrray"+ RefMetadata.Name;
			MetadataTabularSection = Undefined;
			TakeIntoAccountImplementationAdjustment = False;
			TakeIntoAccountReturnOfGoodsFromClient = False;
			
			TabularSectionQueryText = "";
			If KeyValue.Key = Type("DocumentRef.CashRegisterReceipt") Then
				
				TextOfQueryTemplateForTablePart = TextOfRequestTemplateForTabularPartCashRegisterReceipt;
				Query.SetParameter(NameOfRequestParameter, KeyValue.Value);
				MetadataTabularSection = RefMetadata.TabularSections.Goods; // MetadataObjectTabularSection
			
			ElsIf KeyValue.Key = Type("DocumentRef.ReturnablePackagingRedemptionByCustomer")
				Or KeyValue.Key = Type("DocumentRef.RedemptionOfGoodsByCustodian")
				Or KeyValue.Key = Type("DocumentRef.SalesOrder")
				Or KeyValue.Key = Type("DocumentRef.CustomerInvoice") 
				Or KeyValue.Key = Type("DocumentRef.CustomerInvoiceServices") Then
				
				Query.SetParameter(NameOfRequestParameter, KeyValue.Value);
				If KeyValue.Key = Type("DocumentRef.CustomerInvoiceServices") Then
					MetadataTabularSection = RefMetadata.TabularSections.Services; // MetadataObjectTabularSection
				Else
					MetadataTabularSection = RefMetadata.TabularSections.Goods; // MetadataObjectTabularSection
				EndIf;
				
				If KeyValue.Key = Type("DocumentRef.CustomerInvoice") 
					Or KeyValue.Key = Type("DocumentRef.CustomerInvoiceServices") Then
					TakeIntoAccountImplementationAdjustment = True;
					If KeyValue.Key = Type("DocumentRef.CustomerInvoice") Then
						TakeIntoAccountReturnOfGoodsFromClient = True;
					EndIf;
				EndIf;
			ElsIf GiftCertificatesLocalization.TypeRefersToDocumentsOfTollingScheme(KeyValue.Key) Then
				
				Query.SetParameter(NameOfRequestParameter, KeyValue.Value);
				MetadataTabularSection = RefMetadata.TabularSections.ManufacturedProduct; // MetadataObjectTabularSection
				
				If KeyValue.Key = Type("DocumentRef.ReportToMaterialProvider2_5") Then
					TakeIntoAccountImplementationAdjustment = True;
				EndIf;
			EndIf;
			
			If Query.Parameters.Property(NameOfRequestParameter) Then
				TabularSectionQueryText = StrReplace(TextOfQueryTemplateForTablePart,"&TabularSection", RefMetadata.FullName()+"."+MetadataTabularSection.Name);
				TabularSectionQueryText = StrReplace(TabularSectionQueryText,"ReferencesArrray", NameOfRequestParameter);
				QueryTextArray.Add(TabularSectionQueryText);
				If TakeIntoAccountImplementationAdjustment = True Then
					QueryTextArray.Add(StrReplace(TextOfQueryTemplateForTablePartOfImplementationAdjustment,"ReferencesArrray", NameOfRequestParameter));
				EndIf;
				If TakeIntoAccountReturnOfGoodsFromClient = True Then
					QueryTextArray.Add(StrReplace(TextOfRequestTemplateForTablePartReturnOfGoodsFromClient,"ReferencesArrray", NameOfRequestParameter));
				EndIf;
			EndIf;
		EndDo;
		
		If QueryTextArray.Count() Then
			QueryTextForTableParts = StrConcat(QueryTextArray, "UNION ALL");
			Query.Text = StrReplace(RequestTemplateText, "&QueryingTableParts", "("+QueryTextForTableParts+")");
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				ProductsForAnalysis = QueryResult.Unload();
			EndIf;
		EndIf;
		
	EndIf;
	
	Return ProductsForAnalysis;
EndFunction

// Starts automatic accrual and deduction of points and monitors the result.
Procedure CancellationOfGiftCertificatesRoutineTask() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.GiftCertificateCancellation);
	
	If Not GetFunctionalOption("UseGiftCards") Then
		Return;
	EndIf;

	If IsBlankString(UserName()) Then
		SetPrivilegedMode(True);
	EndIf;
	
	TypeRestriction = New TypeDescription("CatalogRef.Companies");
	Organization = TypeRestriction.AdjustValue(Undefined);
	
	LogParameters = New Structure("EventGroup_, Metadata, Data");
	LogParameters.EventGroup_ = NStr("vi = 'Tự động hủy phiếu quà tặng. Khởi động theo lịch biểu';
									|ru = 'Автоматическое аннулирование подарочных сертификатов. Запуск по расписанию';
									|en = 'Automatically void gift cards. Start on schedule'; fa = 'Automatically void gift cards. Start on schedule';
									|it = 'Annullamento automatico dei buoni regalo. Avvio da programma';
									|pl = 'Automatyczne anulowanie certyfikatów podarunkowych. Uruchomienie zgodnie z harmonogramem';
									|tr = 'Hediye kartlarının otomatik iptali. Programlı başlatma'");
	LogParameters.Metadata    = Organization.Metadata();
	LogParameters.Data        = Organization;
	
	SegmentsServer.LogRecord(LogParameters, EventLogLevel.Note, "", NStr("vi = 'Khởi động';
																		|ru = 'Запуск';
																		|en = 'Start'; fa = 'شروع';
																		|it = 'Avvio';
																		|pl = 'Start';
																		|tr = 'Başlangıc'"));
	
	Documents.GiftCertificateCancellation.CancellationOfExpiredGiftCertificates(Organization);
	SegmentsServer.LogRecord(LogParameters, EventLogLevel.Note, "",NStr("vi = 'Kết thúc';
																		|ru = 'Завершение';
																		|en = 'Complete'; fa = 'تکمیل';
																		|it = 'Completamento';
																		|pl = 'Complete';
																		|tr = 'Tamamlama'"));
	
EndProcedure

#EndRegion

#Region Private

#Region FillChecking

// The procedure checks the completion of gift certificates in the tabular part of the "Decryption of payment".
//
// Parameters:
//  Object - DocumentObject - The current document.
//  Table Part name - String is the name of the metadata of the table part of the document.
//  Cancel - Boolean - indicates that the document was rejected.
//
// Returns:
//  Number - The number of rows in the table part in which the gift card is the object of calculation
//
Function CheckCompletionOfTabularPartOfPaymentDecryption(Object, Cancel)
	
	NumberOfGiftCards = 0;
	ObjectReferenceType = TypeOf(Object.Ref);
	TabularSectionName = "";
	CheckEqualityOfAmountAndFaceValue = True;
	ARAPObjectIsObject = False;
	If ObjectReferenceType = Type("DocumentRef.ARAPSettlement") Then
		If (Object.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard) Then
			TabularSectionName = Object.Ref.Metadata().TabularSections.AccountsPayable.Name;
			CheckEqualityOfAmountAndFaceValue = False;
		ElsIf (Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties) Then
			TabularSectionName = Object.Ref.Metadata().TabularSections.AccountsReceivable.Name;
			CheckEqualityOfAmountAndFaceValue = False;
		Else
			Return NumberOfGiftCards;
		EndIf;
	ElsIf ObjectReferenceType = Type("DocumentRef.OBEntryARAP") Then
		TabularSectionName = Object.Ref.Metadata().TabularSections.PartnersARAPAccounting.Name;
		CheckEqualityOfAmountAndFaceValue = False;
		ARAPObjectIsObject = True;
	ElsIf ObjectReferenceType = Type("DocumentRef.CashAccountReceiptNote")
			Or ObjectReferenceType = Type("DocumentRef.BankAccountReceiptNote")
			Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction")
			Or ObjectReferenceType = Type("DocumentRef.CashVoucher")
			Or ObjectReferenceType = Type("DocumentRef.BankAccountIssue")
			Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction")
			Or ObjectReferenceType = Type("DocumentRef.PaymentRequest") Then
		TabularSectionName = Object.Ref.Metadata().TabularSections.ARAPDetails.Name;
	Else
		Return NumberOfGiftCards;
	EndIf;
	
	SynonymForNameOfTablePart = Object.Ref.Metadata().TabularSections[TabularSectionName].Synonym;
	TabularSection = Object[TabularSectionName];
	
	If TabularSection.Count() = 0 Then
		Return NumberOfGiftCards;
	EndIf;
	
	TypeOfOperationForGiftCertificates = GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object);
	CurrentDate = ?(ValueIsFilled(Object.Ref), Object.Date, CurrentSessionDate());
	
	GiftCertificateARAPObjects = New Map;
	GiftCertificatesForSettlementObjects = New Map;
	GiftCertificates = New Array;
	If ARAPObjectIsObject Then
		For Each LineOfATabularSection In TabularSection Do
			If TypeOf(LineOfATabularSection.ARAPObject) = Type("CatalogRef.GiftCertificates") Then
				GiftCertificates.Add(LineOfATabularSection.ARAPObject);
			EndIf;
		EndDo;
		GiftCertificateARAPObjects = Common.ObjectsAttributeValue(GiftCertificates, "ARAPObject");
		For Each KeyValue In GiftCertificateARAPObjects Do
			If ValueIsFilled(KeyValue.Key) And ValueIsFilled(KeyValue.Value) Then
				GiftCertificatesForSettlementObjects.Insert(KeyValue.Value, KeyValue.Key);
			EndIf;
		EndDo;
	Else
		GiftCertificatesForSettlementObjects = Catalogs.GiftCertificates.GiftCertificatesForSettlementObjects(TabularSection.UnloadColumn("ARAPObject"));
	EndIf;
	
	NumberOfGiftCards = GiftCertificatesForSettlementObjects.Count();
	If NumberOfGiftCards = 0 Then
		Return NumberOfGiftCards;
	EndIf;
	
	GiftCertificates = Common.UnloadColumn(GiftCertificatesForSettlementObjects, "Value", True);
	DataOfGiftCertificates = GiftCertificatesServerCall.GetGiftCertificatesDetails(GiftCertificates, CurrentDate, Object.Ref);
	LineNumbersOfCalculationObjects = New Map;
	For Each DecryptionString In TabularSection Do
		
		GiftCertificate = Undefined;
		If ARAPObjectIsObject Then
			If Not GiftCertificateARAPObjects[DecryptionString.ARAPObject] = Undefined Then
				GiftCertificate = DecryptionString.ARAPObject;
			EndIf;
		Else
			GiftCertificate = GiftCertificatesForSettlementObjects.Get(DecryptionString.ARAPObject);
		EndIf;
		If ValueIsFilled(GiftCertificate) Then
			GiftCertificateDetails = DataOfGiftCertificates[GiftCertificate];
			
			ErrorText = "";
			LineNumberOfCalculationObject = LineNumbersOfCalculationObjects[DecryptionString.ARAPObject];
			If LineNumberOfCalculationObject = Undefined Then
				TableLineParts  = DecryptionString; // LineOfATabularSection
				LineNumbersOfCalculationObjects.Insert(DecryptionString.ARAPObject, TableLineParts.LineNumber);
			Else
				ErrorText = NStr("vi = 'Đối tượng hạch toán %Certificate% Trong dòng %LineNumber% danh sách ""%TabularSection%"" bị trùng trong các dòng khác.';
								|ru = 'Объект расчетов %Certificate% В строке %LineNumber% списка ""%TabularSection%"" дублируется в других строках.';
								|en = 'The %Certificate% AR/AP object in row %LineNumber% of the %TabularSection% list is duplicated in other rows.'; fa = 'The %Certificate% AR/AP object in row %LineNumber% of the %TabularSection% list is duplicated in other rows.';
								|it = 'Oggetto dei calcoli %Certificate% Nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è duplicato in altre stringhe.';
								|pl = 'Obiekt rozliczeń %Certificate% W wierszu %LineNumber% listy ""%TabularSection%"" jest zduplikowane w innych wierszach.';
								|tr = 'Alacak/Borç nesnesi %Certificate% Listenin %LineNumber% satırında ""%TabularSection%"" diğer satırlarda tekrarlanıyor.'");
				ErrorText = StrReplace(ErrorText, "%Certificate%",  GiftCertificate);
				ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumberOfCalculationObject);
				ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
				Common.MessageToUser(
					ErrorText,
					Object,
					CommonClientServer.PathToTabularSection(TabularSectionName, LineNumberOfCalculationObject, "ARAPObject"),
					,
					Cancel);
			EndIf;
			
			ErrorText = "";
			If TypeOfOperationForGiftCertificates = 1 Then
			// Sale
				If GiftCertificateDetails.ActivationStatus Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" đã được kích hoạt và không được phép để bán';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" уже активирован и недоступен для продажи';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is already activated and unavailable for sale'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is already activated and unavailable for sale';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è già attivato e non è disponibile per la vendita';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest już aktywowany i niedostępny do sprzedaży';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı zaten etkinleştirilmiştir ve satış için uygun değildir'");
				EndIf;
			ElsIf TypeOfOperationForGiftCertificates = 2 Then
			// Return
				If Not GiftCertificateDetails.ActivationStatus Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" chưa được kích hoạt và không được phép để trả lại.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" не активирован и недоступен для возврата.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated and cannot be returned.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated and cannot be returned.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" non è attivato e non è disponibile per il reso.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" nie jest aktywowany i jest niedostępny do zwrotu.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı etkinleştirilmemiştir ve iade için kullanılamaz.'");
				ElsIf GiftCertificateDetails.ValidityEndDate < Object.Date Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" đã quá hạn và không được phép để trả lại.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" просрочен и недоступен для возврата.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list expired and cannot be returned.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list expired and cannot be returned.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è scaduto e non è disponibile per il reso.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest przeterminowany i niedostępny do zwrotu.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartının süresi doldu ve iade için kullanılamıyor.'");
				EndIf;
			ElsIf TypeOfOperationForGiftCertificates = 3 Then
			// Payment
				If Not GiftCertificateDetails.ActivationStatus Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" chưa được kích hoạt và không được phép để thanh toán.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" не активирован и недоступен для оплаты.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated and unavailable for payment.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated and unavailable for payment.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" non è attivato e non è disponibile per il pagamento.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" nie jest aktywowany i jest niedostępny do opłaty.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı etkinleştirilmemiştir ve ödeme için kullanılamaz.'");
				ElsIf Not(GiftCertificateDetails.ValidityStartDate <= Object.Date And GiftCertificateDetails.ValidityEndDate >= Object.Date) Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" đã quá hạn và không thể thanh toán.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" просрочен и недоступен для оплаты.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list expired and is unavailable for payment.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list expired and is unavailable for payment.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è scaduto e non è disponibile per il pagamento.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest przeterminowany i niedostępny do opłaty.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartının süresi doldu ve ödeme için uygun değil.'");
				EndIf;
			EndIf;
			
			If Not ValueIsFilled(ErrorText) Then
				If DecryptionString.Sum > GiftCertificateDetails.Nominal Then
					ErrorText = NStr("vi = 'Đối với phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" đã chỉ ra số tiền lớn hơn mệnh giá.';
									|ru = 'Для подарочного сертификата %Certificate% в строке %LineNumber% списка ""%TabularSection%"" указана сумма больше номинала.';
									|en = 'The amount specified for the %Certificate% gift card in row %LineNumber% of the %TabularSection% list exceeds the gift card amount.'; fa = 'The amount specified for the %Certificate% gift card in row %LineNumber% of the %TabularSection% list exceeds the gift card amount.';
									|it = 'Per il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è indicato un importo maggiore del valore nominale.';
									|pl = 'Dla certyfikatu podarunkowego %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest podana wartość większa niż wartość nominalna.';
									|tr = '%Certificate% hediye kartı için, ""%TabularSection%"" listesinin %LineNumber% satırı nominal değerden daha büyük bir tutar içeriyor.'");
				ElsIf CheckEqualityOfAmountAndFaceValue = True And DecryptionString.Sum <> GiftCertificateDetails.Nominal Then
					ErrorText = NStr("vi = 'Đối với phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" số tiền không bằng mệnh giá của phiếu quà tặng.';
									|ru = 'Для подарочного сертификата %Certificate% в строке %LineNumber% списка ""%TabularSection%"" сумма не равна номиналу подарочного сертификата.';
									|en = 'The amount specified for the %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not equal to the gift card amount.'; fa = 'The amount specified for the %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not equal to the gift card amount.';
									|it = 'Per il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" l''importo non è pari al valore nominale del buono regalo.';
									|pl = 'Dla certyfikatu podarunkowego %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" wartość nie jest równa wartości nominalnej certyfikatu podarunkowego.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı için tutar, hediye kartı değerine eşit değil.'");
				EndIf;
			EndIf;
			
			If ValueIsFilled(ErrorText) Then
				
				TableLineParts  = DecryptionString; // LineOfATabularSection
				ErrorText = StrReplace(ErrorText, "%Certificate%",  GiftCertificate);
				ErrorText = StrReplace(ErrorText, "%LineNumber%", TableLineParts.LineNumber);
				ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
				
				Common.MessageToUser(
					ErrorText,
					Object,
					CommonClientServer.PathToTabularSection(TabularSectionName, TableLineParts.LineNumber, "ARAPObject"),
					,
					Cancel);
			EndIf;
			
		Else
			TableLineParts  = DecryptionString; // LineOfATabularSection
			ErrorText = NStr("vi = 'Trong chứng từ hạch toán theo phiếu quà tặng không được có những đối tượng hạch toán khác';
							|ru = 'В документе расчета по подарочному сертификату не должно быть иных объектов расчетов';
							|en = 'A gift card AR/AP document cannot contain other AR/AP objects'; fa = 'A gift card AR/AP document cannot contain other AR/AP objects';
							|it = 'Nel documento di calcolo non devono esserci altri oggetti di calcolo per il buono regalo';
							|pl = 'W dokumencie rozliczenia według certyfikatu podarunkowego nie powinno być innych obiektów rozliczeń';
							|tr = 'Hediye kartı mutabakat nesnesi belgesinde başka bir alacak/borç nesnesi bulunmamalıdır'");
			Common.MessageToUser(
					ErrorText,
					Object,
					CommonClientServer.PathToTabularSection(TabularSectionName, TableLineParts.LineNumber, "ARAPObject"),
					,
					Cancel);
			Break;
		EndIf;
		
	EndDo;
	
	Return NumberOfGiftCards;
EndFunction

// The procedure checks the completion of gift certificates in the table part "gift Certificates".
//
// Parameters:
//  Object - DocumentObject - Current document.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure CheckCompletionOfTablePartGiftCertificates(Object, Cancel)
	
	If Object.GiftCertificates.Count() = 0 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	TabularSectionName = Object.Ref.Metadata().TabularSections.GiftCertificates.Name;
	SynonymForNameOfTablePart = Object.Ref.Metadata().TabularSections[TabularSectionName].Synonym;
	TabularSection = Object[TabularSectionName];
	
	TypeOfOperationForGiftCertificates = GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object);
	ValidStatusesFromHistoryOfGiftCertificates = GiftCertificatesClientServer.AcceptableStatusesOfGiftCertificates(Object);
	
	CurrentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	DataOfGiftCertificates = GiftCertificatesServerCall.GetGiftCertificatesDetails(TabularSection.UnloadColumn("GiftCertificate"), CurrentDate, Object.Ref);
	
	If TypeOf(Object) = Type("DocumentObject.OBEntry") 
		Or TypeOf(Object) = Type("DocumentObject.OBEntrySalesForPastPeriods") Then
		DetailsTypeOfGiftCertificate = Common.ObjectAttributesValues(Object.GiftCertificateKind, "Nominal, Currency");
	EndIf;
	
	For Each TableRow In TabularSection Do // LineOfATabularSection
		GiftCertificateDetails = DataOfGiftCertificates[TableRow.GiftCertificate];
	
		If GiftCertificateDetails = Undefined Then
			ErrorText = NStr("vi = 'Trong dòng %LineNumber% của phần bảng ""%TabularSection%"" chưa chỉ ra phiếu quà tặng.';
							|ru = 'В строке %LineNumber% табличной части ""%TabularSection%"" не указан подарочный сертификат.';
							|en = 'Specify the gift card in line %LineNumber% of the %TabularSection% table.'; fa = 'Specify the gift card in line %LineNumber% of the %TabularSection% table.';
							|it = 'В строке %LineNumber% табличной части ""%TabularSection%"" не указан подарочный сертификат.';
							|pl = 'Specify the gift card in line %LineNumber% of the %TabularSection% table.';
							|tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırı bir hediye kartı içermiyor.'");
			ErrorText = StrReplace(ErrorText, "%TabularSection%",  SynonymForNameOfTablePart);
			ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
				,
				Cancel);
			Continue;
		EndIf;

		If (TypeOf(Object) = Type("DocumentObject.OBEntry") 
				Or TypeOf(Object) = Type("DocumentObject.OBEntrySalesForPastPeriods"))
			And DetailsTypeOfGiftCertificate.Nominal < TableRow.AmountInCertificateCurrency Then
			
			ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" có số dư vượt quá mệnh giá %Nominal% %Currency%.';
							|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" имеет остаток, превышающий номинал %Nominal% %Currency%.';
							|en = 'The balance of the %Certificate% gift card in row %LineNumber% of the %TabularSection% list exceeds the gift card amount: %Nominal% %Currency%.'; fa = 'The balance of the %Certificate% gift card in row %LineNumber% of the %TabularSection% list exceeds the gift card amount: %Nominal% %Currency%.';
							|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" presenta dei saldi che superano il valore nominale %Nominal% %Currency%.';
							|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" ma resztę, przekraczającą nominał %Nominal% %Currency%.';
							|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartının bakiyesi %Nominal% %Currency% değerinden büyük.'");
			ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
			ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
			ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
			ErrorText = StrReplace(ErrorText, "%Nominal%",     DetailsTypeOfGiftCertificate.Nominal);
			ErrorText = StrReplace(ErrorText, "%Currency%",      DetailsTypeOfGiftCertificate.Currency);
			
			Common.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
				,
				Cancel);
				
		EndIf;
		
		If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")
			And Not ValueIsFilled(GiftCertificateDetails.IncomeItem) Then
			
			ErrorText = NStr("vi = 'Trong dòng %LineNumber% phần bảng ""%TabularSection%"" chưa điền dữ liệu của dạng phiếu quà tặng %CertificateType_%. 
									|Hãy điền dạng thu nhập trong dạng phiếu quà tặng.';
									|ru = 'В строке %LineNumber% табличной части ""%TabularSection%"" не заполнены данные вида сертификата %CertificateType_%. 
									|Заполните статью доходов в виде сертификата.';
									|en = 'Data of the %CertificateType_% gift card kind is not filled in row %LineNumber% of the %TabularSection% table. 
									|Fill the income item in the gift card kind.'; fa = 'Data of the %CertificateType_% gift card kind is not filled in row %LineNumber% of the %TabularSection% table. 
									|Fill the income item in the gift card kind.';
									|it = 'Nella stringa %LineNumber% della tabella ""%TabularSection%"" non sono compilati i dati del tipo di buono %CertificateType_%. 
									|Compilare la voce di entrata nel tipo di buono.';
									|pl = 'W wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" nie są wypełnione dane rodzaju certyfikatu %CertificateType_%. 
									|Wypełnij pozycję dochodów w rodzaju certyfikatu.';
									|tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırında %CertificateType_% kart türünün verileri doldurulmadı. 
									|Kart türündeki gelir kalemini doldur.'");
			ErrorText = StrReplace(ErrorText, "%TabularSection%",  SynonymForNameOfTablePart);
			ErrorText = StrReplace(ErrorText, "%CertificateType_%",  GiftCertificateDetails.GiftCertificateKind);
			ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
			ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				Object,
				CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
				,
				Cancel);
			
		EndIf;

		If GiftCertificateDetails.GiftCardAccounting25 Then
			
			If TypeOfOperationForGiftCertificates = 1 Then
			// Sale
				If GiftCertificateDetails.ActivationStatus Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" đã được kích hoạt.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" уже активирован.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is already activated.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is already activated.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è già attivato.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest już aktywowany.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı zaten etkinleştirilmiştir.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
				EndIf;
			ElsIf TypeOfOperationForGiftCertificates = 2 Then
			// Return
				If Not GiftCertificateDetails.ActivationStatus
						Or GiftCertificateDetails.ValidityEndDate < Object.Date
						Or GiftCertificateDetails.RefundIssued
						Or Not (GiftCertificateDetails.Balance = GiftCertificateDetails.Nominal) Then
					ErrorText = NStr("vi = 'Không thể dùng phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" để trả lại. Phiếu này đã quá hạn, đã bị trả lại, hoặc đã được dùng để thanh toán.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" недоступен для возврата. Он, либо просрочен, либо возвращен, либо им уже была произведена оплата.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list cannot be returned. It expired, was returned, or used for payment.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list cannot be returned. It expired, was returned, or used for payment.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" non è disponibile per il reso. Potrebbe essere scaduto, reso o già pagato.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest niedostępny dla zwrotu. Jest on już przeterminowany, lub został zwrócony, albo za jego pomocą została dokonana opłata.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı iade için uygun değil. Süresi dolmuş, iade edilmiş veya ödemesi zaten yapılmış olabilir.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
				EndIf;
			ElsIf TypeOfOperationForGiftCertificates = 3 Then
			// Payment
				If Not GiftCertificateDetails.ActivationStatus 
						Or Not(GiftCertificateDetails.ValidityStartDate <= Object.Date And GiftCertificateDetails.ValidityEndDate >= Object.Date)
						Or GiftCertificateDetails.Balance < GiftCertificateDetails.Nominal And GiftCertificateDetails.PartialPayment = False
						Or	GiftCertificateDetails.Balance <= 0 And GiftCertificateDetails.PartialPayment = True Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"", chưa được kích hoạt, đã quá hạn hoặc đã được thanh toán hết.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"", либо не активирован, либо просрочен, либо полностью погашен.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated, fully used, or expired.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated, fully used, or expired.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" non è attivato, è scaduto, oppure è stato completamente rimborsato.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"", lub nie jest jeszcze aktywowany, lub jest przeterminowany, albo został w całości zrealizowany.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı aktive edilmedi veya süresi doldu veya tamamen kullanıldı.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
				EndIf;
			ElsIf TypeOfOperationForGiftCertificates = 4 Then
			// Cancellation
				If Not GiftCertificateDetails.ActivationStatus
						Or Not GiftCertificateDetails.Balance > 0
						Or Not (GiftCertificateDetails.PartialPayment = False And
										(GiftCertificateDetails.Balance <= GiftCertificateDetails.Nominal)
								Or GiftCertificateDetails.PartialPayment = True) Then
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"", chưa được kích hoạt, đã được thanh toán hết hoặc đã bị hủy.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"", либо не был активирован, либо полностью погашен, либо уже аннулирован.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated, fully used, or voided.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list is not activated, fully used, or voided.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber%dell''elenco ""%TabularSection%"" non è stato attivato, è stato completamente rimborsato oppure è stato annullato.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"", lub nie został jeszcze aktywowany, lub jest w całości spłacony lub jest już anulowany.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartı aktive edilmedi veya tamamen kullanıldı veya artık iptal edildi.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
				EndIf;
				
			EndIf;
			
		Else
			
			If (ValidStatusesFromHistoryOfGiftCertificates.Find(GiftCertificateDetails.StatusFromHistoryOfGiftCertificates) = Undefined
					And TypeOf(Object) <> Type("DocumentObject.OBEntry")
					And TypeOf(Object) <> Type("DocumentObject.OBEntrySalesForPastPeriods"))
				Or (ValidStatusesFromHistoryOfGiftCertificates.Find(GiftCertificateDetails.StatusFromHistoryOfGiftCertificates) = Undefined 
					And (TypeOf(Object) = Type("DocumentObject.OBEntry")
						Or TypeOf(Object) = Type("DocumentObject.OBEntrySalesForPastPeriods"))
					And GiftCertificateDetails.DocumentSales <> Object.Ref) Then
				
				// For reusable old-style certificates, let's assume the Status is partially redeemed with a Balance equal to zero.
				// Therefore, for a payment operation, you need to check that the Balance is greater than zero.
				If Not (TypeOfOperationForGiftCertificates = 3 And GiftCertificateDetails.Balance > 0) 
				
					// You cannot cancel a reusable old-style gift certificate if it is partially redeemed and its Balance is zero.
					// The Cash Register Receipt document does not take into account the Balance of the gift certificate when calculating the Status.
					Or (TypeOfOperationForGiftCertificates = 4 
						And GiftCertificateDetails.PartialPayment = True 
						And GiftCertificateDetails.StatusFromHistoryOfGiftCertificates = PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid")
						And GiftCertificateDetails.Balance = 0) Then
							
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" có trạng thái không hợp lệ ""%Status%"".';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" имеет недопустимый статус ""%Status%"".';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list has an incorrect status: %Status%.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list has an incorrect status: %Status%.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" presenta stato non disponibile ""%Status%"".';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" ma niedopuszczalny status ""%Status%"".';
									|tr = '%TabularSection% listesinin %LineNumber% satırındaki %Certificate% hediye kartı erişilebilir değil ""%Status%"" durumuna sahip.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
					ErrorText = StrReplace(ErrorText, "%Status%",      GiftCertificateDetails.StatusFromHistoryOfGiftCertificates);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
				EndIf;
			EndIf;
		
			If TypeOf(Object) = Type("DocumentObject.CashRegisterReceipt")
				Or TypeOf(Object) = Type("DocumentObject.ReturnOfGiftCards") Then
				If GiftCertificateDetails.ValidityEndDate < Object.Date Then
				
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" đã quá hạn. Ngày kết thúc hiệu lực %ValidityEndDate%.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" просрочен. Дата окончания действия %ValidityEndDate%.';
									|en = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list expired. Expiration date: %ValidityEndDate%.'; fa = 'The %Certificate% gift card in row %LineNumber% of the %TabularSection% list expired. Expiration date: %ValidityEndDate%.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" è scaduto. Data di fine validità %ValidityEndDate%.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" jest przeterminowany. Data zakończenia ważności %ValidityEndDate%.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartının vadesi geçti. Geçerlilik bitiş tarihi %ValidityEndDate%.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",             TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%",            TableRow.LineNumber);
					ErrorText = StrReplace(ErrorText, "%ValidityEndDate%",  GiftCertificateDetails.ValidityEndDate);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
					
				EndIf;
			EndIf;
			
			If TypeOf(Object) = Type("DocumentObject.ReturnOfGiftCards") Then
				If Not GiftCertificateDetails.Nominal = GiftCertificateDetails.Balance Then
					
					ErrorText = NStr("vi = 'Phiếu quà tặng %Certificate% trong dòng %LineNumber% danh sách ""%TabularSection%"" có số dư %Balance% %Currency% khi mệnh giá là %Nominal% %Currency% và không hợp lệ để trả lại.';
									|ru = 'Подарочный сертификат %Certificate% в строке %LineNumber% списка ""%TabularSection%"" имеет остаток %Balance% %Currency% при номинале в %Nominal% %Currency% и недоступен для возврата.';
									|en = 'The balance of the %Certificate% gift card in row %LineNumber% of the %TabularSection% list is equal to %Balance% %Currency%. The gift card amount is %Nominal% %Currency%. The gift card cannot be returned.'; fa = 'The balance of the %Certificate% gift card in row %LineNumber% of the %TabularSection% list is equal to %Balance% %Currency%. The gift card amount is %Nominal% %Currency%. The gift card cannot be returned.';
									|it = 'Il buono regalo %Certificate% nella stringa %LineNumber% dell''elenco ""%TabularSection%"" presenta saldi %Balance%%Currency% al valore nominale in %Nominal% %Currency% e non è disponibile per il reso.';
									|pl = 'Certyfikat podarunkowy %Certificate% w wierszu %LineNumber% listy ""%TabularSection%"" ma resztę %Balance% %Currency% przy wartości nominalnej %Nominal% %Currency% i jest niedostępny dla zwrotu.';
									|tr = '""%TabularSection%"" listesinin %LineNumber% satırındaki %Certificate% hediye kartının nominal değeri %Nominal% %Currency% olan %Balance% %Currency% bakiyesi var ve iade için uygun değil.'");
					ErrorText = StrReplace(ErrorText, "%TabularSection%", SynonymForNameOfTablePart);
					ErrorText = StrReplace(ErrorText, "%Certificate%",  TableRow.GiftCertificate);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
					ErrorText = StrReplace(ErrorText, "%Balance%",     GiftCertificateDetails.Balance);
					ErrorText = StrReplace(ErrorText, "%Currency%",      GiftCertificateDetails.Currency);
					ErrorText = StrReplace(ErrorText, "%Nominal%",     GiftCertificateDetails.Nominal);
					
					Common.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, TableRow.LineNumber, "GiftCertificate"),
						,
						Cancel);
					
				EndIf;
			EndIf;
			
		EndIf;
	EndDo;
	
	If TypeOf(Object) = Type("DocumentObject.OBEntry") 
		Or TypeOf(Object) = Type("DocumentObject.OBEntrySalesForPastPeriods") Then
		
		CardType = Common.ObjectAttributeValue(Object.GiftCertificateKind, "CardType");
		
		Query = New Query("
		|SELECT
		|	Table.GiftCertificateKind AS GiftCertificateKind,
		|	Table.Barcode AS Barcode,
		|	Table.MagneticCode AS MagneticCode,
		|	Table.BarcodeLength AS BarcodeLength,
		|	Table.MagneticCodeLength AS MagneticCodeLength,
		|	Table.LineNumber AS LineNumber
		|INTO Table
		|FROM
		|	&GiftCertificates AS Table
		|;
		|
		|SELECT
		|	Table.LineNumber AS LineNumber
		|INTO CorrectCodes
		|FROM
		|	Table AS Table
		|		INNER JOIN Catalog.GiftCertificateKinds.GiftCertificateCodeTemplates AS GiftCertificateCodeTemplates
		|		ON GiftCertificateCodeTemplates.Ref = Table.GiftCertificateKind
		|	AND &CheckMagneticCode
		|	AND &CheckBarcode
		|;
		|SELECT
		|	Table.LineNumber AS LineNumber,
		|	Table.MagneticCode AS MagneticCode,
		|	Table.Barcode AS Barcode
		|FROM
		|	Table
		|WHERE
		|	Table.LineNumber NOT IN (SELECT T.LineNumber FROM CorrectCodes AS T)
		|");
		
		GiftCertificates = TabularSection.Unload(); // ValueTable
		GiftCertificates.Columns.Add("GiftCertificateKind", New TypeDescription("CatalogRef.GiftCertificateKinds"));
		GiftCertificates.Columns.Add("BarcodeLength",            Common.TypeDescriptionNumber(3,0));
		GiftCertificates.Columns.Add("MagneticCodeLength",       Common.TypeDescriptionNumber(3,0));
		For Each TSRow In GiftCertificates Do
			TSRow.GiftCertificateKind = Object.GiftCertificateKind;
			TSRow.BarcodeLength = StrLen(TSRow.Barcode);
			TSRow.MagneticCodeLength = StrLen(TSRow.MagneticCode);
		EndDo;
		
		CardType = Common.ObjectAttributeValue(Object.GiftCertificateKind, "CardType");
		If CardType = Enums.CardTypes.Magnetic Or CardType = Enums.CardTypes.Mixed Then
			Query.Text = StrReplace(Query.Text, "AND &CheckMagneticCode", 
				"AND GiftCertificateCodeTemplates.StartOfMagneticCodeRange <= Table.MagneticCode
				|	AND GiftCertificateCodeTemplates.EndOfMagneticCodeRange  >= Table.MagneticCode
				|	AND GiftCertificateCodeTemplates.MagneticCodeLength           = Table.MagneticCodeLength");
		Else	
			Query.Text = StrReplace(Query.Text, "AND &CheckMagneticCode", "");
		EndIf;
		If CardType = Enums.CardTypes.Barcode_ Or CardType = Enums.CardTypes.Mixed Then
			Query.Text = StrReplace(Query.Text, "AND &CheckBarcode", 
				"AND GiftCertificateCodeTemplates.StartOfBarcodeRange <= Table.Barcode
				|	AND GiftCertificateCodeTemplates.EndOfBarcodeRange  >= Table.Barcode
				|	AND GiftCertificateCodeTemplates.BarcodeLength           = Table.BarcodeLength");
		Else	
			Query.Text = StrReplace(Query.Text, "AND &CheckBarcode", "");
		EndIf;
		
		Query.SetParameter("GiftCertificates", GiftCertificates);
		
		If CardType = Enums.CardTypes.Magnetic Then
			ErrorText = NStr("vi = 'Mã thẻ từ %MagneticCode% trong dòng %LineNumber% phần bảng ""%TabularSection%"" không đáp ứng yêu cầu của dạng phiếu quà tặng """"%GiftCertificateKind%""""';
							|ru = 'Магнитный код %MagneticCode% в строке %LineNumber% табличной части ""%TabularSection%"" не соответствует требованиям вида подарочного сертификата """"%GiftCertificateKind%""""';
							|en = 'The %MagneticCode% magnetic code in row %LineNumber% of the %TabularSection% table does not meet the requirements for the %GiftCertificateKind% gift card kind'; fa = 'The %MagneticCode% magnetic code in row %LineNumber% of the %TabularSection% table does not meet the requirements for the %GiftCertificateKind% gift card kind';
							|it = 'Il codice magnetico %MagneticCode% nella stringa %LineNumber% della tabella %TabularSection% non corrisponde ai requisiti del tipo di buono regalo """"%GiftCertificateKind%""""';
							|pl = 'Kod magnetyczny %MagneticCode% w wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" nie spełnia wymagań rodzaju certyfikatu podarunkowego """"%GiftCertificateKind%""""';
							|tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırındaki %MagneticCode% manyetik kodu, """"%GiftCertificateKind%"""" hediye kartı türünün gereksinimlerine uygun değil'");
		ElsIf CardType = Enums.CardTypes.Barcode_  Then
			ErrorText = NStr("vi = 'Mã vạch %Barcode% trong dòng %LineNumber% phần bảng ""%TabularSection%"" không đáp ứng yêu cầu của dạng phiếu quà tặng """"%GiftCertificateKind%""""';
							|ru = 'Штрихкод %Barcode% в строке %LineNumber% табличной части ""%TabularSection%"" не соответствует требованиям вида подарочного сертификата """"%GiftCertificateKind%""""';
							|en = 'The %Barcode% barcode in row %LineNumber% of the %TabularSection% table does not meet the requirements for the %GiftCertificateKind% gift card kind'; fa = 'The %Barcode% barcode in row %LineNumber% of the %TabularSection% table does not meet the requirements for the %GiftCertificateKind% gift card kind';
							|it = 'Il codice a barre %Barcode% nella stringa %LineNumber% della tabella ""%TabularSection%"" non corrisponde ai requisiti del tipo di buono regalo """"%GiftCertificateKind%""""';
							|pl = 'Kod kreskowy %Barcode% w wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" nie spełnia wymagań certyfikatu podarunkowego """"%GiftCertificateKind%""""';
							|tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırındaki %Barcode% barkodu, """"%GiftCertificateKind%"""" hediye kartı türü gereksinimlerine uygun değil'");
		Else
			ErrorText = NStr("vi = 'Mã thẻ từ %MagneticCode% hoặc mã vạch %Barcode% trong dòng %LineNumber% phần bảng ""%TabularSection%"" không đáp ứng yêu cầu của dạng phiếu quà tặng """"%GiftCertificateKind%""""';
							|ru = 'Магнитный код %MagneticCode% или штрихкод %Barcode% в строке %LineNumber% табличной части ""%TabularSection%"" не соответствует требованиям вида подарочного сертификата """"%GiftCertificateKind%""""';
							|en = 'The %MagneticCode% magnetic code or the %Barcode% barcode in row %LineNumber% of the %TabularSection% table does not meet the requirements for the %GiftCertificateKind% gift card kind'; fa = 'The %MagneticCode% magnetic code or the %Barcode% barcode in row %LineNumber% of the %TabularSection% table does not meet the requirements for the %GiftCertificateKind% gift card kind';
							|it = 'Il codice magnetico %MagneticCode% o il codice a barre %Barcode% nella stringa %LineNumber% della tabella ""%TabularSection%"" non corrisponde ai requisiti del tipo di buono regalo """"%GiftCertificateKind%""""';
							|pl = 'Kod magnetyczny %MagneticCode% lub kod kreskowy %Barcode% w wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" nie spełnia wymagań rodzaju certyfikatu podarunkowego """"%GiftCertificateKind%""""';
							|tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırındaki manyetik kod %MagneticCode% veya barkod %Barcode%, """"%GiftCertificateKind%"""" hediye kartı türü gereksinimlerine uygun değil'");
		EndIf;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			Text = ErrorText;
			Text = StrReplace(Text, "%TabularSection%", SynonymForNameOfTablePart);
			Text = StrReplace(Text, "%GiftCertificateKind%",             Object.GiftCertificateKind);
			Text = StrReplace(Text, "%Barcode%",     Selection.Barcode);
			Text = StrReplace(Text, "%MagneticCode%", Selection.MagneticCode);
			Text = StrReplace(Text, "%LineNumber%",  Selection.LineNumber);
			
			Common.MessageToUser(
				Text,
				Object,
				CommonClientServer.PathToTabularSection(TabularSectionName, Selection.LineNumber, "GiftCertificate"),
				,
				Cancel);
		
		EndDo;
		
		Query = New Query("
		|SELECT
		|	Table.Barcode AS Barcode,
		|	Table.MagneticCode AS MagneticCode,
		|	Table.LineNumber AS LineNumber,
		|	Table.SerialNumber AS SerialNumber
		|INTO Table
		|FROM
		|	&GiftCertificates AS Table
		|;
		|
		|SELECT
		|	Table.Barcode AS Barcode,
		|	Table.MagneticCode AS MagneticCode,
		|	Table.LineNumber AS LineNumber,
		|	Table.SerialNumber AS SerialNumber,
		|	ISNULL(CatalogGiftCertificatesByBarcode.Ref, VALUE(Catalog.GiftCertificates.EmptyRef)) AS BarcodeGiftCertificate,
		|	ISNULL(CatalogGiftCertificatesByMagneticCode.Ref, VALUE(Catalog.GiftCertificates.EmptyRef)) AS MagneticCodeGiftCertificate,
		|	ISNULL(CatalogGiftCertificateBySerialNumber.Ref, VALUE(Catalog.GiftCertificates.EmptyRef)) AS GiftCertificateBySerialNumber
		|FROM
		|	Table AS Table
		|		LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificatesByBarcode
		|		ON CatalogGiftCertificatesByBarcode.Barcode = Table.Barcode
		|		AND CatalogGiftCertificatesByBarcode.Owner = &GiftCertificateKind
		|
		|		LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificatesByMagneticCode
		|		ON CatalogGiftCertificatesByMagneticCode.MagneticCode = Table.MagneticCode
		|		AND CatalogGiftCertificatesByMagneticCode.Owner = &GiftCertificateKind
		|
		|		LEFT JOIN Catalog.GiftCertificates AS CatalogGiftCertificateBySerialNumber
		|		ON CatalogGiftCertificateBySerialNumber.Code = Table.SerialNumber
		|");
		
		Query.SetParameter("GiftCertificateKind", Object.GiftCertificateKind);
		Query.SetParameter("GiftCertificates", TabularSection.Unload());
		
		Table = Query.Execute().Unload();
		
		For Each TSRow In GiftCertificates Do  // LineOfATabularSection
			
			If Not ValueIsFilled(TSRow.GiftCertificate) Then
				
				FoundRow = Table.FindRows(New Structure("LineNumber", TSRow.LineNumber))[0];
				
				If CardType = Enums.CardTypes.Barcode_ Then
					
					If FoundRow.GiftCertificateBySerialNumber <> FoundRow.BarcodeGiftCertificate Then
						
						Text = NStr("vi = 'Trong dòng %LineNumber% phần bảng ""%TabularSection%"" dữ liệu được điền không chính xác.
						                 |Đối với mã vạch %Barcode% phiếu quà tặng %1%.
						                 |Đối với số sê-ri %SerialNumber% phiếu quà tặng %2%.';
						                 |ru = 'В строке %LineNumber% табличной части ""%TabularSection%"" данные заполнены некорректно.
						                 |Для штрихкода %Barcode% сертификат %1%.
						                 |Для серийного номера %SerialNumber% сертификат %2%.';
						                 |en = 'Row %LineNumber% of the %TabularSection% table contains incorrect data.
						                 |For the %Barcode% barcode, gift card %1% is specified.
						                 |For serial number %SerialNumber%, gift card %2% is specified.'; fa = 'Row %LineNumber% of the %TabularSection% table contains incorrect data.
						                 |For the %Barcode% barcode, gift card %1% is specified.
						                 |For serial number %SerialNumber%, gift card %2% is specified.';
						                 |it = 'Nella stringa %LineNumber% della tabella ""%TabularSection%"" i dati sono compilati in modo errato.
						                 |Per il codice a barre %Barcode% il buono %1%.
						                 |Per il numero di serie%SerialNumber% buono %2%.';
						                 |pl = 'W wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" dane są wypełnione niepoprawnie.
						                 |Dla kodu kreskowego %Barcode% certyfikat %1%.
						                 |Dla numeru seryjnego %SerialNumber% certyfikat %2%.';
						                 |tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırında veriler yanlış dolduruldu.
						                 |Barkod %Barcode% sertifika %1% için.
						                 |Seri numarası %SerialNumber% sertifika %2% ​​için.'");
						Text = StrReplace(Text, "%TabularSection%", SynonymForNameOfTablePart);
						Text = StrReplace(Text, "%Barcode%",      FoundRow.Barcode);
						Text = StrReplace(Text, "%SerialNumber%", FoundRow.SerialNumber);
						Text = StrReplace(Text, "%MagneticCode%",  FoundRow.MagneticCode);
						Text = StrReplace(Text, "%LineNumber%",   FoundRow.LineNumber);
						Text = StrReplace(Text, "%1%", ?(ValueIsFilled(FoundRow.BarcodeGiftCertificate),FoundRow.BarcodeGiftCertificate,NStr("vi = 'không tìm thấy';
																																			|ru = 'не найден';
																																			|en = 'not found'; fa = 'not found';
																																			|it = 'non trovato';
																																			|pl = 'nie znaleziono';
																																			|tr = 'bulunamadı'")));
						Text = StrReplace(Text, "%2%", ?(ValueIsFilled(FoundRow.GiftCertificateBySerialNumber),FoundRow.GiftCertificateBySerialNumber,NStr("vi = 'không tìm thấy';
																																							|ru = 'не найден';
																																							|en = 'not found'; fa = 'not found';
																																							|it = 'non trovato';
																																							|pl = 'nie znaleziono';
																																							|tr = 'bulunamadı'")));
						
						Common.MessageToUser(
							Text,
							Object,
							CommonClientServer.PathToTabularSection(TabularSectionName, FoundRow.LineNumber, "GiftCertificate"),
							,
							Cancel);
					EndIf;
					
				ElsIf CardType = Enums.CardTypes.Magnetic Then
					
					If FoundRow.GiftCertificateBySerialNumber <> FoundRow.MagneticCodeGiftCertificate Then
						
						Text = NStr("vi = 'Trong dòng %LineNumber% phần bảng ""%TabularSection%"" dữ liệu được điền không chính xác.
						                 |Đối với mã thẻ từ %MagneticCode% phiếu quà tặng %1%.
						                 |Đối với số sê-ri %SerialNumber% phiếu quà tặng %2%.';
						                 |ru = 'В строке %LineNumber% табличной части ""%TabularSection%"" данные заполнены некорректно.
						                 |Для магнитного кода %MagneticCode% сертификат %1%.
						                 |Для серийного номера %SerialNumber% сертификат %2%.';
						                 |en = 'Row %LineNumber% of the %TabularSection% table contains incorrect data.
						                 |For the %MagneticCode% magnetic code, gift card %1% is specified.
						                 |For serial number %SerialNumber%, gift card %2% is specified.'; fa = 'Row %LineNumber% of the %TabularSection% table contains incorrect data.
						                 |For the %MagneticCode% magnetic code, gift card %1% is specified.
						                 |For serial number %SerialNumber%, gift card %2% is specified.';
						                 |it = 'Nella stringa %LineNumber% della tabella ""%TabularSection%"" i dati sono compilati in modo errato. 
						                 |Per il codice magnetico %MagneticCode%il buono %1%.
						                 |Per il numero di serie %SerialNumber% il buono %2%.';
						                 |pl = 'W wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" dane są wypełnione niepoprawnie.
						                 |Dla kodu magnetycznego %MagneticCode% certyfikat %1%.
						                 |Dla numeru seryjnego %SerialNumber% certyfikat %2%.';
						                 |tr = '""%TabularSection%"" tablo bölümünün %LineNumber% satırında veriler yanlış dolduruldu.
						                 |%MagneticCode% manyetik kodu için sertifika %1%''dir.
						                 |%SerialNumber% Seri numarası için sertifika %2%.'");
						Text = StrReplace(Text, "%TabularSection%", SynonymForNameOfTablePart);
						Text = StrReplace(Text, "%Barcode%",      FoundRow.Barcode);
						Text = StrReplace(Text, "%SerialNumber%", FoundRow.SerialNumber);
						Text = StrReplace(Text, "%MagneticCode%",  FoundRow.MagneticCode);
						Text = StrReplace(Text, "%LineNumber%",   FoundRow.LineNumber);
						Text = StrReplace(Text, "%1%", ?(ValueIsFilled(FoundRow.MagneticCodeGiftCertificate),FoundRow.MagneticCodeGiftCertificate,NStr("vi = 'không tìm thấy';
																																						|ru = 'не найден';
																																						|en = 'not found'; fa = 'not found';
																																						|it = 'non trovato';
																																						|pl = 'nie znaleziono';
																																						|tr = 'bulunamadı'")));
						Text = StrReplace(Text, "%2%", ?(ValueIsFilled(FoundRow.GiftCertificateBySerialNumber),FoundRow.GiftCertificateBySerialNumber,NStr("vi = 'không tìm thấy';
																																							|ru = 'не найден';
																																							|en = 'not found'; fa = 'not found';
																																							|it = 'non trovato';
																																							|pl = 'nie znaleziono';
																																							|tr = 'bulunamadı'")));
						
						Common.MessageToUser(
							Text,
							Object,
							CommonClientServer.PathToTabularSection(TabularSectionName, FoundRow.LineNumber, "GiftCertificate"),
							,
							Cancel);
						
					EndIf;
					
				Else
					
					If FoundRow.GiftCertificateBySerialNumber <> FoundRow.MagneticCodeGiftCertificate
						Or FoundRow.GiftCertificateBySerialNumber <> FoundRow.BarcodeGiftCertificate Then
						
						Text = NStr("vi = 'Trong dòng %LineNumber% phần bảng ""%TabularSection%"" dữ liệu được điền không chính xác.
						                 |Đối với mã thẻ từ %MagneticCode% phiếu quà tặng %1%.
						                 |Đối với mã vạch %Barcode% phiếu quà tặng %2%.
						                 |Đối với số sê-ri %SerialNumber% phiếu quà tặng %3%.';
						                 |ru = 'В строке %LineNumber% табличной части ""%TabularSection%"" данные заполнены некорректно.
						                 |Для магнитного кода %MagneticCode% сертификат %1%.
						                 |Для штрихкода %Barcode% сертификат %2%.
						                 |Для серийного номера %SerialNumber% сертификат %3%.';
						                 |en = 'Row %LineNumber% of the %TabularSection% table contains incorrect data.
						                 |For the %MagneticCode% magnetic code, gift card %1% is specified.
						                 |For the %Barcode% barcode, gift card %2% is specified.
						                 |For serial number %SerialNumber%, gift card %3% is specified.'; fa = 'Row %LineNumber% of the %TabularSection% table contains incorrect data.
						                 |For the %MagneticCode% magnetic code, gift card %1% is specified.
						                 |For the %Barcode% barcode, gift card %2% is specified.
						                 |For serial number %SerialNumber%, gift card %3% is specified.';
						                 |it = 'Nella stringa %LineNumber% della tabella ""%TabularSection%"" i dati sono compilati in modo errato.
						                 |Per il codice magnetico %MagneticCode% il buono %1%.
						                 |Per il codice a barre %Barcode% il buono %2%.
						                 |Per il numero di serie %SerialNumber% il buono %3%.';
						                 |pl = 'W wierszu %LineNumber% sekcji tabelarycznej ""%TabularSection%"" dane są wypełnione niepoprawnie.
						                 |Dla kodu magnetycznego %MagneticCode% certyfikat %1%.
						                 |Dla kodu kreskowego %Barcode% certyfikat %2%.
						                 |Dla numeru seryjnego %SerialNumber% certyfikat %3%.';
						                 |tr = '""%TabularSection%"" tablo parçasının %LineNumber% satırındaki veriler yanlış dolduruldu.
						                 |Manyetik kod için %MagneticCode% sertifikası %1%.
						                 |Barkod için %Barcode% sertifikası %2%.
						                 | Seri numarası için %SerialNumber% sertifikası %3%.'");
						Text = StrReplace(Text, "%TabularSection%", SynonymForNameOfTablePart);
						Text = StrReplace(Text, "%Barcode%",      FoundRow.Barcode);
						Text = StrReplace(Text, "%SerialNumber%", FoundRow.SerialNumber);
						Text = StrReplace(Text, "%MagneticCode%",  FoundRow.MagneticCode);
						Text = StrReplace(Text, "%LineNumber%",   FoundRow.LineNumber);
						Text = StrReplace(Text, "%1%", ?(ValueIsFilled(FoundRow.MagneticCodeGiftCertificate),FoundRow.MagneticCodeGiftCertificate,NStr("vi = 'không tìm thấy';
																																						|ru = 'не найден';
																																						|en = 'not found'; fa = 'not found';
																																						|it = 'non trovato';
																																						|pl = 'nie znaleziono';
																																						|tr = 'bulunamadı'")));
						Text = StrReplace(Text, "%2%", ?(ValueIsFilled(FoundRow.BarcodeGiftCertificate),FoundRow.BarcodeGiftCertificate,NStr("vi = 'không tìm thấy';
																																			|ru = 'не найден';
																																			|en = 'not found'; fa = 'not found';
																																			|it = 'non trovato';
																																			|pl = 'nie znaleziono';
																																			|tr = 'bulunamadı'")));
						Text = StrReplace(Text, "%3%", ?(ValueIsFilled(FoundRow.GiftCertificateBySerialNumber),FoundRow.GiftCertificateBySerialNumber,NStr("vi = 'không tìm thấy';
																																							|ru = 'не найден';
																																							|en = 'not found'; fa = 'not found';
																																							|it = 'non trovato';
																																							|pl = 'nie znaleziono';
																																							|tr = 'bulunamadı'")));
						
						Common.MessageToUser(
							Text,
							Object,
							CommonClientServer.PathToTabularSection(TabularSectionName, FoundRow.LineNumber, "GiftCertificate"),
							,
							Cancel);
						
					EndIf;
					
				EndIf;
			
			EndIf;
		EndDo;
		
	EndIf;
	
	KeyAttributes = New Array;
	KeyAttributes.Add("GiftCertificate");
	TMCommonUse.CheckForDuplicatesOfTSStrings(Object, TabularSectionName, KeyAttributes, Cancel, SynonymForNameOfTablePart);
	
EndProcedure

#EndRegion

#Region GiftCertificateCancellation

#EndRegion

#EndRegion
