#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the document.
//  - Updates the spending limit.
//  - Fills in the table part of accounts Receivable
//  - Fills in the table part of accounts payable
//  - Counting the reserves.
// 
// Parameters:
// 	AccountsReceivableData - ValueTable - 
// 	InteractiveUpdate - Boolean - flag for calling limit updates from the document form
//
Procedure FillInDocument(AccountsReceivableData, InteractiveUpdate = False) Export
	
	UpdateYourSpendingLimit(False, InteractiveUpdate);
	FillInAccountsReceivable(AccountsReceivableData, False);
	FillInAccountsPayable(, False);
	CalculateReserves();
	
EndProcedure

// Fills in the table part of accounts Receivable.
// 
// Parameters:
//  AccountsReceivableData - ValueTable - contains data for filling in accounts receivable 
// 	CalculateReserves_ - Boolean - if True, reserves are calculated after filling in
// 
Procedure FillInAccountsReceivable(AccountsReceivableData, CalculateReserves_ = True) Export
	
	AccountsReceivable.Load(AccountsReceivableData);
	AccountsReceivable.Sort("DebtKind,Counterparty,Contract,ARAPDocument,DateOfDebtOccurrence");
	
	MARatingTable = AccrualAndWriteOffOfBadDebtAlowancesServer.MARatingTable(Organization, Date);
	EvaluationParameters_ = New Structure("EvaluationTable", MARatingTable);
	TimingEvaluationTable = TimingEvaluationTable(MARatingTable);
	
	LinesToDelete = New Array();
	For Each CurrentRow In AccountsReceivable Do
		CurrentRow.RowID = New UUID;
		CurrentRow.DoubtfulDebtPeriod = Max(0, (BegOfDay(Date) - CurrentRow.DateOfDebtOccurrence) / 86400);
		
		If CurrentRow.ManualAdjustment Then
			Continue;
		EndIf;
		
		If DoNotIncludeInReserveByTerm(CurrentRow.DebtKind, CurrentRow.DoubtfulDebtPeriod, TimingEvaluationTable) Then
			LinesToDelete.Add(CurrentRow);
			Continue;
		EndIf;
		
		CurrentRow.Evaluation = Documents.AccrualAndWriteOffOfBadDebtAlowances.GetEstimate(
			CurrentRow.DebtKind, CurrentRow.DoubtfulDebtPeriod, EvaluationParameters_);
	EndDo;
	
	For Each String In LinesToDelete Do
		AccountsReceivable.Delete(String);
	EndDo;
	
	If CalculateReserves_ Then
		CalculateReserves();
	EndIf;
	
EndProcedure

// Fills the table part of the accounts payable.
// 
// Parameters:
// 	DimensionAccounting_1 - Structure, Undefined - Analytics for which you need to fill out accounts payable
// 		from accounting data. If Undefined, then fill in the entire table.
// 	* Contractor
// 	* Contract
// 	* Settlement Document
// 	CalculateReserves_ - Boolean - if True, reserves are calculated after filling in 
//
Procedure FillInAccountsPayable(DimensionAccounting_1 = Undefined, CalculateReserves_ = True) Export
	
	If Not AccrualAndWriteOffOfBadDebtAlowancesLocalization.TakeIntoAccountTheCounterDebt(Date) Then
		AccountsPayable.Clear();
		Return;
	EndIf;
	
	ProcessEverything = DimensionAccounting_1 = Undefined;
	
	// We receive counter debt only for counterparties from the accounts receivable table.
	ArrayOfCounterparties = TMCommonUse.DeleteDuplicateElementsFromArray(
		AccountsReceivable.Unload(, "Counterparty").UnloadColumn("Counterparty"));
	
	// We receive updated information about the counter debt.
	
	FillParameters = New Structure("Counterparty,Contract,ARAPDocument");
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Ref", Ref);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("ArrayOfCounterparties", ArrayOfCounterparties);
	FillParameters.Insert("ProcessEverything", ProcessEverything);
	
	If Not DimensionAccounting_1 = Undefined Then
		FillPropertyValues(FillParameters, DimensionAccounting_1, "Counterparty,Contract,ARAPDocument");
	EndIf;
	
	QueryResult = Documents.AccrualAndWriteOffOfBadDebtAlowances.GetDataForFillingAccountsPayable(
		FillParameters);
	
	// Processing the received information:
	// 1. If the amount was adjusted manually, then we leave it as it is.
	// 2. If there is already such a counterparty, contract, settlement document, then we update the amount.
	// 3. If there is no such counterparty, contract, settlement document, then add a new line.
	// 4. Otherwise, we delete the counter debt line.
	
	DataAccountsPayable = QueryResult.Unload();
	DataAccountsPayable.Indexes.Add("Counterparty,Contract,ARAPDocument");
	
	LinesToDelete = New Array;
	KZProcessingLines = ?(ProcessEverything, AccountsPayable, AccountsPayable.FindRows(DimensionAccounting_1));
	
	For Each curData In KZProcessingLines Do
		TheStructureOfTheSearch = InitializeSearchStructure(curData, False);
		FillPropertyValues(TheStructureOfTheSearch, curData);
		
		FoundRows = DataAccountsPayable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() = 0 Then
			LinesToDelete.Add(curData);
			Continue;
		EndIf;
		
		If Not curData.ManualAdjustment Then
			curData.Sum = FoundRows[0].Sum;
		EndIf;
		DataAccountsPayable.Delete(FoundRows[0]);
	EndDo;
	
	For Each curData In DataAccountsPayable Do
		NewRow = AccountsPayable.Add();
		FillPropertyValues(NewRow, curData);
	EndDo;
	
	For Each curData In LinesToDelete Do
		If curData.ManualAdjustment Then
			Continue;
		EndIf;
		
		AccountsPayable.Delete(curData);
	EndDo;
	
	AccountsPayable.Sort("Counterparty,Contract,ARAPDocument");
	
	If CalculateReserves_ Then
		CalculateReserves(DimensionAccounting_1);
	EndIf;
	
EndProcedure

// Calculates reserves in the accounts Receivable table.
// 
// Parameters:
// 	DimensionAccounting_1 - Structure, Undefined - Analytics by which to calculate reserves.
// 		If Undefined, then for all tables.
// 	* Contractor
// 	* Contract
// 	* Settlement document
// 	
// Performs the following actions in order:
// 1. Distributes the amount of collateral (according to the transferred analytics).
// 2. Distributes the counter debt (to the counterparty from the transferred analytics).
// 3. Calculates the amount of the BU reserve (for the counterparty from the transferred analytics).
// 4. Calculates the amount of the NU reserve (for the counterparty from the transferred analytics).
// 5. Calculates WELL within the limit (for the entire table).
// 	
// 	ACC - Boolean - if True, the amount of the BU reserve is calculated
// 	TA - Boolean - if True, the reserve amount is calculated.
// 	MA - Boolean - if True, the amount of the reserve is calculated in the settlement currency
//
Procedure CalculateReserves(DimensionAccounting_1 = Undefined, ACC = True, TA = True, MA = True) Export
	
	InternationalVersion = Not GetFunctionalOption("LocalizationRFService");
	
	DistributeCollateral(DimensionAccounting_1);
	DistributeCounterDebt(?(DimensionAccounting_1 = Undefined, Undefined,
		New Structure("Counterparty", DimensionAccounting_1.Counterparty)));
	
	// Calculation of the amount of reserves.
	
	ProcessEverything = DimensionAccounting_1 = Undefined;
	
	If Not TA Then
		TA = False;
		GenerateTA = False;
	Else
		StructureOfFlagsTA = AccrualAndWriteOffOfBadDebtAlowancesLocalization.ValuesOfTaxAccountingFlags(
								Organization,
								Date,
								TA,
								GenerateTA);
		If StructureOfFlagsTA <> Undefined Then
			TA = StructureOfFlagsTA.TA;
			GenerateTA = StructureOfFlagsTA.GenerateTA;
		Else
			TA = False;
			GenerateTA = False;
		EndIf;
	EndIf;
	
	TaRatingTable = Documents.AccrualAndWriteOffOfBadDebtAlowances.TaRatingTable();
	EvaluationParameters_ = New Structure("EvaluationTable", TaRatingTable);
	
	DZProcessingLines = ?(ProcessEverything, AccountsReceivable,
		AccountsReceivable.FindRows(New Structure("Counterparty", DimensionAccounting_1.Counterparty)));
	For Each VTRow In DZProcessingLines Do
		If VTRow.DoNotAccrue Then
			VTRow.ACReserve = 0;
			VTRow.TAReserve = 0;
			VTRow.Reserve = 0;
			
			Continue;
		EndIf;
		
		BaseOfCalculation = VTRow.AmountOfDebtLocal - VTRow.AmountOfSecurity;
		If ACC And Not (VTRow.ManualAdjustment And ProcessEverything) Then
			VTRow.ACReserve = BaseOfCalculation * VTRow.Evaluation / 100;
		EndIf;
		
		If MA And Not (VTRow.ManualAdjustment And ProcessEverything) Then
			VTRow.Reserve = ?(VTRow.AmountOfDebtLocal = 0, 0,
				VTRow.DebtAmount * VTRow.ACReserve / VTRow.AmountOfDebtLocal);
		EndIf;
		
		If InternationalVersion And VTRow.ManualAdjustment And Not ProcessEverything
			And ACC = False And MA = False And TA = False Then
				VTRow.ACReserve = ?(VTRow.DebtAmount = 0, 0,
					VTRow.AmountOfDebtLocal * VTRow.Reserve / VTRow.DebtAmount);
		EndIf;
		
		BaseOfCalculation = BaseOfCalculation - VTRow.MutualDebt;
		If TA Then
			If GenerateTA Then
				TAScore = Documents.AccrualAndWriteOffOfBadDebtAlowances.GetEstimate(
					VTRow.DebtKind, VTRow.DoubtfulDebtPeriod, EvaluationParameters_);
				VTRow.TAReserve = BaseOfCalculation * TAScore / 100;
			Else
				VTRow.TAReserve = 0;
			EndIf;
		EndIf;
	EndDo;
	
	If TA Then
		CalculateReservesWithinLimits();
	EndIf;
	
EndProcedure

// Updates the user's spending limit.
// 
// Parameters:
// 	CalculateReserves_ - Boolean - if True, reserves are calculated after filling in
// 	InteractiveUpdate - Boolean - flag for calling limit updates from the document form
//
Procedure UpdateYourSpendingLimit(CalculateReserves_ = True, InteractiveUpdate) Export
	
	ThisOrganization = Common.ObjectAttributesValues(
		Organization, "BranchOffice, ParentCompany");
	
	If ThisOrganization.BranchOffice Then
		If InteractiveUpdate = True Then 
			LimitOfTAExpenses = AccrualAndWriteOffOfBadDebtAlowancesLocalization.GetTaSpendingLimit(
				Date, ThisOrganization.ParentCompany);
		Else
			LimitOfTAExpenses = 0;
		EndIf;
	Else
		LimitOfTAExpenses = AccrualAndWriteOffOfBadDebtAlowancesLocalization.GetTaSpendingLimit(
			Date, Organization);
	EndIf;
	
	If CalculateReserves_ Then
		CalculateReserves(, False);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Let's check that there are no more similar documents this month.
	
	If Not DeletionMark Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	AccrualAndWriteOffOfBadDebtAlowances.Ref
		|FROM
		|	Document.AccrualAndWriteOffOfBadDebtAlowances AS AccrualAndWriteOffOfBadDebtAlowances
		|WHERE
		|	NOT AccrualAndWriteOffOfBadDebtAlowances.Ref = &Ref
		|	AND BEGINOFPERIOD(AccrualAndWriteOffOfBadDebtAlowances.Date, MONTH) = &BegOfMonth
		|	AND AccrualAndWriteOffOfBadDebtAlowances.Organization = &Organization
		|	AND NOT AccrualAndWriteOffOfBadDebtAlowances.DeletionMark";
		
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("BegOfMonth", BegOfMonth(Date));
		Query.SetParameter("Organization", Organization);
		
		Result = Query.Execute();
		Selection = Result.Select();
		If Selection.Next() Then
			MessageText = NStr("vi = 'Đối với doanh nghiệp ""%1"" trong ""%2"" tháng đã tạo chứng từ ""%3"".';
								|ru = 'По организации ""%1"" за ""%2"" месяц уже оформлен документ ""%3"".';
								|en = 'The ""%3"" document is already registered for the ""%1"" company for ""%2"" month.'; fa = 'The ""%3"" document is already registered for the ""%1"" company for ""%2"" month.';
								|it = 'Per l''azienda ""%1"" relativo al ""%2"" mese è stato già emesso il documento ""%3"".';
								|pl = 'Według firmy „%1” za ”%2„ miesiąc został już sporządzony dokument ”%3”.';
								|tr = '""%1"" iş yeri ""%2"" ayı için zaten ""%3"" belgesi düzenlendi.'");
			MessageText = StrTemplate(MessageText, Organization, Format(Date, NStr("vi = 'ДФ=''ММММ''';
																					|ru = 'ДФ=''ММММ''';
																					|en = 'DF=''MMMM'''; fa = 'DF=''MMMM''';
																					|it = 'FD=''MMMM''';
																					|pl = 'DF=''MMMM''';
																					|tr = 'DF=''MMMM'''")), Selection.Ref);
			CommonClientServer.MessageToUser(MessageText, Ref, , , Cancel);
			Return;
		EndIf;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "AccountsReceivable,PaidOffDebt");
	
	AdjustRowIDs();
	
	AccrualAndWriteOffOfBadDebtAlowancesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "AccountsReceivable,PaidOffDebt");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	AccrualAndWriteOffOfBadDebtAlowancesLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Function InitializeSearchStructure(DimensionAccounting_1, ThisIsAccountsReceivable = True)

	If DimensionAccounting_1 = Undefined Then
		Return Undefined;
	EndIf;

	If Not ThisIsAccountsReceivable Then
		Return New Structure("Counterparty,Contract,ARAPDocument");
	ElsIf DimensionAccounting_1.DebtKind = Enums.KindsOfDebt.IssuedBorrowings Then
		Return New Structure("Counterparty,Contract,AmountType");
	Else
		Return New Structure("DebtKind,Counterparty,Contract,ARAPDocument");
	EndIf;

EndFunction

// Distribution of the security amount by Analytics.
//
Procedure DistributeCollateral(Val FilterStructure1 = Undefined)
	
	ProcessEverything = False;
	If FilterStructure1 = Undefined Then
		ProcessEverything = True;
		FilterStructure1 = New Structure("DebtKind,Counterparty,Contract,ARAPDocument");
	EndIf;
	
	SecurityTable = AccountsReceivable.Unload(, "DebtKind,Counterparty,Contract,ARAPDocument,AmountOfSecurityByDimension");
	SecurityTable.GroupBy("DebtKind,Counterparty,Contract,ARAPDocument,AmountOfSecurityByDimension");
	
	DistributionTable_1 = AccountsReceivable.UnloadColumns(
		"DoNotAccrue,DateOfDebtOccurrence,AmountOfDebtLocal");
	DistributionTable_1.Columns.Add("CalculationLine");
	
	CollateralDistributionLines = ?(ProcessEverything, SecurityTable, SecurityTable.FindRows(FilterStructure1));
	For Each SecurityLine In CollateralDistributionLines Do
		FillPropertyValues(FilterStructure1, SecurityLine);
		FillInSecurityDistributionTable(DistributionTable_1, AccountsReceivable, FilterStructure1);
		
		AmountToDistribute = SecurityLine.AmountOfSecurityByDimension;
		SkippingDistribution = DistributionTable_1.Total("AmountOfDebtLocal") <= AmountToDistribute;
		
		For Each DistributionString In DistributionTable_1 Do
			If SkippingDistribution Then
				DistributionString.CalculationLine.AmountOfSecurity = DistributionString.AmountOfDebtLocal;
				Continue;
			EndIf;
			
			If AmountToDistribute = 0 Then
				DistributionString.CalculationLine.AmountOfSecurity = 0;
				Continue;
			EndIf;
			
			DistributionString.CalculationLine.AmountOfSecurity = Min(DistributionString.AmountOfDebtLocal, AmountToDistribute);
			AmountToDistribute = AmountToDistribute - DistributionString.CalculationLine.AmountOfSecurity;
		EndDo;
	EndDo;
	
EndProcedure

// Distribution of accounts payable by counterparty.
//
Procedure DistributeCounterDebt(Val FilterStructure1 = Undefined)
	
	ProcessEverything = False;
	If FilterStructure1 = Undefined Then
		ProcessEverything = True;
		FilterStructure1 = New Structure("Counterparty");
	EndIf;
	
	KZTable = AccountsPayable.Unload(, "Counterparty,Sum");
	KZTable.GroupBy("Counterparty", "Sum");
	
	// We will clear the counter debt of the necessary rows of the accounts receivable table before distribution.
	If ProcessEverything Then
		ArrayOfZeros = New Array;
		For IndexOf = 1 To AccountsReceivable.Count() Do
			ArrayOfZeros.Add(0);
		EndDo;
		
		AccountsReceivable.LoadColumn(ArrayOfZeros, "MutualDebt");
	Else
		FoundRows = AccountsReceivable.FindRows(FilterStructure1);
		For Each FoundRow In FoundRows Do
			FoundRow.MutualDebt = 0;
		EndDo;
	EndIf;
	
	DistributionTable_1 = AccountsReceivable.UnloadColumns(
		"DoNotAccrue,DebtKind,DateOfDebtOccurrence,AmountOfDebtLocal,AmountOfSecurity");
	DistributionTable_1.Columns.Add("CalculationLine");
	
	KZDistributionLines = ?(ProcessEverything, KZTable, KZTable.FindRows(FilterStructure1));
	For Each KZLine In KZDistributionLines Do
		FillPropertyValues(FilterStructure1, KZLine);
		FillInTableOfDistributionOfCounterDebt(DistributionTable_1, AccountsReceivable, FilterStructure1);
		
		AmountToDistribute = KZLine.Sum;
		SkippingDistribution = DistributionTable_1.Total("AmountOfDebtLocal") -
			DistributionTable_1.Total("AmountOfSecurity") <= AmountToDistribute;
		
		For Each DistributionString In DistributionTable_1 Do
			DoubtfulDebts = Max(0, DistributionString.AmountOfDebtLocal - DistributionString.AmountOfSecurity);
			If SkippingDistribution Then
				DistributionString.CalculationLine.MutualDebt = DoubtfulDebts;
				Continue;
			EndIf;
			
			If AmountToDistribute = 0 Then
				DistributionString.CalculationLine.MutualDebt = 0;
				Continue;
			EndIf;
			
			DistributionString.CalculationLine.MutualDebt = Min(DoubtfulDebts, AmountToDistribute);
			AmountToDistribute = AmountToDistribute - DistributionString.CalculationLine.MutualDebt;
		EndDo;
	EndDo;
	
EndProcedure

Procedure FillInSecurityDistributionTable(DistributionTable_1, AccountsReceivable, TheStructureOfTheSearch)
	
	DistributionTable_1.Clear();
	DZProcessingLines = AccountsReceivable.FindRows(TheStructureOfTheSearch);
	
	For Each VTRow In DZProcessingLines Do
		NewRow = DistributionTable_1.Add();
		FillPropertyValues(NewRow, VTRow);
		
		// We do not distribute the lines marked with the "Do not charge" sign.
		
		If VTRow.DoNotAccrue Then
			NewRow.AmountOfDebtLocal = 0;
		EndIf;
		
		NewRow.CalculationLine = VTRow;
	EndDo;
	
	DistributionTable_1.Sort("DateOfDebtOccurrence");
	
EndProcedure

Procedure FillInTableOfDistributionOfCounterDebt(DistributionTable_1, AccountsReceivable, TheStructureOfTheSearch)
	
	DistributionTable_1.Clear();
	DZProcessingLines = AccountsReceivable.FindRows(TheStructureOfTheSearch);
	
	For Each VTRow In DZProcessingLines Do
		NewRow = DistributionTable_1.Add();
		FillPropertyValues(NewRow, VTRow);
		
		// We distribute the lines for which the reserve is accrued only for settlements with counterparties. 
		
		If
			VTRow.DoNotAccrue Or
				Not VTRow.DebtKind = Enums.KindsOfDebt.ReceivablesFromCounterpartiesLocal And
				Not VTRow.DebtKind = Enums.KindsOfDebt.CounterpartyAccountsReceivablesInForeignCurrency
		Then
			NewRow.AmountOfSecurity = 0;
			NewRow.AmountOfDebtLocal = 0;
		EndIf;
		
		NewRow.CalculationLine = VTRow;
	EndDo;
	
	DistributionTable_1.Sort("DateOfDebtOccurrence");
	
EndProcedure

Procedure CalculateReservesWithinLimits()
	
	ReserveAmount_ = AccountsReceivable.Total("TAReserve");
	ShareOfBadDebtAlowancesTaxAccounting = ?(ReserveAmount_ = 0, 0, Min(ReserveAmount_, LimitOfTAExpenses) / ReserveAmount_);
	
	If ShareOfBadDebtAlowancesTaxAccounting >= 1 Then
		AccountsReceivable.LoadColumn(AccountsReceivable.UnloadColumn("TAReserve"),
			"TAReserveWithinBorderOfLimit");
	Else
		TableToDistribution = AccountsReceivable.Unload();
		
		TAReserveWithinBorderOfLimit = Round(ReserveAmount_ * ShareOfBadDebtAlowancesTaxAccounting, 2);
		If TAReserveWithinBorderOfLimit = 0 Then
			TableToDistribution.FillValues(0, "TAReserveWithinBorderOfLimit");
		Else
			ArrayOfOldAmounts = TableToDistribution.UnloadColumn("TAReserve");
			ArrayOfNewAmounts = CommonClientServer.DistributeAmountInProportionToCoefficients(
				TAReserveWithinBorderOfLimit, ArrayOfOldAmounts);
			If Not ArrayOfNewAmounts = Undefined Then
		 		TableToDistribution.LoadColumn(ArrayOfNewAmounts, "TAReserveWithinBorderOfLimit");
			EndIf; 
		EndIf;
		
		AccountsReceivable.Load(TableToDistribution);
	EndIf;
	
EndProcedure

Procedure AdjustRowIDs()
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	DocumentData.LineNumber,
	|	
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|	DocumentData.LineOfBusiness,
	|	
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPDocument,
	|	DocumentData.AmountType,
	|	DocumentData.Currency,
	|	
	|	DocumentData.RowID
	|INTO Tt_DocumentData
	|FROM
	|	&DocumentData AS DocumentData
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Tt_DocumentData.Counterparty AS Counterparty,
	|	Tt_DocumentData.Contract AS Contract,
	|	Tt_DocumentData.ARAPObject AS ARAPObject,
	|	Tt_DocumentData.ARAPDocument AS ARAPDocument,
	|	Tt_DocumentData.AmountType AS AmountType,
	|	MAX(Tt_DocumentData.RowID) AS RowID
	|INTO Tt_AdjustingRowIDs
	|FROM
	|	Tt_DocumentData AS Tt_DocumentData
	|
	|GROUP BY
	|	Tt_DocumentData.Counterparty,
	|	Tt_DocumentData.Contract,
	|	Tt_DocumentData.ARAPObject,
	|	Tt_DocumentData.ARAPDocument,
	|	Tt_DocumentData.AmountType
	|
	|HAVING
	|	COUNT(DISTINCT Tt_DocumentData.RowID) > 1
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Tt_DocumentData.LineNumber AS LineNumber,
	|	Tt_AdjustingRowIDs.RowID AS RowID
	|FROM
	|	Tt_DocumentData AS Tt_DocumentData
	|		LEFT JOIN Tt_AdjustingRowIDs AS Tt_AdjustingRowIDs
	|		ON Tt_DocumentData.Counterparty = Tt_AdjustingRowIDs.Counterparty
	|		AND Tt_DocumentData.Contract = Tt_AdjustingRowIDs.Contract
	|		AND Tt_DocumentData.ARAPObject = Tt_AdjustingRowIDs.ARAPObject
	|		AND Tt_DocumentData.ARAPDocument = Tt_AdjustingRowIDs.ARAPDocument
	|		AND Tt_DocumentData.AmountType = Tt_AdjustingRowIDs.AmountType
	|WHERE
	|	(Tt_DocumentData.RowID = """"
	|			OR NOT Tt_AdjustingRowIDs.RowID IS NULL)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Tt_AdjustingRowIDs";
	
	Query.SetParameter("DocumentData", AccountsReceivable.Unload(,
		"LineNumber,Partner,Counterparty,Contract,LineOfBusiness,ARAPObject,ARAPDocument,AmountType,Currency,RowID"));
	
	PackageResult = Query.ExecuteBatch();
	QueryResult2 = PackageResult.Get(2); // QueryResult
	Selection = QueryResult2.Select();
	While Selection.Next() Do
		AccountsReceivable[Selection.LineNumber -1].RowID = Selection.RowID;
	EndDo;

	FillInIdsOfLinesOfRepaidDebt(Query.TempTablesManager);
	
EndProcedure

Procedure FillInIdsOfLinesOfRepaidDebt(TempTablesManager)
	
	PaidOffDebt.Clear();
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	AccountingDimensionByPartners.DimensionKey AS DimensionKey,
	|	AccountingDimensionByPartners.Partner AS Partner,
	|	AccountingDimensionByPartners.Counterparty AS Counterparty,
	|	AccountingDimensionByPartners.Contract AS Contract,
	|	AccountingDimensionByPartners.LineOfBusiness AS LineOfBusiness
	|INTO Tt_AccountingAnalytics
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|WHERE
	|	AccountingDimensionByPartners.Organization = &Organization
	|
	|INDEX BY
	|	DimensionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Tt_AccountingAnalytics.DimensionKey AS DimensionKey,
	|	Tt_DocumentData.ARAPObject AS ARAPObject,
	|	Tt_DocumentData.ARAPDocument AS ARAPDocument,
	|	Tt_DocumentData.AmountType AS AmountType
	|INTO Tt_DocumentAnalytics
	|FROM
	|	Tt_DocumentData AS Tt_DocumentData
	|		INNER JOIN Tt_AccountingAnalytics AS Tt_AccountingAnalytics
	|		ON Tt_DocumentData.Partner = Tt_AccountingAnalytics.Partner
	|		AND Tt_DocumentData.Counterparty = Tt_AccountingAnalytics.Counterparty
	|		AND CASE
	|			WHEN VALUETYPE(Tt_DocumentData.Contract) = TYPE(Catalog.LoanAndDepositContracts)
	|				THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			ELSE Tt_DocumentData.Contract
	|		END = Tt_AccountingAnalytics.Contract
	|		AND Tt_DocumentData.LineOfBusiness = Tt_AccountingAnalytics.LineOfBusiness
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Balance.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Balance.ARAPObject AS ARAPObject,
	|	Balance.ARAPDocument AS ARAPDocument,
	|	Balance.AmountType AS AmountType,
	|	Balance.Currency AS Currency,
	|	SUM(Balance.Sum) AS Sum,
	|	SUM(Balance.SumMan) AS SumMan,
	|	SUM(Balance.SumCompl) AS SumCompl,
	|	SUM(Balance.PermanentDifference) AS PermanentDifference,
	|	SUM(Balance.CostTD) AS CostTD
	|FROM
	|	(SELECT
	|		Reserves.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Reserves.ARAPObject AS ARAPObject,
	|		Reserves.ARAPDocument AS ARAPDocument,
	|		Reserves.AmountType AS AmountType,
	|		Reserves.Currency AS Currency,
	|		Reserves.SumBalance AS Sum,
	|		Reserves.SumManBalance AS SumMan,
	|		Reserves.SumComplBalance AS SumCompl,
	|		Reserves.PermanentDifferenceBalance AS PermanentDifference,
	|		Reserves.CostTDBalance AS CostTD
	|	FROM
	|		AccumulationRegister.LossAllowance.Balance(&EndOfMonthBoundary, AccountingDimensionByPartners IN
	|			(SELECT
	|				T.DimensionKey
	|			FROM
	|				Tt_AccountingAnalytics AS T)) AS Reserves
	|			LEFT JOIN Tt_DocumentAnalytics AS Tt_DocumentAnalytics
	|			ON Reserves.AccountingDimensionByPartners = Tt_DocumentAnalytics.DimensionKey
	|			AND Reserves.ARAPObject = Tt_DocumentAnalytics.ARAPObject
	|			AND Reserves.ARAPDocument = Tt_DocumentAnalytics.ARAPDocument
	|			AND Reserves.AmountType = Tt_DocumentAnalytics.AmountType
	|	WHERE
	|		Tt_DocumentAnalytics.ARAPDocument IS NULL
	|
	|	UNION ALL
	|
	|	SELECT
	|		Reserves.AccountingDimensionByPartners,
	|		Reserves.ARAPObject,
	|		Reserves.ARAPDocument,
	|		Reserves.AmountType,
	|		Reserves.Currency,
	|		CASE
	|			WHEN Reserves.RecordType = &RecordTypeExpense
	|				THEN Reserves.Sum
	|			ELSE -Reserves.Sum
	|		END,
	|		CASE
	|			WHEN Reserves.RecordType = &RecordTypeExpense
	|				THEN Reserves.SumMan
	|			ELSE -Reserves.SumMan
	|		END,
	|		CASE
	|			WHEN Reserves.RecordType = &RecordTypeExpense
	|				THEN Reserves.SumCompl
	|			ELSE -Reserves.SumCompl
	|		END,
	|		CASE
	|			WHEN Reserves.RecordType = &RecordTypeExpense
	|				THEN Reserves.PermanentDifference
	|			ELSE -Reserves.PermanentDifference
	|		END,
	|		CASE
	|			WHEN Reserves.RecordType = &RecordTypeExpense
	|				THEN Reserves.CostTD
	|			ELSE -Reserves.CostTD
	|		END
	|	FROM
	|		AccumulationRegister.LossAllowance AS Reserves
	|			LEFT JOIN Tt_DocumentAnalytics AS Tt_DocumentAnalytics
	|			ON Reserves.AccountingDimensionByPartners = Tt_DocumentAnalytics.DimensionKey
	|			AND Reserves.ARAPObject = Tt_DocumentAnalytics.ARAPObject
	|			AND Reserves.ARAPDocument = Tt_DocumentAnalytics.ARAPDocument
	|			AND Reserves.AmountType = Tt_DocumentAnalytics.AmountType
	|	WHERE
	|		&ExcludeDocumentRegisteredRecords
	|		AND Tt_DocumentAnalytics.ARAPDocument IS NULL
	|		AND Reserves.Recorder = &Recorder) AS Balance
	|GROUP BY
	|	Balance.AccountingDimensionByPartners,
	|	Balance.ARAPObject,
	|	Balance.ARAPDocument,
	|	Balance.AmountType,
	|	Balance.Currency
	|HAVING
	|	SUM(Balance.Sum) <> 0
	|	OR SUM(Balance.SumMan) <> 0
	|	OR SUM(Balance.SumCompl) <> 0
	| 	OR SUM(Balance.PermanentDifference) <> 0
	|	OR SUM(Balance.CostTD) <> 0";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("EndOfMonthBoundary", New Boundary(Date, BoundaryType.Including));
	Query.SetParameter("ExcludeDocumentRegisteredRecords",
		Not AdditionalProperties.DocumentsPosting.DocumentProperties.IsNew);
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("RecordTypeExpense", AccumulationRecordType.Expense);
	
	// We block the entire accumulation register, because the organization we need is part of the partner accounting analytics.
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("AccumulationRegister.LossAllowance");
	DataLockItem.Mode = DataLockMode.Shared;
	Try
		DataLock.Lock();
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			NewRow = PaidOffDebt.Add();
			FillPropertyValues(NewRow, Selection);
			NewRow.RowID = New UUID;
		EndDo;
	Except
		Common.MessageToUser("vi = 'Không thể phong tỏa biểu ghi tích lũy ""Dự phòng nợ xấu""';
							|ru = 'Не удалось заблокировать регистр накопления ""Резервы по сомнительным долгам""';
							|en = 'Cannot block the ""Loss allowance"" accumulation register';
							|it = 'Не удалось заблокировать регистр накопления ""Резервы по сомнительным долгам""';
							|pl = 'Cannot block the ""Loss allowance"" accumulation register';
							|tr = '""Şüpheli borç karşılığı"" birikim kaydı tablosu engellenemedi'");
	EndTry;
	
EndProcedure

Function TimingEvaluationTable(ACRatingTable)

	If RecordInTaxAccounting Then
		TaRatingTable = Documents.AccrualAndWriteOffOfBadDebtAlowances.TaRatingTable();
		CommonClientServer.SupplementTable(TaRatingTable, ACRatingTable);
	EndIf;

	Query = New Query;
	Query.Text = 
		"SELECT
		|	ACRatingTable.DebtKind AS DebtKind,
		|	ACRatingTable.LowerBoundOfInterval AS LowerBoundOfInterval,
		|	ACRatingTable.Evaluation AS Evaluation
		|INTO VTData
		|FROM
		|	&ACRatingTable AS ACRatingTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VTData.DebtKind AS DebtKind,
		|	MIN(VTData.LowerBoundOfInterval) AS LowerBoundOfInterval
		|FROM
		|	VTData AS VTData
		|WHERE
		|	VTData.Evaluation <> 0
		|
		|GROUP BY
		|	VTData.DebtKind";
	
	Query.SetParameter("ACRatingTable", ACRatingTable);
	
	QueryResult = Query.Execute();

	Return QueryResult.Unload();

EndFunction 

Function DoNotIncludeInReserveByTerm(DebtKind, DoubtfulDebtPeriod, TimingEvaluationTable)
	
	FoundRows = TimingEvaluationTable.FindRows(New Structure("DebtKind", DebtKind));
	If DebtKind = Enums.KindsOfDebt.Other Then
		Return False;
	ElsIf FoundRows.Count()>0 Then
		Return FoundRows[0].LowerBoundOfInterval > DoubtfulDebtPeriod;
	Else
		Return True;
	EndIf;
	
EndFunction

#EndRegion

#EndIf
