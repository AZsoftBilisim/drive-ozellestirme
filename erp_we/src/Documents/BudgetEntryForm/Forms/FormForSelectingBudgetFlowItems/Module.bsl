
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	StructureOfBudgetParameters = New Structure(BudgetingClientServer.NamesOfBudgetAttributes());
	StructureOfBudgetParameters.Insert("ArrayOfBudgetItems");
	StructureOfBudgetParameters.Delete("BudgetProfile");
	FillPropertyValues(StructureOfBudgetParameters, Parameters);
	
	FillInTurnoverByBudgetItems();
	
	SetColumnsVisibility();
	
	SetBudgetItemSelectionParameters();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BudgetFlowItemOnChange(Item)
	
	SetSelectionOfTurnoverLinesByBudgetItems();
	
EndProcedure

&AtClient
Procedure PlanningPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetSelectionOfTurnoverLinesByBudgetItems();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetFlowItemTurnovers

&AtClient
Procedure BudgetFlowItemTurnoversSelection(Item, RowSelected, Field, StandardProcessing)
	
	TableRow = BudgetFlowItemTurnovers.FindByID(RowSelected);
	If TableRow.Check Then
		Return;
	EndIf;
	
	AdjustmentsByBudgetItems = FormOwner.AdjustmentsByBudgetItems; // - FormDataCollection -
	NewRow = AdjustmentsByBudgetItems.Add();
	FillPropertyValues(NewRow, TableRow);
	NewRow.AmountDecrease = TableRow.Sum;
	NewRow.AmountInCurrencyDecrease = TableRow.AmountInCurrency;
	NewRow.QuantityReduction = TableRow.Count;
	
	TableRow.Check = True;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetSelectionOfTurnoverLinesByBudgetItems()
	
	RowFilter = New Structure;
	If ValueIsFilled(BudgetFlowItem) Then
		RowFilter.Insert("BudgetFlowItem", BudgetFlowItem);
	EndIf;
	If ValueIsFilled(PlanningPeriod) Then
		RowFilter.Insert("PlanningPeriod", PlanningPeriod);
	EndIf;
	
	If RowFilter.Count() = 0 Then
		Items.BudgetFlowItemTurnovers.RowFilter = Undefined;
	Else
		Items.BudgetFlowItemTurnovers.RowFilter = New FixedStructure(RowFilter);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetBudgetItemSelectionParameters()
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Ref",
		New FixedArray(StructureOfBudgetParameters.ArrayOfBudgetItems)));
	Items.BudgetFlowItem.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	TypesOfArticlesAndIndicators = New Array;
	For Each ArrayElement In StructureOfBudgetParameters.ArrayOfBudgetItems Do
		If TypesOfArticlesAndIndicators.Find(TypeOf(ArrayElement)) = Undefined Then
			TypesOfArticlesAndIndicators.Add(TypeOf(ArrayElement));
		EndIf;
	EndDo;
	
	Items.BudgetFlowItem.TypeRestriction = New TypeDescription(TypesOfArticlesAndIndicators);
	
EndProcedure

&AtServer
Procedure FillInTurnoverByBudgetItems()
	
	Query = New Query;
	For Each Parameter In StructureOfBudgetParameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	Query.Text = 
	"SELECT
	|	TurnoversAndTurnovers.BudgetFlowItem AS BudgetFlowItem,
	|	TurnoversAndTurnovers.PlanningPeriod AS PlanningPeriod,
	|	TurnoversAndTurnovers.Currency AS Currency,
	|	TurnoversAndTurnovers.Dimension1 AS Dimension1,
	|	TurnoversAndTurnovers.Dimension2 AS Dimension2,
	|	TurnoversAndTurnovers.Dimension3 AS Dimension3,
	|	TurnoversAndTurnovers.Dimension4 AS Dimension4,
	|	TurnoversAndTurnovers.Dimension5 AS Dimension5,
	|	TurnoversAndTurnovers.Dimension6 AS Dimension6,
	|	TurnoversAndTurnovers.CountTurnover AS Count,
	|	TurnoversAndTurnovers.AmountInCurrencyTurnover AS AmountInCurrency,
	|	TurnoversAndTurnovers.ScenarioAmountTurnover AS Sum,
	|	(TurnoversAndTurnovers.CountTurnover <> 0) AS RecordByQuantity,
	|	(TurnoversAndTurnovers.AmountInCurrencyTurnover <> TurnoversAndTurnovers.ScenarioAmountTurnover) AS RecordByCurrency,
	|	CASE
	|		WHEN TurnoversAndTurnovers.Dimension6 <> UNDEFINED
	|			THEN 6
	|		WHEN TurnoversAndTurnovers.Dimension5 <> UNDEFINED
	|			THEN 5
	|		WHEN TurnoversAndTurnovers.Dimension4 <> UNDEFINED
	|			THEN 4
	|		WHEN TurnoversAndTurnovers.Dimension3 <> UNDEFINED
	|			THEN 3
	|		WHEN TurnoversAndTurnovers.Dimension2 <> UNDEFINED
	|			THEN 2
	|		WHEN TurnoversAndTurnovers.Dimension1 <> UNDEFINED
	|			THEN 1
	|		ELSE 0
	|	END AS NumberOfAnalysts
	|FROM
	|	AccumulationRegister.BudgetTurnovers.Turnovers(
	|			,
	|			&Date,
	|			,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND (PlanningPeriod BETWEEN &BeginOfPeriod AND &PeriodEnding)
	|				AND Status = VALUE(Enum.PlanStatuses.Upholded)
	|				AND Scenario = &Scenario
	|				AND BudgetFlowItem IN (&ArrayOfBudgetItems)) AS TurnoversAndTurnovers";
	
	BudgetFlowItemTurnovers.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Procedure SetColumnsVisibility()
	
	RecordByCurrency = BudgetFlowItemTurnovers.FindRows(New Structure("RecordByCurrency", True)).Count()
		> 0;
	RecordByQuantity = BudgetFlowItemTurnovers.FindRows(New Structure("RecordByQuantity",
		True)).Count() > 0;
	
	Items.BudgetFlowItemTurnoversCurrency.Visible = RecordByCurrency;
	Items.BudgetFlowItemTurnoversCount.Visible = RecordByQuantity;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	NumberOfAnalyticsIsUsed = False;
	For Counter = 0 To MaximumNumberOfAnalysts-1 Do
		NumberOfAnalysts = MaximumNumberOfAnalysts - Counter;
		If Not NumberOfAnalyticsIsUsed Then
			NumberOfAnalyticsIsUsed = BudgetFlowItemTurnovers.FindRows(New Structure("NumberOfAnalysts",
				NumberOfAnalysts)).Count() > 0;
		EndIf;
		Items["TurnoverByBudgetItemsAnalytics"+NumberOfAnalysts].Visible = NumberOfAnalyticsIsUsed;
	EndDo;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_PlanningPeriod" Then
		PlanningPeriodOnChange(Items.PlanningPeriod);
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
