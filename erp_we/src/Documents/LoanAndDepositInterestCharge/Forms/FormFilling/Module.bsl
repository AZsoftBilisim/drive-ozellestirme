
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // refund upon receipt of the form for analysis
		Return;
	EndIf;
	
	FillPropertyValues(ThisForm, Parameters,
		"Organization, AccrualAddressInTheStorage, BusinessOperation, StartDate, EndDate, Recorder, DocumentFormID");
	
	SetContractSelectionParameters();
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation( ThisObject, "Partner", BusinessOperation);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	SetContractSelectionParameters();
	
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	SetContractSelectionParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Fill(Command)
	
	AccrualsServer();
	
	Structure = New Structure("AccrualAddressInTheStorage", AccrualAddressInTheStorage);
	NotifyChoice(Structure);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Function SetContractSelectionParameters()
	
	ParametersArray = New Array;
	ParametersArray.Add(New ChoiceParameter("Filter.Organization", Organization));
	ParametersArray.Add(New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	ParametersArray.Add(New ChoiceParameter("Filter.ContractKind",
		Catalogs.LoanAndDepositContracts.NatureOfTransactionAgreement(BusinessOperation)));
		
	If Not Partner.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Partner", Partner));
	EndIf;
	If Not Counterparty.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.Counterparty", Counterparty));
	EndIf;
	If Not EmployeeResponsible.IsEmpty() Then
		ParametersArray.Add(New ChoiceParameter("Filter.EmployeeResponsible", EmployeeResponsible));
	EndIf;
	
	Items.LoanDepositContract.ChoiceParameters = New FixedArray(ParametersArray);
	
EndFunction

&AtServer
Function RequestTextForAccruals()
	
	Return 
	"SELECT
	|	ScheduleOfAccruals.Period,
	|	ScheduleOptions.Owner AS Contract,
	|	ScheduleOfAccruals.ScheduleOption,
	|	ScheduleOfAccruals.Interests,
	|	ScheduleOfAccruals.Fee
	|INTO AccrualsUnderContracts
	|FROM
	|	InformationRegister.ScheduleOfAccrualsForLoansAndDeposits AS ScheduleOfAccruals
	|		LEFT JOIN Catalog.OptionsOfLoansAndDepositsSchedules AS ScheduleOptions
	|		ON ScheduleOfAccruals.ScheduleOption = ScheduleOptions.Ref
	|WHERE
	|	ScheduleOfAccruals.Period BETWEEN &StartDate AND &EndDate
	|	AND ScheduleOptions.Used
	|	AND NOT ScheduleOptions.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualsUnderContracts.Period,
	|	LoanAndDepositContracts.Organization,
	|	LoanAndDepositContracts.Partner,
	|	LoanAndDepositContracts.Counterparty,
	|	AccrualsUnderContracts.Contract,
	|	AccrualsUnderContracts.ScheduleOption,
	|	AccrualsUnderContracts.Interests,
	|	AccrualsUnderContracts.Fee,
	|	LoanAndDepositContracts.IncomeExpenseItemForInterestAccruals AS InterestArticle,
	|	LoanAndDepositContracts.IncomeExpenseItemForFeeAccruals AS CommissionArticle,
	|	LoanAndDepositContracts.ARAPCurrency,
	|	LoanAndDepositContracts.ContractKind
	|INTO CurCharges
	|FROM
	|	AccrualsUnderContracts AS AccrualsUnderContracts
	|		LEFT JOIN Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
	|		ON AccrualsUnderContracts.Contract = LoanAndDepositContracts.Ref
	|WHERE
	|	NOT LoanAndDepositContracts.DeletionMark
	|	AND LoanAndDepositContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND LoanAndDepositContracts.Organization = &Organization
	|	AND LoanAndDepositContracts.ContractKind = &ContractKind
	|{WHERE
	|	LoanAndDepositContracts.Partner.*,
	|	LoanAndDepositContracts.Counterparty.*,
	|	AccrualsUnderContracts.Contract.*,
	|	LoanAndDepositContracts.EmployeeResponsible.*}
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialInstrumentsARAP.Period,
	|	FinancialInstrumentsARAP.AccountingDimensionByPartners,
	|	DimensionKeysOfAccountingByPartners.Organization,
	|	DimensionKeysOfAccountingByPartners.Partner,
	|	DimensionKeysOfAccountingByPartners.Counterparty,
	|	FinancialInstrumentsARAP.Contract,
	|	FinancialInstrumentsARAP.Sum AS Interests,
	|	0 AS Fee,
	|	FinancialInstrumentsARAP.ScheduleType,
	|	FinancialInstrumentsARAP.AmountType,
	|	FinancialInstrumentsARAP.DimensionItem
	|INTO SettlementsOnCreditsDeposits
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstrumentsARAP
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeysOfAccountingByPartners
	|		ON FinancialInstrumentsARAP.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.DimensionKey
	|WHERE
	|	FinancialInstrumentsARAP.Period BETWEEN &StartDate AND &EndDate
	|	AND FinancialInstrumentsARAP.ScheduleType = VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)
	|	AND DimensionKeysOfAccountingByPartners.Organization = &Organization
	|	AND FinancialInstrumentsARAP.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|	AND FinancialInstrumentsARAP.Recorder <> &Recorder
	|{WHERE
	|	DimensionKeysOfAccountingByPartners.Partner.*,
	|	DimensionKeysOfAccountingByPartners.Counterparty.*,
	|	FinancialInstrumentsARAP.Contract.*,
	|	FinancialInstrumentsARAP.Contract.EmployeeResponsible.* AS EmployeeResponsible}
	|
	|UNION ALL
	|
	|SELECT
	|	FinancialInstrumentsARAP.Period,
	|	FinancialInstrumentsARAP.AccountingDimensionByPartners,
	|	DimensionKeysOfAccountingByPartners.Organization,
	|	DimensionKeysOfAccountingByPartners.Partner,
	|	DimensionKeysOfAccountingByPartners.Counterparty,
	|	FinancialInstrumentsARAP.Contract,
	|	0,
	|	FinancialInstrumentsARAP.Sum,
	|	FinancialInstrumentsARAP.ScheduleType,
	|	FinancialInstrumentsARAP.AmountType,
	|	FinancialInstrumentsARAP.DimensionItem
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS FinancialInstrumentsARAP
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeysOfAccountingByPartners
	|		ON FinancialInstrumentsARAP.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.DimensionKey
	|WHERE
	|	FinancialInstrumentsARAP.Period BETWEEN &StartDate AND &EndDate
	|	AND FinancialInstrumentsARAP.ScheduleType = VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)
	|	AND DimensionKeysOfAccountingByPartners.Organization = &Organization
	|	AND FinancialInstrumentsARAP.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|	AND FinancialInstrumentsARAP.Recorder <> &Recorder
	|{WHERE
	|	DimensionKeysOfAccountingByPartners.Partner.*,
	|	DimensionKeysOfAccountingByPartners.Counterparty.*,
	|	FinancialInstrumentsARAP.Contract.*,
	|	FinancialInstrumentsARAP.Contract.EmployeeResponsible.* AS EmployeeResponsible}
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SettlementsOnCreditsDeposits.Period AS Period,
	|	SettlementsOnCreditsDeposits.AccountingDimensionByPartners,
	|	SettlementsOnCreditsDeposits.Organization,
	|	SettlementsOnCreditsDeposits.Partner,
	|	SettlementsOnCreditsDeposits.Counterparty,
	|	SettlementsOnCreditsDeposits.Contract,
	|	SettlementsOnCreditsDeposits.ScheduleType
	|INTO PreviousAccruals
	|FROM
	|	SettlementsOnCreditsDeposits AS SettlementsOnCreditsDeposits
	|
	|GROUP BY
	|	SettlementsOnCreditsDeposits.Period,
	|	SettlementsOnCreditsDeposits.AccountingDimensionByPartners,
	|	SettlementsOnCreditsDeposits.Organization,
	|	SettlementsOnCreditsDeposits.Partner,
	|	SettlementsOnCreditsDeposits.Counterparty,
	|	SettlementsOnCreditsDeposits.Contract,
	|	SettlementsOnCreditsDeposits.ScheduleType
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurCharges.Period AS Date,
	|	CurCharges.Organization,
	|	CurCharges.Partner,
	|	CurCharges.Counterparty,
	|	CurCharges.Contract,
	|	CurCharges.Contract.Department AS Department,
	|	CurCharges.Contract.LineOfBusiness AS LineOfBusiness,
	|	CurCharges.ScheduleOption,
	|	CurCharges.Interests,
	|	CurCharges.Fee,
	|	CurCharges.InterestArticle,
	|	CurCharges.CommissionArticle,
	|	CurCharges.ARAPCurrency,
	|	PreviousAccruals.Period AS PeriodAccrued,
	|	CurCharges.ContractKind
	|FROM
	|	CurCharges AS CurCharges
	|		LEFT JOIN PreviousAccruals AS PreviousAccruals
	|		ON CurCharges.Period = PreviousAccruals.Period
	|			AND CurCharges.Counterparty = PreviousAccruals.Counterparty
	|			AND CurCharges.Contract = PreviousAccruals.Contract
	|WHERE
	|	PreviousAccruals.Period IS NULL ";
	
EndFunction

&AtServer
Procedure AccrualsServer()
	
	// We will get a table of accruals according to the schedule
	QueryBuilder = New QueryBuilder(RequestTextForAccruals());
	QueryBuilder.Parameters.Insert("StartDate", StartDate);
	QueryBuilder.Parameters.Insert("EndDate", EndDate);
	QueryBuilder.Parameters.Insert("Organization", Organization);
	QueryBuilder.Parameters.Insert("Recorder", Recorder);
	QueryBuilder.Parameters.Insert("ContractKind",
		Catalogs.LoanAndDepositContracts.NatureOfTransactionAgreement(BusinessOperation));
	
	If ValueIsFilled(Partner) Then
		NewFilter = QueryBuilder.Filter.Add("Partner");
		NewFilter.Set(Partner);
	EndIf;
	
	If ValueIsFilled(Counterparty) Then
		NewFilter = QueryBuilder.Filter.Add("Counterparty");
		NewFilter.Set(Counterparty);
	EndIf;
	
	If ValueIsFilled(LoanDepositContract) Then
		NewFilter = QueryBuilder.Filter.Add("Contract");
		NewFilter.Set(LoanDepositContract);
	EndIf;
	
	If ValueIsFilled(EmployeeResponsible) Then
		NewFilter = QueryBuilder.Filter.Add("EmployeeResponsible");
		NewFilter.Set(EmployeeResponsible);
	EndIf;
	
	QueryBuilder.Execute();
	ScheduleAccruals = QueryBuilder.Result.Unload();
	Accruals = ScheduleAccruals.CopyColumns("Date,Partner,Counterparty,Contract,Department,LineOfBusiness,ARAPCurrency");
	
	TypesArray = New Array();
	Accruals.Columns.Add("IncomeAndExpenseItem",New TypeDescription("ChartOfCharacteristicTypesRef.IncomeItems,ChartOfCharacteristicTypesRef.ExpenseItems"));
	Accruals.Columns.Add("ScheduleAmountType",New TypeDescription("EnumRef.LoanAndDepositScheduleAmountTypes"));
	Accruals.Columns.Add("Sum",TMCommonUse.MoneyFieldTypeDescription());
	Accruals.Columns.Add("AmountARAP",TMCommonUse.MoneyFieldTypeDescription());
	
	// Let's move the accrual table according to the schedule to the tabular part of the document
	IncompleteContracts = New Map;
	EmptyIncomeItem = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	EmptyExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	For Each Page1 In ScheduleAccruals Do
		
		If Page1.Interests + Page1.Fee = 0 Then
			Continue;
		EndIf;
		
		If Page1.Interests > 0 Then
			
			NewRow = Accruals.Add();
			FillPropertyValues(NewRow,Page1);
			NewRow.IncomeAndExpenseItem = Page1.InterestArticle;
			NewRow.ScheduleAmountType = Enums.LoanAndDepositScheduleAmountTypes.Interests;
			NewRow.AmountARAP = Page1.Interests;
			
		EndIf;// there are percentages
		
		If Page1.Fee > 0 Then
			
			NewRow = Accruals.Add();
			FillPropertyValues(NewRow,Page1);
			NewRow.IncomeAndExpenseItem = Page1.CommissionArticle;
			NewRow.ScheduleAmountType = Enums.LoanAndDepositScheduleAmountTypes.Fee;
			NewRow.AmountARAP = Page1.Fee;
			
		EndIf;// there is a commission
		
	EndDo;// according to the accrual schedule
	
	AccrualAddressInTheStorage = PutToTempStorage(Accruals, UUID);
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	SetContractSelectionParameters();
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
