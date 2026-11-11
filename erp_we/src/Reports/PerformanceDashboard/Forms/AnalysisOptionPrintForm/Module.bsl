#Region Variables

&AtClient
Var HandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// Support for integration with mailing lists-reports
	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("AnalysisOptionFilter")
			And ValueIsFilled(Parameters.Filter.AnalysisOptionFilter) Then
			AnalysisOptionFilter = Parameters.Filter.AnalysisOptionFilter; // CatalogRef.AnalysisOptionsOfTargetValues -
			Title = Common.ObjectAttributeValue(AnalysisOptionFilter, "Description");
		Else
			Title = NStr("vi = 'Màn hình chỉ số mục tiêu (in)';
						|ru = 'Монитор целевых показателей (печать)';
						|en = 'Performance dashboard (print)'; fa = 'Performance dashboard (print)';
						|it = 'Target monitor (stampare)';
						|pl = 'Monitor docelowych wskaźników (druk)';
						|tr = 'Performans gösterge paneli (yazdırma)'");
		EndIf;
		If Parameters.Filter.Property("DemoMode")
			And Parameters.Filter.DemoMode Then
			Title = NStr("vi = 'Chế độ minh họa';
						|ru = 'Демонстрационный режим';
						|en = 'Demo mode'; fa = 'حالت نمایشی';
						|it = 'Modalità dimostrativa';
						|pl = 'Tryb demonstracyjny';
						|tr = 'Demo modu'") + ": " + Title;
		EndIf;
	EndIf;
	
	ReportCurrentOptionDescription = Title;
	
	ReportOptionMode = True;
	CurrentVariantKey = "PerformanceDashboard";
	
	// Local variables
	ReportObject = FormAttributeToValue("Report");
	ReportMetadata = ReportObject.Metadata();
	ReportSettings = ReportsClientServer.GetDefaultReportSettings();
	SchemaURL = PutToTempStorage(ReportObject.DataCompositionSchema, UUID);
	
	ReportSettings.Insert("SchemaURL", SchemaURL);
	ReportSettings.Insert("FullName", ReportMetadata.FullName());
	ReportSettings.Insert("Description", TrimAll(ReportMetadata.Presentation()));
	
	Information = ReportsOptions.ReportInformation(ReportSettings.FullName);
	ReportSettings.Insert("ReportRef", Information.Report);
	ReportSettings.Insert("OptionRef", ReportsOptions.ReportVariant(ReportSettings.ReportRef, CurrentVariantKey));
	ReportSettings.Insert("External", False);
	
	Report.PrintMode = True;
	
	// Close integration with mail and mailing.
	CanSendEmails = False;
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperations = Common.CommonModule("EmailOperations");
		CanSendEmails = ModuleEmailOperations.CanSendEmails();
	EndIf;
	If CanSendEmails Then
		If Common.SubsystemExists("StandardSubsystems.ReportMailing") Then
			ModuleReportDistribution = Common.CommonModule("ReportMailing");
			ModuleReportDistribution.ReportFormAddCommands(ThisObject, Cancel, StandardProcessing);
		Else // If there is one command in the submenu, the drop-down list is not displayed.
			Items.SendEmail.Title = Items.SendGroup.Title + "...";
			Items.Move(Items.SendEmail, Items.SendGroup.Parent, Items.SendGroup);
		EndIf;
	Else
		Items.SendGroup.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure ChoiceProcessing(Result, SubordinateForm)
	ResultProcessed = False;
	
	// Expansion mechanisms.
	If CommonClient.SubsystemExists("StandardSubsystems.ReportMailing") Then
		ModuleReportDistributionClient = CommonClient.CommonModule("ReportMailingClient");
		ModuleReportDistributionClient.ChoiceProcessingReportForm(ThisObject, Result, SubordinateForm, ResultProcessed);
	EndIf;
	ReportsClientOverridable.ChoiceProcessing(ThisObject, Result, SubordinateForm, ResultProcessed);
EndProcedure
#EndRegion

#Region FormCommandsEventHandlers

// Plug-in event handler for the form element.
// 
// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_Command(Command)
	ConstantCommand = ConstantCommands.FindByValue(Command.Name);
	If ConstantCommand <> Undefined And ValueIsFilled(ConstantCommand.Presentation) Then
		SubstringsArray = StrSplit(ConstantCommand.Presentation, ".");
		ModuleClient = CommonClient.CommonModule(SubstringsArray[0]);
		Handler = New CallbackDescription(SubstringsArray[1], ModuleClient, Command);
		RunCallback(Handler, ThisObject);
	Else
		ReportsClientOverridable.HandlerCommands(ThisObject, Command, False);
	EndIf;
EndProcedure

&AtClient
Procedure SendEmail(Command)
	ShowSendEmailDialog();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowSendEmailDialog()
	ProtectionFlag = Result.Protection;
	Result.Protection = False;
	Attachment = New Structure;
	Attachment.Insert("AddressInTempStorage", PutToTempStorage(Result, UUID));
	Attachment.Insert("Presentation", Title);
	Result.Protection = ProtectionFlag;
	
	AttachmentsList = CommonClientServer.ValueInArray(Attachment);
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		SendOptions = ModuleEmailOperationsClient.EmailSendOptions();
		SendOptions.Subject = Title;
		SendOptions.Attachments = AttachmentsList;
		ModuleEmailOperationsClient.CreateNewEmailMessage(SendOptions);
	EndIf;
EndProcedure

#EndRegion
