//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		Items.List.ChangeRowSet = False;
		
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ItemsNames = New Array; // Array of String
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		
		ItemsNames.Add(Items.FilterOrganization.Name);
		ItemsNames.Add(Items.CompanySelectionForRegistration.Name);
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		
		ItemsNames.Add(Items.CurrencySelectionForRegistration.Name);
		
	EndIf;
	
	If Not AccessRight("Insert", Metadata.Documents.CustomerBonusCertificate) Then
		
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		ItemsNames.Add(Items.DocumentsForRegistrationPage.Name);
		ItemsNames.Add(Items.GroupQuickSelectionsForRegistration.Name);
		ItemsNames.Add(Items.DateOfFormationOfDocuments.Name);
		ItemsNames.Add(Items.CompanySelectionForRegistration.Name);
		ItemsNames.Add(Items.CounterpartySelectionForRegistration.Name);
		ItemsNames.Add(Items.CurrencySelectionForRegistration.Name);
		ItemsNames.Add(Items.SummaryByCounterparty.Name);
		ItemsNames.Add(Items.TheListForRegistrationIssueDocument.Name);
		ItemsNames.Add(Items.TheListForRegistration.Name);
		
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemsNames, "Visible", False);
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Organization", Organization, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "Organization", "Visible", Not ValueIsFilled(Organization));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "Status", Status, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "Status", "Visible", Not ValueIsFilled(Status));
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
		List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	CommonClientServer.SetFormItemProperty(
		Items, "EmployeeResponsible", "Visible", Not ValueIsFilled(EmployeeResponsible));
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	DateOfFormationOfDocuments = CurrentSessionDate();
	
	SetPropertiesOfDynamicListToLayout();
	BoundaryOfResidues = UpdateDate();
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration, "BoundaryOfResidues", BoundaryOfResidues);
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Organization", Organization, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "Status", Status, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(
		List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_CustomerBonusCertificate" Then
		
		Items.TheListForRegistration.Refresh();
		
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	CompanyIsFull = ValueIsFilled(Organization);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		CompanyIsFull);
	
	CommonClientServer.SetFormItemProperty(
		Items, "Organization", "Visible", Not CompanyIsFull);
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	StatusFilledIn = ValueIsFilled(Status);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Status,
		DataCompositionComparisonType.Equal,
		,
		StatusFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "Status", "Visible", Not StatusFilledIn);
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	ResponsiblePersonFilledIn = ValueIsFilled(EmployeeResponsible);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"EmployeeResponsible",
		EmployeeResponsible,
		DataCompositionComparisonType.Equal,
		,
		ResponsiblePersonFilledIn);
	
	CommonClientServer.SetFormItemProperty(
		Items, "EmployeeResponsible", "Visible", Not ResponsiblePersonFilledIn);
	
EndProcedure

&AtClient
Procedure CompanySelectionForRegistrationOnChange(Item)
	
	CompanyIsFull = ValueIsFilled(CompanySelectionForRegistration);
	
	CommonClientServer.SetDynamicListFilterItem(
		TheListForRegistration,
		"Organization",
		CompanySelectionForRegistration,
		DataCompositionComparisonType.Equal,
		,
		CompanyIsFull);
	
EndProcedure

&AtClient
Procedure CounterpartySelectionForRegistrationOnChange(Item)
	
	CounterpartyIsFull = ValueIsFilled(CounterpartySelectionForRegistration);
	
	CommonClientServer.SetDynamicListFilterItem(
		TheListForRegistration,
		"Counterparty",
		CounterpartySelectionForRegistration,
		DataCompositionComparisonType.Equal,
		,
		CounterpartyIsFull);
	
EndProcedure

&AtClient
Procedure CurrencySelectionForRegistrationOnChange(Item)
	
	CurrencyIsFull = ValueIsFilled(CurrencySelectionForRegistration);
	
	CommonClientServer.SetDynamicListFilterItem(
		TheListForRegistration,
		"Currency",
		CurrencySelectionForRegistration,
		DataCompositionComparisonType.Equal,
		,
		CurrencyIsFull);
	
EndProcedure

&AtClient
Procedure DateOfFormationOfDocumentsOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfFormationOfDocumentsOnChangeServer();
	
EndProcedure

&AtClient
Procedure SummaryByCounterpartyOnChange(Item)
	
	SummaryByCounterpartyOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure IssueDocument(Command)
	
	Cancel = False;
	ClearMessages();
	
	If DateOfFormationOfDocuments = Date(1, 1, 1) Then
		
		FieldKind = "Field";
		MessageKind = "FillType";
		
		FieldName = NStr("vi = 'Ngày lập chứng từ';
						|ru = 'Дата формирования документов';
						|en = 'Document creation date'; fa = 'تاریخ ایجاد سند';
						|it = 'Дата формирования документов';
						|pl = 'Document creation date';
						|tr = 'Belge oluşturma tarihi'");
		MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
		CommonClient.MessageToUser(MessageText,, "DateOfFormationOfDocuments",, Cancel);
		
	EndIf;
	
	CurrentData = Items.TheListForRegistration.CurrentData; // FormDataStructure
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Chưa chọn dòng số dư để lập chứng từ';
							|ru = 'Не выбрана строка остатков для оформления документа';
							|en = 'Balance line for the document registration is not selected'; fa = 'Balance line for the document registration is not selected';
							|it = 'Не выбрана строка остатков для оформления документа';
							|pl = 'Balance line for the document registration is not selected';
							|tr = 'Belge oluşturma işlemi için bakiye satırı seçilmedi'");
		CommonClient.MessageToUser(MessageText,, "TheListForRegistration",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		
		If SummaryByCounterparty Then
			PartnerToFillIn = PredefinedValue("Catalog.Partners.EmptyRef");
		Else
			PartnerToFillIn = CurrentData.Partner;
		EndIf;
		
		FillingData = New Structure;
		FillingData.Insert("Organization", CurrentData.Organization);
		FillingData.Insert("Date", DateOfFormationOfDocuments);
		FillingData.Insert("Counterparty", CurrentData.Counterparty);
		FillingData.Insert("DocumentCurrency", CurrentData.Currency);
		FillingData.Insert("ARAPCurrency", CurrentData.Currency);
		FillingData.Insert("Partner", PartnerToFillIn);
		FillingData.Insert("FillingByBalances", True);
		
		FormParameters = New Structure;
		FormParameters.Insert("FillingValues", FillingData);
		
		OpenForm("Document.CustomerBonusCertificate.Form.DocumentForm", FormParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure SummaryByCounterpartyOnChangeServer()
	
	SetPropertiesOfDynamicListToLayout();
	
	Items.TheListForRegistrationPartner.Visible = Not SummaryByCounterparty;
	
EndProcedure

&AtServer
Procedure DateOfFormationOfDocumentsOnChangeServer()
	
	BoundaryOfResidues = UpdateDate();
	
	CommonClientServer.SetDynamicListParameter(
		TheListForRegistration, "BoundaryOfResidues", BoundaryOfResidues);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetPropertiesOfDynamicListToLayout()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = DynamicListQueryText1();
	ListProperties.MainTable = "AccumulationRegister.CustomerRebates.Balance";
	ListProperties.DynamicDataRead = False;
	Common.SetDynamicListProperties(Items.TheListForRegistration, ListProperties);
	
	SetSortingOfListOfDocumentsForRegistration();
	
EndProcedure

&AtServer
Function DynamicListQueryText1()
	
	If SummaryByCounterparty Then
		
		QueryText =
		"SELECT ALLOWED
		|	BalancesAsOfDate.Organization AS Organization,
		|	BalancesAsOfDate.Counterparty AS Counterparty,
		|	BalancesAsOfDate.Currency AS Currency,
		|	CASE
		|		WHEN SUM(BalancesAsOfDate.AmountBonusBalance - BalancesAsOfDate.ToCertifyBalance - BalancesAsOfDate.ToSignBalance - BalancesAsOfDate.ToWriteOffBalance) > SUM(RemainsEnd.AmountBonusBalance - RemainsEnd.ToCertifyBalance - RemainsEnd.ToSignBalance - RemainsEnd.ToWriteOffBalance)
		|			THEN SUM(RemainsEnd.AmountBonusBalance - RemainsEnd.ToCertifyBalance - RemainsEnd.ToSignBalance - RemainsEnd.ToWriteOffBalance)
		|		ELSE SUM(BalancesAsOfDate.AmountBonusBalance - BalancesAsOfDate.ToCertifyBalance - BalancesAsOfDate.ToSignBalance - BalancesAsOfDate.ToWriteOffBalance)
		|	END AS Sum,
		|	"""" AS Indent
		|{SELECT
		|	Organization.*,
		|	Counterparty.*,
		|	Currency.*,
		|	Sum,
		|	Indent}
		|FROM
		|	AccumulationRegister.CustomerRebates.Balance(&BoundaryOfResidues, {(Organization) AS Organization, (Counterparty) AS Counterparty, (Currency) AS Currency}) AS BalancesAsOfDate
		|		INNER JOIN AccumulationRegister.CustomerRebates.Balance(, {(Organization) AS Organization, (Counterparty) AS Counterparty, (Currency) AS Currency}) AS RemainsEnd
		|		ON BalancesAsOfDate.Organization = RemainsEnd.Organization
		|			AND BalancesAsOfDate.Counterparty = RemainsEnd.Counterparty
		|			AND BalancesAsOfDate.Currency = RemainsEnd.Currency
		|			AND BalancesAsOfDate.BeginOfPeriod = RemainsEnd.BeginOfPeriod
		|			AND BalancesAsOfDate.PeriodEnding = RemainsEnd.PeriodEnding
		|			AND BalancesAsOfDate.TermDocument = RemainsEnd.TermDocument
		|
		|GROUP BY
		|	BalancesAsOfDate.Organization,
		|	BalancesAsOfDate.Counterparty,
		|	BalancesAsOfDate.Currency
		|
		|HAVING
		|	SUM(BalancesAsOfDate.AmountBonusBalance - BalancesAsOfDate.ToCertifyBalance - BalancesAsOfDate.ToSignBalance - BalancesAsOfDate.ToWriteOffBalance) > 0 AND
		|	SUM(RemainsEnd.AmountBonusBalance - RemainsEnd.ToCertifyBalance - RemainsEnd.ToSignBalance - RemainsEnd.ToWriteOffBalance) > 0";
		
	Else
		
		QueryText =
		"SELECT ALLOWED
		|	BalancesAsOfDate.Organization AS Organization,
		|	BalancesAsOfDate.Counterparty AS Counterparty,
		|	BalancesAsOfDate.Partner AS Partner,
		|	BalancesAsOfDate.Currency AS Currency,
		|	CASE
		|		WHEN SUM(BalancesAsOfDate.AmountBonusBalance - BalancesAsOfDate.ToCertifyBalance - BalancesAsOfDate.ToSignBalance - BalancesAsOfDate.ToWriteOffBalance) > SUM(RemainsEnd.AmountBonusBalance - RemainsEnd.ToCertifyBalance - RemainsEnd.ToSignBalance - RemainsEnd.ToWriteOffBalance)
		|			THEN SUM(RemainsEnd.AmountBonusBalance - RemainsEnd.ToCertifyBalance - RemainsEnd.ToSignBalance - RemainsEnd.ToWriteOffBalance)
		|		ELSE SUM(BalancesAsOfDate.AmountBonusBalance - BalancesAsOfDate.ToCertifyBalance - BalancesAsOfDate.ToSignBalance - BalancesAsOfDate.ToWriteOffBalance)
		|	END AS Sum,
		|	"""" AS Indent
		|{SELECT
		|	Organization.*,
		|	Counterparty.*,
		|	Partner.*,
		|	Currency.*,
		|	Sum,
		|	Indent}
		|FROM
		|	AccumulationRegister.CustomerRebates.Balance(&BoundaryOfResidues, {(Organization) AS Organization, (Counterparty) AS Counterparty, (Currency) AS Currency}) AS BalancesAsOfDate
		|		INNER JOIN AccumulationRegister.CustomerRebates.Balance(, {(Organization) AS Organization, (Counterparty) AS Counterparty, (Currency) AS Currency}) AS RemainsEnd
		|		ON BalancesAsOfDate.Organization = RemainsEnd.Organization
		|			AND BalancesAsOfDate.Counterparty = RemainsEnd.Counterparty
		|			AND BalancesAsOfDate.Partner = RemainsEnd.Partner
		|			AND BalancesAsOfDate.Currency = RemainsEnd.Currency
		|			AND BalancesAsOfDate.BeginOfPeriod = RemainsEnd.BeginOfPeriod
		|			AND BalancesAsOfDate.PeriodEnding = RemainsEnd.PeriodEnding
		|			AND BalancesAsOfDate.TermDocument = RemainsEnd.TermDocument
		|
		|GROUP BY
		|	BalancesAsOfDate.Organization,
		|	BalancesAsOfDate.Counterparty,
		|	BalancesAsOfDate.Partner,
		|	BalancesAsOfDate.Currency
		|
		|HAVING
		|	SUM(BalancesAsOfDate.AmountBonusBalance - BalancesAsOfDate.ToCertifyBalance - BalancesAsOfDate.ToSignBalance - BalancesAsOfDate.ToWriteOffBalance) > 0 AND
		|	SUM(RemainsEnd.AmountBonusBalance - RemainsEnd.ToCertifyBalance - RemainsEnd.ToSignBalance - RemainsEnd.ToWriteOffBalance) > 0";
		
	EndIf;
		
	Return QueryText;
	
EndFunction

&AtServer
Procedure SetSortingOfListOfDocumentsForRegistration()
	
	TheListForRegistration.Order.Items.Clear();
	
	OrderItem = TheListForRegistration.Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Organization");
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
	OrderItem = TheListForRegistration.Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Counterparty");
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
	If Not SummaryByCounterparty Then
		
		OrderItem = TheListForRegistration.Order.Items.Add(Type("DataCompositionOrderItem"));
		OrderItem.Field = New DataCompositionField("Partner");
		OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		OrderItem.OrderType = DataCompositionSortDirection.Asc;
		OrderItem.Use = True;
		
	EndIf;
	
	OrderItem = TheListForRegistration.Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Currency");
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
	OrderItem = TheListForRegistration.Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Sum");
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.Use = True;
	
EndProcedure

// Returns:
//  Date, Boundary - Current date
//
&AtServer
Function UpdateDate()
	
	If ValueIsFilled(DateOfFormationOfDocuments) Then
		
		Result = New Boundary(EndOfDay(DateOfFormationOfDocuments), BoundaryType.Including);
		
	Else
		
		Result = Date(1, 1, 1);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure

// End StandardSubsystems.AttachableCommands

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
	If Item.Name = "sh_ShamsiInput_F_DateOfFormationOfDocuments" Then
		DateOfFormationOfDocumentsOnChange(Items.DateOfFormationOfDocuments);
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
