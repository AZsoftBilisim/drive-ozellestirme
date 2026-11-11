#Region Public

// Returns an empty structure of parameters for forming the Currency label and document rates.
//
// Returns:
//  Structure - parameters to fill in in the form where:
//   * DonTShowCalculations - Boolean
//   * DocumentCurrency - CatalogRef.Currencies
//   * ARAPCurrency - CatalogRef.Currencies
//   * CurrencyOfComplianceAccounting - CatalogRef.Currencies
//   * DocumentAmount - Number
//   * AmountARAP - Number
//   * CourseNumerator - Number
//   * CourseDenominator - Number
//
Function CurrencyLabelParameters() Export
	
	Return New Structure("DonTShowCalculations,
							|DocumentCurrency,
							|ARAPCurrency,
							|CurrencyOfComplianceAccounting,
							|DocumentAmount,
							|AmountARAP,
							|CourseNumerator,
							|CourseDenominator", False);
	
EndFunction

// Calculates the final balance in the tabular part of the Grouping of financial instruments in the reconciliation document.
//
// Parameters:
//  Group - FormDataCollection - The current row in the table part of the grouping.
//  DetailedRecords - FormDataCollection - Table part of detailed records of financial instruments.
//
Procedure CalculateFinalBalanceOnFinancialInstruments(Group, DetailedRecords) Export
	
	Filter = New Structure("Contract");
	FillPropertyValues(Filter, Group);
	
	GroupingDetails_1 = DetailedRecords.FindRows(Filter);
	
	TurnoverAsset = New Structure("Dr, Cr", 0, 0);
	TurnoverLiability = New Structure("Dr, Cr", 0, 0);
	For Each Record In GroupingDetails_1 Do
		If Group.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor") Then
			AddTurnover(TurnoverLiability, Record, "LeaseObligations");
			AddTurnover(TurnoverAsset, Record, "DepositPayment");
			AddTurnover(TurnoverLiability, Record, "RentalService");
			AddTurnover(TurnoverLiability, Record, "BuyoutValue");
			
		ElsIf Group.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CreditorARAPAccounting") Then
			AddTurnover(TurnoverLiability, Record, "PrincipalDebt");
			AddTurnover(TurnoverLiability, Record, "Interests");
			AddTurnover(TurnoverLiability, Record, "Fee");
			
		Else
			AddTurnover(TurnoverAsset, Record, "PrincipalDebt");
			AddTurnover(TurnoverAsset, Record, "Interests");
			AddTurnover(TurnoverAsset, Record, "Fee");
			
		EndIf;
	EndDo;
	
	Group.ClosingBalanceDr = Group.OpeningBalanceDr + TurnoverAsset.Dr - TurnoverAsset.Cr;
	Group.ClosingBalanceCr = Group.OpeningBalanceCr - TurnoverLiability.Dr + TurnoverLiability.Cr;
	Group.TurnoverReceipt = TurnoverAsset.Dr + TurnoverLiability.Dr;
	Group.TurnoverExpense = TurnoverAsset.Cr + TurnoverLiability.Cr;
	
	// we will set the final balance, if there was no initial balance
	If Group.OpeningBalanceDr = 0 Then
		Group.ClosingBalanceDr = TurnoverAsset.Dr - TurnoverAsset.Cr;
	EndIf;
		
	If Group.OpeningBalanceCr = 0 Then
		Group.ClosingBalanceCr = -TurnoverLiability.Dr + TurnoverLiability.Cr;
	EndIf;
	
	If Group.PaymentType_ <> PredefinedValue("Enum.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor") Then
		ClosingBalance = Group.ClosingBalanceDr - Group.ClosingBalanceCr;
		If ClosingBalance > 0 Then
			Group.ClosingBalanceDr = ClosingBalance;
			Group.ClosingBalanceCr = 0;
		Else
			Group.ClosingBalanceDr = 0;
			Group.ClosingBalanceCr = -ClosingBalance;
		EndIf;
	EndIf;
	
	If Group.ClosingBalanceDr < 0 Then
		Group.ClosingBalanceCr = Group.ClosingBalanceCr - Group.ClosingBalanceDr;
		Group.ClosingBalanceDr = 0;
	EndIf;
	If Group.ClosingBalanceCr < 0 Then
		Group.ClosingBalanceDr = Group.ClosingBalanceDr - Group.ClosingBalanceCr;
		Group.ClosingBalanceCr = 0;
	EndIf;
	
EndProcedure

// Calculates the final balance in the tabular part of the Grouping of mutual settlements of the document Sverkavzaimorachetov.
//
// Parameters:
//  Group - FormDataCollection - The current row in the table part of the grouping.
//  DetailedRecords - FormDataCollection - A table of detailed records of payments.
//  LocalAmounts - Boolean - Use resources with regl for calculation. amounts.
//
Procedure CalculateFinalBalanceOnMutualSettlements(Group, DetailedRecords, LocalAmounts = False) Export
	
	Filter = New Structure("PaymentType_,ARAPObject,Partner,Contract");
	FillPropertyValues(Filter, Group);
	
	DebtAmount_ = ?(LocalAmounts, "DebtAmountLocal", "DebtAmount_");
	AmountPrepayment = ?(LocalAmounts, "PrepaymentAmountLocal_", "AmountPrepayment");
	TurnoverReceipt = ?(LocalAmounts, "TurnoverDebitLocal", "TurnoverReceipt");
	TurnoverExpense = ?(LocalAmounts, "TurnoverCreditLocal", "TurnoverExpense");
	OpeningBalance = ?(LocalAmounts, "OpeningBalanceLocal", "OpeningBalance");
	ClosingBalance = ?(LocalAmounts, "ClosingBalanceLocal", "ClosingBalance");
	
	GroupingDetails_1 = DetailedRecords.FindRows(Filter);
	TurnoverByArrival = 0;
	ConsumptionTurnover = 0;
	For Each Record In GroupingDetails_1 Do
			
		If Record[DebtAmount_] > 0 Then
			TurnoverByArrival = TurnoverByArrival + Record[DebtAmount_];
		Else
			ConsumptionTurnover = ConsumptionTurnover - Record[DebtAmount_];
		EndIf;
		
		If Record[AmountPrepayment] > 0 Then
			ConsumptionTurnover = ConsumptionTurnover + Record[AmountPrepayment];
		Else
			TurnoverByArrival = TurnoverByArrival - Record[AmountPrepayment];
		EndIf;
		
	EndDo;
	
	Group[TurnoverReceipt] = TurnoverByArrival;
	Group[TurnoverExpense] = ConsumptionTurnover;
	Group[ClosingBalance] = Group[OpeningBalance] + Group[TurnoverReceipt] - Group[TurnoverExpense];
	
EndProcedure

// calculates the final Dr balance/in the tabular part of the Cr, the final records of the mutual settlements of the document sparkle2_5_11.
//
// Parameters:
//  FinalRecord - FormDataCollectionItem - the Cur line of the final records of mutual settlements of the document.
//  DetailedRecords - FormDataCollection - A table of detailed records of payments.
//  ReconciliationUnderContracts - Boolean - Total reconciliation mode.
//  TheseAreCounterpartyFields - Boolean - Indicates whether the calculation is based on the Organization (False) or Counterparty (True) fields.
//
Procedure CalculateFinalBalanceOfDrCr(FinalRecord, DetailedRecords, ReconciliationUnderContracts = False, TheseAreCounterpartyFields = False) Export

	FieldName = New Structure;
	If TheseAreCounterpartyFields Then
		FieldName.Insert("OpeningBalanceDr", "OpeningBalanceDrCounterparty");
		FieldName.Insert("OpeningBalanceCr", "OpeningBalanceCrCounterparty");
		FieldName.Insert("DebitAmount", "AmountDebitCounterparty");
		FieldName.Insert("LoanAmount_", "AmountCreditCounterparty");
		FieldName.Insert("TurnoverDr", "TurnoverDrCounterparty");
		FieldName.Insert("TurnoverCr", "TurnoverCrCounterparty");
		FieldName.Insert("ClosingBalanceDr", "ClosingBalanceDrCounterparty");
		FieldName.Insert("ClosingBalanceCr", "ClosingBalanceCrCounterparty");
	Else
		FieldName.Insert("OpeningBalanceDr", "OpeningBalanceDr");
		FieldName.Insert("OpeningBalanceCr", "OpeningBalanceCr");
		FieldName.Insert("DebitAmount", "DebitAmount");
		FieldName.Insert("LoanAmount_", "LoanAmount_");
		FieldName.Insert("TurnoverDr", "TurnoverDr");
		FieldName.Insert("TurnoverCr", "TurnoverCr");
		FieldName.Insert("ClosingBalanceDr", "ClosingBalanceDr");
		FieldName.Insert("ClosingBalanceCr", "ClosingBalanceCr");
	EndIf;
	
	Filter = New Structure("PaymentType_, Partner, Contract");
	If Not ReconciliationUnderContracts Then
		Filter.Insert("ARAPObject");
	EndIf;
	FillPropertyValues(Filter, FinalRecord);

	GroupingDetails_1 = DetailedRecords.FindRows(Filter);
	TurnoverDr = 0;
	TurnoverCr = 0;
	For Each Record In GroupingDetails_1 Do
		TurnoverDr = TurnoverDr + Record[FieldName.DebitAmount];
		TurnoverCr = TurnoverCr + Record[FieldName.LoanAmount_];
	EndDo;
	
	FinalRecord[FieldName.TurnoverDr] = TurnoverDr;
	FinalRecord[FieldName.TurnoverCr] = TurnoverCr;
	
	ClosingBalance = FinalRecord[FieldName.OpeningBalanceDr] - FinalRecord[FieldName.OpeningBalanceCr] + TurnoverDr - TurnoverCr;
	FinalRecord[FieldName.ClosingBalanceDr] = Max(ClosingBalance, 0);
	FinalRecord[FieldName.ClosingBalanceCr] = Max(-ClosingBalance, 0);
	
	If FinalRecord[FieldName.OpeningBalanceDr] <> 0
		And FinalRecord[FieldName.OpeningBalanceCr] <> 0 Then
		FinalRecord[FieldName.ClosingBalanceDr] = FinalRecord[FieldName.OpeningBalanceDr] + TurnoverDr;
		FinalRecord[FieldName.ClosingBalanceCr] = FinalRecord[FieldName.OpeningBalanceCr] + TurnoverCr;
	EndIf;
	
EndProcedure

// Returns a list of types of agreements and contracts with clients.
// 
// Returns:
// 	ValueList - A list of types of contracts with a counterparty, as with a client.
Function TypesOfContractsWithClient() Export
	
	Types = New ValueList;
	Types.Add(PredefinedValue("Enum.ContractTypes.WithCustomer"));
	Types.Add(PredefinedValue("Enum.ContractTypes.WithConsignee"));
	Types.Add(PredefinedValue("Enum.ContractTypes.TransferToCustody"));
	Types.Add(PredefinedValue("Enum.ContractTypes.ReceiptForTolling2_5"));
	Types.Add(PredefinedValue("Enum.ContractTypes.CustomerInvoiceOutsourcedSale"));
	Types.Add(PredefinedValue("Enum.ContractTypes.TransferToRental"));
	Types.Add(PredefinedValue("Enum.ContractTypes.Sublease"));
	Return Types;
EndFunction

// Returns a list of contract types and contracts with suppliers.
// 
// Returns:
// 	ValueList - A list of types of contracts with a counterparty, as with a supplier.
Function TypesOfContractsWithSupplier() Export
	
	Types = New ValueList;
	Types.Add(PredefinedValue("Enum.ContractTypes.WithVendor"));
	Types.Add(PredefinedValue("Enum.ContractTypes.Import"));
	Types.Add(PredefinedValue("Enum.ContractTypes.TransferToTolling2_5"));
	Types.Add(PredefinedValue("Enum.ContractTypes.SubcontractingToTheEAEUCountries"));
	Types.Add(PredefinedValue("Enum.ContractTypes.ReceivingForCustody"));
	Types.Add(PredefinedValue("Enum.ContractTypes.WithConsignor"));
	Types.Add(PredefinedValue("Enum.ContractTypes.PurchaseEAEU"));
	
	Return Types;
EndFunction

// Constructor of the selection structure for retrieving selection data
// 
// Returns:
//  Structure - Selection Data Selection Structure:
//   * PaymentType_ - EnumRef.PartnersARAPAccountingTypes
//   * Organization - CatalogRef.Companies
//   * Counterparty - CatalogRef.Counterparties
//   * Partner - CatalogRef.Partners
//   * SelectAccountsReceivable - Boolean
//   * RecordBranches - Boolean
//   * EditableDocument - Undefined
//   * Text - String, Array of String - The number to be entered in the selection field for the search. Array of IP numbers from client-bank.
//   * TypesOfBases_ - Array of Type
//   * OBEntry - Boolean
//   * BusinessTransactionOfEnteringBalances - EnumRef.BusinessTransactions
//   * ChoosingAdvancePayment - Boolean
Function SelectionDataSelectionStructure() Export
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("PaymentType_",                    PredefinedValue("Enum.PartnersARAPAccountingTypes.EmptyRef"));
	FilterStructure1.Insert("Organization",                    PredefinedValue("Catalog.Companies.EmptyRef"));
	FilterStructure1.Insert("Counterparty",                     PredefinedValue("Catalog.Counterparties.EmptyRef"));
	FilterStructure1.Insert("Partner",                        PredefinedValue("Catalog.Partners.EmptyRef"));
	FilterStructure1.Insert("SelectAccountsReceivable", False);
	FilterStructure1.Insert("RecordBranches",               False);
	FilterStructure1.Insert("EditableDocument",          Undefined);
	FilterStructure1.Insert("Text",                          "");
	FilterStructure1.Insert("TypesOfBases_",                  New Array);
	FilterStructure1.Insert("OBEntry",                   False);
	FilterStructure1.Insert("BusinessTransactionOfEnteringBalances", PredefinedValue("Enum.BusinessTransactions.EmptyRef"));
	FilterStructure1.Insert("ChoosingAdvancePayment",                    False);
	
	Return FilterStructure1;
	
EndFunction

// Initializes the calculation state structure.
//
// Parameters:
//  WithClient - Boolean - 
//
// Returns:
//	Structure - structure with fields:
//	 * State - EnumRef.SalesOrderStates -
//	 * StateOverdue - Boolean -
//	 * PayAmount - Number -
//	 * AmountByShipment - Number -
//	 * PayPercentage - Number -
//	 * OrderShipmentPercentage - Number -
//	 * AmountOfDebt - Number -
//	 * DebtPercentage - Number -
//	 * AmountToPay - Number -
//
Function StructureOfStateOfCalculations(WithClient) Export
	
	StructureOfStateOfCalculations = New Structure();
	
	StructureOfStateOfCalculations.Insert(
		"State",
		?(WithClient,
			PredefinedValue("Enum.SalesOrderStates.EmptyRef"),
			PredefinedValue("Enum.PurchaseOrderStates.EmptyRef")));
		
	StructureOfStateOfCalculations.Insert("StateOverdue", False);
	StructureOfStateOfCalculations.Insert("PayAmount", 0);
	StructureOfStateOfCalculations.Insert("PayPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
	StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountOfDebt", 0);
	StructureOfStateOfCalculations.Insert("DebtPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountToPay", 0);
	Return StructureOfStateOfCalculations;
	
EndFunction

#Region ARAPReconciliation2_5_11

// Procedure - Calculate the Attributes of the form for the final entries
//  Performs line-by-line calculation of the Attributes values of the form of the transmitted table.
// Parameters:
//  FormTable	 - FormDataCollection - It can take the values of an object.Totals of the record or Object.Detailed recordings.
//  ThereAreDiscrepancies - Boolean - Custom flag for displaying discrepancies from the document header.
//															If disabled, all rows are considered matched without discrepancies.
//  CurrentRow	 - FormDataCollectionItem - A row in the form table. If omitted, the calculation is performed for all rows.
//
Procedure CalculateAttributesOfFinalRecordsForm(FormTable, ThereAreDiscrepancies, CurrentRow = Undefined) Export

	If CurrentRow = Undefined Then
		RowsArray = FormTable.FindRows(New Structure());
	Else
		RowsArray = New Array;
		RowsArray.Add(CurrentRow);
	EndIf;

	For Each LineOfATabularSection In RowsArray Do
		
		LineOfATabularSection.ThereIsOrganizationData = LineOfATabularSection.OpeningBalanceDr <> 0
			Or LineOfATabularSection.OpeningBalanceCr <> 0
			Or LineOfATabularSection.TurnoverDr <> 0
			Or LineOfATabularSection.TurnoverCr <> 0
			Or LineOfATabularSection.ClosingBalanceDr <> 0
			Or LineOfATabularSection.ClosingBalanceCr <> 0
			Or LineOfATabularSection.ContractNumber <> ""
			Or ValueIsFilled(LineOfATabularSection.ContractDate_)
			Or LineOfATabularSection.ContractName <> "";
		
		LineOfATabularSection.ThereIsDataOfCounterparty = LineOfATabularSection.OpeningBalanceDrCounterparty <> 0
			Or LineOfATabularSection.OpeningBalanceCrCounterparty <> 0
			Or LineOfATabularSection.TurnoverDrCounterparty <> 0
			Or LineOfATabularSection.TurnoverCrCounterparty <> 0
			Or LineOfATabularSection.ClosingBalanceDrCounterparty <> 0
			Or LineOfATabularSection.ClosingBalanceCrCounterparty <> 0
			Or LineOfATabularSection.ContractNumberCounterparty <> ""
			Or ValueIsFilled(LineOfATabularSection.ContractDateCounterparty)
			Or LineOfATabularSection.ContractNameCounterparty <> "";
		
		If Not ThereAreDiscrepancies Then
			LineOfATabularSection.TypeOfDiscrepancies = 0;	// Mapped1
		ElsIf LineOfATabularSection.ThereIsOrganizationData And Not LineOfATabularSection.ThereIsDataOfCounterparty
			Or Not LineOfATabularSection.ThereIsOrganizationData And LineOfATabularSection.ThereIsDataOfCounterparty Then
			LineOfATabularSection.TypeOfDiscrepancies = 1;	// Not matched
			
		ElsIf LineOfATabularSection.ContractNumber <> LineOfATabularSection.ContractNumberCounterparty
			Or LineOfATabularSection.ContractDate_ <> LineOfATabularSection.ContractDateCounterparty
			Or LineOfATabularSection.OpeningBalanceDr <> LineOfATabularSection.OpeningBalanceDrCounterparty
			Or LineOfATabularSection.OpeningBalanceCr <> LineOfATabularSection.OpeningBalanceCrCounterparty
			Or LineOfATabularSection.TurnoverDr <> LineOfATabularSection.TurnoverDrCounterparty
			Or LineOfATabularSection.TurnoverCr <> LineOfATabularSection.TurnoverCrCounterparty
			Or LineOfATabularSection.ClosingBalanceDr <> LineOfATabularSection.ClosingBalanceDrCounterparty
			Or LineOfATabularSection.ClosingBalanceCr <> LineOfATabularSection.ClosingBalanceCrCounterparty Then
			LineOfATabularSection.TypeOfDiscrepancies = 2;	// There are discrepancies
		Else
			LineOfATabularSection.TypeOfDiscrepancies = 0;	// Mapped1
		EndIf;

		If LineOfATabularSection.TypeOfDiscrepancies > 0 Then
			LineOfATabularSection.NumberOfDiscrepancies = 1;
		Else
			LineOfATabularSection.NumberOfDiscrepancies = 0;
		EndIf;
	
	EndDo;

EndProcedure

// Procedure - Calculate the Attributes of the form for detailed records
//  Performs line-by-line calculation of the Attributes values of the form of the transmitted table.
// Parameters:
//  FormTable	 - FormDataCollection - It can take the values of an object.Totals of the record or Object.Detailed recordings.
//  ThereAreDiscrepancies - Boolean - Custom flag for displaying discrepancies from the document header.
//															If disabled, all rows are considered matched without discrepancies.
//  CurrentRow	 - FormDataCollectionItem - A row in the form table. If omitted, the calculation is performed for all rows.
//
Procedure CalculateAttributesOfDetailedRecordsForm(FormTable, ThereAreDiscrepancies, CurrentRow = Undefined) Export

	If CurrentRow = Undefined Then
		RowsArray = FormTable.FindRows(New Structure());
	Else
		RowsArray = New Array;
		RowsArray.Add(CurrentRow);
	EndIf;

	For Each LineOfATabularSection In RowsArray Do
		
		LineOfATabularSection.ThereIsOrganizationData = LineOfATabularSection.DebitAmount <> 0
			Or LineOfATabularSection.LoanAmount_ <> 0
			Or LineOfATabularSection.DocumentNumber <> ""
			Or ValueIsFilled(LineOfATabularSection.DocumentDate)
			Or LineOfATabularSection.DocumentName3 <> "";
		
		LineOfATabularSection.ThereIsDataOfCounterparty = LineOfATabularSection.AmountDebitCounterparty <> 0
			Or LineOfATabularSection.AmountCreditCounterparty <> 0
			Or LineOfATabularSection.IncomingNumberCounterparty <> ""
			Or ValueIsFilled(LineOfATabularSection.DocumentDateCounterparty)
			Or LineOfATabularSection.DocumentNameCounterparty <> "";
		
		If Not ThereAreDiscrepancies Then
			LineOfATabularSection.TypeOfDiscrepancies = 0;	// Mapped1
		ElsIf LineOfATabularSection.ThereIsOrganizationData And Not LineOfATabularSection.ThereIsDataOfCounterparty
			Or Not LineOfATabularSection.ThereIsOrganizationData And LineOfATabularSection.ThereIsDataOfCounterparty
			Or LineOfATabularSection.DocumentNumber <> LineOfATabularSection.IncomingNumberCounterparty
			Or LineOfATabularSection.DocumentDate <> LineOfATabularSection.DocumentDateCounterparty Then
			LineOfATabularSection.TypeOfDiscrepancies = 1;	// Not matched
			
		ElsIf LineOfATabularSection.DebitAmount <> LineOfATabularSection.AmountDebitCounterparty
			Or LineOfATabularSection.LoanAmount_ <> LineOfATabularSection.AmountCreditCounterparty Then
			LineOfATabularSection.TypeOfDiscrepancies = 2;	// There are discrepancies
		Else
			LineOfATabularSection.TypeOfDiscrepancies = 0;	// Mapped1
		EndIf;

		If LineOfATabularSection.TypeOfDiscrepancies > 0 Then
			LineOfATabularSection.NumberOfDiscrepancies = 1;
		Else
			LineOfATabularSection.NumberOfDiscrepancies = 0;
		EndIf;

		LineOfATabularSection.IsTurnoverDr = LineOfATabularSection.DebitAmount Or LineOfATabularSection.AmountDebitCounterparty;
		LineOfATabularSection.IsTurnoverCr = LineOfATabularSection.LoanAmount_ Or LineOfATabularSection.AmountCreditCounterparty;
	
	EndDo;

EndProcedure

// Function - There are discrepancies
//  returns the document reconciliation State.
// Parameters:
//  Object - DocumentObject.ARAPReconciliation2_5_11, FormDataStructure - The object being transferred.
//  CountingNumberOfDiscrepancies - Boolean - a sign of the need for accurate calculation of the number of discrepancies.
// 
// Returns:
//  Structure - Description of the presence of discrepancies. Contains properties:
//   * ThereAreDiscrepancies - Boolean - Flag for discrepancies in the document;
//   * ThereAreDiscrepanciesInResults - Boolean - Flag for discrepancies in the final records;
//   * NumberOfDetailDiscrepancies - Number - The number of discrepancies in the detailed records.
//
Function ThereAreDiscrepancies(Object, CountingNumberOfDiscrepancies = False) Export
	
	NumberOfDetailDiscrepancies = 0;
	ThereAreDiscrepanciesInResults = False;

	If TypeOf(Object) = Type("FormDataStructure") Then	// calling from the form, it is possible to use the Attributes of the form
		ThereAreDiscrepanciesInResults = Object.SummaryRecords.Total("NumberOfDiscrepancies") > 0;
		If CountingNumberOfDiscrepancies Then
			NumberOfDetailDiscrepancies = Object.DetailedRecords.Total("NumberOfDiscrepancies");
		EndIf;
	Else	// Calling from an object, a line-by-line calculation is required
		ThereAreDiscrepanciesInResults = False;
		For Each String In Object.SummaryRecords Do
			If String.OpeningBalanceDr <> String.OpeningBalanceDrCounterparty
				Or String.OpeningBalanceCr <> String.OpeningBalanceCrCounterparty
				Or String.TurnoverDr <> String.TurnoverDrCounterparty
				Or String.TurnoverCr <> String.TurnoverCrCounterparty   
				Or String.ClosingBalanceDr <> String.ClosingBalanceDrCounterparty
				Or String.ClosingBalanceCr <> String.ClosingBalanceCrCounterparty Then
				ThereAreDiscrepanciesInResults = True;
				Break;
			EndIf;
		EndDo;

		For Each String In Object.DetailedRecords Do
			If String.DocumentNumber <> String.IncomingNumberCounterparty
				Or String.DocumentDate <> String.DocumentDateCounterparty
				Or String.DebitAmount <> String.AmountDebitCounterparty   
				Or String.LoanAmount_ <> String.AmountCreditCounterparty Then
				NumberOfDetailDiscrepancies = NumberOfDetailDiscrepancies + 1;
				If Not CountingNumberOfDiscrepancies Then
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndIf;

	ThereAreDiscrepancies = ThereAreDiscrepanciesInResults Or NumberOfDetailDiscrepancies > 0;
	Result = New Structure("ThereAreDiscrepancies, ThereAreDiscrepanciesInResults, NumberOfDetailDiscrepancies",
		ThereAreDiscrepancies, ThereAreDiscrepanciesInResults, NumberOfDetailDiscrepancies);

	Return Result;

EndFunction

// updates the State of the reconciliation in the form of a document
// 
// Parameters:
//  Form - ClientApplicationForm - the form where we update the reconciliation State
Procedure UpdateReconciliationStateInForm(Form) Export

	If Form.Object.ThereAreDiscrepancies = False Then
		Form.ReconciliationState = NStr("vi = 'Không có sự khác biệt';
										|ru = 'Нет расхождений';
										|en = 'No discrepancies'; fa = 'No discrepancies';
										|it = 'Nessuna discrepanza';
										|pl = 'Brak odchylenia';
										|tr = 'Tutarsızlık yok'");
		Return;
	EndIf;

	Result = ThereAreDiscrepancies(Form.Object, True);
	If Result.ThereAreDiscrepancies = False Then
		Form.ReconciliationState = NStr("vi = 'Không có sự khác biệt';
										|ru = 'Нет расхождений';
										|en = 'No discrepancies'; fa = 'No discrepancies';
										|it = 'Nessuna discrepanza';
										|pl = 'Brak odchylenia';
										|tr = 'Tutarsızlık yok'");
		Return;
	EndIf;

	If Result.ThereAreDiscrepanciesInResults Then
		Form.ReconciliationState = NStr("vi = 'Có chênh lệch';
										|ru = 'Есть расхождения';
										|en = 'There are discrepancies'; fa = 'مغایرت وجود دارد';
										|it = 'Ci sono discrepanze';
										|pl = 'Istnieje odchylenie';
										|tr = 'Tutarsızlıklar var'");
	Else
		Template = NStr("vi = 'Có chênh lệch trong bản ghi chi tiết (%1 trong %2)';
						|ru = 'Есть расхождения в детальных записях (%1 из %2)';
						|en = 'There are discrepancies in the detailed records (%1 out of %2)'; fa = 'There are discrepancies in the detailed records (%1 out of %2)';
						|it = 'Есть расхождения в детальных записях (%1 из %2)';
						|pl = 'There are discrepancies in the detailed records (%1 out of %2)';
						|tr = 'Detaylı kayıtlarda tutarsızlıklar mevcut (%2''dan %1)'");
		Form.ReconciliationState = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			Result.NumberOfDetailDiscrepancies,
			Form.Object.DetailedRecords.Count());
	EndIf;

EndProcedure

// procedure - update the object reconciliation State
//   updates the reconciliation State in the object Attributes.
// Parameters:
//  Object - DocumentObject.ARAPReconciliation2_5_11 - Target document
//
Procedure UpdateObjectReconciliationState(Object) Export

	If Object.ThereAreDiscrepancies = False Then
		Object.State = NStr("vi = 'Không có sự khác biệt';
							|ru = 'Нет расхождений';
							|en = 'No discrepancies'; fa = 'No discrepancies';
							|it = 'Nessuna discrepanza';
							|pl = 'Brak odchylenia';
							|tr = 'Tutarsızlık yok'");
		Return;
	EndIf;

	Result = ThereAreDiscrepancies(Object, False);
	If Result.ThereAreDiscrepancies = False Then
		Object.State = NStr("vi = 'Không có sự khác biệt';
							|ru = 'Нет расхождений';
							|en = 'No discrepancies'; fa = 'No discrepancies';
							|it = 'Nessuna discrepanza';
							|pl = 'Brak odchylenia';
							|tr = 'Tutarsızlık yok'");
		Return;
	EndIf;

	If Result.ThereAreDiscrepanciesInResults Then
		Object.State = NStr("vi = 'Có chênh lệch';
							|ru = 'Есть расхождения';
							|en = 'There are discrepancies'; fa = 'مغایرت وجود دارد';
							|it = 'Ci sono discrepanze';
							|pl = 'Istnieje odchylenie';
							|tr = 'Tutarsızlıklar var'");
	Else
		Object.State = NStr("vi = 'Có chênh lệch trong các bản ghi chi tiết';
							|ru = 'Есть расхождения в детальных записях';
							|en = 'There are discrepancies in the detailed records'; fa = 'There are discrepancies in the detailed records';
							|it = 'Есть расхождения в детальных записях';
							|pl = 'There are discrepancies in the detailed records';
							|tr = 'Detaylı kayıtlarda tutarsızlıklar mevcut'");
	EndIf;

EndProcedure

// Function - There are disparate detailed entries
//  Returns an indication of the presence of non-matched rows in the table part
// Parameters:
//  TabularSection - FormDataCollection - 
// 
// Returns:
//  Boolean - 
//
Function ThereAreUnmappedRecords(TabularSection) Export

	For Each LineOfATabularSection In TabularSection Do
		If LineOfATabularSection.TypeOfDiscrepancies = 1 Then	// An unmapped string
			Return True;
		EndIf;
	EndDo;

	Return False;

EndFunction

#EndRegion

#Region Modularity

// Service procedure that fills in the hyperlink text of the payment rules 
// 
// Parameters:
//	Form       - ClientApplicationForm - Agreement specified in the document:
//	 * Items - FormItems - elements of the calling form
//	ParametersStructure - See ARAPAccountingServer.MechanismParameters
//	SystemSettings_  - Structure - System settings from advanced settings, if already received.
//
// Returns:
//  String - Formatted string of payment stages
Function FormattedStringOfPaymentStages(Form, ParametersStructure, SystemSettings_) Export
	
	PaymentMethod               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentMethod);
	PaymentSchedule              = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentSchedule);
	ARAPObjectSettings           = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
	PaymentSteps               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps);
	PaymentDate               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentDate);
	AmountToPay              = AmountToPay(Form, ParametersStructure);
	ExecutionScheduleIsSpecified     = ParametersStructure.ExecutionScheduleIsSpecified;
	ThisIsOrder                  = ParametersStructure.ThisIsOrder;
	UsePaymentSchedules = SystemSettings_.UsePaymentSchedules;
	
	ThereAreStagesOfPayment = PaymentSteps <> Undefined;
	
	If PaymentSteps <> Undefined Then
		NumberOfPaymentStages    = PaymentSteps.Count();
	Else
		NumberOfPaymentStages    = ?(ValueIsFilled(PaymentDate), 1, 0);
	EndIf;
	
	
	RowsArray = New Array;
	
	If ThisIsOrder And ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments") Then
		
		RowsArray.Add(NStr("vi = 'Theo khoản thanh toán và hóa đơn';
							|ru = 'По платежам и накладным';
							|en = 'For payments and invoices'; fa = 'For payments and invoices';
							|it = 'Per pagamenti e fatture';
							|pl = 'Wg płatności i faktury';
							|tr = 'Ödeme ve irsaliyelere göre'"));
		
	ElsIf ExecutionScheduleIsSpecified And ThisIsOrder
		And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") 
			Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"))Then
		
		RowsArray.Add(NStr("vi = 'Theo lịch biểu hợp đồng';
							|ru = 'По графику договора';
							|en = 'By contract schedule'; fa = 'By contract schedule';
							|it = 'In base al grafico del contratto';
							|pl = 'Zgodnie z harmonogramem umowy';
							|tr = 'Sözleşme programına göre'"));
		
	Else
		
		If AmountToPay <= 0 And NumberOfPaymentStages = 0 
			Or Not ParametersStructure.ChangesPaymentPlan And Not ParametersStructure.OrderAsAProformaInvoice 
			Or AmountToPay <= 0 And (ParametersStructure.ThisIsSalePurchase Or ParametersStructure.ThisIsOrder) Then
			
			RowsArray.Add(NStr("vi = 'Không cần thanh toán';
								|ru = 'Оплата не требуется';
								|en = 'Payments: not configured'; fa = 'Payments: not configured';
								|it = 'Pagamento non richiesto';
								|pl = 'Płatność nie jest wymagana';
								|tr = 'Ödeme gerekmiyor'"));
			
		Else
			
			RowsArray.Add(PresentationOfPaymentForm(PaymentMethod));
			If NumberOfPaymentStages = 0 Then
				
				ErrorText = ?(ThereAreStagesOfPayment, NStr("vi = 'chưa chỉ ra các giai đoạn';
															|ru = 'этапы не указаны';
															|en = 'milestones are not set'; fa = 'milestones are not set';
															|it = 'Fasi non indicate';
															|pl = 'etapy nie są wskazane';
															|tr = 'aşamalar belirtilmedi'"), NStr("vi = 'chưa chỉ ra ngày thanh toán';
																									|ru = 'не указана дата платежа';
																									|en = 'payment date is not specified'; fa = 'payment date is not specified';
																									|it = 'Data pagamento non indicata';
																									|pl = 'data płatności nie została określona';
																									|tr = 'ödeme tarihi belirtilmedi'"));
				
				RowsArray.Add(", ");
				RowsArray.Add("<span style=""color: OverdueDocument"">" + ErrorText +"</span>");
				
			ElsIf Not ThereAreStagesOfPayment Then
				
				RowsArray.Add(" ");
				RowsArray.Add(Format(PaymentDate, "DLF=D"));
				
			ElsIf NumberOfPaymentStages <= 2 Then
				
				RowsArray.Add(" ");
				For Cnt=1 To NumberOfPaymentStages Do
					PaymentLine_ = PaymentSteps[Cnt-1];
					If ValueIsFilled(PaymentLine_.PaymentDate) And PaymentLine_.PaymentPercentage > 0 Then
						RowsArray.Add("<span style=""color: HyperlinkColor"">" + Format(PaymentLine_.PaymentDate, "DLF=D") +"</span>");
						RowsArray.Add(" (" + Format(PaymentLine_.PaymentPercentage, "ND=3; NFD=; NZ=0") + "%)");
						If Cnt < NumberOfPaymentStages Then
							RowsArray.Add(", ");
						EndIf;
					EndIf;
				EndDo;
				
			ElsIf UsePaymentSchedules And ValueIsFilled(PaymentSchedule)  And Not ExecutionScheduleIsSpecified Then
				
				RowsArray.Add(" ");
				RowsArray.Add(NStr("vi = 'theo lịch biểu';
									|ru = 'по графику';
									|en = 'on schedule'; fa = 'on schedule';
									|it = 'secondo il grafico';
									|pl = 'wg harmonogramu';
									|tr = 'programa göre'") + " """ + String(PaymentSchedule) + """");
				
			Else
				
				StageText = TMCommonUseClientServer.DeclensionOfWord(
					NumberOfPaymentStages,
					NStr("vi = 'giai đoạn, giai đoạn, giai đoạn, m';
						|ru = 'этапы, этапа, этапов, м';
						|en = 'stage, stages'; fa = 'stage, stages';
						|it = 'этапы, этапа, этапов, м';
						|pl = 'stage, stages';
						|tr = 'aşama, aşama, aşamalar, m'"));
					
				RowsArray.Add(" ");
				RowsArray.Add(NStr("vi = 'trong';
									|ru = 'в';
									|en = 'in'; fa = 'در';
									|it = 'il';
									|pl = 'in';
									|tr = 'içinde'") +" " + Format(NumberOfPaymentStages, "NZ=0") +" " + StageText);
				
			EndIf;
		EndIf;
		
	EndIf;
	
	Return StrConcat(RowsArray);
	
EndFunction

// Forms the caption of the currency Caption element
// 
// Parameters:
//	Form       - ClientApplicationForm - Agreement specified in the document:
//	 * Items - FormItems - elements of the calling form
//	ParametersStructure - See ARAPAccountingServer.MechanismParameters
//
Procedure UpdateHyperlinkText(Form, ParametersStructure = Undefined) Export
	
	If ParametersStructure <> Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(ParametersStructure);
	Else
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray; // Array of See ARAPAccountingServer.MechanismParameters
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
	
		If Not ValueIsFilled(ParametersStructure.CourseNumerator)
			Or Not ValueIsFilled(ParametersStructure.FormItems.LabelCurrencies) Then
			Continue;
		EndIf;
		
		DocumentCurrency          = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency);
		ARAPCurrency     = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency);
		CourseNumerator            = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CourseNumerator);
		CourseDenominator          = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CourseDenominator);
		Organization              = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
		DocumentExchangeRateDate = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentExchangeRateDate);
		
		DonTShowCalculations  = ParametersStructure.DonTShowCalculations;
		
		LocalAccountingCurrency = SettingsValueClientServerCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		
		CurrencyCaptionElement = Form.Items[ParametersStructure.FormItems.LabelCurrencies]; // FormField
		
		If ValueIsFilled(ParametersStructure.DocumentAmountForm) And DocumentCurrency = ARAPCurrency Then
			DocumentAmount = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmountForm, , 0);
			AmountARAP = DocumentAmount;
		ElsIf ValueIsFilled(ParametersStructure.PathToTSData) And ValueIsFilled(ParametersStructure.PropsNameTSAmountWithVAT) Then
			TS = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSData);
			DocumentAmount = TS.Total(ParametersStructure.PropsNameTSAmountWithVAT);
			If TS.Count() > 0 And CommonClientServer.HasAttributeOrObjectProperty(TS[0],"AmountARAP") Then
				AmountARAP = TS.Total("AmountARAP");
			Else
				AmountARAP = 0;
			EndIf;
		Else
			AmountARAP  = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.AmountARAP);
			DocumentAmount       = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmount);
		EndIf;
		
		If DocumentAmount = 0 Then
			TextAmountOfDocument = "";
		Else
			TextAmountOfDocument = " " + Format(DocumentAmount, "NFD=2");
		EndIf;
		
		If DocumentCurrency = ARAPCurrency Or DonTShowCalculations Then
			
			LabelCurrencies = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chứng từ và tính toán:%1 %2';
						|ru = 'Документ и расчеты:%1 %2';
						|en = 'Document and AR/AP accounting:%1 %2'; fa = 'Document and AR/AP accounting:%1 %2';
						|it = 'Documento e calcoli:%1 %2';
						|pl = 'Dokument i rozliczenia:%1 %2';
						|tr = 'Belgeler ve hesaplaşmalar:%1 %2'"),
					TextAmountOfDocument,
					DocumentCurrency);
			
			If ValueIsFilled(DocumentExchangeRateDate) Then
				LabelCurrencies = LabelCurrencies + " " + NStr("vi = 'theo tỷ giá tại ngày:';
																|ru = 'по курсу на дату:';
																|en = 'by rate as of the date:'; fa = 'by rate as of the date:';
																|it = 'in base al tasso di cambio alla data:';
																|pl = 'według kursu na datę:';
																|tr = 'tarihe döviz kuruna göre:'") + " " + Format(DocumentExchangeRateDate, "DLF=D")
			EndIf;
			
		Else
			
			TextDocument_ = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chứng từ%1 %2';
						|ru = 'Документ%1 %2';
						|en = 'Document %1 %2'; fa = 'Document %1 %2';
						|it = 'Documento%1 %2';
						|pl = 'Dokument%1 %2';
						|tr = 'Belge%1 %2'"),
					TextAmountOfDocument,
					DocumentCurrency);
			
			If ValueIsFilled(DocumentExchangeRateDate) Then
				TextDocument_ = TextDocument_ + " " + NStr("vi = 'theo tỷ giá tại ngày:';
															|ru = 'по курсу на дату:';
															|en = 'by rate as of the date:'; fa = 'by rate as of the date:';
															|it = 'in base al tasso di cambio alla data:';
															|pl = 'według kursu na datę:';
															|tr = 'tarihe döviz kuruna göre:'") + " " + Format(DocumentExchangeRateDate, "DLF=D");
				If DocumentCurrency = LocalAccountingCurrency Then
					TextDocument_ = TextDocument_ + NStr("vi = '(đối với kế toán quản trị)';
														|ru = '(для упр. учета)';
														|en = '(for management accounting)'; fa = '(for management accounting)';
														|it = '(per contabilità gest.)';
														|pl = '(dla ewidencji zarz.)';
														|tr = '(yönetim muhasebesi için)'");
				EndIf;
			EndIf;
			
			If AmountARAP = 0 Then
				TextAmountOfSettlements = "";
			Else
				TextAmountOfSettlements = " " + Format(AmountARAP, "NFD=2");
			EndIf;
			
			If ValueIsFilled(ARAPCurrency) Then
				TextCurrencyOfSettlements = ARAPCurrency;
			Else
				TextCurrencyOfSettlements = NStr("vi = '<Không được chọn>';
												|ru = '<Не выбрана>';
												|en = '<Not selected>'; fa = '<Not selected>';
												|it = '<non selezionato>';
												|pl = '<nie wybrano>';
												|tr = '<Seçilmedi>'")
			EndIf;
			
			TextCalculations = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = ', Tính toán %1 %2';
						|ru = ', Расчеты%1 %2';
						|en = ', AR/AP accounting%1 %2'; fa = ', AR/AP accounting%1 %2';
						|it = ', calcoli %1%2';
						|pl = ', Rozliczenia%1 %2';
						|tr = ', Hesaplaşmalar%1 %2'"),
					TextAmountOfSettlements,
					TextCurrencyOfSettlements);
			
			If Not ValueIsFilled(ARAPCurrency) Then
				
				TextDecryption = "";
				
			ElsIf DocumentCurrency = LocalAccountingCurrency
				Or ARAPCurrency = LocalAccountingCurrency Then
				
				CurrencyOfInscription = ?(LocalAccountingCurrency = DocumentCurrency,
								ARAPCurrency,
								DocumentCurrency);
				
				If CourseDenominator = 1 Then
					
						TextDecryption = StringFunctionsClientServer.SubstituteParametersToString(
							"(%1=%2 %3)",
							CurrencyOfInscription,
							CourseNumerator,
							LocalAccountingCurrency);
					
					Else
						
						TextDecryption = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = '( %1 %2 cho %3%4)';
								|ru = '(%1 %2 за %3 %4)';
								|en = '(%1 %2 for %3 %4)'; fa = '(%1 %2 for %3 %4)';
								|it = '(%1 %2 per %3 %4)';
								|pl = '(%1 %2 za %3 %4)';
								|tr = '(%3 %4 için %1 %2)'"),
							CourseNumerator,
							LocalAccountingCurrency,
							CourseDenominator,
							CurrencyOfInscription);
						
				EndIf;
				
			Else
				
				If CourseDenominator = 1 Then
					
					TextDecryption = StringFunctionsClientServer.SubstituteParametersToString(
						"(%1=%2 %3)",
						DocumentCurrency,
						CourseNumerator,
						ARAPCurrency);
				Else
					
					TextCourse = String(CourseNumerator) + " " + ARAPCurrency;
					
					TextMultiplicity= String(CourseDenominator);
					
					TextDecryption = StringFunctionsClientServer.SubstituteParametersToString(
						"(%1=%2 %3)",
						TextCourse,
						TextMultiplicity,
						DocumentCurrency);
						
				EndIf;
				
			EndIf;
			
			LabelCurrencies = TextDocument_ + TextCalculations + " " + TextDecryption;
			
		EndIf;
		
		CurrencyCaptionElement.Title = LabelCurrencies;
	EndDo;
	
EndProcedure

// Sets the visibility of the payment offset button according to the order of calculation of the document, if there is one on the form.
//
// Parameters:
//	Form - ClientApplicationForm - The form where the payment offset command is located.
//	ParametersStructure - See ARAPAccountingServer.MechanismParameters
//
Procedure SetVisibilityOfPaymentOffset(Form, ParametersStructure) Export
	
	If Not ValueIsFilled(ParametersStructure.FormItems.PaymentSettlement) Then
		Return;
	EndIf;
	
	CheckRequiredParameters(ParametersStructure, "ARAPObjectSettings");
	
	PaymentOffsetIsAvailable = ParametersStructure.ChangesCalculations;
	ARAPObjectSettings = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
	
	If ParametersStructure.ThisIsOrder Then
		ItemVisibility = ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
							And ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")
							And PaymentOffsetIsAvailable;
	ElsIf TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders,,False) Then
		ItemVisibility = ARAPObjectSettings <> PredefinedValue("Enum.ARAPObjectSettings.ByOrders") And PaymentOffsetIsAvailable;
	ElsIf ParametersStructure.IsCatalog Then
		ItemVisibility = (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
							Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")) And PaymentOffsetIsAvailable;
	Else
		ItemVisibility = PaymentOffsetIsAvailable;
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items, 
		ParametersStructure.FormItems.PaymentSettlement,
		"Visible",
		ItemVisibility);
	
EndProcedure


#EndRegion

#EndRegion

#Region Private

Procedure AddTurnover(Turnovers, Record, ResourceName)
	
	ResourceValue = Record[ResourceName];
	If ResourceValue > 0 Then
		Turnovers.Dr = Turnovers.Dr + ResourceValue;
	Else
		Turnovers.Cr = Turnovers.Cr + (-ResourceValue);
	EndIf;
	
EndProcedure

//Checks whether the passed parameters are full in the structure, and throws an exception if they are empty.
Procedure CheckRequiredParameters(ParametersStructure, RequiredParameters2) Export
	
	Attributes = StrSplit(RequiredParameters2, ",");
	For Each Attribute In Attributes Do
		If Not ParametersStructure.Property(TrimAll(Attribute)) 
			Or Not ValueIsFilled(ParametersStructure[TrimAll(Attribute)]) Then
				Raise(StringFunctionsClientServer.SubstituteParametersToString(
										NStr("vi = 'Thiếu tham số bắt buộc của cơ chế ""Hạch toán"":%1';
											|ru = 'Не заполнен обязательный параметр механизма ""Взаиморасчеты"":%1';
											|en = 'Parameter of the ""AR/AP accounting"" mechanism is required: %1'; fa = 'Parameter of the ""AR/AP accounting"" mechanism is required: %1';
											|it = 'Non è compilato il parametro obbligatorio del meccanismo ""Regolamenti reciproci"":%1';
											|pl = 'Nie wypełniono obowiązkowego parametru mechanizmu ""Rozliczenia wzajemne"":%1';
											|tr = '""Mutabakatlar"" mekanizmasının gerekli parametresi doldurulmadı:%1'"),
										Attribute));
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//   ParametersArray - See ARAPAccountingServer.AugmentedMechanismParameters
//   ItemsNames - String, Array of String - The name of the form field.
//
// Returns:
//   Array of Structure:
//    * ParametersStructure - See ARAPAccountingServer.MechanismParameters 
//    * UsedFormElements - Array of See ARAPAccountingServer.MechanismParameters 
//
Function ArrayOfParameterStructuresByElement(ParametersArray, ItemsNames) Export
	If TypeOf(ItemsNames) = Type("Array") Then
		Items = ItemsNames;
	Else
		Items = New Array;
		Items.Add(ItemsNames);
	EndIf;
	Result = New Array;
	For Each ParametersStructure In ParametersArray Do
		ArrayOfFoundElements = New Array;
		For Each Item In Items Do
			If ParametersStructure.UsedFormElements.Find(Item) <> Undefined Then
				ArrayOfFoundElements.Add(Item);
			EndIf;
		EndDo;
		If ArrayOfFoundElements.Count() > 0 Then
			ResultStructure1 = New Structure;
			ResultStructure1.Insert("ParametersStructure",       ParametersStructure);
			ResultStructure1.Insert("UsedFormElements", ArrayOfFoundElements);
			Result.Add(ResultStructure1);
		EndIf;
	EndDo;
	Return Result;
EndFunction

// Parameters:
//   ParametersArray - Array of See ARAPAccountingServer.MechanismParameters.
//   TagName - String
//
// Returns:
//   See ARAPAccountingServer.MechanismParameters.
//
Function StructureOfParametersByElementName(ParametersArray, TagName) Export
	
	ArrayOfParameterStructures = ArrayOfParameterStructuresByElement(ParametersArray, TagName);
	
	If ArrayOfParameterStructures.Count() > 1 Then
		Raise(NStr("vi = 'Một phần tử được gắn với một số tham số của cơ chế giải quyết lẫn nhau.';
					|ru = 'Элемент привязан к нескольким параметрам механизма взаиморасчетов.';
					|en = 'Item is linked to several parameters of AR/AP accounting.'; fa = 'Item is linked to several parameters of AR/AP accounting.';
					|it = 'Un elemento è legato a diversi parametri del meccanismo di regolamento reciproco.';
					|pl = 'Element jest przywiązany do kilku parametrów mechanizmu rozliczeń wzajemnych.';
					|tr = 'Öğe, mutabakat mekanizmasının birkaç parametresine bağlıdır.'"));
	ElsIf ArrayOfParameterStructures.Count() = 0 Then
		Raise(NStr("vi = 'Phần tử không được gắn với các tham số của cơ chế giải quyết lẫn nhau.';
					|ru = 'Элемент не привязан к параметрам механизма взаиморасчетов.';
					|en = 'Item is not linked to parameters of AR/AP accounting.'; fa = 'Item is not linked to parameters of AR/AP accounting.';
					|it = 'Un elemento non è legato a diversi parametri del meccanismo di regolamento reciproco.';
					|pl = 'Element nie jest przywiązany do parametrów mechanizmu rozliczeń wzajemnych.';
					|tr = 'Öğe, mutabakat mekanizmasının parametrelerine bağlı değildir.'"));
	Else
		Return ArrayOfParameterStructures[0].ParametersStructure;
	EndIf;
	
EndFunction

// Returns an informative view of the payment form for documents
//
// Parameters:
// 		PaymentMethod - EnumRef.PaymentForms - form of payment. for which you need to get a view.
//
// Returns:
// 		String - presentation of the payment form.
//
Function PresentationOfPaymentForm(PaymentMethod)
	
	Presentation = "";
	
	If Not ValueIsFilled(PaymentMethod) Then
		Presentation = NStr("vi = 'Cần thanh toán';
							|ru = 'К оплате';
							|en = 'Amount due'; fa = 'مبلغ سررسیدشده';
							|it = 'Da pagare';
							|pl = 'Do płatności';
							|tr = 'Ödenecek'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.BankAccountPayment") Then
		Presentation = NStr("vi = 'Cần thanh toán bằng tiền gửi ngân hàng';
							|ru = 'К оплате безнал';
							|en = 'Amount due by bank transfer'; fa = 'Amount due by bank transfer';
							|it = 'In pagamento cashless';
							|pl = 'Płatność bezgotówkowa';
							|tr = 'Gayri nakit ödeme için'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.CashAccountPayment_") Then
		Presentation = NStr("vi = 'Cần thanh toán bằng tiền mặt';
							|ru = 'К оплате нал';
							|en = 'Amount due by cash'; fa = 'Amount due by cash';
							|it = 'In pagamento contanti';
							|pl = 'Płatność gotówkowa';
							|tr = 'Nakit ödeme için'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.PaymentCard") Then
		Presentation = NStr("vi = 'Cần thanh toán bằng thẻ thanh toán';
							|ru = 'К оплате платежной картой';
							|en = 'Amount due by payment card'; fa = 'Amount due by payment card';
							|it = 'In pagamento tramite carta di pagamento';
							|pl = 'Do zapłaty kartą płatniczą';
							|tr = 'Ödeme kartı ile ödeme için'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.SettlementOfARAP") Then
		Presentation = NStr("vi = 'Đối trừ';
							|ru = 'Взаимозачет';
							|en = 'Offsetting'; fa = 'تهاتر';
							|it = 'Compensazione';
							|pl = 'Rozliczenie wzajemne';
							|tr = 'Uzlaşma'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.InstantPayments") Then
		Presentation = NStr("ru = 'К оплате СБП';
							|vi = 'Amount due FPS';
							|en = 'Amount due FPS'; fa = 'Amount due FPS';
							|it = 'Amount due FPS';
							|pl = 'Amount due FPS';
							|tr = 'SBP ödemesine git'");
	EndIf;
	
	Return Presentation;
	
EndFunction

Function IsTabularSection(Table) Export
	Return CommonClientServer.HasAttributeOrObjectProperty(Table, "Columns");
EndFunction

Function AmountToPay(Form, ParametersStructure) Export
	
	If  TypeOf(Form.Object.Ref) = Type("DocumentRef.SaleAdjustment")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.PurchaseAdjustment") Then 
		AmountTotal = TMCommonUseClientServer.DataAlongWay(Form, "Form.TotalAmountShovelcharge");
	ElsIf ValueIsFilled(ParametersStructure.DocumentAmountForm) Then
		AmountTotal = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmountForm);
	ElsIf ValueIsFilled(ParametersStructure.PathToTSData) Then
		TS = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSData);
		AmountTotal = TotalForSumsOfOneCharacter(TS, ParametersStructure.PropsNameTSAmountWithVAT);
	Else
		AmountTotal = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmount);
	EndIf;
	
	Return AmountTotal;
	
EndFunction

Function TotalForSumsOfOneCharacter(Table, ColumnName, Negative_ = False) Export
	
	Total = 0;
	For Each TableRow In Table Do
		If Negative_
				And TableRow[ColumnName] < 0
			Or Not Negative_
				And TableRow[ColumnName] > 0 Then
			Total = Total + TableRow[ColumnName];
		EndIf;
	EndDo;
	
	Return Total;
	
EndFunction

Function ArrayOfShipmentDates(Form, ParametersStructure) Export
	
	If Not ParametersStructure.ThisIsOrder Then
		Return New Array;
	EndIf;
	
	ShippingDates = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DateOfShipment);
	
	If TypeOf(ShippingDates) = Type("Array") Then
		
		TabularSection = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSData);
		IndexOf = TabularSection.Count();
		While IndexOf > 0 Do
			IndexOf = IndexOf - 1;
			If Not ValueIsFilled(ShippingDates[IndexOf])
				Or CommonClientServer.HasAttributeOrObjectProperty(TabularSection[IndexOf], "Canceled")
					And TabularSection[IndexOf].Canceled Then
				ShippingDates.Delete(IndexOf);
			EndIf;
		EndDo;
		ShippingDates = CommonClientServer.CollapseArray(ShippingDates);
		
		Return ShippingDates;
		
	ElsIf ValueIsFilled(ShippingDates) Then
		
		Return CommonClientServer.ValueInArray(ShippingDates);
		
	EndIf;
	
	Return New Array;
	
EndFunction

#EndRegion
