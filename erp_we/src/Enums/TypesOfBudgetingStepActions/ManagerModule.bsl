#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the form name corresponding to the value of the enumeration to configure.
//
// Parameters:
//  ActionType - EnumRef.TypesOfBudgetingStepActions - The action for which the configuration form is defined.
//
// Returns:
//   String   - The name of the form.
//
Function FormName(ActionType) Export
	
	Return "Enum.TypesOfBudgetingStepActions.Form." + 
						Common.EnumerationValueName(ActionType);
		
EndFunction

// Returns a table of values filled with action settings.
//
// Parameters:
//  Form  - ClientApplicationForm - the form where the user specified the settings.
//
// Returns:
//   ValueTable - generated settings.
//
Function ActionSettings(Form) Export
	
	SettingsDetails_ = DetailsByActionType(Form, ActionType(Form.FormName), Form.BudgetingModel);
	
	Settings = New ValueTable;
	Settings.Columns.Add("Name");
	Settings.Columns.Add("Value");
	Settings.Columns.Add("Presentation");
	
	FormAttributes = Form.GetAttributes();
	For Each SettingsDetails In SettingsDetails_ Do
		For Each FormAttribute In FormAttributes Do
			If FormAttribute.Name <> SettingsDetails Then
				Continue;
			EndIf;
			NewRow = Settings.Add();
			NewRow.Name = FormAttribute.Name;
			If TypeOf(Form[FormAttribute.Name]) = Type("FormDataCollection") Then
				NewRow.Value = Form.FormAttributeToValue(FormAttribute.Name);
			Else
				NewRow.Value = Form[FormAttribute.Name];
			EndIf;
			NewRow.Presentation = FormAttribute.Title;
			Break;
		EndDo;
	EndDo;
	
	Return Settings;
	
EndFunction

// The procedure fills in the form details based on the passed table of values with settings.
//
// Parameters:
//  Settings  - ValueTable - a table saved in a process step or task.
//  Form - ClientApplicationForm - the form in which you want to restore settings.
//
Procedure RestoreActionSettings(Settings, Form) Export
	
	Attributes = Form.GetAttributes();
	For Each Attribute In Attributes Do
		If Attribute.Name = "Address" Or Attribute.Name = "AddressBudgetPopulationDimension" 
			Or Attribute.Name = "BudgetingStep" Or Attribute.Name = "BudgetingModel" Then 
			Continue;
		EndIf;
		Item = Settings.Find(Attribute.Name, "Name");
		If Item <> Undefined And Attribute.ValueType.ContainsType(TypeOf(Item.Value)) Then
			If TypeOf(Form[Attribute.Name]) = Type("FormDataCollection") Then
				Form.ValueToFormAttribute(Item.Value, Attribute.Name);
			Else 
				Form[Attribute.Name] = Item.Value;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// This function returns a view of the settings to display on the budget task or process step form.
//
// Parameters:
//  ActionSettings - ValueTable - action settings for which you want to define a Presentation:
//		*Name - String - Contains the name of the setting.
//		*Value - Arbitrary - Contains the setting value.
//  Action - EnumRef.TypesOfBudgetingStepActions - action of the budget preparation stage
//
// Returns:
//   String - name of the settings.
//
Function GetActionPresentation(Val ActionSettings, Action) Export

	Result = "";
	
	If ActionSettings.Count() = 0 Then
		Result = NStr("vi = '<Không cài đặt hành động>';
						|ru = '<Настройки действия не заданы>';
						|en = '<Action settings are not specified>'; fa = '<تنظیمات اقدام مشخص نشده است>';
						|it = '<le impostazioni dell''azione non sono state specificate>';
						|pl = '<Ustawienia działania nie są określone>';
						|tr = '<Eylem ayarları yapılmamış>'");
		Return Result;
	EndIf;
	
	If Action = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		TableNameTypesOfBudgets = "BalancesOfCalculatedIndicators";
	Else
		TableNameTypesOfBudgets = "BudgetProfiles";
	EndIf;
	
	BudgetProfiles = Undefined;
	Filter = New Structure();
	Filter.Insert("Name", TableNameTypesOfBudgets);
	Rows = ActionSettings.FindRows(Filter);
	If Rows.Count() > 0 Then
		BudgetProfiles = Rows[0].Value;
		If TypeOf(BudgetProfiles) <> Type("ValueTable") Then
			BudgetProfiles = Undefined;
		EndIf;
	EndIf;

	Template = NStr("vi = '%1: %2';
					|ru = '%1: %2';
					|en = '%1: %2'; fa = '%1: %2';
					|it = '%1: %2';
					|pl = '%1: %2';
					|tr = '%1: %2'");
	
	MeasurementPresentations = New Map;
	
	DimensionName = "Organization";
	MeasurementPresentations.Insert(DimensionName,
		BudgetReportingClientServer.PresentationOfBudgetingDimension(DimensionName));
	DimensionName = "Department";
	MeasurementPresentations.Insert(DimensionName,
		BudgetReportingClientServer.PresentationOfBudgetingDimension(DimensionName));
	DimensionName = "Scenario";
	MeasurementPresentations.Insert(DimensionName,
		BudgetReportingClientServer.PresentationOfBudgetingDimension(DimensionName));
	 
	If ValueIsFilled(BudgetProfiles) Then

		Text = "";
		
		If BudgetProfiles.Columns.Find("BudgetBalanceItem") <> Undefined Then
		
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template,
				NStr("vi = 'Chỉ tiêu tính toán';
					|ru = 'Расчетный показатель';
					|en = 'Estimate'; fa = 'Estimate';
					|it = 'Estimate';
					|pl = 'Estimate';
					|tr = 'Hesaplanan gösterge'"),
				BudgetProfiles[0].BudgetBalanceItem);
		
		ElsIf BudgetProfiles.Columns.Find("CalculationRule") <> Undefined And ValueIsFilled(
			BudgetProfiles[0].CalculationRule) Then
		
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template,
					NStr("vi = 'Quy tắc tính toán';
						|ru = 'Правило расчета';
						|en = 'Calculation rule'; fa = 'قاعده محاسبه';
						|it = 'Calculation rule';
						|pl = 'Calculation rule';
						|tr = 'Hesaplama kuralı'"),
					BudgetProfiles[0].CalculationRule);
		
		ElsIf ValueIsFilled(BudgetProfiles[0].BudgetProfile) Then
		
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template,
					NStr("vi = 'Dạng ngân sách';
						|ru = 'Вид бюджета';
						|en = 'Budget profile'; fa = 'پروفایل بودجه';
						|it = 'Tipologia di bilancio';
						|pl = 'Rodzaj budżetu';
						|tr = 'Bütçe profili'"),
					BudgetProfiles[0].BudgetProfile);
		
		EndIf;
		Result = Result + ?(ValueIsFilled(Result), ", ", "") + Text;
		
		If BudgetProfiles.Columns.Find("Action") <> Undefined And ValueIsFilled(BudgetProfiles[0].Action) Then
		
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template,
					NStr("vi = 'Thao tác';
						|ru = 'Действие';
						|en = 'Action'; fa = 'Action';
						|it = 'Действие';
						|pl = 'Czynność';
						|tr = 'Eylem'"),
					BudgetProfiles[0].Action);
			Result = Result + ?(ValueIsFilled(Result), ", ", "") + Text;
		
		EndIf;
		
		DimensionSettings = Undefined;
		
		Filter = New Structure();
		Filter.Insert("Name","BudgetPopulationDimension");
		Rows = ActionSettings.FindRows(Filter);
		If Rows.Count() > 0
		   And TypeOf(Rows[0].Value) = Type("ValueTable")
		   And Rows[0].Value.Count() > 0 Then
			
			DimensionSettings = Rows[0].Value; // ValueTable -
			ConfiguringAnalytics = DimensionSettings[0];
			
			If BudgetProfiles.Columns.Find("BudgetProfile") <> Undefined And ValueIsFilled(
				BudgetProfiles[0].BudgetProfile) Then
				BudgetDetails = Common.ObjectAttributeValue(BudgetProfiles[0].BudgetProfile,
					"HeaderDimensions").Unload().UnloadColumn("DimensionKind");
			Else
				BudgetDetails = New Array;
			EndIf;
			
			AnalyticsTextToEdit = "";
			TypeDescriptionNumber = New TypeDescription("Number");
			For Each Column In DimensionSettings.Columns Do
				
				If Column.Name = "RowKey" Then
					Continue;
				EndIf;
				
				If StrFind(Column.Name, "Availability") > 0 Then
					If ConfiguringAnalytics[Column.Name] = True Then
						ColumnName = StrReplace(Column.Name,"Availability","");
						DimensionNumber = TypeDescriptionNumber.AdjustValue(StrReplace(Column.Name,"AvailabilityOfAnalytics_",""));
						If DimensionNumber > 0 Then
							AnalyticsPresentation = String(BudgetDetails[DimensionNumber - 1]);
						Else
							AnalyticsPresentation = MeasurementPresentations.Get(ColumnName);
							If AnalyticsPresentation = Undefined Then
								AnalyticsPresentation = ColumnName;
							EndIf;		
						EndIf;
						AnalyticsTextToEdit = AnalyticsTextToEdit + 
							?(ValueIsFilled(AnalyticsTextToEdit), ", ", "") + AnalyticsPresentation; 
					EndIf;
					Continue;
				EndIf;
					
				If ValueIsFilled(ConfiguringAnalytics[Column.Name]) Then
					NameColumn = Column.Name;
					ColumnPresentation = "";
					Cnt = 1;
					While Cnt <= BudgetDetails.Count() Do
						If Column.Name = "Dimension"+Cnt Then
							ColumnPresentation = String(BudgetDetails[Cnt - 1]);
							Break;
						EndIf;
						Cnt = Cnt + 1;
					EndDo;
					If IsBlankString(ColumnPresentation) Then
						ColumnPresentation = MeasurementPresentations.Get(NameColumn);
						If ColumnPresentation = Undefined Then
							ColumnPresentation = NameColumn;
						EndIf;
					EndIf;
					Text = StringFunctionsClientServer.SubstituteParametersToString(Template,
							ColumnPresentation,
							ConfiguringAnalytics[Column.Name]);
					Result = Result + ?(ValueIsFilled(Result), ", ", "") + Text;
				EndIf;
				
			EndDo;
			If ValueIsFilled(AnalyticsTextToEdit) Then
				ConnectingStrings = New Array;
				ConnectingStrings.Add(Result + ",");
				ConnectingStrings.Add(NStr("vi = 'Được phép chỉnh sửa:';
											|ru = 'Разрешено для редактирования:';
											|en = 'Allowed for editing:'; fa = 'Allowed for editing:';
											|it = 'Modifica consentita:';
											|pl = 'Dozwolone do edycji:';
											|tr = 'Düzenlemeye izin veriliyor'"));
				ConnectingStrings.Add(AnalyticsTextToEdit);
				Result = StrConcat(ConnectingStrings, " ");
			EndIf;
		EndIf;
		
		SettingsCount = 0;
		SettingWeight = New Map;
		If DimensionSettings <> Undefined Then
			SettingsAnalyticsCopy = DimensionSettings.Copy(,"RowKey");
			SettingsAnalyticsCopy.Columns.Add("Weight");
			SettingsAnalyticsCopy.FillValues(1,"Weight");
			SettingsAnalyticsCopy.GroupBy("RowKey","Weight");
			For Each Page1 In SettingsAnalyticsCopy Do
				SettingWeight.Insert(Page1.RowKey,Page1.Weight);
			EndDo;
		EndIf;
		For Each Page1 In BudgetProfiles Do
			TheWeightOfARow =  SettingWeight.Get(Page1.DimensionSettingLineKey);
			If TheWeightOfARow = Undefined Then
				TheWeightOfARow = 1;
			EndIf;
			SettingsCount = SettingsCount + TheWeightOfARow;
		EndDo;
		
		If SettingsCount > 1 Then
			If BudgetProfiles.Columns.Find("BudgetBalanceItem") <> Undefined Then
				LinePresentation = NStr("vi = 'và hơn nữa chỉ tiêu ngân sách (%1)';
										|ru = 'и еще показателей бюджетов (%1)';
										|en = 'and more budget balance items (%1)'; fa = 'and more budget balance items (%1)';
										|it = 'and more budget balance items (%1)';
										|pl = 'and more budget balance items (%1)';
										|tr = 've (%1) bütçe göstergesi daha'");
			ElsIf BudgetProfiles.Columns.Find("CalculationRule") <> Undefined And ValueIsFilled(BudgetProfiles[0].CalculationRule) Then
				LinePresentation = NStr("vi = 'và hơn nữa quy tắc tính toán (%1)';
										|ru = 'и еще правил расчета (%1)';
										|en = 'and more calculation rules (%1)'; fa = 'and more calculation rules (%1)';
										|it = 'and more calculation rules (%1)';
										|pl = 'and more calculation rules (%1)';
										|tr = 've ayrıca hesaplama kuralı (%1)'");
			Else
				LinePresentation = NStr("vi = 'và dạng ngân sách khác (%1)';
										|ru = 'и еще видов бюджетов (%1)';
										|en = 'and more budget profiles (%1)'; fa = 'and more budget profiles (%1)';
										|it = 'e altre tipologie di budget (%1)';
										|pl = 'i więcej rodzajów budżetów (%1)';
										|tr = 've daha fazla bütçe profilleri(%1)'");
			EndIf;
			Result = Result + " " + StringFunctionsClientServer.SubstituteParametersToString(LinePresentation,
				SettingsCount - 1);
		EndIf;
				
	Else
	
		For Each Setting In ActionSettings Do
			If Not ValueIsFilled(Setting.Value) Then
				Continue;
			EndIf;
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(Template,
					Setting.Presentation,
					Setting.Value);
			
			Result = Result + ?(ValueIsFilled(Result), ", ", "") + Text;
			
		EndDo;
		
	EndIf;
	
	Return Result; 
	
EndFunction

#EndRegion

#Region Private

Function ActionType(FormName)
	
	AbbreviatedFormName = Metadata.FindByFullName(FormName).Name;
	ActionType = Enums.TypesOfBudgetingStepActions[AbbreviatedFormName];
	Return ActionType;
	
EndFunction

Function GetHeaderFields(Ref) Export
	
	If TypeOf(Ref) = Type("CatalogRef.NonFinancialItemsOfBudgets") And Not Ref.IsEmpty() Then
		Attributes = Common.ObjectAttributesValues(Ref, "ByCompanies, ByBusinessUnits, ByScenarios");
		Return Attributes;
		
	ElsIf TypeOf(Ref) = Type("CatalogRef.NonFinancialItemProfiles")  And Not Ref.IsEmpty() Then
		PeriodParameters_ = New Structure("BeginOfPeriod, PeriodEnding",
											BegOfYear(CurrentSessionDate()), EndOfYear(CurrentSessionDate()));
		
		InputDescriptionStructure = Documents.SetValuesForNonFinancialItems.DescriptionStructureOfInputDocumentFields(
				Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate, Undefined, Ref,
					Common.ObjectAttributeValue(Ref, "DefaultComplexTableValues"), PeriodParameters_);
		
		Result = New Structure("ByCompanies, ByBusinessUnits, ByScenarios", False, False, False);
		If InputDescriptionStructure <> Undefined Then
			For Each ArrayElement In InputDescriptionStructure.LeftColumn Do
				If ArrayElement.Name = "Scenario" Then
					Result.ByScenarios = True;
				ElsIf ArrayElement.Name = "Organization" Then
					Result.ByCompanies = True;
				ElsIf ArrayElement.Name = "Department" Then
					Result.ByBusinessUnits = True;
				EndIf;
			EndDo;
		EndIf;
		
		Return Result;
		
	Else
		Return New Structure("ByCompanies, ByBusinessUnits, ByScenarios", False, False, False);
		
	EndIf;
		
EndFunction

Function DetailsByActionType(Form, ActionType, BudgetingModel) Export
	
	FOParameters = New Structure("BudgetingModel", BudgetingModel);
	If ActionType = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
		Or ActionType = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		Or ActionType = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets Then
		Attributes = New Array;
		Attributes.Add("BudgetProfiles");
		Attributes.Add("BudgetPopulationDimension");
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.PlanEntry Then
		Attributes = New Array;
		Attributes.Add("PlanType");
		Attributes.Add("Scenario");
		Attributes.Add("PlanProfile");
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
		Attributes = New Array;
		Attributes.Add("OperationKind");
		If Form.OperationKind = Enums.OperationKindsOfSettingOfNonFinancialItemValues.EnterValuesFromTemplate Then
			SettingsDetails_ = GetHeaderFields(Form.InputTemplate);
			Attributes.Add("InputTemplate");
		Else
			SettingsDetails_ = GetHeaderFields(Form.NonFinancialItem);
			Attributes.Add("NonFinancialItem");
		EndIf;
		If SettingsDetails_.ByCompanies Then
			Attributes.Add("Organization");
		EndIf;
		If SettingsDetails_.ByBusinessUnits Then
			Attributes.Add("Department");
		EndIf;
		If SettingsDetails_.ByScenarios Then
			Attributes.Add("Scenario");
		EndIf;
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		Attributes = New Array;
		Attributes.Add("BalancesOfCalculatedIndicators");
		Attributes.Add("BudgetPopulationDimension");
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		Or ActionType = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Attributes = New Array;
		Attributes.Add("ApprovedStagesOfBudgetPreparation");
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.StepGroupRepetition Then
		Attributes = New Array;
		Attributes.Add("StepGroup");
		Attributes.Add("Scenario");
		If GetFunctionalOption("GenerateBudgetsByCompanies", FOParameters) Then
			Attributes.Add("Organization");
		EndIf;
		If GetFunctionalOption("GenerateBudgetsByBusinessUnits", FOParameters) Then
			Attributes.Add("Department");
		EndIf;
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.Other Then
		Attributes = New Array;
	ElsIf ActionType = Enums.TypesOfBudgetingStepActions.SetCashFlowLimits Then
		Attributes = New Array;
		If GetFunctionalOption("UseCashFlowLimitsByCompanies") Then
			Attributes.Add("Organization");
		EndIf;
		If GetFunctionalOption("UseCashFlowLimitsByBusinessUnit") Then
			Attributes.Add("Department");
		EndIf;
	Else
		Raise NStr("vi = 'Hành động chưa biết của giai đoạn chuẩn bị ngân sách';
					|ru = 'Неизвестное действие этапа подготовки бюджетов';
					|en = 'Unknown action in budgeting step'; fa = 'Unknown action in budgeting step';
					|it = 'Sconosciuta l''azione di fase di stesura dei budget';
					|pl = 'Nieznane działanie w fazie przygotowania budżetów';
					|tr = 'Bilinmeyen bütçe hazırlama aşaması eylemleri'")
	EndIf;
	
	Return Attributes;
	
EndFunction

#EndRegion

#EndIf

