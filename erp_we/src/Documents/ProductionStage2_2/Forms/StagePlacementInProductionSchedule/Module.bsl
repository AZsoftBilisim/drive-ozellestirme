
#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillInManualPlacementParameters(Parameters);
	FillInStoredValues(ThisObject);
	
	UpdateCompositionOfEmploymentColumns();
	FillEmploymentTypesOfWorkCenters();
	
	CustomizeFormElements();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	ProcessingOfEmploymentVerificationOfTypesOfWorkCenters(Cancel);
	
	HandlingRunTimeAndBusyIntervalChecks(Cancel);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Not ClosingInProgress And Not Exit Then
		
		Cancel = True;
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText       = NStr("vi = 'Biểu mẫu sẽ được đóng lại, tất cả dữ liệu đã nhập sẽ bị mất. Tiếp tục?';
								|ru = 'Форма будет закрыта, все введенные данные будут потеряны. Продолжить?';
								|en = 'Form will be closed, all entered data will be lost. Continue?'; fa = 'Form will be closed, all entered data will be lost. Continue?';
								|it = 'Il modulo sarà chiuso, tutti i dati inseriti andranno persi. Continuare?';
								|pl = 'Formularz zostanie zamknięty, wszystkie wprowadzone dane zostaną utracone. Kontynuować?';
								|tr = 'Form kapatılacak, girilen tüm veriler kaybolacaktır. Devam edilsin mi?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingPlacementParameters("Begin");
	
EndProcedure

&AtClient
Procedure EndingOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingPlacementParameters("Ending");
	
EndProcedure

&AtClient
Procedure StagePlacementInProductionScheduleClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	StagePlacementInProductionSchedule = True;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure HyperlinkPinToPreviousClick(Item)
	
	Begin = PressureParameters.LeftLimit;
	
	WhenChangingPlacementParameters("Begin");
	
EndProcedure

&AtClient
Procedure HyperlinkPressToNextClick(Item)
	
	Ending = PressureParameters.RightBorder_;
	
	WhenChangingPlacementParameters("Ending");
	
EndProcedure

&AtClient
Procedure HyperlinkToReFillTheExecutionPeriodClick(Item)
	
	NumberOfIntervals_ = DisplayedIntervals.Count();
	
	If NumberOfIntervals_ > 0 Then
		
		BeginOfPeriod = DisplayedIntervals[0].Value;
		PeriodEnding = DisplayedIntervals[NumberOfIntervals_-1].Value;
		
		FixStageExecutionPeriod(BeginOfPeriod, PeriodEnding);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkReFillBusyIntervalsClick(Item)
	
	CorrectOccupancyPeriods();
	
EndProcedure

&AtClient
Procedure HyperlinkDeviationsFromTheStandardClick(Item)
	
	Items.GroupOfDeviationsFromTheStandard.Visible      = True;
	Items.HyperlinkDeviationsFromTheStandard.Visible = False;
	
	DisplayDeviationsFromStandard();
	
EndProcedure

&AtClient
Procedure HyperlinkCloseDeviationsFromTheStandardClick(Item)
	
	Items.GroupOfDeviationsFromTheStandard.Visible = False;
	
	HideDeviationsFromStandard();
	
EndProcedure

&AtClient
Procedure GoToAvailabilityInputIndicatorClick(Item)
	
	BeginOfPeriod = BegOfDay(CommonClient.SessionDate());
	If DisplayedIntervals.Count() > 0 Then
		BeginOfPeriod = DisplayedIntervals[0].Value;
	EndIf;
	
	WorkCenterType = Undefined;
	If Items.OccupancyOfWorkCenterTypes.CurrentData <> Undefined Then
		WorkCenterType = Items.OccupancyOfWorkCenterTypes.CurrentData.WorkCenterType; 
	EndIf;
	
	WorkMode = PredefinedValue("Enum.ModesOfEditingTypeOfWorkCentersAvailability.EnterAvailabilityToGenerateProductionSchedule");
	
	FormParameters = New Structure;
	FormParameters.Insert("WorkCenterType", WorkCenterType);
	FormParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	FormParameters.Insert("WorkMode", WorkMode);
	
	OpenForm("DataProcessor.AvailabilityOfWorkCenterTypes.Form", FormParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkShowAdjacentStagesClick(Item)
	
	NameOfFormToOpen_ = "Report.ConnectedProductionStagesChart.ObjectForm";
	
	ScheduleStatus = StatusWorkingSchedule();
	
	FormParameters = New Structure;
	FormParameters.Insert("CommandParameter", Ref);
	FormParameters.Insert("ScheduleStatus", ScheduleStatus);
	
	OpenForm(
		NameOfFormToOpen_,
		FormParameters,
		ThisObject,
		Ref);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOccupancyOfWorkCenterTypes

&AtClient
Procedure OccupancyOfWorkCenterTypesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OccupancyOfWorkCenterTypesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	
	If NewRow Then
		
		CurrentData.BusyIndicator = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure OccupancyOfWorkCenterTypesOnEditEnd(Item, NewRow, CancelEdit)
	
	ProcessEndOfEditing();
	
EndProcedure

&AtClient
Procedure OccupancyOfWorkCenterTypesAfterDeleteRow(Item)
	
	ProcessEndOfEditing();
	
EndProcedure

&AtClient
Procedure EmploymentTypeOfWorkCenterOnChange(Item)
	
	CurrentData = Items.OccupancyOfWorkCenterTypes.CurrentData;
	
	ReferencesArrray = New Array;
	ReferencesArrray.Add(CurrentData.WorkCenterType);
	
	UpdateAvailabilityOfWorkCenterTypes(ReferencesArrray);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	ClearMessages();
	
	If CheckFilling() Then
		
		// Removal of modifiability, because before closing, the attribute is checked
		Modified = False;
		
		Result = New Structure;
		
		Result.Insert("StagePlacementInProductionSchedule", StagePlacementInProductionSchedule);
		Result.Insert("DataManualPlacementInGraph", ManualPlacementDataInGraph(ThisObject));
		Result.Insert("AddressOccupiedByStage", OccupiedByStageInStorage());
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateAvailabilityOfWorkCenterTypes();
	
EndProcedure

&AtClient
Procedure FillInOccupancy(Command)
	
	FillEmploymentTypesOfWorkCenters();
	ConfigureDependentFormElements(ThisObject, "OccupancyOfWorkCenterTypes");
	
EndProcedure

&AtClient
Procedure ClearOccupancy(Command)
	
	OccupancyOfWorkCenterTypes.Clear();
	ConfigureDependentFormElements(ThisObject, "OccupancyOfWorkCenterTypes");
	
EndProcedure

&AtClient
Procedure AddIntervalOnTheLeft(Command)
	
	AddInterval(-1);
	
EndProcedure

&AtClient
Procedure AddIntervalOnTheRight(Command)
	
	AddInterval(1);
	
EndProcedure

#EndRegion

#Region Private

#Region FormMaintenance

// Fills in the manual placement parameters
//
// Parameters:
//  Var_Parameters - Structure - Contains:
//               * Ref - DocumentRef.ProductionStage2_2 -
//
&AtServer
Procedure FillInManualPlacementParameters(Var_Parameters)
	
	// Stage data
	
	Ref = Var_Parameters.Ref;
	Status = Var_Parameters.Status;
	
	ReadOnly = (Status = StatusCompleted_1());
	
	ReferenceOrder  = Var_Parameters.ReferenceOrder;
	Department = Var_Parameters.Department;
	
	SetPrivilegedMode(True);
	DetailsOfDivision = Common.ObjectAttributesValues(
		Department, 
		"PlanningInterval,
		|PlanningIntervalStart,
		|PlanningIntervalEnd");
	SetPrivilegedMode(False);
	
	FillPropertyValues(ThisObject, DetailsOfDivision);
	
	// Production schedule
	
	StagePlacementInProductionSchedule = Var_Parameters.StagePlacementInProductionSchedule;
	
	Predecessors = Undefined;
	Successors   = Undefined;
	
	ReferencesArrray = Documents.ProductionStage2_2.AdjacentStages(Ref, Predecessors, Successors);
	ThereAreAdjacentStages = (ReferencesArrray.Count() > 0);
	
	If Var_Parameters.ProductionSchedule <> Undefined Then
		FillPropertyValues(ThisObject, Var_Parameters.ProductionSchedule);
	Else
		ReferencesArrray.Add(Ref);
	EndIf;
	
	ScheduleOfProductionStages = InformationRegisters.ScheduleOfProductionStages2_2.ProductionSchedule(ReferencesArrray);
	
	EndOfPrevious = '00010101';
	BeginningOfNext = '00010101';
	
	For Each Schedule In ScheduleOfProductionStages Do
		
		If Schedule.Stage <> Ref Then
			
			If Not Schedule.Calculated Then
				Continue;
			EndIf;
			
			If Predecessors.Find(Schedule.Stage) <> Undefined Then
				
				EndOfPrevious = Max(Schedule.Ending, EndOfPrevious);
				
			Else 
				
				If BeginningOfNext > '00010101' Then
					BeginningOfNext = Min(Schedule.Begin, BeginningOfNext);
				Else
					BeginningOfNext = Schedule.Begin;
				EndIf;
				
			EndIf;
			
		Else
			
			FillPropertyValues(ThisObject, Schedule);
			
		EndIf;
		
	EndDo;
	
	PressureParameters = PressureParameters();
	
	DetailsOfOrder = Common.ObjectAttributesValues(
		ReferenceOrder, "DemandDate, EarliestStartDate");
	
	If EndOfPrevious > '00010101' Then 
		
		PressureParameters.LeftLimit = EndOfPrevious + 1;
		PressureParameters.LeftBorderPattern = NStr("vi = 'nhấn để tiếp theo (%1)';
													|ru = 'прижать к предыдущему (%1)';
													|en = 'press to the previous one (%1)'; fa = 'press to the previous one (%1)';
													|it = 'stringere verso il precedente (%1)';
													|pl = 'docisnąć do poprzedniego (%1)';
													|tr = 'öncekine ekle (%1)'");
		
	ElsIf DetailsOfOrder.EarliestStartDate > CurrentSessionDate() Then
		
		PressureParameters.LeftLimit = DetailsOfOrder.EarliestStartDate;
		PressureParameters.LeftBorderPattern = NStr("vi = 'ghim để bắt đầu (%1)';
													|ru = 'прижать к началу (%1)';
													|en = 'press to start (%1)'; fa = 'press to start (%1)';
													|it = 'stringere verso l''alto (%1)';
													|pl = 'docisnąć do początku (%1)';
													|tr = 'başlangıca ekle (%1)'");
		
	EndIf;
	
	If BeginningOfNext > '00010101' Then
		
		PressureParameters.RightBorder_ = BeginningOfNext - 1;
		PressureParameters.TemplateRightBorder = NStr("vi = 'nhấn để tiếp theo (%1)';
														|ru = 'прижать к следующему (%1)';
														|en = 'press to the next one (%1)'; fa = 'press to the next one (%1)';
														|it = 'stringere verso il successivo (%1)';
														|pl = 'docisnąć do następnego (%1)';
														|tr = 'sonrakine ekle (%1)'");
		
	ElsIf DetailsOfOrder.DemandDate > CurrentSessionDate()
			And DetailsOfOrder.DemandDate > EndOfPrevious Then
		
		PressureParameters.RightBorder_ = DetailsOfOrder.DemandDate;
		PressureParameters.TemplateRightBorder = NStr("vi = 'ghim đến ngày cần (%1)';
														|ru = 'прижать к дате потребности (%1)';
														|en = 'press to the demand date (%1)'; fa = 'press to the demand date (%1)';
														|it = 'stringere verso la data di fabbisogno (%1)';
														|pl = 'docisnąć do daty zapotrzebowania (%1)';
														|tr = 'gereksinim tarihine ekle (%1)'");
		
	EndIf;
	
	// Standards
	
	If IsTempStorageURL(Var_Parameters.AddressStandards) Then
		
		StandardsFromRepository = GetFromTempStorage(Var_Parameters.AddressStandards); // ValueTable - 
		
		TypeDetails = Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative);
		StandardsFromRepository.Columns.Add("Count", TypeDetails);
		
		For Each String In StandardsFromRepository Do
			
			String.Count = ProductionPlanningClientServer.GetTimeInSeconds(
				String.OperationTime, String.UnitOfMeasure)/3600;
			
		EndDo;
		
		StandardsFromRepository.GroupBy("WorkCenterType", "Count");
		
		Standards.Load(StandardsFromRepository);
		
	EndIf;
	
	// Employment of types of work centers
	
	AddressEmploymentStructure = Var_Parameters.AddressEmploymentStructure;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// text "General availability"
#Region TextGeneralAvailability
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.EmploymentAvailabilityIndicator.Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Sẵn có chung';
													|ru = 'Общая доступность';
													|en = 'Total availability'; fa = 'Total availability';
													|it = 'Disponibilità generale';
													|pl = 'Ogólna dostępność';
													|tr = 'Genel kullanılabilirlik'"));
	
#EndRegion

	// text "Freely"
#Region TextFreely
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.EmploymentIndicatorIsFree.Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Vị trí trống';
													|ru = 'Свободно';
													|en = 'Available'; fa = 'در دسترس';
													|it = 'Libero';
													|pl = 'Available';
													|tr = 'Boş'"));
	
#EndRegion

	// the text "Occupy"
#Region TextToOccupy
	
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.EmploymentBusyIndicator.Name);
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Chiếm';
													|ru = 'Занять';
													|en = 'Reserve'; fa = 'رزرو';
													|it = 'Occupato';
													|pl = 'Reserve';
													|tr = 'Meşgul'"));
	
#EndRegion

	// color highlighting excess occupancy
#Region ExcessEmployment

	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.EmploymentTotalEmployed.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("OccupancyOfWorkCenterTypes.TotalFree");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = New DataCompositionField("OccupancyOfWorkCenterTypes.TotalOccupied");
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
#EndRegion
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	FillPropertyValues(ThisObject, SubsystemSettingsProduction);
	
	Items.Begin.EditFormat = ScheduleDateFormat;
	Items.Ending.EditFormat = ScheduleDateFormat;
	
	Items.ProductionResourcePlanningGroup.Visible = PlanningByProductionResourcesIsUsed;
	
	If PressureParameters.LeftLimit <> '00010101' Then
		
		Items.HyperlinkPinToPrevious.Title = StrTemplate(PressureParameters.LeftBorderPattern, 
			Format(PressureParameters.LeftLimit, ScheduleDateFormat));
		
	EndIf;
	
	If PressureParameters.RightBorder_ <> '00010101' Then
		
		Items.HyperlinkPressToNext.Title = StrTemplate(PressureParameters.TemplateRightBorder, 
			Format(PressureParameters.RightBorder_, ScheduleDateFormat));
		
	EndIf;
	
	Items.HyperlinkShowAdjacentStages.Visible = ThereAreAdjacentStages;
	
	UpdateDeviationHyperlink();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	// Start and end of the stage
	If AttributesStructure1.Property("StagePlacementInProductionSchedule") Or Initialize Then
		
		If Form.StagePlacementInProductionSchedule Then
			Items.Begin.TextColor = WebColors.Black;
			Items.Ending.TextColor = WebColors.Black;
		Else
			Items.Begin.TextColor = WebColors.Gray;
			Items.Ending.TextColor = WebColors.Gray;
		EndIf;
		
	EndIf;
	
	// Manual placement in the chart
	If AttributesStructure1.Property("StagePlacementInProductionSchedule") Or Initialize Then
		
		Items.StagePlacementInProductionSchedule.Visible = 
			Not Form.StagePlacementInProductionSchedule And Not Form.ReadOnly;
	
	EndIf;
	
	// Press to the previous one
	If AttributesStructure1.Property("Begin") Or Initialize Then
		
		Items.HyperlinkPinToPrevious.Visible =
			Form.PressureParameters.LeftLimit > '00010101'
			And Form.Begin <> Form.PressureParameters.LeftLimit
			And Not Form.ReadOnly;
		
	EndIf;
	
	// Press to the next
	If AttributesStructure1.Property("Ending") Or Initialize Then
		
		Items.HyperlinkPressToNext.Visible = 
			Form.PressureParameters.RightBorder_ > '00010101'
			And Form.Ending <> Form.PressureParameters.RightBorder_
			And Not Form.ReadOnly;
		
	EndIf;
	
	// Planning for production resources
	If AttributesStructure1.Property("StagePlacementInProductionSchedule") Or Initialize Then
		
		Items.ProductionResourcePlanningGroup.Enabled = Form.StagePlacementInProductionSchedule;
		
	EndIf;
	
	// Re-filling intervals
	If AttributesStructure1.Property("Begin")
		Or AttributesStructure1.Property("Ending")
		Or AttributesStructure1.Property("OccupancyOfWorkCenterTypes") Then
		
		ErrorCode = CheckExecutionPeriodAndBusyIntervals(Form);
		
		Items.TheGroupNeedsToBeReFilledWithEmployment.Visible    = (ErrorCode > 0);
		Items.HyperlinkToReFillTheExecutionPeriod.Visible = (ErrorCode > 0) And Form.DisplayedIntervals.Count() > 0;
		
		If ErrorCode > 0 Then
			If ErrorCode = ErrorCodeDoesNotGoBeyondBoundariesOfStage() Then
				Items.GroupErrorTextNeedsToBeRefilledBusy.CurrentPage = Items.TheEmploymentGroupGoesBeyondTheBoundariesOfTheStage;
			Else
				Items.GroupErrorTextNeedsToBeRefilledBusy.CurrentPage = Items.TheExecutionPeriodGroupDoesNotMatchTheIntervals;
			EndIf;
		EndIf;
		
	EndIf;
	
	// Deviations from the standards 
	If AttributesStructure1.Property("ThereAreAdjacentStages") Or Initialize Then
		
		Items.HyperlinkShowAdjacentStages.Visible = Form.ThereAreAdjacentStages;
		
	EndIf;
	
	// Modified
	If AttributesStructure1.Property("Begin")
		Or AttributesStructure1.Property("Ending")
		Or AttributesStructure1.Property("StagePlacementInProductionSchedule")
		Or AttributesStructure1.Property("OccupancyOfWorkCenterTypes") Then
		
		Form.Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StoredValues

&AtClientAtServerNoContext
Procedure FillInStoredValues(Form)
	
	AttributesNames = AttributesToSaveNames();
	
	Form.StoredValues = New Structure(AttributesNames);
	
	FillPropertyValues(Form.StoredValues, Form, AttributesNames);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RestoreSavedValues(Form)
	
	AttributesNames = AttributesToSaveNames();
	
	If Form.StoredValues <> Undefined Then
		FillingValues = Form.StoredValues;
	Else
		FillingValues = New Structure(AttributesNames);
	EndIf;
	
	FillPropertyValues(Form, FillingValues, AttributesNames);
	
EndProcedure

&AtClientAtServerNoContext
Function SavedValueChanged(Form, AttributeName, Value)
	
	Return Form.StoredValues = Undefined
			 Or Form.StoredValues[AttributeName] <> Value;
	
EndFunction

&AtClientAtServerNoContext
Function AttributesToSaveNames()
	
	Result = 
		"Begin,
		|Ending,
		|StagePlacementInProductionSchedule";
		
	Return Result;
	
EndFunction

#EndRegion

#Region StagePlacementInProductionSchedule

#Region ExecutionPeriod

&AtClient
Procedure WhenChangingPlacementParameters(Var_AttributeName)
	
	If SavedValueChanged(ThisObject, Var_AttributeName, ThisObject[Var_AttributeName]) Then
		
		WhenYouChangePlacementSettingsOnServer(Var_AttributeName);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenYouChangePlacementSettingsOnServer(Var_AttributeName)
	
	ChangedBankingDetails = Var_AttributeName;
	If Not StagePlacementInProductionSchedule Then
		StagePlacementInProductionSchedule = True;
		ChangedBankingDetails = ChangedBankingDetails + ",StagePlacementInProductionSchedule";
	EndIf;

	If Not CalculateStageBoundaries(Var_AttributeName) Then
		
		MessageText = NStr("vi = 'Không thể tính ranh giới kỳ.';
							|ru = 'Не удалось рассчитать границы этапа.';
							|en = 'Cannot calculate the stage limits.'; fa = 'Cannot calculate the stage limits.';
							|it = 'Non è stato possibile valutare i limiti della fase.';
							|pl = 'Nie udało się obliczyć granic etapu';
							|tr = 'Aşama sınırları hesaplanamadı.'");
		
		CommonClientServer.MessageToUser(MessageText,, Var_AttributeName);
		
		RestoreSavedValues(ThisObject);
		
		Return;
		
	EndIf;
	
	FillInStoredValues(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FixStageExecutionPeriod(BeginOfPeriod, PeriodEnding)
	
	If Not CalculateExecutionPeriod(BeginOfPeriod, PeriodEnding) Then
		
		MessageText = NStr("vi = 'Không thể tính ranh giới kỳ.';
							|ru = 'Не удалось рассчитать границы этапа.';
							|en = 'Cannot calculate the stage limits.'; fa = 'Cannot calculate the stage limits.';
							|it = 'Non è stato possibile valutare i limiti della fase.';
							|pl = 'Nie udało się obliczyć granic etapu';
							|tr = 'Aşama sınırları hesaplanamadı.'");
		
		CommonClientServer.MessageToUser(MessageText);
		
		RestoreSavedValues(ThisObject);
		
		Return;
		
	EndIf;
	
	FillInStoredValues(ThisObject);
	
	ConfigureDependentFormElements(ThisObject, "Begin, Ending");
	
EndProcedure

&AtServer
Procedure CorrectOccupancyPeriods()
	
	UpdateCompositionOfEmploymentColumns();
	
	UpdateAvailabilityOfWorkCenterTypes();
	
	CalculateTotals_2();
	
	ConfigureDependentFormElements(ThisObject, "OccupancyOfWorkCenterTypes");

EndProcedure

&AtServer
Function CalculateStageBoundaries(Var_AttributeName)
	
	If Begin > Ending Then 
		If PlacementDirection(Var_AttributeName) > 0 Then
			Ending = Begin;
		Else
			Begin = Ending;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function CalculateExecutionPeriod(LeftLimit = '00010101', RightBorder_ = '00010101')
	
	If LeftLimit <> '00010101' Then
		
		Begin = ProductionPlanningClientServer.PlanningIntervalStart(
			LeftLimit, PlanningInterval, PlanningIntervalStart);
			
	EndIf;
	
	If RightBorder_ <> '00010101' Then
		
		Ending = ProductionPlanningClientServer.PlanningIntervalEnd(
			RightBorder_, PlanningInterval, PlanningIntervalEnd);
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region OccupancyOfWorkCenterTypes

#Region FillType

&AtServer
Procedure UpdateCompositionOfEmploymentColumns()
	
	AddedIntervals = New Array;
	DeletedIntervals = New Array;
	
	PeriodIntervals = IntervalsFromExecutionPeriod(Begin,
													Ending,
													PlanningInterval,
													Department);
	
	// New intervals.
	For Each Interval In PeriodIntervals Do
		
		If DisplayedIntervals.FindByValue(Interval) <> Undefined Then
			Continue;
		EndIf;
		
		AddedIntervals.Add(Interval);
		
	EndDo;
	
	// Intervals to delete.
	For Each DisplayedInterval In DisplayedIntervals Do
		
		Interval = DisplayedInterval.Value;
		
		If PeriodIntervals.Find(Interval) <> Undefined Then
			Continue;
		EndIf;
		
		DeletedIntervals.Add(Interval);
		
	EndDo;
	
	ChangeCompositionOfEmploymentColumns(AddedIntervals, DeletedIntervals);
	
EndProcedure

&AtServer
Procedure ChangeCompositionOfEmploymentColumns(AddedIntervals = Undefined, DeletedIntervals = Undefined)
	
	AttributesToBeAdded = New Array;
	AttributesToBeDeleted = New Array;
	
	DataPath = "OccupancyOfWorkCenterTypes";
	
	DescriptionOfColumnGroupInterval = DescriptionOfColumnGroupInterval();
	
	// Details to add.
	If AddedIntervals <> Undefined Then
			
		For Each Interval In AddedIntervals Do
			
			ColumnNameInterval = ColumnNameInterval(Interval);
			
			For Each ColumnDetails In DescriptionOfColumnGroupInterval Do
				
				ColumnName = ColumnNameInterval + ColumnDetails.Name;
				
				NewColumn = New FormAttribute(
						ColumnName, ColumnDetails.Type, DataPath);
				
				AttributesToBeAdded.Add(NewColumn);
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
	// Details for deletion.
	If DeletedIntervals <> Undefined Then
		
		For Each Interval In DeletedIntervals Do
			
			ColumnNameInterval = ColumnNameInterval(Interval);
			
			For Each ColumnDetails In DescriptionOfColumnGroupInterval Do
				
				ColumnName = ColumnNameInterval + ColumnDetails.Name;
				
				AttributesToBeDeleted.Add(DataPath + "." + ColumnName);
				
				Items.Delete(Items.Find(ColumnName));
				
			EndDo;
			
			Items.Delete(Items.Find(ColumnNameInterval + GroupNameInterval()));
			
			DisplayedIntervals.Delete(DisplayedIntervals.FindByValue(Interval));
			
		EndDo;
	
	EndIf;
	
	// We delete and add the details of the form.
	If AttributesToBeAdded.Count() > 0 Or AttributesToBeDeleted.Count() > 0 Then
		
		ChangeAttributes(AttributesToBeAdded, AttributesToBeDeleted);
		
	EndIf;
	
	NumberOfIntervals_ = DisplayedIntervals.Count();
	OrderedInsertIsRequired = NumberOfIntervals_ > 0;
	
	// We add form elements, if there are none yet.
	For Each Interval In AddedIntervals Do
		
		ColumnNameInterval = ColumnNameInterval(Interval);
		
		If OrderedInsertIsRequired Then
			
			If Interval < DisplayedIntervals[0].Value Then
				IndexOf = 0;
			ElsIf Interval > DisplayedIntervals[NumberOfIntervals_-1].Value Then
				IndexOf = NumberOfIntervals_;
			Else
				IndexOf = 0;
				For Each DisplayedInterval In DisplayedIntervals Do
					If Interval < DisplayedInterval.Value Then
						Break;
					EndIf;
					IndexOf = IndexOf + 1;
				EndDo;
			EndIf;
			DisplayedIntervals.Insert(IndexOf, Interval, ColumnNameInterval);
			
		Else
			
			DisplayedIntervals.Add(Interval, ColumnNameInterval);
			
		EndIf;
		
		NumberOfIntervals_ = NumberOfIntervals_ + 1;
		
		// Find the column before which you need to add a new one
		InsertionBoundary = Items.EmploymentRightBorder;
		
		For Each CurrentColumn In Items.OccupancyOfWorkCenterTypes.ChildItems Do
			
			If StrFind(CurrentColumn.Name, GroupNameInterval()) = 0 Then
				Continue;
			EndIf;
			
			CurrentInterval = SpacingFromColumnName(CurrentColumn.Name);
			If CurrentInterval > Interval Then
				InsertionBoundary = CurrentColumn;
				Break;
			EndIf;
			
		EndDo;
		
		// Let's add a group in which new elements will be placed
		
		ColumnGroupInterval = Items.Insert(
			ColumnNameInterval + GroupNameInterval(), 
			Type("FormGroup"), 
			Items.OccupancyOfWorkCenterTypes, 
			InsertionBoundary);
		
		ColumnGroupInterval.Title = ColumnHeaderInterval(Interval);
		ColumnGroupInterval.ShowInHeader    = True;
		ColumnGroupInterval.ShowTitle = True;
		ColumnGroupInterval.Group = ColumnsGroup.Vertical;
		
		// Adding elements
		For Each ColumnDetails In DescriptionOfColumnGroupInterval Do
			
			NameOfNewElement = ColumnNameInterval + ColumnDetails.Name;
			
			NewItem = Items.Add(
					NameOfNewElement, 
					Type("FormField"), 
					ColumnGroupInterval);
			
			NewItem.Type    = ColumnDetails.Kind;
			NewItem.Format = ColumnDetails.Format;
			NewItem.Width = ColumnDetails.Width;
			
			NewItem.DataPath = DataPath + "." + NameOfNewElement;
			NewItem.ShowInHeader = False;
			
		EndDo; 
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddInterval(Direction = 1)
	
	AddedIntervals = New Array;
	DeletedIntervals   = New Array;
	NumberOfIntervals_ = DisplayedIntervals.Count();
	
	If NumberOfIntervals_ = 0 Then
		
		StartIndex = 0;
		TheEndIndex  = -1;
		
		IntervalEndpoint = CurrentSessionDate();
		
	ElsIf Direction > 0 Then 
		
		StartIndex = 0;
		TheEndIndex  = NumberOfIntervals_-1;
		
		IntervalEndpoint = DisplayedIntervals[NumberOfIntervals_-1].Value;
		
	Else
		
		StartIndex = -NumberOfIntervals_+1;
		TheEndIndex  = 0;
		
		IntervalEndpoint = DisplayedIntervals[0].Value;
		
	EndIf;
	
	If Direction > 0 Then
		
		NewInterval = ProductionPlanningClientServer.NextSchedulingInterval(
			IntervalEndpoint+1, PlanningInterval);
		
		AddedIntervals.Add(NewInterval);
		
	Else
		
		NewInterval = ProductionPlanningClientServer.PreviousSchedulingInterval(
			IntervalEndpoint, PlanningInterval);
		
		NewInterval = ProductionPlanningClientServer.PlanningIntervalStart(
			NewInterval, PlanningInterval);
		
		AddedIntervals.Add(NewInterval);
		
	EndIf;
	
	For IndexOf = StartIndex To TheEndIndex Do
		
		DisplayedInterval = DisplayedIntervals[Max(IndexOf, -IndexOf)];
		
		Interval = DisplayedInterval.Value;
		ColumnNameOccupied = DisplayedInterval.Presentation + FieldNameOccupied();
		
		IntervalBusy = False;
		For Each VRCString In OccupancyOfWorkCenterTypes Do
			If VRCString[ColumnNameOccupied] > 0 Then
				IntervalBusy = True;
				Break;
			EndIf;
		EndDo;
		
		If IntervalBusy Then
			Break;
		EndIf;
		
		DeletedIntervals.Add(Interval);
		
	EndDo;
	
	ChangeCompositionOfEmploymentColumns(AddedIntervals, DeletedIntervals);
	
	UpdateAvailabilityOfWorkCenterTypes(, AddedIntervals);
	
	ConfigureDependentFormElements(ThisObject, "OccupancyOfWorkCenterTypes");
	
EndProcedure

&AtServer
Procedure FillEmploymentTypesOfWorkCenters()
	
	OccupancyOfWorkCenterTypes.Clear();
	
	If DisplayedIntervals.Count() = 0 Then
		Return;
	EndIf;
	
	If Not IsTempStorageURL(AddressEmploymentStructure) Then
		Return;
	EndIf;
	
	EmploymentStructure = GetFromTempStorage(AddressEmploymentStructure);
	
	If EmploymentStructure.VRCArray.UBound() <> -1 Then
		
		FieldNameOccupied = FieldNameOccupied();
		FieldNameIsFree = FieldNameIsFree();
		AvailabilityFieldName = AvailabilityFieldName();
		
		FilterParameters = New Structure("WorkCenterType, IntervalDate");
		
		BusyStage = EmploymentStructure.BusyStage;
		
		AvailableInInterval = ReadAvailabilityOfTypesOfWorkCenters(
					EmploymentStructure.VRCArray);
		
		For Each WorkCenterType In EmploymentStructure.VRCArray Do
			
			FilterParameters.WorkCenterType = WorkCenterType;
			
			NewRow = OccupancyOfWorkCenterTypes.Add();
			NewRow.WorkCenterType = WorkCenterType;
			NewRow.BusyIndicator   = True;
			
			TotalOccupied = 0;
			TotalFree = 0;
			TotalAvailability = 0;
			
			For Each DisplayedInterval In DisplayedIntervals Do
		
				Interval = DisplayedInterval.Value;
				
				ColumnNameOccupied = DisplayedInterval.Presentation + FieldNameOccupied;
				ColumnNameIsFree = DisplayedInterval.Presentation + FieldNameIsFree;
				ColumnNameAvailability = DisplayedInterval.Presentation + AvailabilityFieldName;
				
				FilterParameters.IntervalDate = Interval;
				
				For Each String In BusyStage.FindRows(FilterParameters) Do
					
					NewRow[ColumnNameOccupied] = String.Count/3600;
					TotalOccupied = TotalOccupied + String.Count/3600;
					
					Break;
					
				EndDo;
				
				For Each String In AvailableInInterval.FindRows(FilterParameters) Do
					
					NewRow[ColumnNameIsFree] = String.AvailableForInventoryAllocation/3600;
					TotalFree = TotalFree + String.AvailableForInventoryAllocation/3600;
					
					NewRow[ColumnNameAvailability] = String.Enabled/3600;
					TotalAvailability = TotalAvailability + String.Enabled/3600;
					
					Break;
					
				EndDo;
				
			EndDo;
			
			NewRow.TotalOccupied = TotalOccupied;
			NewRow.TotalFree = TotalFree;
			NewRow.TotalAvailability = TotalAvailability;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAvailabilityOfWorkCenterTypes(VRCArray = Undefined, Intervals = Undefined)
	
	If VRCArray = Undefined Then
		VRCArray = DisplayedViewsOfWorkCenters();
	EndIf;
	
	If Intervals = Undefined Then
		Intervals = DisplayedIntervals.UnloadValues();
	EndIf;
	
	FieldNameIsFree = FieldNameIsFree();
	AvailabilityFieldName = AvailabilityFieldName();
	
	FilterParameters = New Structure("WorkCenterType, IntervalDate");
	
	AvailableInInterval = ReadAvailabilityOfTypesOfWorkCenters(VRCArray, Intervals);
	
	For Each VRCString In OccupancyOfWorkCenterTypes Do
		
		If VRCArray.Find(VRCString.WorkCenterType) = Undefined Then
			Continue;
		EndIf;
		
		TotalFree = 0;
		TotalAvailability = 0;
		
		FilterParameters.WorkCenterType = VRCString.WorkCenterType;
		
		For Each DisplayedInterval In DisplayedIntervals Do
			
			ColumnNameIsFree = DisplayedInterval.Presentation + FieldNameIsFree;
			ColumnNameAvailability = DisplayedInterval.Presentation + AvailabilityFieldName;
			
			If Intervals.Find(DisplayedInterval.Value) <> Undefined Then
				
				FilterParameters.IntervalDate = DisplayedInterval.Value;
				
				VRCString[ColumnNameIsFree] = 0;
				VRCString[ColumnNameAvailability] = 0;
				
				For Each String In AvailableInInterval.FindRows(FilterParameters) Do
					
					VRCString[ColumnNameIsFree] = String.AvailableForInventoryAllocation/3600;
					VRCString[ColumnNameAvailability] = String.Enabled/3600;
					Break;
					
				EndDo;
				
			EndIf;
			
			TotalFree = TotalFree + VRCString[ColumnNameIsFree];
			TotalAvailability = TotalAvailability + VRCString[ColumnNameAvailability];
			
		EndDo;
		
		VRCString.TotalFree = TotalFree;
		VRCString.TotalAvailability = TotalAvailability;
		
	EndDo;
	
EndProcedure

&AtServer
Function ReadAvailabilityOfTypesOfWorkCenters(VRCArray = Undefined, Intervals = Undefined)
	
	If VRCArray = Undefined Then
		VRCArray = DisplayedViewsOfWorkCenters();
	EndIf;
	
	If Intervals = Undefined Then
		Intervals = DisplayedIntervals.UnloadValues();
	EndIf;
	
	NumberOfIntervals_ = Intervals.Count();
	If NumberOfIntervals_ = 0 Or VRCArray.Count() = 0 Then
		Return EmptyAvailabilityTable();
	EndIf;
	
	BeginOfPeriod = Intervals[0];
	PeriodEnding = Intervals[NumberOfIntervals_-1];
	
	PlanningParameters = DataProcessors.ProductionSchedulePlanning2_2.SchedulePlanningOptions();
	
	DataProcessors.ProductionSchedulePlanning2_2.ReadUpdateOrderDetails(
		PlanningParameters, ReferenceOrder, False);
	
	ArrayOfStages = New Array;
	ArrayOfStages.Add(Ref);
	
	TempTablesManager = New TempTablesManager;
	
	DataProcessors.ProductionSchedulePlanning2_2.CreateTTAvailabilityOfRCTypes(
				TempTablesManager,
				"TTAvailability",
				VRCArray,
				ArrayOfStages,
				BeginOfPeriod,
				PeriodEnding,
				PlanningParameters);
	
	Query = New Query(
		"SELECT
		|	Table.Performer               AS WorkCenterType,
		|	Table.IntervalDate             AS IntervalDate,
		|	SUM(Table.CountReceipt)   AS Enabled,
		|	SUM(Table.CountReceipt
		|		- Table.CountExpense)   AS AvailableForInventoryAllocation
		|FROM
		|	TTAvailability AS Table
		|
		|GROUP BY
		|	Table.Performer,
		|	Table.IntervalDate
		|
		|HAVING
		|	SUM(Table.CountReceipt) > 0");
		
	Query.TempTablesManager = TempTablesManager;
	
	AvailabilityTable = Query.Execute().Unload();
	AvailabilityTable.Indexes.Add("WorkCenterType, IntervalDate");
	
	Return AvailabilityTable;
	
EndFunction

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function FieldNameOccupied()
	
	Return "Busy";
	
EndFunction

&AtClientAtServerNoContext
Function FieldNameIsFree()
	
	Return "AvailableForInventoryAllocation";
	
EndFunction

&AtClientAtServerNoContext
Function AvailabilityFieldName()
	
	Return "Enabled";
	
EndFunction

&AtClientAtServerNoContext
Function GroupNameInterval()
	
	Return "IntervalGroup";
	
EndFunction

&AtServerNoContext
Function IntervalsFromExecutionPeriod(Val StageStart, Val StageEnd, Val PlanningInterval, Department)
	
	PeriodIntervals = New Array;
	
	If StageStart = '000101010000' Or StageEnd = '000101010000' Then
		Return PeriodIntervals;
	EndIf;
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		
		PeriodIntervals = ShiftsForPeriod(StageStart, StageEnd, Department);
		
	Else
		
		PeriodBoundary = ProductionPlanningClientServer.PlanningIntervalStart(
																	StageStart,
																	PlanningInterval);
		
		While PeriodBoundary <= StageEnd Do
			
			PeriodIntervals.Add(PeriodBoundary);
			
			PeriodBoundary = ProductionPlanningClientServer.NextSchedulingInterval(
																	PeriodBoundary+1, 
																	PlanningInterval);
		EndDo;
		
	EndIf;
	
	Return PeriodIntervals;
	
EndFunction

&AtServerNoContext
Function ShiftsForPeriod(Begin, Ending, Department)
	
	Schedules = ProductionServer.DivisionWorkSchedules(Department).UnloadColumn("WorkScheduleCalendar");
	
	TempTablesManager = New TempTablesManager;
	CalendarSchedules.CreateTTWorkSchedulesForPeriod(
		TempTablesManager, Schedules, BegOfDay(Begin), Ending, False);
	
	Query = New Query(
		"SELECT
		|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
		|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
		|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) AS Begin
		|FROM
		|	TTWorkSchedules AS Schedule
		|
		|GROUP BY
		|	Schedule.WorkScheduleCalendar,
		|	Schedule.Period
		|
		|HAVING
		|	MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
		|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
		|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) >= &Begin
		|	AND MIN(DATEADD(Schedule.ScheduleDate, MINUTE,
		|		HOUR(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1)))*60
		|		+ MINUTE(ISNULL(Schedule.BeginTime, DATETIME(1, 1, 1))))) < &Ending
		|
		|ORDER BY
		|	Begin");
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Begin", Begin);
	Query.SetParameter("Ending", Ending);
	
	Return Query.Execute().Unload().UnloadColumn("Begin");
	
EndFunction

&AtClientAtServerNoContext
Function ColumnNameInterval(Interval)

	Return "_K" + Format(Interval, "DF=yyyyMMddHHmm");

EndFunction

&AtClientAtServerNoContext
Function SpacingFromColumnName(ColumnName)

	Return Date(Mid(ColumnName,3,12));

EndFunction

&AtServer
Function ColumnHeaderInterval(Interval)
	
	Return ProductionAccounting.LineSchedulingInterval(Interval, PlanningInterval);
	
EndFunction

&AtServerNoContext
Function AddColumnDescription(ColumnsList, Name, Type)
	
	ColumnDetails = New Structure( 
			"Name,
			|Type,
			|Kind,
			|Format,
			|Width");
	
	ColumnDetails.Name = Name;
	ColumnDetails.Type = Type;
	
	ColumnsList.Add(ColumnDetails);
	
	Return ColumnDetails;
	
EndFunction

// Returns a description of the column group interval
//
// Returns:
//  Array of Structure - Contains:
//             * Name - String - 
//             * Type - Type -
//             * Kind - FormFieldType -
//             * Format - String - 
//             * Width - Number - 
//
&AtServerNoContext
Function DescriptionOfColumnGroupInterval()
	
	Result = New Array;
	
	TypeOfWatch = New TypeDescription("Number", New NumberQualifiers(10, 2, AllowedSign.Nonnegative));
	
	NewColumn = AddColumnDescription(Result, AvailabilityFieldName(), TypeOfWatch);
	NewColumn.Kind = FormFieldType.LabelField;
	NewColumn.Format = "NFD=2; NZ='0'";
	NewColumn.Width = 14;
	
	NewColumn = AddColumnDescription(Result, FieldNameIsFree(), TypeOfWatch);
	NewColumn.Kind = FormFieldType.LabelField;
	NewColumn.Format = "NFD=2; NZ='0'";
	NewColumn.Width = 14;
	
	NewColumn = AddColumnDescription(Result, FieldNameOccupied(), TypeOfWatch);
	NewColumn.Kind = FormFieldType.InputField;
	NewColumn.Format = "";
	NewColumn.Width = 14;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function EmptyEmploymentTable()
	
	Table = New ValueTable;
	
	Table.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	Table.Columns.Add("IntervalDate", New TypeDescription("Date"));
	Table.Columns.Add("Count");

	Return Table;
	
EndFunction

&AtServerNoContext
Function EmptyAvailabilityTable()
	
	Table = New ValueTable;
	
	Table.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	Table.Columns.Add("IntervalDate", New TypeDescription("Date"));
	Table.Columns.Add("Enabled");
	Table.Columns.Add("AvailableForInventoryAllocation");

	Return Table;
	
EndFunction

&AtClientAtServerNoContext
Procedure CalculateTotalsByLine(String, DisplayedIntervals)
	
	AvailabilityFieldName = AvailabilityFieldName();
	FieldNameIsFree = FieldNameIsFree();
	FieldNameOccupied = FieldNameOccupied();
	
	TotalAvailability = 0;
	TotalFree = 0;
	TotalOccupied = 0;
	
	For Each DisplayedInterval In DisplayedIntervals Do
		
		TotalOccupied = TotalOccupied + String[DisplayedInterval.Presentation + FieldNameOccupied];
		TotalFree = TotalFree + String[DisplayedInterval.Presentation + FieldNameIsFree];
		TotalAvailability = TotalAvailability + String[DisplayedInterval.Presentation + AvailabilityFieldName];
		
	EndDo;
	
	String.TotalOccupied = TotalOccupied;
	String.TotalFree = TotalFree;
	String.TotalAvailability = TotalAvailability;
	
EndProcedure

&AtServer
Procedure CalculateTotals_2()
	
	For Each String In OccupancyOfWorkCenterTypes Do
		CalculateTotalsByLine(String, DisplayedIntervals);
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessEndOfEditing()
	
	Id = Items.OccupancyOfWorkCenterTypes.CurrentRow;
	
	If Id <> Undefined Then
		
		CurrentRow = OccupancyOfWorkCenterTypes.FindByID(Id);
		CalculateTotalsByLine(CurrentRow, DisplayedIntervals);
		
	EndIf;
	
	If Items.GroupOfDeviationsFromTheStandard.Visible Then
		
		DisplayDeviationsFromStandard();
		
	Else
		
		UpdateDeviationHyperlink();
		
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "OccupancyOfWorkCenterTypes");
	
EndProcedure

&AtServer
Function DisplayedViewsOfWorkCenters()
	
	Return TMCommonUse.UnloadColumnValues(OccupancyOfWorkCenterTypes, "WorkCenterType");
	
EndFunction

#EndRegion

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function CheckExecutionPeriodAndBusyIntervals(Form)
	
	If Not Form.StagePlacementInProductionSchedule
		Or Form.OccupancyOfWorkCenterTypes.Count() = 0
		Then
		Return 0;
	EndIf;
	
	PeriodIntervals = IntervalsFromExecutionPeriod(
									Form.Begin,
									Form.Ending,
									Form.PlanningInterval,
									Form.Department);
	
	DisplayedIntervals = Form.DisplayedIntervals.UnloadValues();
	
	For Each Interval In DisplayedIntervals Do
		
		If PeriodIntervals.Find(Interval) <> Undefined Then
			Continue;
		EndIf;
		
		Return ErrorCodeDoesNotGoBeyondBoundariesOfStage();
		
	EndDo;
	
	For Each Interval In PeriodIntervals Do
		
		If DisplayedIntervals.Find(Interval) <> Undefined Then
			Continue;
		EndIf;
		
		Return ErrorCodeExecutionPeriodDoesNotMatchIntervals();
		
	EndDo;
	
	Return 0;
	
EndFunction

&AtServer
Function OccupiedByStageInStorage()
	
	FieldNameOccupied = FieldNameOccupied();
	EmploymentTable = EmptyEmploymentTable();
	
	For Each String In OccupancyOfWorkCenterTypes Do
		
		For Each DisplayedInterval In DisplayedIntervals Do
			
			If String[DisplayedInterval.Presentation + FieldNameOccupied] > 0 Then
				
				NewRow = EmploymentTable.Add();
				
				NewRow.WorkCenterType = String.WorkCenterType;
				NewRow.IntervalDate = DisplayedInterval.Value;
				
				NewRow.Count = String[DisplayedInterval.Presentation + FieldNameOccupied] * 3600;
				
			EndIf;
			
		EndDo;
		
	EndDo;

	EmploymentTable.GroupBy("WorkCenterType, IntervalDate", "Count");
	
	Return PutToTempStorage(EmploymentTable, UUID);

EndFunction

&AtClientAtServerNoContext
Function ManualPlacementDataInGraph(Form)
	
	Result = ProductionManagementClientServer.StructureOfStagePlacementInSchedule();
	
	Result.Calculated = True;
	Result.Begin                          = Form.Begin;
	Result.PreliminaryBufferEnd = Form.Begin;
	Result.FollowUpBufferStart        = Form.Ending;
	Result.Ending                       = Form.Ending;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region VariancesFromStandard

&AtServer
Procedure DisplayDeviationsFromStandard()
	
	VariancesFromStandard.Clear();
	
	Areas = AreasOfStandardDeviationTable();
	
	VariancesFromStandard.Put(Areas.Title);
	
	For Each String In VariancesFromStandard() Do
		
		Areas.String.Parameters.Fill(String);
		
		VariancesFromStandard.Put(Areas.String);
		
	EndDo;
	
EndProcedure

&AtServer
Function AreasOfStandardDeviationTable()
	
	Result = New Structure();
	
	Table = New SpreadsheetDocument;
	
	// Indent
	Area = Table.Area("R1C1:R1C1");
	Area.ColumnWidth = 5;
	
	// The "Header" area
	
	// View of the work center
	Area = CellAreaHeader(Table, "R2C2:R3C2", 50);
	Area.Text = NStr("vi = 'Dạng nguồn lực sản xuất';
					|ru = 'Вид рабочего центра';
					|en = 'Work center type'; fa = 'نوع مرکز کاری';
					|it = 'Tipo di centro di lavoro';
					|pl = 'Rodzaj centrum wykonania pracy';
					|tr = 'İş merkezi türü'");
	
	// Operating time
	Area = CellAreaHeader(Table, "R2C3:R2C5", 45);
	Area.Text = NStr("vi = 'Thời gian làm việc';
					|ru = 'Время работы, ч';
					|en = 'Working hours, h'; fa = 'Working hours, h';
					|it = 'Orario di lavoro, h';
					|pl = 'Czas pracy, g';
					|tr = 'Çalışma süre, sa.'");
	
	// NormativeStandard
	Area = CellAreaHeader(Table, "R3C3:R3C3", 15);
	Area.Text = NStr("vi = 'Tiêu chuẩn';
					|ru = 'Норматив';
					|en = 'Standard'; fa = 'استاندارد';
					|it = 'Normativa';
					|pl = 'Standard';
					|tr = 'Standart'");
	
	// Busy
	Area = CellAreaHeader(Table, "R3C4:R3C4", 15);
	Area.Text = NStr("vi = 'Đã chiếm';
					|ru = 'Занято';
					|en = 'Used'; fa = 'استفاده‌شده';
					|it = 'Occupato';
					|pl = 'Used';
					|tr = 'Meşgul'");
	
	// Deviation
	Area = CellAreaHeader(Table, "R3C5:R3C5", 15);
	Area.Text = NStr("vi = 'Sai lệnh';
					|ru = 'Отклонение';
					|en = 'Variance'; fa = 'انحراف';
					|it = 'Variazione';
					|pl = 'Variance';
					|tr = 'Sapma'");
	
	Result.Insert("Title", Table.GetArea("R1C1:R3C5"));
	
	// The "Row" area
	
	// View of the work center
	Area = CellAreaViewOfWorkCenter(Table, "R4C2:R4C2");
	
	// NormativeStandard
	Area = CellAreaNumber(Table, "R4C3:R4C3");
	Area.Parameter = "NormativeStandard";
	
	// Busy
	Area = CellAreaNumber(Table, "R4C4:R4C4");
	Area.Parameter = "Busy";
	
	// Deviation
	Area = CellAreaNumber(Table, "R4C5:R4C5");
	Area.Parameter = "Deviation";
	Area.TextColor = StyleColors.SpecialTextColor;

	Result.Insert("String", Table.GetArea("R4C1:R4C5"));
	
	Return Result;

EndFunction

&AtServer
Function CellAreaHeader(Table, AreaName, Var_Width)
	
	Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	Area = Table.Area(AreaName);
	
	Area.BackColor = WebColors.WhiteSmoke;
	Area.Font    = New Font("Tahoma", 8);
	
	Area.HorizontalAlign = HorizontalAlign.Center;
	Area.VerticalAlign   = VerticalAlign.Top;
	
	Area.ColumnWidth = Var_Width;
	
	Area.Outline(Border,Border,Border,Border);
	Area.Merge();

	Return Area;
	
EndFunction

&AtServer
Function CellAreaViewOfWorkCenter(Table, AreaName)
	
	Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	Area = Table.Area(AreaName);
	
	Area.FillType = SpreadsheetDocumentAreaFillType.Parameter;
	Area.Parameter            = "WorkCenterType";
	Area.DetailsParameter = "WorkCenterType";
	
	Area.HorizontalAlign = HorizontalAlign.Left;
	Area.VerticalAlign   = VerticalAlign.Bottom;
	
	Area.Outline(Border,Border,Border,Border);
	
	Return Area;
	
EndFunction

&AtServer
Function CellAreaNumber(Table, AreaName)
	
	Border = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	Area = Table.Area(AreaName);
	
	Area.FillType = SpreadsheetDocumentAreaFillType.Parameter;
	
	Area.HorizontalAlign = HorizontalAlign.Right;
	Area.VerticalAlign   = VerticalAlign.Bottom;
	
	Area.Format = "NFD=2";
	
	Area.Outline(Border,Border,Border,Border);
	
	Return Area;
	
EndFunction

&AtServer
Procedure UpdateDeviationHyperlink()
	
	ThereAreVariances = False;
	
	If Standards.Count() > 0 Then
		
		FilterParameters = New Structure("WorkCenterType");
		
		Map = New Map;
		
		For Each String In OccupancyOfWorkCenterTypes Do
			
			FilterParameters.WorkCenterType = String.WorkCenterType;
			
			If Standards.FindRows(FilterParameters).UBound() = -1 Then
				ThereAreVariances = True;
				Break;
			EndIf;
			
			CurrentValue = Map.Get(String.WorkCenterType);
			
			If CurrentValue <> Undefined Then
				Map[String.WorkCenterType] = CurrentValue + String.TotalOccupied;
			Else
				Map.Insert(String.WorkCenterType, String.TotalOccupied);
			EndIf;
			
		EndDo;
		
		If Not ThereAreVariances Then
			
			For Each String In Standards Do
				
				If Map.Get(String.WorkCenterType) <> String.Count Then
					ThereAreVariances = True;
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Items.HyperlinkDeviationsFromTheStandard.Visible = ThereAreVariances;
	
EndProcedure

&AtServer
Function VariancesFromStandard()
	
	Result = EmptyDeviationTable();
	
	For Each String In Standards Do
		
		NewRow = Result.Add();
		
		NewRow.WorkCenterType = String.WorkCenterType;
		NewRow.NormativeStandard          = String.Count;
		NewRow.Deviation        = -String.Count;
	
	EndDo;
	
	FilterParameters = New Structure("WorkCenterType");
	
	For Each String In OccupancyOfWorkCenterTypes Do
		
		FilterParameters.WorkCenterType = String.WorkCenterType;
		FoundRows = Result.FindRows(FilterParameters);
		
		If FoundRows.UBound() = -1 Then
			CurrentRow = Result.Add();
			CurrentRow.WorkCenterType = String.WorkCenterType;
		Else
			CurrentRow = FoundRows[0];
		EndIf;
		
		CurrentRow.Busy     = CurrentRow.Busy + String.TotalOccupied;
		CurrentRow.Deviation = CurrentRow.Busy - CurrentRow.NormativeStandard;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure HideDeviationsFromStandard()
	
	VariancesFromStandard.Clear();
	
	UpdateDeviationHyperlink();
	
EndProcedure

&AtServerNoContext
Function EmptyDeviationTable()
	
	Table = New ValueTable;
	
	TypeDetails = New TypeDescription("CatalogRef.WorkCenterTypes");
	Table.Columns.Add("WorkCenterType", TypeDetails);
	
	TypeDetails = Common.TypeDescriptionNumber(10, 2);
	Table.Columns.Add("NormativeStandard",   TypeDetails);
	Table.Columns.Add("Busy",     TypeDetails);
	Table.Columns.Add("Deviation", TypeDetails);

	Return Table;
	
EndFunction

#EndRegion

#Region FillChecking

&AtServer
Procedure ProcessingOfEmploymentVerificationOfTypesOfWorkCenters(Cancel)
	
	If Not StagePlacementInProductionSchedule Then
		Return;
	EndIf;
	
	TabularSectionName = "OccupancyOfWorkCenterTypes";
	
	MessageTemplate = NStr("vi = 'Cột ""%1"" trong hàng %2 của danh sách ""Loại việc làm của trung tâm công việc"" không được điền.';
							|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Занятость видов рабочих центров"".';
							|en = 'Column ""%1"" in line %2 of list ""Stage placement in work center calendar"" is not filled in.'; fa = 'Column ""%1"" in line %2 of list ""Stage placement in work center calendar"" is not filled in.';
							|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""Tipi di occupazione di centri di lavoro"" non è stata compilata.';
							|pl = 'Kolumna ""%1"" w wierszu %2 listy ""Zajętość rodzajów centrów roboczych"" nie jest wypełniona.';
							|tr = '""İş Merkezi Türlerinin Doluluğu"" listesinin %2 satırında ""%1"" sütunu doldurulmadı.'");
	
	LineNumber = 1;
	
	For Each String In OccupancyOfWorkCenterTypes Do
		
		If Not ValueIsFilled(String.WorkCenterType) Then
			
			Field = CommonClientServer.PathToTabularSection(
						TabularSectionName, LineNumber, "WorkCenterType");
			
			MessageText = StrTemplate(MessageTemplate, 
				NStr("vi = 'Dạng nguồn lực sản xuất';
					|ru = 'Вид рабочего центра';
					|en = 'Work center type'; fa = 'نوع مرکز کاری';
					|it = 'Tipo di centro di lavoro';
					|pl = 'Rodzaj centrum wykonania pracy';
					|tr = 'İş merkezi türü'"), LineNumber);
			
			CommonClientServer.MessageToUser(
						MessageText,, 
						Field,, 
						Cancel); 
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure HandlingRunTimeAndBusyIntervalChecks(Cancel)

	ErrorCode = CheckExecutionPeriodAndBusyIntervals(ThisObject);
	
	If ErrorCode = ErrorCodeDoesNotGoBeyondBoundariesOfStage() Then
		
		Field = "OccupancyOfWorkCenterTypes";
		
		MessageText = NStr("vi = 'Mức tải của các dạng nguồn lực sản xuất vượt quá biên của công đoạn';
							|ru = 'Занятость видов рабочих центров выходит за границы этапа';
							|en = 'Stage placement in work center calendar exceeds the stage'; fa = 'قرارگیری مرحله در تقویم مرکز کاری از مرحله فراتر می‌رود';
							|it = 'L''occupazione dei centri di lavoro si concentrano oltre confini di questa fase';
							|pl = 'Zajętość rodzajów centrów roboczych wychodzi za granicy etapu';
							|tr = 'İş merkezi türlerinin doluluğu, aşama sınırlarını aşmaktadır'");
		
		CommonClientServer.MessageToUser(
					MessageText,,
					Field,, 
					Cancel);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Constants

&AtClientAtServerNoContext
Function StatusCompleted_1()
	
	Return PredefinedValue("Enum.StatusesOfProductionStages2_2.Completed");

EndFunction

&AtServerNoContext
Function StatusWorkingSchedule()
	
	Return InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule();
	
EndFunction

&AtClientAtServerNoContext
Function ErrorCodeExecutionPeriodDoesNotMatchIntervals()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Function ErrorCodeDoesNotGoBeyondBoundariesOfStage()
	
	Return 2;
	
EndFunction

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function PressureParameters()

	Result = New Structure;
	
	Result.Insert("LeftLimit", '00010101');
	Result.Insert("LeftBorderPattern", "");
	
	Result.Insert("RightBorder_", '00010101');
	Result.Insert("TemplateRightBorder", "");
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function PlacementDirection(AttributeName)

	If Find(AttributeName, "Begin") > 0 Then
		Return 1;
	Else
		Return -1;
	EndIf;
	
EndFunction

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

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
	If Item.Name = "sh_ShamsiInput_F_Begin" Then
		BeginOnChange(Items.Begin);
	ElsIf Item.Name = "sh_ShamsiInput_F_Ending" Then
		EndingOnChange(Items.Ending);
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
