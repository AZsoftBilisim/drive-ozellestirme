
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure PeriodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	SelectionResult = Undefined;
	SelectPeriodFromDropDownList(SelectionResult, Item, PeriodType, Object.Period);
	
EndProcedure

&AtClient
Procedure LimitsThereIsNoExpenseLimitWhenChanging(Item)
	
	CurrentData = Items.Limits.CurrentData;
	
	If Not CurrentData.ThereIsLimit Then
		CurrentData.Sum = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInWithLimitsOfLastMonth(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Limits;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("FillInWithLimitsOfLastMonthCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInWithLimitsOfLastMonthCompletion(Result, AdditionalParameters) Export 
	
	FillInWithLimitsOfLastMonthServer();
	
EndProcedure

&AtClient
Procedure PopulateWithCashFlowItems(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Limits;
	CheckParameters.CheckForPromiscuity = False;
	Notification = New CallbackDescription("PopulateWithCashFlowItemsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure PopulateWithCashFlowItemsCompletion(Result, AdditionalParameters) Export 
	
	PopulateWithCashFlowItemsServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LimitsSum.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Limits.ThereIsLimit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không hạn chế>';
													|ru = '<не ограничен>';
													|en = '<not limited>'; fa = '<not limited>';
													|it = '<non limitato>';
													|pl = '<nie ograniczony>';
													|tr = '<sınırsız>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

#Region Other

&AtClient
Procedure SelectPeriodFromDropDownList(SelectionResult, Item, PeriodType, Period, IndexOfInitialValue = Undefined)
	
	PeriodsList = ListOfFixedPeriods(Period, PeriodType, CommonClient.SessionDate());
	If IndexOfInitialValue = Undefined Then
		IndexOfInitialValue = PeriodsList.FindByValue(Period);
	EndIf;
	If IndexOfInitialValue = Undefined Then
		IndexOfInitialValue = PeriodsList.Count() - 1;
	EndIf;
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("PeriodsList", PeriodsList);
	NotificationParameters.Insert("SelectionResult", SelectionResult);
	NotificationParameters.Insert("FormItem", Item);
	
	CallbackDescription = New CallbackDescription("SelectingPeriodFromListCompletion", ThisForm, NotificationParameters);
	
	ShowChooseFromList(CallbackDescription, PeriodsList, Item, IndexOfInitialValue);
	
EndProcedure

// The treatment of choice
// 
// Parameters:
//    SelectedElement - FormField - Selected element
//    AdditionalParameters - Structure - structure with fields:
//     * PeriodsList - ValueList - List of periods
//     * SelectionResult - String - Selected period
//     * FormItem - FormField - Field where the period is selected
//
&AtClient
Procedure SelectingPeriodFromListCompletion(SelectedElement, AdditionalParameters) Export
	
	SelectionResult = AdditionalParameters.SelectionResult;
	
	If SelectedElement = Undefined Then
		SelectionResult = Undefined;
		Return;
	EndIf;
	
	// Flipping up and down.
	PeriodsList = AdditionalParameters.PeriodsList;
	IndexOf = PeriodsList.IndexOf(SelectedElement);
	If IndexOf = 0 Or IndexOf = PeriodsList.Count() - 1 Then
		SelectPeriodFromDropDownList(
			SelectionResult, AdditionalParameters.FormItem, PeriodType, SelectedElement.Value, IndexOf);
	Else
		Object.Period = SelectedElement.Value;
		Modified = True;
		FillInPeriodSelectionList();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	PeriodType = Enums.AvailableReportPeriods.Month;
	
	FillInPeriodSelectionList();
	
	CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
	
	Items.LimitsSum.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Hạn mức (%1)';
			|ru = 'Лимит (%1)';
			|en = 'Limit (%1)'; fa = 'Limit (%1)';
			|it = 'Limite (%1)';
			|pl = 'Limit (%1)';
			|tr = 'Limit (%1)'"),
		String(CurrencyOfManAccounting));
	
EndProcedure

&AtServer
Procedure FillInPeriodSelectionList()
	
	PeriodSelectionList = Items.Period.ChoiceList;
	PeriodSelectionList.Clear();
	
	PeriodAsString = GetPeriodPresentation(PeriodType, Object.Period, EndOfMonth(Object.Period));
	PeriodSelectionList.Add(Object.Period, PeriodAsString);
	
EndProcedure

&AtServer
Procedure FillInWithLimitsOfLastMonthServer()
	
	Query = New Query(
	"SELECT
	|	CashFlowLimits.CashFlowItem AS CashFlowItem,
	|	TRUE AS ThereIsLimit,
	|	CashFlowLimits.LimitTurnover AS Sum
	|FROM
	|	AccumulationRegister.CashFlowLimits.Turnovers(
	|		DATEADD(&StartDate, MONTH, -1),
	|		DATEADD(&EndDate, MONTH, -1),
	|		,
	|		Organization = &Organization
	|		AND Department = &Department) AS CashFlowLimits");
	
	UseOrganizationLimits = GetFunctionalOption("UseCashFlowLimitsByCompanies"); 
	UseLimitsByDivision = GetFunctionalOption("UseCashFlowLimitsByBusinessUnit");
	
	Query.SetParameter("Organization", 
		?(UseOrganizationLimits, Object.Organization, Catalogs.Companies.EmptyRef()));
	Query.SetParameter("Department", 
		?(UseLimitsByDivision, Object.Department, Catalogs.BusinessStructure.EmptyRef()));
		
	Query.SetParameter("StartDate", Object.Period);
	Query.SetParameter("EndDate", EndOfMonth(Object.Period));
	
	Object.Limits.Load(Query.Execute().Unload());
	
	If Not Object.Limits.Count() Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không có dữ liệu để điền.';
												|ru = 'Отсутствуют данные для заполнения.';
												|en = 'No data to fill in.'; fa = 'No data to fill in.';
												|it = 'Mancano i dati per la compilazione.';
												|pl = 'Brak danych do wypełnienia.';
												|tr = 'Doldurma için veriler mevcut değil.'"),, "Object");
	EndIf;
	
EndProcedure

&AtServer
Procedure PopulateWithCashFlowItemsServer()
	
	Query = New Query("
	|SELECT DISTINCT
	|	CashFlowReportItems.Ref AS CashFlowItem
	|FROM
	|	Catalog.CashFlowReportItems.BusinessTransactions AS CashFlowReportItems
	|WHERE
	|	CashFlowReportItems.BusinessOperation IN (&OperationArray)
	|	AND NOT CashFlowReportItems.Ref.DeletionMark
	|	AND NOT CashFlowReportItems.Ref.IsFolder
	|");
	
	Query.SetParameter("OperationArray",
		Catalogs.CashFlowReportItems.EconomicOperationsOfCashFlow());
	Object.Limits.Load(Query.Execute().Unload());
	
EndProcedure

&AtServer
Function GetPeriodPresentation(PeriodType, Val BeginOfPeriod, Val EndOfPeriod)
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Custom") Then	
		If Not ValueIsFilled(BeginOfPeriod) And Not ValueIsFilled(EndOfPeriod) Then
			Return "";
		Else
			Return Format(BeginOfPeriod, "DF=MM/dd/yy") + " - " + Format(EndOfPeriod, "DF=MM/dd/yy");
		EndIf;
	Else
		BeginOfPeriod = BegOfDay(BeginOfPeriod);
		EndOfPeriod = EndOfDay(EndOfPeriod);
		EstimatedPeriodType = TMReportFunctionsClientServer.GetPeriodView(BeginOfPeriod, EndOfPeriod);
		If EstimatedPeriodType <> PeriodType And ValueIsFilled(BeginOfPeriod) Then
			PeriodType = EstimatedPeriodType;
		EndIf;
		
		List = ListOfFixedPeriods(BeginOfPeriod, PeriodType, CurrentSessionDate());
		
		ListItem = List.FindByValue(BeginOfPeriod);
		If ListItem <> Undefined Then
			Return ListItem.Presentation;
		Else
			Return "";
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

&AtClientAtServerNoContext
Function ListOfFixedPeriods(Val BeginOfPeriod, PeriodType, Today)
	
	PeriodsList = New ValueList;
	
	If BeginOfPeriod = '00010101' Then
		Return PeriodsList;
	EndIf;
	
	BeginOfPeriod = BegOfDay(BeginOfPeriod);
	
	Today = BegOfDay(Today);
	
	NavigationItemPreviouslyPresentation = NStr("vi = 'Trước đây...';
												|ru = 'Ранее...';
												|en = 'Previously ...'; fa = 'Previously ...';
												|it = 'Prima...';
												|pl = 'Wcześniej...';
												|tr = 'Önceden...'");
	NavigationItemLaterPresentation = NStr("vi = 'Muộn hơn...';
											|ru = 'Позже...';
											|en = 'Later ...'; fa = 'Later ...';
											|it = 'Dopo...';
											|pl = 'Później...';
											|tr = 'Daha sonra...'");
	
	If PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Day") Then
		CurDayOfWeek   = WeekDay(Today);
		SelectedDayOfWeek = WeekDay(BeginOfPeriod);
		
		// Calculation of the initial and final period by the formula. In 1 day 86400 seconds.
		StartingDayOfWeek = CurDayOfWeek - 5;
		EndDayOfWeek  = CurDayOfWeek + 1;
		If SelectedDayOfWeek > EndDayOfWeek Then
			SelectedDayOfWeek = SelectedDayOfWeek - 7;
		EndIf;
		
		Period = BeginOfPeriod - 86400 * (SelectedDayOfWeek - StartingDayOfWeek);
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		PeriodsList.Add(Period - 86400 * 7, NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For Counter = 1 To 7 Do
			PeriodsList.Add(Period, Format(Period, NStr("vi = 'ДФ=''дд ММММ гггг, дддд''';
														|ru = 'ДФ=''dd MMMM yyyy, dddd''';
														|en = 'DF=''MMMM dd yyyy, dddd'''; fa = 'DF=''MMMM dd yyyy, dddd''';
														|it = 'ДФ=''дд ММММ гггг, дддд''';
														|pl = 'DF=''dd MMMM yyyy, dddd''';
														|tr = 'DF=''dd MMMM yyyy, dddd'''"))
				+ ?(Period = Today, " - " + NStr("vi = 'hôm nay';
												|ru = 'сегодня';
												|en = 'today'; fa = 'today';
												|it = 'oggi';
												|pl = 'today';
												|tr = 'bugün'"), ""));
			Period = Period + 86400;
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		PeriodsList.Add(Period + 86400 * 6, NavigationItemLaterPresentation);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Week") Then
		CurStartOfWeek   = BegOfWeek(Today);
		SelectedStartOfWeek = BegOfWeek(BeginOfPeriod);
		
		// Calculation of the initial and final period by the formula. There are 604800 seconds in 7 days.
		DifferenceOfWeeks = (SelectedStartOfWeek - CurStartOfWeek) / 604800;
		ZoomRatio = (DifferenceOfWeeks - 2)/7;
		ZoomRatio = Int(ZoomRatio - ?(ZoomRatio < 0, 0.9, 0)); // Negative numbers are rounded to the largest part.
		InitialWeek = CurStartOfWeek + (2 + ZoomRatio*7) * 604800;
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		PeriodsList.Add(InitialWeek - 7 * 604800, NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For Counter = 0 To 6 Do
			Period = InitialWeek + Counter * 604800;
			EndOfPeriod  = EndOfWeek(Period);
			PeriodPresentation = Format(Period, "DF=dd.MM") + " - " + Format(EndOfPeriod, "DLF=D")
				+ " (" + WeekOfYear(EndOfPeriod) + " " + NStr("vi = 'tuần năm';
																|ru = 'неделя года';
																|en = 'week of the year'; fa = 'week of the year';
																|it = 'settimana dell''anno';
																|pl = 'tydzień roku';
																|tr = 'yıl haftası'") + ")";
			If Period = CurStartOfWeek Then
				PeriodPresentation = PeriodPresentation + " - " + NStr("vi = 'tuần này';
																		|ru = 'эта неделя';
																		|en = 'this week'; fa = 'this week';
																		|it = 'questa settimana';
																		|pl = 'ten tydzień';
																		|tr = 'bu hafta'");
			EndIf;
			PeriodsList.Add(Period, PeriodPresentation);
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		PeriodsList.Add(InitialWeek + 13 * 604800, NavigationItemLaterPresentation);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.TenDays") Then
		CurrentYear   = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentMonth   = Month(Today);
		SelectedMonth = Month(BeginOfPeriod);
		CurrentDay   = Day(Today);
		SelectedDay = Day(BeginOfPeriod);
		CurrentTenDays   = ?(CurrentDay   <= 10, 1, ?(CurrentDay   <= 20, 2, 3));
		SelectedDecade = ?(SelectedDay <= 10, 1, ?(SelectedDay <= 20, 2, 3));
		CurDecadeAbsolutely   = CurrentYear*36 + (CurrentMonth-1)*3 + (CurrentTenDays-1);
		ChosenDecadeIsAbsolutely = SelectedYear*36 + (SelectedMonth-1)*3 + (SelectedDecade-1);
		StringDecade = NStr("vi = '10 ngày';
							|ru = 'декада';
							|en = 'ten-day period'; fa = 'ten-day period';
							|it = 'decade';
							|pl = 'dekada';
							|tr = '10 günlük süre'");
		
		// Calculation of the initial and final period by the formula.
		ZoomRatio = (ChosenDecadeIsAbsolutely - CurDecadeAbsolutely - 2)/7;
		ZoomRatio = Int(ZoomRatio - ?(ZoomRatio < 0, 0.9, 0)); // Negative numbers are rounded to the largest part.
		InitialDecade = CurDecadeAbsolutely + 2 + ZoomRatio*7;
		FinalDecade  = InitialDecade + 6;
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		TenDays = InitialDecade - 7;
		Year = Int(TenDays/36);
		DecadeYear = TenDays - Year*36;
		MonthOfYear = Int(DecadeYear/3) + 1;
		DecadePerMonth = DecadeYear - (MonthOfYear-1)*3 + 1;
		Period = Date(Year, MonthOfYear, (DecadePerMonth - 1) * 10 + 1);
		PeriodsList.Add(Period, NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For TenDays = InitialDecade To FinalDecade Do
			Year = Int(TenDays/36);
			DecadeYear = TenDays - Year*36;
			MonthOfYear = Int(DecadeYear/3) + 1;
			DecadePerMonth = DecadeYear - (MonthOfYear-1)*3 + 1;
			Period = Date(Year, MonthOfYear, (DecadePerMonth - 1) * 10 + 1);
			Presentation = Format(Period, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
												|ru = 'ДФ=''MMMM yyyy''';
												|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
												|it = 'ДФ=''ММММ гггг''';
												|pl = 'DF=''MMMM yyyy''';
												|tr = 'DF=''MMMM yyyy'''"))
				+ ", " + Left("III", DecadePerMonth)
				+ " " + StringDecade + ?(TenDays = CurDecadeAbsolutely, " - " + NStr("vi = 'mười ngày này';
																					|ru = 'эта декада';
																					|en = 'this ten-day period'; fa = 'this ten-day period';
																					|it = 'questa decade';
																					|pl = 'bieżąca dekada';
																					|tr = 'bu 10 günlük süredir'"), "");
			PeriodsList.Add(Period, Presentation);
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		TenDays = FinalDecade + 1;
		Year = Int(TenDays/36);
		DecadeYear = TenDays - Year*36;
		MonthOfYear = Int(DecadeYear/3) + 1;
		DecadePerMonth = DecadeYear - (MonthOfYear-1)*3 + 1;
		Period = Date(Year, MonthOfYear, (DecadePerMonth - 1) * 10 + 1);
		PeriodsList.Add(Period, NavigationItemLaterPresentation);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Month") Then
		CurrentYear   = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentMonth   = CurrentYear*12   + Month(Today);
		SelectedMonth = SelectedYear*12 + Month(BeginOfPeriod);
		
		// Calculation of the initial and final period by the formula.
		ZoomRatio = (SelectedMonth - CurrentMonth - 2)/7;
		ZoomRatio = Int(ZoomRatio - ?(ZoomRatio < 0, 0.9, 0)); // Negative numbers are rounded to the largest part.
		InitialMonth = CurrentMonth + 2 + ZoomRatio*7;
		EndMonth  = InitialMonth + 6;
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		Month = InitialMonth - 7;
		Year = Int((Month - 1) / 12);
		MonthOfYear = Month - Year * 12;
		Period = Date(Year, MonthOfYear, 1);
		PeriodsList.Add(Period, NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For Month = InitialMonth To EndMonth Do
			Year = Int((Month - 1) / 12);
			MonthOfYear = Month - Year * 12;
			Period = Date(Year, MonthOfYear, 1);
			PeriodsList.Add(Period, Format(Period, NStr("vi = 'ДФ=''""tháng"" ММ ""năm"" гггг''';
														|ru = 'ДФ=''MMMM yyyy''';
														|en = 'DF=''MMMM yyyy'''; fa = 'DF=''MMMM yyyy''';
														|it = 'ДФ=''ММММ гггг''';
														|pl = 'DF=''MMMM yyyy''';
														|tr = 'DF=''MMMM yyyy'''"))
				+ ?(Year = CurrentYear And CurrentMonth = Month, " - " + NStr("vi = 'tháng này';
																				|ru = 'этот месяц';
																				|en = 'this month'; fa = 'this month';
																				|it = 'questo mese';
																				|pl = 'ten miesiąc';
																				|tr = 'bu ay'"), ""));
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		Month = EndMonth + 1;
		Year = Int((Month - 1) / 12);
		MonthOfYear = Month - Year * 12;
		Period = Date(Year, MonthOfYear, 1);
		PeriodsList.Add(Period, NavigationItemLaterPresentation);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Quarter") Then
		CurrentYear = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentQuarter   = 1 + Int((Month(Today)-1)/3);
		SelectedQuarter = 1 + Int((Month(BeginOfPeriod)-1)/3);
		CurrentQuarterIsAbsolutely   = CurrentYear*4   + CurrentQuarter   - 1;
		SelectedQuarterAbsolutely = SelectedYear*4 + SelectedQuarter - 1;
		LineQuarter = NStr("vi = 'quý';
							|ru = 'квартал';
							|en = 'quarter'; fa = 'quarter';
							|it = 'trimestre';
							|pl = 'kwartał';
							|tr = 'çeyrek'");
		
		// Calculation of the initial and final period by the formula.
		ZoomRatio = (SelectedQuarterAbsolutely - CurrentQuarterIsAbsolutely - 2)/7;
		ZoomRatio = Int(ZoomRatio - ?(ZoomRatio < 0, 0.9, 0)); // Negative numbers are rounded to the largest part.
		InitialQuarter = CurrentQuarterIsAbsolutely + 2 + ZoomRatio*7;
		FinalQuarter  = InitialQuarter + 6;
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		Quarter = InitialQuarter - 7;
		Year = Int(Quarter/4);
		QuarterOfYear = Quarter - Year*4 + 1;
		MonthOfYear = (QuarterOfYear-1)*3 + 1;
		Period = Date(Year, MonthOfYear, 1);
		PeriodsList.Add(Period, NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For Quarter = InitialQuarter To FinalQuarter Do
			Year = Int(Quarter/4);
			QuarterOfYear = Quarter - Year*4 + 1;
			MonthOfYear = (QuarterOfYear-1)*3 + 1;
			Period = Date(Year, MonthOfYear, 1);
			Presentation = ?(QuarterOfYear = 4, "IV", Left("III", QuarterOfYear))
				+ " " + LineQuarter + " " + Format(Period, NStr("vi = 'ДФ=''гггг''';
																|ru = 'ДФ=''yyyy''';
																|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
																|it = 'FD=''aaaa''';
																|pl = 'DF=''yyyy''';
																|tr = 'DF=''yyyy'''"))
				+ ?(Quarter = CurrentQuarterIsAbsolutely, " - " + NStr("vi = 'quý này';
																		|ru = 'этот квартал';
																		|en = 'this quarter'; fa = 'this quarter';
																		|it = 'questo trimestre';
																		|pl = 'bieżący kwartał';
																		|tr = 'bu çeyrek'"), "");
			PeriodsList.Add(Period, Presentation);
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		Quarter = FinalQuarter + 1;
		Year = Int(Quarter/4);
		QuarterOfYear = Quarter - Year*4 + 1;
		MonthOfYear = (QuarterOfYear-1)*3 + 1;
		Period = Date(Year, MonthOfYear, 1);
		PeriodsList.Add(Period, NavigationItemLaterPresentation);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.HalfYear") Then
		CurrentYear = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		CurrentHalfYear   = 1 + Int((Month(Today)-1)/6);
		SelectedHalfYear = 1 + Int((Month(BeginOfPeriod)-1)/6);
		CurrentHalfYearIsAbsolutely   = CurrentYear*2   + CurrentHalfYear   - 1;
		SelectedHalfYearAbsolutely = SelectedYear*2 + SelectedHalfYear - 1;
		LineHalfYear = NStr("vi = 'nửa năm';
							|ru = 'полугодие';
							|en = 'half-year'; fa = 'نیم‌سال';
							|it = 'semestre';
							|pl = 'półrocze';
							|tr = 'yarıyıl'");
		
		// Calculation of the initial and final period by the formula.
		ZoomRatio = (SelectedHalfYearAbsolutely - CurrentHalfYearIsAbsolutely - 2)/7;
		ZoomRatio = Int(ZoomRatio - ?(ZoomRatio < 0, 0.9, 0)); // Negative numbers are rounded to the largest part.
		InitialHalfYear = CurrentHalfYearIsAbsolutely + 2 + ZoomRatio*7;
		FinalHalfYear  = InitialHalfYear + 6;
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		HalfYear = InitialHalfYear - 7;
		Year = Int(HalfYear/2);
		HalfYearInYear = HalfYear - Year*2 + 1;
		MonthOfYear = (HalfYearInYear-1)*6 + 1;
		Period = Date(Year, MonthOfYear, 1);
		PeriodsList.Add(Period, NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For HalfYear = InitialHalfYear To FinalHalfYear Do
			Year = Int(HalfYear/2);
			HalfYearInYear = HalfYear - Year*2 + 1;
			MonthOfYear = (HalfYearInYear-1)*6 + 1;
			Period = Date(Year, MonthOfYear, 1);
			Presentation = Left("II", HalfYearInYear) + " "
				+ LineHalfYear + " " + Format(Period, NStr("vi = 'ДФ=''гггг''';
															|ru = 'ДФ=''yyyy''';
															|en = 'DF=''yyyy'''; fa = 'DF=''yyyy''';
															|it = 'FD=''aaaa''';
															|pl = 'DF=''yyyy''';
															|tr = 'DF=''yyyy'''"))
				+ ?(HalfYear = CurrentHalfYearIsAbsolutely, " - " + NStr("vi = 'nửa năm này';
																		|ru = 'это полугодие';
																		|en = 'this half-year'; fa = 'this half-year';
																		|it = 'questi sei mesi';
																		|pl = 'bieżące półrocze';
																		|tr = 'bu yarıyıldır'"), "");
			PeriodsList.Add(Period, Presentation);
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		HalfYear = FinalHalfYear + 1;
		Year = Int(HalfYear/2);
		HalfYearInYear = HalfYear - Year*2 + 1;
		MonthOfYear = (HalfYearInYear-1)*6 + 1;
		Period = Date(Year, MonthOfYear, 1);
		PeriodsList.Add(Period, NavigationItemLaterPresentation);
		
	ElsIf PeriodType = PredefinedValue("Enum.AvailableReportPeriods.Year") Then
		CurrentYear = Year(Today);
		SelectedYear = Year(BeginOfPeriod);
		
		// Calculation of the initial and final period by the formula.
		ZoomRatio = (SelectedYear - CurrentYear - 2)/7;
		ZoomRatio = Int(ZoomRatio - ?(ZoomRatio < 0, 0.9, 0)); // Negative numbers are rounded to the largest part.
		StartingYear = CurrentYear + 2 + ZoomRatio*7;
		FinalYear = StartingYear + 6;
		
		// Adding the navigation item "<Earlier>..." to go to earlier periods.
		PeriodsList.Add(Date(StartingYear-7, 1, 1), NavigationItemPreviouslyPresentation);
		
		// Adding values.
		For Year = StartingYear To FinalYear Do
			PeriodsList.Add(Date(Year, 1, 1), Format(Year, "NG=")
				+ ?(Year = CurrentYear, " - " + NStr("vi = 'năm nay';
													|ru = 'этот год';
													|en = 'this year'; fa = 'this year';
													|it = 'quest''anno';
													|pl = 'bieżący rok';
													|tr = 'bu yıl'"), ""));
		EndDo;
		
		// Adding a navigation point "<Later >..." to move to later periods.
		PeriodsList.Add(Date(FinalYear+7, 1, 1), NavigationItemLaterPresentation);
	EndIf;
	
	Return PeriodsList;
	
EndFunction

#EndRegion

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
