
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Period") Then
		Period = Parameters.Period;
	Else
		Period = BegOfMonth(CurrentSessionDate());
	EndIf;
	
	If Parameters.Property("OnlyEmpty") Then
		
		OnlyUnfilledIndicators = Parameters.OnlyEmpty;
		OutputOnlyMetricsToFillIn();
		
	EndIf;
	
	Factor = Catalogs.CostAllocationRules.EmptyRef();
	CommonClientServer.SetDynamicListParameter(ValuesToFillIn, "Factor", Factor);
	CommonClientServer.SetDynamicListParameter(ValuesToBeFilledInOnTheHIA, "Factor", Factor);
	
	If Parameters.Property("Factor") And ValueIsFilled(Parameters.Factor) Then
	
		Factor = Parameters.Factor;
		ThePurposeOfTheIndicators = Common.ObjectAttributeValue(Factor, "AssignRule");
		CommonClientServer.SetDynamicListParameter(?(ThePurposeOfTheIndicators = Enums.AssignmentOfCostAllocationRules.CostAllocationToCostCenter, ValuesToBeFilledInOnTheHIA, ValuesToFillIn), "Factor", Factor);

		If Parameters.Property("OnlyValues") Then
			Items.GroupIndicators.Visible = False;
			Title = StrTemplate("Return values_ indicator_ %1", String(Factor));
		EndIf;
	
	ElsIf Parameters.Property("AssignRule") Then
		ThePurposeOfTheIndicators = Parameters.AssignRule;
	Else
		ThePurposeOfTheIndicators = Enums.AssignmentOfCostAllocationRules.CostAllocationBetweenBusinessUnits;
	EndIf;
	CommonClientServer.SetDynamicListFilterItem(IndicatorsToFillIn, "AssignRule", ThePurposeOfTheIndicators);
	
	If Parameters.Property("Departments")Then
		CommonClientServer.SetDynamicListFilterItem(
			ValuesToFillIn,
			"Department",
			Parameters.Departments,
			DataCompositionComparisonType.InList);
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(ValuesToFillIn, "BegOfMonth", BegOfMonth(Period));
	CommonClientServer.SetDynamicListParameter(ValuesToBeFilledInOnTheHIA, "BegOfMonth", BegOfMonth(Period));

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	If ValueIsFilled(Factor) Then
		Items.IndicatorsToFillIn.CurrentRow = Factor;
	EndIf;
	DisplayMetricValues();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure IndicatorsToFillInOnActivateRow(Item)
	
	AttachIdleHandler("IndicatorsToFillInOnActivateRowCompletion", 0.2, True);
	
EndProcedure

&AtClient
Procedure IndicatorsToFillInOnActivateRowCompletion()
	
	If (Factor <> Items.IndicatorsToFillIn.CurrentRow) Then
		Factor = Items.IndicatorsToFillIn.CurrentRow;
		DisplayMetricValues();
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayMetricValues()
	
	IndicatorSelected = TypeOf(Factor) = Type("CatalogRef.CostAllocationRules");
	
	Items.ValuesToFillIn.Enabled = IndicatorSelected;
	Items.ValuesToBeFilledInOnTheHIA.Enabled = IndicatorSelected;
	Items.GroupOfValuesToFillInTheKP.Enabled = IndicatorSelected;
	Items.GroupOfValuesToFillOutTheHIAP.Enabled = IndicatorSelected;
	If Not IndicatorSelected Then
		Return;
	EndIf;
	
	References_0 = Common.ObjectAttributesValues(Factor, "AssignRule,AllocationBase");
	
	OnOvz = References_0.AssignRule = PredefinedValue("Enum.AssignmentOfCostAllocationRules.CostAllocationToCostCenter");
	Periodic3 = Not References_0.AllocationBase = PredefinedValue("Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand");
	
	Items.GroupOfValuesToFillInTheKP.Visible = Not OnOvz;
	Items.ValuesToFillIn.Visible = Not OnOvz;

	Items.GroupOfValuesToFillOutTheHIAP.Visible = OnOvz;
	Items.ValuesToBeFilledInOnTheHIA.Visible = OnOvz;
	
	If OnOvz Then
		Items.ValuesToBeFilledInOnTheHIAPeriod.Visible = Not Periodic3;
	Else
		Items.ValuesToFillInPeriod.Visible = Not Periodic3;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(?(OnOvz, ValuesToBeFilledInOnTheHIA, ValuesToFillIn), "Factor", Factor);
	
EndProcedure

&AtClient
Procedure ValuesToFillInBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	If Items.IndicatorsToFillIn.CurrentData <> Undefined Then
		FormParameters = New Structure("Factor, Period", Items.IndicatorsToFillIn.CurrentData.Ref, Period);
		OpenForm("InformationRegister.IndicatorValuesToAllocateCosts.Form.RecordForm", FormParameters, ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure ValuesToBeFilledInOnTheHIABeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
	If Items.IndicatorsToFillIn.CurrentData <> Undefined Then
		FormParameters = New Structure("Factor, Period", Items.IndicatorsToFillIn.CurrentData.Ref, Period);
		OpenForm("InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.Form.RecordForm", FormParameters, ThisForm);
	EndIf;
EndProcedure


&AtClient
Procedure PeriodTuning(Item, Direction, StandardProcessing)
	StandardProcessing = False;
	Period = AddMonth(Period, Direction);
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	CommonClientServer.SetDynamicListParameter(ValuesToFillIn, "BegOfMonth", BegOfMonth(Period));
	CommonClientServer.SetDynamicListParameter(ValuesToBeFilledInOnTheHIA, "BegOfMonth", BegOfMonth(Period));
EndProcedure

&AtClient
Procedure ValuesToFillInSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Data = Item.CurrentData;
	
	ParametersOfFormToOpen = New Structure();
	ParametersOfFormToOpen.Insert("Factor",			Factor);
	ParametersOfFormToOpen.Insert("Period",				Period);
	ParametersOfFormToOpen.Insert("Department",			Data.Department);
	ParametersOfFormToOpen.Insert("IndicatorValue",	Data.Factor);
	
	CallbackDescription = New CallbackDescription("UpdateListOfMetrics", ThisForm);
	
	OpenForm("InformationRegister.IndicatorValuesToAllocateCosts.Form.RecordForm", ParametersOfFormToOpen, ThisForm,,,,CallbackDescription);
	
EndProcedure

&AtClient
Procedure ValuesToBeFilledInOnTheHIASelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	Data = Item.CurrentData;
	
	ParametersOfFormToOpen = New Structure();
	ParametersOfFormToOpen.Insert("Factor",			Factor);
	ParametersOfFormToOpen.Insert("Period",				Period);
	ParametersOfFormToOpen.Insert("CONSTCENTER",					Data.ConstCenter);
	ParametersOfFormToOpen.Insert("IndicatorValue",	Data.Factor);
	
	CallbackDescription = New CallbackDescription("UpdateListOfHIAIndicators", ThisForm);
	
	OpenForm("InformationRegister.IndicatorValuesForAllocatingExpensesBetweenExpenseObjects.Form.RecordForm", ParametersOfFormToOpen, ThisForm,,,,CallbackDescription);
	
EndProcedure


&AtClient
Procedure UpdateListOfMetrics(Result, CommandParameter) Export
	Items.ValuesToFillIn.Refresh();
EndProcedure

&AtClient
Procedure UpdateListOfHIAIndicators(Result, CommandParameter) Export
	Items.ValuesToBeFilledInOnTheHIA.Refresh();
EndProcedure

&AtClient
Procedure PeriodStartChoice(Item, ChoiceData, StandardProcessing)
	Notification = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	TMCommonUseClient.StartSelectingRegistrationPeriodPresentation(Item, StandardProcessing, Period, ThisForm, Notification);
EndProcedure

#EndRegion

#Region ServiceProceduresFunctions 

&AtServer
Procedure OutputOnlyMetricsToFillIn()
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	Indicators.Ref AS Factor
	|FROM
	|	Catalog.CostAllocationRules AS Indicators
	|		LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts AS ValuesMonthly
	|		ON Indicators.Ref = ValuesMonthly.Factor
	|			AND (BEGINOFPERIOD(ValuesMonthly.Period, MONTH) = &BegOfMonth)
	|WHERE
	|	NOT Indicators.DeletionMark
	|	AND ValuesMonthly.Factor IS NULL 
	|	AND Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.VariableEnteredManuallyOnMonthlyBasis)
	|
	|UNION ALL
	|
	|SELECT
	|	Indicators.Ref
	|FROM
	|	Catalog.CostAllocationRules AS Indicators
	|		LEFT JOIN InformationRegister.IndicatorValuesToAllocateCosts.SliceLast(&EndOfMonth, ) AS ValuesOnChange
	|		ON Indicators.Ref = ValuesOnChange.Factor
	|WHERE
	|	NOT Indicators.DeletionMark
	|	AND ValuesOnChange.Factor IS NULL 
	|	AND Indicators.AllocationBase = VALUE(Enum.TypesOfCostAllocatingBase.ConstantEnteredManuallyOnDemand)");
	
	Query.SetParameter("BegOfMonth", BegOfMonth(Period));
	Query.SetParameter("EndOfMonth", EndOfMonth(Period));

	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		BlankIndicators = Result.Unload().UnloadColumn("Factor");
		CommonClientServer.SetDynamicListFilterItem(IndicatorsToFillIn, "Ref", BlankIndicators, DataCompositionComparisonType.InList, ,True);
	Else
		CommonClientServer.SetDynamicListFilterItem(IndicatorsToFillIn, "Ref", Catalogs.CostAllocationRules.EmptyRef(), DataCompositionComparisonType.Equal, ,True);
	EndIf;
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(SelectedPeriod);
	EndIf;
	CommonClientServer.SetDynamicListParameter(ValuesToFillIn, "BegOfMonth", BegOfMonth(Period));
	CommonClientServer.SetDynamicListParameter(ValuesToBeFilledInOnTheHIA, "BegOfMonth", BegOfMonth(Period));
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	BoldFont = New Font(, , True, , , , );
	
	#Region FormalizingValueToFillIn
	
	ConditionalAppearance.Items.Clear();
	
	// ValuesToFillIn.Factor
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValuesToFillInFactor.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValuesToFillIn.Factor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	// ValuesToFillIn.Period
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValuesToFillInPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValuesToFillIn.Factor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa đặt>';
													|ru = '<не задано>';
													|en = '<not set>'; fa = '<تنظیم نشده>';
													|it = '<non indicato>';
													|pl = '<nie określono>';
													|tr = '<belirtilmedi>'"));
	
	// ValuesToFillIn.Department
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValuesToFillInDepartment.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ValuesToFillIn.Factor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Font", BoldFont);
	
	#EndRegion

	#Region RegistrationOfValueForFillingInHIA
	
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		
		// ValuesToBeFilledInOnTheHIA.Factor
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ValuesToBeFilledInOnTheHIAFactor.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValuesToBeFilledInOnTheHIAFactor.Factor");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
		
		// ValuesToBeFilledInOnTheHIA.Period
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ValuesToBeFilledInOnTheHIAPeriod.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValuesToBeFilledInOnTheHIA.Factor");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa đặt>';
														|ru = '<не задано>';
														|en = '<not set>'; fa = '<تنظیم نشده>';
														|it = '<non indicato>';
														|pl = '<nie określono>';
														|tr = '<belirtilmedi>'"));
		
		// ValuesToFillIn.ConstCenter
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ValuesToBeFilledInOnTheHIAConstCenter.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValuesToBeFilledInOnTheHIA.Factor");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		Item.Appearance.SetParameterValue("Font", BoldFont);
		
	EndIf;
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnlyBlankWhenChanging(Item)
	
	If OnlyUnfilledIndicators Then
		OutputOnlyMetricsToFillIn();
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(IndicatorsToFillIn, "Ref");
	EndIf;
	
EndProcedure

&AtClient
Procedure IndicatorsToFillInSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	OpenForm("Catalog.CostAllocationRules.Form.IndicatorForm", New Structure("Key", RowSelected));
EndProcedure

&AtClient
Procedure ThePurposeOfTheIndicatorsOnChange(Item)
	AssigningMetricsWhenChangingOnServer();
EndProcedure

&AtServer
Procedure AssigningMetricsWhenChangingOnServer()
	CommonClientServer.SetDynamicListFilterItem(IndicatorsToFillIn, "AssignRule", ThePurposeOfTheIndicators);
EndProcedure

#EndRegion