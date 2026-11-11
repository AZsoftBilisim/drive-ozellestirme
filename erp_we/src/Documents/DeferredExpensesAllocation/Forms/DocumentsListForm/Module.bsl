
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = Documents.DeferredExpensesAllocation.QueryTextExpenseForAllocation();
	Common.SetDynamicListProperties(Items.ExpenseForAllocation,
		ListProperties);	
	
	If Parameters.Property("Organization") Then
		 Organization = Parameters.Organization;
		 ThisForm.Items.Pages.CurrentPage = Items.PageOfTheOrderForRegistration;
	EndIf;
	If Parameters.Property("RegistrationPeriod") Then
		 Period = BegOfMonth(Parameters.RegistrationPeriod);
	Else
		 Period = BegOfMonth(CurrentDate());
	EndIf;
	SetDynamicListSelection();
	SetParametersForDynamicLists();
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		DefaultCompany = Catalogs.Companies.DefaultCompany();
	EndIf;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	Items.ExpensesToBeAllocatedGroupToBeAllocatedUpr.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để phân bổ vào kế toán quản trị (%1)';
			|ru = 'К распределению в упр. учете (%1)';
			|en = 'For allocation in management accounting (%1)'; fa = 'For allocation in management accounting (%1)';
			|it = 'Da allocare in contabilità gestionale (%1)';
			|pl = 'Do przydzielenia w ewidencji zarządczej (%1)';
			|tr = 'Yönetim muhasebesinde dağıtım için (%1)'"),
		ManagementAccountingCurrency);
		
	SetDesignOfDynamicLists();
	SetConditionalAppearance();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	
	SetVisibilityAccessibilityOfElements();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_DeferredExpensesAllocation" Then
		Items.ExpenseForAllocation.Refresh();
	ElsIf EventName = "Write_ConstantsSet" Then
		SetVisibilityAccessibilityOfElements();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("Organization") Then
		 Organization = Parameters.Organization;
	Else 
		 Organization = Settings.Get("Organization");
	EndIf;
	
	If Parameters.Property("Department") Then
		 Department = Parameters.Department;
	Else 
		 Department = Settings.Get("Department");
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		Period = Parameters.RegistrationPeriod;
	ElsIf Settings.Get("Period") <> Undefined Then
		Period = Settings.Get("Period");
	EndIf;
	
	SetVisibilityAccessibilityOfElements();
	SetDesignOfDynamicLists();
	SetDynamicListSelection();
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetDesignOfDynamicLists();
	SetDynamicListSelection();
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	SetDynamicListSelection();
	SetParametersForDynamicLists();
	
EndProcedure


&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Period, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);

		SetParametersForDynamicLists();
	EndIf;
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		Period,
		MonthLine);
	SetParametersForDynamicLists();
	
EndProcedure

&AtClient
Procedure MonthLineClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.PageOfTheOrderForRegistration Then
		Items.ExpenseForAllocation.Refresh();
	EndIf;
	
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

&AtClient
Procedure CreateExpenseAllocation(Command)
	
	String = Items.ExpenseForAllocation.CurrentData;
	If String <> Undefined Then
		
		StructureBase = New Structure("Date, Organization, Department",
			Period,
			String.Organization,
			String.Department);
			
		StructureBase.Insert("Period", EndOfMonth(Period));
		StructureBase.Insert("ExpenseItem",     String.ExpenseItem);
		StructureBase.Insert("DimensionOfExpenses",  String.DimensionOfExpenses);
		StructureBase.Insert("LineOfBusiness", String.LineOfBusiness);
		StructureBase.Insert("DocumentAmount",     String.Sum);
		StructureBase.Insert("DocumentAmountManag",  String.SumMan);
		StructureBase.Insert("TheAmountOfTheDocumentRegl", String.SumCompl);
		StructureBase.Insert("DocumentAmountPD",   String.PermanentDifference);
		StructureBase.Insert("DocumentAmountTD",   String.CostTD);
		StructureBase.Insert("DocumentAmountAIT",  String.AITAmount);
		StructureBase.Insert("CostAllocationFromCostCenter", Not ValueIsFilled(String.ExpenseItem));
		
		ArticleParameters = New Structure;
		ArticleParameters.Insert("Period", Period);
		ArticleParameters.Insert("Organization",
			?(ValueIsFilled(String.Organization),
				String.Organization,
				DefaultCompany));
		ArticleParameters.Insert("Department", String.Department);
		ArticleParameters.Insert("ExpenseItem", String.ExpenseItem);
		ArticleParameters.Insert("DimensionOfExpenses", String.DimensionOfExpenses);
		ArticleParameters.Insert("LineOfBusiness", String.LineOfBusiness);
		StateOfDistribution = GetStateOfRBPDistribution(ArticleParameters);
		If StateOfDistribution = Undefined Then
			ErrorText = NStr("vi = 'Theo dòng được chọn đã nhập sai dữ liệu. 
			|Có thể là trong kỳ hiện tại đã nhập hơn một chứng từ phân bổ.';
			|ru = 'По выбранной строке внесены ошибочные данные. 
			|Возможно в текущем периоде введено более одного документа распределения.';
			|en = 'Invalid data is entered for the selected line. 
			|More than one allocation document may have been entered in the current period.'; fa = 'Invalid data is entered for the selected line. 
			|More than one allocation document may have been entered in the current period.';
			|it = 'Sono stati inseriti dati errati nella riga selezionata.
			|È possibile che nel periodo corrente siano inseriti più documenti di distribuzione.';
			|pl = 'Dla wybranego wiersza wprowadzono błędne dane. 
			|Możliwe, że w bieżącym okresie zostało wprowadzono więcej niż jeden dokument przydzielenia.';
			|tr = 'Seçilen satır için hatalı veri girildi. 
			|Geçerli dönemde birden fazla dağıtım belgesi girilmiş olabilir.'");
			CommonClient.MessageToUser(ErrorText, ThisObject, "ExpenseForAllocation");
		EndIf;
		
		SetOfRules = New Map();
		SetOfAccountingSections = New Structure();
		 
		If StateOfDistribution.ManagementAccounting 
			And Not ValueIsFilled(StateOfDistribution.DocumentMan) 
		Then
			SetOfAccountingSections.Insert("ManagementAccounting", True);
			If ValueIsFilled(StateOfDistribution.CostAllocationRuleManag) Then
				SetOfRules.Insert(StateOfDistribution.CostAllocationRuleManag);
			EndIf;
		Else
			SetOfAccountingSections.Insert("ManagementAccounting", False);
		EndIf;
		
		If StateOfDistribution.LocalAccounting 
			And Not ValueIsFilled(StateOfDistribution.DocumentCompl) 
		Then
			SetOfAccountingSections.Insert("LocalAccounting", True);
			If ValueIsFilled(StateOfDistribution.CostAllocationRuleLocal) Then
				SetOfRules.Insert(StateOfDistribution.CostAllocationRuleLocal);
			EndIf;
		Else
			SetOfAccountingSections.Insert("LocalAccounting", False);
		EndIf;
		If StateOfDistribution.TaxAccounting
			And Not ValueIsFilled(StateOfDistribution.DocumentTA) 
		Then
			SetOfAccountingSections.Insert("TaxAccounting", True);
			If ValueIsFilled(StateOfDistribution.CostAllocationRuleTax) Then
				SetOfRules.Insert(StateOfDistribution.CostAllocationRuleTax);
			EndIf;
		Else
			SetOfAccountingSections.Insert("TaxAccounting", False);
		EndIf;
		If SetOfRules.Count() <= 1 Then
			For Each Rule In SetOfRules Do
				StructureBase.Insert("RBPRule", Rule.Key);
			EndDo;
			For Each AccountingDimension In SetOfAccountingSections Do
				StructureBase.Insert(AccountingDimension.Key, AccountingDimension.Value);
			EndDo;
			ParametersStructure1 = New Structure;
			ParametersStructure1.Insert("Basis", StructureBase);
			OpenForm("Document.DeferredExpensesAllocation.ObjectForm", ParametersStructure1, Items.List);
		Else
			OpenForm("Document.DeferredExpensesAllocation.Form.SettingsSelectionForm", StateOfDistribution, Items.List, , , , 
				New CallbackDescription("CreateExpenseAllocationCompletion", ThisObject, StructureBase), FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenListOfDocumentsDistributionOfDeferredExpenses(Command)
	OpenForm("Document.DeferredExpensesAllocation.ListForm");
EndProcedure

&AtClient
Procedure OpenExpenseCard(Command)

	If Items.ExpenseForAllocation.CurrentData = Undefined Then
		Return
	EndIf;
	
	FieldsOfAccountingTypes = New Map;
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationSum", 0);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationSumMan", 2);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationSumCompl", 3);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationAmountFA", 4);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationPermanentDifference", 4);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationCostTD", 4);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationAITAmount", 4);
	
	ReportData = FieldsOfAccountingTypes.Get(Items.ExpenseForAllocation.CurrentItem.Name);
	
	ExplanationFormParameters = New Structure;
	ExplanationFormParameters.Insert("Organization", Items.ExpenseForAllocation.CurrentData.Organization);
	ExplanationFormParameters.Insert("Department", Items.ExpenseForAllocation.CurrentData.Department);
	ExplanationFormParameters.Insert("LineOfBusiness", Items.ExpenseForAllocation.CurrentData.LineOfBusiness);
	ExplanationFormParameters.Insert("ExpenseItem", Items.ExpenseForAllocation.CurrentData.ExpenseItem);
	ExplanationFormParameters.Insert("DimensionOfExpenses", Items.ExpenseForAllocation.CurrentData.DimensionOfExpenses);
	ExplanationFormParameters.Insert("AllocationOption", PredefinedValue("Enum.CostAllocationOptions.ToDeferredExpenses"));
	ExplanationFormParameters.Insert("Periodicity", 1);
	ExplanationFormParameters.Insert("PeriodOfEmphasis", New StandardPeriod(BegOfMonth(Period), EndOfMonth(Period)));
	
	If ReportData <> Undefined Then
		ExplanationFormParameters.Insert("ReportData", ReportData);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("Filter", ExplanationFormParameters);
	
	OpenForm("Report.ExpenseCard.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure OpenDeferredExpensesAnalysis(Command)

	If Items.ExpenseForAllocation.CurrentData = Undefined Then
		Return
	EndIf;
	
	FieldsOfAccountingTypes = New Map;
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationSum", 0);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationSumMan", 2);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationSumCompl", 3);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationAmountFA", 4);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationPermanentDifference", 4);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationCostTD", 4);
	FieldsOfAccountingTypes.Insert("ExpenseForAllocationAITAmount", 4);
	
	ReportData = FieldsOfAccountingTypes.Get(Items.ExpenseForAllocation.CurrentItem.Name);
	
	ExplanationFormParameters = New Structure;
	ExplanationFormParameters.Insert("Organization", Items.ExpenseForAllocation.CurrentData.Organization);
	ExplanationFormParameters.Insert("Department", Items.ExpenseForAllocation.CurrentData.Department);
	ExplanationFormParameters.Insert("LineOfBusiness", Items.ExpenseForAllocation.CurrentData.LineOfBusiness);
	ExplanationFormParameters.Insert("ExpenseItem", Items.ExpenseForAllocation.CurrentData.ExpenseItem);
	ExplanationFormParameters.Insert("DimensionOfExpenses", Items.ExpenseForAllocation.CurrentData.DimensionOfExpenses);
	ExplanationFormParameters.Insert("PeriodOfEmphasis", New StandardPeriod(BegOfMonth(Period), EndOfMonth(Period)));
	
	If ReportData <> Undefined Then
		ExplanationFormParameters.Insert("ReportData", ReportData);
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("GenerateOnOpen", True);
	FormParameters.Insert("Filter", ExplanationFormParameters);
	
	OpenForm("Report.DeferredExpenseAnalysis.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure SwitchToDisplayDifferences(Command)
	DisplayDifferences = Not DisplayDifferences;
	SetVisibilityAccessibilityOfElements();
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

#Region Other

&AtServer
Procedure SetParametersForDynamicLists()
	
	LStartDate = ?(ValueIsFilled(Period), BegOfMonth(Period), BegOfMonth(CurrentSessionDate()));
	LEndDate = ?(ValueIsFilled(Period), EndOfMonth(Period), EndOfMonth(CurrentSessionDate()));
	
	List.Parameters.SetParameterValue("StartDate", LStartDate);
	List.Parameters.SetParameterValue("EndDate", LEndDate);
	
	ExpenseForAllocation.Parameters.SetParameterValue("BeginOfPeriod", LStartDate);
	ExpenseForAllocation.Parameters.SetParameterValue("EndOfPeriod", LEndDate);
	ExpenseForAllocation.Parameters.SetParameterValue("Organization", Organization);
	ExpenseForAllocation.Parameters.SetParameterValue("ByAllCompanies", Not ValueIsFilled(Organization));
	ExpenseForAllocation.Parameters.SetParameterValue("Department", Department);
	ExpenseForAllocation.Parameters.SetParameterValue("ByAllBusinessUnits", Not ValueIsFilled(Department));
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", Organization, DataCompositionComparisonType.Equal,, ValueIsFilled(Organization));
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtServerNoContext
Function GetStateOfRBPDistribution(Parameters)
	
	Result = New Structure("
	|ManagementAccounting,CostAllocationRuleManag,DocumentMan,
	|TaxAccounting,CostAllocationRuleTax,DocumentTA,
	|LocalAccounting,CostAllocationRuleLocal,DocumentCompl
	|");
	
	QueryText = "SELECT
	|	
	|	ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS ManagementAccounting,
	|	ExpenseItems.CostAllocationRuleManag AS CostAllocationRuleManag,
	|	ISNULL(MaDocuments.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentMan,
	|
	|	ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS LocalAccounting,
	|	ExpenseItems.CostAllocationRuleLocal AS CostAllocationRuleLocal,
	|	ISNULL(RUDocuments.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentCompl
	|
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	
	|	LEFT JOIN Document.DeferredExpensesAllocation AS MaDocuments
	|	ON
	|		MaDocuments.ExpenseItem = ExpenseItems.Ref
	|		AND MaDocuments.Organization = &Organization
	|		AND MaDocuments.Department = &Department
	|		AND MaDocuments.DimensionOfExpenses = &DimensionOfExpenses
	|		AND MaDocuments.Date BETWEEN &StartDate AND &EndDate
	|		AND MaDocuments.ManagementAccounting
	|		AND MaDocuments.Posted
	|		AND MaDocuments.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|	
	|	LEFT JOIN Document.DeferredExpensesAllocation AS RUDocuments
	|	ON
	|		RUDocuments.ExpenseItem = ExpenseItems.Ref
	|		AND RUDocuments.Organization = &Organization
	|		AND RUDocuments.Department = &Department
	|		AND RUDocuments.DimensionOfExpenses = &DimensionOfExpenses
	|		AND RUDocuments.Date BETWEEN &StartDate AND &EndDate
	|		AND RUDocuments.LocalAccounting
	|		AND RUDocuments.Posted
	|		AND RUDocuments.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
	|	
	|WHERE
	|	ExpenseItems.Ref = &ExpenseItem";
	If ValueIsFilled(Parameters.ExpenseItem) Then
		QueryText = "SELECT
			|	
			|	ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS ManagementAccounting,
			|	ISNULL(SettingsByOrganizationAndDivision.SettingsManAccounting, ISNULL(OrganizationSettings.SettingsManAccounting, ExpenseItems.CostAllocationRuleManag)) AS CostAllocationRuleManag,
			|	ISNULL(MaDocuments.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentMan,
			|
			|	NOT &UseLocal OR ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS TaxAccounting,
			|	ISNULL(SettingsByOrganizationAndDivision.SettingsTaxAccounting, ISNULL(OrganizationSettings.SettingsTaxAccounting, ExpenseItems.CostAllocationRuleTax)) AS CostAllocationRuleTax,
			|	ISNULL(DocumentsTa.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentTA,
			|	
			|	ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS LocalAccounting,
			|	ISNULL(SettingsByOrganizationAndDivision.SettingsLocal, ISNULL(OrganizationSettings.SettingsLocal, ExpenseItems.CostAllocationRuleLocal)) AS CostAllocationRuleLocal,
			|	ISNULL(RUDocuments.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentCompl
			|
			|FROM
			|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
			|	
			|	LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS OrganizationSettings
			|	ON
			|		ExpenseItems.Ref = OrganizationSettings.ExpenseItem
			|		AND OrganizationSettings.Organization = &Organization
			|		AND (OrganizationSettings.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
			|	
			|	LEFT JOIN InformationRegister.SettingsOfItemizedExpensesAllocation AS SettingsByOrganizationAndDivision
			|	ON
			|		ExpenseItems.Ref = SettingsByOrganizationAndDivision.ExpenseItem
			|		AND SettingsByOrganizationAndDivision.Organization = &Organization
			|		AND SettingsByOrganizationAndDivision.Department = &Department
			|	
			|	LEFT JOIN Document.DeferredExpensesAllocation AS MaDocuments
			|	ON
			|		MaDocuments.ExpenseItem = ExpenseItems.Ref
			|		AND MaDocuments.Organization = &Organization
			|		AND MaDocuments.Department = &Department
			|		AND MaDocuments.DimensionOfExpenses = &DimensionOfExpenses
			|		AND MaDocuments.LineOfBusiness = &LineOfBusiness
			|		AND MaDocuments.Date BETWEEN &StartDate AND &EndDate
			|		AND MaDocuments.ManagementAccounting
			|		AND MaDocuments.Posted
			|		AND MaDocuments.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
			|	
			|	LEFT JOIN Document.DeferredExpensesAllocation AS DocumentsTa
			|	ON
			|		DocumentsTa.ExpenseItem = ExpenseItems.Ref
			|		AND DocumentsTa.Organization = &Organization
			|		AND DocumentsTa.Department = &Department
			|		AND DocumentsTa.DimensionOfExpenses = &DimensionOfExpenses
			|		AND DocumentsTa.LineOfBusiness = &LineOfBusiness
			|		AND DocumentsTa.Date BETWEEN &StartDate AND &EndDate
			|		AND DocumentsTa.TaxAccounting
			|		AND DocumentsTa.Posted
			|		AND DocumentsTa.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
			|	
			|	LEFT JOIN Document.DeferredExpensesAllocation AS RUDocuments
			|	ON
			|		RUDocuments.ExpenseItem = ExpenseItems.Ref
			|		AND RUDocuments.Organization = &Organization
			|		AND RUDocuments.Department = &Department
			|		AND RUDocuments.DimensionOfExpenses = &DimensionOfExpenses
			|		AND RUDocuments.LineOfBusiness = &LineOfBusiness
			|		AND RUDocuments.Date BETWEEN &StartDate AND &EndDate
			|		AND RUDocuments.LocalAccounting
			|		AND RUDocuments.Posted
			|		AND RUDocuments.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
			|	
			|WHERE
			|	ExpenseItems.Ref = &ExpenseItem";
		
	Else

		QueryText = "SELECT
			|	
			|	ExpenseItems.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS ManagementAccounting,
			|	ExpenseItems.CostAllocationRuleManag AS CostAllocationRuleManag,
			|	ISNULL(MaDocuments.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentMan,
			|
			|	NOT &UseLocal OR ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS TaxAccounting,
			|	ExpenseItems.CostAllocationRuleTax AS CostAllocationRuleTax,
			|	ISNULL(DocumentsTa.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentTA,
			|	
			|	ExpenseItems.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToDeferredExpenses) AS LocalAccounting,
			|	ExpenseItems.CostAllocationRuleLocal AS CostAllocationRuleLocal,
			|	ISNULL(RUDocuments.Ref, VALUE(Document.DeferredExpensesAllocation.EmptyRef)) AS DocumentCompl
			|
			|FROM
			|	Catalog.CostCenters AS ExpenseItems
			|	
			|	LEFT JOIN Document.DeferredExpensesAllocation AS MaDocuments
			|	ON
			|		MaDocuments.DimensionOfExpenses = ExpenseItems.Ref
			|		AND MaDocuments.Organization = &Organization
			|		AND MaDocuments.Department = &Department
			|		AND MaDocuments.Date BETWEEN &StartDate AND &EndDate
			|		AND MaDocuments.ManagementAccounting
			|		AND MaDocuments.Posted
			|	
			|	LEFT JOIN Document.DeferredExpensesAllocation AS DocumentsTa
			|	ON
			|		DocumentsTa.DimensionOfExpenses = ExpenseItems.Ref
			|		AND DocumentsTa.Organization = &Organization
			|		AND DocumentsTa.Department = &Department
			|		AND DocumentsTa.Date BETWEEN &StartDate AND &EndDate
			|		AND DocumentsTa.TaxAccounting
			|		AND DocumentsTa.Posted
			|	
			|	LEFT JOIN Document.DeferredExpensesAllocation AS RUDocuments
			|	ON
			|		RUDocuments.DimensionOfExpenses = ExpenseItems.Ref
			|		AND RUDocuments.Organization = &Organization
			|		AND RUDocuments.Department = &Department
			|		AND RUDocuments.Date BETWEEN &StartDate AND &EndDate
			|		AND RUDocuments.LocalAccounting
			|		AND RUDocuments.Posted
			|	
			|WHERE
			|	ExpenseItems.Ref = &DimensionOfExpenses";
	EndIf;
	Query = New Query(QueryText);
	Query.SetParameter("StartDate", BegOfMonth(Parameters.Period));
	Query.SetParameter("EndDate", EndOfMonth(Parameters.Period));
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Department", Parameters.Department);
	Query.SetParameter("ExpenseItem", Parameters.ExpenseItem);
	Query.SetParameter("DimensionOfExpenses", Parameters.DimensionOfExpenses);
	Query.SetParameter("LineOfBusiness", Parameters.LineOfBusiness);
	Query.SetParameter("UseLocal", GetFunctionalOption("UseLocal"));
	Selection = Query.Execute().Select();
	If Not Selection.Next() Or Selection.Count() > 1 Then
		Return Undefined;
	Else
		FillPropertyValues(Result, Selection);
		Return Result;
	EndIf;
	
EndFunction

&AtClient
Procedure CreateExpenseAllocationCompletion(CreationParameters, AdditionalParameters) Export
	
	If CreationParameters <> Undefined Then
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("Basis", AdditionalParameters);
		CommonClientServer.SupplementStructure(AdditionalParameters, CreationParameters);
		OpenForm("Document.DeferredExpensesAllocation.ObjectForm", ParametersStructure1, Items.List);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ExpenseForAllocationExpenseItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ExpenseForAllocation.ExpenseItem");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
		Item.Appearance.SetParameterValue("Text",  NStr("vi = '<Trong khuôn khổ SXDD>';
														|ru = '<В рамках ОВЗ>';
														|en = '<Within cost center>'; fa = '<Within cost center>';
														|it = '<Nell''ambito del CdC>';
														|pl = '<W ramach obiektu tworzenia się rozchodów>';
														|tr = '<MOM kapsamında>'"));
		Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	EndIf;
	// Man
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Không cần thiết >';
													|ru = '< Не требуется >';
													|en = '< Not required >'; fa = '< Not required >';
													|it = '< Non si necessita >';
													|pl = '< Nie jest wymagane >';
													|tr = '< Gerekli değil >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Cần tự động >';
													|ru = '< Требуется авто >';
													|en = '< Auto is required >'; fa = '< خودکار الزامی است >';
													|it = '< Richiesto automatico >';
													|pl = '< Wymagane jest auto >';
													|tr = '< Otomatik gerekli >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.HelpText);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Sum");
	ElementSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EverythingIsDistributedAmount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SumMan");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountOfUprStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Không cần thiết >';
													|ru = '< Не требуется >';
													|en = '< Not required >'; fa = '< Not required >';
													|it = '< Non si necessita >';
													|pl = '< Nie jest wymagane >';
													|tr = '< Gerekli değil >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SumMan");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountOfUprStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Cần tự động >';
													|ru = '< Требуется авто >';
													|en = '< Auto is required >'; fa = '< خودکار الزامی است >';
													|it = '< Richiesto automatico >';
													|pl = '< Wymagane jest auto >';
													|tr = '< Otomatik gerekli >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.HelpText);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SumMan");
	ElementSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EverythingIsDistributedAmountMA");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountOfUprStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
// Compl
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SumCompl");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountReglStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Không cần thiết >';
													|ru = '< Не требуется >';
													|en = '< Not required >'; fa = '< Not required >';
													|it = '< Non si necessita >';
													|pl = '< Nie jest wymagane >';
													|tr = '< Gerekli değil >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SumCompl");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountReglStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Cần tự động >';
													|ru = '< Требуется авто >';
													|en = '< Auto is required >'; fa = '< خودکار الزامی است >';
													|it = '< Richiesto automatico >';
													|pl = '< Wymagane jest auto >';
													|tr = '< Otomatik gerekli >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.HelpText);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("SumCompl");
	ElementSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EverythingIsDistributedAmountLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountReglStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
// TA
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AmountFA");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountAndStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Không cần thiết >';
													|ru = '< Не требуется >';
													|en = '< Not required >'; fa = '< Not required >';
													|it = '< Non si necessita >';
													|pl = '< Nie jest wymagane >';
													|tr = '< Gerekli değil >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AmountFA");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountAndStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Cần tự động >';
													|ru = '< Требуется авто >';
													|en = '< Auto is required >'; fa = '< خودکار الزامی است >';
													|it = '< Richiesto automatico >';
													|pl = '< Wymagane jest auto >';
													|tr = '< Otomatik gerekli >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.HelpText);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AmountFA");
	ElementSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EverythingIsDistributedSumIsTA");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountAndStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
// AIT
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AITAmount");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NDDAmountStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Không cần thiết >';
													|ru = '< Не требуется >';
													|en = '< Not required >'; fa = '< Not required >';
													|it = '< Non si necessita >';
													|pl = '< Nie jest wymagane >';
													|tr = '< Gerekli değil >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AITAmount");
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NDDAmountStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '< Cần tự động >';
													|ru = '< Требуется авто >';
													|en = '< Auto is required >'; fa = '< خودکار الزامی است >';
													|it = '< Richiesto automatico >';
													|pl = '< Wymagane jest auto >';
													|tr = '< Otomatik gerekli >'"));
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.HelpText);
	
	Item = ExpenseForAllocation.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("AITAmount");
	ElementSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	ElementSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EverythingIsDistributedAmountNDD");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ItemFilter = ElementSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NDDAmountStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	Item.Appearance.SetParameterValue("TextColor",  StyleColors.UnavailableTextColor);
	
EndProcedure

&AtServer
Procedure SetDesignOfDynamicLists()
	
	UseLocal = GetFunctionalOption("UseLocal");
	
	TitleOfReglGroup = 
		?(UseLocal, 
			NStr("vi = 'Cần phân bổ vào kế toán tài chính';
				|ru = 'К распределению в регл. учете';
				|en = 'For allocation in local accounting'; fa = 'برای تسهیم در حسابداری محلی';
				|it = 'Da ripartire nella contabilità regolamentata';
				|pl = 'Do podziału w ewidencji regl.';
				|tr = 'Yerel muhasebede dağıtılacak'"),
			NStr("vi = 'Cần phân bổ vào kế toán tài chính';
				|ru = 'К распределению в регл. учете';
				|en = 'For allocation in local accounting'; fa = 'برای تسهیم در حسابداری محلی';
				|it = 'Da ripartire nella contabilità regolamentata';
				|pl = 'Do podziału w ewidencji regl.';
				|tr = 'Yerel muhasebede dağıtılacak'")
		);
	
	If ValueIsFilled(Organization) Then
		LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		Items.ExpensesToBeAllocatedGroupToBeAllocatedRegl.Title = StringFunctionsClientServer.SubstituteParametersToString(
			TitleOfReglGroup + " (%1)",
			LocalAccountingCurrency);
	Else
		Items.ExpensesToBeAllocatedGroupToBeAllocatedRegl.Title = TitleOfReglGroup;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityAccessibilityOfElements()
	
	UseAccountingOfOtherIncomeExpensesInLocalAccounting = GetFunctionalOption("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	Items.ExpensesToBeAllocatedGroupToBeAllocatedRegl.Visible = UseAccountingOfOtherIncomeExpensesInLocalAccounting;
	Items.ExpenseForAllocationSumCompl.Visible = UseAccountingOfOtherIncomeExpensesInLocalAccounting;
	
	UseLocal = GetFunctionalOption("UseLocal");
	Items.ExpenseForAllocationSumCompl.TitleLocation = ?(UseLocal, FormItemTitleLocation.Auto, FormItemTitleLocation.None);
	Items.ExpenseForAllocationAmountFA.Visible = UseLocal;
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False;
	Items.ExpenseForAllocationPermanentDifference.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept And DisplayDifferences;
	Items.ExpenseForAllocationCostTD.Visible = CalculationOfPermanentAndTemporaryDifferencesIsKept And DisplayDifferences;
	
	AITRecordsAreKept = CalculationOfCostLocalization.GetFunctionalOptionAITAccounting();
	Items.ExpenseForAllocationAITAmount.Visible = AITRecordsAreKept;
	
EndProcedure

#EndRegion

#EndRegion
