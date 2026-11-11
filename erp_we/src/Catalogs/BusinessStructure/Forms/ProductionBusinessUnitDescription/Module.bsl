
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ThisIsCA = GetFunctionalOption("ComplexAutomation");
	
	Parameters.Property("Ref", Ref);
	ObjectData = GetFromTempStorage(Parameters.StorageAddressObjectData);
	ObjectMetadata = Object.Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		Object[Attribute.Name] = ObjectData[Attribute.Name];
	EndDo;
	For Each TabularSection In ObjectMetadata.TabularSections Do
		
		If TabularSection.Name = "WorkSchedules"
			And Object.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule Then
			
			If ObjectData.WorkSchedules.Count() <> 0 Then
				WorkScheduleCalendar = ObjectData.WorkSchedules[0].WorkScheduleCalendar;
				Continue;
			EndIf;
			
		EndIf;
		
		Object[TabularSection.Name].Load(ObjectData[TabularSection.Name]);
		
	EndDo;
	MaterialsWarehouse = ObjectData.MaterialsWarehouse;
	ProductionSettings = ProductionServer.SubsystemSettingsProduction();
	Production21 = ProductionSettings.ProductionIsUsed21;
	Production22 = ProductionSettings.ProductionIsUsed22;
	TheProductionScheduleIsPlanned = ProductionSettings.TheProductionScheduleIsPlanned;
	DynamicStructureOfProductionOrders = ProductionSettings.DynamicStructureOfProductionOrders;
	UsePlanningIntervalHour = Constants.UsePlanningIntervalHour.Get();
	
	ConfigureIntervalSelectionList();
	InitializeSchedulingIntervalParameters();
	SetTextHoursDaysMonthsWeeks();
	If Object.UseTeamWorkOrders And Object.UsePersonalWorkOrders Then
		WorkOrderKinds = "TeamsAndEmployees";
	ElsIf Object.UseTeamWorkOrders Then
		WorkOrderKinds = "Teams";
	Else
		WorkOrderKinds = "Employees";
	EndIf;
	
	If Object.RecordingExpensesOnProcustCostIsUsed Then
		TheUseOfTheWriteOffOfIssueCosts = 1;
	Else
		TheUseOfTheWriteOffOfIssueCosts = 2;
	EndIf;
	
	EnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
	If Not EnterpriseCalendar.IsEmpty() Then
		Items.PagesEnterpriseCalendar.CurrentPage = Items.PageCalendarIsSet;
	Else
		Items.PagesEnterpriseCalendar.CurrentPage = Items.PageCalendarIsNotSet;
	EndIf; 
	If Not TheProductionScheduleIsPlanned And Not Object.UseManufacturingExecutionSystem And Not DynamicStructureOfProductionOrders Then
		
		ToolTip    = Items.UseManufacturingExecutionSystem.ToolTip;
		AdditionalHint = NStr("vi = 'Để sử dụng lập kế hoạch giao dịch, cần bật sử dụng lịch sản xuất (phân hệ ""Danh mục và Quản trị"" - ""Sản xuất"").';
								|ru = 'Для использования пооперационного планирования необходимо включить использование графика производства (раздел ""НСИ и администрирование"" - ""Производство"").';
								|en = 'To use Manufacturing execution system (MES), enable production schedule usage (Master data and settings - Manufacturing).'; fa = 'To use Manufacturing execution system (MES), enable production schedule usage (Master data and settings - Manufacturing).';
								|it = 'Per utilizzare la gestione consecutiva delle operazioni è necessario attivare l''utilizzo dell''orario di produzione (campo ""Informazione normativa di riferimento e amministrazione"" - ""Produzione"").';
								|pl = 'Aby używać planowania operacyjnego należy włączyć używanie harmonogramu produkcji (rozdział ""Ustawienia"" - ""Produkcja"").';
								|tr = 'İşlemsel planlamayı kullanmak için, üretim programı kullanımının etkinleştirilmesi gerekir (""Master veri ve yönetim"" - ""Üretim"" bölümü).'");
		
		If IsBlankString(ToolTip) Then
			Items.UseManufacturingExecutionSystem.ToolTip = AdditionalHint;
		Else
			Items.UseManufacturingExecutionSystem.ToolTip = ?(Right(ToolTip, 1) = ".",
				StrTemplate("%1 %2", ToolTip, AdditionalHint),
				StrTemplate("%1. %2", ToolTip, AdditionalHint));
		EndIf;
		
	EndIf;
	VisibilityManagement();
	
	If AccessRight("Update", Metadata.Catalogs.BusinessStructure) Then
		AvailabilityControl();
	Else
		ReadOnly = True;
	EndIf;
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm,,, New Structure("Ref", Ref));
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule
			And WorkScheduleCalendar.IsEmpty() Then
		MessageText = NStr("vi = 'Trường ""Lịch biểu"" trống';
							|ru = 'Поле ""График работы"" не заполнено';
							|en = '""Work schedule"" is required'; fa = '""Work schedule"" is required';
							|it = 'Il campo ""Orario di lavoro"" non è compilato';
							|pl = 'Nie wypełniono pola ""Harmonogram pracy""';
							|tr = '""Çalışma takvimi"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(MessageText,, "WorkScheduleCalendar",, Cancel);
	EndIf;
	If Object.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.Shifts
			And Object.WorkSchedules.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa nhập dòng nào vào danh sách ""Phiên làm việc"".';
							|ru = 'Не введено ни одной строки в список ""Смены""';
							|en = 'No lines entered into the Shifts list'; fa = 'No lines entered into the Shifts list';
							|it = 'Non è stata inserita nemmeno una riga nell''elenco ""Turni""';
							|pl = 'Nie wprowadzono ani jednego wiersza do listy ""Zmiany""';
							|tr = '""Vardiyalar"" listesine satır girilmedi'");
		CommonClientServer.MessageToUser(MessageText,, "WorkSchedules", "Object", Cancel);
	EndIf;
	
	ShiftContent = New Map;
	For Each String In Object.WorkSchedules Do
		
		If String.WorkScheduleCalendar.IsEmpty() Then
			
			MessageText = StrTemplate(NStr("vi = 'Chưa điền cột ""Phiên làm việc"" vào dòng %1 trong danh sách ""Phiên làm việc"".';
											|ru = 'Не заполнена колонка ""Смена"" в строке %1 списка ""Смены"".';
											|en = 'Column ""Shift"" in line %1 of the ""Shifts"" list is not filled in.'; fa = 'Column ""Shift"" in line %1 of the ""Shifts"" list is not filled in.';
											|it = 'La colonna ""Turno"" nella riga %1 dell''elenco ""Turni"" non è compilata.';
											|pl = 'Nie wypełniono kolumny ""Zmiana"" w wierszu %1 listy ""Zmiany"".';
											|tr = '""Vardiyalar"" listesinin %1 satırındaki ""Vardiya"" sütunu doldurulmadı.'"),
				Format(String.LineNumber, "NG="));
			Field = CommonClientServer.PathToTabularSection("WorkSchedules", String.LineNumber, "WorkScheduleCalendar");
			CommonClientServer.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		Else
			
			If ShiftContent.Get(String.WorkScheduleCalendar) = Undefined Then
				
				ShiftContent.Insert(String.WorkScheduleCalendar, False);
				
			Else
				
				If Not ShiftContent[String.WorkScheduleCalendar] Then
					
					MessageText = StrTemplate(NStr("vi = 'Phiên làm việc ""%1"" đã được chỉ định nhiều lần trong danh sách ""Phiên làm việc"".';
													|ru = 'Смена ""%1"" указана в списке ""Смены"" более одного раза.';
													|en = 'The ""%1"" shift is specified in the Shifts list more than once.'; fa = 'The ""%1"" shift is specified in the Shifts list more than once.';
													|it = 'Il turno ""%1"" è indicato più di una volta nell''elenco ""Turni"".';
													|pl = 'Zmiana ""%1"" jest wskazana na liście ""Zmiany"" więcej niż jeden raz.';
													|tr = 'Vardiya ""%1"", Vardiyalar listesinde birden çok kez belirtiliyor.'"),
						String.WorkScheduleCalendar);
					Field = CommonClientServer.PathToTabularSection("WorkSchedules", String.LineNumber, "WorkScheduleCalendar");
					CommonClientServer.MessageToUser(MessageText,, Field, "Object", Cancel);
					
					ShiftContent[String.WorkScheduleCalendar] = True;
					
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	If Object.ProductionByOrders Then
		
		
		If Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Day
			And BegOfMinute(TheBeginningOfThePlanningIntervalTheTimeOfDay) >= BegOfMinute(TheEndOfThePlanningIntervalTheTimeOfDay) Then
			MessageText = NStr("vi = 'Thời gian bắt đầu lập kế hoạch lớn hơn thời gian kết thúc';
								|ru = 'Время начала интервала планирования больше времени окончания';
								|en = 'Planning interval start time is greater than end time'; fa = 'Planning interval start time is greater than end time';
								|it = 'L''ora di inizio dell''intervallo di pianificazione è più lunga dell''ora di fine';
								|pl = 'Czas rozpoczęcia interwału planowania jest późniejszy od czasu zakończenia';
								|tr = 'Planlama aralığının başlangıç ​​zamanı, bitiş zamanından daha büyük'");
			CommonClientServer.MessageToUser(MessageText,, "EndOfThePlanningIntervalDay",, Cancel);
		ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Week
			And Enums.WeekDays.IndexOf(StartOfThePlanningIntervalDayOfTheWeek) >= Enums.WeekDays.IndexOf(EndOfThePlanningIntervalDayOfTheWeek) Then
			MessageText = NStr("vi = 'Thời gian bắt đầu lập kế hoạch lớn hơn thời gian kết thúc';
								|ru = 'Время начала интервала планирования больше времени окончания';
								|en = 'Planning interval start time is greater than end time'; fa = 'Planning interval start time is greater than end time';
								|it = 'L''ora di inizio dell''intervallo di pianificazione è più lunga dell''ora di fine';
								|pl = 'Czas rozpoczęcia interwału planowania jest późniejszy od czasu zakończenia';
								|tr = 'Planlama aralığının başlangıç ​​zamanı, bitiş zamanından daha büyük'");
			CommonClientServer.MessageToUser(MessageText,, "EndOfThePlanningIntervalWeekDay",, Cancel);
		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("FinishEditingAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseEnterpriseScheduleOnChange(Item)
	
	If Not WorkScheduleCalendar.IsEmpty() Then
		WorkScheduleCalendar = Undefined;
	EndIf;
	If Object.WorkSchedules.Count() <> 0 Then
		Object.WorkSchedules.Clear();
	EndIf;
	
	UseScheduleOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure UseIndividualScheduleOnChange(Item)
	
	If Object.WorkSchedules.Count() <> 0 Then
		Object.WorkSchedules.Clear();
	EndIf;
	
	UseScheduleOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure UseShiftsOnChange(Item)
	
	If Not WorkScheduleCalendar.IsEmpty() Then
		WorkScheduleCalendar = Undefined;
	EndIf;
	
	UseShiftsOnChangesAtServer()
	
EndProcedure

&AtClient
Procedure PlanningIntervalOnChange(Item)
	If Object.PlanningInterval.IsEmpty() Then
		Object.PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Day");
	EndIf;
	
	SchedulingIntervalForChangesOnServer();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure OperationSheetManagementOnChange(Item)
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure UseOperationManagementOnChange(Item)
	
	If Not Object.UseOperationManagement Then
		
		Object.UseMaterialsInOperations = False;
		Object.UseFinishedProductsInOperations = False;
		Object.UseShiftTasks = False;
		Object.UseManufacturingExecutionSystem = False;
		
	EndIf;
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure UseShiftTasksOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure UseManufacturingExecutionSystemOnChange(Item)
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure FillInAvailabilityForProductionScheduleIntervalQuantityOnChange(Item)
	
	SetTextHoursDaysMonthsWeeks();
	
EndProcedure

&AtClient
Procedure FillInAvailabilityForWorkCenterTimetableNumberOfIntervalsOnChange(Item)
	
	SetTextHoursDaysMonthsWeeks();
	
EndProcedure

&AtClient
Procedure ObjectProductionByOrdersOnChange(Item)
	
	Object.ProductionBusinessUnit = Object.BackflushProduction_ Or Object.ProductionByOrders;
	
	If Not Object.ProductionByOrders Then
		
		Object.UseProductionSites = False;
		Object.UseOperationManagement = False;
		Object.UseMaterialsInOperations = False;
		Object.UseFinishedProductsInOperations = False;
		Object.UseShiftTasks = False;
		Object.UseManufacturingExecutionSystem = False;
		
	EndIf;
	
	ProductionByOrderObjectWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure ObjectBackflushProduction_OnChange(Item)
	
	Object.ProductionBusinessUnit = Object.BackflushProduction_ Or Object.ProductionByOrders;
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure ObjectProductionBusinessUnitOnChange(Item)
	
	Object.BackflushProduction_ = Object.ProductionBusinessUnit;
	
	If Not ThisIsCA Then
		Object.ProductionByOrders = Object.ProductionBusinessUnit;
	EndIf;
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure TypesOfOutfitsWhenChanging(Item)
	
	Object.UseTeamWorkOrders = WorkOrderKinds = "TeamsAndEmployees" Or WorkOrderKinds = "Teams";
	Object.UsePersonalWorkOrders = WorkOrderKinds = "TeamsAndEmployees" Or WorkOrderKinds = "Employees";
	
	If Not Object.UseTeamWorkOrders Then
		Object.UseLPR = False;
		Object.UseTariffRates = False;
		Object.UseHoursWorked = False;
	EndIf;
	
	Items.UseLPR.Enabled = Object.UseTeamWorkOrders;
	Items.UseHoursWorked.Enabled = Object.UseTeamWorkOrders;
	Items.UseTariffRates.Enabled = Object.UseHoursWorked;
	
EndProcedure

&AtClient
Procedure UseHoursWorkedOnChange(Item)
	
	If Not Object.UseHoursWorked Then
		Object.UseTariffRates = False;
	EndIf;
	
	Items.UseTariffRates.Enabled = Object.UseHoursWorked;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShifts

&AtClient
Procedure WorkSchedulesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.WorkSchedules.ReadOnly Then
		
		StandardProcessing = False;
		ShowValue(, Object.WorkSchedules.FindByID(RowSelected).WorkScheduleCalendar);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingCommand(Command)
	
	FinishEditingAndClose(Undefined, Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NameOfUnlockForm = "Catalog.BusinessStructure.Form.UnlockProductionParameters";
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject);
	ProcedureParameters.Object = New Structure("Ref", Ref);
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure VisibilityManagement()
	Items.ProductionGroup.Visible       = ThisIsCA Or (Production22 And Not Production21);
	
	Items.GroupDivisionDispatcher.Visible = Not ThisIsCA;
	Items.ProductionGroup21.Visible     = Not ThisIsCA And Production21;
	Items.GroupProductionByOrders.Visible  = Not ThisIsCA;
	Items.LaborCostsGroup.Visible           = Production22;
	
	Items.RouteListManagementGroup.Visible = Not ThisIsCA And Production21;
	Items.SemiFinishedProductsReceiptMethod.Visible      = Not ThisIsCA And Production21;
	Items.MaterialsWarehouse.Visible                    = Not ThisIsCA And Production21;
	Items.GroupProductionWithoutOrdersAtP21.Visible   = Not ThisIsCA And Production21;
	Items.GroupProductionWithoutOrdersKA.Visible     = ThisIsCA And Production21;
	
	Items.IntraShopManagementGroup2_2.Visible    = Not ThisIsCA And Production22;
	Items.UseShifts.Visible                   = Not ThisIsCA And Not Production21 And Production22;
	Items.WorkSchedules.Visible                       = Not ThisIsCA And Not Production21 And Production22;
	Items.UseShiftTasks.Visible          = Not ThisIsCA And Not Production21 And Production22;
	Items.UseProductionSites.Visible = Not ThisIsCA And Not Production21 And Production22;
	
	Items.OutputRegistrationFrequency.Visible = Constants.UseOutputRegistrationFrequency.Get();
	
	If Not ThisIsCA Then
		
		If Production21 And Production22 Then
			Items.IntraShopManagementGroup.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Else
			Items.IntraShopManagementGroup.PagesRepresentation = FormPagesRepresentation.None;
		EndIf;
		
	EndIf;
	Return; // in ut empty
	
EndProcedure

&AtServer
Procedure AvailabilityControl()
	
	NoEditingOfBankingDetails = EditingBankingDetailsIsProhibited();
	
	
	AvailableManufacturingExecutionSystem = Not DynamicStructureOfProductionOrders;
	
	If PropsAreEditable("UseMaterialsInOperations", NoEditingOfBankingDetails) Then
		Items.UseMaterialsInOperations.Enabled = Object.UseOperationManagement;
	EndIf;
	
	If PropsAreEditable("UseFinishedProductsInOperations", NoEditingOfBankingDetails) Then
		Items.UseFinishedProductsInOperations.Enabled = Object.UseOperationManagement;
	EndIf;
	
	If PropsAreEditable("UseShiftTasks", NoEditingOfBankingDetails) Then
		Items.UseShiftTasks.Enabled = Object.UseOperationManagement
			And (Not Object.UseManufacturingExecutionSystem Or Not AvailableManufacturingExecutionSystem);
	EndIf;
		
	If Not AvailableManufacturingExecutionSystem Then
		Items.UseManufacturingExecutionSystem.Visible = False;
	Else
		If PropsAreEditable("UseManufacturingExecutionSystem", NoEditingOfBankingDetails) Then
			Items.UseManufacturingExecutionSystem.Enabled = Object.UseOperationManagement
				And Not Object.UseShiftTasks
				And (TheProductionScheduleIsPlanned Or Object.UseManufacturingExecutionSystem);
		EndIf;
	EndIf;
	
	If PropsAreEditable("WorkSchedules", NoEditingOfBankingDetails) Then
		Items.WorkSchedules.Enabled = (Object.WorkScheduleSetupMethod
			= Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.Shifts);
		Items.WorkSchedules.AutoMarkIncomplete = Items.WorkSchedules.Enabled;
	EndIf;
	
	If PropsAreEditable("WorkScheduleCalendar", NoEditingOfBankingDetails) Then
		Items.WorkScheduleCalendar.Enabled = (Object.WorkScheduleSetupMethod
			= Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule);
		Items.WorkScheduleCalendar.AutoMarkIncomplete = Items.WorkScheduleCalendar.Enabled;
	EndIf;
	
	Items.GroupProductionByOrders.Enabled =
		Object.ProductionByOrders And Production21
		Or Object.ProductionBusinessUnit And Not Production21;
	
	Items.GroupProductionWithoutOrdersAtP21.Enabled = Not ThisIsCA And Object.BackflushProduction_;
	Items.GroupProductionWithoutOrdersKA.Enabled   = ThisIsCA And Object.BackflushProduction_;
	
	Items.ProductionCalendarGroup.Enabled = ThisIsCA And Object.BackflushProduction_ Or Not ThisIsCA;
	Items.AGroupOfWarehouseMaterials.Enabled = ThisIsCA And Object.BackflushProduction_ Or Not ThisIsCA;
	
	Items.LaborCostsGroup.Enabled = Object.ProductionBusinessUnit;
	
	Items.UseLPR.Enabled = Object.UseTeamWorkOrders;
	Items.UseHoursWorked.Enabled = Object.UseTeamWorkOrders;
	Items.UseTariffRates.Enabled = Object.UseHoursWorked;
	
EndProcedure

&AtServer
Procedure SetTextHoursDaysMonthsWeeks()
	
	If Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour
		Or Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift
		Or Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		NumerationItemOptions = NStr("vi = 'ngày, ngày, ngày, m ,,,,, 0';
									|ru = 'день, дня, дней, м,,,,,0';
									|en = 'day, days,,,0'; fa = 'day, days,,,0';
									|it = 'giorno, del giorno, dei giorni, m,,,,,0';
									|pl = 'dzień, dnia, dni, m,,,,,0';
									|tr = 'gün, gün, günler,,,,,,0'");
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		NumerationItemOptions = NStr("vi = 'tuần, tuần, tuần, w ,,,,, 0';
									|ru = 'неделю, недели, недель, ж,,,,,0';
									|en = 'week, weeks,,,0'; fa = 'week, weeks,,,0';
									|it = 'settimana, della settimana, delle settimane, g,,,,,0';
									|pl = 'tydzień, tygodnia, tygodni, k,,,,,0';
									|tr = 'hafta, haftalar, hafta,,,,,,0'");
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		NumerationItemOptions = NStr("vi = 'tháng, tháng, tháng, m ,,,,, 0';
									|ru = 'месяц, месяца, месяцев, м,,,,,0';
									|en = 'month, months,,,0'; fa = 'month, months,,,0';
									|it = 'mese, del mese, dei mesi, m,,,,,0';
									|pl = 'miesiąc, miesiąca, miesięcy, m,,,,,0';
									|tr = 'ay, ayın, ayların,,,,,,0'");
	Else
		NumerationItemOptions = NStr("vi = 'khoảng, khoảng, khoảng, m ,,,,, 0';
									|ru = 'интервал, интервала, интервалов, м,,,,,0';
									|en = 'interval, intervals,,,0'; fa = 'interval, intervals,,,0';
									|it = 'intervallo, dell''intervallo, degli intervalli, m,,,,,0';
									|pl = 'interwał, interwału, interwałów, m,,,,,0';
									|tr = 'aralık, aralığın, aralıkların,,,,,,0'");
	EndIf;
	
	PeriodInWords = GetPeriodInWords(Object.FillInAvailabilityForProductionScheduleIntervalQuantity, NumerationItemOptions);
	Items.HoursDaysWeeksMonths.Title = StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = '%1 và nhắc nhở về việc lập trong';
														|ru = '%1 и напоминать о составлении за';
														|en = '%1 and remind of drawing up in'; fa = '%1 and remind of drawing up in';
														|it = '%1 e ricordare della stesura per';
														|pl = '%1 i przypominaj o sporządzaniu za';
														|tr = '%1 ve hazırlamayı hatırlat'"),
													PeriodInWords);
													
	PeriodInWords = GetPeriodInWords(Object.FillInAvailabilityForWorkCenterTimetableNumberOfIntervals, NumerationItemOptions);
	Items.HoursDaysWeeksMonths1.Title = StringFunctionsClientServer.SubstituteParametersToString(
													NStr("vi = '%1 và nhắc nhở về việc lập trong';
														|ru = '%1 и напоминать о составлении за';
														|en = '%1 and remind of drawing up in'; fa = '%1 and remind of drawing up in';
														|it = '%1 e ricordare della stesura per';
														|pl = '%1 i przypominaj o sporządzaniu za';
														|tr = '%1 ve hazırlamayı hatırlat'"),
													PeriodInWords);
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FinishEditingAndClose(Result, AdditionalParameters) Export

	ClearMessages();
	If Not CheckFilling() Then
		Return
	EndIf;
	
	Modified = False;
	
	Close(
		PrepareDataForRecordingAndPlaceItInStorage());
	
EndProcedure

&AtServer
Function PrepareDataForRecordingAndPlaceItInStorage()
	
	Object.RecordingExpensesOnProcustCostIsUsed =
		TheUseOfTheWriteOffOfIssueCosts = 1
			And Object.BackflushProduction_;
	
	If Object.WorkScheduleSetupMethod =
			Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule Then
		Object.WorkSchedules.Add().WorkScheduleCalendar = WorkScheduleCalendar;
	EndIf;
	SaveSchedulingIntervalSetting();
	ObjectData = New Structure;
	ObjectMetadata = Object.Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		ObjectData.Insert(Attribute.Name, Object[Attribute.Name]);
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		ObjectData.Insert(TabularSection.Name, Object[TabularSection.Name].Unload());
	EndDo;
	
	ObjectData.Insert("MaterialsWarehouse", MaterialsWarehouse);
	
	Return PutToTempStorage(ObjectData, UUID);
	
EndFunction

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisForm, Result);
		AvailabilityControl();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProductionByOrderObjectWhenModifiedOnServer()
	If Object.PlanningInterval.IsEmpty() Then
		Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Day;
		SchedulingIntervalForChangesOnServer();
	EndIf;
	
	
	AvailabilityControl();
	
EndProcedure

&AtServer
Function EditingBankingDetailsIsProhibited()
	
	Result = False;
	
	FormAttributes = ThisObject.GetAttributes();
	For Each FormAttribute In FormAttributes Do
		If FormAttribute.Name = "AttributeEditProhibitionParameters" Then
			Result = True;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function PropsAreEditable(Var_AttributeName, NoEditingOfBankingDetails)
	
	If Not NoEditingOfBankingDetails Then
		Result = True;
	Else
		
		TheStructureOfTheSearch = New Structure("AttributeName", Var_AttributeName);
		FoundRows = ThisObject.AttributeEditProhibitionParameters.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() = 0 Then
			Result = True;
		Else
			Result = FoundRows[0].EditingAllowed;
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure UseScheduleOnChangesAtServer()
	If Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Day;
		SchedulingIntervalForChangesOnServer();
	EndIf;
	ConfigureIntervalSelectionList();
	AvailabilityControl();
	
EndProcedure

&AtServer
Procedure UseShiftsOnChangesAtServer()
	ConfigureIntervalSelectionList();
	AvailabilityControl();
	
EndProcedure

&AtServer
Function GetPeriodInWords(Number, NumerationItemOptions)
	
	PortionInWords = NumberInWords(Number,, NumerationItemOptions);
	
	PortionInWordsM = StrReplace(PortionInWords, " ", Chars.LF);
	
	Return StrGetLine(PortionInWordsM, StrLineCount(PortionInWordsM));
	
EndFunction

&AtServer
Procedure SaveSchedulingIntervalSetting()
	
	DateEmpty = '00010101';
	
	If Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		
		IntervalLength = 3600;
		
		Object.PlanningIntervalStart = ProductionPlanningClientServer.PlanningIntervalStart(DateEmpty, Object.PlanningInterval);
		Object.PlanningIntervalEnd = ProductionPlanningClientServer.PlanningIntervalEnd(DateEmpty, Object.PlanningInterval);
		
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		
		IntervalLength = 86400;
		
		Object.PlanningIntervalStart = ProductionPlanningClientServer.PlanningIntervalStart(DateEmpty, Object.PlanningInterval);
		Object.PlanningIntervalEnd = ProductionPlanningClientServer.PlanningIntervalEnd(DateEmpty, Object.PlanningInterval);
		
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Day
		Or Object.PlanningInterval = Enums.ProductionScheduleAccuracy.EmptyRef() Then
		
		IntervalLength = 86400;
		
		Object.PlanningIntervalStart = DateEmpty + Hour(TheBeginningOfThePlanningIntervalTheTimeOfDay) * 60 * 60 
															+ Minute(TheBeginningOfThePlanningIntervalTheTimeOfDay) * 60;
															
		Object.PlanningIntervalEnd = DateEmpty + Hour(TheEndOfThePlanningIntervalTheTimeOfDay) * 60 * 60 
																+ Minute(TheEndOfThePlanningIntervalTheTimeOfDay) * 60;
																
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		
		IntervalLength = 604800;
		
		Object.PlanningIntervalStart = DateEmpty + Enums.WeekDays.IndexOf(StartOfThePlanningIntervalDayOfTheWeek) * 86400
															+ Hour(TheBeginningOfThePlanningIntervalTheTimeOfDay) * 60 * 60 
																+ Minute(TheBeginningOfThePlanningIntervalTheTimeOfDay) * 60;
																
		Object.PlanningIntervalEnd = DateEmpty + Enums.WeekDays.IndexOf(EndOfThePlanningIntervalDayOfTheWeek) * 86400
																+ Hour(TheEndOfThePlanningIntervalTheTimeOfDay) * 60 * 60 
																	+ Minute(TheEndOfThePlanningIntervalTheTimeOfDay) * 60;
																	
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		
		IntervalLength = 2678400;
		
		Object.PlanningIntervalStart = ProductionPlanningClientServer.PlanningIntervalStart(DateEmpty, Object.PlanningInterval);
		Object.PlanningIntervalEnd = ProductionPlanningClientServer.PlanningIntervalEnd(DateEmpty, Object.PlanningInterval);
		
	EndIf;
	
	If Object.PlanningIntervalStart = Object.PlanningIntervalEnd Then
		
		Object.PlanningIntervalEnd = EndOfMinute(Object.PlanningIntervalEnd + IntervalLength - 60);
		
	ElsIf Object.PlanningIntervalStart > Object.PlanningIntervalEnd Then
		
		Object.PlanningIntervalEnd = EndOfMinute(Object.PlanningIntervalEnd + IntervalLength);
		
	Else
		
		Object.PlanningIntervalEnd = EndOfMinute(Object.PlanningIntervalEnd);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure InitializeSchedulingIntervalParameters(Reset = False)
	
	If Reset Then
		
		Object.PlanningIntervalStart = '00010101';
		Object.PlanningIntervalEnd = ProductionPlanningClientServer.PlanningIntervalEnd('00010101', Object.PlanningInterval);
		
	EndIf;
	
	If Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		
		Items.GroupSettingUpThePlanningInterval.Visible = True;
		Items.GroupSettingUpThePlanningInterval.CurrentPage = Items.GroupPlanningIntervalDay;
		
		TheBeginningOfThePlanningIntervalTheTimeOfDay    = Object.PlanningIntervalStart;
		TheEndOfThePlanningIntervalTheTimeOfDay = Object.PlanningIntervalEnd;
		
	ElsIf Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		
		Items.GroupSettingUpThePlanningInterval.Visible = True;
		Items.GroupSettingUpThePlanningInterval.CurrentPage = Items.GroupPlanningIntervalWeek;
		
		StartOfThePlanningIntervalDayOfTheWeek     = Enums.WeekDays[WeekDay(Object.PlanningIntervalStart) - 1];
		TheBeginningOfThePlanningIntervalTheTimeOfDay       = Object.PlanningIntervalStart;
		
		EndOfThePlanningIntervalDayOfTheWeek  = Enums.WeekDays[WeekDay(Object.PlanningIntervalEnd) - 1];
		TheEndOfThePlanningIntervalTheTimeOfDay    = Object.PlanningIntervalEnd;
		
	Else
		
		Items.GroupSettingUpThePlanningInterval.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureIntervalSelectionList()
	
	Items.PlanningInterval.ChoiceList.Clear();
	
	If UsePlanningIntervalHour
		Or Object.PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		Items.PlanningInterval.ChoiceList.Add(Enums.ProductionScheduleAccuracy.Hour);
	EndIf;
	
	If DynamicStructureOfProductionOrders
		And Object.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.Shifts Then
		Items.PlanningInterval.ChoiceList.Add(Enums.ProductionScheduleAccuracy.Shift);
	EndIf;
	
	Items.PlanningInterval.ChoiceList.Add(Enums.ProductionScheduleAccuracy.Day);
	Items.PlanningInterval.ChoiceList.Add(Enums.ProductionScheduleAccuracy.Week);
	Items.PlanningInterval.ChoiceList.Add(Enums.ProductionScheduleAccuracy.Month);
	
EndProcedure

&AtServer
Procedure SchedulingIntervalForChangesOnServer()
	
	SetTextHoursDaysMonthsWeeks();
	InitializeSchedulingIntervalParameters(True);
	
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
