///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var CommandToExecute;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.SectionName)
		And Parameters.SectionName <> AdditionalReportsAndDataProcessorsClientServer.StartPageName() Then
		SectionRef = Common.MetadataObjectID(Metadata.Subsystems.Find(Parameters.SectionName));
	Else
		SectionRef = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	DataProcessorsKind = AdditionalReportsAndDataProcessors.GetDataProcessorKindByKindStringPresentation(Parameters.Kind);
	If DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.ObjectFilling Then
		AreAssignableDataProcessors = True;
		Title = NStr("vi = 'Lệnh điền đối tượng';
					|ru = 'Команды заполнения объектов';
					|en = 'Object filling commands'; fa = 'Object filling commands';
					|it = 'Comandi di compilazione degli oggetti';
					|pl = 'Polecenia wypeniania obiektów';
					|tr = 'Nesne doldurma komutları'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Then
		AreAssignableDataProcessors = True;
		AreReports = True;
		Title = NStr("vi = 'Báo cáo';
					|ru = 'Отчеты';
					|en = 'Reports'; fa = 'گزارش‌ها';
					|it = 'Report';
					|pl = 'Raporty';
					|tr = 'Raporlar'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		AreAssignableDataProcessors = True;
		Title = NStr("vi = 'Mẫu in bổ sung';
					|ru = 'Дополнительные печатные формы';
					|en = 'Additional print forms'; fa = 'Additional print forms';
					|it = 'Modelli di stampa aggiuntivi';
					|pl = 'Dodatkowe formularze wydruku';
					|tr = 'Ek yazdırma formları'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation Then
		AreAssignableDataProcessors = True;
		Title = NStr("vi = 'Lệnh tạo đối tượng liên kết';
					|ru = 'Команды создания связанных объектов';
					|en = 'Create related objects commands'; fa = 'Create related objects commands';
					|it = 'Comandi di creazione degli oggetti collegati';
					|pl = 'Polecenia tworzenia obiektów powiązanych';
					|tr = 'Bağlantılı nesne oluşturma için komutlar'");
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		AreGlobalDataProcessors = True;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Bộ xử lý bổ sung (%1)';
				|ru = 'Дополнительные обработки (%1)';
				|en = 'Additional data processors (%1)'; fa = 'Additional data processors (%1)';
				|it = 'Elaborazioni aggiuntive (%1)';
				|pl = 'Dodatkowe procedury przetwarzania (%1)';
				|tr = 'Ek veri işlemcileri (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(SectionRef));
	ElsIf DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		AreGlobalDataProcessors = True;
		AreReports = True;
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Báo cáo bổ sung (%1)';
				|ru = 'Дополнительные отчеты (%1)';
				|en = 'Additional reports (%1)'; fa = 'Additional reports (%1)';
				|it = 'Report aggiuntivi (%1)';
				|pl = 'Raporty dodatkowe (%1)';
				|tr = 'Ek raporlar (%1)'"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(SectionRef));
	EndIf;
	
	If ValueIsFilled(Parameters.WindowOpeningMode) Then
		WindowOpeningMode = Parameters.WindowOpeningMode;
	EndIf;
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	If AreAssignableDataProcessors Then
		Items.CustomizeList.Visible = False;
		
		RelatedObjects.LoadValues(Parameters.RelatedObjects.UnloadValues());
		If RelatedObjects.Count() = 0 Then
			Cancel = True;
			Return;
		EndIf;
		
		OwnerInfo = AdditionalReportsAndDataProcessorsCached.AssignedObjectFormParameters(Parameters.FormName);
		ParentMetadata = Metadata.FindByType(TypeOf(RelatedObjects[0].Value));
		If ParentMetadata = Undefined Then
			ParentRef = OwnerInfo.ParentRef;
		Else
			ParentRef = Common.MetadataObjectID(ParentMetadata);
		EndIf;
		If TypeOf(OwnerInfo) = Type("FixedStructure") Then
			IsObjectForm = OwnerInfo.IsObjectForm;
		Else
			IsObjectForm = False;
		EndIf;
	EndIf;
	
	FillDataProcessorsTable();
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If ValueSelected = "MyReportsAndDataProcessorsSetupDone" Then
		FillDataProcessorsTable();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCommandsTable

&AtClient
Procedure CommandsTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	RunDataProcessorByParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExecuteProcessing(Command)
	
	RunDataProcessorByParameters()
	
EndProcedure

&AtClient
Procedure CustomizeList(Command)
	FormParameters = New Structure("DataProcessorsKind, SectionRef");
	FillPropertyValues(FormParameters, ThisObject);
	OpenForm("CommonForm.MyReportsAndDataProcessorsSettings", FormParameters, ThisObject, False);
EndProcedure

&AtClient
Procedure CancelDataProcessorExecution(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillDataProcessorsTable()
	CommandsTypes = New Array;
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ClientMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.OpeningForm);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.SafeModeScenario);
	
	AdditionalCommands = AdditionalReportsAndDataProcessors.AdditionalCommands(DataProcessorsKind, 
		?(AreGlobalDataProcessors, SectionRef, ParentRef), IsObjectForm, CommandsTypes);
	CommandsTable.Load(AdditionalCommands);
EndProcedure

&AtClient
Procedure RunDataProcessorByParameters()
	DataProcessorData = Items.CommandsTable.CurrentData;
	If DataProcessorData = Undefined Then
		Return;
	EndIf;
	
	CommandToExecute = New Structure(
		"Ref, Presentation, 
		|Id, StartupOption, ShouldShowUserNotification, 
		|Modifier, RelatedObjects, IsReport, Kind");
	FillPropertyValues(CommandToExecute, DataProcessorData);
	If Not AreGlobalDataProcessors Then
		CommandToExecute.RelatedObjects = RelatedObjects.UnloadValues();
	EndIf;
	CommandToExecute.IsReport = AreReports;
	CommandToExecute.Kind = DataProcessorsKind;
	
	If DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		AdditionalReportsAndDataProcessorsClient.OpenDataProcessorForm(CommandToExecute, FormOwner, CommandToExecute.RelatedObjects);
		
	ElsIf DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		AdditionalReportsAndDataProcessorsClient.ExecuteDataProcessorClientMethod(CommandToExecute, FormOwner, CommandToExecute.RelatedObjects);
		
	ElsIf DataProcessorsKind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm")
		And DataProcessorData.Modifier = "PrintMXL1" Then
		
		AdditionalReportsAndDataProcessorsClient.ExecutePrintFormOpening(CommandToExecute, FormOwner, CommandToExecute.RelatedObjects);
		
	ElsIf DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or DataProcessorData.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
		
		// Change form items.
		Items.ExplainingDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện lệnh ""%1""...';
				|ru = 'Выполняется команда ""%1""...';
				|en = 'Executing command %1…'; fa = 'Executing command %1…';
				|it = 'Comando in esecuzione ""%1""...';
				|pl = 'Trwa wykonywanie polecenia ""%1""...';
				|tr = '""%1"" komutu yürütülüyor...'"),
			DataProcessorData.Presentation);
		Items.Pages.CurrentPage = Items.DataProcessorExecutionPage;
		Items.CustomizeList.Visible = False;
		Items.ExecuteProcessing.Visible = False;
		
		// Delaying the server call until the form state becomes consistent.
		AttachIdleHandler("ExecuteDataProcessorServerMethod", 0.1, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteDataProcessorServerMethod()
	
	Job = RunBackgroundJob1(CommandToExecute, UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("ExecuteDataProcessorServerMethodCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

&AtServerNoContext
Function RunBackgroundJob1(Val CommandToExecute, Val UUID)
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Báo cáo và bộ xử lý bổ sung: Thực hiện lệnh ""%1""';
			|ru = 'Доп. отчеты и обработки: Выполнение команды ""%1""';
			|en = 'Additional reports and data processors: executing command %1.'; fa = 'Additional reports and data processors: executing command %1.';
			|it = 'Elaborazioni e report aggiuntivi: Esecuzione del comando ""%1""';
			|pl = 'Dodatkowe raporty i procedury przetwarzania: Wykonywanie polecenia ""%1""';
			|tr = 'Ek raporlar ve veri işlemcileri: ""%1"" komutu yürütülüyor'"),
		CommandToExecute.Presentation);
	
	StartSettings1.RefinementErrors = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể thực hiện lệnh ""%1"" theo nguyên nhân:';
			|ru = 'Не удалось выполнить команду ""%1"" по причине:';
			|en = 'Cannot execute the command. Reason: %1.'; fa = 'Cannot execute the command. Reason: %1.';
			|it = 'Не удалось выполнить команду ""%1"" по причине:';
			|pl = 'Cannot execute the command. Reason: %1.';
			|tr = 'İşlem şu sebeple yürütülemedi:%1'"),
		CommandToExecute.Presentation);
	
	MethodParameters = New Structure("AdditionalDataProcessorRef, CommandID, RelatedObjects");
	MethodParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	MethodParameters.CommandID          = CommandToExecute.Id;
	MethodParameters.RelatedObjects             = CommandToExecute.RelatedObjects;
	
	Return TimeConsumingOperations.ExecuteInBackground("AdditionalReportsAndDataProcessors.ExecuteCommand",
		MethodParameters, StartSettings1);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ExecuteDataProcessorServerMethodCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		If IsOpen() Then
			Close();
		EndIf;
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
		
	// Showing a pop-up notification and closing this form.
	If CommandToExecute.ShouldShowUserNotification Then
		ShowUserNotification(NStr("vi = 'Đã thực hiện lệnh';
									|ru = 'Команда выполнена';
									|en = 'The operation is completed.'; fa = 'The operation is completed.';
									|it = 'Comando eseguito';
									|pl = 'Polecenie wykonano';
									|tr = 'Komut yapıldı'"),, CommandToExecute.Presentation);
	EndIf;
	If IsOpen() Then
		Close();
	EndIf;
	
	// Refresh owner form.
	If IsObjectForm Then
		Try
			FormOwner.Read();
		Except
			// No action required.
		EndTry;
	EndIf;
	
	// Notify other forms.
	ExecutionResult = GetFromTempStorage(Result.ResultAddress);
	NotifyForms = CommonClientServer.StructureProperty(ExecutionResult, "NotifyForms");
	If NotifyForms <> Undefined Then
		StandardSubsystemsClient.NotifyFormsAboutChange(NotifyForms);
	EndIf;
	
EndProcedure

#EndRegion