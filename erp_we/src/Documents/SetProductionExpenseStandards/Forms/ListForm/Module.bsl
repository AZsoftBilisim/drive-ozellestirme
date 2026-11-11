#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	Period = BegOfMonth(CurrentSessionDate());
	NumberOfMonths = 3;
	
	#Region Filters
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Organization", Organization, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	
	#EndRegion
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.AttachableCommands
	
	AttachableCommands.OnCreateAtServer(ThisObject);
	
	// End StandardSubsystems.AttachableCommands
	#EndRegion
	
	MonthLine = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(CurrentSessionDate());	
	FillInStandards();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ToDoListOverridable.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Var FiltersStructure;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("Department") Then
			Settings.Insert("Department", FiltersStructure.Department)
		EndIf;
		
		If FiltersStructure.Property("Organization") Then
			Settings.Insert("Organization", FiltersStructure.Organization)
		EndIf;
		
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", Department, QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", Organization, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	
EndProcedure

&AtClient
Procedure SelectingAnOrganizationToInstallOnChange(Item)

	FillInStandards();
	
EndProcedure

&AtClient
Procedure FilterStateOnChange(Item)
	
	FillInStandards();
	
EndProcedure

&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	Notification = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	TMCommonUseClient.StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, Period, ThisForm, Notification);
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
		
	EndIf;
	
	FillInStandards();
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	Period = AddMonth(Period, Direction);
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	
	FillInStandards();
	
EndProcedure

&AtClient
Procedure MonthLineClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure NumberOfMonthsOnChange(Item)
	
	FillInStandards();
	
EndProcedure

&AtClient
Procedure StandardsToSetSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = StandardsToSet.FindByID(RowSelected);
	
	If ValueIsFilled(CurrentData.Ref) Then
		ShowValue(, CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region ListEventHandlers_

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


#Region Universal_

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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ProductionExpenseStandards(Command)
	
	If Items.FormPages.CurrentPage = Items.ForSetting Then
		
		CurrentData = Items.StandardsToSet.CurrentData;
		PeriodParameter = New StandardPeriod(AddMonth(Period, -NumberOfMonths), EndOfMonth(Period));
		
	Else
		
		CurrentData = Items.List.CurrentData;
		EndOfPeriod = CurrentData.ValidityEndDate;
		If Not ValueIsFilled(EndOfPeriod) Then
			EndOfPeriod = EndOfYear(CurrentData.ValidityStartDate);
		EndIf;
		
		PeriodParameter = New StandardPeriod(CurrentData.ValidityStartDate, EndOfPeriod);
		
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("StandardPeriod", PeriodParameter);
	Filter.Insert("Organization", CurrentData.Organization);
	Filter.Insert("Department", CurrentData.Department);
	
	FormParameters = New Structure("VariantKey, PurposeUseKey, Filter, GenerateOnOpen, ReportOptionsCommandsVisibility");
	FormParameters.Insert("PurposeUseKey",		Undefined);
	FormParameters.Insert("Filter",							Filter);
	FormParameters.Insert("GenerateOnOpen",			True);
	FormParameters.Insert("ReportOptionsCommandsVisibility",	False);
	
	OpenForm("Report.PlannedAndActualProductionExpenseStandards.Form", FormParameters);
	
EndProcedure

#EndRegion

&AtClient
Procedure ToSetStandards(Command)
	
	CurrentData = Items.StandardsToSet.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("Organization", CurrentData.Organization);
	FillParameters.Insert("Department", CurrentData.Department);
	FillParameters.Insert("ValidityStartDate", Period);
	FillParameters.Insert("NumberOfMonths", NumberOfMonths);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillParameters);
	
	OpenForm("Document.SetProductionExpenseStandards.Form.DocumentForm", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");
	
	// The standards are overdue.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardsToSetCompletion.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardsToSetStateOfStandards.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StandardsToSet.StateOfStandards");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Overdue_1";
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);
	
	// The standards are indefinite.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardsToSetCompletion.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StandardsToSet.StateOfStandards");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Installed_";
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StandardsToSet.ValidTo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không giới hạn';
													|ru = 'Бессрочно';
													|en = 'Permanent'; fa = 'دائمی';
													|it = 'A tempo indefinito';
													|pl = 'Permanent';
													|tr = 'Süresiz'"));
	
	// Representation of the "Not installed" status.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardsToSetStateOfStandards.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StandardsToSet.StateOfStandards");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "NotInstalled_";
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chưa đặt';
													|ru = 'Не установлены';
													|en = 'Not set'; fa = 'تنظیم نشده';
													|it = 'Non impostati';
													|pl = 'Nie ustawione';
													|tr = 'Yapılandırılmadı'"));
	
EndProcedure

&AtServer
Procedure FillInStandards()
	
	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	OtherExpensesTurnover.Organization AS Organization,
		|	OtherExpensesTurnover.Department AS Department
		|INTO Expenses
		|FROM
		|	AccumulationRegister.OtherWorkInProgressExpenses.Turnovers(
		|			&BeginOfPeriod,
		|			&PeriodEnding,
		|			,
		|			ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToProductionCosts)
		|				AND (Organization = &Organization
		|					OR &ByAllCompanies)) AS OtherExpensesTurnover
		|WHERE
		|	OtherExpensesTurnover.CostReceipt > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	MAX(Standards.Date) AS Date,
		|	Standards.Organization AS Organization,
		|	Standards.Department AS Department
		|INTO MaximumDatesForSettingStandards
		|FROM
		|	Document.SetProductionExpenseStandards AS Standards
		|WHERE
		|	Standards.ValidityStartDate <= &Period
		|	AND NOT Standards.DeletionMark
		|	AND (Standards.Organization = &Organization
		|			OR &ByAllCompanies)
		|
		|GROUP BY
		|	Standards.Organization,
		|	Standards.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MaximumDatesForSettingStandards.Organization AS Organization,
		|	MaximumDatesForSettingStandards.Department AS Department,
		|	MAX(Standards.Ref) AS Ref
		|INTO CurrentRegulatoryDocuments
		|FROM
		|	MaximumDatesForSettingStandards AS MaximumDatesForSettingStandards
		|		INNER JOIN Document.SetProductionExpenseStandards AS Standards
		|		ON MaximumDatesForSettingStandards.Date = Standards.Date
		|			AND MaximumDatesForSettingStandards.Organization = Standards.Organization
		|			AND MaximumDatesForSettingStandards.Department = Standards.Department
		|			AND (NOT Standards.DeletionMark)
		|
		|GROUP BY
		|	MaximumDatesForSettingStandards.Organization,
		|	MaximumDatesForSettingStandards.Department
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(CurrentDocumentsByPeriod.Organization, Expenses.Organization) AS Organization,
		|	ISNULL(CurrentDocumentsByPeriod.Department, Expenses.Department) AS Department,
		|	ISNULL(SetProductionExpenseStandards.ValidityEndDate, DATETIME(1, 1, 1)) AS ValidTo,
		|	CASE
		|		WHEN SetProductionExpenseStandards.ValidityEndDate IS NULL
		|			THEN ""NotInstalled_""
		|		WHEN SetProductionExpenseStandards.ValidityEndDate < &Period
		|				AND NOT SetProductionExpenseStandards.ValidityEndDate = DATETIME(1, 1, 1)
		|			THEN ""Overdue_1""
		|		ELSE ""Installed_""
		|	END AS StateOfStandards,
		|	CASE
		|		WHEN Expenses.Organization IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreExpenses,
		|	SetProductionExpenseStandards.Ref AS Ref
		|FROM
		|	Expenses AS Expenses
		|		FULL JOIN CurrentRegulatoryDocuments AS CurrentDocumentsByPeriod
		|		ON Expenses.Organization = CurrentDocumentsByPeriod.Organization
		|			AND Expenses.Department = CurrentDocumentsByPeriod.Department
		|		LEFT JOIN Document.SetProductionExpenseStandards AS SetProductionExpenseStandards
		|		ON CurrentDocumentsByPeriod.Ref = SetProductionExpenseStandards.Ref
		|WHERE
		|	(CASE
		|				WHEN SetProductionExpenseStandards.ValidityEndDate IS NULL
		|					THEN ""NotInstalled_""
		|				WHEN SetProductionExpenseStandards.ValidityEndDate < &Period
		|						AND NOT SetProductionExpenseStandards.ValidityEndDate = DATETIME(1, 1, 1)
		|					THEN ""Overdue_1""
		|				ELSE ""Installed_""
		|			END = &State
		|			OR &AcrossAllStates)";
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("BeginOfPeriod", AddMonth(Period, -NumberOfMonths));
	Query.SetParameter("PeriodEnding", New Boundary(EndOfMonth(Period), BoundaryType.Including));
	Query.SetParameter("Organization", SelectingAnOrganizationToInstall);
	Query.SetParameter("ByAllCompanies", Not ValueIsFilled(SelectingAnOrganizationToInstall));
	Query.SetParameter("State", FilterState);
	Query.SetParameter("AcrossAllStates", Not ValueIsFilled(FilterState));
	
	StandardsToSet.Load(Query.Execute().Unload());
	
EndProcedure

#EndRegion
