
#Region Public

// Returns the payment date according to the calendar, taking into account the shift.
// 
// Parameters:
//  Parameters - See PaymentStepsClientServer.PaymentDateCalculationParameters
// 
// Returns:
//  Date - Payment date by calendar
Function PaymentDateByCalendar(Parameters) Export
	
	TopUpDatesIfNotFilledIn(Parameters);
	
	If Not ValueIsFilled(Parameters.CalculateFrom) Then
		PaymentDate = Date(1,1,1);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.FixedDate Then
		PaymentDate = Parameters.PaymentDate;
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate And ValueIsFilled(Parameters.OrderDate) Then
		PaymentDate = DateByCalendar(Parameters.Calendar, Parameters.OrderDate, Parameters.Move);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.FromApprovalDate And ValueIsFilled(Parameters.ApprovalDate) Then
		PaymentDate = DateByCalendar(Parameters.Calendar, Parameters.ApprovalDate, Parameters.Move);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.BeforeShipmentDate And ValueIsFilled(Parameters.DateOfShipment) Then
		PaymentDate = DateByCalendar(Parameters.Calendar, Parameters.DateOfShipment, -Parameters.Move);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate And ValueIsFilled(Parameters.DateOfShipment) Then
		PaymentDate = DateByCalendar(Parameters.Calendar, Parameters.DateOfShipment, Parameters.Move);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfReceipt And ValueIsFilled(Parameters.DateOfReceipt) Then
		PaymentDate = DateByCalendar(Parameters.Calendar, Parameters.DateOfReceipt, Parameters.Move);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods And ValueIsFilled(Parameters.DateOfTransferOfTitleToGoods) Then
		PaymentDate = DateByCalendar(Parameters.Calendar, Parameters.DateOfTransferOfTitleToGoods, Parameters.Move);
	ElsIf Parameters.CalculateFrom = Enums.PaymentDateCalculationOptions.Formula And ValueIsFilled(Parameters.Formula) Then
		PaymentDate = DateOfPaymentByFormula(Parameters);
	Else
		PaymentDate = Date(1,1,1);
	EndIf;
	
	Return PaymentDate
	
EndFunction

// Returns the estimated payment date without taking into account the production calendar.
// 
// Parameters:
//  Parameters - See PaymentStepsClientServer.PaymentDateCalculationParameters
// 
// Returns:
//  Date - Payment date (excluding calendar)
//
Function PaymentDateWithoutCalendar(Parameters) Export
	
	TopUpDatesIfNotFilledIn(Parameters);
	
	If Not ValueIsFilled(Parameters.CalculateFrom) Then
		PaymentDate = Date(1,1,1);
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		PaymentDate = Parameters.PaymentDate;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromOrderDate") And ValueIsFilled(Parameters.OrderDate) Then
		PaymentDate = Parameters.OrderDate + 86400 * Parameters.Move;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromApprovalDate") And ValueIsFilled(Parameters.ApprovalDate) Then
		PaymentDate = Parameters.ApprovalDate + 86400 * Parameters.Move;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") And ValueIsFilled(Parameters.DateOfShipment) Then
		PaymentDate = Parameters.DateOfShipment - 86400 * Parameters.Move;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate") And ValueIsFilled(Parameters.DateOfShipment) Then
		PaymentDate = Parameters.DateOfShipment + 86400 * Parameters.Move;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt") And ValueIsFilled(Parameters.DateOfReceipt) Then
		PaymentDate = Parameters.DateOfReceipt + 86400 * Parameters.Move;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods") And ValueIsFilled(Parameters.DateOfTransferOfTitleToGoods) Then
		PaymentDate = Parameters.DateOfTransferOfTitleToGoods + 86400 * Parameters.Move;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") And ValueIsFilled(Parameters.Formula) Then
		PaymentDate = DateOfPaymentByFormula(Parameters);
	Else
		PaymentDate = Date(1,1,1);
	EndIf;
	
	Return PaymentDate;
	
EndFunction

// Returns the calendar offset from the payment date.
// 
// Parameters:
//  Parameters - See PaymentStepsClientServer.PaymentDateCalculationParameters
// 
// Returns:
//  Number - Calendar Shift
Function CalendarShift(Parameters) Export
	
	TopUpDatesIfNotFilledIn(Parameters);
	
	If Parameters.PaymentDate = Date(1,1,1) Or Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		Move = 0;
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromOrderDate") 
		And ValueIsFilled(Parameters.OrderDate) Then
		Move = ShiftBetweenDatesOnCalendar(Parameters.Calendar, Parameters.OrderDate, Parameters.PaymentDate);
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromApprovalDate") 
		And ValueIsFilled(Parameters.ApprovalDate) Then
		Move = ShiftBetweenDatesOnCalendar(Parameters.Calendar, Parameters.ApprovalDate, Parameters.PaymentDate);
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
		And ValueIsFilled(Parameters.DateOfShipment) Then
		Move = ShiftBetweenDatesOnCalendar(Parameters.Calendar, Parameters.PaymentDate, Parameters.DateOfShipment);
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
		And ValueIsFilled(Parameters.DateOfShipment) Then
		Move = ShiftBetweenDatesOnCalendar(Parameters.Calendar, Parameters.DateOfShipment, Parameters.PaymentDate);
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt")
		And ValueIsFilled(Parameters.DateOfReceipt) Then
		Move = ShiftBetweenDatesOnCalendar(Parameters.Calendar, Parameters.DateOfReceipt, Parameters.PaymentDate);
	ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")
		And ValueIsFilled(Parameters.DateOfTransferOfTitleToGoods) Then
		Move = ShiftBetweenDatesOnCalendar(Parameters.Calendar, Parameters.DateOfTransferOfTitleToGoods, Parameters.PaymentDate);
	Else
		Move = 0;
	EndIf;
	
	Return Move;
	
EndFunction

// Returns the estimated number of days from the event date to the payment date, excluding the production calendar.
// 
// Parameters:
//  Parameters - See PaymentStepsClientServer.PaymentDateCalculationParameters
// 
// Returns:
//  Number - Shift, days (excluding calendar)
//
Function ShiftWithoutCalendar(Parameters) Export
	
	TopUpDatesIfNotFilledIn(Parameters);
	
	If Not ValueIsFilled(Parameters.CalculateFrom)
		Or Not ValueIsFilled(Parameters.PaymentDate) 
		Or Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate") Then
		Move = 0;
	Else
		If Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromOrderDate") 
			And ValueIsFilled(Parameters.OrderDate) Then
			Move = (Parameters.PaymentDate - BegOfDay(Parameters.OrderDate)) / 86400 ;
		ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromApprovalDate") 
			And ValueIsFilled(Parameters.ApprovalDate) Then
			Move = (Parameters.PaymentDate - Parameters.ApprovalDate) / 86400 ;
		ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate") 
			And ValueIsFilled(Parameters.DateOfShipment) Then
			Move = (Parameters.DateOfShipment - Parameters.PaymentDate) / 86400 ;
		ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate")
			And ValueIsFilled(Parameters.DateOfShipment) Then
			Move = (Parameters.PaymentDate - Parameters.DateOfShipment) / 86400 ;
		ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt")
			And ValueIsFilled(Parameters.DateOfReceipt) Then
			Move = (Parameters.PaymentDate - Parameters.DateOfReceipt) / 86400;
		ElsIf Parameters.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods")
			And ValueIsFilled(Parameters.DateOfTransferOfTitleToGoods) Then
			Move = (Parameters.PaymentDate - Parameters.DateOfTransferOfTitleToGoods) / 86400 ;
		Else
			Move = 0;
		EndIf;
	EndIf;
	
	Return Move;
	
EndFunction

// Function for checking whether the payment schedule is included in the agreement
//
// Parameters:
// 		Terms - CatalogRef.TermsOfPurchaseFromVendors, CatalogRef.TermsOfSale - 
//
// Returns:
// 		Boolean - "True" if there is at least one stage in the schedule and agreements are used
//
Function AgreementScheduleIsFilledIn(Terms) Export
	
	If Not ValueIsFilled(Terms) Then
		Return False;
	EndIf;
	
	If TypeOf(Terms) = Type("CatalogRef.TermsOfSale")
		And Not GetFunctionalOption("ToUseTermsOfSales")
		Or TypeOf(Terms) = Type("CatalogRef.TermsOfPurchaseFromVendors")
		And Not GetFunctionalOption("UseTermsOfPurchases") Then
		Return False;
	EndIf;
	
	If TypeOf(Terms) = Type("CatalogRef.TermsOfSale") Then
		Query = New Query(
			"SELECT TOP 1
			|	TermsOfSalePaymentScheduleSteps.Ref
			|FROM
			|	Catalog.TermsOfSale.PaymentScheduleSteps AS TermsOfSalePaymentScheduleSteps
			|WHERE
			|	TermsOfSalePaymentScheduleSteps.Ref = &Terms");
	Else
		Query = New Query(
			"SELECT TOP 1
			|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Ref
			|FROM
			|	Catalog.TermsOfPurchaseFromVendors.PaymentScheduleSteps AS TermsOfPurchaseFromVendorsPaymentScheduleSteps
			|WHERE
			|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Ref = &Terms");
	EndIf;
	Query.SetParameter("Terms", Terms);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// In the stage table there are stages from the date of shipment.
// 
// Parameters:
//  PaymentScheduleSteps - ValueTable - The stages of payment schedule
// 
// Returns:
//  Boolean - In The Stage Table There Are Stages From The Date Of Shipment
Function InStageTableThereAreStagesFromDateOfShipment(Val PaymentScheduleSteps) Export
	
	For Each StageString_ In PaymentScheduleSteps Do
		If PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(StageString_.CalculateFrom, StageString_.Formula) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Returns a date that differs from the specified datestate By the number of days
// included in the specified schedule or work Schedule production calendar.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars - the schedule or 
//                    production calendar that you need to use to calculate the date.
//   DateFrom			- Date - the date from which to calculate the number of days.
//   DaysCount	- Number - the number of days to increase the start date by.
//   RaiseException1 - Boolean - if True, throw an exception if the graph is empty.
//
// Returns:
//   Date, Undefined - the date increased by the number of days included in the schedule.
//	                      If the selected schedule is not filled, and call an exception = False, returns Indefinite.
//
Function DateByCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DaysCount, RaiseException1 = False) Export
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch làm việc hoặc lịch sản xuất.';
						|ru = 'Не указан график работы или производственный календарь.';
						|en = 'Work schedule or business calendar is not specified.'; fa = 'Work schedule or business calendar is not specified.';
						|it = 'Non è specificato un programma di lavoro o un calendario di produzione.';
						|pl = 'Nie jest wskazany harmonogram pracy lub kalendarz biznesowy.';
						|tr = 'Çalışma takvimi veya iş takvimi belirtilmedi.'");
		EndIf;
		Return Undefined;
	EndIf;
	
	DateFrom = BegOfDay(DateFrom);
	
	If DaysCount = 0 Then
		Return DateFrom;
	EndIf;
	
	DaysArray = New Array;
	DaysArray.Add(DaysCount);
	
	DatesArray = DatesByCalendar(WorkScheduleCalendar, DateFrom, DaysArray, RaiseException1);
	
	Return ?(DatesArray <> Undefined And DatesArray.Count() > 0, DatesArray[0], Date(1,1,1));
	
EndFunction

#EndRegion

#Region Private

// Returns the dates that are different from the specified date Datat on the number of days
// included in the specified schedule Graficart.
//
// Parameters:
//   WorkScheduleCalendar	- CatalogRef.Calendars
//	             	- CatalogRef.BusinessCalendars - a schedule or 
//                    production calendar to be used to calculate dates.
//   DateFrom			- Date - the date from which to calculate the number of days.
//   DaysArray		- Array of Number - the number of days (Number) to increase the start date by.
//   RaiseException1 - Boolean - if True, throw an exception if the graph is empty.
//
// Returns:
//   Undefined, Array of Date - array of dates increased by the number of days included in the schedule,
//	                        If the schedule is not filled, and cause an exception = False, returns Indefinite.
//
Function DatesByCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DaysArray, RaiseException1 = True) 
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch biểu làm việc hoặc lịch sản xuất.';
						|ru = 'Не указан график работы или производственный календарь.';
						|en = 'Work schedule or business calendar is not specified.'; fa = 'Work schedule or business calendar is not specified.';
						|it = 'Non è specificato un programma di lavoro o un calendario di produzione.';
						|pl = 'Nie jest wskazany harmonogram pracy lub kalendarz biznesowy.';
						|tr = 'Çalışma takvimi veya iş takvimi belirtilmedi.'");
		EndIf;
		Return Undefined;
	EndIf;
	
	Query = New Query;
	
	// According to the production calendar.
	Query.Text =
	"SELECT
	|	CalendarSchedules.Date AS ScheduleDate
	|FROM
	|	InformationRegister.BusinessCalendarData AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.BusinessCalendar = &WorkScheduleCalendar
	|	AND CalendarSchedules.DayKind IN (VALUE(Enum.BusinessCalendarDaysKinds.Work), VALUE(Enum.BusinessCalendarDaysKinds.Preholiday))
	|ORDER BY
	|	CalendarSchedules.Date DESC";
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	
	DatesArray = Query.Execute().Unload().UnloadColumn("ScheduleDate");
	
	For Cnt = 0 To DatesArray.UBound() Do
		If DatesArray[Cnt] >= DateFrom Then
			IndexFrom = Cnt;
		Else
			Break;
		EndIf;
	EndDo;
	
	If IndexFrom = Undefined Then
		ErrorMessage = NStr("vi = 'Chưa điền lịch sản xuất «%1» từ ngày %2 đối với số lượng ngày làm việc đã chỉ ra.';
							|ru = 'Производственный календарь «%1» не заполнен с даты %2 на указанное количество рабочих дней.';
							|en = 'Cannot determine the date because business calendar ""%1"" is not filled for the specified number of workdays after %2.'; fa = 'Cannot determine the date because business calendar ""%1"" is not filled for the specified number of workdays after %2.';
							|it = 'Calendario di produzione ""%1"" non compilato con la data %2 nel numero indicato di giorni lavorativi.';
							|pl = 'Kalendarz biznesowy «%1» nie jest wypełniony od daty %2 nie jest wskazana ilość dni roboczych.';
							|tr = 'Üretim takvimi ""%1"", belirtilen iş günü sayısı için %2 tarihinden itibaren doldurulmadı.'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, WorkScheduleCalendar, Format(DateFrom, "DLF=D"));
		If RaiseException1 Then
			Raise ErrorMessage
		Else
			Common.MessageToUser(ErrorMessage);
			Return Undefined
		EndIf;
	Else
		If DateFrom <> DatesArray[IndexFrom] Then
			Move = 1;
		Else
			Move = 0;
		EndIf;
		
		MatchingDates = New Map;
		For Cnt = 0 To DatesArray.Count()-1 Do
			MatchingDates.Insert(IndexFrom - Cnt + Move, DatesArray[Cnt]);
		EndDo;
	EndIf;
	
	ArrayOfDatesResult = New Array;
	
	For Each DaysRow In DaysArray Do
		Date = MatchingDates.Get(DaysRow);
		If Date = Undefined Then
			ErrorMessage = NStr("vi = 'Chưa điền lịch sản xuất «%1» từ ngày %2 đối với số lượng ngày làm việc đã chỉ ra.';
								|ru = 'Производственный календарь «%1» не заполнен с даты %2 на указанное количество рабочих дней.';
								|en = 'Cannot determine the date because business calendar ""%1"" is not filled for the specified number of workdays after %2.'; fa = 'Cannot determine the date because business calendar ""%1"" is not filled for the specified number of workdays after %2.';
								|it = 'Calendario di produzione ""%1"" non compilato con la data %2 nel numero indicato di giorni lavorativi.';
								|pl = 'Kalendarz biznesowy «%1» nie jest wypełniony od daty %2 nie jest wskazana ilość dni roboczych.';
								|tr = 'Üretim takvimi ""%1"", belirtilen iş günü sayısı için %2 tarihinden itibaren doldurulmadı.'");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, WorkScheduleCalendar, Format(Date, "DLF=D"));
			If RaiseException1 Then
				Raise ErrorMessage
			Else
				Common.MessageToUser(ErrorMessage);
			EndIf;
		Else
			ArrayOfDatesResult.Add(Date);
		EndIf;
	EndDo;
	
	Return ArrayOfDatesResult;
	
EndFunction

Function ShiftBetweenDatesOnCalendar(Val WorkScheduleCalendar, Val DateFrom, Val DateBefore, RaiseException1 = False) 
	
	If Not ValueIsFilled(WorkScheduleCalendar) Then
		If RaiseException1 Then
			Raise NStr("vi = 'Chưa chỉ ra lịch làm việc hoặc lịch sản xuất.';
						|ru = 'Не указан график работы или производственный календарь.';
						|en = 'Work schedule or business calendar is not specified.'; fa = 'Work schedule or business calendar is not specified.';
						|it = 'Non è specificato un programma di lavoro o un calendario di produzione.';
						|pl = 'Nie jest wskazany harmonogram pracy lub kalendarz biznesowy.';
						|tr = 'Çalışma takvimi veya iş takvimi belirtilmedi.'");
		EndIf;
		Return 0;
	EndIf;
	
	Query = New Query;
	
	// According to the production calendar.
	Query.Text =
	"SELECT
	|	CalendarSchedules.Date AS ScheduleDate
	|FROM
	|	InformationRegister.BusinessCalendarData AS CalendarSchedules
	|WHERE
	|	CalendarSchedules.BusinessCalendar = &WorkScheduleCalendar
	|	AND CalendarSchedules.DayKind IN (VALUE(Enum.BusinessCalendarDaysKinds.Work), VALUE(Enum.BusinessCalendarDaysKinds.Preholiday))
	|ORDER BY
	|	CalendarSchedules.Date DESC";
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	DatesArray = Query.Execute().Unload().UnloadColumn("ScheduleDate");
	
	If DatesArray.Count() = 0 Or DateFrom > DatesArray[0] Then
		ErrorMessage = NStr("vi = 'Chưa điền lịch sản xuất ""%1"" vào ngày %2.';
							|ru = 'Производственный календарь «%1» не заполнен на дату %2.';
							|en = 'Business calendar ""%1"" is not filled in on date %2.'; fa = 'Business calendar ""%1"" is not filled in on date %2.';
							|it = 'Calendario produttivo «%1» non compilato in data %2.';
							|pl = 'Kalendarz biznesowy «%1» nie jest wypełniony na datę %2.';
							|tr = 'Üretim takvimi ""%1"" %2 tarihinde doldurulmadı.'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, WorkScheduleCalendar, Format(DateFrom, "DLF=D"));
		If RaiseException1 Then
			Raise ErrorMessage;
		Else
			Common.MessageToUser(ErrorMessage);
			Return 0;
		EndIf;
	ElsIf DatesArray.Count() = 0 Or DateBefore > DatesArray[0] Then
		ErrorMessage = NStr("vi = 'Chưa điền lịch sản xuất ""%1"" vào ngày %2.';
							|ru = 'Производственный календарь «%1» не заполнен на дату %2.';
							|en = 'Business calendar ""%1"" is not filled in on date %2.'; fa = 'Business calendar ""%1"" is not filled in on date %2.';
							|it = 'Calendario produttivo «%1» non compilato in data %2.';
							|pl = 'Kalendarz biznesowy «%1» nie jest wypełniony na datę %2.';
							|tr = 'Üretim takvimi ""%1"" %2 tarihinde doldurulmadı.'");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, WorkScheduleCalendar, Format(DateBefore, "DLF=D"));
		If RaiseException1 Then
			Raise ErrorMessage;
		Else
			Common.MessageToUser(ErrorMessage);
			Return 0;
		EndIf;
	EndIf;
	
	IndexOf = 0;
	DaysFrom = Undefined;
	DaysBefore = Undefined;
	For Each Day In DatesArray Do
		If DaysFrom <> Undefined And DaysBefore <> Undefined Then
			Break;
		EndIf;
		If DateFrom >= Day And DaysFrom = Undefined Then
			DaysFrom = IndexOf;
		EndIf;
		If DateBefore >= Day And DaysBefore = Undefined  Then
			DaysBefore = IndexOf;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	Return DaysFrom - DaysBefore;
	
EndFunction

Function DateOfPaymentByFormula(Parameters)
	
	FormulaTemplate = Common.ObjectAttributeValue(Parameters.Formula, Metadata.Catalogs.FormulasForCalculatingPaymentDate.Attributes.Formula.Name);
	
	Formula = FormulaTemplate;
	ArrayOfParameterValues = New Array;
	OperandsTree = PaymentStepsServer.OperandTreeForFormula();
	For Each OperandString_ In OperandsTree.Rows Do
		If OperandString_.Id = "Move" Or OperandString_.Id = "DeadlineOfTransferOfTitleToGoods" Then
			ArrayOfParameterValues.Add(Parameters[OperandString_.Id]*86400);
		Else
			ArrayOfParameterValues.Add(Parameters[OperandString_.Id]);
		EndIf;
		OperandWithBrackets = ProcessingOfFormulasClientServer.GetOperandTextToInsert(OperandString_.Id);
		ReplacementStringInTemplate = "Parameters[" + String(ArrayOfParameterValues.Count()-1) + "]";
		Formula = StrReplace(Formula, OperandWithBrackets, ReplacementStringInTemplate);
	EndDo;
	
	Try
		PaymentDate = Common.CalculateInSafeMode(Formula,ArrayOfParameterValues);
	Except
		
		ErrorMessage = StrTemplate(NStr("ru = 'Невозможно рассчитать дату платежа по формуле %1 по причине: %2';
										|vi = 'Cannot calculate the payment date using the %1 formula. Reason: %2';
										|en = 'Cannot calculate the payment date using the %1 formula. Reason: %2'; fa = 'Cannot calculate the payment date using the %1 formula. Reason: %2';
										|it = 'Cannot calculate the payment date using the %1 formula. Reason: %2';
										|pl = 'Cannot calculate the payment date using the %1 formula. Reason: %2';
										|tr = '%1 formülüne göre ödeme tarihi hesaplanamıyor. Sebep: %2'"),FormulaTemplate,ErrorDescription());
		Raise ErrorMessage;
		
	EndTry;
	
	Return PaymentDate;
	
EndFunction

// Refills the dates in the parameters for calculating the shift/payment date if they are not filled in.
Procedure TopUpDatesIfNotFilledIn(Parameters)
	
	If Not ValueIsFilled(Parameters.ApprovalDate)  And ValueIsFilled(Parameters.OrderDate) Then
		Parameters.ApprovalDate = Parameters.OrderDate;
	EndIf;
	
	If Not ValueIsFilled(Parameters.DateOfShipment) And ValueIsFilled(Parameters.OrderDate) Then
		Parameters.DateOfShipment = Parameters.OrderDate;
	EndIf;
	
	If Not ValueIsFilled(Parameters.DateOfTransferOfTitleToGoods) And ValueIsFilled(Parameters.DateOfShipment) Then
		Parameters.DateOfTransferOfTitleToGoods = Parameters.DateOfShipment + Parameters.DeadlineOfTransferOfTitleToGoods*86400;
	EndIf;
	
	If Not ValueIsFilled(Parameters.OrderDate) And ValueIsFilled(Parameters.DateOfShipment) Then
		Parameters.OrderDate = Parameters.DateOfShipment;
	EndIf;
	
	If Not ValueIsFilled(Parameters.DateOfReceipt) And ValueIsFilled(Parameters.DateOfShipment) Then
		Parameters.DateOfReceipt = Parameters.DateOfShipment;
	EndIf;
	
EndProcedure

#EndRegion
