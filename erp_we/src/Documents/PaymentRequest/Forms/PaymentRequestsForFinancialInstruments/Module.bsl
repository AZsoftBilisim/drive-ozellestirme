
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	RequestsIsAvailable = AccessRight("Edit", Metadata.Documents.PaymentRequest);
	
	If Not RequestsIsAvailable Then
		Items.TheListOfOrdersToCreateApplications.Enabled = False;
		Items.List.Visible = False;
	Else
		StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	EndIf;
	
	InitializeBankingDetails();
	
	SetDynamicListSelection();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.ListCommandBar);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_PaymentRequest" Then
		Items.AmountDue.Refresh();
	EndIf;
	
	// Subsystem "Electronic documents"
	If EventName = "UpdateEdState" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	PlanningAreasFilter = Settings.Get("PlanningAreasFilter");
	InitializePlanningAreas();
	If PlanningAreasFilter <> Undefined Then
		For Each Area In PlanningAreasFilter Do
			If Area.Check Then
				ListArea = PlanningAreasFilter.FindByValue(Area.Value);
				If ListArea <> Undefined Then
					ListArea.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	PlanningAreasFilterPresentation = ListPresentation(PlanningAreasFilter);
	
	SetContractTypeRestriction();
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure PlanningAreasFilterStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		New Structure("TransactionList, Title", PlanningAreasFilter, NStr("vi = 'Công cụ tài chính';
																			|ru = 'Финансовые инструменты';
																			|en = 'Financial instruments'; fa = 'ابزارهای مالی';
																			|it = 'Strumenti finanziari';
																			|pl = 'Instrumenty finansowe';
																			|tr = 'Finansal araçlar'")), Item);
	
EndProcedure

&AtClient
Procedure PlanningAreasFilterClearing(Item, StandardProcessing)
	
	PlanningAreasFilter.FillChecks(False);
	
	SetContractTypeRestriction();
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure PlanningAreasFilterChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		PlanningAreasFilter = ValueSelected;
	Else
		For Each ListItem In PlanningAreasFilter Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	PlanningAreasFilterPresentation = ListPresentation(PlanningAreasFilter);
	
	ContractSelection = Undefined;
	SetContractTypeRestriction();
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure PaymentDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Boundary = ?(ValueIsFilled(PaymentDate), EndOfDay(PaymentDate), Date('39990101'));
	AmountDue.Parameters.SetParameterValue("PaymentDate", Boundary);
	
EndProcedure

&AtClient
Procedure ContractSelectionOnChange(Item)
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region EventHandlersForListElements

&AtClient
Procedure AmountDueSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	Ref = Item.CurrentData.Ref;
	If ValueIsFilled(Ref) Then
		ShowValue(, Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateRequests(Command)
	
	CashClient.PayChartLines(Items.AmountDue, "PaymentRequest");
	
EndProcedure

&AtClient
Procedure CreateALoanRequest(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived"));
	
EndProcedure

&AtClient
Procedure CreateADepositRequest(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.TransferToDeposits"));
	
EndProcedure

&AtClient
Procedure CreateARequestForLoansToACounterparty(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.CashIssueAsLoanToCounterparty"));
	
EndProcedure

&AtClient
Procedure CreateAPaymentToTheLandlord(Command)
	
	CreateRequestForSpendingMoney(PredefinedValue("Enum.BusinessTransactions.PaymentToLessor"));
	
EndProcedure

&AtClient
Procedure CreateRequestForSpendingMoney(BusinessOperation)
	
	Basis = New Structure("BusinessOperation", BusinessOperation);
	ParametersStructure1 = New Structure("Basis", Basis);
	OpenForm("Document.PaymentRequest.ObjectForm", ParametersStructure1, Items.List);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AmountDuePaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountDue.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
EndProcedure

&AtServer
Procedure InitializeBankingDetails()
	
	UseLoansDeposits = GetFunctionalOption("UseLoanAndDepositContracts");
	UseTheLease = NonCurrentAssets.VNAManagementIsUsed();
	AreasBusinessTransactionsTemp = New Map;
	AreasBusinessTransactionsTemp.Insert(Enums.PaymentPlanningAreas.LoansOrBorrowingsReceived, Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived);
	AreasBusinessTransactionsTemp.Insert(Enums.PaymentPlanningAreas.Deposits, Enums.BusinessTransactions.TransferToDeposits);
	AreasBusinessTransactionsTemp.Insert(Enums.PaymentPlanningAreas.IssuedBorrowings, Enums.BusinessTransactions.CashIssueAsLoanToCounterparty);
	AreasBusinessTransactionsTemp.Insert(Enums.PaymentPlanningAreas.Lease, Enums.BusinessTransactions.PaymentToLessor);
	AreasBusinessTransactions = New FixedMap(AreasBusinessTransactionsTemp);
	
	InitializePlanningAreas();
	
EndProcedure

&AtServer
Procedure InitializePlanningAreas()
	
	AreasList = New ValueList;
	
	If UseLoansDeposits Then
		AreasList.Add(Enums.PaymentPlanningAreas.LoansOrBorrowingsReceived);
		AreasList.Add(Enums.PaymentPlanningAreas.Deposits);
		AreasList.Add(Enums.PaymentPlanningAreas.IssuedBorrowings);
	EndIf;
	
	If UseTheLease Then
		AreasList.Add(Enums.PaymentPlanningAreas.Lease);
	EndIf;
	
	For Each PlanningAreaSelection In PlanningAreasFilter Do
		If PlanningAreaSelection.Check Then
			PlanningArea = AreasList.FindByValue(PlanningAreaSelection.Value);
			If PlanningArea <> Undefined Then
				PlanningArea.Check = True;
			EndIf;
		EndIf;
	EndDo;
	
	PlanningAreasFilter = AreasList;
	
	Items.PlanningAreasFilter.ChoiceList.Clear();
	For Each Area In PlanningAreasFilter Do
		Items.PlanningAreasFilter.ChoiceList.Add(Area.Value);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(CompanyFilter);
	
	If ValueIsFilled(CompanyFilter)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed
		|");
		Query.SetParameter("Organization", CompanyFilter);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		AmountDue,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(CompanyFilter));
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(CompanyFilter));
		
	Boundary = ?(ValueIsFilled(PaymentDate), EndOfDay(PaymentDate), Date('39990101'));
	AmountDue.Parameters.SetParameterValue("PaymentDate", Boundary);
	
	BsnsTransactions = New Array;
	PlanningAreas = New Array;
	AreasOfPaymentPlanningForHouseholdOperations = AreasBusinessTransactions; // FixedMap
	For Each ListItem In PlanningAreasFilter Do
		If ListItem.Check Then
			PlanningAreas.Add(ListItem.Value);
			ValueOfHouseholdOperation = AreasOfPaymentPlanningForHouseholdOperations.Get(ListItem.Value);
			BsnsTransactions.Add(ValueOfHouseholdOperation);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		AmountDue,
		"PlanningArea",
		PlanningAreas,
		DataCompositionComparisonType.InList,,
		PlanningAreas.Count());
		
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"BusinessOperation",
		BsnsTransactions,
		DataCompositionComparisonType.InList,,
		BsnsTransactions.Count());
		
	CommonClientServer.SetDynamicListFilterItem(
		AmountDue,
		"Ref",
		ContractSelection,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(ContractSelection));
	
EndProcedure

&AtServer
Procedure SetContractTypeRestriction()
	LoanAgreement = False;
	LeaseContracts = False;
	
	For Each Area In PlanningAreasFilter Do
		If Area.Check Then
			If Area.Value = Enums.PaymentPlanningAreas.Lease Then
				LeaseContracts = True;
			Else
				LoanAgreement = True;
			EndIf;
		EndIf;
	EndDo;
	If LoanAgreement And LeaseContracts
		Or Not LoanAgreement And Not LeaseContracts Then
		Items.ContractSelection.TypeRestriction = New TypeDescription("CatalogRef.LoanAndDepositContracts, CatalogRef.LeaseContract");
	ElsIf LoanAgreement Then
		Items.ContractSelection.TypeRestriction = New TypeDescription("CatalogRef.LoanAndDepositContracts");
	ElsIf LeaseContracts Then
		Items.ContractSelection.TypeRestriction = New TypeDescription("CatalogRef.LeaseContract");
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Function ListPresentation(List)
	
	ListPresentation = "";
	For Each ListItem In List Do
		If ListItem.Check Then
			ListPresentation = ListPresentation
				+ ?(ValueIsFilled(ListPresentation), ", ", "")
				+ ?(ValueIsFilled(ListItem.Presentation), ListItem.Presentation, ListItem.Value);
		EndIf;
	EndDo;
	
	Return ListPresentation;
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_PaymentDate" Then
		PaymentDateOnChange(Items.PaymentDate);
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
