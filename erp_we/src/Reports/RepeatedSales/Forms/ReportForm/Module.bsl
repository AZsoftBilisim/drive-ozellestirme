#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	RestoreSettings();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		ShouldSaveSettings();
	EndIf;

	If ValueIsFilled(JobID) Then
		CancelBackgroundTask(JobID);
		JobID = Undefined;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManagerOnChange(Item)
	
	ManagerUsage = True;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)

	OrganizationUsage = True;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure BeginningDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodOfUse = True;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure EndingDateOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PeriodOfUse = True;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure ManagerUsageOnChange(Item)
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure OrganizationUsageOnChange(Item)
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure PeriodOfUseOnChange(Item)
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");

EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;

	Details.Insert("Color", Item.CurrentArea.BackColor);
	OpenForm("Report.RepeatedSales.Form.DrillDownForm",Details,ThisForm);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Settings(Command)
	
	AttributesToSaveNames =
		"Organization,OrganizationUsage,
		|Manager,ManagerUsage,
		|StartDate,EndDate,PeriodOfUse,
		|ActiveLoyalTo,ActiveFaithfulFrom,ActiveUpTo,ActiveFrom,
		|ActiveProspectiveUpTo,ActiveProspectiveClients,
		|FallingAsleepFaithfulTo,FallingAsleepFaithfulFrom,FallingAsleepBefore,FallingAsleepFrom,
		|FallingAsleepPromisingUpTo,FallingAsleepPerspectiveFrom,
		|CustomersNumbersPercentages,DisplayLabelsForArrows,
		|Products,NomenclatureUsage,DisplayArrows,
		|PurchasesAreCorrect,NewPurchases,PurchasesArePromisingUpTo,ProspectivePurchasesFrom,
		|ExtendedMode,Potential,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage,
		|Sleepers,SleepingFaithful,SleepingProspects";

	AddlParameters = New Structure(AttributesToSaveNames);
	FillPropertyValues(AddlParameters, ThisForm);

	OpenForm("Report.RepeatedSales.Form.SettingsForm",AddlParameters,ThisForm,,,, 
		New CallbackDescription("SettingsCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SettingsCompletion(ExecutionResult, AdditionalParameters) Export
   	
	If ExecutionResult = Undefined Then
    	Return;
	EndIf;
	
	SettingsChanged_1 = False;
	If TypeOf(ExecutionResult) = Type("Structure") Then
		For Each KeyValue In ExecutionResult Do
			If ThisForm[KeyValue.Key] <> KeyValue.Value Then
				SettingsChanged_1 = True;
			EndIf;
			ThisForm[KeyValue.Key] = KeyValue.Value;
      	EndDo;
  	EndIf;
	
	If SettingsChanged_1 Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	EndIf;

EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ValueSelected) Then
		PeriodOfUse = False;
		StartDate = Undefined;
		EndDate = Undefined;
	Else
		
	Period = ValueSelected;
	StartDate = Period.StartDate;
	EndDate = Period.EndDate;

	PeriodOfUse = True;
EndIf;

	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "Irrelevance");
	
EndProcedure

&AtClient
Procedure GenerateReport(Command)
	
	CheckSelections();

	ExecutionResult = Segments();
	
	If Not ExecutionResult.Status = "Completed2" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("GenerateAlertReport", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "ReportGeneration");
		
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RestoreSettings()
	
	SettingsValue = Common.SystemSettingsStorageLoad(
		"Report.RepeatedSales", "CurrentSettings");

	If TypeOf(SettingsValue) = Type("Structure") Then
		FillPropertyValues(ThisForm, SettingsValue);
	Else
		FillInDefaultValues()
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()

	AttributesToSaveNames ="Organization,OrganizationUsage,
		|Manager,ManagerUsage,Period,
		|StartDate,EndDate,PeriodOfUse,
		|ActiveLoyalTo,ActiveUpTo,ActiveProspectiveUpTo,
		|FallingAsleepFaithfulTo,FallingAsleepFaithfulFrom,FallingAsleepBefore,FallingAsleepFrom,
		|FallingAsleepPromisingUpTo,FallingAsleepPerspectiveFrom,
		|CustomersNumbersPercentages,DisplayLabelsForArrows,
		|Products,NomenclatureUsage,DisplayArrows,
		|PurchasesAreCorrect,NewPurchases,PurchasesArePromisingUpTo,ProspectivePurchasesFrom,
		|ExtendedMode,Potential,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage,
		|Sleepers,SleepingFaithful,SleepingProspects";

	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisForm);

	Common.SystemSettingsStorageSave("Report.RepeatedSales", "CurrentSettings", Settings); 
	
EndProcedure

&AtServer
Procedure FillInDefaultValues()

	NewPurchases = 1;
	ProspectivePurchasesFrom = 2;
	PurchasesArePromisingUpTo = 7;
	PurchasesAreCorrect = 7;
	
	ActiveUpTo = 30;
	ActiveProspectiveUpTo = 30;
	ActiveLoyalTo = 30;

	FallingAsleepFrom = 30;
	FallingAsleepBefore = 50;
	FallingAsleepPerspectiveFrom = 30;
	FallingAsleepPromisingUpTo = 50;
	FallingAsleepFaithfulFrom = 30;
	FallingAsleepFaithfulTo = 50;
	
	Sleepers = 50;
	SleepingProspects = 50;
	SleepingFaithful = 50;

	DisplayArrows = True;
	DisplayLabelsForArrows = "Interests";
	
	Potential = 12;
	
EndProcedure

&AtClient
Procedure CheckSelections()
	
	If PeriodOfUse = True Then
		If Not ValueIsFilled(StartDate) Or Not ValueIsFilled(EndDate) Then
			PeriodOfUse = False;
		EndIf;
	EndIf;
	
	If OrganizationUsage = True Then
		If Not ValueIsFilled(Organization) Then
			OrganizationUsage = False;
		EndIf;
	EndIf;
	
	If ManagerUsage = True Then
		If Not ValueIsFilled(Manager) Then
			ManagerUsage = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function Segments()
	
	If ValueIsFilled(JobID) Then
		CancelBackgroundTask(JobID);
		JobID = Undefined;
	EndIf;

	//filling in the decryption parameters
	SelectionParameterNames = 
		"Organization,OrganizationUsage,
		|Manager,ManagerUsage,
		|PeriodOfUse,
		|Products,NomenclatureUsage,,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage,
		|PurchasesArePromisingUpTo,ActiveUpTo,FallingAsleepBefore,
		|ActiveProspectiveUpTo,FallingAsleepPromisingUpTo,
		|ActiveLoyalTo,FallingAsleepFaithfulTo,PurchasesAreCorrect";

	Filters = New Structure(SelectionParameterNames);
	FillPropertyValues(Filters, ThisForm);
	Filters.Insert("BeginningDateOfPeriod",StartDate);
	Filters.Insert("EndingDateOfPeriod",EndDate);
	
	If Not CheckFilling() Then
		Return New Structure("Status", "Completed2");
	EndIf;

	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"Reports.RepeatedSales.FillCustomerSegments", 
		Filters,
		BackgroundExecutionParameters);
	
	JobID = ExecutionResult.JobID;
	StorageAddress       = ExecutionResult.ResultAddress;
	
	If ExecutionResult.Status = "Completed2" Then
		OutputSegments();
	EndIf;

	Return ExecutionResult;

EndFunction

&AtClient
Procedure GenerateAlertReport(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		OutputSegments();
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CancelBackgroundTask(JobID)
	TimeConsumingOperations.CancelJobExecution(JobID);
EndProcedure

&AtServer
Procedure OutputSegments()
	
	ExecutionResult = GetFromTempStorage(StorageAddress);
	DeleteFromTempStorage(StorageAddress);
	JobID = Undefined;

	SelectionParameterNames = 
		"Organization,OrganizationUsage,
		|Manager,ManagerUsage,
		|StartDate,EndDate,PeriodOfUse,
		|Products,NomenclatureUsage,,
		|CustomerSegment,CustomerSegmentUsage,
		|ProductSegment,ItemSegmentUsage,
		|AmountOfPurchases,PurchaseAmountUsage";

	Filters = New Structure(SelectionParameterNames);
	FillPropertyValues(Filters, ThisForm);
			
	//Output segments	
	Template = Reports.RepeatedSales.GetTemplate("CustomerClassification");
	
	ScopeOfApplication = Template.GetArea("Active_1");
	AreaFallingAsleep = Template.GetArea("FallingAsleep");
	SleepingArea = Template.GetArea("Sleepers");
	
	//Filling in the parameters	
	
	//Fill in and/or calculate the percentage of transitions
	If DisplayLabelsForArrows = "Interests" Or DisplayLabelsForArrows = "PercentNumbers" Then
		
		If (ExecutionResult.ActiveNewBeginnings.Count()+ExecutionResult.FirstPurchase.Count()) <> 0 Then  
			PercentageOfTransitions = Format(Round(100*ExecutionResult.APTransition/(ExecutionResult.ActiveNewBeginnings.Count()+ExecutionResult.FirstPurchase.Count())), NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																												|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																												|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																												|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																												|pl = 'NFD=0; NZ=0%; NF=N%';
																																												|tr = 'NFD=0; NZ=0%; NF=N%'"));
			PercentageOfZnTraffic = Format(Round(100*ExecutionResult.ZNTransition/(ExecutionResult.ActiveNewBeginnings.Count()+ExecutionResult.FirstPurchase.Count())),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																											|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																											|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																											|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																											|pl = 'NFD=0; NZ=0%; NF=N%';
																																											|tr = 'NFD=0; NZ=0%; NF=N%'"));
		Else
			PercentageOfTransitions = "0%";
			PercentageOfZnTraffic = "0%";
		EndIf;
		
		If (ExecutionResult.FallingAsleepNewBeginnings.Count()+ExecutionResult.ZNTransition) <> 0 Then  	
			PercentageTransitionCH = Format(Round(100*ExecutionResult.TransitionCH/(ExecutionResult.FallingAsleepNewBeginnings.Count()+ExecutionResult.ZNTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																											|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																											|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																											|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																											|pl = 'NFD=0; NZ=0%; NF=N%';
																																											|tr = 'NFD=0; NZ=0%; NF=N%'"));	
			PercentageOfTransitions_1 = Format(Round(100*ExecutionResult.ZNAPTransition/(ExecutionResult.FallingAsleepNewBeginnings.Count()+ExecutionResult.ZNTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																												|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																												|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																												|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																												|pl = 'NFD=0; NZ=0%; NF=N%';
																																												|tr = 'NFD=0; NZ=0%; NF=N%'"));	
		Else
			PercentageTransitionCH = "0%";
			PercentageOfTransitions_1 = "0%";
		EndIf;
		
		If (ExecutionResult.SleepingNewBeginnings.Count()+ExecutionResult.TransitionCH)<> 0 Then 
			PercentageTransitionSnap = Format(Round(100*ExecutionResult.SNAPTransition/(ExecutionResult.SleepingNewBeginnings.Count()+ExecutionResult.TransitionCH)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																											|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																											|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																											|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																											|pl = 'NFD=0; NZ=0%; NF=N%';
																																											|tr = 'NFD=0; NZ=0%; NF=N%'"));
		Else
			PercentageTransitionSnap = "0%";
		EndIf;
		
		If (ExecutionResult.ActivePromisingCompanies.Count()+ExecutionResult.APTransition+ExecutionResult.ZNAPTransition+ExecutionResult.SNAPTransition+ExecutionResult.PoTransition_) <> 0 Then
			PercentageOfTraffic = Format(Round(100*ExecutionResult.TransitionAB/(ExecutionResult.ActivePromisingCompanies.Count()
				+ ExecutionResult.APTransition+ExecutionResult.ZNAPTransition+ExecutionResult.SNAPTransition+ExecutionResult.PoTransition_)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																					|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																					|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																					|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																					|pl = 'NFD=0; NZ=0%; NF=N%';
																																					|tr = 'NFD=0; NZ=0%; NF=N%'"));	
			PercentageOfPOTraffic = Format(Round(100*ExecutionResult.POTransition/(ExecutionResult.ActivePromisingCompanies.Count()
				+ ExecutionResult.APTransition+ExecutionResult.ZNAPTransition+ExecutionResult.SNAPTransition+ExecutionResult.PoTransition_)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																					|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																					|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																					|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																					|pl = 'NFD=0; NZ=0%; NF=N%';
																																					|tr = 'NFD=0; NZ=0%; NF=N%'"));	
		Else
			PercentageOfTraffic = "0%";
			PercentageOfPOTraffic = "0%";
		EndIf;
		
		If (ExecutionResult.FallingAsleepPromisingStart.Count()+ExecutionResult.POTransition+ExecutionResult.SPAPTransition) <> 0 Then
			PercentageOfTransitions_3 = Format(Round(100*ExecutionResult.SPTransition/(ExecutionResult.FallingAsleepPromisingStart.Count()+ExecutionResult.POTransition+ExecutionResult.SPAPTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																																				|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																																				|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																																				|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																																				|pl = 'NFD=0; NZ=0%; NF=N%';
																																																				|tr = 'NFD=0; NZ=0%; NF=N%'"));
			PercentageOfPOTraffic_ = Format(Round(100*ExecutionResult.PoTransition_/(ExecutionResult.FallingAsleepPromisingStart.Count()+ExecutionResult.POTransition+ExecutionResult.SPAPTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																																			|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																																			|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																																			|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																																			|pl = 'NFD=0; NZ=0%; NF=N%';
																																																			|tr = 'NFD=0; NZ=0%; NF=N%'"));
			PercentageOfZpavTraffic = Format(Round(100*ExecutionResult.ZPAVTransition/(ExecutionResult.FallingAsleepPromisingStart.Count()+ExecutionResult.POTransition+ExecutionResult.SPAPTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																																				|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																																				|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																																				|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																																				|pl = 'NFD=0; NZ=0%; NF=N%';
																																																				|tr = 'NFD=0; NZ=0%; NF=N%'"));
		Else
			PercentageOfTransitions_3 = "0%";
			PercentageOfPOTraffic_ = "0%";
			PercentageOfZpavTraffic = "0%";
		EndIf;
		
		If (ExecutionResult.SleepingProspectsStartList.Count()+ExecutionResult.SPTransition) <> 0 Then 
			PercentageOfSPAPTraffic = Format(Round(100*ExecutionResult.SPAPTransition/(ExecutionResult.SleepingProspectsStartList.Count()+ExecutionResult.SPTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																												|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																												|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																												|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																												|pl = 'NFD=0; NZ=0%; NF=N%';
																																												|tr = 'NFD=0; NZ=0%; NF=N%'"));
			PercentageTransitionSPAV = Format(Round(100*ExecutionResult.SPAVTransition/(ExecutionResult.SleepingProspectsStartList.Count()+ExecutionResult.SPTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																												|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																												|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																												|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																												|pl = 'NFD=0; NZ=0%; NF=N%';
																																												|tr = 'NFD=0; NZ=0%; NF=N%'"));
		Else
			PercentageOfSPAPTraffic = "0%";
			PercentageTransitionSPAV = "0%";
		EndIf;
		
		If (ExecutionResult.ActiveLoyalFriends.Count()+ExecutionResult.TransitionAB+ExecutionResult.ZPAVTransition+ExecutionResult.SPAVTransition+ExecutionResult.ZVAVTransition) <> 0 Then 
			PercentageOfTransitions_ = Format(Round(100*ExecutionResult.ZvTransition/(ExecutionResult.ActiveLoyalFriends.Count()
				+ ExecutionResult.TransitionAB+ExecutionResult.ZPAVTransition+ExecutionResult.SPAVTransition+ExecutionResult.ZVAVTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																					|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																					|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																					|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																					|pl = 'NFD=0; NZ=0%; NF=N%';
																																					|tr = 'NFD=0; NZ=0%; NF=N%'"));	
		Else
			PercentageOfTransitions_ = "0%";	
		EndIf;
		
		If (ExecutionResult.FallingAsleepFaithfulBeginnings.Count()+ExecutionResult.ZvTransition+ExecutionResult.SVAVTransition) <> 0 Then  
			PercentageOfTransitions_2 = Format(Round(100*ExecutionResult.SVTransition/(ExecutionResult.FallingAsleepFaithfulBeginnings.Count()
				+ ExecutionResult.ZvTransition+ExecutionResult.SVAVTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																					|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																					|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																					|it = 'ЧФD=0; ЧН=0%; NF=N%';
																					|pl = 'NFD=0; NZ=0%; NF=N%';
																					|tr = 'NFD=0; NZ=0%; NF=N%'"));
			PercentageOfCallTransitions = Format(Round(100*ExecutionResult.ZVAVTransition/(ExecutionResult.FallingAsleepFaithfulBeginnings.Count()
				+ ExecutionResult.ZvTransition+ExecutionResult.SVAVTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																					|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																					|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																					|it = 'ЧФD=0; ЧН=0%; NF=N%';
																					|pl = 'NFD=0; NZ=0%; NF=N%';
																					|tr = 'NFD=0; NZ=0%; NF=N%'"));
		Else
			PercentageOfTransitions_2 = "0%";
			PercentageOfCallTransitions = "0%";
		EndIf;
		
		If (ExecutionResult.SleepingFaithfulListBeginning.Count()+ExecutionResult.SVTransition) <> 0 Then	
			PercentageTransitionSVAV = Format(Round(100*ExecutionResult.SVAVTransition/(ExecutionResult.SleepingFaithfulListBeginning.Count()+ExecutionResult.SVTransition)),NStr("vi = 'ЧФD=0; ЧН=0%; NF=Ч%';
																																													|ru = 'ЧДЦ=0; ЧН=0%; ЧФ=Ч%';
																																													|en = 'NFD=0; NZ=0%; NF=N%'; fa = 'NFD=0; NZ=0 درصد; NF=N درصد';
																																													|it = 'ЧФD=0; ЧН=0%; NF=N%';
																																													|pl = 'NFD=0; NZ=0%; NF=N%';
																																													|tr = 'NFD=0; NZ=0%; NF=N%'"));
		Else
			PercentageTransitionSVAV = "0%";
		EndIf;
		
		If DisplayLabelsForArrows = "PercentNumbers" Then
			
			ScopeOfApplication.Parameters.APTransition=String(ExecutionResult.APTransition) + " (" + String(PercentageOfTransitions) + ")";
			ScopeOfApplication.Parameters.TransitionAB=String(ExecutionResult.TransitionAB) + " (" + String(PercentageOfTraffic) + ")";
			
			AreaFallingAsleep.Parameters.ZNTransition = String(ExecutionResult.ZNTransition) + " (" + String(PercentageOfZnTraffic) + ")";
			AreaFallingAsleep.Parameters.POTransition = String(ExecutionResult.POTransition) + " (" + String(PercentageOfPOTraffic) + ")";
		
			SleepingArea.Parameters.TransitionCH = String(ExecutionResult.TransitionCH) + " (" + String(PercentageTransitionCH) + ")";
			SleepingArea.Parameters.SPTransition = String(ExecutionResult.SPTransition) + " (" + String(PercentageOfTransitions_3) + ")";
			
			AreaFallingAsleep.Parameters.ZvTransition = String(ExecutionResult.ZvTransition) + " (" + String(PercentageOfTransitions_) + ")";
			SleepingArea.Parameters.SVTransition = String(ExecutionResult.SVTransition) + " (" + String(PercentageOfTransitions_2) + ")";	
			
			//Up arrows
			SleepingArea.Parameters.SNAPTransition = String(ExecutionResult.SNAPTransition) + " (" + String(PercentageTransitionSnap) + ")";
			AreaFallingAsleep.Parameters.ZNAPTransition = String(ExecutionResult.ZNAPTransition) + " (" + String(PercentageOfTransitions_1) + ")";

			SleepingArea.Parameters.SVAVTransition = String(ExecutionResult.SVAVTransition) + " (" + String(PercentageTransitionSVAV) + ")";
			AreaFallingAsleep.Parameters.ZVAVTransition = String(ExecutionResult.ZVAVTransition) + " (" + String(PercentageOfCallTransitions) + ")";
			
			SleepingArea.Parameters.SPAPTransition = String(ExecutionResult.SPAPTransition) + " (" + String(PercentageOfSPAPTraffic) + ")";
			AreaFallingAsleep.Parameters.PoTransition_ = String(ExecutionResult.PoTransition_) + " (" + String(PercentageOfPOTraffic_) + ")";
			
			SleepingArea.Parameters.SPAVTransition =  String(ExecutionResult.SPAVTransition) + " (" + String(PercentageTransitionSPAV) + ")";;
			AreaFallingAsleep.Parameters.ZPAVTransition =  String(ExecutionResult.ZPAVTransition) + " (" + String(PercentageOfZpavTraffic) + ")";;
		ElsIf DisplayLabelsForArrows = "Interests" Then
			
			ScopeOfApplication.Parameters.APTransition = PercentageOfTransitions;
			ScopeOfApplication.Parameters.TransitionAB = PercentageOfTraffic;
			
			AreaFallingAsleep.Parameters.ZNTransition = PercentageOfZnTraffic;
			AreaFallingAsleep.Parameters.POTransition = PercentageOfPOTraffic;
			
			SleepingArea.Parameters.TransitionCH = PercentageTransitionCH;
			SleepingArea.Parameters.SPTransition =  PercentageOfTransitions_3;
			
			AreaFallingAsleep.Parameters.ZvTransition = PercentageOfTransitions_;
			SleepingArea.Parameters.SVTransition = PercentageOfTransitions_2;	
			
			//Up arrows
			SleepingArea.Parameters.SNAPTransition = PercentageTransitionSnap;
			AreaFallingAsleep.Parameters.ZNAPTransition = PercentageOfTransitions_1;

			SleepingArea.Parameters.SVAVTransition = PercentageTransitionSVAV;
			AreaFallingAsleep.Parameters.ZVAVTransition = PercentageOfCallTransitions;
			
			SleepingArea.Parameters.SPAPTransition = PercentageOfSPAPTraffic;
			AreaFallingAsleep.Parameters.PoTransition_ = PercentageOfPOTraffic_;
			
			SleepingArea.Parameters.SPAVTransition = PercentageTransitionSPAV;
			AreaFallingAsleep.Parameters.ZPAVTransition = PercentageOfZpavTraffic;
		EndIf;

	ElsIf DisplayLabelsForArrows = "Numbers_1" Then 
		ScopeOfApplication.Parameters.APTransition=ExecutionResult.APTransition;
		ScopeOfApplication.Parameters.TransitionAB=ExecutionResult.TransitionAB;	
		AreaFallingAsleep.Parameters.ZNTransition = ExecutionResult.ZNTransition;
		AreaFallingAsleep.Parameters.POTransition =ExecutionResult.POTransition;	
		SleepingArea.Parameters.TransitionCH = ExecutionResult.TransitionCH;
		SleepingArea.Parameters.SPTransition = ExecutionResult.SPTransition;	
		AreaFallingAsleep.Parameters.ZvTransition =ExecutionResult.ZvTransition;
		SleepingArea.Parameters.SVTransition = ExecutionResult.SVTransition;		
		//Up arrows
		SleepingArea.Parameters.SNAPTransition = ExecutionResult.SNAPTransition;
		AreaFallingAsleep.Parameters.ZNAPTransition = ExecutionResult.ZNAPTransition;
		SleepingArea.Parameters.SVAVTransition = ExecutionResult.SVAVTransition;
		AreaFallingAsleep.Parameters.ZVAVTransition = ExecutionResult.ZVAVTransition;
		SleepingArea.Parameters.SPAPTransition = ExecutionResult.SPAPTransition;
		AreaFallingAsleep.Parameters.PoTransition_ = ExecutionResult.PoTransition_;
		SleepingArea.Parameters.SPAVTransition = ExecutionResult.SPAVTransition;
		AreaFallingAsleep.Parameters.ZPAVTransition = ExecutionResult.ZPAVTransition;
	EndIf;

	ScopeOfApplication.Parameters.New_Items = ExecutionResult.FirstPurchase.Count();
		
	//Filling in the number of clients
	NumberOfCustomersTotal = ExecutionResult.ActiveNew.Count()+ExecutionResult.ActiveProspects.Count()+ExecutionResult.ActiveFaithful.Count()
			+ExecutionResult.FallingAsleepNew.Count()+ExecutionResult.FallingAsleepProspects.Count()+ExecutionResult.SleepingFaithful_.Count()
			+ExecutionResult.SleepingNew.Count()+ExecutionResult.SleepingProspectsList.Count()+ExecutionResult.SleepingFaithfulList.Count();

	If NumberOfCustomersTotal <> 0 Then 
		ActiveNewInterest = (ExecutionResult.ActiveNew.Count()/NumberOfCustomersTotal)*100;
		ActiveProspectiveInterest = (ExecutionResult.ActiveProspects.Count()/NumberOfCustomersTotal)*100;
		ActiveCorrectPercentages = (ExecutionResult.ActiveFaithful.Count()/NumberOfCustomersTotal)*100;

		FallingAsleepNewPercentages = (ExecutionResult.FallingAsleepNew.Count()/NumberOfCustomersTotal)*100;
		FallingAsleepPromisingPercentages = (ExecutionResult.FallingAsleepProspects.Count()/NumberOfCustomersTotal)*100;
		FallingAsleepTruePercentages = (ExecutionResult.SleepingFaithful_.Count()/NumberOfCustomersTotal)*100;

		DormantNewPercentages = (ExecutionResult.SleepingNew.Count()/NumberOfCustomersTotal)*100;
		DormantProspectiveInterest = (ExecutionResult.SleepingProspectsList.Count()/NumberOfCustomersTotal)*100;
		SleepingTruePercentages = (ExecutionResult.SleepingFaithfulList.Count()/NumberOfCustomersTotal)*100;
	EndIf;
	
	//Fill in and/or calculate the percentage of customers
	If Not CustomersNumbersPercentages Then 
		ScopeOfApplication.Parameters.AN = ExecutionResult.ActiveNew.Count();
		ScopeOfApplication.Parameters.AP = ExecutionResult.ActiveProspects.Count();
		ScopeOfApplication.Parameters.AV = ExecutionResult.ActiveFaithful.Count();
		
		AreaFallingAsleep.Parameters.ZN = ExecutionResult.FallingAsleepNew.Count();
		AreaFallingAsleep.Parameters.WP = ExecutionResult.FallingAsleepProspects.Count();
		AreaFallingAsleep.Parameters.ZV_ = ExecutionResult.SleepingFaithful_.Count();

		SleepingArea.Parameters.SN = ExecutionResult.SleepingNew.Count();
		SleepingArea.Parameters.SP = ExecutionResult.SleepingProspectsList.Count();
		SleepingArea.Parameters.Sv = ExecutionResult.SleepingFaithfulList.Count();
	Else			
		Text = NStr("vi = '[Count] ([Interests]%)';
					|ru = '[Count] ([Interests]%)';
					|en = '[Count] ([Interests]%)'; fa = '[Count] ([Interests]%)';
					|it = '[Count] ([Interests]%)';
					|pl = '[Count] ([Interests]%)';
					|tr = '[Count] ([Interests]%)'");
		Values = New Structure("Count, Interests");
		
		Values.Insert("Count", ExecutionResult.ActiveNew.Count());	
		Values.Insert("Interests", Format(ActiveNewInterest,"NFD=0"));
		ScopeOfApplication.Parameters.AN = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);	
		Values.Insert("Count", ExecutionResult.ActiveProspects.Count());
		Values.Insert("Interests", Format(ActiveProspectiveInterest,"NFD=0"));
		ScopeOfApplication.Parameters.AP = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
		Values.Insert("Count", ExecutionResult.ActiveFaithful.Count());
		Values.Insert("Interests", Format(ActiveCorrectPercentages,"NFD=0"));
		ScopeOfApplication.Parameters.AV = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);

		Values.Insert("Count", ExecutionResult.FallingAsleepNew.Count());
		Values.Insert("Interests", Format(FallingAsleepNewPercentages,"NFD=0"));
		AreaFallingAsleep.Parameters.ZN = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
		Values.Insert("Count", ExecutionResult.FallingAsleepProspects.Count());
		Values.Insert("Interests", Format(FallingAsleepPromisingPercentages,"NFD=0"));
		AreaFallingAsleep.Parameters.WP = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
		Values.Insert("Count", ExecutionResult.SleepingFaithful_.Count());
		Values.Insert("Interests", Format(FallingAsleepTruePercentages,"NFD=0"));
		AreaFallingAsleep.Parameters.ZV_ = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
		
		Values.Insert("Count", ExecutionResult.SleepingNew.Count());
		Values.Insert("Interests", Format(DormantNewPercentages,"NFD=0"));
		SleepingArea.Parameters.SN	= StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
		Values.Insert("Count", ExecutionResult.SleepingProspectsList.Count());
		Values.Insert("Interests", Format(DormantProspectiveInterest,"NFD=0"));
		SleepingArea.Parameters.SP = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
		Values.Insert("Count", ExecutionResult.SleepingFaithfulList.Count());
		Values.Insert("Interests", Format(SleepingTruePercentages,"NFD=0"));
		SleepingArea.Parameters.Sv = StringFunctionsClientServer.InsertParametersIntoString(Text,Values);
	EndIf;
	
	//Filling in revenue and potential
	Currency = Constants.ManagementAccountingCurrency.Get();
	RowFormat_ = NStr("vi = '[Revenue] [Currency]';
						|ru = '[Revenue] [Currency]';
						|en = '[Revenue] [Currency]'; fa = '[Revenue] [Currency]';
						|it = '[Revenue] [Currency]';
						|pl = '[Revenue] [Currency]';
						|tr = '[Revenue] [Currency]'");
	RevenueCurrency = New Structure("Currency", Currency);
	
	RevenueCurrency.Insert("Revenue", Format(ExecutionResult.RevenueNew,"NFD=2; NZ=0"));
	ScopeOfApplication.Parameters.ANP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
	
	RevenueCurrency.Insert("Revenue", Format(ExecutionResult.RevenueProspects,"NFD=2; NZ=0"));
	ScopeOfApplication.Parameters.APP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
	
	RevenueCurrency.Insert("Revenue", Format(ExecutionResult.RevenueFaithful,"NFD=2; NZ=0"));
	ScopeOfApplication.Parameters.WUA = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
	
	//We make a request for the average check for the previous period
	RequestPotential = New Query();
	RequestPotential.Text = "SELECT ALLOWED DISTINCT
	                        |	Segments.Partner AS Partner
	                        |INTO SelectionByPartnerSegment
	                        |FROM
	                        |	InformationRegister.SegmentPartners AS Segments
	                        |WHERE
	                        |	Segments.Segment = &CustomerSegment
	                        |
	                        |INDEX BY
	                        |	Partner
	                        |;
	                        |
	                        |////////////////////////////////////////////////////////////////////////////////
	                        |SELECT ALLOWED DISTINCT
	                        |	Segments.Products AS Products
	                        |INTO SelectionByProductSegment
	                        |FROM
	                        |	InformationRegister.SegmentProducts AS Segments
	                        |WHERE
	                        |	Segments.Segment = &ProductSegment
	                        |
	                        |INDEX BY
	                        |	Products
	                        |;
	                        |
	                        |////////////////////////////////////////////////////////////////////////////////
	                        |SELECT ALLOWED DISTINCT
	                        |	AVG(Sales.RevenueAmountTurnover) AS RevenueAmountTurnover
	                        |FROM
	                        |	AccumulationRegister.RevenueAndCOGS.Turnovers(
	                        |			&BeginOfPeriod,
	                        |			&EndOfPeriod,
	                        |			Auto,
	                        |			(NOT &ProductSelectionIsUsed_
	                        |				OR ItemsLocationAttributes.Products = &Products)
	                        |				AND (NOT &FilterByPartnerSegmentIsUsed
	                        |					OR AccountingDimensionByPartners.Partner IN
	                        |						(SELECT
	                        |							SelectionByPartnerSegment.Partner
	                        |						FROM
	                        |							SelectionByPartnerSegment))
	                        |				AND (NOT &FilterByProductSegmentIsUsed
	                        |					OR ItemsLocationAttributes.Products IN
	                        |						(SELECT
	                        |							SelectionByProductSegment.Products
	                        |						FROM
	                        |							SelectionByProductSegment))
	                        |				AND (NOT &ManagerSelectionIsUsed
	                        |					OR Manager = &Manager)) AS Sales
	                        |		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	                        |		ON Sales.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	                        |WHERE
	                        |	(NOT &OrganizationSelectionIsUsed
	                        |			OR DimensionKeysOfAccountingByPartners.Organization = &Organization)
	                        |	AND (NOT &SelectionBasedOnAmountOfPurchasesIsUsed
	                        |			OR Sales.RevenueAmountTurnover > &AmountOfPurchases)
	                        |	AND Sales.RevenueAmountTurnover > 0
	                        |GROUP BY
	                        |	Sales.Recorder
	                        |TOTALS
	                        |	AVG(RevenueAmountTurnover)
	                        |BY
	                        |	OVERALL";
	
	//Setting up the selection
	RequestPotential.SetParameter("ProductSelectionIsUsed_",NomenclatureUsage);
	RequestPotential.SetParameter("OrganizationSelectionIsUsed",OrganizationUsage);
	RequestPotential.SetParameter("SelectionBasedOnAmountOfPurchasesIsUsed",PurchaseAmountUsage);
	RequestPotential.SetParameter("FilterByPartnerSegmentIsUsed",CustomerSegmentUsage);
	RequestPotential.SetParameter("FilterByProductSegmentIsUsed",ItemSegmentUsage);
	RequestPotential.SetParameter("ManagerSelectionIsUsed",ManagerUsage);
	RequestPotential.SetParameter("CustomerSegment",CustomerSegment);
	RequestPotential.SetParameter("ProductSegment",ProductSegment);
	RequestPotential.SetParameter("Products",Products);
	RequestPotential.SetParameter("Organization",Organization);
	RequestPotential.SetParameter("AmountOfPurchases",AmountOfPurchases);
	RequestPotential.SetParameter("Manager",Manager);
	
	//We calculate the potential period
	StartDatePotential = AddMonth(BegOfDay(CurrentSessionDate()), -Potential);
	
	RequestPotential.SetParameter("BeginOfPeriod",StartDatePotential);
	RequestPotential.SetParameter("EndOfPeriod",EndOfDay(CurrentSessionDate()));
	Selection = RequestPotential.Execute();

		
	//We check the result and calculate the potential
	If Not Selection.IsEmpty()Then
		
		PotentialResult = Selection.Unload()[0].RevenueAmountTurnover;
		RevenueCurrency.Insert("Revenue", Format(PotentialResult*ExecutionResult.FallingAsleepNew.Count(),"NFD=2; NZ=0"));	
		AreaFallingAsleep.Parameters.ZNP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
		
		RevenueCurrency.Insert("Revenue", Format(PotentialResult*ExecutionResult.FallingAsleepProspects.Count(),"NFD=2; NZ=0"));	
		AreaFallingAsleep.Parameters.STD = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
		
		RevenueCurrency.Insert("Revenue", Format(PotentialResult*ExecutionResult.SleepingFaithful_.Count(),"NFD=2; NZ=0"));	
		AreaFallingAsleep.Parameters.ZVP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
		
		RevenueCurrency.Insert("Revenue",Format(PotentialResult*ExecutionResult.SleepingNew.Count(),"NFD=2; NZ=0"));	
		SleepingArea.Parameters.SNP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
		
		RevenueCurrency.Insert("Revenue", Format(PotentialResult*ExecutionResult.SleepingProspectsList.Count(),"NFD=2; NZ=0"));	
		SleepingArea.Parameters.SPP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);
		
		RevenueCurrency.Insert("Revenue", Format(PotentialResult*ExecutionResult.SleepingFaithfulList.Count(),"NFD=2; NZ=0"));	
		SleepingArea.Parameters.SVP = StringFunctionsClientServer.InsertParametersIntoString(RowFormat_,RevenueCurrency);

	Else
		PotentialResult = "?";
		
		AreaFallingAsleep.Parameters.ZNP = PotentialResult;
		AreaFallingAsleep.Parameters.STD = PotentialResult;
		AreaFallingAsleep.Parameters.ZVP = PotentialResult;

		SleepingArea.Parameters.SNP = PotentialResult;
		SleepingArea.Parameters.SPP = PotentialResult;
		SleepingArea.Parameters.SVP = PotentialResult;
	EndIf;
			
	DecryptionOf = New Structure();
	DecryptionOf.Insert("DecryptionList",ExecutionResult.ActiveNew);
	DecryptionOf.Insert("Interests",ActiveNewInterest);
	DecryptionOf.Insert("Revenue",ExecutionResult.RevenueNew);
	DecryptionOf.Insert("Segment","AN");
	DecryptionOf.Insert("Filter",Filters);
	DecryptionOf.Insert("Before",ActiveUpTo);
	
	DecryptionOfAP = New Structure();
	DecryptionOfAP.Insert("DecryptionList",ExecutionResult.ActiveProspects);
	DecryptionOfAP.Insert("Interests",ActiveProspectiveInterest);
	DecryptionOfAP.Insert("Revenue",ExecutionResult.RevenueProspects);
	DecryptionOfAP.Insert("Segment","AP");
	DecryptionOfAP.Insert("Filter",Filters);
	DecryptionOfAP.Insert("PurchasesFrom",ProspectivePurchasesFrom);
	DecryptionOfAP.Insert("PurchasesBefore",PurchasesArePromisingUpTo);
	DecryptionOfAP.Insert("Before",ActiveProspectiveUpTo);

	DecryptionOfAV = New Structure();
	DecryptionOfAV.Insert("DecryptionList",ExecutionResult.ActiveFaithful);
	DecryptionOfAV.Insert("Interests",ActiveCorrectPercentages);
	DecryptionOfAV.Insert("Revenue",ExecutionResult.RevenueFaithful);
	DecryptionOfAV.Insert("Segment","AV");
	DecryptionOfAV.Insert("Filter",Filters);
	DecryptionOfAV.Insert("Purchases",PurchasesAreCorrect);
	DecryptionOfAV.Insert("Before",ActiveLoyalTo);
	
	ScopeOfApplication.Parameters.kAn = DecryptionOf;
	ScopeOfApplication.Parameters.KAP = DecryptionOfAP;
	ScopeOfApplication.Parameters.ToAV = DecryptionOfAV;
	
	DecryptionOfZn = New Structure();
	DecryptionOfZn.Insert("DecryptionList",ExecutionResult.FallingAsleepNew);
	DecryptionOfZn.Insert("Interests",FallingAsleepNewPercentages);
	DecryptionOfZn.Insert("Potential",AreaFallingAsleep.Parameters.ZNP);
	DecryptionOfZn.Insert("Segment","ZN");
	DecryptionOfZn.Insert("Filter",Filters);
	DecryptionOfZn.Insert("dated",FallingAsleepFrom);
	DecryptionOfZn.Insert("Before",FallingAsleepBefore);
	
	ExplanationOfPO = New Structure();
	ExplanationOfPO.Insert("DecryptionList",ExecutionResult.FallingAsleepProspects);
	ExplanationOfPO.Insert("Interests",FallingAsleepPromisingPercentages);
	ExplanationOfPO.Insert("Potential", AreaFallingAsleep.Parameters.STD);
	ExplanationOfPO.Insert("Segment","WP");
	ExplanationOfPO.Insert("Filter",Filters);
	ExplanationOfPO.Insert("PurchasesFrom",ProspectivePurchasesFrom);
	ExplanationOfPO.Insert("PurchasesBefore",PurchasesArePromisingUpTo);
	ExplanationOfPO.Insert("dated",FallingAsleepPerspectiveFrom);
	ExplanationOfPO.Insert("Before",FallingAsleepPromisingUpTo);
	
	DecryptionOfLinks = New Structure();
	DecryptionOfLinks.Insert("DecryptionList",ExecutionResult.SleepingFaithful_);
	DecryptionOfLinks.Insert("Interests",FallingAsleepTruePercentages);
	DecryptionOfLinks.Insert("Potential", AreaFallingAsleep.Parameters.ZVP);
	DecryptionOfLinks.Insert("Segment","ZV_");
	DecryptionOfLinks.Insert("Filter",Filters);
	DecryptionOfLinks.Insert("Purchases",PurchasesAreCorrect);
	DecryptionOfLinks.Insert("dated",FallingAsleepFaithfulFrom);
	DecryptionOfLinks.Insert("Before",FallingAsleepFaithfulTo);

	AreaFallingAsleep.Parameters.ToZN = DecryptionOfZn;  	
	AreaFallingAsleep.Parameters.ToPO = ExplanationOfPO;
	AreaFallingAsleep.Parameters.ToZV = DecryptionOfLinks;
	
	DecryptionOfCH = New Structure();
	DecryptionOfCH.Insert("DecryptionList",ExecutionResult.SleepingNew);
	DecryptionOfCH.Insert("Interests",DormantNewPercentages);
	DecryptionOfCH.Insert("Potential",SleepingArea.Parameters.SNP);
	DecryptionOfCH.Insert("Segment","SN");
	DecryptionOfCH.Insert("Filter",Filters);
	DecryptionOfCH.Insert("dated",Sleepers);
	
	DecryptionOfJointVenture = New Structure();
	DecryptionOfJointVenture.Insert("DecryptionList",ExecutionResult.SleepingProspectsList);
	DecryptionOfJointVenture.Insert("Interests",DormantProspectiveInterest);
	DecryptionOfJointVenture.Insert("Potential", SleepingArea.Parameters.SPP);
	DecryptionOfJointVenture.Insert("Segment","SP");
	DecryptionOfJointVenture.Insert("Filter",Filters);
	DecryptionOfJointVenture.Insert("PurchasesFrom",ProspectivePurchasesFrom);
	DecryptionOfJointVenture.Insert("PurchasesBefore",PurchasesArePromisingUpTo);
	DecryptionOfJointVenture.Insert("dated",SleepingProspects);
	
	DecodingSV = New Structure();
	DecodingSV.Insert("DecryptionList",ExecutionResult.SleepingFaithfulList);
	DecodingSV.Insert("Interests",SleepingTruePercentages);
	DecodingSV.Insert("Potential", SleepingArea.Parameters.SVP);
	DecodingSV.Insert("Segment","SV");
	DecodingSV.Insert("Filter",Filters);
	DecodingSV.Insert("Purchases",PurchasesAreCorrect);
	DecodingSV.Insert("dated",SleepingFaithful);
	
	SleepingArea.Parameters.ToCH = DecryptionOfCH;
	SleepingArea.Parameters.ToSP = DecryptionOfJointVenture;
	SleepingArea.Parameters.ToSV = DecodingSV;
	
	// We output the areas
	Result.Clear();
	Result.Put(ScopeOfApplication);
	Result.Put(AreaFallingAsleep);
	Result.Put(SleepingArea);
	
	If Not DisplayArrows Then
		Result.DeleteArea(Result.Area("PrimaryArrow"),SpreadsheetDocumentShiftType.WithoutShift);
		Result.DeleteArea(Result.Area("ArrowsVertical1"),SpreadsheetDocumentShiftType.WithoutShift);
		Result.DeleteArea(Result.Area("ArrowsVertical2"),SpreadsheetDocumentShiftType.WithoutShift);
		Result.DeleteArea(Result.Area("ArrowsHorizontal1"),SpreadsheetDocumentShiftType.WithoutShift);
		Result.DeleteArea(Result.Area("ArrowsHorizontal2"),SpreadsheetDocumentShiftType.WithoutShift);
	EndIf;  
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Result, "DontUse");

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
	If Item.Name = "sh_ShamsiInput_F_StartDate" Then
		BeginningDateOfPeriodOnChange(Items.StartDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndDate" Then
		EndingDateOfPeriodOnChange(Items.EndDate);
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
