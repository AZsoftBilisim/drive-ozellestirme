
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AddressOfDescriptionOfChartTypes = PutToTempStorage(DescriptionOfPaymentScheduleTypes(),UUID);
	TypesOfGraphs = GetFromTempStorage(AddressOfDescriptionOfChartTypes).TypesOfGraphs;
	
	AttributesArray = New Array;
	AttributeType = New TypeDescription("Boolean");
	
	For Each DescriptionOfGroupElement In TypesOfGraphs Do
	
		NewAttribute = New FormAttribute(DescriptionOfGroupElement.ScheduleType,
								AttributeType,
								"",
								DescriptionOfGroupElement.TitleOfMarkerChartType);
		AttributesArray.Add(NewAttribute);
	
	EndDo;
		
	ChangeAttributes(AttributesArray);
	
	For Each DescriptionOfGroupElement In TypesOfGraphs Do
	
		ItemType = Items.Add(DescriptionOfGroupElement.ScheduleType,Type("FormField"),Items.LeftGroup1);
		ItemType.Type						= FormFieldType.CheckBoxField;
		ItemType.Title				= DescriptionOfGroupElement.TitleOfMarkerChartType;
		ItemType.DataPath				= DescriptionOfGroupElement.ScheduleType;
		ItemType.TitleLocation		= FormItemTitleLocation.Right;
		ThisObject[DescriptionOfGroupElement.ScheduleType] = True;
	
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CheckBoxesForTypes(Command)
	ChangeMarks(True);
EndProcedure

&AtClient
Procedure UncheckTypes(Command)
	ChangeMarks(False);
EndProcedure

&AtClient
Procedure ShouldRecalculate(Command)
	RecalculateAtServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DescriptionOfCalculationFilter()
	
	DescriptionOfCalculationFilter = New Structure;
	DescriptionOfCalculationFilter.Insert("PlanningAreas",New Array);
	Return DescriptionOfCalculationFilter;
	
EndFunction

&AtServer
Function DescriptionOfPaymentScheduleTypes()
	
	TypesOfGraphs = New Array;
	TypesOfGraphs.Add(DescriptionOfGraphType("CalculationsBy_c_Clients"));
	TypesOfGraphs.Add(DescriptionOfGraphType("PaymentsBy_c_Suppliers"));
	TypesOfGraphs.Add(DescriptionOfGraphType("Cash_credits_pay"));
	TypesOfGraphs.Add(DescriptionOfGraphType("Monetary_Funds_In_Paths"));
	TypesOfGraphs.Add(DescriptionOfGraphType("ReceiptsFrom___Banks_By__quiring"));
	TypesOfGraphs.Add(DescriptionOfGraphType("Financial_Instruments"));
	TypesOfGraphs.Add(DescriptionOfGraphType("Expected_approachments_OfMonetary_Funds"));
	
	DescriptionOfPaymentScheduleTypes = New Structure();
	DescriptionOfPaymentScheduleTypes.Insert("TypesOfGraphs",TypesOfGraphs);
	
	Return DescriptionOfPaymentScheduleTypes;
	
EndFunction

&AtServer
Function DescriptionOfGraphType(ScheduleType)
	
	DescriptionOfGraphType = New Structure;
	DescriptionOfGraphType.Insert("ScheduleType",StrReplace(ScheduleType,"_",""));
	DescriptionOfGraphType.Insert("TitleOfMarkerChartType",StrReplace(ScheduleType,"_"," "));
	
	Return DescriptionOfGraphType;
	
EndFunction

&AtClient
Procedure ChangeMarks(Value)
	
	TypesOfGraphs = GetFromTempStorage(AddressOfDescriptionOfChartTypes).TypesOfGraphs;
	For Each ScheduleDetails In TypesOfGraphs Do
		ThisObject[ScheduleDetails.ScheduleType] = Value;
	EndDo;
	
EndProcedure

&AtServer
Procedure RecalculateAtServer()
	
	If ThisObject.CustomersARAPAccounting Then
		
		FilterSettlementsWithClients = DescriptionOfCalculationFilter(); 
		FilterSettlementsWithClients.Insert("TheseAreSettlementsWithCustomers",True);
		FilterSettlementsWithClients.PlanningAreas.Add(
			PredefinedValue("Enum.PaymentPlanningAreas.CustomersARAPAccounting"));
		
		CalculatePaymentScheduleWithCustomersAndSuppliers(FilterSettlementsWithClients);
		
	EndIf;
	
	If ThisObject.VendorsARAPAccounting Then
		
		FilterSettlementsWithSuppliers = DescriptionOfCalculationFilter(); 
		FilterSettlementsWithSuppliers.Insert("TheseAreSettlementsWithCustomers",False);
		FilterSettlementsWithSuppliers.PlanningAreas.Add(
			PredefinedValue("Enum.PaymentPlanningAreas.VendorsARAPAccounting"));
		
		CalculatePaymentScheduleWithCustomersAndSuppliers(FilterSettlementsWithSuppliers);
		
	EndIf;

	If ThisObject.CashToBePaid Then
		CalculatePaymentScheduleForCashToBePaid();
	EndIf;

	If ThisObject.CashInTransit Then
		CalculatePaymentScheduleForCashInTransit();
	EndIf;

	If ThisObject.ProceedsFromAcquiringBanks Then
		CalculatePaymentScheduleForReceiptsFromBankForAcquiring();
	EndIf;

	If ThisObject.FinancialInstruments Then
		CalculatePaymentScheduleForFinancialInstruments();
	EndIf;

	If ThisObject.ExpectedCashReceipts Then
		CalculatePaymentScheduleForExpectedCashReceipts();
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePaymentScheduleWithCustomersAndSuppliers(CalculationParameters)
	
	TheseAreSettlementsWithCustomers = CalculationParameters.TheseAreSettlementsWithCustomers;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;

	Query.SetParameter("Organization", Organization);
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));	
	Query.SetParameter("AllBankAccountsAndCashAccounts", Not ValueIsFilled(BankAccountCashAccount));
	Query.SetParameter("ThisIsCashAccount", TypeOf(BankAccountCashAccount) = Type("CatalogRef.CashAccounts"));
	Query.SetParameter("CashAccount",BankAccountCashAccount);
	Query.SetParameter("BankAccount",BankAccountCashAccount);
	
	QueryTextBalance =
	"SELECT DISTINCT
	|	Calculations.ARAPObject
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(,) AS Calculations
	|WHERE
	|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance < 0";
	
	If TheseAreSettlementsWithCustomers Then
		QueryTextBalance =
		"SELECT DISTINCT
		|	Calculations.ARAPObject
		|INTO TTBalance
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,) AS Calculations
		|WHERE
		|	Calculations.AmountDueBalance - Calculations.BeingPaidBalance > 0";
	EndIf;
	
	Query.Text =
	QueryTextBalance + Common.QueryBatchSeparator() +
	"SELECT
	|	Balance.ARAPObject AS ARAPObject,
	|	ARAPObjects.Object AS PaymentObject
	|INTO TTPaymentObjects
	|FROM
	|	TTBalance AS Balance
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON Balance.ARAPObject = ARAPObjects.Ref
	|WHERE	
	|	(ARAPObjects.Organization = &Organization
	|			OR &AllCompanies)
	|	AND CASE
	|			WHEN &ThisIsCashAccount
	|				THEN ARAPObjects.CashAccount = &CashAccount	
	|						OR &AllBankAccountsAndCashAccounts
	|			ELSE ARAPObjects.CompanyBankAccount = &BankAccount
	|						OR &AllBankAccountsAndCashAccounts
	|		END";
	
	Query.Execute();
	Result = Query.TempTablesManager.Tables.Find("TTPaymentObjects").GetData();
	If Not Result.IsEmpty() Then
		ClearPaymentSchedule(CalculationParameters,Query.TempTablesManager);
		If TheseAreSettlementsWithCustomers Then
			InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithCustomers(Result.Unload());
		Else
			InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForSettlementsWithSuppliers(Result.Unload());
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePaymentScheduleForCashToBePaid()
	
	CalculationParameters = DescriptionOfCalculationFilter();
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.CashPaymentRequests"));
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.PaymentRequestsPendingApproval"));
	CalculationParameters.PlanningAreas.Add(
			PredefinedValue("Enum.PaymentPlanningAreas.ReferencesForCashTransfer"));
	CalculationParameters.PlanningAreas.Add(
			PredefinedValue("Enum.PaymentPlanningAreas.ReferencesForCashTransferPendingApproval"));
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	SetMainSelection(Query);
	
	Query.Text =
	"SELECT DISTINCT
	|	Cash.PaymentRequest AS PaymentObject
	|INTO TTPaymentObjects
	|FROM
	|	AccumulationRegister.CashToBePaid.Balance(
	|			,
	|			(Organization = &Organization
	|				OR &AllCompanies)
	|				AND (BankAccountCashAccount = &BankAccountCashAccount
	|					OR &AllBankAccountsAndCashAccounts)) AS Cash
	|WHERE
	|	Cash.SumBalance > 0";
	
	Query.Execute();
	Result = Query.TempTablesManager.Tables.Find("TTPaymentObjects").GetData();
	If Not Result.IsEmpty() Then
		ClearPaymentSchedule(CalculationParameters,Query.TempTablesManager);
		ArrayOfPaymentObjects = Result.Unload().UnloadColumn("PaymentObject");
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForCashToBePaid(ArrayOfPaymentObjects);
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePaymentScheduleForCashInTransit()
	
	CalculationParameters = DescriptionOfCalculationFilter();
	CalculationParameters.PlanningAreas.Add(
			PredefinedValue("Enum.PaymentPlanningAreas.CashInTransit"));
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	SetMainSelection(Query);
	
	Query.Text =
	"SELECT
	|	CashInTransit.Recipient AS BankAccountCashAccount,
	|	CASE
	|		WHEN CashInTransit.CashTransferKind IN 
	|
	|		(VALUE(Enum.CashTransferKinds.CashDepositToBank),
	|		 VALUE(Enum.CashTransferKinds.CashCollectionFromBank_),
	|	  VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount),
	|		 VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount))
	|
	|			THEN CashInTransit.Sender
	|
	|		WHEN CashInTransit.CashTransferKind IN 
	|
	|		(VALUE(Enum.CashTransferKinds.ForeignExchangeBuying),
	|		 VALUE(Enum.CashTransferKinds.ForeignExchangeSelling))
	|
	|			THEN CashInTransit.Counterparty
	|
	|	END AS PaymentObject
	|INTO TTPaymentObjects
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(
	|			,
	|			CASE
	|					WHEN CashTransferKind IN
	|
	|					(VALUE(Enum.CashTransferKinds.CashDepositToBank),
	|					 VALUE(Enum.CashTransferKinds.CashCollectionFromBank_),
	|					 VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount),
	|					 VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount))
	|
	|						THEN Sender
	|
	|					WHEN CashTransferKind IN 
	|					(VALUE(Enum.CashTransferKinds.ForeignExchangeBuying),
	|					 VALUE(Enum.CashTransferKinds.ForeignExchangeSelling))
	|
	|						THEN Counterparty
	|						ELSE UNDEFINED
	|
	|				END <> UNDEFINED	
	|				AND (Organization = &Organization OR &AllCompanies)
	|				AND (Recipient = &BankAccountCashAccount OR &AllBankAccountsAndCashAccounts)
	|	) AS CashInTransit";
	
	Query.Execute();
	Result = Query.TempTablesManager.Tables.Find("TTPaymentObjects").GetData();
	If Not Result.IsEmpty() Then
		ClearPaymentScheduleForFundsInTransit(CalculationParameters,Query.TempTablesManager);
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForCashInTransit(Result.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePaymentScheduleForReceiptsFromBankForAcquiring()
	
	CalculationParameters = DescriptionOfCalculationFilter();
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.CashInTransit"));
	
	Query = New Query;
	SetMainSelection(Query);
	Query.SetParameter("PlanningAreas",CalculationParameters.PlanningAreas);
	
	Query.Text =
	"SELECT
	|	Table.PaymentObject,
	|	Table.BankAccountCashAccount
	|FROM
	|	(SELECT
	|		RegisterData.Contract AS PaymentObject,
	|		RegisterData.Recipient AS BankAccountCashAccount,
	|		RegisterData.SumBalance AS Sum
	|	FROM
	|		AccumulationRegister.CashInTransit.Balance(,
	|			(Organization = &Organization
	|				OR &AllCompanies)
	|			AND (Recipient = &BankAccountCashAccount
	|				OR &AllBankAccountsAndCashAccounts)
	|			AND CashTransferKind = VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|			AND Contract <> VALUE(Catalog.AcquiringContracts.EmptyRef)
	|		) AS RegisterData
	|	WHERE
	|		RegisterData.SumBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterData.PaymentObject AS PaymentObject,
	|		RegisterData.BankAccountCashAccount AS BankAccountCashAccount,
	|		-RegisterData.Sum AS Sum
	|	FROM
	|		InformationRegister.ScheduleOfPayments AS RegisterData
	|	WHERE	
	|		RegisterData.AmountType = VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|		AND RegisterData.ReceiptIssue = VALUE(Enum.CashFlowTypes.Inpayment)
	|		AND (RegisterData.Organization = &Organization
	|			OR &AllCompanies)
	|		AND (RegisterData.BankAccountCashAccount = &BankAccountCashAccount
	|			OR &AllBankAccountsAndCashAccounts)
	|	) AS Table
	|GROUP BY
	|	Table.PaymentObject,
	|	Table.BankAccountCashAccount
	|HAVING
	|	SUM(Table.Sum) <> 0
	|";
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForCashInTransit(Result.Unload());
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePaymentScheduleForFinancialInstruments()
	
	CalculationParameters = DescriptionOfCalculationFilter();
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.LoansOrBorrowingsReceived"));
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.Deposits"));
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.IssuedBorrowings"));
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.Lease"));
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	SetMainSelection(Query);
	
	ArrayOfRequestTexts = New Array;
	
	QueryText =
	"SELECT DISTINCT
	|	Calculations.Contract AS PaymentObject
	|INTO TTReceiptsAndDebitsOfFunds
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(, , , 
	|			VALUETYPE(Contract) = TYPE(Catalog.LoanAndDepositContracts)) AS Calculations
	|WHERE
	|	Calculations.SumExpense > 0
	|
	|UNION
	|
	|SELECT
	|	Calculations.Contract
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP.Turnovers(, , , ) AS Calculations
	|WHERE
	|	Calculations.SumReceipt - Calculations.BeingPaidReceipt + Calculations.BeingPaidExpense > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReceiptOfFunds.PaymentObject AS PaymentObject
	|INTO TTPaymentObjects
	|FROM
	|	TTReceiptsAndDebitsOfFunds AS ReceiptOfFunds
	|		INNER JOIN Catalog.LoanAndDepositContracts AS DescriptionOfContracts
	|		ON ReceiptOfFunds.PaymentObject = DescriptionOfContracts.Ref
	|WHERE
	|	(DescriptionOfContracts.Organization = &Organization
	|			OR &AllCompanies)
	|	AND (DescriptionOfContracts.BankAccount = &BankAccountCashAccount
	|			OR &AllBankAccountsAndCashAccounts)";
	
	ArrayOfRequestTexts.Add(QueryText);
	QueryText = 
	"SELECT
	|	ReceiptOfFunds.PaymentObject
	|FROM
	|	TTReceiptsAndDebitsOfFunds AS ReceiptOfFunds
	|		INNER JOIN Catalog.LeaseContract AS DescriptionOfContracts
	|		ON ReceiptOfFunds.PaymentObject = DescriptionOfContracts.Ref
	|WHERE
	|	(DescriptionOfContracts.Organization = &Organization
	|			OR &AllCompanies)
	|	AND (DescriptionOfContracts.BankAccount = &BankAccountCashAccount
	|			OR &AllBankAccountsAndCashAccounts)";
	
	ArrayOfRequestTexts.Add(QueryText);
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.UnionAllText());
	Query.Execute();
	Result = Query.TempTablesManager.Tables.Find("TTPaymentObjects").GetData();
	If Not Result.IsEmpty() Then
		ClearPaymentSchedule(CalculationParameters,Query.TempTablesManager);
		ArrayOfPaymentObjects = Result.Unload().UnloadColumn("PaymentObject");
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForFinancialInstruments(ArrayOfPaymentObjects);
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculatePaymentScheduleForExpectedCashReceipts()
	
	CalculationParameters = DescriptionOfCalculationFilter();
	CalculationParameters.PlanningAreas.Add(
		PredefinedValue("Enum.PaymentPlanningAreas.PlannedCashReceipts"));
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	SetMainSelection(Query);
	Query.SetParameter("SettlementEndDate",BegOfDay(CurrentSessionDate()));
	
	Query.Text = 
	"SELECT DISTINCT
	|	Table.Organization AS Organization,
	|	Table.CashAccount AS CashAccount
	|INTO TTCashBalances
	|FROM
	|	AccumulationRegister.CashAccountBalance.Balance(
	|			,
	|			(Organization = &Organization
	|				OR &AllCompanies)
	|				AND (CashAccount = &BankAccountCashAccount
	|					OR &AllBankAccountsAndCashAccounts)) AS Table
	|WHERE
	|	(Table.SumBalance > 0
	|			OR Table.SumManBalance > 0
	|			OR Table.SumComplBalance > 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Organization AS Organization,
	|	Table.BankAccount AS BankAccount
	|INTO TTNonCashBalances
	|FROM
	|	AccumulationRegister.BankAccountCash.Balance(
	|			,
	|			(Organization = &Organization
	|				OR &AllCompanies)
	|				AND (BankAccount = &BankAccountCashAccount
	|					OR &AllBankAccountsAndCashAccounts)) AS Table
	|WHERE
	|	(Table.SumBalance > 0
	|			OR Table.SumManBalance > 0
	|			OR Table.SumComplBalance > 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(SettlementDates_.DateOfCalculation) AS StartDate,
	|	&SettlementEndDate AS EndDate
	|INTO TTIsCalculationPeriod
	|FROM
	|	(SELECT
	|		BEGINOFPERIOD(Cash.Period, DAY) AS DateOfCalculation
	|	FROM
	|		TTCashBalances AS Balance
	|			LEFT JOIN AccumulationRegister.CashAccountBalance AS Cash
	|			ON Balance.Organization = Cash.Organization
	|				AND Balance.CashAccount = Cash.CashAccount
	|	
	|	UNION
	|	
	|	SELECT
	|		BEGINOFPERIOD(Cash.Period, DAY)
	|	FROM
	|		TTNonCashBalances AS Balance
	|			LEFT JOIN AccumulationRegister.BankAccountCash AS Cash
	|			ON Balance.Organization = Cash.Organization
	|				AND Balance.BankAccount =
	|					Cash.BankAccount) AS SettlementDates_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExpectedReceipt.Ref AS PaymentObject,
	|	ExpectedReceipt.PaymentDate AS DateOfCalculation
	|INTO TTPaymentObjects
	|FROM
	|	TTIsCalculationPeriod AS TTIsCalculationPeriod
	|		INNER JOIN Document.PlannedCashReceipt AS ExpectedReceipt
	|		ON (ExpectedReceipt.PaymentDate BETWEEN
	|				TTIsCalculationPeriod.StartDate AND TTIsCalculationPeriod.EndDate)
	|WHERE
	|	ExpectedReceipt.Posted
	|	AND (ExpectedReceipt.Organization = &Organization
	|			OR &AllCompanies)
	|	AND CASE
	|			WHEN ExpectedReceipt.PaymentMethod =
	|					VALUE(Enum.PaymentForms.EmptyRef)
	|				THEN TRUE
	|			ELSE ExpectedReceipt.CashAccountBankAccount =
	|					&BankAccountCashAccount
	|						OR &AllBankAccountsAndCashAccounts
	|		END";
	
	Query.Execute();
	Result = Query.TempTablesManager.Tables.Find("TTPaymentObjects").GetData();
	If Not Result.IsEmpty() Then
		ClearPaymentSchedule(CalculationParameters,Query.TempTablesManager);
		TableOfPaymentObjects = Result.Unload();
		ArrayOfCalculationDates = Common.UnloadColumn(TableOfPaymentObjects,"DateOfCalculation",True);
		ArrayOfPaymentObjects = TableOfPaymentObjects.UnloadColumn("PaymentObject");
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForExpectedCashReceipts(ArrayOfCalculationDates,,,
																										ArrayOfPaymentObjects);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetMainSelection(Query)
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));
	Query.SetParameter("BankAccountCashAccount", BankAccountCashAccount);
	Query.SetParameter("AllBankAccountsAndCashAccounts", Not ValueIsFilled(BankAccountCashAccount));
	
EndProcedure

&AtServer
Procedure ClearPaymentSchedule(CalculationParameters,TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	SetMainSelection(Query);
	Query.SetParameter("PlanningAreas",CalculationParameters.PlanningAreas);
	
	Query.Text = 
	"SELECT DISTINCT
	|	ScheduleOfPayments.PaymentObject AS PaymentObject,
	|	ScheduleOfPayments.PlanningArea AS PlanningArea
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|WHERE
	|	ScheduleOfPayments.PlanningArea IN(&PlanningAreas)
	|	AND (ScheduleOfPayments.Organization = &Organization
	|			OR &AllCompanies)
	|	AND (ScheduleOfPayments.BankAccountCashAccount = &BankAccountCashAccount
	|			OR &AllBankAccountsAndCashAccounts)
	|	AND NOT ScheduleOfPayments.PaymentObject IN
	|				(SELECT DISTINCT
	|					PaymentObjects.PaymentObject
	|				FROM
	|					TTPaymentObjects AS PaymentObjects)";
	
	TableOfPaymentObjects = Query.Execute().Unload();
	DeletePaymentScheduleRecords(TableOfPaymentObjects);
	
EndProcedure

&AtServer
Procedure ClearPaymentScheduleForFundsInTransit(CalculationParameters,TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	SetMainSelection(Query);
	Query.SetParameter("PlanningAreas",CalculationParameters.PlanningAreas);
	
	Query.Text =
	"SELECT DISTINCT
	|	ScheduleOfPayments.PaymentObject AS PaymentObject,
	|	ScheduleOfPayments.PlanningArea AS PlanningArea
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|WHERE
	|	ScheduleOfPayments.PlanningArea IN(&PlanningAreas)
	|	AND (ScheduleOfPayments.Organization = &Organization
	|			OR &AllCompanies)
	|	AND (ScheduleOfPayments.BankAccountCashAccount = &BankAccountCashAccount
	|			OR &AllBankAccountsAndCashAccounts)
	|	AND NOT(ScheduleOfPayments.AmountType = VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)
	|				AND ScheduleOfPayments.ReceiptIssue = VALUE(Enum.CashFlowTypes.Inpayment))
	|	AND NOT (ScheduleOfPayments.PaymentObject, ScheduleOfPayments.BankAccountCashAccount) IN
	|				(SELECT DISTINCT
	|					PaymentObjects.PaymentObject,
	|					PaymentObjects.BankAccountCashAccount
	|				FROM
	|					TTPaymentObjects AS PaymentObjects)";
	
	TableOfPaymentObjects = Query.Execute().Unload();
	DeletePaymentScheduleRecords(TableOfPaymentObjects);
	
EndProcedure

&AtServer
Procedure DeletePaymentScheduleRecords(TableOfPaymentObjects)
	
	BeginTransaction();
	
	Try
	
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ScheduleOfPayments");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = TableOfPaymentObjects;
		LockItem.UseFromDataSource("PaymentObject", "PaymentObject");
		Block.Lock();
		
		For Each DescriptionOfPaymentObject In TableOfPaymentObjects Do
			
			RecordSet = InformationRegisters.ScheduleOfPayments.CreateRecordSet();
			RecordSet.Filter.PaymentObject.Set(DescriptionOfPaymentObject.PaymentObject);
			RecordSet.Read();
			
			SetData = RecordSet.Unload();
			LinesToDelete = SetData.FindRows(New Structure("PlanningArea",DescriptionOfPaymentObject.PlanningArea));
			For Each RowToDelete In LinesToDelete Do
				SetData.Delete(RowToDelete);
			EndDo;
			RecordSet.Load(SetData);
			RecordSet.Write();
			
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Tính lại lịch biểu thanh toán';
							|ru = 'Пересчет графика платежей';
							|en = 'Recalculate payment schedule'; fa = 'محاسبه مجدد برنامه پرداخت';
							|it = 'Пересчет графика платежей';
							|pl = 'Recalculate payment schedule';
							|tr = 'Ödeme programını oku'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion