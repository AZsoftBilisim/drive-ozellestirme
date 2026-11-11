
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Record, ThisObject);
	
	UnitOfMeasureForWeight   = Constants.UnitOfMeasureForWeight.Get();
	UnitOfMeasureForVolume = Constants.UnitOfMeasureForVolume.Get();
	
	SetDefaults();
	
	If Record.ConfigureGenerationByWarehouseAreas = "CustomizeGenerationByWorkAreas" Then
		FillInWorkAreaRestrictionsFilter();
	EndIf;
	
	If Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.SettingsForCreatingMovingTasks.Title = NStr("vi = 'Tạo nhiệm vụ đóng gói lại';
															|ru = 'Создание заданий на подпитку';
															|en = 'Create replenishment jobs'; fa = 'Create replenishment jobs';
															|it = 'Creazione compiti per sovvenzionamento';
															|pl = 'Stworzenie zadań do podładowania';
															|tr = 'Stok yenileme görevini oluşturma'");
	EndIf;
	
	If Parameters.Key.IsEmpty() Then
		
		ExceptionText = NStr("vi = 'Có thể tạo tùy chỉnh chỉ từ biểu mẫu kho bãi (nơi cất giữ) có cơ chế lưu số dư theo địa chỉ.';
							|ru = 'Создавать настройки можно только из форм склада (помещения) с адресным хранением остатков.';
							|en = 'Settings can be created only from warehouse (wareroom) forms with bin location system.'; fa = 'Settings can be created only from warehouse (wareroom) forms with bin location system.';
							|it = 'È possibile creare impostazioni solo dai moduli di magazzino (stanze) con l''archiviazione degli indirizzi dei residui.';
							|pl = 'Możesz tworzyć ustawienia tylko z formularzy magazynowych (pomieszczenia) z przechowywaniem adresowym pozostałości.';
							|tr = 'Ayarlar, bakiye depo konum takibi yalnızca ambar (alan) formlarından oluşturulabilir.'");
		
		Raise ExceptionText;
		
	EndIf;
	
	OnOpeningClickTab = "";
	Parameters.Property("OnOpeningClickTab",OnOpeningClickTab);
	If OnOpeningClickTab = "SettingsForCreatingRecalculations" Then
		Items.TabGroup.CurrentPage = Items.SettingsForCreatingRecalculations;
	ElsIf OnOpeningClickTab = "SettingsForCreatingMovingTasks" Then
		Items.TabGroup.CurrentPage = Items.SettingsForCreatingMovingTasks;
	EndIf;
	
	Items.RecalculationScheduledJobs.RowFilter = New FixedStructure("DisplayInTheList", True);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Creation of routine tasks (obtaining a unique identifier)
	SetPrivilegedMode(True);
	
	// Setting the forecast
	JobDescription = NStr("vi = 'Dự đoán chi phí đóng gói (%WarehousePresentation_%)';
							|ru = 'Прогноз расхода упаковок (%WarehousePresentation_%)';
							|en = 'Packaging units consumption forecast (%WarehousePresentation_%)'; fa = 'Packaging units consumption forecast (%WarehousePresentation_%)';
							|it = 'Previsione consumo pacchetti (%WarehousePresentation_%)';
							|pl = 'Prognozy zużycia opakowań%WarehousePresentation_%)';
							|tr = 'Paketleme ünitesi gider tahmini (%WarehousePresentation_%)'");
	JobDescription = StrReplace(JobDescription, 
		"%WarehousePresentation_%", 
		WarehousesServer.GetWarehousePresentation(CurrentObject.Warehouse,
			CurrentObject.Premise));
	JobParameters = New Structure;
	JobParameters.Insert("Use", Record.ForecastPackageConsumption);
	JobParameters.Insert("Description", Left(JobDescription, 128));
	
	ScheduledJobParameters = New Array;
	ScheduledJobParameters.Add(CurrentObject.Warehouse);
	ScheduledJobParameters.Add(CurrentObject.Premise);
	
	JobParameters.Insert("Parameters", ScheduledJobParameters);
	JobParameters.Insert("Schedule", ForecastCalculationSchedule);
	
	If Not ValueIsFilled(CurrentObject.ScheduledJobOfForecastCalculation) Then
		Job = Undefined;
	Else
		Job = ScheduledJobsServer.Job(CurrentObject.ScheduledJobOfForecastCalculation);
	EndIf;
	
	If Job = Undefined Then
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.CalculationOfPackageConsumptionForecast);
		Job = ScheduledJobsServer.AddJob(JobParameters);
	Else
		ScheduledJobsServer.ChangeJob(Job, JobParameters);
	EndIf;
	
	CurrentObject.ScheduledJobOfForecastCalculation = ScheduledJobsServer.UUID(Job);
	
	// Task for creating selection tasks
	JobParameters = New Structure;
	JobParameters.Insert("Use", Record.UseScheduledJobToCreatePickingJobs);
	
	JobDescription = NStr("vi = 'Tạo nhiệm vụ lọc trong kho ""%WarehousePresentation_%""';
							|ru = 'Создание заданий на отбор на складе ""%WarehousePresentation_%""';
							|en = 'Create picking jobs at warehouse ""%WarehousePresentation_%""'; fa = 'Create picking jobs at warehouse ""%WarehousePresentation_%""';
							|it = 'Creazione compiti per la selezione in magazzino ""%WarehousePresentation_%""';
							|pl = 'Tworzenie zadań do selekcji w magazynie ""%WarehousePresentation_%""';
							|tr = 'Ambarda filtre için görevlerin oluşturulması ""%WarehousePresentation_%""'");
	JobDescription = StrReplace(JobDescription, 
		"%WarehousePresentation_%", 
		WarehousesServer.GetWarehousePresentation(CurrentObject.Warehouse,
			CurrentObject.Premise));
	JobParameters.Insert("Description", JobDescription);
	
	ParametersStructure = WarehousesServer.StructureOfParametersForCreatingTasksForSelectionAndReplenishment();
	ParametersStructure.Warehouse = CurrentObject.Warehouse;
	ParametersStructure.Premise = CurrentObject.Premise;
	ParametersStructure.CustomizeGenerationByWorkAreas = CurrentObject.ConfigureGenerationByWarehouseAreas;
	ParametersStructure.LimitByWeight = CurrentObject.LimitByWeightFilter;
	ParametersStructure.LimitByVolume = CurrentObject.LimitByVolumeFilter;
	ParametersStructure.LimitationByWeight = CurrentObject.LimitationByWeightFilter;
	ParametersStructure.LimitationByVolume = CurrentObject.LimitationByVolumeFilter;
	ParametersStructure.WarehouseZone = CurrentObject.WarehouseZoneFilter;
	ParametersStructure.ByAllReferences = True;
	
	ScheduledJobParameters = New Array;
	ScheduledJobParameters.Add(ParametersStructure);
	
	JobParameters.Insert("Parameters", ScheduledJobParameters);
	JobParameters.Insert("Schedule", ScheduleOfPickingJobCreation);
	
	If Not ValueIsFilled(CurrentObject.ScheduledJobCreatePickingJobs) Then
		Job = Undefined;
	Else
		Job = ScheduledJobsServer.Job(CurrentObject.ScheduledJobCreatePickingJobs);
	EndIf;
	
	If Job = Undefined Then
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.CreatePickingJobs);
		Job = ScheduledJobsServer.AddJob(JobParameters);
	Else
		ScheduledJobsServer.ChangeJob(Job, JobParameters);
	EndIf;
	
	CurrentObject.ScheduledJobCreatePickingJobs = ScheduledJobsServer.UUID(Job);
	
	// Tasks for creating recalculations of goods
	TaskLinesToDelete = New Array;
	For Each RowInRoutineTasksTable In TableOfRoutineTasksForRecalculations Do
				
		If Not ValueIsFilled(RowInRoutineTasksTable.Id) Then
			Job = Undefined;
		Else
			Job = ScheduledJobsServer.Job(RowInRoutineTasksTable.Id);
		EndIf;
		
		If RowInRoutineTasksTable.ModificationState = "Delete" Then
			
			If Job <> Undefined Then 
				ScheduledJobsServer.DeleteJob(Job);
			EndIf;
			TaskLinesToDelete.Add(RowInRoutineTasksTable);
			
		Else // "Create" or "Modify"
			
			JobParameters = New Structure;
			JobParameters.Insert("Use", True);
			JobParameters.Insert("Description", RowInRoutineTasksTable.Description);
			JobParameters.Insert("RestartIntervalOnFailure", RowInRoutineTasksTable.RestartIntervalOnFailure);
			JobParameters.Insert("RestartCountOnFailure", RowInRoutineTasksTable.RestartCountOnFailure);
			JobParameters.Insert("Schedule", RowInRoutineTasksTable.Schedule);
			ScheduledJobParameters = New Array;
			ScheduledJobParameters.Add(RowInRoutineTasksTable.SettingsForCreatingRecalculations);
			JobParameters.Insert("Parameters", ScheduledJobParameters);
			
			If Job = Undefined Then
				JobParameters.Insert("Metadata", Metadata.ScheduledJobs.CreateGoodsRecountJobs);
				Job = ScheduledJobsServer.AddJob(JobParameters);
				RowInRoutineTasksTable.Id = ScheduledJobsServer.UUID(Job);
			Else
				ScheduledJobsServer.ChangeJob(Job, JobParameters);
			EndIf; 
			
		EndIf;
		
	EndDo;
	
	For Each RowInRoutineTasksTable In TaskLinesToDelete Do
		TableOfRoutineTasksForRecalculations.Delete(RowInRoutineTasksTable);
	EndDo; 
	
	CurrentObject.ScheduledJobsForCreatingInventoryRecountJobs = "";
	For Each RowInRoutineTasksTable In TableOfRoutineTasksForRecalculations Do
		CurrentObject.ScheduledJobsForCreatingInventoryRecountJobs = 
			CurrentObject.ScheduledJobsForCreatingInventoryRecountJobs 
			+ ?(ValueIsFilled(CurrentObject.ScheduledJobsForCreatingInventoryRecountJobs),",","") 
			+ String(RowInRoutineTasksTable.Id);
	EndDo;
		
	// Tasks for creating the movement (selection, placement) of goods
	TaskLinesToDelete = New Array;
	For Each RowInRoutineTasksTable In TableOfScheduledMovementTasks Do
				
		If Not ValueIsFilled(RowInRoutineTasksTable.Id) Then
			Job = Undefined;
		Else
			Job = ScheduledJobsServer.Job(RowInRoutineTasksTable.Id);
		EndIf;
		
		If RowInRoutineTasksTable.ModificationState = "Delete" Then
			
			If Job <> Undefined Then 
				ScheduledJobsServer.DeleteJob(Job);
			EndIf;
			TaskLinesToDelete.Add(RowInRoutineTasksTable);
			
		Else // "Create" or "Modify"
			
			JobParameters = New Structure;
			JobParameters.Insert("Use", True);
			JobParameters.Insert("Description", RowInRoutineTasksTable.Description);
			JobParameters.Insert("RestartIntervalOnFailure", 
				RowInRoutineTasksTable.RestartIntervalOnFailure);
			JobParameters.Insert("RestartCountOnFailure", 
				RowInRoutineTasksTable.RestartCountOnFailure);
			JobParameters.Insert("Schedule", RowInRoutineTasksTable.Schedule);
			JobParameters.Insert("Parameters", 
				CommonClientServer.ValueInArray(RowInRoutineTasksTable.SettingsForCreatingMoves));
			
			If Job = Undefined Then
				JobParameters.Insert("Metadata", Metadata.ScheduledJobs.CreateTransferJobs);
				Job = ScheduledJobsServer.AddJob(JobParameters);
				RowInRoutineTasksTable.Id = ScheduledJobsServer.UUID(Job);
			Else
				ScheduledJobsServer.ChangeJob(Job, JobParameters);
			EndIf; 
			
		EndIf;
		
	EndDo;
	
	For Each RowInRoutineTasksTable In TaskLinesToDelete Do
		TableOfScheduledMovementTasks.Delete(RowInRoutineTasksTable);
	EndDo; 
	
	CurrentObject.ScheduledJobsToCreateTransferJobs = "";
	For Each RowInRoutineTasksTable In TableOfScheduledMovementTasks Do
		CurrentObject.ScheduledJobsToCreateTransferJobs = 
			CurrentObject.ScheduledJobsToCreateTransferJobs 
			+ ?(ValueIsFilled(CurrentObject.ScheduledJobsToCreateTransferJobs),",","") 
			+ String(RowInRoutineTasksTable.Id);
	EndDo;
				
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	SetDefaults();
	
	ForecastCalculationSchedule = New JobSchedule;
	ScheduleOfPickingJobCreation	 = New JobSchedule;
	
	SetPrivilegedMode(True);
	JobID = Record.ScheduledJobOfForecastCalculation;
	
	Job = ScheduledJobsServer.Job(JobID);
	If Job <> Undefined Then
		ForecastCalculationSchedule = Job.Schedule;
		Items.ScheduleAsString.Title = String(ForecastCalculationSchedule);
	EndIf;
	
	JobID = Record.ScheduledJobCreatePickingJobs;
	
	Job = ScheduledJobsServer.Job(JobID);
	If Job <> Undefined Then
		ScheduleOfPickingJobCreation	   						= Job.Schedule;
		Items.ScheduleForCreatingLineSelectionTasks.Title  = String(ScheduleOfPickingJobCreation);
	EndIf;
	
	TableOfRoutineTasksForRecalculations.Clear();
	
	If ValueIsFilled(Record.ScheduledJobsForCreatingInventoryRecountJobs) Then
		ArrayOfIdentifiers = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Record.ScheduledJobsForCreatingInventoryRecountJobs);
		For Each TaskIdString In ArrayOfIdentifiers Do
			JobID = New UUID(TaskIdString);
			Job = ScheduledJobsServer.Job(JobID);
			If Job <> Undefined Then
				FillDescription	= True;
				FillableProperties		= "Schedule, RestartIntervalOnFailure, RestartCountOnFailure";
				
				If CommonClientServer.HasAttributeOrObjectProperty(Job, "Description") Then
					FillDescription	= False;
					FillableProperties		= FillableProperties + ", " + "Description";
				EndIf;
				
				RowInRoutineTasksTable = TableOfRoutineTasksForRecalculations.Add();
				RowInRoutineTasksTable.DisplayInTheList = True;
				RowInRoutineTasksTable.Id = JobID;
				FillPropertyValues(RowInRoutineTasksTable, Job, FillableProperties);
				
				UpdateInformationAboutStateOfRoutineTaskForCreatingRecalculations(
					RowInRoutineTasksTable.Id,
					RowInRoutineTasksTable.EndDate,
					RowInRoutineTasksTable.ExecutionState,
					False);
				
				If Job.Parameters.Count() > 0 Then
					RowInRoutineTasksTable.SettingsForCreatingRecalculations = Job.Parameters[0];
					
					If FillDescription Then
						RowInRoutineTasksTable.Description = ScheduledJobDescription(
																			Job.Parameters[0]);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	TableOfScheduledMovementTasks.Clear();
	
	If ValueIsFilled(Record.ScheduledJobsToCreateTransferJobs) Then
		ArrayOfIdentifiers = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Record.ScheduledJobsToCreateTransferJobs);
		For Each TaskIdString In ArrayOfIdentifiers Do
			JobID = New UUID(TaskIdString);
			Job = ScheduledJobsServer.Job(JobID);
			If Job <> Undefined Then
				FillDescription	= True;
				FillableProperties		= "Schedule, RestartIntervalOnFailure, RestartCountOnFailure";
				
				If CommonClientServer.HasAttributeOrObjectProperty(Job, "Description") Then
					FillDescription	= False;
					FillableProperties		= FillableProperties + ", " + "Description";
				EndIf;
				
				RowInRoutineTasksTable = TableOfScheduledMovementTasks.Add();
				RowInRoutineTasksTable.DisplayInTheList = True;
				RowInRoutineTasksTable.Id = JobID;
				FillPropertyValues(RowInRoutineTasksTable, Job, FillableProperties);
				
				UpdateInformationAboutStateOfScheduledTaskForCreatingMoves(
					RowInRoutineTasksTable.Id,
					RowInRoutineTasksTable.EndDate,
					RowInRoutineTasksTable.ExecutionState,
					False);
				
				If Job.Parameters.Count() > 0 Then
					RowInRoutineTasksTable.SettingsForCreatingMoves = Job.Parameters[0];
					
					If FillDescription Then
						RowInRoutineTasksTable.Description = ScheduledJobDescription(
																			Job.Parameters[0],
																			"MoveTask");
					EndIf;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	SetPrivilegedMode(False);
	
	If Not WarehousesServer.UseWarehouseZones(Record.Warehouse, Record.Premise) Then
		Items.GroupSettingsByWorkArea.Enabled 				= False;
		Items.WarehouseZone.Enabled 								= False;
	EndIf;
	
	Items.RecalculationScheduledJobs.Enabled = AccessRight("Update", Metadata.InformationRegisters.SettingsOfBinLocationWarehouses);
	
	SetAvailability(ThisForm);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ForecastPackageConsumptionOnChange(Item)
	SetAvailability(ThisForm);
EndProcedure

&AtClient
Procedure UseAutomaticCreationOfSelectionTasksOnChange(Item)
	SetAvailability(ThisForm);
EndProcedure

&AtClient
Procedure CustomizeGenerationByWorkAreasOnChange(Item)
	If Record.ConfigureGenerationByWarehouseAreas = "ByASingleWarehouseZone"
		And ValueIsFilled(Record.WarehouseZoneFilter) Then
		WorkingSectionIsSelectedWhenServerChanges();
	Else
		SetAvailability(ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure LimitByVolumeOnChange(Item)
	Items.LimitationByVolume.Enabled = Record.LimitByVolumeFilter;
	Items.UnitOfMeasureForVolume.Enabled = Record.LimitByVolumeFilter;
EndProcedure

&AtClient
Procedure LimitByWeightOnChange(Item)
	Items.LimitationByWeight.Enabled = Record.LimitByWeightFilter;
	Items.UnitOfMeasureForWeight.Enabled = Record.LimitByWeightFilter;
EndProcedure

&AtClient
Procedure WarehouseZoneOnChange(Item)
	WorkingSectionIsSelectedWhenServerChanges();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScheduledJobs

&AtClient
Procedure RoutineTasksBeforeYouStartAddingThem(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Item = Items.RecalculationScheduledJobs Then
		AddingChangingRoutineTaskForCreatingRecalculations(?(Copy, "Copy", "Add"));
	ElsIf Item = Items.ScheduledJobsOfTransfers Then
		AddingChangingRoutineTaskForCreatingMoves(?(Copy, "Copy", "Add"));
	EndIf;
	
EndProcedure

&AtClient
Procedure RoutineTasksBeforeStartingTheChange(Item, Cancel)
	
	Cancel = True;
	If Item = Items.RecalculationScheduledJobs Then
		AddingChangingRoutineTaskForCreatingRecalculations("Edit");
	ElsIf Item = Items.ScheduledJobsOfTransfers Then
		AddingChangingRoutineTaskForCreatingMoves("Edit");
	EndIf;
	
EndProcedure

&AtClient
Procedure RoutineTasksBeforeDeletion(Item, Cancel)
	
	Cancel = True;
		
	Modified = True;
	If Item = Items.RecalculationScheduledJobs Then
		CurrentRow = TableOfRoutineTasksForRecalculations.FindByID(Items.RecalculationScheduledJobs.CurrentRow);
		CurrentRow.ModificationState = "Delete";
		CurrentRow.DisplayInTheList = False;
		Items.RecalculationScheduledJobs.RowFilter = New FixedStructure("DisplayInTheList", True);
	ElsIf Item = Items.ScheduledJobsOfTransfers Then
		CurrentRow = TableOfScheduledMovementTasks.FindByID(Items.ScheduledJobsOfTransfers.CurrentRow);
		CurrentRow.ModificationState = "Delete";
		CurrentRow.DisplayInTheList = False;
		Items.ScheduledJobsOfTransfers.RowFilter = New FixedStructure("DisplayInTheList", True);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CustomizeScheduleOfForecastIndicatorCalculation(Command)
	
	ScheduleDialog1 = New ScheduledJobDialog(ForecastCalculationSchedule);
	ScheduleDialog1.Show(New CallbackDescription("CustomizeScheduleOfForecastIndicatorCalculationCompletion", ThisObject, New Structure("ScheduleDialog1", ScheduleDialog1)));
	
EndProcedure

&AtClient
Procedure CustomizeScheduleOfForecastIndicatorCalculationCompletion(Schedule, AdditionalParameters) Export
    
    ScheduleDialog1 = AdditionalParameters.ScheduleDialog1;
    
    
    If Schedule <> Undefined Then
        
        If ForecastCalculationSchedule <> ScheduleDialog1.Schedule Then
            Modified = True;
            ForecastCalculationSchedule = ScheduleDialog1.Schedule;
            Items.ScheduleAsString.Title = String(ForecastCalculationSchedule);
        EndIf;
        
    EndIf;

EndProcedure

&AtClient
Procedure CustomizeScheduleOfPickingJobCreation(Command)
	ScheduleDialog1 = New ScheduledJobDialog(ScheduleOfPickingJobCreation);
	ScheduleDialog1.Show(New CallbackDescription("CustomizeScheduleOfPickingJobCreationCompletion", ThisObject, New Structure("ScheduleDialog1", ScheduleDialog1)));
EndProcedure

&AtClient
Procedure CustomizeScheduleOfPickingJobCreationCompletion(Schedule, AdditionalParameters) Export
    
    ScheduleDialog1 = AdditionalParameters.ScheduleDialog1;
    
    
    If Schedule <> Undefined Then
        
        If ScheduleOfPickingJobCreation <> ScheduleDialog1.Schedule Then
            Modified = True;
            ScheduleOfPickingJobCreation   						  	= ScheduleDialog1.Schedule;
            Items.ScheduleForCreatingLineSelectionTasks.Title  = String(ScheduleOfPickingJobCreation);
        EndIf;
        
    EndIf;

EndProcedure

#EndRegion

#Region Private

#Region NotificationsHandlers

&AtClient
Procedure EditingOfRoutineTaskForCreatingRecalculationsCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;  
	
	Action = "";
	Result.Property("Action",Action);
	If Action = "Cancel" Then
		// actions when closing the form on the "Cancel" button
		Return;
	ElsIf Action = "CloseAndSaveTheScheduledJob" Then
		// actions when closing the form on the "Close and save routine task" button
		Modified = True;
		
		ScheduledJobAction = "";
		Result.Property("ScheduledJobAction",ScheduledJobAction);
		If ScheduledJobAction = "Copy" Or ScheduledJobAction = "Add" Then
			RowInRoutineTasksTable = TableOfRoutineTasksForRecalculations.Add();
			RowInRoutineTasksTable.DisplayInTheList = True;
			RowInRoutineTasksTable.ModificationState = "Creating";
			RowInRoutineTasksTable.Id = New UUID("00000000-0000-0000-0000-000000000000");
		ElsIf ScheduledJobAction = "Edit" Then
			RowInRoutineTasksTable = Items.RecalculationScheduledJobs.CurrentData;
			RowInRoutineTasksTable.ModificationState = ?(RowInRoutineTasksTable.ModificationState = "Creating","Creating","Update");
		EndIf;
			
		Result.Property("JobSchedule",				RowInRoutineTasksTable.Schedule);
		Result.Property("IfThereAreErrorsRepeatThroughTheRoutineTask",	RowInRoutineTasksTable.RestartIntervalOnFailure);
		Result.Property("IfThereAreErrorsRepeatTheRoutineTask",		RowInRoutineTasksTable.RestartCountOnFailure);
		Result.Property("ScheduledJobDescription",				RowInRoutineTasksTable.Description);
		Result.Property("SettingsForCreatingRecalculations",					RowInRoutineTasksTable.SettingsForCreatingRecalculations);
		RowInRoutineTasksTable.SettingsForCreatingRecalculations.Insert("Warehouse", Record.Warehouse);
		RowInRoutineTasksTable.SettingsForCreatingRecalculations.Insert("Premise", Record.Premise);
	EndIf;
	
	UpdateInformationAboutStateOfRoutineTasksForCreatingRecalculations();
EndProcedure

&AtClient
Procedure EditingOfRoutineTaskForCreatingMovementsCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;  
	
	Action = "";
	Result.Property("Action",Action);
	If Action = "Cancel" Then
		// actions when closing the form on the "Cancel" button
		Return;
	ElsIf Action = "CloseAndSaveTheScheduledJob" Then
		// actions when closing the form on the "Close and save routine task" button
		Modified = True;
		
		ScheduledJobAction = "";
		Result.Property("ScheduledJobAction",ScheduledJobAction);
		If ScheduledJobAction = "Copy" Or ScheduledJobAction = "Add" Then
			RowInRoutineTasksTable = TableOfScheduledMovementTasks.Add();
			RowInRoutineTasksTable.DisplayInTheList = True;
			RowInRoutineTasksTable.ModificationState = "Creating";
			RowInRoutineTasksTable.Id = New UUID("00000000-0000-0000-0000-000000000000");
		ElsIf ScheduledJobAction = "Edit" Then
			RowInRoutineTasksTable = Items.ScheduledJobsOfTransfers.CurrentData;
			RowInRoutineTasksTable.ModificationState = 
				?(RowInRoutineTasksTable.ModificationState = "Creating", 
					"Creating", 
					"Update");
		EndIf;
			
		Result.Property("JobSchedule",				RowInRoutineTasksTable.Schedule);
		Result.Property("IfThereAreErrorsRepeatThroughTheRoutineTask",	RowInRoutineTasksTable.RestartIntervalOnFailure);
		Result.Property("IfThereAreErrorsRepeatTheRoutineTask",		RowInRoutineTasksTable.RestartCountOnFailure);
		Result.Property("ScheduledJobDescription",				RowInRoutineTasksTable.Description);
		Result.Property("SettingsForCreatingMoves",					RowInRoutineTasksTable.SettingsForCreatingMoves);
		RowInRoutineTasksTable.SettingsForCreatingMoves.Insert("Warehouse", Record.Warehouse);
		RowInRoutineTasksTable.SettingsForCreatingMoves.Insert("Premise", Record.Premise);
	EndIf;
	
	UpdateInformationAboutStateOfScheduledTasksForCreatingMoves();
EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Procedure SetAvailability(Form)
	Form.Items.NumberOfDaysOfAnalysis.Enabled              = Form.Record.ForecastPackageConsumption;
	Form.Items.MinimumProbabilityOfShipment.Enabled     = Form.Record.ForecastPackageConsumption;
	Form.Items.ServiceLevelOfClassXPackages.Enabled = Form.Record.ForecastPackageConsumption;
	Form.Items.ServiceLevelOfClassYPackages.Enabled = Form.Record.ForecastPackageConsumption;
	Form.Items.ServiceLevelOfClassZPackages.Enabled = Form.Record.ForecastPackageConsumption;
	
	Form.Items.CustomizeScheduleOfForecastIndicatorCalculation.Enabled        = Form.Record.ForecastPackageConsumption;
	Form.Items.CustomizeScheduleOfPickingJobCreation.Enabled    		= Form.Record.UseScheduledJobToCreatePickingJobs;
	Form.Items.AdditionalSettingsOfPickingJobCreation.Enabled					= Form.Record.UseScheduledJobToCreatePickingJobs;
	
	Form.Items.WarehouseZone.Enabled 				= Form.Record.ConfigureGenerationByWarehouseAreas = "ByASingleWarehouseZone";
	Form.Items.LimitationByVolume.Enabled 			= Form.Record.LimitByVolumeFilter;
	Form.Items.UnitOfMeasureForVolume.Enabled 		= Form.Record.LimitByVolumeFilter;
	Form.Items.LimitationByWeight.Enabled			= Form.Record.LimitByWeightFilter;
	Form.Items.UnitOfMeasureForWeight.Enabled			= Form.Record.LimitByWeightFilter;
	
	If Form.Record.ConfigureGenerationByWarehouseAreas = "GroupByWarehouseZones" Then
		Form.Items.RestrictionSettingsGroup.CurrentPage = Form.Items.PageLimitLabel;
	Else
		Form.Items.RestrictionSettingsGroup.CurrentPage = Form.Items.PageLimitCheckBoxes;
	EndIf;
	
	Form.Items.ScheduledJobsOfTransfers.RowFilter = New FixedStructure("DisplayInTheList", True);
	Form.Items.RecalculationScheduledJobs.RowFilter = New FixedStructure("DisplayInTheList", True);
	 
EndProcedure

&AtServer
Procedure SetDefaults()
	
	If Not ValueIsFilled(Record.WarehouseZoneFilter) Then
		Record.WarehouseZoneFilter = Catalogs.WarehouseZones.DefaultWorkArea(Record.Warehouse,Record.Premise);
	EndIf;
	
	If Not ValueIsFilled(Record.ConfigureGenerationByWarehouseAreas)
		Or Not WarehousesServer.UseWarehouseZones(Record.Warehouse, Record.Premise) Then
		Record.ConfigureGenerationByWarehouseAreas = "WithoutBreakdownByWarehouseZones";
	EndIf;
	
EndProcedure

&AtServer
Procedure WorkingSectionIsSelectedWhenServerChanges()
	FillInWorkAreaRestrictionsFilter();
	SetAvailability(ThisForm);
EndProcedure

&AtServer
Procedure FillInWorkAreaRestrictionsFilter()
	AttributesValues = Common.ObjectAttributesValues(Record.WarehouseZoneFilter,
	"LimitByWeight,LimitationByWeight,LimitByVolume,LimitationByVolume");
	
	Record.LimitByWeightFilter = AttributesValues.LimitByWeight;
	Record.LimitationByWeightFilter = AttributesValues.LimitationByWeight;
	Record.LimitByVolumeFilter = AttributesValues.LimitByVolume;
	Record.LimitationByVolumeFilter = AttributesValues.LimitationByVolume; 
EndProcedure

&AtClient
Procedure AddingChangingRoutineTaskForCreatingRecalculations(Action)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Record.Warehouse);
	FormParameters.Insert("Premise", Record.Premise);
	FormParameters.Insert("ScheduledJobAction",Action);
	CurrentData = Items.RecalculationScheduledJobs.CurrentData;
	If Action = "Edit" Or Action = "Copy" Then
		FormParameters.Insert("ScheduledJobDescription", 			CurrentData.Description);
		FormParameters.Insert("JobSchedule",				CurrentData.Schedule);
		FormParameters.Insert("IfThereAreErrorsRepeatTheRoutineTask", 		CurrentData.RestartCountOnFailure);
		FormParameters.Insert("IfThereAreErrorsRepeatThroughTheRoutineTask",	CurrentData.RestartIntervalOnFailure);
		If CurrentData.SettingsForCreatingRecalculations = Undefined Then
			FormParameters.Insert("SettingsForCreatingRecalculations", 
				New Structure("RecountByFilling,RecountBySpecialConditions,
					|DoubtfulBinRecount,RecountByFrequencySettings,RecalculationByCellsWithNegativeResiduals,Filter_Settings,
					|SplitByWorkArea,SplitByNumberOfCells,NumberOfCellsInTheTask"));
		Else
			FormParameters.Insert("SettingsForCreatingRecalculations", CurrentData.SettingsForCreatingRecalculations);
		EndIf;
	Else // "Add"
		ScheduledJobDescription = NStr("vi = 'Tạo nhiệm vụ kiểm đếm hàng hóa trong kho ""%WarehousePresentation_%""';
										|ru = 'Создание заданий на пересчет товаров на складе ""%WarehousePresentation_%""';
										|en = 'Create jobs for inventory count at warehouse ""%WarehousePresentation_%""'; fa = 'Create jobs for inventory count at warehouse ""%WarehousePresentation_%""';
										|it = 'Creazione di compiti per il ricalcolo delle merci in magazzino ""%WarehousePresentation_%""';
										|pl = 'Tworzenie zadań do przeliczania towarów w magazynie ""%WarehousePresentation_%""';
										|tr = 'Ambarda filtre için görevlerin oluşturulması ""%WarehousePresentation_%""'");
		ScheduledJobDescription = StrReplace(ScheduledJobDescription, "%WarehousePresentation_%" , GetWarehousePresentation(Record.Warehouse,
																														Record.Premise));
		FormParameters.Insert("ScheduledJobDescription", 			ScheduledJobDescription);
		FormParameters.Insert("JobSchedule",				New JobSchedule);
		FormParameters.Insert("IfThereAreErrorsRepeatTheRoutineTask", 		0);
		FormParameters.Insert("IfThereAreErrorsRepeatThroughTheRoutineTask",	0);
		FormParameters.Insert("SettingsForCreatingRecalculations", 					
			New Structure("RecountByFilling,RecountBySpecialConditions,
				|DoubtfulBinRecount,RecountByFrequencySettings,RecalculationByCellsWithNegativeResiduals,Filter_Settings,
				|SplitByWorkArea,SplitByNumberOfCells,NumberOfCellsInTheTask"));
	EndIf;
	
	NotificationEndOfEditingRoutineTaskForCreatingRecalculations = 
		New CallbackDescription("EditingOfRoutineTaskForCreatingRecalculationsCompletion", ThisForm);
		
	OpenForm("Document.InventoryRecount.Form.SettingsFormOfInventoryRecountJobsCreation", 
		FormParameters, 
		ThisForm,,,,
		NotificationEndOfEditingRoutineTaskForCreatingRecalculations, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AddingChangingRoutineTaskForCreatingMoves(Action)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Record.Warehouse);
	FormParameters.Insert("Premise", Record.Premise);
	FormParameters.Insert("ScheduledJobAction", Action);
	CurrentData = Items.ScheduledJobsOfTransfers.CurrentData;
	If Action = "Edit" Or Action = "Copy" Then
		FormParameters.Insert("ScheduledJobDescription", 			CurrentData.Description);
		FormParameters.Insert("JobSchedule",				CurrentData.Schedule);
		FormParameters.Insert("IfThereAreErrorsRepeatTheRoutineTask", 		CurrentData.RestartCountOnFailure);
		FormParameters.Insert("IfThereAreErrorsRepeatThroughTheRoutineTask",	CurrentData.RestartIntervalOnFailure);
		If CurrentData.SettingsForCreatingMoves = Undefined Then
			FormParameters.Insert("SettingsForCreatingMoves", 
				New Structure(
					"CustomizeGenerationByWorkAreas, LimitationByWeight,
					|LimitationByVolume, LimitByWeight, LimitByVolume, 
					|TaskCreationRule, WarehouseZone
					|"));
		Else
			FormParameters.Insert("SettingsForCreatingMoves", CurrentData.SettingsForCreatingMoves);
		EndIf;
	Else // "Add"
		
		FormParameters.Insert("ScheduledJobDescription", 			"");
		FormParameters.Insert("JobSchedule",				New JobSchedule);
		FormParameters.Insert("IfThereAreErrorsRepeatTheRoutineTask", 		0);
		FormParameters.Insert("IfThereAreErrorsRepeatThroughTheRoutineTask",	0);
		FormParameters.Insert("SettingsForCreatingMoves",
			New Structure(
					"CustomizeGenerationByWorkAreas, LimitationByWeight,
					|LimitationByVolume, LimitByWeight, LimitByVolume, 
					|TaskCreationRule, WarehouseZone,
					|"));
	EndIf;
	
	NotificationEndOfEditingRoutineTaskForCreatingMovements = 
		New CallbackDescription("EditingOfRoutineTaskForCreatingMovementsCompletion", ThisForm);
		
	OpenForm("InformationRegister.SettingsOfBinLocationWarehouses.Form.SettingsFormOfWarehouseTransferGoodsJobsCreation", 
		FormParameters, 
		ThisForm,,,,
		NotificationEndOfEditingRoutineTaskForCreatingMovements, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServerNoContext
Function GetWarehousePresentation(Warehouse, Premise = "")
	Return WarehousesServer.GetWarehousePresentation(Warehouse, Premise);
EndFunction

&AtServer
Procedure UpdateInformationAboutStateOfRoutineTasksForCreatingRecalculations()
	
	For Each RowInRoutineTasksTable In TableOfRoutineTasksForRecalculations Do
		If RowInRoutineTasksTable.ModificationState = "Update" 
			Or RowInRoutineTasksTable.ModificationState = "" Then
			UpdateInformationAboutStateOfRoutineTaskForCreatingRecalculations(
				RowInRoutineTasksTable.Id,
				RowInRoutineTasksTable.EndDate, 
				RowInRoutineTasksTable.ExecutionState);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateInformationAboutStateOfScheduledTasksForCreatingMoves()
	
	For Each RowInRoutineTasksTable In TableOfScheduledMovementTasks Do
		If RowInRoutineTasksTable.ModificationState = "Update" 
			Or RowInRoutineTasksTable.ModificationState = "" Then
			UpdateInformationAboutStateOfScheduledTaskForCreatingMoves(
				RowInRoutineTasksTable.Id,
				RowInRoutineTasksTable.EndDate, 
				RowInRoutineTasksTable.ExecutionState);
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure UpdateInformationAboutStateOfRoutineTaskForCreatingRecalculations(Val JobID, EndDate, ExecutionState, Val PrivilegedModeNeeded = True)
	
	If PrivilegedModeNeeded Then
		SetPrivilegedMode(True);
	EndIf;
	
	CurRoutineAssignment = ScheduledJobsServer.Job(JobID);
	LastBackgroundJobProperties = TMCommonUse.GetStateOfLastJob(CurRoutineAssignment);
	
	If LastBackgroundJobProperties = Undefined Then	
		TextUndefined 	= ScheduledJobsInternal.TextUndefined();
		EndDate       = TextUndefined;
		ExecutionState = TextUndefined;	
	Else
		EndDate       = ?(ValueIsFilled(LastBackgroundJobProperties.CompletedOn), LastBackgroundJobProperties.CompletedOn, "<>");
		ExecutionState = String(LastBackgroundJobProperties.State);		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure UpdateInformationAboutStateOfScheduledTaskForCreatingMoves(Val JobID, EndDate, ExecutionState, Val PrivilegedModeNeeded = True)
	
	If PrivilegedModeNeeded Then
		SetPrivilegedMode(True);
	EndIf;
	
	CurRoutineAssignment = ScheduledJobsServer.Job(JobID);
	LastBackgroundJobProperties = TMCommonUse.GetStateOfLastJob(CurRoutineAssignment);
	
	If LastBackgroundJobProperties = Undefined Then	
		TextUndefined 	= ScheduledJobsInternal.TextUndefined();
		EndDate       = TextUndefined;
		ExecutionState = TextUndefined;	
	Else
		EndDate       = ?(ValueIsFilled(LastBackgroundJobProperties.CompletedOn), LastBackgroundJobProperties.CompletedOn, "<>");
		ExecutionState = String(LastBackgroundJobProperties.State);		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ScheduledJobDescription(JobParameters, JobType = "SettingRecalculation")
	
	JobDescription = "";
	
	If JobType = "SettingRecalculation" Then
		JobDescription = NStr("vi = 'Tạo nhiệm vụ kiểm đếm hàng hóa trong kho ""%WarehousePresentation_%""';
								|ru = 'Создание заданий на пересчет товаров на складе ""%WarehousePresentation_%""';
								|en = 'Create jobs for inventory count at warehouse ""%WarehousePresentation_%""'; fa = 'Create jobs for inventory count at warehouse ""%WarehousePresentation_%""';
								|it = 'Creazione di compiti per il ricalcolo delle merci in magazzino ""%WarehousePresentation_%""';
								|pl = 'Tworzenie zadań do przeliczania towarów w magazynie ""%WarehousePresentation_%""';
								|tr = 'Ambarda filtre için görevlerin oluşturulması ""%WarehousePresentation_%""'");
		JobDescription = StrReplace(JobDescription,
											"%WarehousePresentation_%",
											GetWarehousePresentation(JobParameters.Warehouse, JobParameters.Premise));
	Else
		JobDescription = NStr("vi = 'Tạo nhiệm vụ điều chuyển ""%Rule%"" đối với kho ""%WarehousePresentation_%""';
								|ru = 'Создание заданий на перемещение ""%Rule%"" для склада ""%WarehousePresentation_%""';
								|en = 'Create transfer jobs ""%Rule%"" for warehouse ""%WarehousePresentation_%""'; fa = 'Create transfer jobs ""%Rule%"" for warehouse ""%WarehousePresentation_%""';
								|it = 'Creazione compiti per lo spostamento ""%Rule%"" per il magazzino ""%WarehousePresentation_%""';
								|pl = 'Tworzenie zadań przemieszczenia ""%Rule%"" na magazyn ""%WarehousePresentation_%""';
								|tr = 'Ambar ""%WarehousePresentation_%"" için transfer görevleri ""%Rule%"" oluştur'");
		JobDescription = StrReplace(JobDescription,
											"%Rule%",
											GenerateRuleNameForRegTask(JobParameters.TaskCreationRule));
		JobDescription = StrReplace(JobDescription,
											"%WarehousePresentation_%",
											GetWarehousePresentation(JobParameters.Warehouse, JobParameters.Premise));
	EndIf;
	
	Return JobDescription;
	
EndFunction

&AtServerNoContext
Function GenerateRuleNameForRegTask(TaskCreationRule)
	
	If TaskCreationRule = Enums.TransferJobCreationRules.TransferByPlacementRulesForGoodsAssigned Then
		Return NStr("vi = 'Xếp vào hàng hóa đặt riêng';
					|ru = 'Размещение обособленных товаров';
					|en = 'Put-away assigned inventory'; fa = 'Put-away assigned inventory';
					|it = 'Posizionamento delle merci separate';
					|pl = 'Rozlokowanie oddzielnych towarów';
					|tr = 'Ayrıştırılmış ürünlerin yerleştirilmesi'");
	ElsIf TaskCreationRule = Enums.TransferJobCreationRules.ReplenishmentOfQuickAccessAreas Then
		Return NStr("vi = 'Thêm khu vực lọc nhanh';
					|ru = 'Подпитка зон быстрого отбора';
					|en = 'Replenishment of quick filter areas'; fa = 'تکمیل ناحیه‌های فیلتر سریع';
					|it = 'Sovvenzionamento delle zone di selezione';
					|pl = 'Podładowanie stref szybkiego filtru';
					|tr = 'Hızlı filtre stok yenileme alanı'");
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#EndRegion
