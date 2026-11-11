#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Not Parameters.Property("RefToSource") Then
		Cancel = True;
	ElsIf TypeOf(Parameters.RefToSource) = Type("CatalogRef.CostAllocationRules") Then
		SettingForDepartment = False;
		Factor = Parameters.RefToSource;
		IndicatorType = Parameters.IndicatorType;
		If Parameters.Property("OnDate") Then
			Period = Parameters.OnDate;
		EndIf;
		If Parameters.Property("DivisionsForWhichNoMetricValueIsEntered") Then
			ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered.LoadValues(Parameters.DivisionsForWhichNoMetricValueIsEntered);
		EndIf;
		Title = NStr("vi = 'Giá trị chỉ số cho phân bổ chi phí';
					|ru = 'Значения показателя для распределения расходов';
					|en = 'Values of indicator for expense allocation'; fa = 'Values of indicator for expense allocation';
					|it = 'Valori dell''indice per allocazione dei costi';
					|pl = 'Wartości wskaźnika dla alokacji rozchodów';
					|tr = 'Giderlerin dağıtımı için gösterge değerleri'");
	ElsIf TypeOf(Parameters.RefToSource) = Type("CatalogRef.BusinessStructure") Then
		SettingForDepartment = True;
		Department = Parameters.RefToSource;
		Title = NStr("vi = 'Giá trị chỉ tiêu cho phân bổ chi phí';
					|ru = 'Значения показателей для распределения расходов';
					|en = 'Indicator values to allocate costs'; fa = 'مقادیر شاخص برای تسهیم هزینه‌ها';
					|it = 'Valori degli indicatori per allocazione dei costi';
					|pl = 'Wartości wskaźników do alokacji kosztów';
					|tr = 'Gider tahsisi için gösterge değerleri'");
	EndIf;
	
	If Not ValueIsFilled(Period) Then 
		Period = CurrentSessionDate();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	SetVisibilityOfBankingDetails();
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	FillInSettingsTable();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsTable1Selection(Item, RowSelected, Field, StandardProcessing)

	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Department", Item.CurrentData.Department);
	ParametersStructure1.Insert("Factor", Item.CurrentData.Factor);
	ParametersStructure1.Insert("IndicatorValue", Item.CurrentData.IndicatorValue);
	ParametersStructure1.Insert("ValidFrom", Period);
	
	Notification = New CallbackDescription("SettingsTable1SelectionCompletion", ThisForm);
	
	OpenForm("DataProcessor.ConfigureIndicatorValuesToAllocateCosts.Form.ValueSettingForm",
		ParametersStructure1, ThisForm, , , , Notification, FormWindowOpeningMode.LockOwnerWindow);

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

		FillInSettingsTable();
	EndIf;
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	StandardProcessing = False;
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction, StandardProcessing, Period, MonthLine);

	FillInSettingsTable();

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetVisibilityOfBankingDetails()

	If SettingForDepartment Then
		Items.Factor.Visible = False;
	Else
		Items.Department.Visible = False;
	EndIf;

EndProcedure

&AtClient
Procedure FillInSettingsTable()

	If SettingForDepartment Then
		FillInForDivision();
	Else
		FillInForMetric();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInForDivision()

	Query = New Query;
	Query.Text = RequestTextForDivision();
	Query.SetParameter("Department", Department);
	Query.SetParameter("OnDate", BegOfMonth(Period));
	Query.SetParameter("WithoutFilterForOneIndicator", True);
	Query.SetParameter("Factor", Catalogs.CostAllocationRules.EmptyRef());
	SettingsTable1.Load(Query.Execute().Unload());

EndProcedure

&AtServer
Procedure FillInForMetric()

	Query = New Query;
	Query.Text = QueryTextForMetric();
	Query.SetParameter("Factor", Factor);
	Query.SetParameter("OnDate", BegOfMonth(Period));
	Query.SetParameter("NoFilterByOneDivision", True);
	Query.SetParameter("Department", Catalogs.BusinessStructure.EmptyRef());
	NoFilterForNonEnteredMetricValues = ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered.FindByValue(Catalogs.BusinessStructure.EmptyRef()) <> Undefined;
	If ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered.Count() > 0 Then
		Query.SetParameter("ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered", ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered);
		Query.SetParameter("NoFilterForNonEnteredMetricValues", NoFilterForNonEnteredMetricValues);
	Else
		Query.SetParameter("ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered", Undefined);
		Query.SetParameter("NoFilterForNonEnteredMetricValues", True);
	EndIf;
	VTResult = Query.Execute().Unload();
	VTResult.Columns.Add("DivisionFullName");
	For Each String In VTResult Do
		String.DivisionFullName = String.Department.FullDescr();
	EndDo;
	VTResult.Sort("DivisionFullName", New CompareValues);
	SettingsTable1.Load(VTResult);

EndProcedure

&AtServer
Function RequestTextForDivision()
	
	QueryText = "SELECT
	|	Indicators.Ref AS Factor,
	|	Indicators.AllocationBase AS Entered
	|INTO TTWhenChanging
	|FROM
	|	Catalog.CostAllocationRules AS Indicators
	|WHERE
	|	Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)
	|	AND Indicators.DeletionMark = FALSE
	|	AND (&WithoutFilterForOneIndicator 
	|		OR Indicators.Ref = &Factor)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Indicators.Ref AS Factor,
	|	Indicators.AllocationBase AS Entered
	|INTO TTMonthly
	|FROM
	|	Catalog.CostAllocationRules AS Indicators
	|WHERE
	|	Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|	AND Indicators.DeletionMark = FALSE
	|	AND (&WithoutFilterForOneIndicator 
	|		OR Indicators.Ref = &Factor)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Department AS Department,
	|	TTWhenChanging.Factor,
	|	TTWhenChanging.Entered,
	|	ISNULL(CrossSectionMetricValues.IndicatorValue, 0) AS IndicatorValue,
	|	ISNULL(CrossSectionMetricValues.Period, DATETIME(1, 1, 1, 0, 0, 0)) AS ValidFrom
	|FROM
	|	TTWhenChanging AS TTWhenChanging
	|		LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts.SliceLast(&OnDate, Department = &Department) AS CrossSectionMetricValues
	|		ON TTWhenChanging.Factor = CrossSectionMetricValues.Factor
	|
	|UNION ALL
	|
	|SELECT
	|	&Department,
	|	TTMonthly.Factor,
	|	TTMonthly.Entered,
	|	ISNULL(IndicatorValues.IndicatorValue, 0),
	|	ISNULL(IndicatorValues.Period, DATETIME(1, 1, 1, 0, 0, 0))
	|FROM
	|	TTMonthly AS TTMonthly
	|		LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts AS IndicatorValues
	|		ON (TTMonthly.Factor = IndicatorValues.Factor
	|			AND IndicatorValues.Period = &OnDate
	|			AND IndicatorValues.Department = &Department)";

	Return QueryText;
	
EndFunction

&AtServer
Function QueryTextForMetric()
	
	QueryText = "SELECT
	|	BusinessStructure.Ref AS Department
	|INTO TTUnits
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|WHERE
	|	BusinessStructure.DeletionMark = FALSE
	|	AND (&NoFilterForNonEnteredMetricValues
	|	   OR BusinessStructure.Ref IN(&ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered)
	|	   )
	|	AND (&NoFilterByOneDivision
	|	   OR BusinessStructure.Ref = &Department
	|	   )
	|	AND BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	If IndicatorType = Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis Then
		
		QueryText = QueryText + "
		|SELECT
		|	&Factor AS Factor,
		|	TTUnits.Department,
		|	VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef) AS Entered,
		|	ISNULL(IndicatorValues.IndicatorValue, 0) AS IndicatorValue,
		|	ISNULL(IndicatorValues.Period, DATETIME(1, 1, 1, 0, 0, 0)) AS ValidFrom
		|FROM
		|	TTUnits AS TTUnits
		|		LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts AS IndicatorValues
		|		ON (TTUnits.Department = IndicatorValues.Department
		|			AND IndicatorValues.Period = &OnDate
		|			AND IndicatorValues.Factor = &Factor)";
		
	ElsIf IndicatorType = Enums.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand Then 
		
		QueryText = QueryText + "
		|SELECT
		|	&Factor AS Factor,
		|	TTUnits.Department,
		|	VALUE(Enum.TypesOfCostAllocatingBase.EmptyRef) AS Entered,
		|	ISNULL(CrossSectionMetricValues.IndicatorValue, 0) AS IndicatorValue,
		|	ISNULL(CrossSectionMetricValues.Period, DATETIME(1, 1, 1, 0, 0, 0)) AS ValidFrom
		|FROM
		|	TTUnits AS TTUnits
		|		LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts.SliceLast(&OnDate, Factor = &Factor) AS CrossSectionMetricValues
		|		ON TTUnits.Department = CrossSectionMetricValues.Department";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

&AtClient
Procedure SettingsTable1SelectionCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		CurrentData = Items.SettingsTable1.CurrentData;
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("OnDate", BegOfMonth(Period));
		ParametersStructure1.Insert("Department", CurrentData.Department);
		ParametersStructure1.Insert("Factor", CurrentData.Factor);
		FillPropertyValues(CurrentData, RereadCurLine(ParametersStructure1));
	EndIf;
	
EndProcedure

&AtServer
Function RereadCurLine(Var_Parameters)
	
	Query = New Query;
	If SettingForDepartment Then
		Query.Text = RequestTextForDivision();
		Query.SetParameter("OnDate", Var_Parameters.OnDate);
		Query.SetParameter("Department", Var_Parameters.Department);
		Query.SetParameter("Factor", Var_Parameters.Factor);
		Query.SetParameter("WithoutFilterForOneIndicator", False);
	Else
		Query.Text = QueryTextForMetric();
		Query.SetParameter("OnDate", Var_Parameters.OnDate);
		Query.SetParameter("Factor", Var_Parameters.Factor);
		Query.SetParameter("Department", Var_Parameters.Department);
		Query.SetParameter("NoFilterByOneDivision", False);
		Query.SetParameter("NoFilterForNonEnteredMetricValues", True); 
		Query.SetParameter("ListOfDepartmentsForWhichTheIndicatorValueIsNotEntered", Undefined);
	EndIf;
	
	ResultingStructure = New Structure;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ResultingStructure.Insert("Department", Selection.Department);
		ResultingStructure.Insert("DivisionFullName", Selection.Department.FullDescr());
		ResultingStructure.Insert("Factor", Selection.Factor);
		ResultingStructure.Insert("IndicatorValue", Selection.IndicatorValue);
		ResultingStructure.Insert("ValidFrom", Selection.ValidFrom);
		ResultingStructure.Insert("Entered", Selection.Entered);
		Return ResultingStructure;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsTable1Factor.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingForDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsTable1DivisionFullName.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingForDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetupTableInstallationDate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsTable1IndicatorValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingsTable1.ValidFrom");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New StandardBeginningDate(Date('00010101000000'));

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không được nhập>';
													|ru = '<Не введено>';
													|en = '<Not entered>'; fa = '<Not entered>';
													|it = '<Non inserito>';
													|pl = '<Nie wprowadzono>';
													|tr = '<Girilmedi>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsTable1Entered.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingsTable1.Entered");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Khi thay đổi';
													|ru = 'При изменении';
													|en = 'On change'; fa = 'On change';
													|it = 'Durante la modifica';
													|pl = 'Podczas zmian';
													|tr = 'Değiştiğinde'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsTable1Entered.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingsTable1.Entered");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis;

	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Hàng tháng';
													|ru = 'Ежемесячно';
													|en = 'Monthly'; fa = 'ماهانه';
													|it = 'Mensilmente';
													|pl = 'Monthly';
													|tr = 'Aylık'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SettingsTable1Entered.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingForDepartment");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("Visible", False);

EndProcedure

#EndRegion
