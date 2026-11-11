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
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject); 
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If Object.ParallelLoad Then
		
		If Not ValueIsFilled(Object.UnitOfMeasureOfLoad) Then
			MessageText = NStr("vi = 'Chưa điền trường ""Đơn vị tính kết nhập"".';
								|ru = 'Поле ""Единица измерения загрузки"" не заполнено.';
								|en = '""Load unit of measure"" is required.'; fa = '""Load unit of measure"" is required.';
								|it = 'Поле ""Единица измерения загрузки"" не заполнено.';
								|pl = 'Nie wypełniono pola ""Jednostka miary obciążenia"".';
								|tr = '""Çalışma Yükü Ölçü Birimi"" alanı doldurulmadı.'");
   			Common.MessageToUser(MessageText,, "UnitOfMeasureOfLoad", "Object", Cancel);
		EndIf; 
		
		If Object.ImportOption = Enums.WorkCenterLoadOptions.Synchronous 
			And Not Object.SetupSettingsAreUsed Then
			
			If Not ValueIsFilled(Object.OperationTime) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Thời gian làm việc"".';
									|ru = 'Поле ""Время работы"" не заполнено.';
									|en = '""Working time"" is required.'; fa = '""Working time"" is required.';
									|it = 'Поле ""Время работы"" не заполнено.';
									|pl = 'Nie wypełniono pola ""Rodzaj pracy"".';
									|tr = '""Çalışma Süresi"" alanı doldurulmadı.'");
	   			Common.MessageToUser(MessageText,, "OperationTime", "Object", Cancel);
			EndIf; 
			If Not ValueIsFilled(Object.UnitOfMeasure) Then
				MessageText = NStr("vi = 'Chưa điền trường ""Đơn vị thời gian"".';
									|ru = 'Поле ""Единица измерения времени"" не заполнено.';
									|en = '""Time unit of measure"" is required.'; fa = '""Time unit of measure"" is required.';
									|it = 'Поле ""Единица измерения времени"" не заполнено.';
									|pl = 'Nie wypełniono pola ""Jednostka miary czasu"".';
									|tr = '""Zaman Ölçü Birimi"" alanı doldurulmadı.'");
	   			Common.MessageToUser(MessageText,, "UnitOfMeasure", "Object", Cancel);
			EndIf; 
			
		EndIf; 
		
	EndIf; 
	
	If Object.SetupSettingsAreUsed Then
		
		If Not ValueIsFilled(Object.ChangeoverTimeUnit) Then
			MessageText = NStr("vi = 'Chưa điền trường ""Đơn vị thời gian chuyển đổi"".';
								|ru = 'Поле ""Единица времени переналадки"" не заполнено.';
								|en = '""Changeover time unit"" is required.'; fa = '""Changeover time unit"" is required.';
								|it = 'Поле ""Единица времени переналадки"" не заполнено.';
								|pl = 'Nie wypełniono pola ""Jednostka czasu rekonfiguracji"".';
								|tr = '""Değiştirme Zamanı Birimi"" alanı doldurulmadı.'");
   			Common.MessageToUser(MessageText,, "UnitOfMeasureOfLoad", "Object", Cancel);
		EndIf; 
		
	EndIf; 
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetPrivilegedMode(True);
	InformationRegisters.ChangeoverDurationTime.SetChangeoverDuration(CurrentObject.Ref,,, ChangeoverTime);
	SetPrivilegedMode(False);
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_WorkCenterTypes");

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SetupOptions" And Source = Object.Ref Then
		// You need to read the time, because it is recorded when recording the type of RC
		ReadChangeoverTime();
		
	ElsIf EventName = "Write_BusinessStructure" Then
		ReadDivisionParameters();
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure VariantOfDescriptionOfWorkCentersOnChange(Item)
	
	Object.EnterAvailabilityForWorkCenterType = (VariantOfDescriptionOfWorkCenters = 1);
	
	If Not Object.EnterAvailabilityForWorkCenterType Then
		Object.Calendar = Undefined;
		Object.NumberOfWorkCenters = 0;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm, "EnterAvailabilityForWorkCenterType");
	
EndProcedure

&AtClient
Procedure UseAvailabilityAccordingToScheduleOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure PlanOperationsOfWorkCentersOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure ParallelLoadOnChange(Item)

	If Object.ParallelLoad
		And Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.EmptyRef") Then
		Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.Asynchronous");
	ElsIf Not Object.ParallelLoad
		And Object.ImportOption <> PredefinedValue("Enum.WorkCenterLoadOptions.EmptyRef") Then
		Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "ParallelLoad");

EndProcedure
 
&AtClient
Procedure AsynchronousLoadingOptionOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "ImportOption");
	
EndProcedure

&AtClient
Procedure DownloadOptionSynchronous2OnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "ImportOption");
	
EndProcedure

&AtClient
Procedure SetupSettingsAreUsedOnChange(Item)

	If Object.SetupSettingsAreUsed And Object.ChangeoverTimeUnit.IsEmpty() Then
		Object.ChangeoverTimeUnit = PredefinedValue("Enum.TimeMeasureUnits.Minute");
	ElsIf Not Object.SetupSettingsAreUsed And Not Object.ChangeoverTimeUnit.IsEmpty() Then
		Object.ChangeoverTimeUnit = PredefinedValue("Enum.TimeMeasureUnits.EmptyRef");
	EndIf; 
	
	ConfigureDependentFormElements(ThisForm, "SetupSettingsAreUsed"); 
	
	ConfigureNavigationBar();
	
EndProcedure


&AtClient
Procedure LongDescOnChange(Item)
	
	Items.AdditionalPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
   
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	#Region ParallelLoad
	// The mark is not filled in for readjustment
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ChangeoverTimeUnit.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetupSettingsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	// The mark of the filled for the unit of loading
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnitOfMeasureOfLoad.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ParallelLoad");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// The mark of the filled in for the working time
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OperationTime.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnitOfMeasure.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ImportOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.WorkCenterLoadOptions.Synchronous;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	#EndRegion
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
	FillPropertyValues(ThisObject, SubsystemSettingsProduction);
	
	ReadDivisionParameters();
	
	ReadChangeoverTime(); // You need to read the time, because it is recorded when recording the type of RC
	
	VariantOfDescriptionOfWorkCenters = Number(Object.EnterAvailabilityForWorkCenterType);
	
	RightToSwitchToEnabledInput = AccessRight("View",
		Metadata.DataProcessors.AvailabilityOfWorkCenterTypes.Commands.AvailabilityOfWorkCenterTypesContext);
	
	FillInLoadUnitSelection();
	
	ConfigureNavigationBar();
	
	ConfigureDependentFormElements(ThisForm);
	
	Items.AdditionalPage.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
	Items.PlanOperationsOfWorkCenters.Visible = UseManufacturingExecutionSystem Or ProductionIsUsed21;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("EnterAvailabilityForWorkCenterType")
		Or Initialize Then   
		Items.Calendar.Visible = Object.EnterAvailabilityForWorkCenterType Or ValueIsFilled(Object.Calendar);
		Items.NumberOfWorkCenters.Visible = Object.EnterAvailabilityForWorkCenterType;
		Items.IndentationGroupDescriptionOfWorkCenters.Visible = Object.EnterAvailabilityForWorkCenterType;
	EndIf;
	
	If AttributesStructure1.Property("ParallelLoad")
		Or Initialize Then 
		Items.UnitOfMeasureOfLoad.Enabled   = Object.ParallelLoad; 
		Items.AsynchronousLoadingOption.Enabled = Object.ParallelLoad;
		Items.DownloadOptionSynchronous1.Enabled = Object.ParallelLoad; 
		Items.DownloadOptionSynchronous2.Enabled = Object.ParallelLoad;
	EndIf;
	
	If AttributesStructure1.Property("ImportOption")
		Or AttributesStructure1.Property("ParallelLoad")
		Or AttributesStructure1.Property("SetupSettingsAreUsed")
		Or Initialize Then 

		If Object.ParallelLoad And Object.SetupSettingsAreUsed Then
			Items.PagesSynchronousLoad.CurrentPage = Items.PageSynchronousLoadWithoutWorkTime;
		Else
			Items.PagesSynchronousLoad.CurrentPage = Items.PageSynchronousLoadWithWorkTime;
		EndIf;
		
		SynchronousLoad = (Object.ImportOption = PredefinedValue("Enum.WorkCenterLoadOptions.Synchronous"));
		Items.OperationTime.Enabled = SynchronousLoad;
		Items.UnitOfMeasure.Enabled = SynchronousLoad;
		
	EndIf;	
	
	If AttributesStructure1.Property("SetupSettingsAreUsed")
		Or Initialize Then 
		Items.ChangeoverTime.Enabled = Object.SetupSettingsAreUsed;
		Items.ChangeoverTimeUnit.Enabled = Object.SetupSettingsAreUsed;
	EndIf;
	
	If AttributesStructure1.Property("Department")
		Or AttributesStructure1.Property("EnterAvailabilityForWorkCenterType")
		Or Initialize Then
		WorkCentersOnlyIndividually = (Form.PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Hour")
			Or Form.PlanningInterval = PredefinedValue("Enum.ProductionScheduleAccuracy.Shift"))
			And Not Object.EnterAvailabilityForWorkCenterType;
		Items.VariantOfDescriptionOfWorkCenters.Enabled = Not WorkCentersOnlyIndividually;
		
		If WorkCentersOnlyIndividually Then
			Items.VariantOfDescriptionOfWorkCenters.ToolTipRepresentation = ToolTipRepresentation.Button;
			Items.VariantOfDescriptionOfWorkCenters.ToolTip = StrTemplate(
				NStr("vi = 'Đối ới bộ phận có khoảng thời gian lập kế hoạch ""%1"", nguồn lực làm việc được xác định riêng biệt.';
					|ru = 'Для подразделений с интервалом планирования ""%1"" рабочие центры задаются только индивидуально.';
					|en = 'You can set work centers for business units with the ""%1"" planning interval only individually.'; fa = 'You can set work centers for business units with the ""%1"" planning interval only individually.';
					|it = 'Для подразделений с интервалом планирования ""%1"" рабочие центры задаются только индивидуально.';
					|pl = 'You can set work centers for business units with the ""%1"" planning interval only individually.';
					|tr = 'Для подразделений с интервалом планирования ""%1"" рабочие центры задаются только индивидуально.'"),
				Form.PlanningInterval);
		Else
			Items.VariantOfDescriptionOfWorkCenters.ToolTipRepresentation = ToolTipRepresentation.None;
			Items.VariantOfDescriptionOfWorkCenters.ToolTip = "";
		EndIf;
	EndIf;
	
	Items.MinimumSignificantBufferGroup.Visible = Object.UseAvailabilityAccordingToSchedule And Form.ProductionIsUsed21;
	Items.MaximumLoadGroup.Visible = Object.ParallelLoad;
	
	If Form.RightToSwitchToEnabledInput Then
		Items.AvailabilityOfWorkCenterTypesContext.Enabled = Object.UseAvailabilityAccordingToSchedule
			Or Object.PlanOperationsOfWorkCenters And (Form.UseManufacturingExecutionSystem Or Form.ProductionIsUsed21);
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureNavigationBar()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("UseSetupSettings", Object.SetupSettingsAreUsed);
	
	TMCommonUse.ConfigureFormByParameters(ThisForm, SettingsStructure);
	
EndProcedure

#Region DivisionParameters

&AtServer
Procedure DivisionWhenChangedOnServer()

	PlanningIntervalBeforeChange = PlanningInterval; 
	
	ReadDivisionParameters();

	If PlanningInterval <> PlanningIntervalBeforeChange Then
		// You need to reset the parameters that are not suitable for the new scheduling interval
		If (PlanningInterval = Enums.ProductionScheduleAccuracy.Hour
			Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift)
			And Object.EnterAvailabilityForWorkCenterType Then
			Object.EnterAvailabilityForWorkCenterType = False;
			VariantOfDescriptionOfWorkCenters = 0;
		EndIf;
	EndIf;
	
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		Object.MaximumWorkCenterAvailability = 1;
		Object.UnitOfMeasureOfWorkCenterSchedule = Enums.TimeMeasureUnits.Hour;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day
		Or PlanningInterval = Enums.ProductionScheduleAccuracy.Shift Then
		Object.MaximumWorkCenterAvailability = 24;
		Object.UnitOfMeasureOfWorkCenterSchedule = Enums.TimeMeasureUnits.Hour;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		Object.MaximumWorkCenterAvailability = 7;
		Object.UnitOfMeasureOfWorkCenterSchedule = Enums.TimeMeasureUnits.Days1;
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		Object.MaximumWorkCenterAvailability = 30;
		Object.UnitOfMeasureOfWorkCenterSchedule = Enums.TimeMeasureUnits.Days1;
	EndIf;
	
	ConfigureDependentFormElements(ThisForm);
	
EndProcedure

&AtServer
Procedure ReadDivisionParameters()
	
	DivisionParameters = ProductionServerCached.ProductionBusinessUnitDescription(Object.Department);
	PlanningInterval = DivisionParameters.PlanningInterval;
	UseManufacturingExecutionSystem = DivisionParameters.UseManufacturingExecutionSystem;
	
	FillInMaximumAvailabilityParameters();
	
EndProcedure
 
&AtServer
Procedure FillInMaximumAvailabilityParameters()

	MaximumHoursPerLine = "";

	If PlanningInterval = Enums.ProductionScheduleAccuracy.Hour Then
		MaximumHoursPerLine = NStr("vi = '1 giờ';
									|ru = '1 час';
									|en = '1 hour'; fa = '1 ساعت';
									|it = '1 ora';
									|pl = '1 godzina';
									|tr = '1 saat'");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Day Then
		MaximumHoursPerLine = NStr("vi = '24 giờ';
									|ru = '24 часа';
									|en = '24 hours'; fa = '24 hours';
									|it = '24 ore';
									|pl = '24 godziny';
									|tr = '24 saat'");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Week Then
		MaximumHoursPerLine = NStr("vi = '7 ngày';
									|ru = '7 дней';
									|en = '7 days'; fa = '7 روز';
									|it = '7 giorni';
									|pl = '7 dni';
									|tr = '7 gün'");
	ElsIf PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		MaximumHoursPerLine = NStr("vi = '30 ngày';
									|ru = '30 дней';
									|en = '30 days'; fa = '30 days';
									|it = '30 giorni';
									|pl = '30 dni';
									|tr = '30 gün'");
	EndIf;
	
	If IsBlankString(MaximumHoursPerLine) Then
		LabelTitle = "";
	Else
		LabelTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '(tối đa %1)';
				|ru = '(максимум %1)';
				|en = '(%1 maximum)'; fa = '(%1 maximum)';
				|it = '(massimo %1)';
				|pl = '(maksimum %1)';
				|tr = '(maksimum %1)'"),
			MaximumHoursPerLine);
	EndIf;
	
	Items.DecorationMaximumAvailabilityOfTheRC.Title = LabelTitle;
	
	ChoiceList = Items.UnitOfMeasureOfWorkCenterSchedule.ChoiceList;
	ChoiceList.Clear();
	ChoiceList.Add(Enums.TimeMeasureUnits.Minute);
	ChoiceList.Add(Enums.TimeMeasureUnits.Hour);
	If PlanningInterval = Enums.ProductionScheduleAccuracy.Week
		Or PlanningInterval = Enums.ProductionScheduleAccuracy.Month Then
		ChoiceList.Add(Enums.TimeMeasureUnits.Days1);
	EndIf;
	
EndProcedure

#EndRegion

#Region ParallelLoad

&AtServer
Procedure FillInLoadUnitSelection()
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	UnitsOfMeasurement.Description AS Description
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS UnitsOfMeasurement
	|WHERE
	|	NOT UnitsOfMeasurement.DeletionMark
	|	AND UnitsOfMeasurement.Owner = VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|
	|ORDER BY
	|	Description";
	
	Result = Query.Execute().Unload().UnloadColumn("Description");
	Items.UnitOfMeasureOfLoad.ChoiceList.LoadValues(Result);
	
EndProcedure

#EndRegion

#Region Changeover
 
&AtServer
Procedure ReadChangeoverTime()

	ChangeoverTime = 0;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ChangeoverDurationTime.ChangeoverTime
	|FROM
	|	InformationRegister.ChangeoverDurationTime AS ChangeoverDurationTime
	|WHERE
	|	ChangeoverDurationTime.WorkCenterType = &WorkCenterType
	|	AND ChangeoverDurationTime.CurrentSetupSettings = VALUE(Catalog.SetupOptions.EmptyRef)
	|	AND ChangeoverDurationTime.NextSetupSettings = VALUE(Catalog.SetupOptions.EmptyRef)";
	
	Query.SetParameter("WorkCenterType", Object.Ref);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	Selection = Result.Select();
	
	If Selection.Next() Then
		ChangeoverTime = Selection.ChangeoverTime;
	EndIf;

EndProcedure


#EndRegion

// StandardSubsystems.Properties 

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion
