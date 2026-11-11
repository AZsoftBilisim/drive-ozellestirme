#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function FunctionText(EnumValueName) Export
	
	Manager = Enums.BudgetingFormulaKinds;
	Value = Manager[EnumValueName];
	If Value = Manager.Max
		Or Value = Manager.Min
		Or Value = Manager.Sum
		Or Value = Manager.AVG
		Then
		
		Return FunctionName(Value)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(%1, %2, , %3)",
				NStr("vi = '<Giá trị 1>';
					|ru = '<Значение 1>';
					|en = '<Value 1>'; fa = '<Value 1>';
					|it = '<Valore 1>';
					|pl = '<Wartość 1>';
					|tr = '<Değer 1>'"),
				NStr("vi = '<Giá trị 2>';
					|ru = '<Значение 2>';
					|en = '<Value 2>'; fa = '<Value 2>';
					|it = '<Valore 2>';
					|pl = '<Wartość 2>';
					|tr = '<Değer 2>'"),
				NStr("vi = '<Giá trị N>';
					|ru = '<Значение N>';
					|en = '<Value N>'; fa = '<Value N>';
					|it = '<Valore N>';
					|pl = '<Wartość N>';
					|tr = '<Değer N>'"));
		
	ElsIf Value = Manager.Deviation 
		Or Value = Manager.VariancePercent
		Or Value = Manager.PerformancePercentage Then
		
		Return FunctionName(Value)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(%1, %2, , %3)",
				NStr("vi = '<Cột chính>';
					|ru = '<Ведущая колонка>';
					|en = '<Leading column>'; fa = '<Leading column>';
					|it = '<Colonna principale>';
					|pl = '<Kolumna wiodąca>';
					|tr = '<Sunucu sütun>'"),
				NStr("vi = '<So sánh cột 1>';
					|ru = '<Сравниваемая колонка 1>';
					|en = '<Comparable column 1>'; fa = '<Comparable column 1>';
					|it = '<Colonna di comparazione 1>';
					|pl = '<Porównywana kolumna 1>';
					|tr = '<Karşılaştırılan sütun 1>'"),
				NStr("vi = '<So sánh cột N>';
					|ru = '<Сравниваемая колонка N>';
					|en = '<Comparable column N>'; fa = '<Comparable column N>';
					|it = '<Colonna di comparazione N>';
					|pl = '<Porównywana kolumna N>';
					|tr = '<Karşılaştırılan sütun N>'"));
		
	ElsIf Value = Manager.RoundOff Then
		
		Return FunctionName(Value)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(%1, %2)",
				NStr("vi = '<Giá trị >';
					|ru = '<Значение>';
					|en = '<Value>'; fa = '<Value>';
					|it = '<Valore>';
					|pl = '<Value>';
					|tr = '<Değer>'"),
				NStr("vi = '<Số lượng ký tự>';
					|ru = '<Число знаков>';
					|en = '<Number of symbols>'; fa = '<Number of symbols>';
					|it = '<Numero simboli>';
					|pl = '<Liczba znaków>';
					|tr = '<İşaretlerin sayısı>'"));
		
	ElsIf Value = Manager.Total Then
		
		Return FunctionName(Value)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(%1, %2)",
				NStr("vi = '<Giá trị >';
					|ru = '<Значение>';
					|en = '<Value>'; fa = '<Value>';
					|it = '<Valore>';
					|pl = '<Value>';
					|tr = '<Değer>'"),
				NStr("vi = '<Hướng>';
					|ru = '<Направление>';
					|en = '<Direction>'; fa = '<Direction>';
					|it = '<Destinazione>';
					|pl = '<Direction>';
					|tr = 'Yön'"));
		
	ElsIf Value = Manager.DateDiff Then
		
		PeriodVariables = BudgetReportingClientServer.VariablesOfBudgetingPeriods();
		FunctionText = FunctionName(Value)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"(%1, %2, ""Month"")",
				PeriodVariables.DataPeriodStart.Name,
				PeriodVariables.DataPeriodEnd.Name);
		
		Return FunctionText;
		
	Else 
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hàm không xác định: %1';
				|ru = 'Неизвестная функция: %1';
				|en = 'Unknown function: %1'; fa = 'Unknown function: %1';
				|it = 'Funzione sconosciuta: %1';
				|pl = 'Nieznana funkcja: %1';
				|tr = 'Belirsiz fonksiyon: %1'"),
			EnumValueName);
	EndIf;
	
EndFunction

Function FunctionName(Value) Export
	
	Manager = Enums.BudgetingFormulaKinds;
	If Value = Manager.Max Then
		Return "MAX";
	ElsIf Value = Manager.Min Then
		Return "MIN";
	ElsIf Value = Manager.Sum Then
		Return "SUM";
	ElsIf Value = Manager.AVG Then
		Return "AVG";
	ElsIf Value = Manager.Deviation Then
		Return "DEVIATION";
	ElsIf Value = Manager.VariancePercent Then
		Return "VARIANCEPERCENTAGE";
	ElsIf Value = Manager.PerformancePercentage Then
		Return "PROGRESSPERCENT";
	ElsIf Value = Manager.RoundOff Then
		Return "ROUNDOFF";
	ElsIf Value = Manager.Total Then
		Return "TOTAL";
	ElsIf Value = Manager.DateDiff Then
		Return "DATEDIFF";
	Else 
		Raise "Unknown_ function: " + Value;
	EndIf;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	Manager = Enums.BudgetingFormulaKinds;
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	ChoiceData.Add(Manager.Sum);
	ChoiceData.Add(Manager.Deviation);
	ChoiceData.Add(Manager.VariancePercent);
	ChoiceData.Add(Manager.PerformancePercentage);
	ChoiceData.Add(Manager.AVG);
	ChoiceData.Add(Manager.Max);
	ChoiceData.Add(Manager.Min);
	
EndProcedure

#EndRegion
