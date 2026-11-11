
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FillPropertyValues(Object, Parameters.Object, AttributesToChange());
	
	RentalAvailable = False;
	RentalAvailable = NonCurrentAssets.VNAManagementIsUsed();
	Items.Lease.Visible = RentalAvailable;
	
	PresentationReportDimensions = PresentationReportDimensions(Object.ReportDimensions);
	
	If Not GetFunctionalOption("UsePaymentRequests") Then
		
		Items.RequestsPendingApproval.Visible = False;
		Items.PlannedCashReceipts.Visible = False;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	CheckedAttributes.Clear();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StringOfPlanningDays = StringOfPlanningDays();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PlanFromDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	FillInEndDates();
	
EndProcedure

&AtClient
Procedure PlanningDaysOnChange(Item)
	
	FillInEndDates();
	StringOfPlanningDays = StringOfPlanningDays();

EndProcedure

&AtClient
Procedure LongTermPlanningPeriodsOnChange(Item)
	
	FillInEndDates();

EndProcedure

&AtClient
Procedure PlanningPeriodicityOnChange(Item)
	
	If Not ValueIsFilled(Object.LongTermPlanningTimeFence) Then
		Object.LongTermPlanningPeriods = 0;
	EndIf;
	
	FillInEndDates();
	
EndProcedure

&AtClient
Procedure EndDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If Object.EndDate < Object.PlanFromDate Then
		Object.EndDate = Object.PlanFromDate;
	EndIf;
	
	If Object.LongTermPlanningPeriods = 0 Then
		Object.PlanningDays = (Object.EndDate - Object.PlanFromDate) / 86400 + 1;
	ElsIf ValueIsFilled(Object.LongTermPlanningTimeFence) Then
		Object.EndDateOfPlanningByDay = WorkingWithClientServerPeriods.AddInterval(Object.EndDate,
			Object.LongTermPlanningTimeFence, -Object.LongTermPlanningPeriods);
		Object.PlanningDays = (Object.EndDateOfPlanningByDay - Object.PlanFromDate) / 86400 + 1;
	EndIf;
	
	If Object.PlanningDays <= 0 Then
		Object.PlanningDays = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationReportDimensionsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("DataProcessor.CashForecast.Form.SettingUpDimensions",
		New Structure("ReportDimensions", Object.ReportDimensions),
		,,,,
		New CallbackDescription("PresentationReportDimensionsStartChoiceCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ApplyAndClose(Command)
	
	If CheckFilling() Then
		Result = New Structure(AttributesToChange());
		FillPropertyValues(Result, Object);
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function AttributesToChange()
	
	Return "PlanFromDate, TotalCurrency, HideDaysOff,
		|RequestsPendingApproval, PlannedCashReceipts, SalesOrders, PurchaseOrders, ReturnsToCustomers, ReturnsFromVendors,
		|LoansOrBorrowingsReceived, Deposits, IssuedBorrowings, Lease,
		|PlanningDays, EndDate, EndDateOfPlanningByDay, LongTermPlanningPeriods,
		|LongTermPlanningTimeFence, EndDateOfLongTermPlanning, ZeroBalancesAndTurnover,
		|ReportDimensions, DepthOfDisplayOfOverduePayments, GroupDocumentsWhenCreating";
	
EndFunction

&AtServer
Procedure FillInEndDates()
	
	DataProcessors.CashForecast.FillInEndDates(Object);
	
EndProcedure

&AtClientAtServerNoContext
Function PresentationReportDimensions(Groups)

	Presentation = "";
	For Each EmailGrouping In Groups Do
		If EmailGrouping.Check Then
			Presentation = Presentation + "," + EmailGrouping.Presentation;
		EndIf;
	EndDo;
	
	Return Mid(Presentation, 2);

EndFunction

&AtClient
Procedure PresentationReportDimensionsStartChoiceCompletion(ListOfDimensions, AdditionalParameters) Export

	If TypeOf(ListOfDimensions) = Type("ValueList") Then
		Object.ReportDimensions = ListOfDimensions;
		PresentationReportDimensions = PresentationReportDimensions(ListOfDimensions);
	EndIf;

EndProcedure

&AtClient
Function StringOfPlanningDays()

	Return StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';1 ngày;;1 ngày;1 ngày;1 ngày';
																			|ru = ';день;;дня;дней;дня';
																			|en = ';day;;;;days'; fa = ';day;;;;days';
																			|it = ';day;;;;days';
																			|pl = ';day;;;;days';
																			|tr = ';gün;;gün;gün;gün'"),
		Object.PlanningDays);

EndFunction

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
	If Item.Name = "sh_ShamsiInput_PlanFromDate" Then
		PlanFromDateOnChange(Items.PlanFromDate);
	ElsIf Item.Name = "sh_ShamsiInput_EndDate" Then
		EndDateOnChange(Items.EndDate);
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
