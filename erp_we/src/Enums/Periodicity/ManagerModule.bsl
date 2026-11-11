#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns an ordered array of periodicities.
//
// Returns:
// 	 Array, ValueTable - periodicity from "small" to "large"
//
// Parameters:
// 	 ReturnAsTable - Boolean - If True, returns a table of values
//
Function OrderedPeriodicities(ReturnAsTable = False) Export
	
	Periodicity_ = BudgetReportingClientServer.OrderedPeriodicities();
	
	If ReturnAsTable Then
		PeriodicityTable = New ValueTable;
		PeriodicityTable.Columns.Add("Order", New TypeDescription("Number"));
		PeriodicityTable.Columns.Add("Periodicity", New TypeDescription("EnumRef.Periodicity"));
		For Each Periodicity In Periodicity_ Do
			NewLinePeriodicity = PeriodicityTable.Add();
			NewLinePeriodicity.Periodicity = Periodicity;
			NewLinePeriodicity.Order = PeriodicityTable.IndexOf(NewLinePeriodicity);
		EndDo;
		Periodicity_ = PeriodicityTable;
	EndIf;
	
	Return Periodicity_;
	
EndFunction

// Returns the number of subperiods in the period
//
// Parameters:
// 	Periodicity - EnumRef.Periodicity - The periodicity for which the number of subperiods is determined
// 	SubperiodFrequency - EnumRef.Periodicity - Periodicity, the number of periods to find
// 
// Returns:
// 	 Number - The number of periods found
//
Function NumberOfPeriods(Periodicity, SubperiodFrequency) Export
	
	Table = RatioOfPeriods();
	NumberOfPeriods = 0;
	
	Rows = Table.FindRows(New Structure("Periodicity, SubperiodFrequency", Periodicity, SubperiodFrequency));
	If Not Rows.Count() = 0 Then
		NumberOfPeriods = Rows[0].NumberOfPeriods;
	EndIf;
	
	If NumberOfPeriods = 0 Then
		ErrorText = NStr("vi = 'Chỉ tiêu phi tài chính hiển thị giá trị định kỳ không chính xác cho giai đoạn chính và lồng nhau';
						|ru = 'В нефинансовом показателе указаны некорректные значения периодичностей основного и вложенного периодов';
						|en = 'Non-financial item shows incorrect frequency values for the main and nested period'; fa = 'Non-financial item shows incorrect frequency values for the main and nested period';
						|it = 'Nell''indicatore non finanziario sono stati indicati valori errati di periodicità dei periodi principale e secondario';
						|pl = 'Wskaźnik niefinansowy pokazuje nieprawidłowe wartości okresowości okresów głównych i podręcznych.';
						|tr = 'Finansal olmayan öğede ana ve iç içe geçmiş dönemlerin dönemselliğine dair yanlış değerler belirtilmiş'");
		Raise ErrorText;
	EndIf;
	
	Return NumberOfPeriods;
	
EndFunction

Function RatioOfPeriods()
	
	// Generation of the period ratio table. The number of periods is specified normatively
	// (excluding leap year), because the value of the non-financial indicator may be valid for the following periods
	// until a new value is entered.
	
	RatioOfPeriods = New ValueTable;
	RatioOfPeriods.Columns.Add("Periodicity", New TypeDescription("EnumRef.Periodicity"));
	RatioOfPeriods.Columns.Add("SubperiodFrequency", New TypeDescription("EnumRef.Periodicity"));
	RatioOfPeriods.Columns.Add("NumberOfPeriods", New TypeDescription("Number",,, New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Year;
	RelationString.SubperiodFrequency = Enums.Periodicity.HalfYear;
	RelationString.NumberOfPeriods       = 2;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Year;
	RelationString.SubperiodFrequency = Enums.Periodicity.Quarter;
	RelationString.NumberOfPeriods       = 4;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Year;
	RelationString.SubperiodFrequency = Enums.Periodicity.Month;
	RelationString.NumberOfPeriods       = 12;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Year;
	RelationString.SubperiodFrequency = Enums.Periodicity.TenDays;
	RelationString.NumberOfPeriods       = 36;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Year;
	RelationString.SubperiodFrequency = Enums.Periodicity.Week;
	RelationString.NumberOfPeriods       = 53;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Year;
	RelationString.SubperiodFrequency = Enums.Periodicity.Day;
	RelationString.NumberOfPeriods       = 365;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.HalfYear;
	RelationString.SubperiodFrequency = Enums.Periodicity.Quarter;
	RelationString.NumberOfPeriods       = 2;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.HalfYear;
	RelationString.SubperiodFrequency = Enums.Periodicity.Month;
	RelationString.NumberOfPeriods       = 6;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.HalfYear;
	RelationString.SubperiodFrequency = Enums.Periodicity.TenDays;
	RelationString.NumberOfPeriods       = 18;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.HalfYear;
	RelationString.SubperiodFrequency = Enums.Periodicity.Week;
	RelationString.NumberOfPeriods       = 27;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.HalfYear;
	RelationString.SubperiodFrequency = Enums.Periodicity.Day;
	RelationString.NumberOfPeriods       = 184;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Quarter;
	RelationString.SubperiodFrequency = Enums.Periodicity.Month;
	RelationString.NumberOfPeriods       = 3;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Quarter;
	RelationString.SubperiodFrequency = Enums.Periodicity.TenDays;
	RelationString.NumberOfPeriods       = 9;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Quarter;
	RelationString.SubperiodFrequency = Enums.Periodicity.Week;
	RelationString.NumberOfPeriods       = 14;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Quarter;
	RelationString.SubperiodFrequency = Enums.Periodicity.Day;
	RelationString.NumberOfPeriods       = 92;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Month;
	RelationString.SubperiodFrequency = Enums.Periodicity.TenDays;
	RelationString.NumberOfPeriods       = 3;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Month;
	RelationString.SubperiodFrequency = Enums.Periodicity.Week;
	RelationString.NumberOfPeriods       = 5;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Month;
	RelationString.SubperiodFrequency = Enums.Periodicity.Day;
	RelationString.NumberOfPeriods       = 31;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.TenDays;
	RelationString.SubperiodFrequency = Enums.Periodicity.Week;
	RelationString.NumberOfPeriods       = 2;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.TenDays;
	RelationString.SubperiodFrequency = Enums.Periodicity.Day;
	RelationString.NumberOfPeriods       = 10;
	
	RelationString = RatioOfPeriods.Add();
	RelationString.Periodicity            = Enums.Periodicity.Week;
	RelationString.SubperiodFrequency = Enums.Periodicity.Day;
	RelationString.NumberOfPeriods       = 7;
	
	Return RatioOfPeriods;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("Scenario") Then
		
		StandardProcessing = False;
		ChoiceData = New ValueList;
		
		BudgetingScenarios = New Array;
		BudgetingScenarios.Add(Parameters.Scenario);
		If Parameters.Property("ScenarioForComparison") Then
			BudgetingScenarios.Add(Parameters.ScenarioForComparison);
		EndIf;
		
		PeriodicityOfScenarios = Common.ObjectsAttributeValue(BudgetingScenarios, "Periodicity");
		PeriodicityInOrder = OrderedPeriodicities();
		
		IndexForSelection = 0;
		For Each Item In PeriodicityOfScenarios Do
			
			IndexOf = PeriodicityInOrder.Find(Item.Value);
			If IndexOf > IndexForSelection Then
				IndexForSelection = IndexOf;
			EndIf;
			
		EndDo;
		
		For IndexOf = IndexForSelection To PeriodicityInOrder.Count() - 1 Do
			ChoiceData.Add(PeriodicityInOrder.Get(IndexOf));
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf