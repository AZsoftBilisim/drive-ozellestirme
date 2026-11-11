///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens a form with available commands.
//
// Parameters:
//   CommandParameter - Arbitrary - passed "as is" from the command handler parameters.
//   CommandExecuteParameters - CommandExecuteParameters - passed "as is" from the command handler parameters.
//   Kind - String - A data processor type that can be obtained from the function series:
//       AdditionalReportsAndDataProcessorsClientServer.DataProcessorKind<…>.
//   SectionName - String - a name of the command interface section the command is called from.
//
Procedure OpenAdditionalReportAndDataProcessorCommandsForm(CommandParameter, CommandExecuteParameters, Kind, SectionName = "") Export
	
	RelatedObjects = New ValueList;
	If TypeOf(CommandParameter) = Type("Array") Then // Assignable data processor.
		RelatedObjects.LoadValues(CommandParameter);
	ElsIf CommandParameter <> Undefined Then
		RelatedObjects.Add(CommandParameter);
	EndIf;
	
	Parameters = New Structure("RelatedObjects, Kind, SectionName, WindowOpeningMode");
	Parameters.RelatedObjects = RelatedObjects;
	Parameters.Kind = Kind;
	Parameters.SectionName = SectionName;
	
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm") Then // Assignable data processor.
		Parameters.Insert("FormName", CommandExecuteParameters.Source.FormName);
	EndIf;
	
	If TypeOf(CommandExecuteParameters) = Type("CommandExecuteParameters") Then
		RefForm = CommandExecuteParameters.URL;
	Else
		RefForm = Undefined;
	EndIf;
	
	OpenForm("CommonForm.AdditionalReportsAndDataProcessors", Parameters,
		CommandExecuteParameters.Source,,, RefForm);
	
EndProcedure

// Opens an additional report form with the specified report option.
//
// Parameters:
//   AdditionalReport - CatalogRef.AdditionalReportsAndDataProcessors
//   VariantKey - String - a name of the additional report option.
//
Procedure OpenAdditionalReportOption(AdditionalReport, VariantKey) Export
	
	If TypeOf(AdditionalReport) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Return;
	EndIf;
	
	ReportName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(AdditionalReport);
	FormName = StrTemplate("ExternalReport.%1.Form", ReportName);
	Uniqueness = StrTemplate("ExternalReport.%1/VariantKey.%2", ReportName, VariantKey);
	OpeningParameters = New Structure("VariantKey", VariantKey);
	OpenForm(FormName, OpeningParameters, Undefined, Uniqueness);
	
EndProcedure

// Returns a blank structure of parameters of command execution in the background.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors - a reference to a report or data processor being executed.
//
// Returns:
//   Structure - Parameter template for executing the command in the background:
//      * AdditionalDataProcessorRef - CatalogRef.AdditionalReportsAndDataProcessors - passed "as is" from
//                                                                                          the form parameters.
//      * AccompanyingText1 - String - a text of a long-running operation.
//      * RelatedObjects - Array - references to the objects the command is being executed for.
//          It is used for additional data processors to assign.
//      * CreatedObjects - Array - references to the objects created while executing the command.
//          It is used for assignable additional data processors of the "Create related objects" kind.
//      * OwnerForm - ClientApplicationForm - a list form or an object form the command is called from.
//
Function CommandExecuteParametersInBackground(Ref) Export
	
	Result = New Structure("AdditionalDataProcessorRef", Ref);
	Result.Insert("AccompanyingText1");
	Result.Insert("RelatedObjects");
	Result.Insert("CreatedObjects");
	Result.Insert("OwnerForm");
	Return Result;
	
EndFunction

// Executes command CommandID in the background using the long-running operation mechanism.
// It is intended for use in forms of external reports and data processors.
//
// Parameters:
//   CommandID - String - a command name as it is specified in function ExternalDataProcessorInfo in the object module.
//   CommandParameters - Structure - command execution parameters.
//       For parameters, see function CommandExecuteParametersInBackground.
//       Also includes an internal parameter reserved by the subsystem:
//         * CommandID - String - a name of the command being executed. Matches the CommandID parameter.
//       In addition to standard parameters, the procedure can have custom parameters used in the command handler.
//       It is recommended that you add a prefix, such as "Context…", to custom parameter names
//       to avoid exact matches with standard parameter names.
//   Handler - See TimeConsumingOperationsClient.WaitCompletion.CallbackOnCompletion
//
// Example:
//	&AtClient
//	Procedure CommandHandler(Command)
//		CommandParameters = AdditionalReportsAndDataProcessorsClient.CommandExecuteParametersInBackground(Parameters.AdditionalDataProcessorRef);
//		CommandParameters.AccompanyingText = NStr("en = 'Executing command…'; fa = 'Executing command…'");
//		Handler = New NotifyDescription("<ExportProcedureName>", ThisObject);
//		AdditionalReportsAndDataProcessorsClient.ExecuteCommnadInBackground(Command.Name, CommandParameters, Handler);
//	EndProcedure
//
Procedure ExecuteCommandInBackground(Val CommandID, Val CommandParameters, Val Handler) Export
	
	ProcedureName = "AdditionalReportsAndDataProcessorsClient.ExecuteCommandInBackground";
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandID",
		CommandID,
		Type("String"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandParameters",
		CommandParameters,
		Type("Structure"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"CommandParameters.AdditionalDataProcessorRef",
		CommonClientServer.StructureProperty(CommandParameters, "AdditionalDataProcessorRef"),
		Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	CommonClientServer.CheckParameter(
		ProcedureName,
		"Handler",
		Handler,
		New TypeDescription("CallbackDescription, ClientApplicationForm"));
	
	CommandParameters.Insert("CommandID", CommandID);
	MustReceiveResult = CommonClientServer.StructureProperty(CommandParameters, "MustReceiveResult", False);
	
	Form = Undefined;
	If CommandParameters.Property("OwnerForm", Form) Then
		CommandParameters.OwnerForm = Undefined;
	EndIf;
	If TypeOf(Handler) = Type("CallbackDescription") Then
		CommonClientServer.CheckParameter(ProcedureName, "Handler.Module",
			Handler.Module,
			Type("ClientApplicationForm"));
		Form = ?(Form <> Undefined, Form, Handler.Module);
	Else
		Form = Handler;
		Handler = Undefined;
		MustReceiveResult = True; // For backward compatibility purposes.
	EndIf;
	
	Job = AdditionalReportsAndDataProcessorsServerCall.StartTimeConsumingOperation(Form.UUID, CommandParameters);
	
	AccompanyingText1 = CommonClientServer.StructureProperty(CommandParameters, "AccompanyingText1", "");
	Title = CommonClientServer.StructureProperty(CommandParameters, "Title");
	If ValueIsFilled(Title) Then
		AccompanyingText1 = TrimAll(Title + Chars.LF + AccompanyingText1);
	EndIf;
	If Not ValueIsFilled(AccompanyingText1) Then
		AccompanyingText1 = NStr("vi = 'Đang thực hiện lệnh.';
								|ru = 'Команда выполняется.';
								|en = 'Command running.'; fa = 'Command running.';
								|it = 'Comando in esecuzione.';
								|pl = 'Polecenie jest wykonywane.';
								|tr = 'Komut yapılıyor.'");
	EndIf;
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(Form);
	WaitSettings.MessageText       = AccompanyingText1;
	WaitSettings.OutputIdleWindow = True;
	WaitSettings.MustReceiveResult    = MustReceiveResult; // For backward compatibility purposes.
	WaitSettings.OutputMessages    = True;
	WaitSettings.OutputProgressBar = True;
	
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead of using the ChoiceProcessing event along with source analysis,
// use the notification handler (see the Handler parameter in the ExecuteCommandInBackground procedure):
// ChoiceSource.FormName = AdditionalReportsAndDataProcessorsClient.TimeConsumingOperationFormName().
// Returns a form name that is used to identify the outcome of the long-running operation.
//
// 
//
// Returns:
//   String - See ExecuteCommandInBackground.
//
Function TimeConsumingOperationFormName() Export
	
	Return "CommonForm.TimeConsumingOperation";
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Opens the form for picking additional reports.
// Usage locations:
//   Catalog.ReportMailings.Form.ItemForm.AddAdditionalReport.
//
// Parameters:
//   FormItem - Arbitrary - a form item the items are picked for.
//
Procedure ReportDistributionPickAddlReport(FormItem) Export
	
	AdditionalReport = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalReport");
	Report               = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.Report");
	
	FilterByType = New ValueList;
	FilterByType.Add(AdditionalReport, AdditionalReport);
	FilterByType.Add(Report, Report);
	
	ChoiceFormParameters = New Structure;
	ChoiceFormParameters.Insert("WindowOpeningMode",  FormWindowOpeningMode.Independent);
	ChoiceFormParameters.Insert("ChoiceMode",        True);
	ChoiceFormParameters.Insert("CloseOnChoice", False);
	ChoiceFormParameters.Insert("MultipleChoice", True);
	ChoiceFormParameters.Insert("Filter",              New Structure("Kind", FilterByType));
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ChoiceForm", ChoiceFormParameters, FormItem);
	
EndProcedure

// Attachable command clarifying handler.
//
// Parameters:
//   ObjectsToPrint - Array of AnyRef - references to the selected objects for which a command is being executed.
//   ExecutionParameters - See AttachableCommandsClient.CommandExecuteParameters
//
Procedure BeforeExecutePrintCommand(ObjectsToPrint, ExecutionParameters) Export
	
	StartupOption = ExecutionParameters.CommandDetails.AdditionalParameters.AdditionalParameters.StartupOption;
	If StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall")
	 Or StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		Return;
	EndIf;
	
	StandardProcessing = True;
	AdditionalReportsAndDataProcessorsClientOverridable.BeforeExecuteExternalPrintFormPrintCommand(
		ObjectsToPrint, StandardProcessing);
	
	If StandardProcessing And AdditionalReportsAndDataProcessorsServerCall.IsPostingAvailable(ObjectsToPrint) Then
		ExecutionParameters.PostingRequired = True;
	EndIf;
	
EndProcedure

// External print command handler.
//
// Parameters:
//  CommandToExecute - Structure        - a structure from the command table row, see
//                                        AdditionalReportsAndDataProcessors.OnReceivePrintCommands.
//  Form            - ClientApplicationForm - a form where the print command is executed.
//
Procedure ExecuteAssignablePrintCommand(CommandToExecute, Form) Export
	
	// Moving additional parameters passed by this subsystem to the structure root.
	For Each KeyAndValue In CommandToExecute.AdditionalParameters Do
		CommandToExecute.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	// Writing fixed parameters.
	CommandToExecute.Insert("IsReport", False);
	CommandToExecute.Insert("Kind", PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm"));
	
	// Starting the data processor method that matches the command context.
	StartupOption = CommandToExecute.StartupOption;
	If StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		OpenDataProcessorForm(CommandToExecute, Form, CommandToExecute.PrintObjects);
	ElsIf StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		ExecuteDataProcessorClientMethod(CommandToExecute, Form, CommandToExecute.PrintObjects);
	Else
		ExecutePrintFormOpening(CommandToExecute, Form, CommandToExecute.PrintObjects, True);
	EndIf;
	
EndProcedure

// Opens a list of commands of additional reports and data processors for the given objects.
//
// Parameters:
//   Objects - Array of AnyRef - Objects targeted by the command.
//   ExecutionParameters - Structure:
//       * CommandDetails - Structure:
//          ** Id - String - Command ID.
//          ** Presentation - String - Command presentation in a form.
//          ** Name - String - a command name on a form.
//          ** AdditionalParameters - See AdditionalReportsAndDataProcessors.AdditionalCommandParameters
//       * Form - ClientApplicationForm - a form where the command is called.
//       * Source - FormDataStructure
//                  - FormTable - an object or a form list with the Reference field.
//
Procedure OpenCommandList(Val Objects, Val ExecutionParameters) Export
	Context = New Structure;
	Context.Insert("Source", ExecutionParameters.Form);
	Kind = ExecutionParameters.CommandDetails.AdditionalParameters.Kind;
	OpenAdditionalReportAndDataProcessorCommandsForm(Objects, Context, Kind);
EndProcedure

// See AdditionalReportsAndDataProcessors.HandlerFillingCommands
Procedure HandlerFillingCommands(Val ReferencesArrray, Val ExecutionParameters) Export
	Form              = ExecutionParameters.Form;
	Object             = ExecutionParameters.Source;
	CommandToExecute = ExecutionParameters.CommandDetails.AdditionalParameters; // See AdditionalReportsAndDataProcessors.AdditionalFillingCommandParameters
	

	ServerCallParameters = New Structure;
	ServerCallParameters.Insert("CommandID",          CommandToExecute.Id);
	ServerCallParameters.Insert("AdditionalDataProcessorRef", CommandToExecute.Ref);
	ServerCallParameters.Insert("RelatedObjects",             New Array);
	ServerCallParameters.Insert("FormName",                      Form.FormName);
	ServerCallParameters.RelatedObjects.Add(Object.Ref);
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	// Runtime control is supported only for server methods.
	// If a form opens or client-side code is called, the result is output by the data processor.
	If CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		OpenAdditionalReportDataProcessorForm(CommandToExecute.Ref, CommandToExecute.IsReport,
			ServerCallParameters, Form);
		
	ElsIf CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		ExternalObjectForm = AdditionalReportDataProcessorForm(CommandToExecute.Ref, CommandToExecute.IsReport,
			ServerCallParameters, Form);
		If ExternalObjectForm <> Undefined Then
			ExternalObjectForm.ExecuteCommand(ServerCallParameters.CommandID, ServerCallParameters.RelatedObjects);
		EndIf;
		
	ElsIf CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or CommandToExecute.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
		
		ServerCallParameters.Insert("ExecutionResult", New Structure);
		AdditionalReportsAndDataProcessorsServerCall.ExecuteCommand(ServerCallParameters, Undefined);
		
		ApplicationParameters.Insert(ApplicationParameterNameFormCommandExecutionOwner(), Form);
		AttachIdleHandler("OnCompleteFillCommandExecution", 0.1, True);
	EndIf;
	
EndProcedure

Procedure OpenAdditionalReportsAndDataProcessorsList() Export
	
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ListForm");
	
EndProcedure

#EndRegion

#Region Private

Procedure OpenAdditionalReportDataProcessorForm(AdditionalReportDataProcessor, IsReport, FormParameters, OwnerForm)

	FormName = AdditionalReportDataProcessorFormName(AdditionalReportDataProcessor, IsReport);
	If IsBlankString(FormName) Then
		Return;
	EndIf;
	OpenForm(FormName, FormParameters, OwnerForm);

EndProcedure

Function AdditionalReportDataProcessorForm(AdditionalReportDataProcessor, IsReport, FormParameters, OwnerForm)

	FormName = AdditionalReportDataProcessorFormName(AdditionalReportDataProcessor, IsReport);
	If IsBlankString(FormName) Then
		Return Undefined;
	EndIf;
	Return GetForm(FormName, FormParameters, OwnerForm); // ACC:65 - Intended for backward compatibility: Invocation of a client data processor procedure.

EndFunction

Function AdditionalReportDataProcessorFormName(AdditionalReportDataProcessor, IsReport)

	If TypeOf(AdditionalReportDataProcessor) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		Return "";
	EndIf;
	
	ExternalObjectName = AdditionalReportsAndDataProcessorsServerCall.AttachExternalDataProcessor(AdditionalReportDataProcessor);
	Return ?(IsReport, StrTemplate("ExternalReport.%1.Form", ExternalObjectName),
		StrTemplate("ExternalDataProcessor.%1.Form", ExternalObjectName));

EndFunction

Procedure ShowNotificationOnCommandExecution(CommandToExecute)
	If CommandToExecute.ShouldShowUserNotification Then
		ShowUserNotification(NStr("vi = 'Đang thực hiện lệnh...';
									|ru = 'Команда выполняется...';
									|en = 'Command running…'; fa = 'Command running…';
									|it = 'Comando in esecuzione...';
									|pl = 'Polecenie jest wykonywane...';
									|tr = 'Komut yapılıyor...'"), , CommandToExecute.Presentation);
	EndIf;
EndProcedure

Procedure OpenDataProcessorForm(CommandToExecute, Form, RelatedObjects) Export
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName, SessionKey1");
	ProcessingParameters.CommandID          = CommandToExecute.Id;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                      = ?(Form = Undefined, Undefined, Form.FormName);
	ProcessingParameters.SessionKey1 = CommandToExecute.Ref.UUID();
	
	If TypeOf(RelatedObjects) = Type("Array") Then
		ProcessingParameters.Insert("RelatedObjects", RelatedObjects);
	EndIf;
	
#If ThickClientOrdinaryApplication Then
	ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.ExternalDataProcessorObject(CommandToExecute.Ref);
	DataProcessorForm = ExternalDataProcessor.GetForm(, Form); // ACC:65 - Improves diagnostics.
	If DataProcessorForm = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không có biểu mẫu chính nào được chỉ định cho báo cáo hoặc quá trình xử lý ""%1"", 
			|hoặc biểu mẫu chính không nhằm chạy trong một ứng dụng thông thường.
			|Không thể thực hiện lệnh ""%2"".';
			|ru = 'Для отчета или обработки ""%1"" не назначена основная форма,
			|или основная форма не предназначена для запуска в обычном приложении.
			|Команда ""%2"" не может быть выполнена.';
			|en = '%1 report or data processor is missing the main form,
			|or the main form does not support standard applications.
			|Command %2 failed.'; fa = '%1 report or data processor is missing the main form,
			|or the main form does not support standard applications.
			|Command %2 failed.';
			|it = 'Per il report o per l''elaborazione ""%1"" non è impostato un modello principale,
			|oppure il modello non è predisposto per l''avvio nell''applicazione standard.
			|Il comando ""%2"" non può essere eseguito.';
			|pl = 'Dla raportu lub przetwarzania ""%1""nie określono formularzu podstawowego,
			|lub formularz podstawowy nie jest przeznaczony do uruchomienia w zwykłej aplikacji.
			|Polecenie ""%2"" nie może być wykonane.';
			|tr = 'Rapor veya veri işlemcisi için ""%1"" ana form 
			|atanmamış veya ana formun, normal uygulamada başlatılması amaçlanmamıştır. 
			|Komut ""%2"" çalıştırılamıyor.'"),
			String(CommandToExecute.Ref),
			CommandToExecute.Presentation);
	EndIf;
	DataProcessorForm.Open();
	DataProcessorForm = Undefined;
#Else
	OpenAdditionalReportDataProcessorForm(CommandToExecute.Ref, CommandToExecute.IsReport, ProcessingParameters, Form);
#EndIf

EndProcedure

Procedure ExecuteDataProcessorClientMethod(CommandToExecute, Form, RelatedObjects) Export
	
	ShowNotificationOnCommandExecution(CommandToExecute);
	
	ProcessingParameters = New Structure("CommandID, AdditionalDataProcessorRef, FormName");
	ProcessingParameters.CommandID          = CommandToExecute.Id;
	ProcessingParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcessingParameters.FormName                      = ?(Form = Undefined, Undefined, Form.FormName);
	
	If TypeOf(RelatedObjects) = Type("Array") Then
		ProcessingParameters.Insert("RelatedObjects", RelatedObjects);
	EndIf;
	
#If ThickClientOrdinaryApplication Then
	ExternalDataProcessor = AdditionalReportsAndDataProcessorsServerCall.ExternalDataProcessorObject(CommandToExecute.Ref);
	DataProcessorForm = ExternalDataProcessor.GetForm(, Form); // ACC:65 - Improves diagnostics.
	If DataProcessorForm = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không có biểu mẫu chính nào được chỉ định cho báo cáo hoặc quá trình xử lý ""%1"",
			|hoặc biểu mẫu chính không nhằm chạy trong một ứng dụng thông thường.
			|Không thể thực hiện lệnh ""%2"".';
			|ru = 'Для отчета или обработки ""%1"" не назначена основная форма,
			|или основная форма не предназначена для запуска в обычном приложении.
			|Команда ""%2"" не может быть выполнена.';
			|en = '%1 report or data processor is missing the main form,
			|or the main form does not support standard applications.
			|Command %2 failed.'; fa = '%1 report or data processor is missing the main form,
			|or the main form does not support standard applications.
			|Command %2 failed.';
			|it = 'Per il report o per l''elaborazione ""%1"" non è impostato un modello principale,
			|oppure il modello non è predisposto per l''avvio nell''applicazione standard.
			|Il comando ""%2"" non può essere eseguito.';
			|pl = 'Dla raportu lub przetwarzania ""%1""nie określono formularzu podstawowego,
			|lub formularz podstawowy nie jest przeznaczony do uruchomienia w zwykłej aplikacji.
			|Polecenie ""%2"" nie może być wykonane.';
			|tr = 'Rapor veya veri işlemcisi için ""%1"" ana form 
			|atanmamış veya ana formun, normal uygulamada başlatılması amaçlanmamıştır. 
			|Komut ""%2"" çalıştırılamıyor.'"),
			String(CommandToExecute.Ref),
			CommandToExecute.Presentation);
	EndIf;
#Else
	DataProcessorForm = AdditionalReportDataProcessorForm(CommandToExecute.Ref, CommandToExecute.IsReport, ProcessingParameters, Form);
#EndIf
	
	If CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor")
		Or CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.AdditionalReport") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.RelatedObjectsCreation") Then
		
		CreatedObjects = New Array;
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id, RelatedObjects, CreatedObjects);
		
		CreatedObjectTypes = New Array;
		For Each CreatedObject In CreatedObjects Do
			Type = TypeOf(CreatedObject);
			If CreatedObjectTypes.Find(Type) = Undefined Then
				CreatedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In CreatedObjectTypes Do
			NotifyChanged(Type);
		EndDo
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.PrintForm") Then
		
		DataProcessorForm.Print(CommandToExecute.Id, RelatedObjects);
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.ObjectFilling") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id, RelatedObjects);
		
		ModifiedObjectTypes = New Array;
		For Each ModifiedObject In RelatedObjects Do
			Type = TypeOf(ModifiedObject);
			If ModifiedObjectTypes.Find(Type) = Undefined Then
				ModifiedObjectTypes.Add(Type);
			EndIf;
		EndDo;
		
		For Each Type In ModifiedObjectTypes Do
			NotifyChanged(Type);
		EndDo
		
	ElsIf CommandToExecute.Kind = PredefinedValue("Enum.AdditionalReportsAndDataProcessorsKinds.Report") Then
		
		DataProcessorForm.ExecuteCommand(CommandToExecute.Id, RelatedObjects);
		
	EndIf;
	
	DataProcessorForm = Undefined;
	
EndProcedure

// Generates a spreadsheet document in the Print subsystem form.
Procedure ExecutePrintFormOpening(CommandToExecute, Form, RelatedObjects, FromAttachableCommand = False) Export
	
	If FromAttachableCommand Then
		StandardProcessing = False;
	Else
		StandardProcessing = True;
		AdditionalReportsAndDataProcessorsClientOverridable.BeforeExecuteExternalPrintFormPrintCommand(
			RelatedObjects, StandardProcessing);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
		ModulePrintManagerInternalClient.ExecutePrintFormOpening(
			CommandToExecute.Ref,
			CommandToExecute.Id,
			RelatedObjects,
			Form,
			StandardProcessing);
	EndIf;
	
EndProcedure

// Shows the extension installation dialog box, and then exports additional report or data processor data.
//
// Parameters:
//   ExportingParameters - Structure:
//   * Ref - AnyRef
//
Procedure ExportToFile(ExportingParameters) Export
	Var Address;
	
	ExportingParameters.Property("DataProcessorDataAddress", Address);
	If Not ValueIsFilled(Address) Then
		Address = AdditionalReportsAndDataProcessorsServerCall.PutInStorage(ExportingParameters.Ref, Undefined);
	EndIf;
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	SavingParameters.SuggestionText = NStr("vi = 'Để lưu xử lý bên ngoài (báo cáo) vào một tệp, nên cài đặt tiện ích mở rộng để làm việc với 1C: Enterprise.';
											|ru = 'Для сохранения внешней обработки (отчета) в файл рекомендуется установить расширение для работы с 1С:Предприятием.';
											|en = 'It is recommended that you install 1C:Enterprise Extension before you save the external report or data processor to a file.'; fa = 'It is recommended that you install 1C:Enterprise Extension before you save the external report or data processor to a file.';
											|it = 'Per salvare un''elaborazione esterna (report) nel file si consiglia di impostare l''estensione di lavoro con 1C:Enterprise.';
											|pl = 'W celu zapisywania zewnętrznego przetwarzania (raportu) do pliku, zalecane jest zainstalowanie rozszerzenia do pracy z 1C:Enterprise.';
											|tr = 'Harici bir veri işlemcisini (rapor) dosyaya kaydetmek için, 1C:Enterprise ile çalışmak için uzantıyı yükleyin.'");
	SavingParameters.Dialog.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	SavingParameters.Dialog.Title = NStr("vi = 'Hãy chỉ ra tệp';
										|ru = 'Укажите файл';
										|en = 'Select file'; fa = 'انتخاب فایل';
										|it = 'Indicate un file';
										|pl = 'Wskaż plik';
										|tr = 'Dosyayı belirtin'");
	SavingParameters.Dialog.FilterIndex = ?(ExportingParameters.IsReport, 1, 2);
	SavingParameters.Dialog.FullFileName = ExportingParameters.FileName;
	
	FileSystemClient.SaveFile(Undefined, Address, ExportingParameters.FileName, SavingParameters);
	
EndProcedure

// Intended for the PopulateCommandHandler procedure
Procedure UpdateDataInForm() Export
	
	ParameterName = ApplicationParameterNameFormCommandExecutionOwner();
	If ApplicationParameters[ParameterName] = Undefined Then
		Return;
	EndIf;
	
	Form = ApplicationParameters[ParameterName];
	Form.Read();
	
	ApplicationParameters[ParameterName] = Undefined;
	
EndProcedure

Function ApplicationParameterNameFormCommandExecutionOwner()
	
	Return "StandardSubsystems.AdditionalReportsAndDataProcessors.FormCommandExecutionOwner";
	
EndFunction

#EndRegion
