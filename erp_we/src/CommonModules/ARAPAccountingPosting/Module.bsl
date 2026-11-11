#Region Public

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - a recordable document.
//  Properties - See DocumentsPosting.DocumentProperties.
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism.
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	Parameters.ThereAreDerivedMotions = True;
	
	// For the Register of accumulation of percentages, the mechanism of conducting documents is used for documents
	// Input of the results of the calculations and the Reverse
	If TypeOf(Document) = Type("DocumentObject.ReversingEntry") Then
		DocumentsForDiscounting = AccumulationRegisters.DiscountInterestExpense.GetTypesOfDocumentsInvolvedInDiscounting();
		MovementRegisteredRecordsInterestExpenseDiscounting = DocumentsForDiscounting.Find(TypeOf(Document.ReversedDocument)) <> Undefined;
	Else
		MovementRegisteredRecordsInterestExpenseDiscounting = TypeOf(Document) = Type("DocumentObject.OBEntryARAP");
	EndIf;
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingPlannedShipments);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingPlannedDeliveries);
		
		If MovementRegisteredRecordsInterestExpenseDiscounting Then
			Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.DiscountInterestExpense);
		EndIf;
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting);
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting);
		If MovementRegisteredRecordsInterestExpenseDiscounting Then
			Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.DiscountInterestExpense);
		EndIf;
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDocuments);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDocuments);
		If MovementRegisteredRecordsInterestExpenseDiscounting Then
			Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.DiscountInterestExpense);
		EndIf;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of KeyAndValue - Contains the texts of the cancellation requests, where:
// 		* Key - String - full name of the register.
// 		* Value - String - query text.
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;
	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.CustomersARAPAccounting;
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;
	
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryText = "
		|SELECT
		|	DocumentsStorno.Ref AS Recorder,
		|	DocumentsStorno.Date   AS Period,
		|	DocumentsStorno.Date   AS RecorderDate,
		|	DocumentsStorno.Number  AS RecorderNumber,
		|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
		|	&SelectionFields1,
		|	TRUE AS ReversingEntry,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS CorPartnerAccountingDimension,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CalculationObjectReceiver,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
		|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
		|	0 AS AmountReceiver,
		|	FALSE AS ByDataOfSourceARAPObject,
		|	UUID(DocumentsStorno.Ref) AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RestoreDebtPrepaymentUponARAPAccountingStorno) AS BusinessTransactionSetting,
		|	VALUE(Enum.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno) AS BusinessOperation,
		|	CASE WHEN RegisterData.Sum <> 0
		|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
		|		ELSE VALUE(Enum.SettlementOperations.EmptyRef)
		|	END AS SettlementTransaction
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS RegisterData
		|	INNER JOIN
		|		&DocumentName AS DocumentsStorno
		|	ON
		|		RegisterData.Recorder = DocumentsStorno.ReversedDocument
		|		AND DocumentsStorno.Ref IN (&Ref)
		|WHERE
		|	NOT RegisterData.ReversingEntry
		|";
		
		ArrayOfSelectionFields = New Array;
		
		Exceptions = New Array;
		
		Exceptions.Add(RegisterMetadata.StandardAttributes.Active.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.LineNumber.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.Recorder.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.Period.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ReversingEntry.Name);
		Exceptions.Add(RegisterMetadata.Attributes.LinkedDocument.Name);
		Exceptions.Add(RegisterMetadata.Attributes.RecorderDate.Name);
		
		// Transfers between calculation objects are not needed in storno records.
		Exceptions.Add(RegisterMetadata.Attributes.CorARAPObject.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CorPartnerAccountingDimension.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CalculationObjectReceiver.Name);
		Exceptions.Add(RegisterMetadata.Attributes.DestinationAccountingDimensionByPartners.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CurrencyReceiver.Name);
		Exceptions.Add(RegisterMetadata.Attributes.AmountReceiver.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ByDataOfSourceARAPObject.Name);
		
		// They are used in the distribution of mutual settlements, the initial ones for Registered Records are storno preserved
		Exceptions.Add(RegisterMetadata.Attributes.FinRecordID.Name);
		Exceptions.Add(RegisterMetadata.Attributes.BusinessTransactionSetting.Name);
		Exceptions.Add(RegisterMetadata.Attributes.BusinessOperation.Name);
		Exceptions.Add(RegisterMetadata.Attributes.SettlementTransaction.Name);
		Exceptions.Add(RegisterMetadata.Attributes.RateARAPCurrencyNumerator.Name);
		Exceptions.Add(RegisterMetadata.Attributes.RateARAPCurrencyDenominator.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ExchangeRateNumeratorOfManSCurrency.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ExchangeRateDenominatorCurrencyMan.Name);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
		
		NonInvertibleBankingDetails = New Array;
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.RateARAPCurrencyNumerator);
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.RateARAPCurrencyDenominator);
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.ExchangeRateNumeratorOfManSCurrency);
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.ExchangeRateDenominatorCurrencyMan);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(NonInvertibleBankingDetails, 
			ArrayOfSelectionFields,
			New Array);
		
		SelectionFieldText= StrConcat(ArrayOfSelectionFields,"," + Chars.LF);
		QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFieldText);
		QueryText = StrReplace(QueryText, "&DocumentName", MetadataOfDocument.FullName());
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
		
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.VendorsARAPAccounting;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryTemplate = "
		|SELECT
		|	DocumentsStorno.Ref AS Recorder,
		|	DocumentsStorno.Date   AS Period,
		|	DocumentsStorno.Date   AS RecorderDate,
		|	DocumentsStorno.Number  AS RecorderNumber,
		|	RegisterData.AccountingDimensionByPartners.Contract AS Contract,
		|	&SelectionFields1,
		|	DocumentsStorno.ReversedDocument AS LinkedDocument,
		|	TRUE AS ReversingEntry,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS CorPartnerAccountingDimension,
		|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CalculationObjectReceiver,
		|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS DestinationAccountingDimensionByPartners,
		|	VALUE(Catalog.Currencies.EmptyRef) AS CurrencyReceiver,
		|	0 AS AmountReceiver,
		|	FALSE AS ByDataOfSourceARAPObject,
		|	UUID(DocumentsStorno.Ref) AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RestoreDebtPrepaymentUponARAPAccountingStorno) AS BusinessTransactionSetting,
		|	VALUE(Enum.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno) AS BusinessOperation,
		|	CASE WHEN RegisterData.Sum <> 0
		|		THEN VALUE(Enum.SettlementOperations.ARAPAdjustment)
		|		ELSE VALUE(Enum.SettlementOperations.EmptyRef)
		|	END AS SettlementTransaction
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS RegisterData
		|	INNER JOIN
		|		&DocumentName AS DocumentsStorno
		|	ON
		|		RegisterData.Recorder = DocumentsStorno.ReversedDocument
		|		AND DocumentsStorno.Ref IN (&Ref)
		|WHERE
		|	NOT RegisterData.ReversingEntry
		|";
		
		ArrayOfSelectionFields = New Array;
		
		Exceptions = New Array;
		Exceptions.Add(RegisterMetadata.StandardAttributes.Active.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.LineNumber.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.Recorder.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.Period.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ReversingEntry.Name);
		Exceptions.Add(RegisterMetadata.Attributes.LinkedDocument.Name);
		Exceptions.Add(RegisterMetadata.Attributes.RecorderDate.Name);
		
		// Transfers between calculation objects are not needed in storno records.
		Exceptions.Add(RegisterMetadata.Attributes.CorARAPObject.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CorPartnerAccountingDimension.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CalculationObjectReceiver.Name);
		Exceptions.Add(RegisterMetadata.Attributes.DestinationAccountingDimensionByPartners.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CurrencyReceiver.Name);
		Exceptions.Add(RegisterMetadata.Attributes.AmountReceiver.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ByDataOfSourceARAPObject.Name);
		
		// They are used in the distribution of mutual settlements, the initial ones for Registered Records are storno preserved
		Exceptions.Add(RegisterMetadata.Attributes.FinRecordID.Name);
		Exceptions.Add(RegisterMetadata.Attributes.BusinessTransactionSetting.Name);
		Exceptions.Add(RegisterMetadata.Attributes.BusinessOperation.Name);
		Exceptions.Add(RegisterMetadata.Attributes.SettlementTransaction.Name);
		Exceptions.Add(RegisterMetadata.Attributes.RateARAPCurrencyNumerator.Name);
		Exceptions.Add(RegisterMetadata.Attributes.RateARAPCurrencyDenominator.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ExchangeRateNumeratorOfManSCurrency.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ExchangeRateDenominatorCurrencyMan.Name);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
		
		NonInvertibleBankingDetails = New Array;
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.RateARAPCurrencyNumerator);
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.RateARAPCurrencyDenominator);
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.ExchangeRateNumeratorOfManSCurrency);
		NonInvertibleBankingDetails.Add(RegisterMetadata.Attributes.ExchangeRateDenominatorCurrencyMan);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(NonInvertibleBankingDetails, 
			ArrayOfSelectionFields,
			New Array);
		
		SelectionFieldText= StrConcat(ArrayOfSelectionFields,"," + Chars.LF);
		QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
		QueryText = StrReplace(QueryText, "&DocumentName", MetadataOfDocument.FullName());
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.DiscountInterestExpense;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryTemplate = "
		|SELECT
		|	DocumentsStorno.Ref AS Recorder,
		|	DocumentsStorno.Date   AS Period,
		|	DocumentsStorno.Date   AS RecorderDate,
		|	DocumentsStorno.Number  AS RecorderNumber,
		|	&SelectionFields1,
		|	DocumentsStorno.ReversedDocument AS LinkedDocument,
		|	TRUE AS ReversingEntry
		|FROM
		|	AccumulationRegister.DiscountInterestExpense AS RegisterData
		|	INNER JOIN
		|		&DocumentName AS DocumentsStorno
		|	ON
		|		RegisterData.Recorder = DocumentsStorno.ReversedDocument
		|		AND DocumentsStorno.Ref IN (&Ref)
		|WHERE
		|	NOT RegisterData.ReversingEntry
		|";
		
		ArrayOfSelectionFields = New Array;
		
		Exceptions = New Array;
		Exceptions.Add(RegisterMetadata.StandardAttributes.Active.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.LineNumber.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.Recorder.Name);
		Exceptions.Add(RegisterMetadata.StandardAttributes.Period.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ReversingEntry.Name);
		Exceptions.Add(RegisterMetadata.Attributes.DiscountRate.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ActualDebtWithoutVAT.Name);
		Exceptions.Add(RegisterMetadata.Attributes.DiscountedDebtWithoutVAT.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CalculatedInterestBalance.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ActualDebtWithoutVATCompl.Name);
		Exceptions.Add(RegisterMetadata.Attributes.DiscountedDebtWithoutVATCompl.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CalculatedInterestBalanceCompl.Name);
		Exceptions.Add(RegisterMetadata.Attributes.ActualDebtWithoutVATMan.Name);
		Exceptions.Add(RegisterMetadata.Attributes.DiscountedDebtWithoutVATMan.Name);
		Exceptions.Add(RegisterMetadata.Attributes.CalculatedInterestBalanceMan.Name);
		
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
			
		SelectionFieldText= StrConcat(ArrayOfSelectionFields,"," + Chars.LF);
		QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
		QueryText = StrReplace(QueryText, "&DocumentName", MetadataOfDocument.FullName());
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of KeyAndValue:
//		* Key - String - The name of the temporary register change table.
//		* Value - String - query text.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of settlements.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	NewOnlineARAPAccounting = Constants.NewOnlineARAPAccounting.Get();
	NameSettlementsWithClients = Metadata.AccumulationRegisters.CustomersARAPAccounting.Name;
	NameSettlementsWithSuppliers = Metadata.AccumulationRegisters.VendorsARAPAccounting.Name;
	
	ArrayOfContracts = New Array();
	
	// Filling in the analytics is brought forward
	// because to check the receivers when carrying out the debt offset document
	// between two organizations and one counterparty, both calculation tables are required
	// because the debt receiver may be in a different register
	TableSettlementsWithCustomers = Undefined;
	TablesForRegisteredRecords.Property("Table" + "CustomersARAPAccounting", TableSettlementsWithCustomers);
	If ValueIsFilled(TableSettlementsWithCustomers) Then
		CheckSetCalculationObjects(TableSettlementsWithCustomers,Cancel,True);
		CheckAndFillOutPartnerAccountingAnalytics(TableSettlementsWithCustomers);
		CommonClientServer.SupplementArray(ArrayOfContracts, TableSettlementsWithCustomers.UnloadColumn("Contract"));
	EndIf;
	If TableSettlementsWithCustomers <> Undefined And TableSettlementsWithCustomers.Columns.Find("ReversingEntry") = Undefined Then
		TableSettlementsWithCustomers.Columns.Add("ReversingEntry", New TypeDescription("Boolean"));
	EndIf;
	
	TableSettlementsWithSuppliers = Undefined;
	TablesForRegisteredRecords.Property("Table" + "VendorsARAPAccounting", TableSettlementsWithSuppliers);
	If ValueIsFilled(TableSettlementsWithSuppliers) Then
		CheckSetCalculationObjects(TableSettlementsWithSuppliers, Cancel, False);
		CheckAndFillOutPartnerAccountingAnalytics(TableSettlementsWithSuppliers);
		CommonClientServer.SupplementArray(ArrayOfContracts, TableSettlementsWithSuppliers.UnloadColumn("Contract")); 
	EndIf;
	If TableSettlementsWithSuppliers <> Undefined And TableSettlementsWithSuppliers.Columns.Find("ReversingEntry") = Undefined Then
		TableSettlementsWithSuppliers.Columns.Add("ReversingEntry", New TypeDescription("Boolean"));
	EndIf;
	
	ArrayOfContracts = CommonClientServer.CollapseArray(ArrayOfContracts);
	ProceduresForOffsettingPaymentsOfInvoicesContracts = Common.ObjectsAttributeValue(ArrayOfContracts, "OffsetOrderOfPaymentsAndInvoices");
	
	#Region CustomersARAPAccounting
	
	If ValueIsFilled(TableSettlementsWithCustomers) Then
		
			DocumentType = TypeOf(RegisterRecords.CustomersARAPAccounting.Filter.Recorder.Value);
			AddFillInOrderOfOperation(TableSettlementsWithCustomers, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
			
			TableOfReceivers = New ValueTable;
			TableOfReceivers.Columns.Add("DestinationAccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
			TableOfReceivers.Columns.Add("CalculationObjectReceiver", New TypeDescription("CatalogRef.ARAPObjects"));
			TableOfReceivers.Columns.Add("CurrencyReceiver", New TypeDescription("CatalogRef.Currencies"));
			TableOfReceivers.Columns.Add("ReversingEntry", New TypeDescription("Boolean"));
			
			CheckOrderType =  TableSettlementsWithCustomers.Columns.Find("SaleByOrder") <> Undefined;
			CheckConnectionsOfSourcesReceivers = TableSettlementsWithCustomers.Columns.Find("CalculationObjectReceiver") <> Undefined;
			
			For Each Page1 In TableSettlementsWithCustomers Do
				If CheckOrderType And Not ValueIsFilled(Page1.SaleByOrder) And Page1.SaleByOrder <> Undefined Then
					Page1.SaleByOrder = Undefined;
				EndIf;
				
				If Page1.ReversingEntry = Undefined Then
					Page1.ReversingEntry = False;
				EndIf;
				If CheckConnectionsOfSourcesReceivers Then
					If NewOnlineARAPAccounting Then
						ByDataOfSourceARAPObject = ?(Page1.ByDataOfSourceARAPObject = Undefined,False,Page1.ByDataOfSourceARAPObject);
						AllReceiverFieldsAreFilledIn = ValueIsFilled(Page1.CalculationObjectReceiver)
							+ ValueIsFilled(Page1.DestinationAccountingDimensionByPartners)
							+ ValueIsFilled(Page1.CurrencyReceiver)
							+ (ValueIsFilled(Page1.AmountReceiver) And ValueIsFilled(Page1.Sum));
						If Not ByDataOfSourceARAPObject And AllReceiverFieldsAreFilledIn <> 4 And AllReceiverFieldsAreFilledIn <> 0 Then
							Raise(StrTemplate(NStr("vi = 'Chưa điền đầy đủ đối tượng phân tích hoặc số tiền đích trong các bản ghi kết chuyển theo %1';
													|ru = 'Не полностью заполнена аналитика или сумма приемника в движениях по %1';
													|en = 'The destination dimension or amount in the register records by %1 is not fully filled'; fa = 'The destination dimension or amount in the register records by %1 is not fully filled';
													|it = 'Не полностью заполнена аналитика или сумма приемника в движениях по %1';
													|pl = 'The destination dimension or amount in the register records by %1 is not fully filled';
													|tr = 'Boyut tam olarak veya %1 hareketlerinde hedef tutarına göre doldurulmamış'"),
														NameSettlementsWithClients));
						EndIf;
					EndIf;
				EndIf;
				
				If CheckConnectionsOfSourcesReceivers And ValueIsFilled(Page1.CalculationObjectReceiver) Then
					FillPropertyValues(TableOfReceivers.Add(),New Structure("CalculationObjectReceiver, DestinationAccountingDimensionByPartners, CurrencyReceiver, ReversingEntry",
							Page1.CalculationObjectReceiver, Page1.DestinationAccountingDimensionByPartners, Page1.CurrencyReceiver, Page1.ReversingEntry));
				EndIf;
			EndDo;
			
			If TableOfReceivers.Count() > 0 Then
				TableOfReceivers.GroupBy("CalculationObjectReceiver, DestinationAccountingDimensionByPartners, CurrencyReceiver, ReversingEntry");
				TableSettlementsWithCustomers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency,ReversingEntry");
				TheStructureOfTheSearch = New Structure("ARAPObject,AccountingDimensionByPartners,Currency,ByDataOfSourceARAPObject,ReversingEntry");
				For Each Page1 In TableOfReceivers Do
					TheStructureOfTheSearch.AccountingDimensionByPartners = Page1.DestinationAccountingDimensionByPartners;
					TheStructureOfTheSearch.ARAPObject = Page1.CalculationObjectReceiver;
					TheStructureOfTheSearch.Currency = Page1.CurrencyReceiver;
					TheStructureOfTheSearch.ReversingEntry = Page1.ReversingEntry;
					TheStructureOfTheSearch.ByDataOfSourceARAPObject = True;
					
					AvailableInClients = TableSettlementsWithCustomers.FindRows(TheStructureOfTheSearch).Count() > 0;
					AvailableFromSuppliers = TableSettlementsWithSuppliers <> Undefined
										And TableSettlementsWithSuppliers.FindRows(TheStructureOfTheSearch).Count() > 0;
					If Not (AvailableInClients Or AvailableFromSuppliers) Then
						If TableSettlementsWithSuppliers <> Undefined Then
							Raise(StrTemplate(NStr("vi = 'Không tìm thấy bản ghi kết chuyển đích trong bản ghi kết chuyển theo %1 và %2';
													|ru = 'Не найдены движения приемника в движениях по %1 и %2';
													|en = 'Cannot find the destination register records in the register records by %1 and %2'; fa = 'Cannot find the destination register records in the register records by %1 and %2';
													|it = 'Не найдены движения приемника в движениях по %1 и %2';
													|pl = 'Cannot find the destination register records in the register records by %1 and %2';
													|tr = '%1 ve %2 hareketlerinde alıcı hareketleri bulunmadı'"),
												NameSettlementsWithClients,
												NameSettlementsWithSuppliers));
						Else
							Raise(StrTemplate(NStr("vi = 'Không tìm thấy bản ghi kết chuyển đích trong bản ghi kết chuyển theo %1';
													|ru = 'Не найдены движения приемника в движениях по %1';
													|en = 'Cannot find the destination register records in the register records by %1'; fa = 'Cannot find the destination register records in the register records by %1';
													|it = 'Не найдены движения приемника в движениях по %1';
													|pl = 'Cannot find the destination register records in the register records by %1';
													|tr = '%1 hareketlerinde alıcı hareketleri bulunmadı'"),
												NameSettlementsWithClients));
						EndIf;
					EndIf;
				EndDo;
			EndIf;
			
			RegisterRecords.CustomersARAPAccounting.Write = True;
			RegisterRecords.CustomersARAPAccounting.Load(TableSettlementsWithCustomers);
	EndIf;
	
	If RegisterRecords.Find("CustomersARAPAccounting") <> Undefined
		And RegisterRecords.CustomersARAPAccounting.Write
		And Not ValueIsFilled(TableSettlementsWithCustomers) Then
		RegisterRecords.CustomersARAPAccountingByDocuments.Write = True;
	EndIf;
	
	#EndRegion
	
	#Region CustomersARAPAccountingCashFlowPlan
	
	NameOfTableSettlementsWithClientsPaymentPlan = "Table" + "CustomersARAPAccountingCashFlowPlan";
	If TablesForRegisteredRecords.Property(NameOfTableSettlementsWithClientsPaymentPlan) Then
		
		TableSettlementsWithClientsPaymentPlan = TablesForRegisteredRecords[NameOfTableSettlementsWithClientsPaymentPlan];

		If ValueIsFilled(TableSettlementsWithClientsPaymentPlan) Then
		
			DocumentType = TypeOf(RegisterRecords.CustomersARAPAccountingCashFlowPlan.Filter.Recorder.Value);
			AddFillInOrderOfOperation(TableSettlementsWithClientsPaymentPlan, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
			CheckAndFillOutPartnerAccountingAnalytics(TableSettlementsWithClientsPaymentPlan);
			
			RegisterRecords.CustomersARAPAccountingCashFlowPlan.Write = True;
			RegisterRecords.CustomersARAPAccountingCashFlowPlan.Load(TableSettlementsWithClientsPaymentPlan);
			
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region CustomersARAPAccountingPlannedShipments
	
	NameOfTableSettlementsWithCustomersShipmentPlan = "Table" + "CustomersARAPAccountingPlannedShipments";
	If TablesForRegisteredRecords.Property(NameOfTableSettlementsWithCustomersShipmentPlan) Then
		
		TableSettlementsWithCustomersShipmentPlan = TablesForRegisteredRecords[NameOfTableSettlementsWithCustomersShipmentPlan];

		If ValueIsFilled(TableSettlementsWithCustomersShipmentPlan) Then
		
			DocumentType = TypeOf(RegisterRecords.CustomersARAPAccountingPlannedShipments.Filter.Recorder.Value);
			AddFillInOrderOfOperation(TableSettlementsWithCustomersShipmentPlan, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
			CheckAndFillOutPartnerAccountingAnalytics(TableSettlementsWithCustomersShipmentPlan);
			
			RegisterRecords.CustomersARAPAccountingPlannedShipments.Write = True;
			RegisterRecords.CustomersARAPAccountingPlannedShipments.Load(TableSettlementsWithCustomersShipmentPlan);
			
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region VendorsARAPAccounting
	
	If ValueIsFilled(TableSettlementsWithSuppliers) Then
		
			DocumentType = TypeOf(RegisterRecords.VendorsARAPAccounting.Filter.Recorder.Value);
			AddFillInOrderOfOperation(TableSettlementsWithSuppliers, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
			
			TableOfReceivers = New ValueTable;
			TableOfReceivers.Columns.Add("DestinationAccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
			TableOfReceivers.Columns.Add("CalculationObjectReceiver", New TypeDescription("CatalogRef.ARAPObjects"));
			TableOfReceivers.Columns.Add("CurrencyReceiver", New TypeDescription("CatalogRef.Currencies"));
			TableOfReceivers.Columns.Add("ReversingEntry", New TypeDescription("Boolean"));
			
			CheckOrderType =  TableSettlementsWithSuppliers.Columns.Find("PurchaseByOrder") <> Undefined;
			CheckConnectionsOfSourcesReceivers = TableSettlementsWithSuppliers.Columns.Find("CalculationObjectReceiver") <> Undefined;
			
			For Each Page1 In TableSettlementsWithSuppliers Do
				If CheckOrderType And Not ValueIsFilled(Page1.PurchaseByOrder) And Page1.PurchaseByOrder <> Undefined Then
					Page1.PurchaseByOrder = Undefined;
				EndIf;
				
				If Page1.ReversingEntry = Undefined Then
					Page1.ReversingEntry = False;
				EndIf;
				If CheckConnectionsOfSourcesReceivers Then
					If NewOnlineARAPAccounting Then
						ByDataOfSourceARAPObject = ?(Page1.ByDataOfSourceARAPObject = Undefined,False,Page1.ByDataOfSourceARAPObject);
						AllReceiverFieldsAreFilledIn = ValueIsFilled(Page1.CalculationObjectReceiver)
							+ ValueIsFilled(Page1.DestinationAccountingDimensionByPartners)
							+ ValueIsFilled(Page1.CurrencyReceiver)
							+ (ValueIsFilled(Page1.AmountReceiver) And ValueIsFilled(Page1.Sum));
						If Not ByDataOfSourceARAPObject And AllReceiverFieldsAreFilledIn <> 4 And AllReceiverFieldsAreFilledIn <> 0 Then
							Raise(StrTemplate(NStr("vi = 'Chưa điền đầy đủ đối tượng phân tích hoặc số tiền đích trong các bản ghi kết chuyển theo %1';
													|ru = 'Не полностью заполнена аналитика или сумма приемника в движениях по %1';
													|en = 'The destination dimension or amount in the register records by %1 is not fully filled'; fa = 'The destination dimension or amount in the register records by %1 is not fully filled';
													|it = 'Не полностью заполнена аналитика или сумма приемника в движениях по %1';
													|pl = 'The destination dimension or amount in the register records by %1 is not fully filled';
													|tr = 'Boyut tam olarak veya %1 hareketlerinde hedef tutarına göre doldurulmamış'"),
														NameSettlementsWithSuppliers));
						EndIf;
					EndIf;
				EndIf;
				
				If CheckConnectionsOfSourcesReceivers And ValueIsFilled(Page1.CalculationObjectReceiver) Then
					FillPropertyValues(TableOfReceivers.Add(),New Structure("CalculationObjectReceiver, DestinationAccountingDimensionByPartners, CurrencyReceiver, ReversingEntry",
						Page1.CalculationObjectReceiver, Page1.DestinationAccountingDimensionByPartners, Page1.CurrencyReceiver, Page1.ReversingEntry));
				EndIf;
			EndDo;
			
			If TableOfReceivers.Count() > 0 Then
				TableOfReceivers.GroupBy("CalculationObjectReceiver, DestinationAccountingDimensionByPartners, CurrencyReceiver, ReversingEntry");
				TableSettlementsWithSuppliers.Indexes.Add("ARAPObject,AccountingDimensionByPartners,Currency,ReversingEntry");
				TheStructureOfTheSearch = New Structure("ARAPObject,AccountingDimensionByPartners,Currency,ByDataOfSourceARAPObject,ReversingEntry");
				For Each Page1 In TableOfReceivers Do
					TheStructureOfTheSearch.AccountingDimensionByPartners = Page1.DestinationAccountingDimensionByPartners;
					TheStructureOfTheSearch.ARAPObject = Page1.CalculationObjectReceiver;
					TheStructureOfTheSearch.Currency = Page1.CurrencyReceiver;
					TheStructureOfTheSearch.ReversingEntry = Page1.ReversingEntry;
					TheStructureOfTheSearch.ByDataOfSourceARAPObject = True;
					
					AvailableFromSuppliers = TableSettlementsWithSuppliers.FindRows(TheStructureOfTheSearch).Count() > 0;
					AvailableInClients = TableSettlementsWithCustomers <> Undefined
										And TableSettlementsWithCustomers.FindRows(TheStructureOfTheSearch).Count() > 0;
					If Not (AvailableInClients Or AvailableFromSuppliers) Then
						If TableSettlementsWithCustomers <> Undefined Then
							Raise(StrTemplate(NStr("vi = 'Không tìm thấy bản ghi kết chuyển đích trong bản ghi kết chuyển theo %1 và %2';
													|ru = 'Не найдены движения приемника в движениях по %1 и %2';
													|en = 'Cannot find the destination register records in the register records by %1 and %2'; fa = 'Cannot find the destination register records in the register records by %1 and %2';
													|it = 'Не найдены движения приемника в движениях по %1 и %2';
													|pl = 'Cannot find the destination register records in the register records by %1 and %2';
													|tr = '%1 ve %2 hareketlerinde alıcı hareketleri bulunmadı'"),
												NameSettlementsWithClients,
												NameSettlementsWithSuppliers));
						Else
							Raise(StrTemplate(NStr("vi = 'Không tìm thấy bản ghi kết chuyển đích trong bản ghi kết chuyển theo %1';
													|ru = 'Не найдены движения приемника в движениях по %1';
													|en = 'Cannot find the destination register records in the register records by %1'; fa = 'Cannot find the destination register records in the register records by %1';
													|it = 'Не найдены движения приемника в движениях по %1';
													|pl = 'Cannot find the destination register records in the register records by %1';
													|tr = '%1 hareketlerinde alıcı hareketleri bulunmadı'"),
												NameSettlementsWithSuppliers));
						EndIf;
					EndIf;
					
				EndDo;
			EndIf;
			
			RegisterRecords.VendorsARAPAccounting.Write = True;
			RegisterRecords.VendorsARAPAccounting.Load(TableSettlementsWithSuppliers);
	EndIf;
	
	If RegisterRecords.Find("VendorsARAPAccounting") <> Undefined
		And RegisterRecords.VendorsARAPAccounting.Write
		And Not ValueIsFilled(TableSettlementsWithSuppliers) Then
		RegisterRecords.VendorsARAPAccountingByDocuments.Write = True;
	EndIf;
	
	#EndRegion
	
	#Region VendorsARAPAccountingCashFlowPlan
	
	NameOfTableSettlementsWithSuppliersPaymentPlan = "Table" + "VendorsARAPAccountingCashFlowPlan";
	If TablesForRegisteredRecords.Property(NameOfTableSettlementsWithSuppliersPaymentPlan) Then
		
		TableSettlementsWithSuppliersPaymentPlan = TablesForRegisteredRecords[NameOfTableSettlementsWithSuppliersPaymentPlan];

		If ValueIsFilled(TableSettlementsWithSuppliersPaymentPlan) Then
		
			DocumentType = TypeOf(RegisterRecords.VendorsARAPAccountingCashFlowPlan.Filter.Recorder.Value);
			AddFillInOrderOfOperation(TableSettlementsWithSuppliersPaymentPlan, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
			CheckAndFillOutPartnerAccountingAnalytics(TableSettlementsWithSuppliersPaymentPlan);
			
			RegisterRecords.VendorsARAPAccountingCashFlowPlan.Write = True;
			RegisterRecords.VendorsARAPAccountingCashFlowPlan.Load(TableSettlementsWithSuppliersPaymentPlan);
			
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region VendorsARAPAccountingPlannedDeliveries
	
	NameOfTableSettlementsWithSuppliersDeliveryPlan = "Table" + "VendorsARAPAccountingPlannedDeliveries";
	If TablesForRegisteredRecords.Property(NameOfTableSettlementsWithSuppliersDeliveryPlan) Then
		
		TableSettlementsWithSuppliersDeliveryPlan = TablesForRegisteredRecords[NameOfTableSettlementsWithSuppliersDeliveryPlan];

		If ValueIsFilled(TableSettlementsWithSuppliersDeliveryPlan) Then
		
			DocumentType = TypeOf(RegisterRecords.VendorsARAPAccountingPlannedDeliveries.Filter.Recorder.Value);
			AddFillInOrderOfOperation(TableSettlementsWithSuppliersDeliveryPlan, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts);
			CheckAndFillOutPartnerAccountingAnalytics(TableSettlementsWithSuppliersDeliveryPlan);
			
			RegisterRecords.VendorsARAPAccountingPlannedDeliveries.Write = True;
			RegisterRecords.VendorsARAPAccountingPlannedDeliveries.Load(TableSettlementsWithSuppliersDeliveryPlan);
			
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region DiscountingCalculations
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "DiscountInterestExpense");
	#EndRegion
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	#Region CustomersARAPAccounting
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "SettlementsWithClients_Update") Then
		
		QueryText =
			"SELECT
			|	OrdersTable.ARAPObject AS ARAPObject,
			|	OrdersTable.Currency         AS Currency,
			|	SUM(CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				AND OrdersTable.ARAPObject.Object = OrdersTable.Recorder
			|				AND NOT OrdersTable.ExcludeDuringControl THEN
			|				OrdersTable.AmountDue
			|			ELSE 0
			|		END)                 AS OrderAmount,
			|	SUM(CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Expense)
			|				THEN OrdersTable.Sum
			|			ELSE 0
			|		END +
			|		CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Expense)
			|				THEN -OrdersTable.BeingPaid
			|			ELSE OrdersTable.BeingPaid
			|		END)                 AS PayAmount
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting AS OrdersTable
			|WHERE
			|	(OrdersTable.ARAPObject, OrdersTable.Currency, OrdersTable.Active) IN
			|			(SELECT
			|				Table.ARAPObject,
			|				Table.Currency,
			|				TRUE
			|			FROM
			|				SettlementsWithClients_Update AS Table)
			|
			|GROUP BY
			|	OrdersTable.Currency,
			|	OrdersTable.ARAPObject
			|
			|HAVING
			|	SUM(CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				AND OrdersTable.ARAPObject.Object = OrdersTable.Recorder
			|				AND NOT OrdersTable.ExcludeDuringControl THEN
			|				OrdersTable.AmountDue
			|			ELSE 0
			|		END) > 0
			|	AND
			|	SUM(CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Receipt)
			|				AND OrdersTable.ARAPObject.Object = OrdersTable.Recorder
			|				AND NOT OrdersTable.ExcludeDuringControl THEN
			|				OrdersTable.AmountDue
			|			ELSE 0
			|		END)
			|	>
			|	SUM(CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Expense)
			|				THEN OrdersTable.Sum
			|			ELSE 0
			|		END +
			|		CASE
			|			WHEN OrdersTable.RecordType = VALUE(AccumulationRecordType.Expense)
			|				THEN -OrdersTable.BeingPaid
			|			ELSE OrdersTable.BeingPaid
			|		END)";
		
		QueryTexts.Add(QueryText, "ErrorsSettlementsWithCustomers");
		
	EndIf;
	
	#EndRegion
	
	#Region AmountsTermOfDebt
		
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt")
		Or DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsWithCustomersChangeTermControl") Then
		
		QueryTexts.Add(
			"SELECT
			|	RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt.AccountingDimensionByPartners.Contract AS Contract
			|INTO ContractDataChangeInDebtAmount
			|FROM
			|	RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt AS RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt
			|
			|INDEX BY
			|	Contract");
		
		QueryTexts.Add(
			"SELECT
			|	RegisteredRecordsSettlementsWithCustomersChangeTermControl.AccountingDimensionByPartners.Contract AS Contract
			|INTO ContractDataChangeTermControl
			|FROM
			|	RegisteredRecordsSettlementsWithCustomersChangeTermControl AS RegisteredRecordsSettlementsWithCustomersChangeTermControl
			|
			|INDEX BY
			|	Contract");
		
		QueryTexts.Add(
			"SELECT
			|	RegisterRecordTable.Contract                             AS Contract,
			|	ContractData.ARAPCurrency                 AS Currency,
			|	ContractData.LimitDebtAmount       AS LimitDebtAmount,
			|	ContractData.AllowableAmountPayable         AS AllowableAmountPayable,
			|	FALSE                                                AS ShipmentIsProhibitedInCaseOfARAPOverdue
			|
			|INTO ContractDataPreliminary
			|FROM
			|	ContractDataChangeInDebtAmount AS RegisterRecordTable
			|	
			|	INNER JOIN
			|		Catalog.CounterpartyContracts AS ContractData
			|	ON
			|		RegisterRecordTable.Contract = ContractData.Ref
			|
			|WHERE
			|	ContractData.LimitDebtAmount
			|
			|UNION ALL
			|
			|SELECT
			|	RegisterRecordTable.ARAPObject                      AS Contract,
			|	ContractData.ARAPCurrency                 AS Currency,
			|	ContractData.LimitDebtAmount       AS LimitDebtAmount,
			|	ContractData.AllowableAmountPayable         AS AllowableAmountPayable,
			|	FALSE                                                AS ShipmentIsProhibitedInCaseOfARAPOverdue
			|
			|FROM
			|	RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt AS RegisterRecordTable
			|	
			|	INNER JOIN
			|		Catalog.CounterpartyContracts AS ContractData
			|	ON
			|		RegisterRecordTable.ARAPObject = ContractData.Ref
			|
			|WHERE
			|	ContractData.LimitDebtAmount
			|
			|UNION ALL
			|
			|SELECT
			|	RegisterRecordTable.Contract                             AS Contract,
			|	ContractData.ARAPCurrency                 AS Currency,
			|	FALSE                                                AS LimitDebtAmount,
			|	0                                                   AS AllowableAmountPayable,
			|	ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue AS ShipmentIsProhibitedInCaseOfARAPOverdue
			|
			|FROM
			|	ContractDataChangeTermControl AS RegisterRecordTable
			|	
			|	INNER JOIN
			|		Catalog.CounterpartyContracts AS ContractData
			|	ON
			|		RegisterRecordTable.Contract = ContractData.Ref
			|
			|WHERE
			|	ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue
			|
			|UNION ALL
			|
			|SELECT
			|	RegisterRecordTable.ARAPObject                      AS Contract,
			|	ContractData.ARAPCurrency                 AS Currency,
			|	FALSE                                                AS LimitDebtAmount,
			|	0                                                   AS AllowableAmountPayable,
			|	ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue AS ShipmentIsProhibitedInCaseOfARAPOverdue
			|
			|FROM
			|	RegisteredRecordsSettlementsWithCustomersChangeTermControl AS RegisterRecordTable
			|	
			|	INNER JOIN
			|		Catalog.CounterpartyContracts AS ContractData
			|	ON
			|		RegisterRecordTable.ARAPObject = ContractData.Ref
			|
			|WHERE
			|	ContractData.ShipmentIsProhibitedInCaseOfARAPOverdue");
		
		QueryTexts.Add(
			"SELECT
			|	ContractData_.Contract                                        AS Contract,
			|	ContractData_.Currency                                         AS Currency,
			|	MAX(ContractData_.LimitDebtAmount)       AS AmountControl,
			|	MAX(ContractData_.AllowableAmountPayable)         AS AcceptableAmount,
			|	MAX(ContractData_.ShipmentIsProhibitedInCaseOfARAPOverdue) AS TermControl
			|
			|INTO ContractData_
			|FROM
			|	ContractDataPreliminary AS ContractData_
			|
			|GROUP BY
			|	ContractData_.Contract,
			|	ContractData_.Currency");
		
		QueryTexts.Add(
			"SELECT DISTINCT
			|	DimensionByPartners.DimensionKey AS DimensionKey,
			|	ContractData_.Contract            AS Contract,
			|	ContractData_.Currency             AS Currency,
			|	ContractData_.AmountControl      AS AmountControl,
			|	ContractData_.TermControl      AS TermControl
			|
			|INTO TTAnalyticsForPartners
			|FROM
			|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
			|	
			|	INNER JOIN ContractData_ AS ContractData_
			|	ON
			|		DimensionByPartners.Contract = ContractData_.Contract
			|");
			
			QueryTexts.Add("
			|SELECT
			|	CustomersARAPAccountingBalance.ARAPObject           AS ARAPObject,
			|	CustomersARAPAccountingBalance.Currency                   AS Currency,
			|	CustomersARAPAccountingBalance.BeingPaidBalance      AS BeingPaidBalance
			|INTO BalancesArePaid
			|FROM AccumulationRegister.CustomersARAPAccounting.Balance(
			|		&DebtTermControlPeriod,
			|		(AccountingDimensionByPartners, Currency) IN (SELECT T.DimensionKey, T.Currency FROM TTAnalyticsForPartners AS T WHERE T.TermControl)
			|	) AS CustomersARAPAccountingBalance
			|INDEX BY
			|	ARAPObject,Currency");
		
		If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt") Then
			
			QueryText = "
			|SELECT
			|	DimensionByPartners.Contract                              AS Contract,
			|	CustomersARAPAccountingBalance.Currency                           AS Currency,
			|	MIN(ContractData_.AcceptableAmount)                  AS AllowableAmountPayable,
			|	SUM(CustomersARAPAccountingBalance.SumBalance) +
			|		SUM(CustomersARAPAccountingBalance.BeingShippedBalance)    AS SumBalance,
			|
			|	SUM(CustomersARAPAccountingBalance.SumBalance) +
			|		SUM(CustomersARAPAccountingBalance.BeingShippedBalance) -
			|		MIN(ContractData_.AcceptableAmount)              AS ExcessAmount
			|
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(
			|		,
			|		(AccountingDimensionByPartners, Currency) IN (SELECT T.DimensionKey, T.Currency FROM TTAnalyticsForPartners AS T WHERE T.AmountControl)
			|	) AS CustomersARAPAccountingBalance
			|	
			|	INNER JOIN
			|		TTAnalyticsForPartners AS DimensionByPartners
			|	ON
			|		CustomersARAPAccountingBalance.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
			|		AND CustomersARAPAccountingBalance.Currency = DimensionByPartners.Currency
			|	
			|	INNER JOIN
			|		ContractData_ AS ContractData_
			|	ON
			|		DimensionByPartners.Contract = ContractData_.Contract
			|		AND DimensionByPartners.Currency = ContractData_.Currency
			|
			|GROUP BY
			|	DimensionByPartners.Contract,
			|	CustomersARAPAccountingBalance.Currency
			|HAVING
			|	SUM(CustomersARAPAccountingBalance.SumBalance)+
			|		SUM(CustomersARAPAccountingBalance.BeingShippedBalance) > MIN(ContractData_.AcceptableAmount)";
			
			QueryTexts.Add(QueryText, "ErrorsLimitAmountOwed");
			
		EndIf;
		
		If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsWithCustomersChangeTermControl") Then
			
			QueryText =
				"SELECT
				|	DimensionByPartners.Contract                              AS Contract,
				|	CustomersARAPAccountingBalance.Currency                           AS Currency,
				|	SUM(CASE WHEN CustomersARAPAccountingBalance.SumBalance >
				|						CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance THEN
				|		CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance
				|	ELSE
				|		CustomersARAPAccountingBalance.SumBalance
				|	END) AS ARAPOverdue
				|
				|FROM
				|	AccumulationRegister.CustomersARAPAccounting.Balance(
				|		&DebtTermControlPeriod,
				|		(AccountingDimensionByPartners, Currency) IN (SELECT T.DimensionKey, T.Currency FROM TTAnalyticsForPartners AS T WHERE T.TermControl)
				|	) AS CustomersARAPAccountingBalance
				|	
				|	INNER JOIN
				|		TTAnalyticsForPartners AS DimensionByPartners
				|	ON
				|		CustomersARAPAccountingBalance.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
				|		AND CustomersARAPAccountingBalance.Currency = DimensionByPartners.Currency
				|	
				|	INNER JOIN
				|		ContractData_ AS ContractData_
				|	ON
				|		DimensionByPartners.Contract = ContractData_.Contract
				|		AND DimensionByPartners.Currency = ContractData_.Currency
				|
				|WHERE
				|	NOT &NewOnlineARAPAccounting
				|	AND CustomersARAPAccountingBalance.SumBalance > 0
				|	AND (CustomersARAPAccountingBalance.AmountDueBalance - CustomersARAPAccountingBalance.BeingPaidBalance) > 0
				|
				|GROUP BY
				|	DimensionByPartners.Contract,
				|	CustomersARAPAccountingBalance.Currency
				|
				|UNION ALL
				|
				|SELECT
				|	DimensionByPartners.Contract                              AS Contract,
				|	CustomersARAPAccountingByDueDatesBalance.Currency                   AS Currency,
				|	SUM(CustomersARAPAccountingByDueDatesBalance.DebtBalance 
				|			- ISNULL(BalancesArePaid.BeingPaidBalance,0)) AS ARAPOverdue
				|
				|FROM
				|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
				|		&DebtTermControlPeriod,
				|		(AccountingDimensionByPartners, Currency) IN (SELECT T.DimensionKey, T.Currency FROM TTAnalyticsForPartners AS T WHERE T.TermControl)
				|		AND PlannedRepaymentDate < BEGINOFPERIOD(&DebtTermControlDay,DAY)
				|	) AS CustomersARAPAccountingByDueDatesBalance
				|	
				|	INNER JOIN
				|		TTAnalyticsForPartners AS DimensionByPartners
				|	ON
				|		CustomersARAPAccountingByDueDatesBalance.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
				|		AND CustomersARAPAccountingByDueDatesBalance.Currency = DimensionByPartners.Currency
				|	
				|	INNER JOIN
				|		ContractData_ AS ContractData_
				|	ON
				|		DimensionByPartners.Contract = ContractData_.Contract
				|		AND DimensionByPartners.Currency = ContractData_.Currency
				|
				|	LEFT JOIN BalancesArePaid AS BalancesArePaid
				|	ON
				|		CustomersARAPAccountingByDueDatesBalance.ARAPObject = BalancesArePaid.ARAPObject
				|		AND CustomersARAPAccountingByDueDatesBalance.Currency = BalancesArePaid.Currency
				|WHERE
				|	&NewOnlineARAPAccounting
				|
				|GROUP BY
				|	DimensionByPartners.Contract,
				|	CustomersARAPAccountingByDueDatesBalance.Currency
				|
				|HAVING SUM(CustomersARAPAccountingByDueDatesBalance.DebtBalance
				|			- ISNULL(BalancesArePaid.BeingPaidBalance,0)) > 0";
			
			Query.SetParameter("NewOnlineARAPAccounting", Constants.NewOnlineARAPAccounting.Get());
			
			QueryTexts.Add(QueryText, "ErrorsControlOfTermOfDebt");
			
		EndIf;
		
		DebtTermControlDay = Max(CurrentSessionDate(), Document.Date);
		Query.SetParameter("DebtTermControlPeriod", New Boundary(EndOfDay(DebtTermControlDay), BoundaryType.Including));
		Query.SetParameter("DebtTermControlDay", DebtTermControlDay);
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementSettlementsWithCustomersChangePaid") Then
		
		QueryText = "
		|SELECT
		|	BalanceTable.AccountingDimensionByPartners           AS AccountingDimensionByPartners,
		|	BalanceTable.ARAPObject                      AS ARAPObject,
		|	BalanceTable.Currency                              AS Currency,
		|	BalanceTable.PaymentRequest AS PaymentRequest,
		|	SUM(CASE WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			BalanceTable.BeingPaid
		|		ELSE
		|			-BalanceTable.BeingPaid
		|		END) AS Sum
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS BalanceTable
		|	INNER JOIN MovementSettlementsWithCustomersChangePaid AS Table
		|	ON Table.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|		AND Table.ARAPObject = BalanceTable.ARAPObject
		|		AND Table.Currency = BalanceTable.Currency
		|		AND Table.PaymentRequest = BalanceTable.PaymentRequest
		|WHERE
		|	BalanceTable.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
		|GROUP BY
		|	BalanceTable.AccountingDimensionByPartners,
		|	BalanceTable.ARAPObject,
		|	BalanceTable.Currency,
		|	BalanceTable.PaymentRequest
		|HAVING
		|	SUM(CASE WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			BalanceTable.BeingPaid
		|		ELSE
		|			-BalanceTable.BeingPaid
		|		END) > 0
		|";
		
		QueryTexts.Add(QueryText, "ErrorsArePaid");
		
	EndIf;
	
	#EndRegion
	
	#Region Prepayments
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "SettlementsWithCustomersChanges") Then
		
		QueryText =
			"SELECT
			|	CustomersARAPAccountingBalance.ARAPObject        AS AdvanceDocument,
			|	CustomersARAPAccountingBalance.Currency                AS Currency,
			|	CustomersARAPAccountingBalance.SumBalance          AS ExcessAmount,
			|	SUM(SettlementsWithCustomersChanges.Sum)        AS AmountOfCreditReduction,
			|	MAX(SettlementsWithCustomersChanges.RaiseException1) AS RaiseException1
			|	
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(,
			|		(ARAPObject, Currency) IN (SELECT ARAPObject, Currency FROM SettlementsWithCustomersChanges WHERE Sum <> 0)) AS CustomersARAPAccountingBalance
			|		INNER JOIN SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
			|			ON SettlementsWithCustomersChanges.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
			|				AND SettlementsWithCustomersChanges.Currency = CustomersARAPAccountingBalance.Currency
			|WHERE
			|	CustomersARAPAccountingBalance.SumBalance > 0
			|	AND (VALUETYPE(CustomersARAPAccountingBalance.ARAPObject.Object) IN (TYPE(Document.BankAccountReceiptNote),
			|													TYPE(Document.CashAccountReceiptNote),
			|													TYPE(Catalog.GiftCertificates),
			|													TYPE(Document.OBEntry),
			|													TYPE(Document.OBEntryARAP))
			|		OR VALUETYPE(CustomersARAPAccountingBalance.ARAPObject.Object) = TYPE(Document.PaymentCardTransaction)
			|			AND CAST(CustomersARAPAccountingBalance.ARAPObject.Object AS Document.PaymentCardTransaction).BusinessOperation
			|				= VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer))
			|GROUP BY
			|	CustomersARAPAccountingBalance.ARAPObject,
			|	CustomersARAPAccountingBalance.Currency,
			|	CustomersARAPAccountingBalance.SumBalance
			|
			|UNION ALL
			|
			|SELECT
			|	CustomersARAPAccountingBalance.ARAPObject        AS AdvanceDocument,
			|	CustomersARAPAccountingBalance.Currency                AS Currency,
			|	CustomersARAPAccountingBalance.SumBalance          AS ExcessAmount,
			|	SUM(SettlementsWithCustomersChanges.Sum)        AS AmountOfCreditReduction,
			|	MAX(SettlementsWithCustomersChanges.RaiseException1) AS RaiseException1
			|	
			|FROM
			|	AccumulationRegister.CustomersARAPAccounting.Balance(,
			|		(ARAPObject, Currency) IN (SELECT ARAPObject, Currency FROM SettlementsWithCustomersChanges WHERE Sum <> 0 AND ARAPObject.ControlPrepaymentBalance)
			|	) AS CustomersARAPAccountingBalance
			|		INNER JOIN Constant.ControlPrepaymentBalance AS ConstantValue
			|			ON ConstantValue.Value
			|		INNER JOIN SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
			|			ON SettlementsWithCustomersChanges.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
			|				AND SettlementsWithCustomersChanges.Currency = CustomersARAPAccountingBalance.Currency
			|WHERE
			|	CustomersARAPAccountingBalance.SumBalance > 0
			|GROUP BY
			|	CustomersARAPAccountingBalance.ARAPObject,
			|	CustomersARAPAccountingBalance.Currency,
			|	CustomersARAPAccountingBalance.SumBalance
			|";
		

		QueryTexts.Add(QueryText, "ErrorsControlOfCreditedAdvancesOnInvoicesClient");
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "VendorsARAPAccountingChanges") Then
		
		QueryText =
			"SELECT
			|	VendorsARAPAccountingBalance.ARAPObject           AS AdvanceDocument,
			|	VendorsARAPAccountingBalance.Currency                   AS Currency,
			|	-VendorsARAPAccountingBalance.SumBalance             AS ExcessAmount,
			|	SUM(VendorsARAPAccountingChanges.Sum)               AS AmountOfCreditReduction,
			|	MAX(VendorsARAPAccountingChanges.RaiseException1) AS RaiseException1
			|
			|FROM
			|	AccumulationRegister.VendorsARAPAccounting.Balance(,
			|		(ARAPObject, Currency) IN (SELECT ARAPObject, Currency FROM VendorsARAPAccountingChanges WHERE Sum <> 0)) AS VendorsARAPAccountingBalance
			|		INNER JOIN VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges
			|			ON VendorsARAPAccountingChanges.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
			|				AND VendorsARAPAccountingChanges.Currency = VendorsARAPAccountingBalance.Currency
			|				AND VendorsARAPAccountingChanges.Sum <> 0
			|WHERE
			|	VendorsARAPAccountingBalance.SumBalance < 0
			|	AND VALUETYPE(VendorsARAPAccountingBalance.ARAPObject.Object) IN (TYPE(Document.BankAccountIssue),
			|													TYPE(Document.CashVoucher),
			|													TYPE(Document.OBEntry),
			|													TYPE(Document.OBEntryARAP))
			|GROUP BY
			|	VendorsARAPAccountingBalance.ARAPObject,
			|	VendorsARAPAccountingBalance.Currency,
			|	-VendorsARAPAccountingBalance.SumBalance
			|
			|UNION ALL
			|
			|SELECT
			|	VendorsARAPAccountingBalance.ARAPObject           AS AdvanceDocument,
			|	VendorsARAPAccountingBalance.Currency                   AS Currency,
			|	-VendorsARAPAccountingBalance.SumBalance            AS ExcessAmount,
			|	SUM(VendorsARAPAccountingChanges.Sum)           AS AmountOfCreditReduction,
			|	MAX(VendorsARAPAccountingChanges.RaiseException1) AS RaiseException1
			|
			|FROM
			|	AccumulationRegister.VendorsARAPAccounting.Balance(,
			|		(ARAPObject, Currency) IN (SELECT ARAPObject, Currency FROM VendorsARAPAccountingChanges WHERE Sum <> 0 AND ARAPObject.ControlPrepaymentBalance)
			|	) AS VendorsARAPAccountingBalance
			|		INNER JOIN Constant.ControlPrepaymentBalance AS ConstantValue
			|			ON ConstantValue.Value
			|		INNER JOIN VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges
			|			ON VendorsARAPAccountingChanges.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
			|				AND VendorsARAPAccountingChanges.Currency = VendorsARAPAccountingBalance.Currency
			|				AND VendorsARAPAccountingChanges.Sum <> 0
			|WHERE
			|	VendorsARAPAccountingBalance.SumBalance < 0
			|GROUP BY
			|	VendorsARAPAccountingBalance.ARAPObject,
			|	VendorsARAPAccountingBalance.Currency,
			|	-VendorsARAPAccountingBalance.SumBalance
			|	
			|";
		
		QueryTexts.Add(QueryText, "ErrorsControlOfCreditedAdvancesOnInvoicesSupplier");
		
	EndIf;
	
	#EndRegion
	
	#Region OBEntry
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "SettlementsWithCustomersChangesEnteringBalances") Then
		
		QueryText =
			"SELECT TOP 1
			|	SettlementsWithCustomersChanges.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
			|	SettlementsWithCustomersChanges.ARAPObject             AS ARAPObject
			|FROM
			|	SettlementsWithCustomersChangesEnteringBalances AS SettlementsWithCustomersChanges
			|		INNER JOIN AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|			ON SettlementsWithCustomersChanges.AccountingDimensionByPartners = CustomersARAPAccounting.AccountingDimensionByPartners
			|				AND SettlementsWithCustomersChanges.ARAPObject = CustomersARAPAccounting.ARAPObject
			|				AND SettlementsWithCustomersChanges.Period < CustomersARAPAccounting.Period 
			|				AND VALUETYPE(CustomersARAPAccounting.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|				AND CustomersARAPAccounting.Sum <> 0
			|	
			|WHERE
			|	NOT VALUETYPE(SettlementsWithCustomersChanges.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|";
		
		QueryTexts.Add(QueryText, "ErrorsThereIsInputOfResiduesAfterCustomers");
		
		QueryText =
			"SELECT TOP 1
			|	SettlementsWithCustomersChanges.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
			|	SettlementsWithCustomersChanges.ARAPObject             AS ARAPObject
			|FROM
			|	SettlementsWithCustomersChangesEnteringBalances AS SettlementsWithCustomersChanges
			|		INNER JOIN AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
			|			ON SettlementsWithCustomersChanges.AccountingDimensionByPartners = CustomersARAPAccounting.AccountingDimensionByPartners
			|				AND SettlementsWithCustomersChanges.ARAPObject = CustomersARAPAccounting.ARAPObject
			|				AND SettlementsWithCustomersChanges.Period > CustomersARAPAccounting.Period 
			|				AND NOT VALUETYPE(CustomersARAPAccounting.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|				AND CustomersARAPAccounting.Sum <> 0
			|	
			|WHERE
			|	VALUETYPE(SettlementsWithCustomersChanges.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|";
		
		QueryTexts.Add(QueryText, "ErrorsAreRegisteredRecordsUpToCustomers");
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "VendorsARAPAccountingChangesEnteringBalances") Then
		
		QueryText =
			"SELECT TOP 1
			|	VendorsARAPAccountingChanges.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
			|	VendorsARAPAccountingChanges.ARAPObject             AS ARAPObject
			|FROM
			|	VendorsARAPAccountingChangesEnteringBalances AS VendorsARAPAccountingChanges
			|		INNER JOIN AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
			|			ON VendorsARAPAccountingChanges.AccountingDimensionByPartners = VendorsARAPAccounting.AccountingDimensionByPartners
			|				AND VendorsARAPAccountingChanges.ARAPObject = VendorsARAPAccounting.ARAPObject
			|				AND VendorsARAPAccountingChanges.Period < VendorsARAPAccounting.Period 
			|				AND VALUETYPE(VendorsARAPAccounting.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|				AND VendorsARAPAccounting.Sum <> 0
			|	
			|WHERE
			|	NOT VALUETYPE(VendorsARAPAccountingChanges.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|";
		
		QueryTexts.Add(QueryText, "ErrorsThereIsInputOfResiduesAfter");
		
		QueryText =
			"SELECT TOP 1
			|	VendorsARAPAccountingChanges.AccountingDimensionByPartners  AS AccountingDimensionByPartners,
			|	VendorsARAPAccountingChanges.ARAPObject             AS ARAPObject
			|FROM
			|	VendorsARAPAccountingChangesEnteringBalances AS VendorsARAPAccountingChanges
			|		INNER JOIN AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
			|			ON VendorsARAPAccountingChanges.AccountingDimensionByPartners = VendorsARAPAccounting.AccountingDimensionByPartners
			|				AND VendorsARAPAccountingChanges.ARAPObject = VendorsARAPAccounting.ARAPObject
			|				AND VendorsARAPAccountingChanges.Period > VendorsARAPAccounting.Period 
			|				AND NOT VALUETYPE(VendorsARAPAccounting.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|				AND VendorsARAPAccounting.Sum <> 0
			|	
			|WHERE
			|	VALUETYPE(VendorsARAPAccountingChanges.Recorder) IN (TYPE(Document.OBEntry),TYPE(Document.OBEntryARAP))
			|";
		
		QueryTexts.Add(QueryText, "ErrorsAreRegisteredRecordsUpTo");
		
	EndIf;
	#EndRegion
	
	#Region SettlementsWithSuppliersArePaid
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementSettlementsWithSuppliersChangePaid") Then
		
		QueryText = "
		|SELECT
		|	BalanceTable.AccountingDimensionByPartners           AS AccountingDimensionByPartners,
		|	BalanceTable.ARAPObject                      AS ARAPObject,
		|	BalanceTable.Currency                              AS Currency,
		|	BalanceTable.PaymentRequest AS PaymentRequest,
		|	SUM(CASE WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			BalanceTable.BeingPaid
		|		ELSE
		|			-BalanceTable.BeingPaid
		|		END) AS Sum
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS BalanceTable
		|	INNER JOIN MovementSettlementsWithSuppliersChangePaid AS Table
		|	ON Table.AccountingDimensionByPartners = BalanceTable.AccountingDimensionByPartners
		|		AND Table.ARAPObject = BalanceTable.ARAPObject
		|		AND Table.Currency = BalanceTable.Currency
		|		AND Table.PaymentRequest = BalanceTable.PaymentRequest
		|WHERE
		|	BalanceTable.PaymentRequest <> VALUE(Document.PaymentRequest.EmptyRef)
		|GROUP BY
		|	BalanceTable.AccountingDimensionByPartners,
		|	BalanceTable.ARAPObject,
		|	BalanceTable.Currency,
		|	BalanceTable.PaymentRequest
		|HAVING
		|	SUM(CASE WHEN BalanceTable.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|			BalanceTable.BeingPaid
		|		ELSE
		|			-BalanceTable.BeingPaid
		|		END) > 0
		|";
		
		QueryTexts.Add(QueryText, "ErrorsArePaid");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	DeviationFromPaymentTermsIsAvailable = UserRightsCached.VarianceFromPaymentTerms();
	
	#Region CustomersARAPAccounting
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "SettlementsWithClients_Update") Then
		
		MessageTemplate = NStr("vi = 'Vi phạm điều kiện thanh toán cần thiết để đảm bảo/giao hàng theo %1,
			|Cần %2 %4 đã thanh toán %3 %4';
			|ru = 'Нарушены условия оплаты, необходимые для обеспечения/отгрузки по %1,
			|Требуется %2 %4 оплачено %3 %4';
			|en = 'Payment terms required for provision / shipment for %1 are violated.
			|Required %2%4 paid %3%4'; fa = 'Payment terms required for provision / shipment for %1 are violated.
			|Required %2%4 paid %3%4';
			|it = 'Non sono stati rispettati i termini di pagamento necessari per garantire approvvigionamento/spedizione%1,
			| Richiesto %2 %4 pagato %3 %4';
			|pl = 'Zostały naruszone warunki płatności, niezbędne do zapewnienia/wysyłki według %1,
			|Wymagane %2 %4 opłacono %3 %4';
			|tr = '%1''de tedarik/sevkiyat için gereken ödeme koşulları ihlal edildi,
			|Gerekli %2 %4 ödendi %3 %4'");
		
		For Each ErrorString In ControlResults.ErrorsSettlementsWithCustomers Do
			
			MessageText = StrTemplate(MessageTemplate, ErrorString.ARAPObject,
				ErrorString.OrderAmount, ErrorString.PayAmount, ErrorString.Currency);
			
			If DeviationFromPaymentTermsIsAvailable Then
				Common.MessageToUser(MessageText, Document);
			Else
				Common.MessageToUser(MessageText, Document,,, Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region AmountsTermOfDebt
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsWithCustomersChangesInAmountOfDebt") Then
		
		MessageTemplate = NStr("vi = 'Theo thỏa thuận %1, số tiền cho vay được vượt quá %2%3';
								|ru = 'По договору %1 превышена допустимая сумма кредита на %2 %3';
								|en = 'Available loan amount under the contract %1 is exceeded by %2%3'; fa = 'Available loan amount under the contract %1 is exceeded by %2%3';
								|it = 'Secondo il contratto %1 è stato superato l''importo di credito consentito di %2 %3';
								|pl = 'W kontrakcie %1 została przekroczona dopuszczalna wartość pożyczki na %2 %3';
								|tr = '%1 sözleşmesine göre mevcut kredi tutarı %2 %3 aşıldı'");
		
		For Each ErrorString In ControlResults.ErrorsLimitAmountOwed Do
			
			MessageText = StrTemplate(MessageTemplate, ErrorString.Contract, ErrorString.ExcessAmount,
				ErrorString.Currency);
			
			If DeviationFromPaymentTermsIsAvailable Then
				Common.MessageToUser(MessageText, Document);
			Else
				Common.MessageToUser(MessageText, Document,,, Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "RegisteredRecordsSettlementsWithCustomersChangeTermControl") Then
		
		MessageTemplate = NStr("vi = 'Theo hợp đồng %1, có khoản nợ quá hạn với số tiền %2%3';
								|ru = 'По договору %1 имеется просроченная задолженность на сумму %2 %3';
								|en = 'There are AR/AP overdue under the contract %1 in the amount of %2%3'; fa = 'There are AR/AP overdue under the contract %1 in the amount of %2%3';
								|it = 'Secondo il contratto %1 esiste un debito arretrato per l''importo di %2 %3';
								|pl = 'W kontrakcie %1 jest obecne przeterminowane zobowiązanie na kwotę %2 %3';
								|tr = '%1 sözleşmesine göre %2 %3 tutarında vadesi geçmiş borç mevcut'");
		
		For Each ErrorString In ControlResults.ErrorsControlOfTermOfDebt Do
			
			MessageText = StrTemplate(MessageTemplate, ErrorString.Contract, ErrorString.ARAPOverdue,
				ErrorString.Currency);
			
			If DeviationFromPaymentTermsIsAvailable Then
				Common.MessageToUser(MessageText, Document);
			Else
				Common.MessageToUser(MessageText, Document,,, Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region Prepayments
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "SettlementsWithCustomersChanges") Then
		
		MessageTemplate = NStr("vi = 'Không đủ số dư ứng trước %1, số dư hiện tại %2 %4, cần %3 %4';
								|ru = 'Не хватает остатка аванса на %1, текущий остаток %2 %4, требуется %3 %4';
								|en = 'There is not enough prepayment balance for %1, the current balance is %2 %4, the required balance is %3 %4'; fa = 'There is not enough prepayment balance for %1, the current balance is %2 %4, the required balance is %3 %4';
								|it = 'Не хватает остатка аванса на %1, текущий остаток %2 %4, требуется %3 %4';
								|pl = 'There is not enough prepayment balance for %1, the current balance is %2 %4, the required balance is %3 %4';
								|tr = '%1 için ön ödeme bakiyesi yetersiz, mevcut bakiye %2 %4, gereken %3 %4'");
		
		For Each ErrorString In ControlResults.ErrorsControlOfCreditedAdvancesOnInvoicesClient Do
			
			SumBalance = ?((ErrorString.ExcessAmount - ErrorString.AmountOfCreditReduction) < 0,0,ErrorString.ExcessAmount - ErrorString.AmountOfCreditReduction);
			
			MessageText = StrTemplate(MessageTemplate,
										ErrorString.AdvanceDocument,
										SumBalance,
										ErrorString.ExcessAmount,
										ErrorString.Currency);
			
			If DeviationFromPaymentTermsIsAvailable  Or Not ErrorString.RaiseException1 Then
				Common.MessageToUser(MessageText, Document);
			Else
				Common.MessageToUser(MessageText, Document,,, Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "VendorsARAPAccountingChanges") Then
		
		MessageTemplate = NStr("vi = 'Không đủ số dư ứng trước %1, số dư hiện tại %2 %4, cần %3 %4';
								|ru = 'Не хватает остатка аванса на %1, текущий остаток %2 %4, требуется %3 %4';
								|en = 'There is not enough prepayment balance for %1, the current balance is %2 %4, the required balance is %3 %4'; fa = 'There is not enough prepayment balance for %1, the current balance is %2 %4, the required balance is %3 %4';
								|it = 'Не хватает остатка аванса на %1, текущий остаток %2 %4, требуется %3 %4';
								|pl = 'There is not enough prepayment balance for %1, the current balance is %2 %4, the required balance is %3 %4';
								|tr = '%1 için ön ödeme bakiyesi yetersiz, mevcut bakiye %2 %4, gereken %3 %4'");
		
		For Each ErrorString In ControlResults.ErrorsControlOfCreditedAdvancesOnInvoicesSupplier Do
			
			SumBalance = ?((ErrorString.ExcessAmount - ErrorString.AmountOfCreditReduction) < 0, 0, ErrorString.ExcessAmount - ErrorString.AmountOfCreditReduction);
			
			MessageText = StrTemplate(MessageTemplate,
										ErrorString.AdvanceDocument,
										SumBalance,
										ErrorString.ExcessAmount,
										ErrorString.Currency);
			
			If DeviationFromPaymentTermsIsAvailable  Or Not ErrorString.RaiseException1 Then
				Common.MessageToUser(MessageText, Document);
			Else
				Common.MessageToUser(MessageText, Document,,, Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region BeingPaid
	
	If DocumentsPosting.ThereAreRecordsInTable(Document, "MovementSettlementsWithCustomersChangePaid")
		Or DocumentsPosting.ThereAreRecordsInTable(Document, "MovementSettlementsWithSuppliersChangePaid") Then
		
		MessageTemplate = NStr("vi = 'Theo đối tượng hạch toán %1 đã thanh toán lớn hơn số tiền được duyệt trong đề nghị là %2 %3';
								|ru = 'По объекту расчетов %1 оплачивается больше, чем утверждено в заявке, на %2 %3';
								|en = 'Under AR/AP object %1 payment is greater than confirmed in the request by %2 %3'; fa = 'Under AR/AP object %1 payment is greater than confirmed in the request by %2 %3';
								|it = 'Per l''oggetto dei calcoli %1 si paga di più di quanto indicato nella richiesta di %2 %3';
								|pl = 'Wg obiektu rozliczeń %1 wypłaca się więcej, niż, jest zatwierdzono w zleceniu, o %2 %3';
								|tr = '%1 alacak/borç nesnesine göre, başvuruda onaylanandan %2 %3 kadar daha fazla ödendi'");
		
		For Each ErrorString In ControlResults.ErrorsArePaid Do
			MessageText = StrTemplate(MessageTemplate,
				ErrorString.ARAPObject, ErrorString.Sum, ErrorString.Currency);
			Common.MessageToUser(MessageText, Document,,, Cancel);
		EndDo;
	EndIf;
	
	#EndRegion
	
EndProcedure

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	If Document.AdditionalProperties.Property("WriteMode")
		And Document.AdditionalProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		Query = New Query;
		Query.Text = "
			|SELECT ALLOWED
			|	ARAPAccountingScheduleAdjustment.Ref AS Ref
			|FROM
			|	Document.ARAPAccountingScheduleAdjustment AS ARAPAccountingScheduleAdjustment
			|WHERE
			|	ARAPAccountingScheduleAdjustment.DocumentBasis = &Ref
			|	AND ARAPAccountingScheduleAdjustment.Posted";
		Query.SetParameter("Ref", Document.Ref);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ErrorText = StrTemplate(
				NStr("vi = 'Đã kết chuyển chứng từ %1 trên cơ sở chứng từ này, ban đầu cần hủy chứng từ điều chỉnh.';
					|ru = 'На основании данного документа проведен документ %1, сначала нужно отменить документ корректировки.';
					|en = 'The %1 document is posted based on this document. First, cancel the adjustment document.'; fa = 'The %1 document is posted based on this document. First, cancel the adjustment document.';
					|it = 'The %1 document is posted based on this document. First, cancel the adjustment document.';
					|pl = 'The %1 document is posted based on this document. First, cancel the adjustment document.';
					|tr = 'Mevcut belge temelinde %1 belgesi kaydedildi, öncelikle düzeltme belgesinin iptal edilmesi gerekmektedir.'"),
				Selection.Ref);
			Common.MessageToUser(ErrorText, Selection.Ref, , , Cancel);
		EndDo;
	EndIf;
	
	// Properties of the Registered Records are created for the accounting mechanism
	AdditionalDocumentProperties = Document.AdditionalProperties;
	If AdditionalDocumentProperties.Property("DocumentsPosting")
		And AdditionalDocumentProperties.DocumentsPosting.Property("PropertiesOfRegisteredRecordsOfMechanisms") Then
		AdditionalDocumentProperties.DocumentsPosting.PropertiesOfRegisteredRecordsOfMechanisms.Insert("ARAPAccounting", New Structure);
	EndIf;
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//								used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	ThereAreChangesInSettlementsWithCustomers = TempTablesManager.Tables.Find("SettlementsWithCustomersChanges") <> Undefined;
	ThereAreChangesInSettlementsWithSuppliers = TempTablesManager.Tables.Find("VendorsARAPAccountingChanges") <> Undefined;
	
	If Cancel
		Or Not ThereAreChangesInSettlementsWithCustomers
			And Not ThereAreChangesInSettlementsWithSuppliers Then
		Return;
	EndIf;
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	AdditionalPropertiesOfConducting = Document.AdditionalProperties.DocumentsPosting;
	ChangesTable        = OnlineARAPAccountingServer.TableOfChangesForRecalculation(TempTablesManager);
	
	DistributionParameters = OnlineARAPAccountingServer.CalculationDistributionParameters();
	DistributionParameters.SupplementDistributeReceivers = True;
	
	If ThereAreChangesInSettlementsWithCustomers Then
		CheckOrderOfOperationOfSourceCalculationObjects(
			Document.RegisterRecords.CustomersARAPAccounting.Unload(),
			AdditionalPropertiesOfConducting,
			Cancel);
	EndIf;
	
	If ThereAreChangesInSettlementsWithSuppliers Then
		CheckOrderOfOperationOfSourceCalculationObjects(
			Document.RegisterRecords.VendorsARAPAccounting.Unload(),
			AdditionalPropertiesOfConducting,
			Cancel);
	EndIf;
		
	If Document.DataExchange.Load Then
		PerformDistributionOfMutualSettlementsInTransaction = False;
	ElsIf AdditionalPropertiesOfConducting.Property("PropertiesOfRegisteredRecordsOfMechanisms")
		And AdditionalPropertiesOfConducting.PropertiesOfRegisteredRecordsOfMechanisms.Property("ARAPAccounting")
		And AdditionalPropertiesOfConducting.PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.Property("PerformDistributionOfMutualSettlementsInTransaction") Then
		PerformDistributionOfMutualSettlementsInTransaction = AdditionalPropertiesOfConducting.PropertiesOfRegisteredRecordsOfMechanisms.ARAPAccounting.PerformDistributionOfMutualSettlementsInTransaction;
	Else
		PerformDistributionOfMutualSettlementsInTransaction = Not OnlineARAPAccountingServer.AllocateARAPInBackgroundJob();
	EndIf;
	
	If Constants.MigrationToOnlineARAPAccountingHasStarted.Get() Then
		OnlineARAPAccountingServer.RegisterChangesToDeferredAllocation(Document.Ref, ChangesTable);
	EndIf;
	
	If NewOnlineARAPAccounting And PerformDistributionOfMutualSettlementsInTransaction Then
		
		OnlineARAPAccountingServer.FillInOperationalARAPAccountsAccordingToTable(DistributionParameters, ChangesTable);
		
	EndIf;
	
	TableOfPaymentObjects = CreateTableOfPaymentObjects(
		Document.Ref,
		TempTablesManager);
	
	TableOfPaymentObjects.Indexes.Add("TheseAreSettlementsWithCustomers");
	
	If ThereAreChangesInSettlementsWithCustomers Then
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithCustomers(
			TableOfPaymentObjects.Copy(New Structure("TheseAreSettlementsWithCustomers",True)));
	EndIf;
	
	If ThereAreChangesInSettlementsWithSuppliers Then
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithSuppliers(
			TableOfPaymentObjects.Copy(New Structure("TheseAreSettlementsWithCustomers",False)),,
			Document.AdditionalProperties.Property("SkipScheduleUpdate"));
	EndIf;
	
EndProcedure

// The function receives temporary tables of exchange rates and areas of activity.
// 
// Parameters:
//  QueryTextOfSourceTable - String - Query Text with data on settlement objects, currencies, And exchange rate dates
//  ThisIsPaymentOperation - Boolean - The default value is False, True for payment and refund operations
// 
// Returns:
//  String - Query Text With the created temporary tables vtcoefficientcounts currency And Vtdirection of activity
Function GetTableOfExchangeRatesLinesOfBusiness(QueryTextOfSourceTable, ThisIsPaymentOperation = False) Export
	
	// Billing always ignores the Contract rate when conducting, because when paying in foreign currency, the rate from the Contract cannot be applied, 
	// and when paying in the accounting currency, the rate from the Contract has already been applied in the form of the document itself and the calculation is not required during the execution
	If ThisIsPaymentOperation Then
		CourseFromContract = "FALSE";
	Else
		CourseFromContract = "ISNULL(DocumentExchangeRates.ARAPObject.Contract.ContractRateOption,
			|		VALUE(Enum.ContractRateOptions.Mutable)) = VALUE(Enum.ContractRateOptions.SpecifiedInContract)";
	EndIf;
	
	QueryText = 
		"SELECT DISTINCT
		|	*
		|INTO TT_TableDocumentExchangeRates
		|FROM
		|	&NestedQuery AS NestedQuery
		|;
		|SELECT DISTINCT
		|	DocumentExchangeRates.Ref AS Ref,
		|	DocumentExchangeRates.ARAPObject AS ARAPObject,
		|	DocumentExchangeRates.ARAPObject.Contract AS Contract,
		|	DocumentExchangeRates.ARAPObject.LineOfBusiness AS LineOfBusiness,
		|	DocumentExchangeRates.DateOfCourse AS DateOfCourse,
		|	DocumentExchangeRates.DocumentCurrency AS DocumentCurrency,
		|	DocumentExchangeRates.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	DocumentExchangeRates.ARAPCurrency AS ARAPCurrency,
		|	&ManagementAccountingCurrency AS ManagementAccountingCurrency,
		|	NOT FixedExchangeRates.Document IS NULL
		|	AND CASE
		|		WHEN DocumentExchangeRates.ARAPObject.Contract.ContractRateOption IS NULL
		|			THEN FALSE
		|		ELSE DocumentExchangeRates.ARAPObject.Contract.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
		|	END AS FixedInvoiceRate,
		|	&CourseFromContract AS CourseFromContract,
		|	ISNULL(FixedExchangeRates.ARAPCurrency, VALUE(Catalog.Currencies.EmptyRef)) AS
		|		CurrencyOfARAPAccountsIsFixedRate,
		|	ISNULL(FixedExchangeRates.RateARAPCurrencyNumerator, 1) AS CurrencyFixedRateNumerator,
		|	ISNULL(FixedExchangeRates.RateARAPCurrencyDenominator, 1) AS
		|		CurrencyFixedRateDenominator
		|INTO TT_ExtendedTableOfExchangeRates
		|FROM
		|	TT_TableDocumentExchangeRates AS DocumentExchangeRates
		|		LEFT JOIN InformationRegister.DocumentCurrenciesAndRates AS FixedExchangeRates
		|		ON DocumentExchangeRates.ARAPObject.OBJECT = FixedExchangeRates.Document
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentExchangeRates.DateOfCourse AS DateOfCourse,
		|	DocumentExchangeRates.DocumentCurrency AS Currency,
		|	DocumentExchangeRates.LocalAccountingCurrency AS LocalAccountingCurrency
		|INTO TT_ExchangeRatesOfDocumentLines
		|FROM
		|	TT_ExtendedTableOfExchangeRates AS DocumentExchangeRates
		|
		|UNION
		|
		|SELECT
		|	DocumentExchangeRates.DateOfCourse AS DateOfCourse,
		|	DocumentExchangeRates.ARAPCurrency AS Currency,
		|	DocumentExchangeRates.LocalAccountingCurrency AS LocalAccountingCurrency
		|FROM
		|	TT_ExtendedTableOfExchangeRates AS DocumentExchangeRates
		|
		|UNION
		|
		|SELECT
		|	DocumentExchangeRates.DateOfCourse AS DateOfCourse,
		|	DocumentExchangeRates.ManagementAccountingCurrency AS Currency,
		|	DocumentExchangeRates.LocalAccountingCurrency AS LocalAccountingCurrency
		|FROM
		|	TT_ExtendedTableOfExchangeRates AS DocumentExchangeRates
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataForCourses.DateOfCourse AS DateOfCourse,
		|	DataForCourses.Currency AS Currency,
		|	DataForCourses.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	MAX(ExRates.Period) AS RatePeriod
		|INTO VT_ExchangeRatePeriodsDocumentLines
		|FROM
		|	TT_ExchangeRatesOfDocumentLines AS DataForCourses
		|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExRates
		|		ON ExRates.Period <= DataForCourses.DateOfCourse
		|		AND ExRates.Currency = DataForCourses.Currency
		|		AND ExRates.BaseCurrency = DataForCourses.LocalAccountingCurrency
		|GROUP BY
		|	DataForCourses.DateOfCourse,
		|	DataForCourses.Currency,
		|	DataForCourses.LocalAccountingCurrency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////		
		|SELECT
		|	CoursePeriods.DateOfCourse AS DateOfCourse,
		|	CoursePeriods.Currency AS Currency,
		|	DocumentExchangeRates_.CourseNumerator AS CurrencyExchangeRateNumerator,
		|	DocumentExchangeRates_.CourseDenominator AS CurrencyExchangeRateDenominator
		|INTO VT_DataOfDocumentSExchangeRates
		|FROM
		|	VT_ExchangeRatePeriodsDocumentLines AS CoursePeriods
		|		INNER JOIN InformationRegister.RelativeExchangeRates AS DocumentExchangeRates_
		|		ON CoursePeriods.RatePeriod = DocumentExchangeRates_.Period
		|		AND CoursePeriods.Currency = DocumentExchangeRates_.Currency
		|		AND CoursePeriods.LocalAccountingCurrency = DocumentExchangeRates_.BaseCurrency
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataForCourses.DateOfCourse AS DateOfCourse,
		|	DataForCourses.Contract AS Contract,
		|	MAX(ExRates.Period) AS RatePeriod
		|INTO VT_PeriodsCoursesOfContracts
		|FROM
		|	TT_ExtendedTableOfExchangeRates AS DataForCourses
		|		INNER JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts AS ExRates
		|		ON ExRates.Period <= DataForCourses.DateOfCourse
		|		AND ExRates.Contract = DataForCourses.Contract
		|		AND DataForCourses.CourseFromContract
		|GROUP BY
		|	DataForCourses.DateOfCourse,
		|	DataForCourses.Contract
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////////////////		
		|SELECT
		|	CoursePeriods.DateOfCourse AS DateOfCourse,
		|	CoursePeriods.Contract AS Contract,
		|	ExchangeRatesContracts.CourseNumerator AS ContractCurrencyExchangeRateNumerator,
		|	ExchangeRatesContracts.CourseDenominator AS ContractCurrencyExchangeRateDenominator
		|INTO VT_ExchangeRateDataContracts
		|FROM
		|	VT_PeriodsCoursesOfContracts AS CoursePeriods
		|		INNER JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts AS ExchangeRatesContracts
		|		ON CoursePeriods.RatePeriod = ExchangeRatesContracts.Period
		|		AND CoursePeriods.Contract = ExchangeRatesContracts.Contract
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OriginalTableOfExchangeRates.Ref                               AS Ref,
		|	OriginalTableOfExchangeRates.DateOfCourse                            AS DateOfCourse,
		|	OriginalTableOfExchangeRates.ARAPCurrency                 AS ARAPCurrency,
		|	OriginalTableOfExchangeRates.LocalAccountingCurrency       AS LocalAccountingCurrency,
		|	OriginalTableOfExchangeRates.ARAPObject                       AS ARAPObject,
		//ManSCoefficient
		|	CAST(1.000000000000000000000000001 * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE ISNULL(DocumentExchangeRates_.CurrencyExchangeRateNumerator, 1)
		|	END * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.ManagementAccountingCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE ISNULL(ManExchangeRates.CurrencyExchangeRateDenominator, 1)
		|	END / 
		|	(CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE ISNULL(DocumentExchangeRates_.CurrencyExchangeRateDenominator, 1)
		|	END *
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.ManagementAccountingCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE ISNULL(ManExchangeRates.CurrencyExchangeRateNumerator, 1)
		|	END) AS NUMBER(31, 17))                                       AS ManSCoefficient,
		|
		//LocalCoefficient
		|	CAST(1.000000000000000000000000001 * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE ISNULL(DocumentExchangeRates_.CurrencyExchangeRateNumerator, 1)
		|	END * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.LocalAccountingCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE 1
		|	END / 
		|	(CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE ISNULL(DocumentExchangeRates_.CurrencyExchangeRateDenominator, 1)
		|	END * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.LocalAccountingCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE 1
		|	END) AS NUMBER(31, 17))                                       AS LocalCoefficient,
		|
		//CoefficientOfMutualSettlements
		|	CAST(1.000000000000000000000000001 * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE ISNULL(DocumentExchangeRates_.CurrencyExchangeRateNumerator, 1)
		|	END * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		WHEN OriginalTableOfExchangeRates.FixedInvoiceRate
		|			THEN CASE
		|				WHEN
		|					OriginalTableOfExchangeRates.ARAPCurrency = OriginalTableOfExchangeRates.CurrencyOfARAPAccountsIsFixedRate
		|					THEN OriginalTableOfExchangeRates.CurrencyFixedRateDenominator
		|				ELSE ISNULL(ExchangeRatesCalculations.CurrencyExchangeRateDenominator, 1)
		|			END
		|		ELSE ISNULL(ExchangeRatesCalculations.CurrencyExchangeRateDenominator, 1)
		|	END / 
		|	(CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE ISNULL(DocumentExchangeRates_.CurrencyExchangeRateDenominator, 1)
		|	END * 
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		WHEN OriginalTableOfExchangeRates.FixedInvoiceRate
		|			THEN CASE
		|				WHEN
		|					OriginalTableOfExchangeRates.ARAPCurrency = OriginalTableOfExchangeRates.CurrencyOfARAPAccountsIsFixedRate
		|					THEN OriginalTableOfExchangeRates.CurrencyFixedRateNumerator
		|				ELSE ISNULL(ExchangeRatesCalculations.CurrencyExchangeRateNumerator, 1)
		|			END
		|		ELSE ISNULL(ExchangeRatesCalculations.CurrencyExchangeRateNumerator, 1)
		|	END) AS NUMBER(31, 17))                                       AS CoefficientOfMutualSettlements,
		// The initial courses are placed in a table for recording in operational registers and subsequent use in the distribution of mutual settlements
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.ManagementAccountingCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE ISNULL(ManExchangeRates.CurrencyExchangeRateNumerator, 1)
		|	END                                                           AS ExchangeRateNumeratorOfManSCurrency,
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|		AND OriginalTableOfExchangeRates.ManagementAccountingCurrency = OriginalTableOfExchangeRates.ARAPCurrency
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE ISNULL(ManExchangeRates.CurrencyExchangeRateDenominator, 1)
		|	END                                                           AS ExchangeRateDenominatorCurrencyMan,
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateNumerator, 1)
		|		ELSE ISNULL(ExchangeRatesCalculations.CurrencyExchangeRateNumerator, 1)
		|	END                                                           AS RateARAPCurrencyNumerator,
		|	CASE
		|		WHEN OriginalTableOfExchangeRates.CourseFromContract
		|			THEN ISNULL(ExchangeRatesContracts.ContractCurrencyExchangeRateDenominator, 1)
		|		ELSE ISNULL(ExchangeRatesCalculations.CurrencyExchangeRateDenominator, 1)
		|	END                                                           AS RateARAPCurrencyDenominator
		|
		|INTO ARAPAccountingOfTTCurrencyConversionRates
		|FROM
		|	TT_ExtendedTableOfExchangeRates AS OriginalTableOfExchangeRates
		|		LEFT JOIN VT_ExchangeRateDataContracts AS ExchangeRatesContracts
		|		ON OriginalTableOfExchangeRates.DateOfCourse = ExchangeRatesContracts.DateOfCourse
		|		AND OriginalTableOfExchangeRates.Contract = ExchangeRatesContracts.Contract
		|		LEFT JOIN VT_DataOfDocumentSExchangeRates AS DocumentExchangeRates_
		|		ON OriginalTableOfExchangeRates.DateOfCourse = DocumentExchangeRates_.DateOfCourse
		|		AND OriginalTableOfExchangeRates.DocumentCurrency = DocumentExchangeRates_.Currency
		|		LEFT JOIN VT_DataOfDocumentSExchangeRates AS ManExchangeRates
		|		ON OriginalTableOfExchangeRates.DateOfCourse = ManExchangeRates.DateOfCourse
		|		AND OriginalTableOfExchangeRates.ManagementAccountingCurrency = ManExchangeRates.Currency
		|		LEFT JOIN VT_DataOfDocumentSExchangeRates AS ExchangeRatesCalculations
		|		ON OriginalTableOfExchangeRates.DateOfCourse = ExchangeRatesCalculations.DateOfCourse
		|		AND OriginalTableOfExchangeRates.ARAPCurrency = ExchangeRatesCalculations.Currency;
		//LineOfBusiness
		|
		|SELECT DISTINCT
		|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
		|	CASE 
		|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE) 
		|					AND DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|				OR ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
		|					AND DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
		|				AND NOT DirectionsOfDocuments.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
		|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS DirectionOfAnalytics
		|INTO TTLinesOfBusiness
		|FROM
		|	TT_ExtendedTableOfExchangeRates AS DirectionsOfDocuments
		|;
		|
		|DROP TT_TableDocumentExchangeRates;
		|DROP TT_ExtendedTableOfExchangeRates;
		|DROP TT_ExchangeRatesOfDocumentLines;
		|DROP VT_ExchangeRatePeriodsDocumentLines;
		|DROP VT_DataOfDocumentSExchangeRates;
		|DROP VT_ExchangeRateDataContracts;
		|DROP VT_PeriodsCoursesOfContracts";
	
	QueryText = StrReplace(QueryText, "&CourseFromContract", CourseFromContract);
	QueryText = StrReplace(QueryText, "&NestedQuery", "(" + QueryTextOfSourceTable + ")");
	
	Return QueryText;
	
EndFunction

// The function receives a temporary table of activity directions.
// 
// Parameters:
//  QueryTextOfSourceTable - String - Query Text with data on settlement objects, currencies, And exchange rate dates
// 
// Returns:
//  String - Query Text With the created temporary Tablereferencesexternal Links
Function GetTableOfLinesOfBusiness(QueryTextOfSourceTable) Export
	
	QueryText = 
		"SELECT DISTINCT
		|	*
		|INTO TT_TableLineOfBusiness
		|FROM
		|	&NestedQuery AS NestedQuery
		|;
		|SELECT 
		|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
		|	DirectionsOfDocuments.ARAPObject.LineOfBusiness AS LineOfBusiness,
		|	CASE 
		|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE) 
		|					AND DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|				OR ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
		|					AND DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
		|				AND NOT DirectionsOfDocuments.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
		|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS DirectionOfAnalytics
		|
		|INTO TTLinesOfBusiness
		|FROM
		|	TT_TableLineOfBusiness AS DirectionsOfDocuments
		|;
		|
		|DROP TT_TableLineOfBusiness
		|";

	QueryText = StrReplace(QueryText, "&NestedQuery", "(" + QueryTextOfSourceTable + ")");
	
	Return QueryText;
	
EndFunction

Function TTTextForTransferringCalculations(TableName = "") Export
	
	QueryTextDetails = "
	|
	|SELECT
	|	IncreasingCustomerDebt.Ref                                    AS Ref,
	|	IncreasingCustomerDebt.Organization                               AS Organization,
	|	IncreasingCustomerDebt.Partner                                   AS Partner,
	|	
	|	IncreasingCustomerDebt.ARAPObject                            AS CalculationObjectReceiver,
	|	IncreasingCustomerDebt.ARAPObject                            AS CalculationObjectSource,
	|	IncreasingCustomerDebt.ARAPCurrency                      AS ARAPCurrency,
	|	IncreasingCustomerDebt.AmountARAP                       AS AmountARAP,
	|	IncreasingCustomerDebt.DocumentCurrency                           AS DocumentCurrency,
	|	IncreasingCustomerDebt.Sum                                     AS Sum,
	|
	|	IncreasingCustomerDebt.DateOfCourse                                 AS DateOfCourse,
	|	IncreasingCustomerDebt.RecorderDate                          AS RecorderDate,
	|	IncreasingCustomerDebt.RecorderNumber                         AS RecorderNumber,
	|	IncreasingCustomerDebt.BusinessOperation                     AS BusinessOperation,
	|	IncreasingCustomerDebt.CashFlowItem             AS CashFlowItem
	|FROM
	|	#IncreasingCustomerDebt AS IncreasingCustomerDebt
	|WHERE
	|	(IncreasingCustomerDebt.ARAPObject.Organization <> IncreasingCustomerDebt.Organization
	|		OR IncreasingCustomerDebt.ARAPObject.Partner <> IncreasingCustomerDebt.Partner)
	|	AND IncreasingCustomerDebt.AmountARAP <> 0
	|";
		
	If ValueIsFilled(TableName) Then
		QueryTextDetails = StrReplace(QueryTextDetails, "IncreasingCustomerDebt", TableName);
	EndIf;
	
	Return QueryTextDetails;
	
EndFunction

Procedure CheckAndFillOutPartnerAccountingAnalytics(RegisterRecordTable) Export
	
	If RegisterRecordTable.Columns.Find("Partner") = Undefined 
		Or RegisterRecordTable.Columns.Find("Organization") = Undefined 
		Or RegisterRecordTable.Columns.Find("Counterparty") = Undefined 
		Or RegisterRecordTable.Columns.Find("Contract") = Undefined 
		Or RegisterRecordTable.Columns.Find("LineOfBusiness") = Undefined Then
		Return;
	EndIf;
	
	AnalyticsFields = "Partner, Organization, Counterparty, Contract, LineOfBusiness";
	TableOfFoundAnalytics = RegisterRecordTable.Copy(,AnalyticsFields); // ValueTable
	TableOfFoundAnalytics.Clear();
	TableOfFoundAnalytics.Columns.Add("AccountingDimensionByPartners", New TypeDescription("CatalogRef.DimensionKeysOfAccountingByPartners"));
	AnalyticsParameters = New Structure(AnalyticsFields);
	
	For Each Record In RegisterRecordTable Do
		
		If Not ValueIsFilled(Record.AccountingDimensionByPartners) Then
			
			FillPropertyValues(AnalyticsParameters, Record);
			If Not ValueIsFilled(AnalyticsParameters.Contract) Then
				If TypeOf(AnalyticsParameters.Counterparty) = Type("CatalogRef.Counterparties") Then
					AnalyticsParameters.Contract = Catalogs.CounterpartyContracts.EmptyRef();
				ElsIf TypeOf(AnalyticsParameters.Counterparty) = Type("CatalogRef.Companies") Then
					AnalyticsParameters.Contract = Catalogs.IntercompanyContracts.EmptyRef();
				EndIf;
			EndIf;
			
			AnalyticsLines_ = TableOfFoundAnalytics.FindRows(AnalyticsParameters);
			If AnalyticsLines_.Count() > 0 Then
				Record.AccountingDimensionByPartners = AnalyticsLines_[0].AccountingDimensionByPartners;
			Else
				Record.AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters);
				NwRw = TableOfFoundAnalytics.Add();
				FillPropertyValues(NwRw, Record);
			EndIf;
		EndIf;
		
		If RegisterRecordTable.Columns.Find("CorPartnerAccountingDimension") <> Undefined
			And RegisterRecordTable.Columns.Find("CorCompany") <> Undefined
			And Not ValueIsFilled(Record.CorPartnerAccountingDimension) 
			And ValueIsFilled(Record.CorCompany)
			And ValueIsFilled(Record.CorCounterparty) Then
			AnalyticsParameters.Partner = Record.CorPartner;
			AnalyticsParameters.Organization = Record.CorCompany;
			AnalyticsParameters.Counterparty = Record.CorCounterparty;
			AnalyticsParameters.Contract = Record.CorContract;
			AnalyticsParameters.LineOfBusiness = Record.CorLineOfBusiness;
			
			If Not ValueIsFilled(AnalyticsParameters.Contract) Then
				If TypeOf(AnalyticsParameters.Counterparty) = Type("CatalogRef.Counterparties") Then
					AnalyticsParameters.Contract = Catalogs.CounterpartyContracts.EmptyRef();
				ElsIf TypeOf(AnalyticsParameters.Counterparty) = Type("CatalogRef.Companies") Then
					AnalyticsParameters.Contract = Catalogs.IntercompanyContracts.EmptyRef();
				EndIf;
			EndIf;
			
			AnalyticsLines_ = TableOfFoundAnalytics.FindRows(AnalyticsParameters);
			If AnalyticsLines_.Count() > 0 Then
				Record.CorPartnerAccountingDimension = AnalyticsLines_[0].AccountingDimensionByPartners;
			Else
				Record.CorPartnerAccountingDimension = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters);
				NwRw = TableOfFoundAnalytics.Add();
				FillPropertyValues(NwRw, AnalyticsParameters);
				NwRw.AccountingDimensionByPartners = Record.CorPartnerAccountingDimension;
			EndIf;
			
		EndIf;
		
		If RegisterRecordTable.Columns.Find("DestinationAccountingDimensionByPartners") <> Undefined
			And RegisterRecordTable.Columns.Find("CompanyDestination") <> Undefined
			And Not ValueIsFilled(Record.DestinationAccountingDimensionByPartners) 
			And ValueIsFilled(Record.CompanyDestination)
			And ValueIsFilled(Record.CounterpartyReceiver) Then
			AnalyticsParameters.Partner = Record.PartnerReceiver;
			AnalyticsParameters.Organization = Record.CompanyDestination;
			AnalyticsParameters.Counterparty = Record.CounterpartyReceiver;
			AnalyticsParameters.Contract = Record.ContractDestination;
			AnalyticsParameters.LineOfBusiness = Record.FieldOfActivityReceiver;
			
			If Not ValueIsFilled(AnalyticsParameters.Contract) Then
				If TypeOf(AnalyticsParameters.Counterparty) = Type("CatalogRef.Counterparties") Then
					AnalyticsParameters.Contract = Catalogs.CounterpartyContracts.EmptyRef();
				ElsIf TypeOf(AnalyticsParameters.Counterparty) = Type("CatalogRef.Companies") Then
					AnalyticsParameters.Contract = Catalogs.IntercompanyContracts.EmptyRef();
				EndIf;
			EndIf;
			
			AnalyticsLines_ = TableOfFoundAnalytics.FindRows(AnalyticsParameters);
			If AnalyticsLines_.Count() > 0 Then
				Record.DestinationAccountingDimensionByPartners = AnalyticsLines_[0].AccountingDimensionByPartners;
			Else
				Record.DestinationAccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters);
				NwRw = TableOfFoundAnalytics.Add();
				FillPropertyValues(NwRw, AnalyticsParameters);
				NwRw.AccountingDimensionByPartners = Record.DestinationAccountingDimensionByPartners;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the fields:
//	Operation Order - used to search for Registered Records before and after the document being modified, to sort documents for offsetting payments and invoices.
//	The offsetting procedure of the payment date is used to search for Registered Records before and after the document being modified when offsetting documents by payment date.
// Parameters:
//  TableCalculations - ValueTable - the table of Registered Records according to the register of calculations with mandatory columns:
//   * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners,
//   * Period - Date,
//   * RecorderDate - Date,
//   * RecorderNumber - String,
//   * Kind - Number
//  DocumentType - Type - Type of registrar's document
//  ProceduresForOffsettingPaymentsOfInvoicesContracts - Map of KeyAndValue -Where:
// 		* Key - CatalogRef.CounterpartyContracts,CatalogRef.IntercompanyContracts - the calculation object for which the data was received.
// 		* Value - EnumRef.OffsetOrdersOfPaymentsAndInvoices
Procedure AddFillInOrderOfOperation(TableCalculations, DocumentType, ProceduresForOffsettingPaymentsOfInvoicesContracts = Undefined) Export
	
	If ProceduresForOffsettingPaymentsOfInvoicesContracts = Undefined Then
		ArrayAnalytics = TableCalculations.UnloadColumn("AccountingDimensionByPartners");
		ArrayAnalytics = CommonClientServer.CollapseArray(ArrayAnalytics);
		ComplianceWithContracts = Common.ObjectsAttributeValue(ArrayAnalytics,"Contract");
		ArrayOfContracts = TMCommonUseClientServer.ConvertMatchOrStructureToArray(ComplianceWithContracts, False);
		ArrayOfContracts = CommonClientServer.CollapseArray(ArrayOfContracts);
		ProceduresForOffsettingPaymentsOfInvoicesContracts = Common.ObjectsAttributeValue(ArrayOfContracts, "OffsetOrderOfPaymentsAndInvoices");
	EndIf;
	
	GeneralProcedureForCreditingInvoicePayments = Constants.OffsetOrderOfPaymentsAndInvoices.Get();
	
	If TableCalculations.Columns.Find("OperationProcedure") = Undefined Then
		TableCalculations.Columns.Add("OperationProcedure",            New TypeDescription("String"));
	EndIf;
	If TableCalculations.Columns.Find("SettlementProcedureByPaymentDate") = Undefined Then
		TableCalculations.Columns.Add("SettlementProcedureByPaymentDate", New TypeDescription("String"));
	EndIf;
	
	Type = OnlineARAPAccountingServer.TypeNumber(DocumentType);
	
	ThereIsPaymentDate = TableCalculations.Columns.Find("PaymentDate") <> Undefined;
	ThereIsSum = TableCalculations.Columns.Find("Sum") <> Undefined;
	ThereIsKindOfOperationForSorting = TableCalculations.Columns.Find("TypeOfOperationForSorting") <> Undefined;
	ThereIsOrderOfOperationsWithinDocument = TableCalculations.Columns.Find("OrderOfOperationsWithinDocument") <> Undefined;
	ThereIsStorno = TableCalculations.Columns.Find("ReversingEntry") <> Undefined;
	For Each Page1 In TableCalculations Do
		
		PaymentDate = ?(ThereIsPaymentDate And ValueIsFilled(Page1.PaymentDate), Page1.PaymentDate, Date(3000,1,1));
		
		If ThereIsKindOfOperationForSorting
			And (ProceduresForOffsettingPaymentsOfInvoicesContracts[Page1.Contract] = Enums.OffsetOrdersOfPaymentsAndInvoices.ByDocumentDateAndType
				Or Not ValueIsFilled(ProceduresForOffsettingPaymentsOfInvoicesContracts[Page1.Contract])
					And GeneralProcedureForCreditingInvoicePayments = Enums.OffsetOrdersOfPaymentsAndInvoices.ByDocumentDateAndType) Then
			TypeOfOperationForSorting = Page1.TypeOfOperationForSorting;
		Else
			TypeOfOperationForSorting = "0";
		EndIf;
		
		If ThereIsOrderOfOperationsWithinDocument Then
			OrderOfOperationsWithinDocument = Page1.OrderOfOperationsWithinDocument;
		Else
			OrderOfOperationsWithinDocument = "1";
		EndIf;
		
		// For storno records, you need to save the type of operation.
		// The order of operations within the document should always be empty.
		If ThereIsStorno And Page1.ReversingEntry = True And ValueIsFilled(Page1.OperationProcedure) Then
			TypeOfOperationForSorting = Mid(Page1.OperationProcedure,9,1);
			OrderOfOperationsWithinDocument = "";
		EndIf;
			
		// The payment plan can be carried out by period = payment date
		If (Not ThereIsSum Or Page1.Sum = 0)
			And DocumentType <> Type("DocumentRef.OBEntry") And DocumentType <> Type("DocumentRef.OBEntryARAP") Then
			Page1.OperationProcedure = OnlineARAPAccountingServer.Order(Page1.RecorderDate, Page1.RecorderNumber, DocumentType, TypeOfOperationForSorting, Type, OrderOfOperationsWithinDocument);
			Page1.SettlementProcedureByPaymentDate = OnlineARAPAccountingServer.Order(PaymentDate, Page1.RecorderNumber, DocumentType, TypeOfOperationForSorting, Type);
		// The actual calculations are always by period.
		Else
			Page1.OperationProcedure = OnlineARAPAccountingServer.Order(Page1.Period, Page1.RecorderNumber, DocumentType, TypeOfOperationForSorting, Type, OrderOfOperationsWithinDocument);
			Page1.SettlementProcedureByPaymentDate = OnlineARAPAccountingServer.Order(PaymentDate, Page1.RecorderNumber, DocumentType, TypeOfOperationForSorting, Type);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

// If the AR/AP object receiver has the order of operation before the source
// , then the document will be interrupted and an error message will be issued.
Procedure CheckOrderOfOperationOfSourceCalculationObjects(ChangesTable, AdditionalProperties, Cancel)
	
	If AdditionalProperties <> Undefined
		And AdditionalProperties.Property("DocumentProperties")
		And AdditionalProperties.DocumentProperties.Property("WriteMode")
		And AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.Posting Then
		TableToCheck_ = ChangesTable.Copy(,
			"AccountingDimensionByPartners,
			|ARAPObject,
			|Currency,
			|ByDataOfSourceARAPObject,
			|DestinationAccountingDimensionByPartners,
			|CalculationObjectReceiver,
			|CurrencyReceiver,
			|Period");
		For Each TableRow In TableToCheck_ Do
			TableRow.Period = BegOfDay(TableRow.Period);
		EndDo;
		TableToCheck_.Indexes.Add("DestinationAccountingDimensionByPartners, CalculationObjectReceiver, CurrencyReceiver");
		Filter = New Structure("DestinationAccountingDimensionByPartners, CalculationObjectReceiver, CurrencyReceiver");
		For Each TableRow In TableToCheck_ Do
			If Not Cancel And TableRow.ByDataOfSourceARAPObject Then
				Filter.DestinationAccountingDimensionByPartners = TableRow.AccountingDimensionByPartners;
				Filter.CalculationObjectReceiver = TableRow.ARAPObject;
				Filter.CurrencyReceiver = TableRow.Currency;
				RowsSources = TableToCheck_.FindRows(Filter);
				For Each SourceRow In RowsSources Do
					If SourceRow.Period > TableRow.Period Then
						Common.MessageToUser(
							NStr("vi = 'Ngày biến động đối tượng hạch toán đích không thể nhỏ hơn ngày biến động đối tượng hạch toán nguồn.';
								|ru = 'Дата движения объекта расчетов приемника не может быть меньше даты движения объекта расчетов источника.';
								|en = 'The date of the destination AR/AP object record must be later than the date of the source AR/AP object record.'; fa = 'The date of the destination AR/AP object record must be later than the date of the source AR/AP object record.';
								|it = 'Дата движения объекта расчетов приемника не может быть меньше даты движения объекта расчетов источника.';
								|pl = 'The date of the destination AR/AP object record must be later than the date of the source AR/AP object record.';
								|tr = 'Alıcı uzlaştırma nesnesinin hareket tarihi, kaynak uzlaştırma nesnesinin hareket tarihinden daha az olamaz.'"),,,,
							Cancel);
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure CheckSetCalculationObjects(RegisterRecordTable, Cancel, TheseAreSettlementsWithCustomers)
	
	If Cancel Then
		Return;
	EndIf;
	
	RegisterName = ?(TheseAreSettlementsWithCustomers,
					Metadata.AccumulationRegisters.CustomersARAPAccounting.Presentation(),
					Metadata.AccumulationRegisters.VendorsARAPAccounting.Presentation());
	NameOfFieldIsARAPObject = ?(TheseAreSettlementsWithCustomers,
					Metadata.AccumulationRegisters.CustomersARAPAccounting.Dimensions.ARAPObject.Presentation(),
					Metadata.AccumulationRegisters.VendorsARAPAccounting.Dimensions.ARAPObject.Presentation());
	// First, you need to check the fullness of the AR/AP object field
	For Each Movement In RegisterRecordTable Do
		If Not ValueIsFilled(Movement.ARAPObject) Then
			Cancel = True;
			Raise(StrTemplate(NStr("ru = 'Запись не верна! Значение поля ""%1"" не может быть пустым! (Регистр накопления: %2; Номер строки: %3)';
									|vi = 'The record is invalid. Fill in the ""%1"" field. (Accumulation register: %2; Line number: %3)';
									|en = 'The record is invalid. Fill in the ""%1"" field. (Accumulation register: %2; Line number: %3)'; fa = 'The record is invalid. Fill in the ""%1"" field. (Accumulation register: %2; Line number: %3)';
									|it = 'The record is invalid. Fill in the ""%1"" field. (Accumulation register: %2; Line number: %3)';
									|pl = 'The record is invalid. Fill in the ""%1"" field. (Accumulation register: %2; Line number: %3)';
									|tr = 'Kayıt doğru değil! ""%1"" alanının değeri boş olamaz! (Birikim kaydı: %2; Satır numarası: %3)'"),
			                            NameOfFieldIsARAPObject,
			                            RegisterName,
			                            RegisterRecordTable.IndexOf(Movement) + 1));
		EndIf;
	EndDo;
	
	ARAPObjects = RegisterRecordTable.Copy(,"ARAPObject");
	ARAPObjects.GroupBy("ARAPObject");
	ARAPObjects = ARAPObjects.UnloadColumn("ARAPObject");
	
	AttributesOfARAPObjcts = Common.ObjectsAttributesValues(ARAPObjects,"DeletionMark,PaymentType_");
	For Each KeyAndValue In AttributesOfARAPObjcts Do
		If KeyAndValue.Value.DeletionMark Then
			Cancel = True;
			Raise(StrTemplate(NStr("vi = 'Không thể chọn đối tượng hạch toán %1 trong các chứng từ, bởi vì đối tượng gốc không còn là đối tượng hạch toán hoặc đã bị đặt dấu xóa.';
									|ru = 'Объект расчетов %1 не может быть выбран в документах, т.к. исходный объект больше не является объектом расчетов или помечен на удаление.';
									|en = 'Cannot select the %1 AR/AP object in documents, as the source object is no longer an AR/AP object or is marked for deletion.'; fa = 'Cannot select the %1 AR/AP object in documents, as the source object is no longer an AR/AP object or is marked for deletion.';
									|it = 'Объект расчетов %1 не может быть выбран в документах, т.к. исходный объект больше не является объектом расчетов или помечен на удаление.';
									|pl = 'Cannot select the %1 AR/AP object in documents, as the source object is no longer an AR/AP object or is marked for deletion.';
									|tr = '%1 Alacak/Borç nesnesi belgelerde seçilemez çünkü kaynak nesne artık Alacak/Borç nesnesi değildir veya silinmek üzere işaretlenmiştir.'"),
													KeyAndValue.Key));
		EndIf;
		
		If TheseAreSettlementsWithCustomers And KeyAndValue.Value.PaymentType_ <> Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting
			Or Not TheseAreSettlementsWithCustomers And KeyAndValue.Value.PaymentType_ <> Enums.PartnersARAPAccountingTypes.VendorARAPAccounting Then
			Cancel = True;
			Raise(StrTemplate(NStr("vi = 'Không thể ghi lại đối tượng hạch toán ""%1"" có kiểu hạch toán ""%2"" vào biểu ghi ""%3"".';
									|ru = 'Объект расчетов ""%1"" с типом расчетов ""%2"" не может быть записан в регистр ""%3"".';
									|en = 'The ""%1"" AR/AP object with the ""%2"" payment type cannot be recorded in the ""%3"" register.'; fa = 'The ""%1"" AR/AP object with the ""%2"" payment type cannot be recorded in the ""%3"" register.';
									|it = 'Объект расчетов ""%1"" с типом расчетов ""%2"" не может быть записан в регистр ""%3"".';
									|pl = 'The ""%1"" AR/AP object with the ""%2"" payment type cannot be recorded in the ""%3"" register.';
									|tr = 'Объект расчетов ""%1"" с типом расчетов ""%2"" не может быть записан в регистр ""%3"".'"),
													KeyAndValue.Key, KeyAndValue.Value.PaymentType_, RegisterName));
		EndIf;
	EndDo;
	
EndProcedure

// Generates a table of payment objects for which it is necessary to calculate the payment schedule after recording the RegisteredRecorded payments.
// 
// Parameters:
//  Recorder - DocumentRef - The document whose Registered Records were recorded
//  TempTablesManager - TempTablesManager - contains a table of changes
// 
// Returns:
//  ValueTable:
//   * TheseAreSettlementsWithCustomers - Boolean - indicates the calculation type.
//   * PaymentObject - DefinedType.ARAPObject - reference to the object of the calculation object.
//   * ARAPObject - CatalogRef.ARAPObjects - the settlement object to calculate the payment schedule for.
//
Function CreateTableOfPaymentObjects(Recorder, TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Recorder", Recorder);
	Query.Text = "";
	If TempTablesManager.Tables.Find("SettlementsWithCustomersChanges") <> Undefined Then
		Query.Text = Query.Text + "
		|SELECT DISTINCT
		|	TRUE AS TheseAreSettlementsWithCustomers,
		|	ISNULL(Table.ARAPObject.Object, &Recorder) AS PaymentObject,
		|	Table.ARAPObject AS ARAPObject
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Table
		|WHERE
		|	Table.Recorder = &Recorder
		|	AND Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	TRUE AS TheseAreSettlementsWithCustomers,
		|	ISNULL(Table.ARAPObject.OBJECT, Table.Document) AS PaymentObject,
		|	Table.ARAPObject AS ARAPObject
		|FROM
		|	SettlementsWithCustomersChanges AS Table
		|WHERE
		|	Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)";
		
	EndIf;
	
	If TempTablesManager.Tables.Find("SettlementsWithCustomersChanges") <> Undefined 
		And TempTablesManager.Tables.Find("VendorsARAPAccountingChanges") <> Undefined Then
		Query.Text = Query.Text + "
		|
		|UNION
		|";
	EndIf;
	
	If TempTablesManager.Tables.Find("VendorsARAPAccountingChanges") <> Undefined Then
		Query.Text = Query.Text + "
		|SELECT DISTINCT
		|	FALSE AS TheseAreSettlementsWithCustomers,
		|	ISNULL(Table.ARAPObject.Object, &Recorder) AS PaymentObject,
		|	Table.ARAPObject AS ARAPObject
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Table
		|WHERE
		|	Table.Recorder = &Recorder
		|	AND Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	FALSE AS TheseAreSettlementsWithCustomers,
		|	ISNULL(Table.ARAPObject.OBJECT, Table.Document) AS PaymentObject,
		|	Table.ARAPObject AS ARAPObject
		|FROM
		|	VendorsARAPAccountingChanges AS Table
		|WHERE
		|	Table.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|";
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion
