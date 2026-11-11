////////////////////////////////////////////////////////////////////////////////
// General planning procedures and functions
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Retrieves the operands from the text of the formula
//
// Parameters:
//  Formula - String - text of the formula.
//
// Returns:
//  Array of String - Operands from a text formula (without external brackets, for example, "Nomenclature.{DR.Forwarder}").
//
Function OperandsOfTextFormula(Formula) Export
	
	ArrayOfOperands = ProcessingOfFormulasClientServer.OperandsOfTextFormula(Formula);
	
	If (ArrayOfOperands.Find("PlannedFinalBalances") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalDeficit") <> Undefined)
		And ArrayOfOperands.Find("PlannedStartBalance") = Undefined Then
		
		ArrayOfOperands.Add("PlannedStartBalance");
		
	EndIf;
	
	If (ArrayOfOperands.Find("PlannedFinalBalancesWithSelection") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalDeficitWithSelection") <> Undefined)
		And ArrayOfOperands.Find("PlannedStartBalanceWithSelection") = Undefined Then
		
		ArrayOfOperands.Add("PlannedStartBalanceWithSelection");
		
	EndIf;
	
	If (ArrayOfOperands.Find("PlannedStartBalance") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalBalances") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalDeficit") <> Undefined)
		Or ArrayOfOperands.Find("ParishPlans") <> Undefined Then
		
		If ArrayOfOperands.Find("PurchasePlans") = Undefined Then
			ArrayOfOperands.Add("PurchasePlans");
		EndIf;
		If ArrayOfOperands.Find("ProductionPlans") = Undefined Then
			ArrayOfOperands.Add("ProductionPlans");
		EndIf;
		If ArrayOfOperands.Find("ReleasePlans") = Undefined Then
			ArrayOfOperands.Add("ReleasePlans");
		EndIf;
		If ArrayOfOperands.Find("AssemblyPlansKits") = Undefined Then
			ArrayOfOperands.Add("AssemblyPlansKits");
		EndIf;
		
		If ArrayOfOperands.Find("DisassemblyPlansComponents") = Undefined Then
			ArrayOfOperands.Add("DisassemblyPlansComponents");
		EndIf;
		
	EndIf;
	
	If (ArrayOfOperands.Find("PlannedStartBalance") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalBalances") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalDeficit") <> Undefined)
		Or ArrayOfOperands.Find("ExpensePlans") <> Undefined Then
		
		If ArrayOfOperands.Find("SalesPlans") = Undefined Then
			ArrayOfOperands.Add("SalesPlans");
		EndIf;
		
		If ArrayOfOperands.Find("InventoryConsumptionPlans") = Undefined Then
			ArrayOfOperands.Add("InventoryConsumptionPlans");
		EndIf;
		If ArrayOfOperands.Find("ProductionPlansMaterials") = Undefined Then
			ArrayOfOperands.Add("ProductionPlansMaterials");
		EndIf;
		If ArrayOfOperands.Find("ProductionPlansNeedForSemiFinishedProducts") = Undefined Then
			ArrayOfOperands.Add("ProductionPlansNeedForSemiFinishedProducts");
		EndIf;
		If ArrayOfOperands.Find("DisassemblyPlansKits") = Undefined Then
			ArrayOfOperands.Add("DisassemblyPlansKits");
		EndIf;
		
		If ArrayOfOperands.Find("BuildPlansComponents") = Undefined Then
			ArrayOfOperands.Add("BuildPlansComponents");
		EndIf;
		
		If ArrayOfOperands.Find("AdjustmentsToPlannedDemands") = Undefined Then
			ArrayOfOperands.Add("AdjustmentsToPlannedDemands");
		EndIf;
		
	EndIf;
	
	If (ArrayOfOperands.Find("PlannedStartBalanceWithSelection") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalBalancesWithSelection") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalDeficitWithSelection") <> Undefined)
		Or ArrayOfOperands.Find("ParishPlansWithSelection") <> Undefined Then
		
		If ArrayOfOperands.Find("PurchasePlansWithSelection") = Undefined Then
			ArrayOfOperands.Add("PurchasePlansWithSelection");
		EndIf;
		If ArrayOfOperands.Find("ProductionPlansWithPicking") = Undefined Then
			ArrayOfOperands.Add("ProductionPlansWithPicking");
		EndIf;
		If ArrayOfOperands.Find("ReleasePlansWithSelection") = Undefined Then
			ArrayOfOperands.Add("ReleasePlansWithSelection");
		EndIf;
		If ArrayOfOperands.Find("AssemblyPlansKitsWithSelection") = Undefined Then
			ArrayOfOperands.Add("AssemblyPlansKitsWithSelection");
		EndIf;
		
		If ArrayOfOperands.Find("DisassemblyPlansComponentsWithSelection") = Undefined Then
			ArrayOfOperands.Add("DisassemblyPlansComponentsWithSelection");
		EndIf;
		
	EndIf;
	
	If (ArrayOfOperands.Find("PlannedStartBalanceWithSelection") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalBalancesWithSelection") <> Undefined
		Or ArrayOfOperands.Find("PlannedFinalDeficitWithSelection") <> Undefined)
		Or ArrayOfOperands.Find("ExpensePlansWithSelection") <> Undefined Then
		
		If ArrayOfOperands.Find("SalesPlansWithSelection") = Undefined Then
			ArrayOfOperands.Add("SalesPlansWithSelection");
		EndIf;
		
		If ArrayOfOperands.Find("InventoryConsumptionPlansWithSelection") = Undefined Then
			ArrayOfOperands.Add("InventoryConsumptionPlansWithSelection");
		EndIf;
		If ArrayOfOperands.Find("ProductionPlansMaterialsWithSelection") = Undefined Then
			ArrayOfOperands.Add("ProductionPlansMaterialsWithSelection");
		EndIf;
		If ArrayOfOperands.Find("ProductionPlansNeedForSemiFinishedProductsWithSelection") = Undefined Then
			ArrayOfOperands.Add("ProductionPlansNeedForSemiFinishedProductsWithSelection");
		EndIf;
		If ArrayOfOperands.Find("DisassemblyPlansKitsWithSelection") = Undefined Then
			ArrayOfOperands.Add("DisassemblyPlansKitsWithSelection");
		EndIf;
		
		If ArrayOfOperands.Find("BuildPlansComponentsWithSelection") = Undefined Then
			ArrayOfOperands.Add("BuildPlansComponentsWithSelection");
		EndIf;
		
		If ArrayOfOperands.Find("AdjustmentsToPlannedDemandsWithSelection") = Undefined Then
			ArrayOfOperands.Add("AdjustmentsToPlannedDemandsWithSelection");
		EndIf;
		
	EndIf;
	
	Return ArrayOfOperands;
	
EndFunction

#Region CrossTableProcedures

// Converting a Table to a Cross-table with transferring the values of the period details to the columns of the cross-table.
//
// Parameters:
//  CrossTable - FormDataCollection - Cross-table in the form
//  Table      - FormDataCollection - Table part of the object
//  Parameters    - Structure - Additional settings passed to the procedure:
//                            Table Periods, Periodicity, structurerequisitovperiod, structurequisits, 
//                            Grouping fields
//  SemiFinishedProductsByDate - ValueTable
//
Procedure FillInCrossTableFromTable(CrossTable, Table, Parameters, SemiFinishedProductsByDate = Undefined) Export
	
	TablePeriods             = Parameters.TablePeriods;
	Periodicity              = Parameters.Periodicity;
	StructureOfPeriodDetails = Parameters.StructureOfPeriodDetails;
	AttributesStructure1        = Parameters.AttributesStructure1;
	GroupFields            = Parameters.GroupFields;
	
	StructureOfFinalDetails = Undefined;
	If Not Parameters.Property("StructureOfFinalDetails", StructureOfFinalDetails) Then
		StructureOfFinalDetails = New Structure;
	EndIf;
	
	CrossTable.Clear();
	If SemiFinishedProductsByDate <> Undefined Then
		SemiFinishedProductsByDate.Clear();
	EndIf;
	
	ExceptionString_ = "";
	For Each FinalProps In StructureOfFinalDetails Do
		ExceptionString_ = ExceptionString_ + ?(IsBlankString(ExceptionString_), "", ", ") + FinalProps.Key;
	EndDo;
	
	For Each TableRow In Table Do
		Filter = New Structure;
		For Each Item In StructureOfPeriodDetails Do
			If Item.Key = "EndDate" Then
				Filter.Insert(
					Item.Key, 
					PlanningClientServerCached.CalculatePeriodEndDate(TableRow[Item.Value], Periodicity));
			Else
				Filter.Insert(
					Item.Key, 
					PlanningClientServerCached.CalculateStartDateOfPeriod(TableRow[Item.Value], Periodicity));
			EndIf;
		EndDo;
		
		FoundPeriodStrings = TablePeriods.FindRows(Filter);
		
		If Not IsBlankString(GroupFields) Then
			Filter = New Structure(GroupFields);
			FillPropertyValues(Filter, TableRow);
			FoundRows = CrossTable.FindRows(Filter);
			If FoundRows.Count()=0 Then
				NewRow = CrossTable.Add();
			Else
				NewRow = FoundRows[0];
			EndIf;
			
			If SemiFinishedProductsByDate <> Undefined
				And TableRow.SemiFinishedProduct Then
				Filter = New Structure(GroupFields + ", ReleaseDateOfProductsOrSemiFinishedProduct");
				FillPropertyValues(Filter, TableRow);
				FoundRowsSemiFinishedProducts = SemiFinishedProductsByDate.FindRows(Filter);
				If FoundRowsSemiFinishedProducts.Count()=0 Then
					NewLineSemiFinishedProducts = SemiFinishedProductsByDate.Add();
				Else
					NewLineSemiFinishedProducts = FoundRowsSemiFinishedProducts[0];
				EndIf;
			EndIf;
		Else
			NewRow = CrossTable.Add();
		EndIf;
		
		FillPropertyValues(NewRow, TableRow,,ExceptionString_);
		If SemiFinishedProductsByDate <> Undefined 
			And TableRow.SemiFinishedProduct Then
			FillPropertyValues(NewLineSemiFinishedProducts, TableRow,,ExceptionString_);
		EndIf;
		
		If FoundPeriodStrings.Count() = 0 Then 
			Continue;
		EndIf;
		PeriodString_ = FoundPeriodStrings[0];
		
		For Each Item In AttributesStructure1 Do
			If StructureOfFinalDetails.Property(Item.Value) Then
				NewRow[Item.Key + PeriodString_.ColumnName] = NewRow[Item.Key + PeriodString_.ColumnName] + TableRow[Item.Value];
			ElsIf Item.Value = "Details"
				And ValueIsFilled(NewRow[Item.Key + PeriodString_.ColumnName])
				And ValueIsFilled(TableRow[Item.Value]) Then
				
				ArrayOfNSStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(NewRow[Item.Key + PeriodString_.ColumnName], " = ");
				RowsArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(TableRow[Item.Value], " = ");
				If RowsArray.Count() > 1 And ArrayOfNSStrings.Count() > 1 Then
					ArrayOfNSStrings[0] = ArrayOfNSStrings[0] + " + " + RowsArray[0];
					ArrayOfNSStrings[1] = ArrayOfNSStrings[1] + " + " + RowsArray[1];
					
					NewRow[Item.Key + PeriodString_.ColumnName] = ArrayOfNSStrings[0] + " = " + ArrayOfNSStrings[1]
						+ " = " + NewRow["Count_"+ PeriodString_.ColumnName];
				ElsIf RowsArray.Count() > 1 Then
					NewRow[Item.Key + PeriodString_.ColumnName] = ArrayOfNSStrings[0] + " + " + RowsArray[0]
						+ " = " + ArrayOfNSStrings[0] + " + " + RowsArray[1]
						+ " = " + NewRow["Count_"+ PeriodString_.ColumnName];
				EndIf;
			
			Else
				NewRow[Item.Key + PeriodString_.ColumnName] = TableRow[Item.Value];
			EndIf;
		EndDo;
		
		For Each Item In StructureOfFinalDetails Do
			NewRow[Item.Value] = NewRow[Item.Value] + TableRow[Item.Key];
		EndDo;
		
		If SemiFinishedProductsByDate <> Undefined 
			And TableRow.SemiFinishedProduct Then
			
			For Each Item In AttributesStructure1 Do
				If StructureOfFinalDetails.Property(Item.Value) Then
					NewLineSemiFinishedProducts[Item.Key + PeriodString_.ColumnName] = NewLineSemiFinishedProducts[Item.Key + PeriodString_.ColumnName] + TableRow[Item.Value];
				Else
					NewLineSemiFinishedProducts[Item.Key + PeriodString_.ColumnName] = TableRow[Item.Value];
				EndIf;
			EndDo;
			
			For Each Item In StructureOfFinalDetails Do
				NewLineSemiFinishedProducts[Item.Value] = NewLineSemiFinishedProducts[Item.Value] + TableRow[Item.Key];
			EndDo;
			
			NewRow["Substituted_" + PeriodString_.ColumnName] = False;
			NewRow["SubstitutedToOrder_" + PeriodString_.ColumnName] = False;
			NewRow["Canceled_" + PeriodString_.ColumnName] = False;
			NewRow["Comment_" + PeriodString_.ColumnName] = "";
			
		EndIf;
		
	EndDo;
			
EndProcedure

// The procedure calculates the added "row Number" field for the crosstab
//
// Parameters:
//  Form                    - ClientApplicationForm - A form that has a cross-table
//  NameOfCrossTableProps - String - Name of the cross-table in the form.
//
Procedure CalculateCrossTableRowNumber(Form, Val NameOfCrossTableProps) Export 

	CrossTable = Form[NameOfCrossTableProps]; // See ServiceCrossTable 
	 
	LineNumber = 0;
	For Each TSRow In CrossTable Do
		
		LineNumber = LineNumber + 1;
		TSRow.LineNumber = LineNumber;
	
	EndDo; 

EndProcedure
 
#EndRegion 

// Returns a service table of values
//
// Returns:
//  ValueTable - Contains:
//  * LineNumber - Number - 
//
Function ServiceCrossTable() Export
	
	Return Undefined;
	
EndFunction


#Region  GeneralPurposePlanningProceduresAndFunctions

// Calculating the start and end dates of the planning period with the specified frequency
//
// Parameters:
//  Periodicity  	- EnumRef.Periodicity - The frequency with which you want to calculate the date
//  BeginOfPeriod  	- Date - start date of the period
//  PeriodEnding  	- Date - end date of the period.
//  CurrentSessionDate   - Date - Current date.
//  NumberOfPeriods - Number
//  RequiresRecalculationOfEndOfPeriod - Boolean
//
Procedure SetStartEndOfPlanPeriod(Val Periodicity, BeginOfPeriod, PeriodEnding, CurrentSessionDate, NumberOfPeriods = 1, RequiresRecalculationOfEndOfPeriod = False) Export 
	
	If Not ValueIsFilled(Periodicity) Then
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(BeginOfPeriod) Then
		
		BeginOfPeriod = CalculateStartDateOfPeriod(BeginOfPeriod, Periodicity);
		
	Else
		
		BeginOfPeriod = CalculateStartDateOfPeriod(CurrentSessionDate, Periodicity);
		
	EndIf;
	
	If RequiresRecalculationOfEndOfPeriod Then
		
		PeriodEnding = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, NumberOfPeriods);
		
	ElsIf ValueIsFilled(PeriodEnding) And Periodicity = PredefinedValue("Enum.Periodicity.Day") And PeriodEnding > BeginOfPeriod Then
		// Recalculation of the end date is not necessary
	ElsIf ValueIsFilled(PeriodEnding) And PeriodEnding > BeginOfPeriod Then
		
		BeginningOfLastPeriod = CalculateStartDateOfPeriod(PeriodEnding, Periodicity);
		PeriodEnding = TMCommonUseClientServer.CalculatePeriodEndDate(BeginningOfLastPeriod, Periodicity, 1);
		
	Else
		
		PeriodEnding = TMCommonUseClientServer.CalculatePeriodEndDate(BeginOfPeriod, Periodicity, NumberOfPeriods);
		
	EndIf;
	
EndProcedure

// Generates a header for a date interval with the specified frequency (Day, week, decade, month, etc.).
//
// Parameters:
//  Periodicity 	- EnumRef.Periodicity - Frequency for which you need to generate a header
//  StartDate 		- Date - start date of the period
//  EndDate 	- Date - Period end date
//  ShowNumberOfPeriod  - Boolean - Flag for displaying the title by period number within a year.
//  Substituted - Boolean
//
// Returns:
//  String - Text representation of the period title.
//
Function GeneratePeriodHeader(Val Periodicity, Val StartDate, Val EndDate, Val ShowNumberOfPeriod = False, Substituted = False) Export
	
	Title = "";
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		If ShowNumberOfPeriod Then
			Title = Format(DayOfYear(StartDate), "NFD=0; NG=0") + " " + NStr("vi = 'ngày';
																			|ru = 'день';
																			|en = 'Day'; fa = 'روز';
																			|it = 'giorno';
																			|pl = 'dzień';
																			|tr = 'gün'");
		Else
			Title = Format(StartDate, "DLF=D");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		If ShowNumberOfPeriod Then
			Title = NStr("vi = '%WeekNumber% tuần';
						|ru = '%WeekNumber% неделя';
						|en = '%WeekNumber% week'; fa = '%WeekNumber% week';
						|it = '%WeekNumber% settimana';
						|pl = '%WeekNumber% tydzień';
						|tr = 'hafta %WeekNumber%'");
			If Year(StartDate) <> Year(EndDate) Then
				WeekNumber = Format(WeekOfYear(StartDate), "NFD=0; NG=0") + "/" +  Format(WeekOfYear(EndDate), "NFD=0; NG=0");
			Else
				WeekNumber = Format(WeekOfYear(StartDate), "NFD=0; NG=0");
			EndIf; 
			Title = StrReplace(Title, "%WeekNumber%", WeekNumber);
		Else
			TextStartDate = Format(BegOfDay(StartDate)+1, NStr("vi = 'ДФ=дд.ММ';
																|ru = 'ДФ=dd.MM';
																|en = 'DF=MM/dd'; fa = 'DF=MM/dd';
																|it = 'ДФ=дд.ММ';
																|pl = 'DF=dd.MM';
																|tr = 'DF=dd.MM'")); 
			TextEndDate = Format(EndDate, NStr("vi = 'ДФ=дд.ММ';
												|ru = 'ДФ=dd.MM';
												|en = 'DF=MM/dd'; fa = 'DF=MM/dd';
												|it = 'ДФ=дд.ММ';
												|pl = 'DF=dd.MM';
												|tr = 'DF=dd.MM'"));
			Title   = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 - %2';
																					|ru = '%1 - %2';
																					|en = '%1 - %2'; fa = '%1 - %2';
																					|it = '%1 - %2';
																					|pl = '%1 - %2';
																					|tr = '%1 - %2'"), TextStartDate, TextEndDate);
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		TextStartDate = Format(BegOfDay(StartDate)+1, NStr("vi = 'ДФ=дд.ММ';
															|ru = 'ДФ=dd.MM';
															|en = 'DF=MM/dd'; fa = 'DF=MM/dd';
															|it = 'ДФ=дд.ММ';
															|pl = 'DF=dd.MM';
															|tr = 'DF=dd.MM'")); 
		TextEndDate = Format(EndDate, NStr("vi = 'ДФ=дд.ММ';
											|ru = 'ДФ=dd.MM';
											|en = 'DF=MM/dd'; fa = 'DF=MM/dd';
											|it = 'ДФ=дд.ММ';
											|pl = 'DF=dd.MM';
											|tr = 'DF=dd.MM'"));
		Title   = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 - %2';
																				|ru = '%1 - %2';
																				|en = '%1 - %2'; fa = '%1 - %2';
																				|it = '%1 - %2';
																				|pl = '%1 - %2';
																				|tr = '%1 - %2'"), TextStartDate, TextEndDate);
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		If ShowNumberOfPeriod Then
			Title = Format(Month(BegOfDay(StartDate)+1), "NFD=0; NG=0") + " " + NStr("vi = 'tháng';
																					|ru = 'месяц';
																					|en = 'month'; fa = 'ماه';
																					|it = 'mese';
																					|pl = 'miesiąc';
																					|tr = 'ay'");
		Else
			FormatString = "DF='MMMM yyyy'; L =%Language%";
			#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
				DefaultLanguageCode = Common.DefaultLanguageCode();
			#Else
				DefaultLanguageCode = CommonClient.DefaultLanguageCode();
			#EndIf
			FormatString = StrReplace(FormatString,"%Language%", DefaultLanguageCode);
			Title = Format(BegOfDay(StartDate)+1, FormatString);
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		If ShowNumberOfPeriod Then
			Title = Format(StartDate, NStr("vi = 'ДФ=''к''';
											|ru = 'ДФ=''q''';
											|en = 'DF=''q'''; fa = 'DF=''q''';
											|it = 'ДФ=''к''';
											|pl = 'DF=''q''';
											|tr = 'DF=''ç'''")) + " " + NStr("vi = 'quý';
																			|ru = 'квартал';
																			|en = 'quarter'; fa = 'quarter';
																			|it = 'trimestre';
																			|pl = 'kwartał';
																			|tr = 'çeyrek'");
		Else
			TextStartDate = Format(StartDate, NStr("vi = 'ДФ=''к''';
													|ru = 'ДФ=''q''';
													|en = 'DF=''q'''; fa = 'DF=''q''';
													|it = 'ДФ=''к''';
													|pl = 'DF=''q''';
													|tr = 'DF=''ç'''"));
			TextEndDate = Format(StartDate, NStr("vi = 'ДФ=гггг';
												|ru = 'ДФ=yyyy';
												|en = 'DF=yyyy'; fa = 'DF=yyyy';
												|it = 'Formato data=yyyy';
												|pl = 'DF=yyyy';
												|tr = 'DF=yyyy'"));
			Title   = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 kb. %2';
																					|ru = '%1 кв. %2';
																					|en = 'Q%1, %2'; fa = 'Q%1, %2';
																					|it = '%1 trim. %2';
																					|pl = '%1 kw. %2';
																					|tr = '%1 çy. %2'"), TextStartDate, TextEndDate);
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		If ShowNumberOfPeriod Then
			Title = ?(StartDate=BegOfYear(StartDate),"1", "2");
		Else
			TextStartDate = ?(StartDate=BegOfYear(StartDate),"1", "2");
			TextEndDate = Format(StartDate, NStr("vi = 'ДФ=гггг';
												|ru = 'ДФ=yyyy';
												|en = 'DF=yyyy'; fa = 'DF=yyyy';
												|it = 'Formato data=yyyy';
												|pl = 'DF=yyyy';
												|tr = 'DF=yyyy'"));
			Title   = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1 nửa năm %2';
																					|ru = '%1 полугодие %2';
																					|en = '%1 half-year %2'; fa = '%1 half-year %2';
																					|it = '%1 semestre %2';
																					|pl = '%1 półrocze %2';
																					|tr = '%1 yarıyıl %2'"), TextStartDate, TextEndDate);
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		Title = Format(StartDate, NStr("vi = 'ДФ=гггг';
										|ru = 'ДФ=yyyy';
										|en = 'DF=yyyy'; fa = 'DF=yyyy';
										|it = 'Formato data=yyyy';
										|pl = 'DF=yyyy';
										|tr = 'DF=yyyy'")) + NStr("vi = ' năm';
																|ru = ' г.';
																|en = ' year'; fa = ' year';
																|it = ' anno';
																|pl = ' r.';
																|tr = ' y.'");
	Else 
		Title = String(StartDate);
	EndIf;
	
	If Substituted Then
		Title = Title + " " + NStr("vi = '(thay thế)';
									|ru = '(замещен)';
									|en = '(replaced)'; fa = '(replaced)';
									|it = '(sostituito)';
									|pl = '(zastąpiony)';
									|tr = '(ikame edildi)'");
	EndIf;
	
	Return Title;

EndFunction

// Calculates the start date of the period based on the specified date and frequency
//
// Parameters:
//  Date			 - Date							 - the date by which the period start date will be calculated
//  Periodicity	 - EnumRef.Periodicity	 - the value of the "Frequency" enumeration.
// 
// Returns:
//  Date - start date of the period
//
Function CalculateStartDateOfPeriod(Val Date, Val Periodicity) Export
	
	OneDay = 86400;
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		StartDate = BegOfDay(Date);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		
		StartDate = BegOfWeek(Date);
				
	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.TenDays")) Then
		
		MonthDay   = Day(Date);
		BegOfMonth = BegOfMonth(Date);
		
		If MonthDay = 1 Or MonthDay = 11 Or MonthDay = 21 Then
			StartDate = Date;
		ElsIf MonthDay <= 10 Then // The first decade
			StartDate = BegOfMonth
		ElsIf MonthDay <= 20 Then // The second decade
			StartDate = BegOfMonth + OneDay * 10;
		Else // The third decade
			StartDate = BegOfMonth + OneDay * 20;
		EndIf;
		
	ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then
		
		StartDate = BegOfMonth(Date);
		
	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Quarter")) Then
		
		StartDate = BegOfQuarter(Date);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.HalfYear")) Then
		
		BegOfYear      = BegOfYear(Date);
		BeginningOfHalfYear = AddMonth(BegOfYear,6);
		
		If Date >= BeginningOfHalfYear Then
			StartDate = BeginningOfHalfYear;
		Else
			StartDate = BegOfYear;
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Year")) Then
		
		StartDate = BegOfYear(Date);
		
	EndIf;
	
	Return StartDate;
	
EndFunction

// Calculates the end date of the period based on the specified date and frequency
//
// Parameters:
//  Date			 - Date							 - the date by which the period end date will be calculated
//  Periodicity	 - EnumRef.Periodicity	 - the value of the "Frequency" enumeration.
// 
// Returns:
//  Date - end date of the period.
//
Function CalculatePeriodEndDate(Val Date, Val Periodicity) Export
	
	OneDay = 86400;
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		EndDate = EndOfDay(Date);
		
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		
		EndDate = EndOfWeek(Date);
				
	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.TenDays")) Then
		
		MonthDay   = Day(Date);
		EndOfMonth = EndOfMonth(Date);
		BegOfMonth = BegOfMonth(Date);
		
		If MonthDay = 10 Or MonthDay = 20 Or MonthDay = Day(EndOfMonth) Then
			EndDate = EndOfDay(Date);
		ElsIf MonthDay <= 9 Then // The first decade
			EndDate = BegOfMonth - 1 + OneDay * 10
		ElsIf MonthDay <= 19 Then // The second decade
			EndDate = BegOfMonth - 1 + OneDay * 20;
		Else // The third decade
			EndDate = EndOfMonth;
		EndIf;
		
	ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then
		
		EndDate = EndOfMonth(Date);
		
	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Quarter")) Then
		
		EndDate = EndOfQuarter(Date);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.HalfYear")) Then
		
		EndOfYear      = EndOfYear(Date);
		EndOfHalfYear = AddMonth(EndOfYear,-6);
		
		If Date < EndOfHalfYear Then
			EndDate = EndOfHalfYear;
		Else
			EndDate = EndOfYear;
		EndIf;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Year")) Then
		
		EndDate = EndOfYear(Date);
		
	EndIf;
	
	Return EndDate;
	
EndFunction

// Checks the dates of the period in the table part correspond to the boundaries of the planning period.
//
// Parameters:
//  Object    - DocumentRef.PurchasePlan - a plan document that checks the dates of the period
// 	          - DocumentRef.PlanOfGoodsStock -
// 	          - DocumentRef.SalesPlan -
// 	          - DocumentRef.SalesPlanByCategories -
// 	          - DocumentRef.ProductionPlan -
// 	          - DocumentRef.AssemblyDisassemblyPlan - 
// 	          - FormDataStructure - with the property:
// 	             * Ref - DocumentRef
//  Cancel     - Boolean - True is assigned if the operation was not completed successfully
//  Parameters - Structure - Additional options (Datacache, Mitocondria, etc.).
//
Procedure CheckDateOfTSPeriod(Object, Cancel, Parameters) Export 

	If ValueIsFilled(Parameters.Periodicity) And ValueIsFilled(Parameters.StartDate) And ValueIsFilled(Parameters.EndDate) Then
		
		KTCHPathPrefix = "";
		If Parameters.Property("KTCHPathPrefix") Then
			KTCHPathPrefix = Parameters.KTCHPathPrefix;
		EndIf;
		
		If TypeOf(Object) <> Type("FormDataStructure") Then
			DataKey = Object;
		Else
			DataKey = Object.Ref;
		EndIf;
		
		AddressTemplate = " " + NStr("vi = 'trong dòng %LineNumber% danh sách ""%PresentationOfTS%""';
									|ru = 'в строке %LineNumber% списка ""%PresentationOfTS%""';
									|en = 'in line %LineNumber% of the ""%PresentationOfTS%"" list'; fa = 'in line %LineNumber% of the ""%PresentationOfTS%"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""%PresentationOfTS%""';
									|pl = 'w wierszu %LineNumber% listy ""%PresentationOfTS%""';
									|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında'");
		AddressTemplate = StrReplace(AddressTemplate,"%PresentationOfTS%", Parameters.PresentationOfTS);
		
		ErrorText = NStr("vi = '%1 phải phù hợp với giai đoạn kế hoạch ""%2"" - ""%3""';
						|ru = '%1 должна соответствовать периоду плана ""%2"" - ""%3""';
						|en = '%1 must correspond to the period plan ""%2"" - ""%3""'; fa = '%1 must correspond to the period plan ""%2"" - ""%3""';
						|it = '%1 deve corrispondere al periodo del piano ""%2"" - ""%3""';
						|pl = '%1 powinna odpowiadać okresowi planu ""%2"" - ""%3""';
						|tr = '%1 dönem planına uyum sağlamalı ""%2"" - ""%3""'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, Parameters.PresentationOfPeriodDate,
			Format(Parameters.StartDate, "DLF=DD"), Format(Parameters.EndDate, "DLF=DD"));
		
		For Each TSRow In Object[Parameters.TSName] Do
			
			ErrorAddress = StrReplace(AddressTemplate,"%LineNumber%", TSRow.LineNumber);

			PeriodDate_ = TSRow[Parameters.NameOfPeriodDateField];
			
			If ValueIsFilled(PeriodDate_) And (PeriodDate_ < Parameters.StartDate Or PeriodDate_ > Parameters.EndDate) Then
				
				PathToTabularSection = CommonClientServer.PathToTabularSection(KTCHPathPrefix + Parameters.TSName, 
					TSRow.LineNumber, Parameters.NameOfPeriodDateField);
				CommonClientServer.MessageToUser(
					ErrorText + ErrorAddress,
					DataKey,
					PathToTabularSection,
					,
					Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

// Compares the changed details that affect the interface update
//
// Parameters:
//  Object               - DocumentObject - or the details of the "Object" form in which the changed details are checked
//  Form                - ClientApplicationForm - the form of the document
//  NameOfVerificationDetails - String - Name of the item that is created on the form to save the item's details values.
//
// Returns:
//  Boolean - True if the interface needs to be updated.
//
Function YouNeedToUpdateInterface(Object, Form, Val NameOfVerificationDetails) Export 

	CheckedAttributes = New Array();
	CheckedAttributes.Add("Periodicity");
	CheckedAttributes.Add("PlanByAmount");
	CheckedAttributes.Add("BeginOfPeriod");
	CheckedAttributes.Add("PeriodEnding");
	CheckedAttributes.Add("PlanProfile");
	
	VerificationDetails_1 = Form[NameOfVerificationDetails];
	If TypeOf(VerificationDetails_1) = Type("Structure") Then
	
		For Each VerificationAttribute In VerificationDetails_1 Do
		
			If CheckedAttributes.Find(VerificationAttribute.Key) <> Undefined And VerificationAttribute.Value <> Object[VerificationAttribute.Key] Then
			
				Return True;
			
			EndIf; 
		
		EndDo; 
	
	EndIf; 
	
	Return False;
	
EndFunction

// Saves the values of the object's details to the structure on the form for subsequent verification of changes.
//
// Parameters:
// Object               - DocumentObject - or the details of the "Object" form in which the changed details are checked
// Form                - ClientApplicationForm
// NameOfVerificationDetails - String - The name of the props created on the form to save the values of the object's props.
//
Procedure SaveValuesOfVerifiedDetails(Object, Form, Val NameOfVerificationDetails) Export 
	
	VerificationDetails_1 = Form[NameOfVerificationDetails];
	FillPropertyValues(VerificationDetails_1, Object);
	
EndProcedure

// Saves the values of the object's details to the structure on the form for subsequent verification of changes.
//
// Parameters:
// Object                 - DocumentObject - or the details of the "Object" form in which the changed details are checked
// Form                  - ClientApplicationForm
// NameOfVerificationDetails   - String - The name of the props created on the form to save the values of the object's props
// ObjectAttributesNames - String - The names of the object's details to which the values are restored.
//
Procedure RestoreValuesFromVerifiedDetails(Object, Form, Val NameOfVerificationDetails, Val ObjectAttributesNames) Export 
	
	VerificationDetails_1 = Form[NameOfVerificationDetails];
	FillPropertyValues(Object, VerificationDetails_1, ObjectAttributesNames);
	
EndProcedure

// The function returns the value of the document reference plan type
//
// Parameters:
//  Ref  - AnyRef - Link to the plan document that you want to define the type for.
//
// Returns:
//   EnumRef.TypesOfPlans   - Type of plan: sales plan, purchase plan, assembly (disassembly) plan, etc.
//
Function GetPlanTypeFromLink(Val Ref) Export 

	ValueType = TypeOf(Ref);
	
	If ValueType = Type("DocumentRef.PurchasePlan") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan");
	
	ElsIf ValueType = Type("DocumentRef.PlanOfGoodsStock") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.PlanOfGoodsStock");
	
	ElsIf ValueType = Type("DocumentRef.SalesPlan") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan");
	
	ElsIf ValueType = Type("DocumentRef.SalesPlanByCategories") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories");
	
	ElsIf ValueType = Type("DocumentRef.InventoryConsumptionPlan") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan");
	ElsIf ValueType = Type("DocumentRef.ProductionPlan") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan");
	ElsIf ValueType = Type("DocumentRef.AssemblyDisassemblyPlan") Then
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan");
	
	Else
	
		PlanType = PredefinedValue("Enum.TypesOfPlans.EmptyRef");
	
	EndIf; 

	Return PlanType;
	
EndFunction 

// Function-Get the text of the selected layout fields based on user settings.
//
// Parameters:
//  SettingsComposer			 - DataCompositionSettingsComposer 	 - the linker settings by which the field work
//  DeleteUnusedFields	 - Boolean	 - If True, all unused fields are removed from user fields
//  UsedFields			 - Array	 - fields used for selection.
//
// Returns:
//  String - string enumeration of selected fields.
//
Function GetTextOfSelectedLayoutFields(SettingsComposer, DeleteUnusedFields = False, UsedFields = Undefined) Export 
	
	PopulationFields = "";
	
	If UsedFields = Undefined Then
		UsedFields = New Array;
	EndIf; 
	
	GroupFields = GetDimensionFields(SettingsComposer);
	SelectionFields = GetSelectionFields(SettingsComposer);
		
	If ValueIsFilled(SettingsComposer.Settings.Structure.UserSettingID) Then
		UserSetup = SettingsComposer.UserSettings.Items.Find(
			SettingsComposer.Settings.Structure.UserSettingID);
		If UserSetup <> Undefined
			And UserSetup.Structure.Count() > 0
			And UserSetup.Structure[0].Use Then
			
			If DeleteUnusedFields Then
				For Each Field In GroupFields Do
					
					If Not Field.Use Then
						Continue;
					EndIf;
					
					If UsedFields.Find(String(Field.Field)) = Undefined Then
					
						Field.Use = False;
					
					EndIf; 
				EndDo; 
			EndIf;
			
		EndIf;
	EndIf;
	
	If ValueIsFilled(SettingsComposer.Settings.Selection.UserSettingID) Then
		UserSetup = SettingsComposer.UserSettings.Items.Find(
			SettingsComposer.Settings.Selection.UserSettingID);
		If UserSetup <> Undefined Then
			If DeleteUnusedFields Then
				For Each Field In SelectionFields Do
					
					If Not Field.Use Then
						Continue;
					EndIf;
					
					If UsedFields.Find(String(Field.Field)) = Undefined Then
					
						Field.Use = False;
					
					EndIf; 
				EndDo; 
			EndIf;
			
		EndIf;
	EndIf;

	For Each Field In GroupFields Do
		If Not Field.Use Then
			Continue;
		EndIf; 
		
		If Not IsBlankString(PopulationFields) Then
			PopulationFields = PopulationFields + ", ";
		EndIf; 
		PopulationFields = PopulationFields + String(Field.Field);
		
	EndDo; 
	For Each Field In SelectionFields Do
		If Not Field.Use Then
			Continue;
		EndIf; 
		If Not IsBlankString(PopulationFields) Then
			PopulationFields = PopulationFields + ", ";
		EndIf; 
		PopulationFields = PopulationFields + String(Field.Field);
	EndDo;
	
	Return PopulationFields;

EndFunction 

// Returns the grouping fields of the settings linker
//
// Parameters:
//  SettingsComposer  - DataCompositionSettingsComposer - the linker where you need to get the grouping fields.
//
// Returns:
//  DataCompositionGroupFieldCollection - Collection of elements of grouping fields.
//
Function GetDimensionFields(SettingsComposer) Export 
	
	GroupFields = New Array;
	
	If Not ValueIsFilled(SettingsComposer.Settings.Structure.UserSettingID) Then
		If SettingsComposer.Settings.Structure.Count() > 0 
			And SettingsComposer.Settings.Structure[0].Use Then
			GroupFields = SettingsComposer.Settings.Structure[0].GroupFields.Items;
		EndIf;
	Else
		SettingItem = SettingsComposer.UserSettings.Items.Find(
			SettingsComposer.Settings.Structure.UserSettingID);
		If SettingItem <> Undefined
			And SettingItem.Structure.Count() > 0
			And SettingItem.Structure[0].Use Then
			GroupFields = SettingItem.Structure[0].GroupFields.Items;
			
		EndIf;
	EndIf;
	
	Return GroupFields;

EndFunction 

// Returns the selection field of the linker settings
//
// Parameters:
//  SettingsComposer  - DataCompositionSettingsComposer - the linker where you need to get the selection fields.
//
// Returns:
//  DataCompositionSelectedFieldCollection - A collection of elements of the selection fields.
//
Function GetSelectionFields(SettingsComposer) Export 
	
	SelectionFields = New Array;
	
	If Not ValueIsFilled(SettingsComposer.Settings.Selection.UserSettingID) Then
		SelectionFields = SettingsComposer.Settings.Selection.Items;
	Else
		SettingItem = SettingsComposer.UserSettings.Items.Find(
			SettingsComposer.Settings.Selection.UserSettingID);
		If SettingItem <> Undefined Then
			SelectionFields = SettingItem.Items;
		EndIf;
	EndIf;
	
	Return SelectionFields;

EndFunction 

// Calculating the day of the week
//
// Parameters:
//	WeekDay	 - EnumRef.WeekDays - weekday.
// Returns:
//	Number - the number of the day of the week.
Function WeekDayNumber(Val WeekDay) Export 

	If Not ValueIsFilled(WeekDay) Then
		Return 0;
	EndIf;
	
	If WeekDay = PredefinedValue("Enum.WeekDays.Monday") Then
		Return 1;
	ElsIf WeekDay = PredefinedValue("Enum.WeekDays.Tuesday") Then
		Return 2;
	ElsIf WeekDay = PredefinedValue("Enum.WeekDays.Wednesday") Then
		Return 3;
	ElsIf WeekDay = PredefinedValue("Enum.WeekDays.Thursday") Then
		Return 4;
	ElsIf WeekDay = PredefinedValue("Enum.WeekDays.Friday") Then
		Return 5;
	ElsIf WeekDay = PredefinedValue("Enum.WeekDays.Saturday") Then
		Return 6;
	Else
		Return 7
	EndIf;

EndFunction 

// Returns the name of the Planning subsystem in the UT /"Budgeting and planning" in KA and up.
// 
// Returns:
//  String - Name of the planning subsystem
Function NameOfSchedulingSubsystem() Export
	
	Return GeneralPurposeTMServerCall.NameOfSchedulingSubsystem();
	
EndFunction

#EndRegion

#Region SimpleFilling

// Returns a selection for a selection of metrics
//
// Parameters:
//  PlanType			 - EnumRef.TypesOfPlans	 - Value of the plan types enumeration
//  Parameters			 - Structure						 - The value for the selection
//  PlanViewParameters	 - Structure						 - The value of the details of the plan type.
// 
// Returns:
//  Structure - Selection structure
//
Function SelectionToFillInIndicators(PlanType, Parameters, PlanViewParameters) Export
	
	Filter = New Structure();
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.PurchasePlan") Then
		
		If PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse Then
			Filter.Insert("FilterWarehouse", 		Parameters.Warehouse);
		EndIf;
		
		If PlanViewParameters.Property("FillInBusinessUnit") And PlanViewParameters.FillInBusinessUnit Then
			Filter.Insert("FilterPurchaseDepartment",Parameters.Department);
		EndIf;
		
		If PlanViewParameters.Property("FillInPartner") And PlanViewParameters.FillInPartner Then
			If Parameters.Property("Vendor") And Parameters.Vendor Then
				Filter.Insert("FilterVendor", 	Parameters.Partner);
			EndIf;
			If Parameters.Property("Client") And Parameters.Client Then
				Filter.Insert("FilterClient", 	Parameters.Partner);
			EndIf;
			Filter.Insert("FilterPartner", 		Parameters.Partner);
		EndIf;
		
		If PlanViewParameters.Property("FillInTermsOfSales") And PlanViewParameters.FillInTermsOfSales Then
			Filter.Insert("FilterTerms", 	Parameters.Terms);
		EndIf;
		
		If PlanViewParameters.Property("FillInTermsOfSales")
			And PlanViewParameters.FillInTermsOfSales
			And Parameters.Property("VendorPriceKind") Then
			Filter.Insert("FilterVendorPriceKind",	Parameters.VendorPriceKind);
		EndIf;
		
	EndIf;
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.PlanOfGoodsStock") Then
		
		If PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse Then
			Filter.Insert("FilterWarehouse", 		Parameters.Warehouse);
		EndIf;
		
	EndIf;
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlan") Then
		
		If PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse Then
			Filter.Insert("FilterWarehouse", 		Parameters.Warehouse);
		EndIf;
		
		If PlanViewParameters.Property("FillInBusinessUnit") And PlanViewParameters.FillInBusinessUnit Then
			Filter.Insert("FilterSalesDivision",Parameters.Department);
		EndIf;
		
		If PlanViewParameters.Property("FillInPartner") And PlanViewParameters.FillInPartner Then
			If Parameters.Property("Vendor") And Parameters.Vendor Then
				Filter.Insert("FilterVendor", 	Parameters.Partner);
			EndIf;
			If Parameters.Property("Client") And Parameters.Client Then
				Filter.Insert("FilterClient", 	Parameters.Partner);
			EndIf;
			Filter.Insert("FilterPartner", 		Parameters.Partner);
		EndIf;
		
		If PlanViewParameters.Property("FillInTermsOfSales") And PlanViewParameters.FillInTermsOfSales Then
			Filter.Insert("FilterTerms", 	Parameters.Terms);
		EndIf;
		
		If PlanViewParameters.Property("FillInManager") And PlanViewParameters.FillInManager Then
			Filter.Insert("FilterManager", 	Parameters.Manager);
		EndIf;
		
		If PlanViewParameters.Property("FillInStoreFormat") And PlanViewParameters.FillInStoreFormat Then
			Filter.Insert("FilterStoreFormat", 	Parameters.StoreFormat);
		EndIf;
		
	EndIf;
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.SalesPlanByCategories") Then
		
		If PlanViewParameters.Property("FillInBusinessUnit") And PlanViewParameters.FillInBusinessUnit Then
			Filter.Insert("FilterSalesDivision", Parameters.Department);
		EndIf;
		
		If PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse Then
			Filter.Insert("FilterWarehouse", Parameters.Warehouse);
		EndIf;
		
		If PlanViewParameters.Property("FillInStoreFormat") And PlanViewParameters.FillInStoreFormat Then
			Filter.Insert("FilterStoreFormat", Parameters.StoreFormat);
		EndIf;
		
	EndIf;
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.AssemblyDisassemblyPlan") 
					And PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse Then
		Filter.Insert("FilterWarehouse",Parameters.Warehouse);
	EndIf;
	
	If PlanType = PredefinedValue("Enum.TypesOfPlans.InventoryConsumptionPlan") Then
		
		If PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse Then
			Filter.Insert("FilterWarehouse", Parameters.Warehouse);
		EndIf;
		
		If PlanViewParameters.Property("FillInBusinessUnit") And PlanViewParameters.FillInBusinessUnit Then
			Filter.Insert("FilterInternalConsumptionDepartment", Parameters.Department);
		EndIf;
		
	EndIf;
	If PlanType = PredefinedValue("Enum.TypesOfPlans.ProductionPlan") Then 
		
		If PlanViewParameters.Property("FillInBusinessUnit") And PlanViewParameters.FillInBusinessUnit Then
			Filter.Insert("FilterProductionDispatcherBusinessUnit", Parameters.Department);
		EndIf;
		Filter.Insert("FilterProductionProcessType", Parameters.ProductionProcessType);
		
		If Parameters.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
			Filter.Insert("FilterItemsType", PredefinedValue("Enum.ItemsTypes.Work_5"));
		EndIf;
	EndIf;
	If PlanViewParameters.Property("PlanningByAssignments") And PlanViewParameters.PlanningByAssignments
		And PlanViewParameters.Property("FillInAssignmentInTabularForm") And Not PlanViewParameters.FillInAssignmentInTabularForm Then
		Filter.Insert("FilterPurpose", Parameters.Purpose);
	EndIf;
		
	Return Filter;
	
EndFunction

// Returns selection for default selection
//
// Parameters:
//  Parameters			 - Structure						 - The value for the selection
//  PlanViewParameters	 - Structure						 - The value of the details of the plan type.
// 
// Returns:
//  Map - Selection structure
//
Function SelectionForSampling(Parameters, PlanViewParameters) Export
	
	Filter = New Map();
	
	If PlanViewParameters.Property("PlanningByAssignments") And PlanViewParameters.PlanningByAssignments
		And PlanViewParameters.Property("FillInAssignmentInTabularForm") And Not PlanViewParameters.FillInAssignmentInTabularForm Then
		Filter.Insert("Purpose", Parameters.Purpose);
	EndIf;
	
	If PlanViewParameters.Property("FillInPartner") And PlanViewParameters.FillInPartner
		And PlanViewParameters.Property("FillInPartnerInTabularForm") And Not PlanViewParameters.FillInPartnerInTabularForm Then
		Filter.Insert("Partner", Parameters.Partner);
		PartnerParameters = GeneralPurposeTMServerCall.ObjectAttributesValues(Parameters.Partner, "Vendor, Client");
		If PartnerParameters.Property("Vendor") And PartnerParameters.Vendor Then
			Filter.Insert("Vendor", Parameters.Partner);
		EndIf;
		If PartnerParameters.Property("Client") And PartnerParameters.Client Then
			Filter.Insert("Client", Parameters.Partner);
		EndIf;
	EndIf;
	
	If PlanViewParameters.Property("FillInTermsOfSales") And PlanViewParameters.FillInTermsOfSales
		And PlanViewParameters.Property("FillInAgreementInTabularForm") And Not PlanViewParameters.FillInAgreementInTabularForm Then
		Filter.Insert("Terms", Parameters.Terms);
	EndIf;
	
	If PlanViewParameters.Property("FillInWarehouse") And PlanViewParameters.FillInWarehouse
		And PlanViewParameters.Property("FillInWarehouseInTabularForm") And Not PlanViewParameters.FillInWarehouseInTabularForm Then
		Filter.Insert("Warehouse", Parameters.Warehouse);
	EndIf;
	
	If PlanViewParameters.Property("FillInBusinessUnit") And PlanViewParameters.FillInBusinessUnit Then
		Filter.Insert("Department", Parameters.Department);
	EndIf;
	
	Return Filter;
	
EndFunction

// Sets the formula view
//
// Parameters:
// Form             - ClientApplicationForm - the form of the document
// CurrentRow     - FormDataCollectionItem - Current data of the table part.
//
Procedure SetFormulaPresentation(Form, CurrentRow) Export
	
	If Form.Object.CrossTable Then
		
		ActivePeriods = Form.TimeIntervals.FindRows(New Structure("Active_", True));
		
		For Each Period In ActivePeriods Do
			
			If CurrentRow.Property("FormulaCalculation_" + Period.ColumnName) Then
				If CurrentRow.Property("SemiFinishedProduct")
					And CurrentRow.SemiFinishedProduct Then
					CurrentRow["FormulaCalculation_" + Period.ColumnName] = SemiFinishedProductFormulaSettingText();
				Else
					CurrentRow["FormulaCalculation_" + Period.ColumnName] = ?(Not ValueIsFilled(CurrentRow["FormulaCalculation_" + Period.ColumnName]), 
						TextForSettingNewFormula(), CurrentRow["FormulaCalculation_" + Period.ColumnName]);
				EndIf;
			EndIf;
		EndDo;
		
	Else
		
		If CurrentRow.Property("FormulaCalculation") Then
			CurrentRow.FormulaCalculation = ?(Not ValueIsFilled(CurrentRow.FormulaCalculation), 
				TextForSettingNewFormula(), CurrentRow.FormulaCalculation);
		EndIf;
	
	EndIf;
	
EndProcedure

// Clears the value of the "formula Calculation" attribute"
//
// Parameters:
// Form             - ClientApplicationForm - the form of the document.
//
Procedure ClearFormulaValue(Form) Export
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("FormulaCalculation", Undefined);
	
	FillPropertyValues(TheStructureOfTheSearch, Form);
	
	If TheStructureOfTheSearch.FormulaCalculation <> Undefined Then
		Form.FormulaCalculation = Undefined;
	EndIf;
	
EndProcedure

// Fills in the values of additional parameters
//
// Parameters:
// Form           - ClientApplicationForm - the form of the document
// AddAttributes    - Array of See Planning.StructureOfAdditionalField - Array of additional details
// TSName           - String - name of the table part.
//
Procedure DisplayValueOfAdditionalParameters(Form, AddAttributes, TSName) Export
	
	CurrentData = Form.Items[TSName].CurrentData;
	CurElementFormField = Form.Items[TSName].CurrentItem; // FormField - 
	ActivePeriods = Form.TimeIntervals.FindRows(New Structure("Active_", True));
	
	Prefix = TSName + "Count_";
	Prefix2 = TSName + "PictureComment_";
	
	If CurrentData = Undefined Then
		PlanningClientServer.ClearFormulaValue(Form);
		Return;
	EndIf;
	
	PeriodFound = False;
	
	If CurElementFormField <> Undefined Then
		
		For Each Period In ActivePeriods Do
			
			For Each AdditionalAttribute5 In AddAttributes Do
				
				ColumnName = AdditionalAttribute5.Name + "_" + Period.ColumnName;
				
				If CurrentData.Property(ColumnName) Then
					Form[AdditionalAttribute5.Name] = ?(ActivePeriods.Count() = 1, CurrentData[ColumnName], Undefined);
				EndIf;
				
			EndDo;
			
			If CurElementFormField.Name = Prefix + Period.ColumnName
				Or CurElementFormField.Name = Prefix2 + Period.ColumnName Then
				
				PeriodFound = True;
				
				If CurrentData.Property("FormulaCalculation_" + Period.ColumnName) 
					And Not ValueIsFilled(CurrentData["FormulaCalculation_" + Period.ColumnName]) Then
					CurrentData["FormulaCalculation_" + Period.ColumnName] = TextForSettingNewFormula();
				EndIf;
				
				For Each AdditionalAttribute5 In AddAttributes Do
					
					ColumnName = AdditionalAttribute5.Name + "_" + Period.ColumnName;
					
					If CurrentData.Property(ColumnName) Then
						Form[AdditionalAttribute5.Name] = CurrentData[ColumnName];
					EndIf;
					
					If AdditionalAttribute5.Name = "FormulaCalculation" And AdditionalAttribute5.CreateProps 
						And Form[AdditionalAttribute5.DataPath] <> SemiFinishedProductFormulaSettingText() Then
						ExpressionField = Form.Items[AdditionalAttribute5.TagName]; // FormField, FormFieldExtensionForALabelField - 
						ExpressionField.Hyperlink = True;
					EndIf;
					
				EndDo;
				
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Not PeriodFound Then
		
		For Each AdditionalAttribute5 In AddAttributes Do
			If AdditionalAttribute5.Name = "FormulaCalculation" And AdditionalAttribute5.CreateProps Then
				Form[AdditionalAttribute5.Name] = TextSampleQuantityColumn();
				ExpressionField = Form.Items[AdditionalAttribute5.TagName]; // FormField, FormFieldExtensionForALabelField - 
				ExpressionField.Hyperlink = False;
				Break;
			EndIf;
		EndDo;
	
	EndIf; 
	
EndProcedure

// Function-returns the text for setting a new formula
// 
// Returns:
//  String - representation of an empty formula.
//
Function TextForSettingNewFormula() Export 

	Return NStr("vi = 'Đặt công thức';
				|ru = 'Задать формулу';
				|en = 'Set formula'; fa = 'Set formula';
				|it = 'Impostare la formula';
				|pl = 'Wyznacz formułę';
				|tr = 'Formül sor'");

EndFunction 

// The function returns the text of the quantity column
//
// Returns:
//	String - the text of the quantity column.
Function TextSampleQuantityColumn() Export 

	Return NStr("vi = 'Chọn cột số lượng';
				|ru = 'Выберите колонку количества';
				|en = 'Select a quantity column'; fa = 'Select a quantity column';
				|it = 'Selezionare la colonna della quantità';
				|pl = 'Wybierz kolumnę ilości';
				|tr = 'Sayı sütunu seçiniz'");

EndFunction

// The function returns the text for the semi-finished product string
//
// Returns:
//	String - the text of the semi-finished product line.
Function SemiFinishedProductFormulaSettingText() Export 

	Return NStr("vi = 'Chọn dòng sản phẩm';
				|ru = 'Выберите строку с продукцией';
				|en = 'Select a line with products'; fa = 'Select a line with products';
				|it = 'Scegliere la riga con i prodotti';
				|pl = 'Wybierz wiersz z produkcją';
				|tr = 'Ürün satırı seçiniz'");

EndFunction

// Calculating the current column number
//
// Parameters:
//	InternalParameters	 - Structure - Service parameters.
//	CustomSetting - Structure - custom setting.
// Returns:
//	Number - the current column number.
Function CurrentColumnNumber(InternalParameters = Undefined, CustomSetting = Undefined) Export
	
	If TypeOf(InternalParameters) = Type("Structure") And InternalParameters.Property("Period") Then
		
		Return InternalParameters.Period.ColumnNumber;
		
	EndIf;
	
	Return 1;
	
EndFunction

// Calculating the column value
//
// Parameters:
//	InternalParameters	 - Structure - Service parameters.
//	CustomSetting - Structure - custom setting.
// Returns:
//	Number - the value in the column.
Function ColumnValue(InternalParameters = Undefined, CustomSetting = Undefined) Export
	
	If CustomSetting <> Undefined And TypeOf(InternalParameters) = Type("Structure") And InternalParameters.Property("TimeIntervals") Then
		
		FoundRows = InternalParameters.TimeIntervals.FindRows(New Structure("ColumnNumber", CustomSetting));
		
		If FoundRows.Count() > 0 Then
			
			Return InternalParameters.CurrentData["Count_"+FoundRows[0].ColumnName];
		
		EndIf;
		
	EndIf;
	
	Return 0;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function AddParametersToFunctions(Calculation_Formula, Parameters) Export
	
	ArrayOfFunctions = FormulaFunctions_();
	
	For Each CurFunction In ArrayOfFunctions Do
		Calculation_Formula = StrReplace(Calculation_Formula, CurFunction, "PlanningClientServer." + CurFunction + Parameters + ",");
	EndDo;
	
	Return Calculation_Formula;
	
EndFunction

Function RemoveParametersInFunctions(Calculation_Formula, Parameters) Export

	ArrayOfFunctions = FormulaFunctions_();
	
	For Each CurFunction In ArrayOfFunctions Do
		Calculation_Formula = StrReplace(Calculation_Formula, CurFunction + Parameters + ",", CurFunction);
	EndDo;
	
	Return Calculation_Formula;

EndFunction

Function FormulaFunctions_()
	
	ArrayOfFunctions = New Array();
	ArrayOfFunctions.Add("ColumnValue(");
	ArrayOfFunctions.Add("CurrentColumnNumber(");
	
	Return ArrayOfFunctions
	
EndFunction

#EndRegion