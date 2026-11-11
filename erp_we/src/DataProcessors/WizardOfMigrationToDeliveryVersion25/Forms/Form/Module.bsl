//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("StartingTransition") Then
		
		StartingTransition = Parameters.StartingTransition;
		
	EndIf;
	
	Status = TransitionStatus();
	FillPropertyValues(ThisObject, Status);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If TransitionIsComplete Then
		
		NotifyAboutEndOfTransitionAndCloseAssistant();
		
	EndIf;
	
	SetVisibilityOfTransitionCompletionCommands();
	
	If Not TransitionIsRunning Then
		
		CreateAndLaunchRoutineTaskForSwitchingToDelivery25();
		SetTransitionStartTime();
		
		Notify("BeginningOfTransitionToDelivery25");
		AttachIdleHandler("UpdatingTransitionStatus", 5, False);
		
	ElsIf Not DataProcessed Then
		
		AttachIdleHandler("UpdatingTransitionStatus", 5, False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseAssistant(Command)
	
	Close();
	
EndProcedure

&AtClient
Async Procedure CompleteTransition(Command)
	
	ConnectionsInformation = ConnectionsInformation();
	If ConnectionsInformation.HasActiveConnections Then
		
		MessageText = GoodsDeliveryClientServer.TextForCheckingActiveSessions();
		DoMessageBoxAsync(MessageText);
		
		Return;
		
	EndIf;
	
	CompleteTransition = Await GoodsDeliveryClient.CheckPossibilityOfSwitchingToDelivery25Async();
	
	If CompleteTransition Then
		
		CompleteTransitionATServer();
		CommonClient.RefreshApplicationInterface();
		NotifyAboutEndOfTransitionAndCloseAssistant();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateAndLaunchRoutineTaskForSwitchingToDelivery25()
	
	JobMetadata = Metadata.ScheduledJobs.MigrationToDeliveryManagement25;
	
	Filter = New Structure;
	Filter.Insert("Key", JobMetadata.Key);
	Filter.Insert("State", BackgroundJobState.Active);
	BackgroundTransitionTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If BackgroundTransitionTasks.Count() = 0 Then
		
		ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.BackgroundJobDescription = JobMetadata.Description;
		ExecutionParameters.BackgroundJobKey = JobMetadata.Key;
		
		TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "GoodsDelivery.StartSwitchingToDelivery25");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdatingTransitionStatus()
	
	Status = TransitionStatus(StartingTransition);
	FillPropertyValues(ThisObject, Status);
	
	UpdateSteps();
	
	If StartingTransition
	   And JobCreated Then
		
		StartingTransition = False;
		
	EndIf;
	
	If DataProcessed Then
		
		Notify("ProcessedDataForSwitchingToDelivery25");
		DetachIdleHandler("UpdatingTransitionStatus");
		
		SetVisibilityOfTransitionCompletionCommands(True);
		
	ElsIf TransitionIsComplete Then
		
		NotifyAboutEndOfTransitionAndCloseAssistant();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfTransitionCompletionCommands(DataProcessed = False)
	
	Items.GroupInformationIsGeneral.Visible = Not DataProcessed;
	Items.TransitionEndGroup.Visible = DataProcessed;
	
EndProcedure

&AtClient
Procedure UpdateSteps()
	
	If Not DataProcessed Then
		
		PartnersProcessed = (NumberOfPartners = NumberOfPartnersProcessed);
		WarehousesHaveBeenProcessed = (NumberOfWarehouses = NumberOfWarehousesProcessed);
		
		If PartnersProcessed Then
			
			Items.Step1Label.CurrentPage = Items.Step1LabelCompleted;
			Items.DecorationStep1CompletedInscription.Title = TextOfPartnersStepHeader();
			
		Else
			
			Items.Step1Label.CurrentPage = Items.Step1TheLabelIsExecuted;
			Items.DecorationStep1InscriptionIsExecuted.Title = TextOfPartnersStepHeader();
			
		EndIf;
		
		If WarehousesHaveBeenProcessed Then
			
			Items.Step2Label.CurrentPage = Items.Step2LabelCompleted;
			Items.DecorationStep2CompletedInscription.Title = TitleTextOfWarehousesStep();
			
		Else
			
			Items.Step2Label.CurrentPage = Items.Step2TheLabelIsExecuted;
			Items.DecorationStep2InscriptionIsExecuted.Title = TitleTextOfWarehousesStep();
			
		EndIf;
		
		If PartnersProcessed
		   And WarehousesHaveBeenProcessed Then
			
			Items.Step3Label.CurrentPage = Items.Step3TheLabelIsExecuted;
			DataProcessed = True;
			
		EndIf;
		
	Else
		
		Items.Step1Label.CurrentPage = Items.Step1LabelCompleted;
		Items.DecorationStep1CompletedInscription.Title = TextOfPartnersStepHeader();
		
		Items.Step2Label.CurrentPage = Items.Step2LabelCompleted;
		Items.DecorationStep2CompletedInscription.Title = TitleTextOfWarehousesStep();
		
		Items.Step3Label.CurrentPage = Items.Step3TheLabelIsExecuted;
		
	EndIf;
	
	If TransitionIsComplete Then 
		
		Items.Step1Label.CurrentPage = Items.Step1LabelCompleted;
		Items.Step2Label.CurrentPage = Items.Step2LabelCompleted;
		Items.Step3Label.CurrentPage = Items.Step3LabelCompleted;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TransitionStatus(Val StartingTransition = False)
	
	TransitionStatus = GoodsDelivery.StatusOfTransitionToDelivery25(StartingTransition);
	Return TransitionStatus;
	
EndFunction

&AtServer
Procedure SetTransitionStartTime()
	
	BeginTime = CurrentSessionDate();
	DateTimeString = Format(BeginTime, "DLF=DT;");
	TemplateTransitionHasBegun = NStr("ru = 'Переход начался: %1';
										|vi = 'Migration started: %1';
										|en = 'Migration started: %1'; fa = 'Migration started: %1';
										|it = 'Migration started: %1';
										|pl = 'Migration started: %1';
										|tr = 'Geçiş başladı: %1'");
	
	Items.SceneryTransitionStartTime.Visible = True;
	Items.SceneryTransitionStartTime.Title = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateTransitionHasBegun,
		DateTimeString);
	
EndProcedure

&AtClient
Function TextOfPartnersStepHeader()
	
	Template = NStr("ru = '1. Формирование точек доставки партнеров (%1 из %2).';
					|vi = '1. Generating partner delivery points (%1 out of %2).';
					|en = '1. Generating partner delivery points (%1 out of %2).'; fa = '1. Generating partner delivery points (%1 out of %2).';
					|it = '1. Generating partner delivery points (%1 out of %2).';
					|pl = '1. Generating partner delivery points (%1 out of %2).';
					|tr = '1. İş ortaklarının teslimat noktalarının oluşturulması (%1/%2).'");
	
	Text = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		Format(NumberOfPartnersProcessed, "NZ=0; NG=0;"),
		Format(NumberOfPartners, "NZ=0; NG=0;"));
	
	Return Text;
	
EndFunction

&AtClient
Function TitleTextOfWarehousesStep()
	
	Template = NStr("ru = '2. Формирование точек доставки складов (%1 из %2).';
					|vi = '2. Generating warehouse delivery points (%1 out of %2).';
					|en = '2. Generating warehouse delivery points (%1 out of %2).'; fa = '2. Generating warehouse delivery points (%1 out of %2).';
					|it = '2. Generating warehouse delivery points (%1 out of %2).';
					|pl = '2. Generating warehouse delivery points (%1 out of %2).';
					|tr = '2. Ambarların teslimat noktalarının oluşturulması (%1/%2).'");
	
	Text = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		Format(NumberOfWarehousesProcessed, "NZ=0; NG=0;"),
		Format(NumberOfWarehouses, "NZ=0; NG=0;"));
	
	Return Text;
	
EndFunction

&AtServerNoContext
Procedure CompleteTransitionATServer()
	
	GoodsDelivery.CompleteTransitionToDelivery25();
	
EndProcedure

&AtClient
Procedure NotifyAboutEndOfTransitionAndCloseAssistant()
	
	Notify("EndOfTransitionToDelivery25");
	Close();
	
EndProcedure

&AtServerNoContext
Function ConnectionsInformation()
	
	Information = IBConnections.ConnectionsInformation();
	Return Information;
	
EndFunction

#EndRegion