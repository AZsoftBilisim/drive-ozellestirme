

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	BudgetFrequency = Undefined;
	If Not Parameters.Property("Periodicity",            BudgetFrequency)
	 Or Not Parameters.Property("AdditionalInformation", PeriodFrequency)
	 Or Not Parameters.Property("PlanningMethod") Then
		MessageText = NStr("vi = 'Không xem xét mở trực tiếp biểu mẫu này. Một biểu mẫu được mở khi một khoảng thời gian được thêm vào chế độ xem ngân sách.';
							|ru = 'Непосредственное открытие этой формы не предусмотрено. Открытие формы выполняется при добавлении периода в вид бюджета.';
							|en = 'Application cannot open this form explicitly. It opens implicitly when you add a period to a budget profile.'; fa = 'Application cannot open this form explicitly. It opens implicitly when you add a period to a budget profile.';
							|it = 'L''apertura diretta di questo modulo non è prevista. L''apertura del modulo viene eseguita quando si aggiunge il periodo nel tipo di budget.';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane. Otwarcie formularza jest wykonywane przy dodaniu okresu do rodzaju budżetu.';
							|tr = 'Bu formların direkt açılmaları öngörülmedi. Formların açılmaları bütçe profiline dönem eklendiğinde gerçekleştirilir.'");
		Raise MessageText;
	EndIf;
	
	If Parameters.PlanningMethod = Enums.BudgetPreparationMethods.ForAFixedPeriod Then
		NumberOfPeriods = 1;
	Else
		NumberOfPeriods = Parameters.NumberOfPeriodsOfRollingBudget;
	EndIf;
	
	Cache = New Map;
	PeriodNumber = 0;
	
	For Cnt = 1 To NumberOfPeriods Do
	
		CurrentDate = Date(1985, 1, 1);
		EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(CurrentDate, BudgetFrequency);
		
		LocalPeriodNumber = 0;
		
		While CurrentDate < EndOfPeriod Do
			
			Presentation = "";
			LocalPeriodNumber = LocalPeriodNumber + 1;
			If PeriodFrequency = Enums.Periodicity.Month
				And BudgetFrequency = Enums.Periodicity.Year Then
				
				FormatString = NStr("vi = 'DF=MMMM';
									|ru = 'ДФ=MMMM';
									|en = 'DF=MMMM'; fa = 'DF=MMMM';
									|it = 'FD=MMMM';
									|pl = 'DF=MMMM';
									|tr = 'DF=MMMM'");
				Presentation = Format(Date(1985, LocalPeriodNumber, 1), FormatString);
				
			ElsIf PeriodFrequency = Enums.Periodicity.Day
				And BudgetFrequency = Enums.Periodicity.Week Then
				
				FormatString = NStr("vi = 'DF=dddd';
									|ru = 'ДФ=dddd';
									|en = 'DF=dddd'; fa = 'DF=dddd';
									|it = 'DF=dddd';
									|pl = 'DF=dddd';
									|tr = 'DF=gggg'");
				Presentation = Format(Date(1985, 1, LocalPeriodNumber), FormatString);
				
			ElsIf PeriodFrequency <> BudgetFrequency Or NumberOfPeriods = 1 Then
				
				Presentation = PeriodName(PeriodNumber + 1, PeriodFrequency);
				
			EndIf;
			
			CurrentDate = WorkingWithClientServerPeriods.AddInterval(CurrentDate, PeriodFrequency, 1, Cache);
			
			If NumberOfPeriods > 1 Then
				If IsBlankString(Presentation) Then
					Presentation = PeriodName(Cnt, BudgetFrequency);
				Else
					Presentation = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1, %3';
							|ru = '%1, %3';
							|en = '%1, %3'; fa = '%1, %3';
							|it = '%1, %3';
							|pl = '%1, %3';
							|tr = '%1, %3'"),
						PeriodName(Cnt, BudgetFrequency),
						Presentation);
				EndIf;
			EndIf;
			
			If IsBlankString(Presentation) Then
				Presentation = String(PeriodFrequency);
			EndIf;
			
			PeriodsList.Add(PeriodNumber, Presentation, True);
			PeriodNumber = PeriodNumber + 1;
			
		EndDo;
	EndDo;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Kỳ %1';
			|ru = 'Период %1';
			|en = '%1'; fa = '%1';
			|it = 'Periodo %1';
			|pl = 'Okres %1';
			|tr = 'Dönem %1'"),
		Lower(String(PeriodFrequency)));
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AllPeriodsOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure SelectedPeriodsOnChange(Item)
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(GetChoiceResult());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FormControl()
	
	Items.PeriodsList.Enabled = SelectedPeriods;
	
EndProcedure

&AtServer
Function PeriodName(PeriodNumber, Periodicity)
	
	If Periodicity = Enums.Periodicity.Day Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-ngày thứ nhất';
																							|ru = '%1-й день';
																							|en = 'day %1'; fa = 'day %1';
																							|it = '%1-й день';
																							|pl = 'day %1';
																							|tr = '%1. gün'"),
			PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.Week Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-tuần thứ nhất';
																							|ru = '%1-я неделя';
																							|en = 'week %1'; fa = 'week %1';
																							|it = '%1-я неделя';
																							|pl = 'week %1';
																							|tr = '%1. hafta'"),
			PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-mười ngày thứ nhất';
																							|ru = '%1-я декада';
																							|en = 'ten-day period %1'; fa = 'ten-day period %1';
																							|it = '%1-я декада';
																							|pl = 'ten-day period %1';
																							|tr = '%1. on günlük süre'"),
			PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.Month Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-tháng thứ nhất';
																							|ru = '%1-й месяц';
																							|en = 'month %1'; fa = 'month %1';
																							|it = '%1-й месяц';
																							|pl = 'month %1';
																							|tr = '%1. ay'"),
			PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-quý thứ nhất';
																							|ru = '%1-й квартал';
																							|en = 'quarter %1'; fa = 'quarter %1';
																							|it = '%1-й квартал';
																							|pl = 'quarter %1';
																							|tr = '%1. çeyrek'"),
			PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-nửa năm thứ nhất';
																							|ru = '%1-е полугодие';
																							|en = 'half-year %1'; fa = 'half-year %1';
																							|it = '%1-е полугодие';
																							|pl = 'half-year %1';
																							|tr = '%1. yarıyıl'"),
			PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		DurationDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '%1-năm thứ nhất';
																							|ru = '%1-й год';
																							|en = 'year %1'; fa = 'year %1';
																							|it = '%1-й год';
																							|pl = 'year %1';
																							|tr = '%1. yıl'"),
			PeriodNumber);
	EndIf;
	
	Return DurationDescription;
	
EndFunction

&AtServer
Procedure AddResultLine(Result, Description, SelectedPeriod = Undefined)
	
	NewRow = New Structure("NameForPrinting, ItemIndicatorDimensionType, DimensionValue, ThisIsDimensionOther");
	NewRow.NameForPrinting 			= Description;
	NewRow.ItemIndicatorDimensionType 	= PeriodFrequency;
	NewRow.DimensionValue 				= SelectedPeriod;
	NewRow.ThisIsDimensionOther 				= False;
	
	Result.Add(NewRow);
	
EndProcedure

&AtServer
Function GetChoiceResult()
	
	Result = New Array;
	
	If Not SelectedPeriods Then
		AddResultLine(Result, String(PeriodFrequency));
	Else
		For Each Item In PeriodsList Do
			If Item.Check Then
				AddResultLine(Result, Item.Presentation, Item.Value);
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
