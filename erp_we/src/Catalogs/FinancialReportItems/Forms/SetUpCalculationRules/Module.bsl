
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("UseStatusFilter") Then
		UseStatusFilter = Parameters.UseStatusFilter;
	ElsIf Parameters.Property("BudgetingModel") Then
		UseStatusFilter = Common.ObjectAttributeValue(Parameters.BudgetingModel,
			"UseBudgetConfirmation");
	EndIf;
	FillPropertyValues(ThisObject, Parameters, "UseFilterByCompany, UseFilterByDepartment, UseFilterScenario");
	
	Catalogs.FinancialReportItems.FormWhenCreatedOnServer(ThisObject);
	MainStorageID = Parameters.MainStorageID;
	
	Title = "";
	If TypeOf(BudgetFlowItem) = Type("CatalogRef.BudgetBalanceItems") Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1: tùy chỉnh quy tắc tính số dư chỉ tiêu';
																				|ru = '%1: настройка правил расчета остатков показателя';
																				|en = '%1: set up item balance calculation rules'; fa = '%1: set up item balance calculation rules';
																				|it = '%1: set up item balance calculation rules';
																				|pl = '%1: set up item balance calculation rules';
																				|tr = '%1: Gösterge bakiyelerinin hesaplanmasına ilişkin kural ayarı'"), BudgetFlowItem);
		Items.PictureBudgetItem.Visible = False;
		Items.BudgetIndicatorPicture.Visible = True;
	Else
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1: tùy chỉnh quy tắc tính phát sinh của mục';
																				|ru = '%1: настройка правил расчета оборотов статьи';
																				|en = '%1: set up item turnover calculation rules'; fa = '%1: set up item turnover calculation rules';
																				|it = '%1: set up item turnover calculation rules';
																				|pl = '%1: set up item turnover calculation rules';
																				|tr = '%1: Kalem cirolarının hesaplanmasına ilişkin kural ayarı'"), BudgetFlowItem);
	EndIf;
	
	FillInCalculationRules();
	
	PrivilegedModeRadioButton = Number(PrivilegedMode);
	
	AddressOfReportItems = Parameters.AddressOfReportItems;
	ItemTableAddress = Parameters.ItemTableAddress;
	AddressOfEditedItem = Parameters.AddressOfEditedItem;
	
	FilterDefinitionParameters = New Structure;
	FilterDefinitionParameters.Insert("AddressOfEditedItem", AddressOfEditedItem);
	FilterDefinitionParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	If ValueIsFilled(ItemTableAddress) Then
		FilterDefinitionParameters.Insert("ItemTableAddress", ItemTableAddress);
	EndIf;
	
	FilterAvailabilityParameters = BudgetReportingCacheCalculationServer.FilterAvailabilityParameters(Undefined, FilterDefinitionParameters);
	
	For Each KeyAndValue In FilterAvailabilityParameters Do
		If KeyAndValue.Key = "Scenario" Then
			Items.UseTheDefaultFilterScenario.Visible = KeyAndValue.Value;
		ElsIf KeyAndValue.Key = "Organization" Then
			Items.UseTheFilterByOrganization.Visible = KeyAndValue.Value;
		ElsIf KeyAndValue.Key = "Department" Then
			Items.UseTheDefaultFilterDepartment.Visible = KeyAndValue.Value;
		EndIf;
	EndDo;
	
	If Parameters.Property("ParentItemKind")
	   And Parameters.ParentItemKind = Enums.FinancialReportItemKinds.DerivedItem
	   And Parameters.Property("UseToEnterPlan")
	   And Parameters.UseToEnterPlan Then
		Items.ExcludeEnteredDocumentDataDuringCalculation.Visible = True;
	Else
		Items.ExcludeEnteredDocumentDataDuringCalculation.Visible = False;
	EndIf;
	
	FormControl(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not Cancel Then
		CheckingSelectionByAvailabilityParameters();
		Catalogs.FinancialReportItems.FormBeforeWritingToServer(ThisObject, CurrentObject, Cancel);
		If ValueIsFilled(ItemAddressInStorage) Then
			ElementStructure = GetFromTempStorage(ItemAddressInStorage);
			ElementStructure.CalculationsRules.Clear();
			For Each StringRule In CalculationsRules Do
				If Not StringRule.Check Then
					Continue;
				EndIf;
				NewLineRule = ElementStructure.CalculationsRules.Add();
				NewLineRule.Rule = StringRule.Rule;
			EndDo;
			PutToTempStorage(ElementStructure, ItemAddressInStorage);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If ValueIsFilled(ItemAddressInStorage) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	SelectedCalculationRules = CalculationsRules.FindRows(New Structure("Check", True));
	If SelectedCalculationRules.Count() = 0 Then
		Common.MessageToUser(NStr("vi = 'Chưa chọn một quy tắc tính nào.';
									|ru = 'Не выбрано ни одного правила расчета.';
									|en = 'No calculation rules selected.'; fa = 'No calculation rules selected.';
									|it = 'No calculation rules selected.';
									|pl = 'No calculation rules selected.';
									|tr = 'Hiçbir hesaplama kuralı seçilmedi.'"), , , , Cancel);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "RecordingCalculationRule"
		And TypeOf(Source) = Type("CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers") Then
		FillInCalculationRules();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure NotUseAFilterOnChange(Item)
	
	InstallSelectionOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCalculationsRules

&AtClient
Procedure CalculationsRulesSelection(Item, RowSelected, Field, StandardProcessing)

	ShowValue(, Item.CurrentData.Rule);

EndProcedure

&AtClient
Procedure CalculationsRulesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
	FillingValues = New Structure("Receiver", BudgetFlowItem);
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Form.ItemForm", FormParameters, ThisObject, UUID, , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateCalculationRules(Command)
	FillInCalculationRules();
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	ClearMessages();
	
	AdditionalInfo = New Structure();
	AdditionalInfo.Insert("UseFilterByCompany", UseFilterByCompany);
	AdditionalInfo.Insert("UseFilterByDepartment", UseFilterByDepartment);
	AdditionalInfo.Insert("UseFilterScenario", UseFilterScenario);
	FinancialReportingClient.FinishEditingReportElement(ThisObject, AdditionalInfo);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	
EndProcedure

&AtServer
Procedure CheckingSelectionByAvailabilityParameters()
	
	If Not Modified Then
		Return;
	EndIf;
	
	FilterDefinitionParameters = New Structure;
	FilterDefinitionParameters.Insert("AddressOfEditedItem", AddressOfEditedItem);
	FilterDefinitionParameters.Insert("AddressOfReportItems", AddressOfReportItems);
	If ValueIsFilled(ItemTableAddress) Then
		FilterDefinitionParameters.Insert("ItemTableAddress", ItemTableAddress);
	EndIf;
	
	FilterAvailabilityParameters = BudgetReportingCacheCalculationServer.FilterAvailabilityParameters(Undefined, FilterDefinitionParameters);
	FilterAvailabilityParameters.Insert("Status", UseStatusFilter);
	
	For Each KeyAndValue In FilterAvailabilityParameters Do
		ListOfSelectionElements = New ValueList;
		SearchForSelectionElements = False;
		If KeyAndValue.Key = "Scenario"
			And Not KeyAndValue.Value
			And UseFilterScenario Then
			SearchForSelectionElements = True;
		EndIf;
		If KeyAndValue.Key = "Organization"
			And Not KeyAndValue.Value
			And UseFilterByCompany Then
			SearchForSelectionElements = True;
		EndIf;
		If KeyAndValue.Key = "Department"
			And Not KeyAndValue.Value
			And UseFilterByDepartment Then
			SearchForSelectionElements = True;
		EndIf;
		If KeyAndValue.Key = "Status"
			And UseStatusFilter Then
			SearchForSelectionElements = True;
		EndIf;
		If SearchForSelectionElements Then
			ListOfSelectionElements = New ValueList;
			BudgetReportingCacheCalculationServer.FindSelectionByName(
				Composer.Settings,
				KeyAndValue.Key,
				ListOfSelectionElements,,
				False);
			
			// The intersection of selections in the column and in the add.selection. The filter usage flag has been enabled.
			// If the list of selection items is empty, it means that the user has cleared the selection,
			// it is necessary to disable the filter use flag.
			If ListOfSelectionElements.Count() = 0 Then
				If KeyAndValue.Key = "Scenario" Then
					UseFilterScenario = 0;
				ElsIf KeyAndValue.Key = "Organization" Then
					UseFilterByCompany = 0;
				ElsIf KeyAndValue.Key = "Department" Then
					UseFilterByDepartment = 0;
				ElsIf KeyAndValue.Key = "Status" Then
					UseStatusFilter = False;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure InstallSelectionOnServer()
	
	Catalogs.FinancialReportItems.SetFilterSettings(ThisObject, Composer, Object.ItemKind, Composer.Settings);
	
EndProcedure

&AtClient
Procedure PrivilegedModeOnChange(Item)
	
	PrivilegedMode = Boolean(PrivilegedModeRadioButton);
	
EndProcedure

&AtServer
Procedure FillInCalculationRules()
	
	Query = New Query;
	Query.SetParameter("BudgetFlowItem", BudgetFlowItem);
	Query.SetParameter("CalculationsRules", Object.CalculationsRules.Unload().UnloadColumn("Rule"));
	Query.Text =
	"SELECT
	|	RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Ref AS Rule,
	|	CASE
	|		WHEN RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Ref IN (&CalculationsRules)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Check,
	|	CASE
	|		WHEN RuleForCalculatingRelatedBudgetBalancesAndTurnovers.SourceType = VALUE(Enum.DataSourceTypesForBudgeting.BudgetTurnovers)
	|			THEN RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Source
	|		ELSE RuleForCalculatingRelatedBudgetBalancesAndTurnovers.SourceType
	|	END AS Source
	|FROM
	|	Catalog.RuleForCalculatingRelatedBudgetBalancesAndTurnovers AS RuleForCalculatingRelatedBudgetBalancesAndTurnovers
	|WHERE
	|	RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Receiver = &BudgetFlowItem
	|	AND NOT RuleForCalculatingRelatedBudgetBalancesAndTurnovers.RecordCalculationInPlanningDocuments
	|	AND RuleForCalculatingRelatedBudgetBalancesAndTurnovers.Status = VALUE(Enum.BudgetingRuleStatuses.Valid)";
	CalculationsRules.Load(Query.Execute().Unload());
	
EndProcedure

#EndRegion

