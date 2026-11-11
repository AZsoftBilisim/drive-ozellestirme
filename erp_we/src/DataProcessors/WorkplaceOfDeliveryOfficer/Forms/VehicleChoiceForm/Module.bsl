// @strict-types

#Region Variables

&AtClient
Var ClosingInProgress; // Boolean

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CurrentSessionDate = CurrentSessionDate();
	
	TonConversionFactor     		 = ProductsServer.TonConversionFactor(Constants.UnitOfMeasureForWeight.Get());
	CubicMeterConversionFactor = ProductsServer.CubicMeterConversionFactor(Constants.UnitOfMeasureForVolume.Get());
	
	DateFilter        = Parameters.DateFilter;
	Warehouse	         = Parameters.Warehouse;
	RequiredWeight     = Parameters.TotalWeight_ * TonConversionFactor;
	RequiredVolume   = Parameters.TotalVolume * CubicMeterConversionFactor;
	RemainedWeight      = RequiredWeight;
	RemainedVolume    = RequiredVolume;
	GainedWeightPercent   = 0;
	GainedVolumePercent = 0;
	If Not ValueIsFilled(DateFilter) Then
		DateFilter = CurrentSessionDate;
	EndIf;
	JobsGenerated.Load(GetFromTempStorage(Parameters.AddressOfGeneratedTasks));
	UpdateTransportList();
	ElementsToFillIn = New Array;
	ElementsToFillIn.Add(Items.SelectedVehiclesTimeFrom);
	ElementsToFillIn.Add(Items.SelectedVehiclesTimeBy);
	GoodsDeliveryClientServer.FillTimeFieldSelectionList(ElementsToFillIn);
	
	If ValueIsFilled(Parameters.JobWillBePerformedBy) Then
		JobWillBePerformedBy = Parameters.JobWillBePerformedBy;
		Items.JobWillBePerformedBy.ReadOnly = True;
	Else
		JobWillBePerformedBy = Enums.TypesOfTransportationJobAssignees.OurTransportationService;
	EndIf;
	ConfigureByArtistType();	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit
		And SelectedVehicles.Count() > 0 Then
		
		Cancel = True;
		WarningText = NStr("vi = 'Dữ liệu đã thay đổi. Tất cả thay đổi sẽ bị mất.';
							|ru = 'Данные были изменены. Все изменения будут потеряны.';
							|en = 'All changes made to the data will be lost.'; fa = 'All changes made to the data will be lost.';
							|it = 'I dati sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Veri değişti. Tüm değişiklikler kaybolacak.'");
		
		Return;
		
	EndIf;
	
	If Not ClosingInProgress
		And SelectedVehicles.Count() > 0 Then
		
		Cancel = True;
		Buttons = New ValueList; // ValueList of DialogReturnCode
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Chuyển và đóng';
												|ru = 'Перенести и закрыть';
												|en = 'Move and close'; fa = 'انتقال و بستن';
												|it = 'Trasferire e chiudere';
												|pl = 'Przenieś i zamknij';
												|tr = 'Taşı ve kapat'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Chưa chuyển và đóng';
												|ru = 'Не переносить и закрыть';
												|en = 'Do not transfer and close'; fa = 'Do not transfer and close';
												|it = 'Non trasferire e chiudere';
												|pl = 'Nie przenosić i zamknąć';
												|tr = 'Taşımayın ve kapatmayın'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(New CallbackDescription("AfterClosingQuestion", ThisObject),
			NStr("vi = 'Phương tiện vận tải đã chọn chưa được chuyển vào danh sách nhiệm vụ. Chuyển?';
				|ru = 'Выбранные транспортные средства не перенесены в список формируемых заданий. Перенести?';
				|en = 'The selected vehicles have not been transferred to the generated job list. Transfer?'; fa = 'The selected vehicles have not been transferred to the generated job list. Transfer?';
				|it = 'I mezzi di trasporto selezionati non sono trasferiti nell''elenco dei task in generazione. Trasferire?';
				|pl = 'Wybrane pojazdy nie zostały przeniesione do listy sporządzanych zadań. Przenieść?';
				|tr = 'Seçilen araçlar oluşturulan işler listesine taşınmadı. Taşınsın mı?'"), Buttons);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();
	ElsIf UserAnswer = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		Close(AddressOfNewTasksInStorage());
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_Vehicle_" Then
		AddChangeTransportLine(Source);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateFilterOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	AttachIdleHandler("DateSelectedWhenWaitHandlerChanges", 0.1, True);
	
EndProcedure

&AtClient
Procedure DateFilterTuning(Item, Direction, StandardProcessing)
	
	If Not ValueIsFilled(DateFilter) Then
		
		StandardProcessing = False;
		DateFilter = CurrentSessionDate;
		AttachIdleHandler("DateSelectedWhenWaitHandlerChanges", 0.3, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure JobWillBePerformedByOnChange(Item)
	If JobWillBePerformedBy = PredefinedValue("Enum.TypesOfTransportationJobAssignees.EmptyRef") Then
		JobWillBePerformedBy = PredefinedValue("Enum.TypesOfTransportationJobAssignees.OurTransportationService");
		If Items.PagesAssigneeTypes.CurrentPage = Items.PageOurTransportationService Then
			Return;
		EndIf;
	EndIf;
	ConfigureByArtistType();
EndProcedure

&AtClient
Procedure CarrierOnChange(Item)
	
	CarrierWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVehicles

&AtClient
Procedure VehiclesSelection(Item, RowSelected, Field, StandardProcessing)
	
	MoveLines(Items.Vehicles.SelectedRows)
	
EndProcedure

&AtClient
Procedure VehiclesDragStart(Item, DragParameters, Perform)
	
	StartedMoving = True;
	
EndProcedure

&AtClient
Procedure VehiclesDragEnd(Item, DragParameters, StandardProcessing)
	
	StartedMoving = False;
	
EndProcedure

&AtClient
Procedure VehiclesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
	FormParameters = New Structure;
	If Copy Then
		FormParameters.Insert("CopyingValue", Items.Vehicles.CurrentData.Ref);
	EndIf;
	
	OpenForm("Catalog.Vehicles.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVehicleTypes

&AtClient
Procedure VehicleTypesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	MoveLines(Items.VehicleTypes.SelectedRows, False)
	
EndProcedure

&AtClient
Procedure VehicleTypesDragStart(Item, DragParameters, Perform)
	
	StartedMoving = True;
	
EndProcedure

&AtClient
Procedure VehicleTypesDragEnd(Item, DragParameters, StandardProcessing)
	
	StartedMoving = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedVehicles

&AtClient
Procedure SelectedVehiclesDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	If Not StartedMoving Then
		DragParameters.Action = DragAction.Cancel;
	Else
		DragParameters.Action = DragAction.Move;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedVehiclesDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If JobWillBePerformedBy = PredefinedValue("Enum.TypesOfTransportationJobAssignees.OurTransportationService") Then
		DragParametersValue = DragParameters.Value[0]; // CatalogRef.VehicleTypes, FormDataStructure
		If TypeOf(DragParametersValue) =Type("CatalogRef.VehicleTypes") Then
			MoveLines(Items.VehicleTypes.SelectedRows, False)
		ElsIf DragParametersValue.Property("Ref")
			And TypeOf(DragParametersValue.Ref) = Type("CatalogRef.Vehicles") Then
			MoveLines(Items.Vehicles.SelectedRows)
		EndIf;
	Else
		If Not ValueIsFilled(Carrier) Then
			MessageText = "vi = 'Chọn một hãng';
							|ru = 'Выберите перевозчика';
							|en = 'Select carrier';
							|it = 'Scegliere il trasportatore';
							|pl = 'Wybierz przewoźnika';
							|tr = 'Taşıyıcı seçin'";
			ShowMessageBox(, MessageText);
			Return;
		EndIf;
		MoveLines(Items.CarrierVehicleTypes.SelectedRows, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectedVehiclesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	DeleteRowsOfSelectedVehicles(Items.SelectedVehicles.SelectedRows);
	
EndProcedure

&AtClient
Procedure TheVehicleSelectedDateTimeWhenYouChange(Item)
	
	CheckAdjustSortByTime(Item.Name);
	
EndProcedure

&AtClient
Procedure SelectedVehiclesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure VehiclesChange(Command)
	
	CurrentData = Items.Vehicles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ShowValue(,CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	If JobWillBePerformedBy = PredefinedValue("Enum.TypesOfTransportationJobAssignees.OurTransportationService") Then
		If Items.PageVehiclesTypes.CurrentPage = Items.PageVehiclesTypes.ChildItems.VehiclesPage Then
			MoveLines(Items.Vehicles.SelectedRows)
		Else 
			MoveLines(Items.VehicleTypes.SelectedRows, False)
		EndIf;
	Else
		If Not ValueIsFilled(Carrier) Then
			MessageText = NStr("vi = 'Chọn một hãng';
								|ru = 'Выберите перевозчика';
								|en = 'Select carrier'; fa = 'Select carrier';
								|it = 'Scegliere il trasportatore';
								|pl = 'Wybierz przewoźnika';
								|tr = 'Taşıyıcı seçin'");
			ShowMessageBox(, MessageText);
			Return;
		EndIf;
		MoveLines(Items.CarrierVehicleTypes.SelectedRows, False)
	EndIf;
		
EndProcedure

&AtClient
Procedure Remove(Command)
	
	If Items.SelectedVehicles.SelectedRows.Count() > 0 Then
		DeleteRowsOfSelectedVehicles(Items.SelectedVehicles.SelectedRows)
	EndIf;
	
EndProcedure

&AtClient
Procedure MoveSelectedToDelivery(Command)
	
	ClosingInProgress = True;
	If SelectedVehicles.Count() = 0 Then
		Close();
	Else
		Close(AddressOfNewTasksInStorage());
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VehiclesName.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Vehicles.StandardFrequency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0.7;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDocumentIndicatorTotals);
	Item.Appearance.SetParameterValue("Font", New Font(,,True));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.VehiclesTransportationJobs.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Vehicles.TransportationJobs");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có nhiệm vụ để vận chuyển>';
													|ru = '<нет заданий на перевозку>';
													|en = '<no itineraries>'; fa = '<no itineraries>';
													|it = '<non ci sono task di trasporto>';
													|pl = '<brak zleceń do transportu>';
													|tr = '<taşıma planı yok>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedVehiclesCarrier.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedVehicles.Carrier");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<dịch vụ vận chuyển của chúng tôi>';
													|ru = '<наша транспортная служба>';
													|en = '<in-house carrier>'; fa = '<in-house carrier>';
													|it = '<il nostro servizio di trasporto>';
													|pl = '<nasza usługa transportowa>';
													|tr = '<taşıma hizmetimiz>.'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

&AtServer
Procedure SetTitleVehiclesOfTransportTask()
	If Not ValueIsFilled(DateFilter) Then
		Items.VehiclesTransportationJobs.Visible = False;
	Else
		Items.VehiclesTransportationJobs.Visible = True;
		Items.VehiclesTransportationJobs.Title = StrTemplate(NStr("vi = 'Nhiệm vụ vận chuyển %1';
																	|ru = 'Задания на перевозку на %1';
																	|en = 'Itineraries for %1'; fa = 'Itineraries for %1';
																	|it = 'Задания на перевозку на %1';
																	|pl = 'Itineraries for %1';
																	|tr = '%1 kapsamında taşıma planı'"),
																		Format(DateFilter, NStr("vi = 'ДФ=""д МММ""';
																								|ru = 'ДФ=""д МММ""';
																								|en = 'DF=""MMM, d""'; fa = 'DF=""MMM, d""';
																								|it = 'ДФ=""д МММ""';
																								|pl = 'DF=""d MMM""';
																								|tr = 'DF=""d MMM""'")));
	EndIf;
EndProcedure

&AtServer
Procedure UpdateTransportList()
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	TransportationJob.Vehicle_ AS Vehicle_,
	|	SUM(1) AS Frequency_2
	|INTO TTFrequencyOfTransportUsage
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|WHERE
	|	TransportationJob.Posted
	|	AND TransportationJob.Date >= &DateForStatistics
	|	AND NOT TransportationJob.Status = VALUE(Enum.StatusesOfTransportationJobs.BeingGenerated)
	|	AND TransportationJob.Warehouse IN HIERARCHY(&Warehouse)
	|
	|GROUP BY
	|	TransportationJob.Vehicle_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Vehicles.Ref AS Ref,
	|	CASE
	|		WHEN VLFrequencyOfTransportUse.Frequency_2 IS NULL 
	|			THEN 0
	|		WHEN TotalFrequencyOfTransportUse.MaxFrequency = 0
	|			THEN 0
	|		ELSE VLFrequencyOfTransportUse.Frequency_2 / TotalFrequencyOfTransportUse.MaxFrequency
	|	END AS StandardFrequency,
	|	FALSE AS Selected,
	|	0 AS CounterSelected
	|FROM
	|	Catalog.Vehicles AS Vehicles
	|		LEFT JOIN TTFrequencyOfTransportUsage AS VLFrequencyOfTransportUse
	|		ON (VLFrequencyOfTransportUse.Vehicle_ = Vehicles.Ref)
	|		LEFT JOIN (SELECT
	|			MAX(TTFrequencyOfTransportUsage.Frequency_2) AS MaxFrequency
	|		FROM
	|			TTFrequencyOfTransportUsage AS TTFrequencyOfTransportUsage) AS TotalFrequencyOfTransportUse
	|		ON (TRUE)
	|WHERE
	|	NOT Vehicles.DeletionMark";
	Query.SetParameter("DateForStatistics",AddMonth(CurrentSessionDate, -2));
	Query.SetParameter("Warehouse", Warehouse);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return
	EndIf;
	
	Vehicles.Load(Result.Unload());
	CompleteTransportationTasks();
	SetTitleVehiclesOfTransportTask()
	
EndProcedure

&AtServer
Procedure CompleteTransportationTasks()
	Query = New Query;
	Query.Text =
	"SELECT
	|	ScheduledTransportationJobs.Vehicle_,
	|	ScheduledTransportationJobs.Ref,
	|	ScheduledTransportationJobs.Status,
	|	ScheduledTransportationJobs.TimeFrom,
	|	ScheduledTransportationJobs.TimeTo
	|INTO TTTransportationTasksPlanned
	|FROM
	|	&ScheduledTransportationJobs AS ScheduledTransportationJobs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTTransportationTasksPlanned.Vehicle_, TransportationJob.Vehicle_) AS Ref,
	|	ISNULL(TTTransportationTasksPlanned.Status, TransportationJob.Status) AS Status,
	|	ISNULL(TTTransportationTasksPlanned.TimeFrom, CASE
	|			WHEN TransportationJob.ActualTripStartTime = DATETIME(1, 1, 1)
	|				THEN TransportationJob.PlanTripStartTime
	|			ELSE TransportationJob.ActualTripStartTime
	|		END) AS TimeFrom,
	|	ISNULL(TTTransportationTasksPlanned.TimeTo, CASE
	|			WHEN TransportationJob.ActualTripEndTime = DATETIME(1, 1, 1)
	|				THEN TransportationJob.PlanTripEndTime
	|			ELSE TransportationJob.ActualTripEndTime
	|		END) AS TimeTo
	|FROM
	|	Document.TransportationJob AS TransportationJob
	|		LEFT JOIN TTTransportationTasksPlanned AS TTTransportationTasksPlanned
	|		ON (TTTransportationTasksPlanned.Ref = TransportationJob.Ref)
	|WHERE
	|	TransportationJob.Posted
	|	AND BEGINOFPERIOD(CASE
	|				WHEN TransportationJob.ActualTripStartTime = DATETIME(1, 1, 1)
	|					THEN TransportationJob.PlanTripStartTime
	|				ELSE TransportationJob.ActualTripStartTime
	|			END, DAY) = &DateFilter
	|	AND NOT TransportationJob.Status = VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|
	|ORDER BY
	|	TimeFrom,
	|	TimeTo";
	
	Query.SetParameter("DateFilter",DateFilter);
	Query.SetParameter("ScheduledTransportationJobs",JobsGenerated.Unload());
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return
	EndIf;
	
	TransportTaskTable = Result.Unload();
	
	For Each Page1 In Vehicles Do
		ArrayOfTransportTasks = TransportTaskTable.FindRows(New Structure("Ref", Page1.Ref));
		TransportTaskRow = "";
		For Each VLRow In ArrayOfTransportTasks Do
			If BegOfDay(VLRow.TimeFrom) = BegOfDay(VLRow.TimeTo) Then
				TransportTaskRow = TransportTaskRow + ?(TransportTaskRow = "","",Chars.LF) + NStr("vi = 'Từ';
																									|ru = 'С';
																									|en = 'FROM'; fa = 'از';
																									|it = 'DAL';
																									|pl = 'OD';
																									|tr = 'ile'")
										+ Chars.NBSp + Format(VLRow.TimeFrom, NStr("vi = 'ДФ=""ЧЧ:мм""';
																					|ru = 'ДФ=""ЧЧ:мм""';
																					|en = 'DF=""HH:mm""'; fa = 'DF=""HH:mm""';
																					|it = 'ДФ=""ЧЧ:мм""';
																					|pl = 'DF=""HH:mm""';
																					|tr = 'DF=""HH:mm""'")) + Chars.NBSp + NStr("vi = 'đến';
																																|ru = 'до';
																																|en = 'to'; fa = 'تا';
																																|it = 'al';
																																|pl = 'do';
																																|tr = 'kadar'")
										+ Chars.NBSp + Format(VLRow.TimeTo, NStr("vi = 'ДФ=""ЧЧ:мм""';
																				|ru = 'ДФ=""ЧЧ:мм""';
																				|en = 'DF=""HH:mm""'; fa = 'DF=""HH:mm""';
																				|it = 'ДФ=""ЧЧ:мм""';
																				|pl = 'DF=""HH:mm""';
																				|tr = 'DF=""HH:mm""'")) + " (" + VLRow.Status + ")"
			Else
				TransportTaskRow = TransportTaskRow + ?(TransportTaskRow = "","",Chars.LF) + NStr("vi = 'Từ';
																									|ru = 'С';
																									|en = 'FROM'; fa = 'از';
																									|it = 'DAL';
																									|pl = 'OD';
																									|tr = 'ile'")
										+ Chars.NBSp + Format(VLRow.TimeFrom, NStr("vi = 'ДФ=""ЧЧ:мм""';
																					|ru = 'ДФ=""ЧЧ:мм""';
																					|en = 'DF=""HH:mm""'; fa = 'DF=""HH:mm""';
																					|it = 'ДФ=""ЧЧ:мм""';
																					|pl = 'DF=""HH:mm""';
																					|tr = 'DF=""HH:mm""'")) + Chars.NBSp + NStr("vi = 'cả ngày (';
																																|ru = 'весь день (';
																																|en = 'all day ('; fa = 'all day (';
																																|it = 'tutto il giorno (';
																																|pl = 'cały dzień (';
																																|tr = 'tüm gün ('") + VLRow.Status + ")"
			EndIf;
		EndDo;
		Page1.TransportationJobs = TransportTaskRow;
	EndDo;
EndProcedure

&AtClient
Procedure DateSelectedWhenWaitHandlerChanges()
	
	DateFilterOnChangeServer();
	
EndProcedure

&AtServer
Procedure MoveLines(Val RowsArray, TheseAreVehicles = True)
	
	If RowsArray.Count() = 0 Then
		
		Common.MessageToUser(NStr("vi = 'Chưa chọn phương tiện vận tải';
									|ru = 'Не выбран транспорт';
									|en = 'Transport is not selected'; fa = 'Transport is not selected';
									|it = 'Trasporto non selezionato';
									|pl = 'NIe został wybrany transport';
									|tr = 'Taşıma seçilmemiş'"));
		Return;
		
	EndIf;
	
	For Each IDLink In RowsArray Do
		newRow_ = SelectedVehicles.Add();
		TransportDetails = "Description, CarryingCapacityInTons, CapacityInCubicMeters";
		If TheseAreVehicles Then
			TransportLine = Vehicles.FindByID(IDLink);
			Ref = TransportLine.Ref;
			TransportLine.Selected = True;
			TransportLine.CounterSelected = TransportLine.CounterSelected + 1;
			TransportDetails = TransportDetails +",Type";
		Else
			Ref = IDLink;
		EndIf;
		newRow_.Ref = Ref;
		AttributesStructure1 = Common.ObjectAttributesValues(Ref, TransportDetails);
		FillPropertyValues(newRow_, AttributesStructure1);
		newRow_.TimeFrom = BegOfDay(DateFilter);
		newRow_.TimeTo = BegOfDay(DateFilter);
		newRow_.JobIsPerformedBy = JobWillBePerformedBy;
		If JobWillBePerformedBy = Enums.TypesOfTransportationJobAssignees.Carrier Then 
			newRow_.Carrier = Carrier;
			newRow_.Counterparty = Counterparty;
			newRow_.CarrierBankAccount = CarrierBankAccount;
		EndIf;
	EndDo;
	
	If RequiredWeight <> 0 Then
		RemainedWeight = RequiredWeight - SelectedVehicles.Total("CarryingCapacityInTons");
		GainedWeightPercent = 100 * (RequiredWeight - RemainedWeight) / RequiredWeight;
	EndIf;
	If RequiredVolume <> 0 Then
		RemainedVolume = RequiredVolume - SelectedVehicles.Total("CapacityInCubicMeters");
		GainedVolumePercent = 100 * (RequiredVolume - RemainedVolume) / RequiredVolume;
	EndIf;
	SelectedVehicles.Sort("TimeFrom, TimeTo");
	
EndProcedure

&AtServer
Procedure DeleteRowsOfSelectedVehicles(Val RowsArray)
	
	For Each ID In RowsArray Do
		TransportLine = SelectedVehicles.FindByID(ID);
		If TransportLine = Undefined Then
			Continue;
		EndIf;
		
		If RequiredWeight <> 0 Then
			RemainedWeight = RemainedWeight + TransportLine.CarryingCapacityInTons;
			GainedWeightPercent = 100 * (RequiredWeight - RemainedWeight) / RequiredWeight;
		EndIf;
		If RequiredVolume <> 0 Then
			RemainedVolume = RemainedVolume + TransportLine.CapacityInCubicMeters;
			GainedVolumePercent = 100 * (RequiredVolume - RemainedVolume) / RequiredVolume;
		EndIf;
		If TypeOf(TransportLine.Ref) = Type("CatalogRef.Vehicles") Then
			RowsArray = Vehicles.FindRows(New Structure("Ref",
																			TransportLine.Ref));
			If RowsArray.Count() > 0 Then
				If RowsArray[0].CounterSelected < 2 Then
					RowsArray[0].CounterSelected = 0;
					RowsArray[0].Selected = False;
				Else
					RowsArray[0].CounterSelected = RowsArray[0].CounterSelected - 1;
				EndIf;
			EndIf;
		EndIf;
		SelectedVehicles.Delete(TransportLine);
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckAdjustSortByTime(TagName)
	
	curData = Items.SelectedVehicles.CurrentData;
	curData.TimeFrom = BegOfDay(curData.TimeFrom)
				+ Hour(curData.TimeFromWithoutDate)*60*60 + Minute(curData.TimeFromWithoutDate)*60;
	curData.TimeTo = BegOfDay(curData.TimeTo)
				+ Hour(curData.TimeToWithoutDate)*60*60 + Minute(curData.TimeToWithoutDate)*60;
	If curData.TimeTo < curData.TimeFrom Then
		If StrFind(TagName,"On") = 0 Then
			curData.TimeTo = curData.TimeFrom;
			curData.TimeToWithoutDate = curData.TimeFromWithoutDate;
		Else
			curData.TimeFrom = curData.TimeTo;
			curData.TimeFromWithoutDate = curData.TimeToWithoutDate;
		EndIf;
	EndIf;
	CurrentRow = SelectedVehicles.FindByID(Items.SelectedVehicles.CurrentRow);
	CurrentIndex = SelectedVehicles.IndexOf(curData);
	
	If (CurrentIndex>0 And (SelectedVehicles[CurrentIndex-1].TimeFrom > CurrentRow.TimeFrom
							 Or (SelectedVehicles[CurrentIndex-1].TimeFrom = CurrentRow.TimeFrom
							 	  And SelectedVehicles[CurrentIndex-1].TimeTo > CurrentRow.TimeTo)))
		  Or (CurrentIndex < SelectedVehicles.Count()-1
		  	   And (SelectedVehicles[CurrentIndex+1].TimeFrom < CurrentRow.TimeFrom
							 Or (SelectedVehicles[CurrentIndex+1].TimeFrom = CurrentRow.TimeFrom
							 	  And SelectedVehicles[CurrentIndex+1].TimeTo < CurrentRow.TimeTo))) Then
		SelectedVehicles.Sort("TimeFrom, TimeTo");
	EndIf;
	
EndProcedure

&AtServer
Procedure AddChangeTransportLine(Ref)
	
	Rows = Vehicles.FindRows(New Structure("Ref", Ref));
	If Rows.Count() = 0 Then
		NewRow = Vehicles.Add();
		NewRow.Ref = Ref;
	EndIf;
	
EndProcedure

&AtServer
Procedure DateFilterOnChangeServer()
	
	If Not ValueIsFilled(DateFilter) Then
		DateFilter = CurrentSessionDate;
	EndIf;
	CompleteTransportationTasks();
	SetTitleVehiclesOfTransportTask();
	
EndProcedure

&AtServer
Procedure ConfigureByArtistType()
	
	If JobWillBePerformedBy = Enums.TypesOfTransportationJobAssignees.OurTransportationService Then
		Items.PagesAssigneeTypes.CurrentPage = Items.PageOurTransportationService;
	Else
		Items.PagesAssigneeTypes.CurrentPage = Items.CarriersPage;
	EndIf;	
	
EndProcedure

&AtServer
Procedure CarrierWhenChangedOnServer()
	
	If ValueIsFilled(Carrier) Then
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Carrier, Counterparty, True);
		
		If ValueIsFilled(Counterparty) Then
			CarrierBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(Counterparty);
		EndIf;
	Else
		Counterparty = Catalogs.Counterparties.EmptyRef();
		CarrierBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfNewTasksInStorage()
	
	Return PutToTempStorage(SelectedVehicles.Unload(), UUID);
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_F_DateFilter" Then
		DateFilterOnChange(Items.DateFilter);
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
