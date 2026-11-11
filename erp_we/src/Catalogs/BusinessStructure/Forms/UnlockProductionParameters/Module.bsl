#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	If GetFunctionalOption("ComplexAutomation") Then
		
		Items.ProductionWithoutOrderTitle.Title = NStr("vi = 'Sản xuất';
														|ru = 'Производство';
														|en = 'Production'; fa = 'تولید';
														|it = 'Produzione';
														|pl = 'Production';
														|tr = 'Üretim'");
		
		Items.OptionOfWritingOffReleaseCostsWithoutOrdersTitle.Title =
			NStr("vi = 'Phương án ghi giảm chi phí xuất xưởng';
				|ru = 'Вариант списания затрат на выпуск';
				|en = 'Option for writing off release costs'; fa = 'Option for writing off release costs';
				|it = 'Opzione di storno dei costi per la produzione';
				|pl = 'Wariant spisania kosztów na produkcję';
				|tr = 'Üretim için giderleştirme seçeneği'");
		
	EndIf;
	
	FillInCheckedParameters();
	
	VisibilityManagement();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = ObjectAttributesToLock();
	Close(Result);

EndProcedure

&AtClient
Procedure CheckObjectUsage(Command)
	
	Result = CheckObjectUsageOnServer();
	
	If Not Result.Status = "Completed2" Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("CheckObjectUsageCompletion", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	Else
		ProcessVerificationResultATServer(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CheckObjectUsageCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessVerificationResultATServer(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtServer
Function CheckObjectUsageOnServer()
	
	JobParameters = New Structure;
	JobParameters.Insert("Object", Parameters.Object);
	
	Result = New Structure("JobCompleted", True);
	
	JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểm tra việc sử dụng đối tượng %1';
				|ru = 'Проверка использования объекта %1';
				|en = 'Checking usage of object %1'; fa = 'Checking usage of object %1';
				|it = 'Verifica dell''utilizzo dell''oggetto %1';
				|pl = 'Weryfikacja wykorzystania obiektu %1';
				|tr = '%1 nesnesinin kullanım kontrolü'"),
			Parameters.Object);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	
	Result = TimeConsumingOperations.ExecuteInBackground(
			"Catalogs.BusinessStructure.CheckUseOfProductionParameters",
			JobParameters,
			ExecutionParameters);
	Return Result;
	
EndFunction

&AtClient
Procedure ProcessVerificationResultATServer(StorageAddress)
	
	CheckResult = GetFromTempStorage(StorageAddress);
	
	ObjectUsed = False;
	
	// Division-dispatcher
	If CheckDispatcherDepartment Then
		
		Items.DivisionManagerVerificationFailed.Visible = False;
		Items.DivisionManagerParameterIsNotUsed.Visible = Not CheckResult.UsedAsDispatcher;
		Items.DivisionManagerParameterIsUsed.Visible = CheckResult.UsedAsDispatcher;
		Items.DispatcherDepartmentParameterDescriptionUsed.Visible = CheckResult.UsedAsDispatcher;
		
		ObjectUsed = ?(CheckResult.UsedAsDispatcher, True, ObjectUsed);
		
	EndIf;
	
	// Custom production
	If CheckProductionByOrder Then
		
		Items.ProductionOnOrderVerificationFailed.Visible = False;
		Items.ProductionByOrderParameterIsNotUsed.Visible = Not CheckResult.UsedForCustomProduction;
		Items.ProductionByOrderParameterUsed.Visible = CheckResult.UsedForCustomProduction;
		Items.ProductionByOrderParameterDescriptionUsed.Visible = CheckResult.UsedForCustomProduction;
		
		ObjectUsed = ?(CheckResult.UsedForCustomProduction, True, ObjectUsed);
		
	EndIf;
	
	// the planning interval
	If CheckPlanningInterval Then
		
		Items.SchedulingIntervalValidationFailed.Visible = False;
		Items.SchedulingIntervalParameterIsNotUsed.Visible = Not CheckResult.SchedulingIntervalIsUsed;
		Items.SchedulingIntervalParameterUsed.Visible = CheckResult.SchedulingIntervalIsUsed;
		Items.PlanningIntervalParameterDescriptionUsed.Visible = CheckResult.SchedulingIntervalIsUsed;
		
		ObjectUsed = ?(CheckResult.SchedulingIntervalIsUsed, True, ObjectUsed);
		
	EndIf;
	
	// Operational stage management
	If CheckOperationStageManagement Then
		
		Items.OperationalStageManagementVerificationFailed.Visible = False;
		Items.OperationalStageManagementThisParameterIsNotUsed.Visible = Not CheckResult.PostOperativeStageManagementIsUsed;
		Items.OperationalManagementOfStagesTheParameterIsUsed.Visible = CheckResult.PostOperativeStageManagementIsUsed;
		Items.StageOperationManagementParameterDescriptionUsed.Visible = CheckResult.PostOperativeStageManagementIsUsed;
		
		ObjectUsed = ?(CheckResult.PostOperativeStageManagementIsUsed, True, ObjectUsed);
		
	EndIf;
	
	// Shift tasks
	If CheckShiftJobUsage Then
		
		Items.ShiftTasksCheckFailed.Visible = False;
		Items.ChangeableTasksTheParameterIsNotUsed.Visible = Not CheckResult.ShiftJobsAreUsed;
		Items.ChangeableTasksTheParameterIsUsed.Visible = CheckResult.ShiftJobsAreUsed;
		Items.ChangeableTasksParameterUsedDescription.Visible = CheckResult.ShiftJobsAreUsed;
		
		ObjectUsed = ?(CheckResult.ShiftJobsAreUsed, True, ObjectUsed);
		
	EndIf;
	
	
	// Production without orders
	If CheckProductionWithoutOrder Then
		
		Items.ProductionWithoutOrderVerificationFailed.Visible = False;
		
		Items.ProductionWithoutOrderParameterIsNotUsed.Visible =
			Not CheckResult.UsedForProductionWithoutOrders;
			
		Items.ProductionWithoutOrderParameterUsed.Visible =
			CheckResult.UsedForProductionWithoutOrders;
			
		Items.ProductionWithoutOrderParameterDescriptionUsed.Visible =
			CheckResult.UsedForProductionWithoutOrders;
			
		ObjectUsed = ?(CheckResult.UsedForProductionWithoutOrders, True, ObjectUsed);
		
	EndIf;
	
	// The option of writing off the costs of issues without orders
	If CheckOptionOfWritingOffReleaseCostsWithoutOrders Then
		
		Items.OptionToWriteOffTheCostOfIssuesWithoutOrdersCheckFailed.Visible = False;
		
		Items.OptionToWriteOffTheCostOfIssuesWithoutOrdersTheParameterIsNotUsed.Visible =
			Not CheckResult.UsedForProductionWithoutOrders;
			
		Items.OptionToWriteOffTheCostOfIssuesWithoutOrdersTheParameterIsUsed.Visible =
			CheckResult.UsedForProductionWithoutOrders;
			
		Items.OptionOfWritingOffReleaseCostsWithoutOrdersParameterDescriptionUsed.Visible =
			CheckResult.UsedForProductionWithoutOrders;
			
		ObjectUsed = ?(CheckResult.UsedForProductionWithoutOrders, True, ObjectUsed);
		
	EndIf;
	
	// Test result
	If ObjectUsed Then
		Items.ObjectIsUsedPagesGroup.CurrentPage = Items.ObjectIsUsedObjectIsUsedGroup;
	Else
		Items.ObjectIsUsedPagesGroup.CurrentPage = Items.ObjectIsUsedObjectIsNotUsedGroup;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ObjectAttributesToLock()
	
	Attributes = Catalogs.BusinessStructure.GetObjectAttributesToLock();
	
	IndexOf = 0;
	For Each Attribute In Attributes Do
		
		DelimeterChar = StrFind(Attribute, ";");
		If Not DelimeterChar = 0 Then
			Attributes[IndexOf] = TrimAll(Left(Attribute, DelimeterChar-1));
		EndIf;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	Return Attributes;
	
EndFunction

&AtServer
Procedure FillInCheckedParameters()
	
	ThisIsCA = GetFunctionalOption("ComplexAutomation");
	
	CheckDispatcherDepartment = Not ThisIsCA;
	CheckProductionByOrder = Not ThisIsCA;
	CheckPlanningInterval = Not ThisIsCA;
	SubsystemSettingsProduction = ProductionServer.SubsystemSettingsProduction();
	

	ExecuteCheck = SubsystemSettingsProduction.ProductionIsUsed22;
		
	CheckOperationStageManagement = ExecuteCheck;
	CheckShiftJobUsage = ExecuteCheck;
EndProcedure

&AtServer
Procedure VisibilityManagement()
	
	Items.GroupDivisionDispatcher.Visible = CheckDispatcherDepartment;
	Items.CustomProductionGroup.Visible = CheckProductionByOrder;
	Items.PlanningIntervalGroup.Visible = CheckPlanningInterval;
	Items.RouteListManagementGroup.Visible = CheckRouteSheetManagement;
	Items.GroupOperationManagementMethod.Visible = CheckMethodOfOperationManagement;
	Items.GroupProductionWithoutAnOrder.Visible = CheckProductionWithoutOrder;
	Items.GroupOptionForWritingOffCostsForIssuesWithoutOrders.Visible = CheckOptionOfWritingOffReleaseCostsWithoutOrders;
	Items.OperationalStageManagementGroup.Visible = CheckOperationStageManagement;
	Items.ThePanelReplacementJobs.Visible = CheckShiftJobUsage;
	
EndProcedure

#EndRegion
