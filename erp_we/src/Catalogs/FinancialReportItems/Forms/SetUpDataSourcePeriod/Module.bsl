
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormParameters = BudgetReportingClientServer.ParametersForOpeningPeriodSettingsForm(Parameters);
	FillPropertyValues(ThisForm, FormParameters);
	
	If Not Parameters.Property("NonFinancialItem") Then
	
		SetVisibilityOfGroupingSettings(Parameters);
		
		ChoiceList = Items.DataLimits.ChoiceList;
		If Parameters.LocationOptionOfActualDataOffset = Enums.LocationOptionsOfActualDataOffsets.BeforeBudgetPreparation Then
			ChoiceList.Delete(ChoiceList.FindByValue("StartFact"));
		ElsIf Parameters.LocationOptionOfActualDataOffset = Enums.LocationOptionsOfActualDataOffsets.WithinBudgetPeriod Then
			ChoiceList.Delete(ChoiceList.FindByValue("FactBeginning"));
		EndIf;
		
	Else
		
		Items.DataBoundaryDetailsGroup.Visible = False;
		Items.DataLimits.Visible = False;
		Items.TheCompanyValues.Visible = False;
		
	EndIf;
	
	SetPeriodOptions();
	FormControl();
	
	WindowOption = "NoGrouping";
	If Not Items.DataLimits.Visible Then
		WindowOption = "NonFinancialItem";
	ElsIf Items.TheCompanyValues.Visible Then
		WindowOption = "GroupingPeriod";
	EndIf;
	
	ThisForm.WindowOptionsKey = "FormOption_" + WindowOption;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	Errors = Undefined;
	
	AttributesNotToCheck = New Array;
	ThereIsErrorAtBeginning = False; ThereIsErrorAtEnd = False;
	
	If Items.DataLimits.Visible Then
		OrderedPeriodicities = New Array;
		OrderedPeriodicities.Add("SECOND");
		OrderedPeriodicities.Add("MINUTE");
		OrderedPeriodicities.Add("HOUR");
		For Each NameOfForbiddenPeriodicity In OrderedPeriodicities Do
			If Not ThereIsErrorAtBeginning And StrFind(Upper(LowerBoundOfData), Upper(NameOfForbiddenPeriodicity)) Then
				ErrorText = NStr("vi = 'Biểu thức về ranh giới của kỳ bắt đầu không thể chứa chu kỳ ngắn hơn một ngày';
								|ru = 'Выражение границ начала периода не может содержать периодичность меньшую, чем день';
								|en = 'Expression of the period start boundary cannot contain frequency that is less than a day'; fa = 'Expression of the period start boundary cannot contain frequency that is less than a day';
								|it = 'L''espressione dell''intervallo di tempo dell''inizio del periodo non può essere inferiore ad un giorno';
								|pl = 'Wyrażenie granic początku okresu nie może zawierać okresowości mniejszej, niż dzień';
								|tr = 'Dönemin başlangıç sınırı ifadesi, günden daha az bir sıklıkta olamaz.'");
				CommonClientServer.AddUserError(Errors, "LowerBoundOfData", ErrorText, "");
				ThereIsErrorAtBeginning = True;
			EndIf;
			If Not ThereIsErrorAtEnd And StrFind(Upper(UpperBoundOfData), Upper(NameOfForbiddenPeriodicity)) Then
				ErrorText = NStr("vi = 'Biểu thức về ranh giới của kỳ kết thúc không thể chứa chu kỳ ngắn hơn một ngày';
								|ru = 'Выражение границ конца периода не может содержать периодичность меньшую, чем день';
								|en = 'Expression of the period end boundaries cannot contain frequency that is less than a day'; fa = 'Expression of the period end boundaries cannot contain frequency that is less than a day';
								|it = 'L''espressione dell''intervallo di tempo della fine del periodo non può essere inferiore ad un giorno';
								|pl = 'Wyrażenie granic końca okresu nie może zawierać okresowości mniejszej, niż dzień';
								|tr = 'Dönemin başlangıç sınırı ifadesi, günden daha az bir sıklıkta olamaz.'");
				CommonClientServer.AddUserError(Errors, "UpperBoundOfData", ErrorText, "");
				ThereIsErrorAtEnd = True;
			EndIf;
			If ThereIsErrorAtBeginning And ThereIsErrorAtEnd Then
				Break;
			EndIf;
		EndDo;
	Else
		AttributesNotToCheck.Add("LowerBoundOfData");
		AttributesNotToCheck.Add("UpperBoundOfData");
	EndIf;
	
	ThereIsErrorAtBeginning = False; ThereIsErrorAtEnd = False;
	
	If ValueIsFilled(GroupingFrequency)
		And Items.TheCompanyValues.Visible Then
		OrderedPeriodicities = BudgetReportingClientServer.OrderedPeriodicities();
		OrderedPeriodicities.Insert(0, "SECOND");
		OrderedPeriodicities.Insert(0, "MINUTE");
		OrderedPeriodicities.Insert(0, "HOUR");
		For Each Periodicity In OrderedPeriodicities Do
			If Not ValueIsFilled(Periodicity) Then
				Continue;
			EndIf;
			If Periodicity = GroupingFrequency Then
				Break;
			EndIf;
			If TypeOf(Periodicity) = Type("String") Then
				NameOfForbiddenPeriodicity = Periodicity;
			Else
				NameOfForbiddenPeriodicity = FinancialReportingClientServerCached.PeriodicityByString(Periodicity);
			EndIf;
			If Not ThereIsErrorAtBeginning And StrFind(Upper(GroupingPeriodStart), Upper(NameOfForbiddenPeriodicity)) Then
				ErrorText = NStr("vi = 'Biểu thức dịch chuyển bắt đầu kỳ gom nhóm không thể chứa chu kỳ nhỏ hơn %1';
								|ru = 'Выражение смещения начала периода группировки не может содержать периодичность меньшую, чем %1';
								|en = 'Offset expression of grouping period start cannot contain frequency that is less than %1'; fa = 'Offset expression of grouping period start cannot contain frequency that is less than %1';
								|it = 'L''espressione di spostamento dell''inizio del periodo di raggruppamento non può essere inferiore a %1';
								|pl = 'Wyrażenie przesunięcia początku okresu grupowania nie może zawierać okresowości mniejszej, niż %1';
								|tr = 'Gruplama döneminin başlangıç sınırı ifadesi, %1 sıklığından daha az bir sıklıkta olamaz.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, GroupingFrequency);
				CommonClientServer.AddUserError(Errors, "GroupingPeriodStart", ErrorText, "");
				ThereIsErrorAtBeginning = True;
			EndIf;
			If Not ThereIsErrorAtEnd And StrFind(Upper(GroupingPeriodEnd), Upper(NameOfForbiddenPeriodicity)) Then
				ErrorText = NStr("vi = 'Biểu thức dịch chuyển của cuối giai đoạn nhóm không thể chứa một chu kỳ nhỏ hơn %1';
								|ru = 'Выражение смещения конца периода группировки не может содержать периодичность меньшую, чем %1';
								|en = 'Offset expression of grouping period end cannot contain frequency that is less than %1'; fa = 'Offset expression of grouping period end cannot contain frequency that is less than %1';
								|it = 'L''espressione di spostamento della fine del periodo di raggruppamento non può essere inferiore a %1';
								|pl = 'Wyrażenie przesunięcia końca okresu grupowania nie może zawierać okresowości mniejszej, niż %1';
								|tr = 'Gruplama döneminin başlangıç sınırı ifadesi, %1 sıklığından daha az bir sıklıkta olamaz.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, GroupingFrequency);
				CommonClientServer.AddUserError(Errors, "GroupingPeriodEnd", ErrorText, "");
				ThereIsErrorAtEnd = True;
			EndIf;
			If ThereIsErrorAtBeginning And ThereIsErrorAtEnd Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not Items.TheCompanyValues.Visible Then
		AttributesNotToCheck.Add("GroupingPeriodStart");
		AttributesNotToCheck.Add("GroupingPeriodEnd");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	If CheckFilling() Then
		ClosingValues = BudgetReportingClientServer.ParametersForOpeningPeriodSettingsForm(ThisForm, False);
		Close(ClosingValues);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataLimitsOnChange(Item)
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	
	If DataLimits = "" Then
		
		LowerBoundOfData = PeriodVariables.DataPeriodStart.Name;
		UpperBoundOfData = PeriodVariables.DataPeriodEnd.Name;
		
	ElsIf DataLimits = "FactBeginning" Then
		
		LowerBoundOfData = PeriodVariables.ActualDataLimit.Name;
		UpperBoundOfData = "AddToDate(" + PeriodVariables.DataPeriodStart.Name + ", DAY, -1)";
		
	ElsIf DataLimits = "StartFact" Then
		
		LowerBoundOfData = PeriodVariables.DataPeriodStart.Name;
		UpperBoundOfData = PeriodVariables.ActualDataLimit.Name;
		
	ElsIf DataLimits = "FactIsEnd" Then
		
		LowerBoundOfData = "AddToDate(" + PeriodVariables.ActualDataLimit.Name + ", DAY, 1)";
		UpperBoundOfData = PeriodVariables.DataPeriodEnd.Name;
		
	ElsIf DataLimits = "Arbitrary" Then
		
		LowerBoundOfData = PeriodVariables.DataPeriodStart.Name;
		UpperBoundOfData = PeriodVariables.DataPeriodEnd.Name;
		
	EndIf;
	
	FormControl();
	
EndProcedure

&AtClient
Procedure PeriodOptionRelativeToGroupingOnChange(Item)
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	
	If PeriodOptionRelativeToGrouping = "" Then
		
		GroupingPeriodStart = PeriodVariables.PeriodOfGrouping.Name;
		GroupingPeriodEnd = PeriodVariables.PeriodOfGrouping.Name;
		
	ElsIf PeriodOptionRelativeToGrouping = "SummingUp" Then
		
		GroupingPeriodStart = PeriodVariables.DataPeriodStart.Name;
		GroupingPeriodEnd = PeriodVariables.PeriodOfGrouping.Name;
		
	ElsIf PeriodOptionRelativeToGrouping = "WholePeriod" Then
		
		GroupingPeriodStart = PeriodVariables.DataPeriodStart.Name;
		GroupingPeriodEnd = PeriodVariables.DataPeriodEnd.Name;
		
	ElsIf PeriodOptionRelativeToGrouping = "Arbitrary" Then
		
		GroupingPeriodStart = PeriodVariables.PeriodOfGrouping.Name;
		GroupingPeriodEnd = PeriodVariables.PeriodOfGrouping.Name;
		
	EndIf;
	
	FormControl();
	
EndProcedure

&AtClient
Procedure LowerLimitOfTheTimePeriod(Item, StandardProcessing)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("ChangingFormula", ThisForm, "LowerBoundOfData");
	OpenForm("CommonForm.FormulasConstructor", 
		GetDataPeriodFormParameters(LowerBoundOfData),,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UpperLimitOfTheClickPeriod(Item, StandardProcessing)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("ChangingFormula", ThisForm, "UpperBoundOfData");
	OpenForm("CommonForm.FormulasConstructor", 
		GetDataPeriodFormParameters(UpperBoundOfData),,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TextOfTheBeginningOfTheGroupingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("ChangingFormula", ThisForm, "GroupingPeriodStart");
	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersForGroupingPeriodForm(GroupingPeriodStart),,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TextOfTheEndOfTheGroupingClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("ChangingFormula", ThisForm, "GroupingPeriodEnd");
	OpenForm("CommonForm.FormulasConstructor", 
		GetParametersForGroupingPeriodForm(GroupingPeriodEnd),,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibilityOfGroupingSettings(Var_Parameters)
	
	ThereIsPeriod = Catalogs.FinancialReportItems.ElementExpandedByPeriod(Var_Parameters, GroupingFrequency);
	Items.TheCompanyValues.Visible = ThereIsPeriod;
	
EndProcedure

&AtServer
Procedure SetPeriodOptions()
	
	PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
	
	If LowerBoundOfData = PeriodVariables.DataPeriodStart.Name
		And UpperBoundOfData = PeriodVariables.DataPeriodEnd.Name Then
		
		DataLimits = "";
		
	ElsIf LowerBoundOfData = PeriodVariables.ActualDataLimit.Name
		And UpperBoundOfData = "AddToDate(" + PeriodVariables.DataPeriodStart.Name + ", DAY, -1)" Then
		
		DataLimits = "FactBeginning";
		
	ElsIf LowerBoundOfData = PeriodVariables.DataPeriodStart.Name
		And UpperBoundOfData = PeriodVariables.ActualDataLimit.Name Then
		
		DataLimits = "StartFact";
		
	ElsIf LowerBoundOfData = "AddToDate(" + PeriodVariables.ActualDataLimit.Name + ", DAY, 1)"
		And UpperBoundOfData = PeriodVariables.DataPeriodEnd.Name Then
	
		DataLimits = "FactIsEnd";
		
	Else
		
		DataLimits = "Arbitrary";
		
	EndIf;
	
	If GroupingPeriodStart = PeriodVariables.PeriodOfGrouping.Name 
		And GroupingPeriodEnd = PeriodVariables.PeriodOfGrouping.Name Then
		
		PeriodOptionRelativeToGrouping = "";
		
	ElsIf GroupingPeriodStart = PeriodVariables.DataPeriodStart.Name
		And GroupingPeriodEnd = PeriodVariables.PeriodOfGrouping.Name Then
		
		PeriodOptionRelativeToGrouping = "SummingUp";
		
	ElsIf GroupingPeriodStart = PeriodVariables.DataPeriodStart.Name
		And GroupingPeriodEnd = PeriodVariables.DataPeriodEnd.Name Then
		
		PeriodOptionRelativeToGrouping = "WholePeriod";
		
	Else
		
		PeriodOptionRelativeToGrouping = "Arbitrary";
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FormControl()
	
	ArbitraryDataPeriod = DataLimits = "Arbitrary";
	
	Items.LowerBoundOfData.Enabled = ArbitraryDataPeriod;
	Items.UpperBoundOfData.Enabled = ArbitraryDataPeriod;
	
	ArbitraryGroupingPeriod = PeriodOptionRelativeToGrouping = "Arbitrary";
	
	Items.GroupingPeriodStart.Enabled = ArbitraryGroupingPeriod;
	Items.GroupingPeriodEnd.Enabled = ArbitraryGroupingPeriod;
	
EndProcedure

&AtClient
Procedure ChangingFormula(Result, FieldName) Export
	
	If Result <> Undefined Then
		ThisForm[FieldName] = Result;
	EndIf;
	
EndProcedure

&AtServer
Function BuildTreeOfOperators()
	
	OperatorsTree = FinancialReportingServerCall.BuildTreeOfOperators();
	PresentationOfOperatorGroup = NStr("vi = 'Chức năng';
										|ru = 'Функции';
										|en = 'Functions'; fa = 'توابع';
										|it = 'Funzioni';
										|pl = 'Funkcje';
										|tr = 'İşlevler'");
	FunctionString = OperatorsTree.Rows.Find(PresentationOfOperatorGroup, "Presentation");
	If FunctionString = Undefined Then
		FunctionString = OperatorsTree;
	EndIf;
	
	Id = "AddToDate";
	StructureToInsert = "DATEADD( , MONTH, 1)";
	Presentation = NStr("vi = 'Thêm tháng';
						|ru = 'Добавить месяц';
						|en = 'Add month'; fa = 'Add month';
						|it = 'Aggiungere mese';
						|pl = 'Dodaj miesiąc';
						|tr = 'Ay ekle'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "AddToDate";
	StructureToInsert = "DATEADD( , YEAR, 1)";
	Presentation = NStr("vi = 'Thêm năm';
						|ru = 'Добавить год';
						|en = 'Add year'; fa = 'Add year';
						|it = 'Aggiungere anno';
						|pl = 'Dodaj rok';
						|tr = 'Yıl ekle'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "BeginOfPeriod";
	StructureToInsert = "BEGINOFPERIOD( , YEAR, 1)";
	Presentation = NStr("vi = 'Đầu năm';
						|ru = 'Начало года';
						|en = 'Beginning of the year'; fa = 'ابتدای سال';
						|it = 'Inizio dell''anno';
						|pl = 'Początek roku';
						|tr = 'Yıl başlangıcı'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "BeginOfPeriod";
	StructureToInsert = "BEGINOFPERIOD( , HALFYEAR)";
	Presentation = NStr("vi = 'Đầu nửa năm';
						|ru = 'Начало полугодия';
						|en = 'Beginning of half-year'; fa = 'Beginning of half-year';
						|it = 'Inizio semestre';
						|pl = 'Pocztek półrocza';
						|tr = 'Yarıyılın başlangıcı'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "BeginOfPeriod";
	StructureToInsert = "BEGINOFPERIOD( , QUARTER)";
	Presentation = NStr("vi = 'Đầu quý';
						|ru = 'Начало квартала';
						|en = 'Quarter start'; fa = 'Quarter start';
						|it = 'Inizio trimestre';
						|pl = 'Początek kwartału';
						|tr = 'Çeyreğin başı'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "BeginOfPeriod";
	StructureToInsert = "BEGINOFPERIOD( , MONTH)";
	Presentation = NStr("vi = 'Đầu tháng';
						|ru = 'Начало месяца';
						|en = 'Month beginning'; fa = 'ابتدای ماه';
						|it = 'Inizio del mese';
						|pl = 'Początek miesiąca';
						|tr = 'Ay başlangıcı'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "BeginOfPeriod";
	StructureToInsert = "BEGINOFPERIOD( , WEEK)";
	Presentation = NStr("vi = 'Đầu tuần';
						|ru = 'Начало недели';
						|en = 'Week start'; fa = 'Week start';
						|it = 'Inizio della settimana';
						|pl = 'Początek tygodnia';
						|tr = 'Haftanın başı'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "EndOfPeriod";
	StructureToInsert = "ENDOFPERIOD( , YEAR)";
	Presentation = NStr("vi = 'Cuối năm';
						|ru = 'Конец года';
						|en = 'End of the year'; fa = 'پایان سال';
						|it = 'Fine dell''anno';
						|pl = 'Koniec roku';
						|tr = 'Yıl sonu'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "EndOfPeriod";
	StructureToInsert = "ENDOFPERIOD( , HALFYEAR)";
	Presentation = NStr("vi = 'Cuối nửa năm';
						|ru = 'Конец полугодия';
						|en = 'End of half-year'; fa = 'End of half-year';
						|it = 'Fine semestre';
						|pl = 'Koniec półrocza';
						|tr = 'Yarıyılın sonu'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "EndOfPeriod";
	StructureToInsert = "ENDOFPERIOD( , QUARTER)";
	Presentation = NStr("vi = 'Cuối quý';
						|ru = 'Конец квартала';
						|en = 'End of quarter'; fa = 'End of quarter';
						|it = 'Fine trimestre';
						|pl = 'Koniec kwartału';
						|tr = 'Çeyreğin sonu'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "EndOfPeriod";
	StructureToInsert = "ENDOFPERIOD( , MONTH)";
	Presentation = NStr("vi = 'Cuối tháng';
						|ru = 'Конец месяца';
						|en = 'End of the month'; fa = 'End of the month';
						|it = 'Fine mese';
						|pl = 'Koniec miesiąca';
						|tr = 'Ay sonu'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Id = "EndOfPeriod";
	StructureToInsert = "ENDOFPERIOD( , WEEK)";
	Presentation = NStr("vi = 'Cuối tuần';
						|ru = 'Конец недели';
						|en = 'End of the week'; fa = 'End of the week';
						|it = 'Fine della settimana';
						|pl = 'Koniec tygodnia';
						|tr = 'Haftanın sonu'");
	ProcessingOfFormulas.AddOperator(FunctionString,
	                                  Id,
	                                  StructureToInsert,
	                                  Presentation);
	
	Return PutToTempStorage(OperatorsTree);
	
EndFunction

&AtServer
Function GetDataPeriodFormParameters(Formula)
	
	PeriodVariablesWithoutBrackets = BudgetReportingClientServer.VariablesOfBudgetingPeriods(True);
	DateDetails = New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime));
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.DataPeriodStart.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.DataPeriodStart.Presentation;
	NewRow.ValueType = DateDetails;
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.DataPeriodEnd.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.DataPeriodEnd.Presentation;
	NewRow.ValueType = DateDetails;
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.ActualDataLimit.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.ActualDataLimit.Presentation;
	NewRow.ValueType = DateDetails;
	
	AddressTreeOfOperands = PutToTempStorage(OperandsTree);
	
	ReturnParameters = New Structure;
	ReturnParameters.Insert("Formula",                      Formula);
	ReturnParameters.Insert("OperandsTree",              AddressTreeOfOperands);
	ReturnParameters.Insert("OperandsTitle",            NStr("vi = 'Ngày tính toán';
															|ru = 'Даты для расчета';
															|en = 'Dates for calculation'; fa = 'Dates for calculation';
															|it = 'Dati per il calcolo';
															|pl = 'Daty do rozliczenia';
															|tr = 'Hesaplama tarihleri'"));
	ReturnParameters.Insert("Operators",                    BuildTreeOfOperators());
	ReturnParameters.Insert("FormulaForCalculationInQuery", True);
	ReturnParameters.Insert("ResultType",                Common.DateTypeDetails(DateFractions.DateTime));
	ReturnParameters.Insert("NotUsePresentation",  True);
	
	Return ReturnParameters;
	
EndFunction

&AtServer
Function GetParametersForGroupingPeriodForm(Formula)
	
	PeriodVariablesWithoutBrackets = BudgetReportingClientServer.VariablesOfBudgetingPeriods(True);
	DateDetails = New TypeDescription("Date",,, New DateQualifiers(DateFractions.DateTime));
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.DataPeriodStart.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.DataPeriodStart.Presentation;
	NewRow.ValueType = DateDetails;
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.DataPeriodEnd.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.DataPeriodEnd.Presentation;
	NewRow.ValueType = DateDetails;
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.PeriodOfGrouping.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.PeriodOfGrouping.Presentation;
	NewRow.ValueType = DateDetails;
	
	NewRow = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	NewRow.Id = PeriodVariablesWithoutBrackets.ActualDataLimit.Name;
	NewRow.Presentation = PeriodVariablesWithoutBrackets.ActualDataLimit.Presentation;
	NewRow.ValueType = DateDetails;
	
	AddressTreeOfOperands = PutToTempStorage(OperandsTree);
	
	ReturnParameters = New Structure;
	ReturnParameters.Insert("Formula",                      Formula);
	ReturnParameters.Insert("OperandsTree",              AddressTreeOfOperands);
	ReturnParameters.Insert("OperandsTitle",            NStr("vi = 'Ngày tính toán';
															|ru = 'Даты для расчета';
															|en = 'Dates for calculation'; fa = 'Dates for calculation';
															|it = 'Dati per il calcolo';
															|pl = 'Daty do rozliczenia';
															|tr = 'Hesaplama tarihleri'"));
	ReturnParameters.Insert("Operators",                    BuildTreeOfOperators());
	ReturnParameters.Insert("FormulaForCalculationInQuery", True);
	ReturnParameters.Insert("ResultType",                Common.DateTypeDetails(DateFractions.DateTime));
	ReturnParameters.Insert("NotUsePresentation",  True);
	
	Return ReturnParameters;
	
EndFunction

#EndRegion