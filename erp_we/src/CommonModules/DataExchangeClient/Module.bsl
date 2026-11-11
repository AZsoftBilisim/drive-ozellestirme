///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Handler procedure intended to close the exchange plan node settings form.
//
// Parameters:
//  Form - ClientApplicationForm - a form the procedure is called from.
// 
Procedure NodesSetupFormCloseFormCommand(Form) Export
	
	If Not Form.CheckFilling() Then
		Return;
	EndIf;
	
	Form.Modified = False;
	FillStructureData(Form);
	Form.Close(Form.Context);
	
EndProcedure

// Handler procedure intended to close the exchange plan node settings form.
//
// Parameters:
//  Form - ClientApplicationForm - a form the procedure is called from.
// 
Procedure NodeSettingsFormCloseFormCommand(Form) Export
	
	OnCloseExchangePlanNodeSettingsForm(Form, "NodeFiltersSetting");
	
EndProcedure

// Handler procedure intended to close the form for setting default exchange plan node values.
//
// Parameters:
//  Form - ClientApplicationForm - a form the procedure is called from.
// 
Procedure DefaultValueSetupFormCloseFormCommand(Form) Export
	
	OnCloseExchangePlanNodeSettingsForm(Form, "DefaultNodeValues");
	
EndProcedure

// Handler procedure intended to close the exchange plan node settings form.
//
// Parameters:
//  Cancel            - Boolean           - a flag showing whether form closing is canceled.
//  Form            - ClientApplicationForm - a form the procedure is called from.
//  Exit - Boolean           - indicates whether the form closes when a user exits the application.
// 
// Example:
//
//	&AtClient
//	Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
//		DataExchangeClient.SetupFormBeforeClose(Cancel,ThisObject,WorkCompletion);
//	EndProcedure
//
Procedure SetupFormBeforeClose(Cancel, Form, Exit) Export
	
	ProcedureName = "DataExchangeClient.SetupFormBeforeClose";
	CommonClientServer.CheckParameter(ProcedureName, "Cancel", Cancel, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "Exit", Exit, Type("Boolean"));
	
	If Not Form.Modified Then
		Return;
	EndIf;
		
	Cancel = True;
	
	If Exit Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Đã thay đổi dữ liệu. Đóng biểu mẫu mà không lưu lại thay đổi?';
					|ru = 'Данные были изменены. Закрыть форму без сохранения изменений?';
					|en = 'Close the form without saving the changes?'; fa = 'Close the form without saving the changes?';
					|it = 'I dati sono stati modificati. Chiudere il form senza salvare le modifiche?';
					|pl = 'Dane zostały zmienione. Zamknąć formularz bez zachowania zmian?';
					|tr = 'Veriler değiştirildi. Değişiklikleri kaydetmeden formu kapatmak istiyor musunuz?'");
	CallbackDescription = New CallbackDescription("SetupFormBeforeCloseCompletion", ThisObject, Form);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.No);
	
EndProcedure

// Handler of item choice start for correspondent base node settings form on setting exchange through
// external connection.
//
// Parameters:
//  AttributeName - String - a form attribute name.
//  TableName - String - Full name of a metadata object.
//  Owner - ClientApplicationForm - a form to select the correspondent base items.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is executed.
//  ExternalConnectionParameters - Structure
//  ChoiceParameters - Structure - a structure of choice parameters.
//
Procedure CorrespondentInfobaseItemSelectionHandlerStartChoice(Val AttributeName, Val TableName, Val Owner,
	Val StandardProcessing, Val ExternalConnectionParameters, Val ChoiceParameters=Undefined) Export
	
	IDAttributeName = AttributeName + "_Key";
	
	ChoiceInitialValue = Undefined;
	ChoiceFoldersAndItems    = Undefined;
	
	OwnerType = TypeOf(Owner);
	If OwnerType=Type("FormTable") Then
		CurrentData = Owner.CurrentData;
		If CurrentData<>Undefined Then
			ChoiceInitialValue = CurrentData[IDAttributeName];
		EndIf;
		
	ElsIf OwnerType=Type("ClientApplicationForm") Then
		ChoiceInitialValue = Owner[IDAttributeName];
		
	EndIf;
	
	If ChoiceParameters<>Undefined Then
		If ChoiceParameters.Property("ChoiceFoldersAndItems") Then
			ChoiceFoldersAndItems = ChoiceParameters.ChoiceFoldersAndItems;
		EndIf;
	EndIf;
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalConnectionParameters",        ExternalConnectionParameters);
	FormParameters.Insert("CorrespondentInfobaseTableFullName", TableName);
	FormParameters.Insert("ChoiceInitialValue",            ChoiceInitialValue);
	FormParameters.Insert("AttributeName",                       AttributeName);
	FormParameters.Insert("ChoiceFoldersAndItems",               ChoiceFoldersAndItems);
	
	OpenForm("CommonForm.SelectCorrespondentInfobaseObjects", FormParameters, Owner);
	
EndProcedure

// Handler of picking up items for correspondent base node settings form on setting exchange through external
// connection.
//
// Parameters:
//  AttributeName - String - a form attribute name.
//  TableName - String - Full name of a metadata object.
//  Owner - ClientApplicationForm - a form to select the correspondent base items.
//  ExternalConnectionParameters - Structure
//  ChoiceParameters - Structure - a structure of choice parameters.
//
Procedure CorrespondentInfobaseItemSelectionHandlerPick(Val AttributeName, Val TableName, Val Owner,
	Val ExternalConnectionParameters, Val ChoiceParameters=Undefined) Export
	
	IDAttributeName = AttributeName + "_Key";
	
	ChoiceInitialValue = Undefined;
	ChoiceFoldersAndItems    = Undefined;
	
	CurrentData = Owner.CurrentData;
	If CurrentData <> Undefined Then
		ChoiceInitialValue = CurrentData[IDAttributeName];
	EndIf;
	
	If ChoiceParameters <> Undefined Then
		If ChoiceParameters.Property("ChoiceFoldersAndItems") Then
			ChoiceFoldersAndItems = ChoiceParameters.ChoiceFoldersAndItems;
		EndIf;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ExternalConnectionParameters",        ExternalConnectionParameters);
	FormParameters.Insert("CorrespondentInfobaseTableFullName", TableName);
	FormParameters.Insert("ChoiceInitialValue",            ChoiceInitialValue);
	FormParameters.Insert("CloseOnChoice",                 False);
	FormParameters.Insert("AttributeName",                       AttributeName);
	FormParameters.Insert("ChoiceFoldersAndItems",               ChoiceFoldersAndItems);
	
	OpenForm("CommonForm.SelectCorrespondentInfobaseObjects", FormParameters, Owner);
EndProcedure

// Handler of item choice processing for correspondent base node settings form on setting exchange through
// external connection.
//
// Parameters:
//  Item - ClientApplicationForm
//          - FormTable - an item to process selection.
//  ValueSelected - Arbitrary - see the SelectedValue parameter description of the ChoiceProcessing event.
//  FormDataCollection - FormDataCollection - for picking from list.
//
Procedure CorrespondentInfobaseItemsSelectionHandlerChoiceProcessing(Val Item, Val ValueSelected, Val FormDataCollection=Undefined) Export
	
	If TypeOf(ValueSelected)<>Type("Structure") Then
		Return;
	EndIf;
	
	IDAttributeName = ValueSelected.AttributeName + "_Key";
	PresentationAttributeName  = ValueSelected.AttributeName;
	
	ElementType = TypeOf(Item);
	If ElementType=Type("FormTable") Then
		
		If ValueSelected.PickMode Then
			If FormDataCollection<>Undefined Then
				Filter = New Structure(IDAttributeName, ValueSelected.Id);
				ExistingRows = FormDataCollection.FindRows(Filter);
				If ExistingRows.Count() > 0 Then
					Return;
				EndIf;
			EndIf;
			
			Item.AddRow();
		EndIf;
		
		CurrentData = Item.CurrentData;
		If CurrentData<>Undefined Then
			CurrentData[IDAttributeName] = ValueSelected.Id;
			CurrentData[PresentationAttributeName]  = ValueSelected.Presentation;
		EndIf;
		
	ElsIf ElementType=Type("ClientApplicationForm") Then
		Item[IDAttributeName] = ValueSelected.Id;
		Item[PresentationAttributeName]  = ValueSelected.Presentation;
		
	EndIf;
	
EndProcedure

// Checks whether the Use flag is set for all table rows.
//
// Parameters:
//  Table - ValueTable - a table to be checked.
//
// Returns:
//  Boolean - the flag that indicates using all items.
//
Function AllRowsMarkedInTable(Table) Export
	
	For Each Item In Table Do
		
		If Item.Use = False Then
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
EndFunction

// Deletes data synchronization settings item.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef - an exchange plan node corresponding to the exchange to be disabled.
//
Procedure DeleteSynchronizationSetting(Val InfobaseNode) Export
	
	If DataExchangeServerCall.IsMasterNode(InfobaseNode) Then
		WarningText = NStr("vi = 'Có thể ngắt cơ sở thông tin khỏi nút chính
			|thông qua tham số khởi động bộ thiết kế /ResetMasterNode.';
			|ru = 'Отключение информационной базы от главного узла можно выполнить
			|с помощью параметра запуска конфигуратора /ResetMasterNode.';
			|en = 'To detach the infobase from the main node,
			|start Designer with parameter /ResetMasterNode.'; fa = 'To detach the infobase from the main node,
			|start Designer with parameter /ResetMasterNode.';
			|it = 'La disattivazione del database dal nodo principale può essere effettuata
			|grazie al parametro d''avvio del configuratore /ResetMasterNode.';
			|pl = 'Odłączenie bazy informacyjnej od głównego węzła można wykonać
			|za pomocą parametrów uruchomienia konfiguratorа /ResetMasterNode.';
			|tr = 'Yapılandırıcı çalıştırma parametresi /ResetMasterNode yardımıyla 
			|Infobase''in ana ünite ile bağlantısı kapatılabilir.'");
		ShowMessageBox(, WarningText);
	Else
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangeNode", InfobaseNode);
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.DeleteSyncSetting", WizardParameters);
	EndIf;
	
EndProcedure

// Handler of the exchange plan node save. If required, saves the node by a long-running operation
//
// Parameters:
//  Form - ClientApplicationForm - an exchange plan node.
//  Cancel - Boolean - indicates whether the exchange plan node save is canceled.
//  WriteParameters - Structure - arbitrary save parameters. See the AfterWrite event details in Syntax Assistant.
//
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	CheckResult = DataExchangeServerCall.CheckTheNeedForADeferredNodeEntry(Form.Object);
	
	If CheckResult.ThereIsAnActiveBackgroundTask Then 
					
		WarningText = NStr("vi = 'Đang thực hiện giao dịch hoãn lại để ghi lại nút.
										|Hãy thử lại sau';
										|ru = 'Уже выполняется отложенная операция записи узла.
										|Повторите попытку позже';
										|en = 'Deferred node saving operation is already in progress.
										|Try again later'; fa = 'Deferred node saving operation is already in progress.
										|Try again later';
										|it = 'L''operazione differita di registrazione del nodo è già in esecuzione.
										|Ripetere il tentativo più tardi';
										|pl = 'Już trwa odroczona operacja zapisu węzła.
										|Powtórz próbę poźniej';
										|tr = 'Ertelenen ünite yazma işlemi zaten devam ediyor.
										|Lütfen daha sonra tekrar deneyin.'");
		
		ShowMessageBox(, WarningText);

		Cancel = True;	
		
	ElsIf CheckResult.ALongTermOperationIsRequired Then
		
		Object = Form.Object; // FormDataStructure
		
		ProcessingParameters = New Structure;
		ProcessingParameters.Insert("Node", 				Object.Ref);
		ProcessingParameters.Insert("NodeStructureAddress", 	CheckResult.NodeStructureAddress);
		
		Form.Modified = False;
		Form.Close();
		
		OpenForm("DataProcessor.DeferredNodeWriting.Form.Form", ProcessingParameters,,,,,,FormWindowOpeningMode.LockOwnerWindow);

		Cancel = True;
		
	EndIf;
	
EndProcedure

// A URL handler of the node form. Applies to the elements that were created programmatically.
// Supports only SaaS infobases.
//
// Parameters:
//  Form - ClientApplicationForm - an exchange plan node.
//  Item - FormItems
//  URL -  String - The generated URL.
//  StandardProcessing - Boolean
//
Procedure HandleURLInNodeForm(Form, Item, URL, StandardProcessing) Export
	
	StandardProcessing = False;
	
	If CommonClient.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeInternalPublicationClient = CommonClient.CommonModule("DataExchangeInternalPublicationClient");
		ModuleDataExchangeInternalPublicationClient.HandleURLInNodeForm(
			Form, URL, StandardProcessing);
	EndIf;
	
EndProcedure

// Opens the data synchronization settings panel.
//
// Parameters:
//  CommandParameter - Structure
//                  - Undefined
//  CommandExecuteParameters - CommandExecuteParameters
//
Procedure OpenDataSynchronizationPanel(CommandParameter, CommandExecuteParameters) Export
	
	DataProcessorName      = "";
	DataProcessorFormName = "";
	
	If StandardSubsystemsClient.ClientRunParameters().SeparatedDataUsageAvailable Then
		If CommonClient.SubsystemExists("DataExchangeApplicationSettings") Then
			DataProcessorName      = "DSLAdministrationPanel";
			DataProcessorFormName = "DataSynchronization";
		ElsIf CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
			DataProcessorName      = "SSLAdministrationPanel";
			DataProcessorFormName = "DataSynchronization";
		EndIf;	
	Else
		If Not CommonClient.SubsystemExists("CloudTechnology") Then
			Return;
		EndIf;
		
		DataProcessorName      = "SSLAdministrationPanelSaaS";
		DataProcessorFormName = "DataSynchronizationForServiceAdministrator";
	EndIf;
	
	If DataProcessorName = "" Then
		Return;
	EndIf;
	
	NameOfFormToOpen_ = "DataProcessor.[DataProcessorName].Form.[DataProcessorFormName]";
	NameOfFormToOpen_ = StrReplace(NameOfFormToOpen_, "[DataProcessorName]", DataProcessorName);
	NameOfFormToOpen_ = StrReplace(NameOfFormToOpen_, "[DataProcessorFormName]", DataProcessorFormName);
	
	OpenForm(
		NameOfFormToOpen_,
		New Structure,
		CommandExecuteParameters.Source,
		NameOfFormToOpen_ + ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

// Opens the form for changing the infobase prefix.
//
// Parameters:
//  IBPrefix - String - The current infobase prefix.
//
Procedure OpenInfobasePrefixChangeForm(Val IBPrefix) Export
	
	FormParameters = New Structure("Prefix", IBPrefix);
	
	NameOfPrefixChangeForm = "DataProcessor.DataExchangeCreationWizard.Form.ChangeInfobaseNodePrefix";
	OpenForm(NameOfPrefixChangeForm, FormParameters,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens the form for clearing up synchronization warnings.
//
// Parameters:
//  OpeningParameters - Structure - Structure with warning filters, where:
//     * ArrayOfExchangePlanNodes - Array of ExchangePlanRef - Array with exchange plan nodes that can be used.
//     * SelectionByDateOfOccurrence - Date - End date for filtering warnings.
//     * SelectionOfExchangePlanNodes - Array of ExchangePlanRef - Array of exchange plan nodes
//                                                            where the warnings are being deleted.
//     * SelectingTypesOfWarnings - Array of EnumRef.DataExchangeIssuesTypes
//                                           EnumRef.ObjectVersionTypes - Types of the warnings being deleted.
//     * OnlyHiddenRecords - Boolean - Filter for deletion only hidden warning records.
//  CallbackDescription - CallbackDescription
//
Procedure OpenFormForDeletingSyncAlerts(OpeningParameters, CallbackDescription = Undefined) Export
	
	NameOfAlertDeletionForm = "InformationRegister.DataExchangeResults.Form.ObsoleteWarningsDeletion";
	OpenForm(NameOfAlertDeletionForm, OpeningParameters, ThisObject, , , , CallbackDescription);
	
EndProcedure

// Opens the form of monitor for data registered for sending.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - 
//
Procedure OpenCompositionOfDataToSend(Val InfobaseNode) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ExchangeNode", InfobaseNode);
	FormParameters.Insert("SelectExchangeNodeProhibited", True);
	
	// Internal data that cannot be modified if the data processor is called from a command.
	FormParameters.Insert("NamesOfMetadataToHide", New ValueList);
	FormParameters.NamesOfMetadataToHide.Add("InformationRegister.InfobaseObjectsMaps");
	
	NotExportByRules = DataExchangeServerCall.NotExportedNodeObjectsMetadataNames(InfobaseNode);
	For Each NameOfMetadataObjects In NotExportByRules Do
		FormParameters.NamesOfMetadataToHide.Add(NameOfMetadataObjects);
	EndDo;
	
	OpenForm("DataProcessor.RegisterChangesForDataExchange.Form", FormParameters,, InfobaseNode);
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. Opens the form of data exchange settings wizard for the specified exchange plan.
//
// Parameters:
//  ExchangePlanName         - String - a name of the exchange plan (as a metadata object)
//                                    for which the wizard is to be opened.
//  SettingID - String - ID of data exchange settings option.
// 
Procedure OpenDataExchangeSetupWizard(Val ExchangePlanName, Val SettingID) Export
	
	// The procedure is not used as the "ConnectionSetup" form is not used to set up synchronization
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Modally opens the event log with filter by data export or import events for the specified exchange plan
// node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - 
//  Owner - MetadataObject - 
//  ActionOnExchange - EnumRef.ActionsOnExchange - 
// 
Procedure GoToDataEventLogModally(InfobaseNode, Owner, ActionOnExchange) Export
	
	// Server call.
	FormParameters = DataExchangeServerCall.EventLogFilterData(InfobaseNode, ActionOnExchange);
	
	OpenForm("DataProcessor.EventLog.Form", FormParameters, Owner);
	
EndProcedure

// Returns the name of the message form that contains a notification about an infobase update error that occurs due to an ORR error.
// 
// Returns:
//  String - a name of failed update message form.
//
Function FailedUpdateMessageFormName() Export
	
	Return "InformationRegister.DataExchangeRules.Form.FailedUpdateMessage";
	
EndFunction

// Updates database configuration.
//
// Parameters:
//  ShouldExitApp - Boolean - 
//
Procedure InstallConfigurationUpdate(ShouldExitApp = False) Export
	
	If CommonClient.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdateClient = CommonClient.CommonModule("ConfigurationUpdateClient");
		ModuleConfigurationUpdateClient.InstallConfigurationUpdate(ShouldExitApp);
	Else
		OpenForm("CommonForm.AdditionalDetails", New Structure("Title,TemplateName",
		NStr("vi = 'Cài đặt bản cập nhật';
			|ru = 'Установка обновления';
			|en = 'Install update'; fa = 'نصب به‌روزرسانی';
			|it = 'Installazione dell''aggiornamento';
			|pl = 'Instalacja aktualizacji';
			|tr = 'Güncelleme kurulumu'"), "ManualUpdateInstruction"));
	EndIf;
	
EndProcedure


////////////////////////////////////////////////////////////////////////////////
// Event handlers of configuration subsystems.

// See CommonClientOverridable.BeforeStart.
Procedure BeforeStart(Parameters) Export
	
	If StrFind(LaunchParameter, "DownloadExtensionsAndShutDown") > 0 Then
				
		DataExchangeServerCall.DownloadExtensions();
		Terminate();
				
	EndIf;
	
	// When launching the infobase on a child node and reimporting exchange messages
	// is required, let the user decide if the import starts or skip it and resume.
	// 
	// 
	
	ClientParameters = StandardSubsystemsClient.ClientParametersOnStart();
	
	If Not ClientParameters.Property("RetryDataExchangeMessageImportBeforeStart") Then
		Return;
	EndIf;
	
	Parameters.InteractiveHandler = New CallbackDescription(
		"RetryDataExchangeMessageImportBeforeStartInteractiveHandler", ThisObject);
	
EndProcedure

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If ClientRunParameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup") Then
		
		For Each Window In GetWindows() Do
			If Window.IsMain Then
				Window.Activate();
				Break;
			EndIf;
		EndDo;
		
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangePlanName",         ClientRunParameters.DIBExchangePlanName);
		WizardParameters.Insert("SettingID", ClientRunParameters.DIBNodeSettingID);
		WizardParameters.Insert("NewSYnchronizationSetting");
		WizardParameters.Insert("ContinueSetupInSubordinateDIBNode");
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SyncSetup", WizardParameters);
	EndIf;
	
EndProcedure

// See CommonClientOverridable.AfterStart.
Procedure AfterStart() Export
	
	ClientRunParameters = StandardSubsystemsClient.ClientParametersOnStart();
	If Not ClientRunParameters.SeparatedDataUsageAvailable Or ClientRunParameters.DataSeparationEnabled Then
		Return;
	EndIf;
		
	If Not ClientRunParameters.IsMasterNode1
		And Not ClientRunParameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup")
		And ClientRunParameters.Property("CheckSubordinateNodeConfigurationUpdateRequired") Then
		
		AttachIdleHandler("CheckSubordinateNodeConfigurationUpdateRequiredOnStart", 1, True);
		
	EndIf;
	
EndProcedure

// Opens a form for writing information register by a given filter.
Procedure OpenInformationRegisterWriteFormByFilter(
		Filter,
		FillingValues,
		Val RegisterName,
		OwnerForm,
		Val FormName = "",
		FormParameters = Undefined,
		ClosingNotification1 = Undefined) Export
	
	Var RecordKey;
	
	EmptyRecordSet = DataExchangeServerCall.RegisterRecordSetIsEmpty(Filter, RegisterName);
	
	If Not EmptyRecordSet Then
		// Filling value type using the Type operator because other methods are not available at client.
		
		ValueType = Type("InformationRegisterRecordKey." + RegisterName);
		Parameters = New Array(1);
		Parameters[0] = Filter;
		
		RecordKey = New(ValueType, Parameters);
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("Key",               RecordKey);
	WriteParameters.Insert("FillingValues", FillingValues);
	
	If FormParameters <> Undefined Then
		
		For Each Item In FormParameters Do
			
			WriteParameters.Insert(Item.Key, Item.Value);
			
		EndDo;
		
	EndIf;
	
	If IsBlankString(FormName) Then
		
		FullFormName = "InformationRegister.[RegisterName].RecordForm";
		FullFormName = StrReplace(FullFormName, "[RegisterName]", RegisterName);
		
	Else
		
		FullFormName = "InformationRegister.[RegisterName].Form.[FormName]";
		FullFormName = StrReplace(FullFormName, "[RegisterName]", RegisterName);
		FullFormName = StrReplace(FullFormName, "[FormName]", FormName);
		
	EndIf;
	
	// Opening the information register record form.
	If ClosingNotification1 <> Undefined Then
		OpenForm(FullFormName, WriteParameters, OwnerForm, , , , ClosingNotification1);
	Else
		OpenForm(FullFormName, WriteParameters, OwnerForm);
	EndIf;
	
EndProcedure

Procedure InitIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters = New Structure;
	IdleHandlerParameters.Insert("MinInterval", 1);
	IdleHandlerParameters.Insert("MaxInterval", 15);
	IdleHandlerParameters.Insert("CurrentInterval", 1);
	IdleHandlerParameters.Insert("IntervalIncreaseCoefficient", 1.4);
	
EndProcedure

Procedure UpdateIdleHandlerParameters(IdleHandlerParameters) Export
	
	IdleHandlerParameters.CurrentInterval = Min(IdleHandlerParameters.MaxInterval,
		Round(IdleHandlerParameters.CurrentInterval * IdleHandlerParameters.IntervalIncreaseCoefficient, 1));
		
EndProcedure

// Opens the form of data exchange execution for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which the form is to open;
//  Owner               - Form-an owner of the form being opened;
// 
Procedure ExecuteDataExchangeCommandProcessing(InfobaseNode, Owner,
		AccountPasswordRecoveryAddress = "", Val AutoSynchronization = Undefined, AdditionalParameters = Undefined) Export
	
	If AutoSynchronization = Undefined Then
		AutoSynchronization = (DataExchangeServerCall.DataExchangeOption(InfobaseNode) = "Synchronization");
	EndIf;
	
	WizardFormName = "";
	
	FormParameters = New Structure;
	FormParameters.Insert("InfobaseNode", InfobaseNode);
	
	If AutoSynchronization Then
		WizardFormName = "DataProcessor.DataExchangeExecution.Form";
		FormParameters.Insert("AccountPasswordRecoveryAddress", AccountPasswordRecoveryAddress);
	Else
		WizardFormName = "DataProcessor.InteractiveDataExchangeWizard.Form";
		FormParameters.Insert("AdvancedExportAdditionMode", True);
	EndIf;

	ClosingNotification1 = Undefined;
	
	If Not AdditionalParameters = Undefined Then
		
		If AdditionalParameters.Property("WizardParameters") Then
			For Each CurrentParameter In AdditionalParameters.WizardParameters Do
				FormParameters.Insert(CurrentParameter.Key, CurrentParameter.Value);
			EndDo;
		EndIf;
		
		AdditionalParameters.Property("ClosingNotification1", ClosingNotification1);
		
	EndIf;
	
	OpenForm(WizardFormName,
		FormParameters, Owner, InfobaseNode.UUID(), , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Starts receiving a file from the server interactively without using 1C:Enterprise Extension.
//
// Parameters:
//     FileToReceive   - Structure - details of the file to be received. It contains the Name and Location properties.
//     DialogParameters - Structure - optional additional parameters of file selection dialog.
//
Procedure SelectAndSaveFileAtClient(Val FileToReceive, Val DialogParameters = Undefined) Export
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("Title",               NStr("vi = 'Hãy chọn tệp để lưu';
															|ru = 'Выберите файл для сохранения';
															|en = 'Select file to download'; fa = 'Select file to download';
															|it = 'Scegliete un file per il salvataggio';
															|pl = 'Wybierz plik do zapisania';
															|tr = 'Kaydedilecek dosyayı seçin'"));
	DefaultDialogOptions.Insert("MultipleChoice",      False);
	DefaultDialogOptions.Insert("Preview", False);
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	SavingParameters = FileSystemClient.FileSavingParameters();
	FillPropertyValues(SavingParameters.Dialog, DialogParameters);
	
	FileSystemClient.SaveFile(Undefined, FileToReceive.Location, FileToReceive.Name, SavingParameters);
	
EndProcedure

Procedure OpenDataSynchronizationSettings() Export
	
	OpenForm("CommonForm.DataSyncSettings");
	
EndProcedure

// Opens a file in the operating system's associated application.
//
// Parameters:
//     Object               - Arbitrary - an object from which the name of the file to open is retrieved by property name.
//     PropertyName          - String       - a name of the object property that contains the name of the file to open.
//     StandardProcessing - Boolean       - the flag of standard processing, it is set to False.
//
Procedure FileOrDirectoryOpenHandler(Object, PropertyName, StandardProcessing = False) Export
	StandardProcessing = False;
	
	FullFileName = Object[PropertyName];
	If IsBlankString(FullFileName) Then
		Return;
	EndIf;
	
	FileSystemClient.OpenExplorer(FullFileName);
	
EndProcedure

// Opens a dialog box to select a file directory and prompts to install 1C:Enterprise Extension.
//
// Parameters:
//     Object                - Arbitrary       - an object to set the property being selected in.
//     PropertyName           - String             - a name of the property that contains the name of the file being set in the object. Source of
//                                                  the initial value.
//     StandardProcessing  - Boolean             - the flag of standard processing, it is set to False.
//     DialogParameters      - Structure          - optional additional parameters of the directory selection dialog.
//     CompletionNotification  - CallbackDescription - an optional notification that is called with the following
//                                                  parameters:
//                                 Result               - String - the selected value (array of strings if
//                                                                    multiple selection is used);
//                                 AdditionalParameters - Undefined.
//
Procedure FileDirectoryChoiceHandler(Object, Val PropertyName, StandardProcessing = False, Val DialogParameters = Undefined, CompletionNotification = Undefined) Export
	StandardProcessing = False;
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("Title", NStr("vi = 'Hãy chỉ ra thư mục';
												|ru = 'Укажите каталог';
												|en = 'Select directory'; fa = 'Select directory';
												|it = 'Specificare la directory';
												|pl = 'Podaj katalog';
												|tr = 'Dizini seçin'") );
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",               Object);
	AdditionalParameters.Insert("PropertyName",          PropertyName);
	AdditionalParameters.Insert("DialogParameters",     DialogParameters);
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New CallbackDescription("FileDirectoryChoiceHandlerCompletionAfterChoiceInDialog", ThisObject, AdditionalParameters);
	
	FileSystemClient.SelectDirectory(Notification, DialogParameters.Title);
	
EndProcedure

// Continuation of the procedure (see above).
// 
Procedure FileDirectoryChoiceHandlerCompletionAfterChoiceInDialog(PathToDirectory, AdditionalParameters) Export
	
	If Not ValueIsFilled(PathToDirectory) Then
		Return;
	EndIf;
	
	Object = AdditionalParameters.Object;
	Object[AdditionalParameters.PropertyName] = PathToDirectory;
	
	If AdditionalParameters.CompletionNotification <> Undefined Then
		RunCallback(AdditionalParameters.CompletionNotification, PathToDirectory);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Export utility functions-properties.

// Returns the maximum number of fields
// to be displayed in the infobase object mapping wizard.
//
// Returns:
//     Number - maximum number of fields for mapping.
//
Function MaxObjectsMappingFieldsCount() Export
	
	Return 5;
	
EndFunction

// Returns the structure of data import execution statuses.
// 
// Returns:
//  Structure:
//    * Undefined - String
//    * Error - String
//    * Success - String
//    * Perform - String
//    * Warning_ExchangeMessageAlreadyAccepted - String
//    * CompletedWithWarnings - String
//    * ErrorMessageTransport - String
//
Function DataImportStatusPages() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined", "ImportStatusUndefined");
	Structure.Insert("Error",       "ImportStatusError");
	Structure.Insert("Success",        "ImportStateSuccess");
	Structure.Insert("Perform",   "ImportStatusExecution");
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", "ImportStatusWarning");
	Structure.Insert("CompletedWithWarnings",                     "ImportStatusWarning");
	Structure.Insert("ErrorMessageTransport",                      "ImportStatusError");
	
	Return Structure;
EndFunction

// Returns the structure of data export execution statuses.
// 
// Returns:
//  Structure:
//    * Undefined - String
//    * Error - String
//    * Success - String
//    * Perform - String
//    * Warning_ExchangeMessageAlreadyAccepted - String
//    * CompletedWithWarnings - String
//    * ErrorMessageTransport - String
//
Function DataExportStatusPages() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined", "ExportStatusUndefined");
	Structure.Insert("Error",       "ExportStatusError");
	Structure.Insert("Success",        "ExportStatusSuccess");
	Structure.Insert("Perform",   "ExportStatusExecution");
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", "ExportStatusWarning");
	Structure.Insert("CompletedWithWarnings",                     "ExportStatusWarning");
	Structure.Insert("ErrorMessageTransport",                      "ExportStatusError");
	
	Return Structure;
EndFunction

// Returns a structure with name of data import field hyperlink.
// 
// Returns:
//  Structure:
//   *    Undefined - String
//   *    Error - String
//   *    CompletedWithWarnings - String
//   *    Success - String
//   *    Perform - String
//   *    Warning_ExchangeMessageAlreadyAccepted - String
//   *    ErrorMessageTransport - String
//
Function DataImportHyperlinksHeaders() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined",               NStr("vi = 'Chưa nhận dữ liệu';
													|ru = 'Получение данных не выполнялось';
													|en = 'Data was not received'; fa = 'Data was not received';
													|it = 'La ricezione dei dati non è stata effettuata';
													|pl = 'Pobieranie danych nie było wykonywane';
													|tr = 'Veri alma işlemi gerçekleştirilmedi'"));
	Structure.Insert("Error",                     NStr("vi = 'Không thể nhận dữ liệu';
														|ru = 'Не удалось получить данные';
														|en = 'Could not receive data'; fa = 'Could not receive data';
														|it = 'Non è stato possibile ottenere i dati';
														|pl = 'Nie udało się otrzymać dane';
														|tr = 'Veri alınamıyor'"));
	Structure.Insert("CompletedWithWarnings", NStr("vi = 'Đã nhận dữ liệu có cảnh báo';
													|ru = 'Данные получены с предупреждениями';
													|en = 'Data was received with warnings'; fa = 'Data was received with warnings';
													|it = 'Dati ottenuti con dei warning';
													|pl = 'Dane są otrzymane z ostrzeżeniami';
													|tr = 'Veriler uyarılarla alındı'"));
	Structure.Insert("Success",                      NStr("vi = 'Đã nhận dữ liệu thành công';
															|ru = 'Данные успешно получены';
															|en = 'Data was received'; fa = 'Data was received';
															|it = 'Dati ottenuti correttamente';
															|pl = 'Dane są pomyślnie otrzymane';
															|tr = 'Veri başarıyla alındı'"));
	Structure.Insert("Perform",                 NStr("vi = 'Đang nhận dữ liệu...';
													|ru = 'Выполняется получение данных...';
													|en = 'Receiving data…'; fa = 'Receiving data…';
													|it = 'Ottenimento dei dati in corso...';
													|pl = 'Trwa pobieranie danych...';
													|tr = 'Veri alınıyor ...'"));
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", NStr("vi = 'Không có dữ liệu để nhận';
																	|ru = 'Нет новых данных для получения';
																	|en = 'No new data to receive'; fa = 'No new data to receive';
																	|it = 'Non ci sono nuovi dati da ottenere';
																	|pl = 'Brak nowych danych do pobierania';
																	|tr = 'Alınacak yeni veri yok'"));
	Structure.Insert("ErrorMessageTransport",                      NStr("vi = 'Không thể nhận dữ liệu';
																		|ru = 'Не удалось получить данные';
																		|en = 'Could not receive data'; fa = 'Could not receive data';
																		|it = 'Non è stato possibile ottenere i dati';
																		|pl = 'Nie udało się otrzymać dane';
																		|tr = 'Veri alınamıyor'"));
	
	Return Structure;
EndFunction

// Returns a structure with name of data export field hyperlink.
// 
// Returns:
//  Structure:
//   *    Undefined - String
//   *    Error - String
//   *    CompletedWithWarnings - String
//   *    Success - String
//   *    Perform - String
//   *    Warning_ExchangeMessageAlreadyAccepted - String
//   *    ErrorMessageTransport - String
//
Function DataExportHyperlinksHeaders() Export
	
	Structure = New Structure;
	Structure.Insert("Undefined", NStr("vi = 'Chưa gửi dữ liệu';
										|ru = 'Отправка данных не выполнялась';
										|en = 'Data was not sent'; fa = 'Data was not sent';
										|it = 'L''invio dei dati non è stato effettuato';
										|pl = 'Wysłanie danych nie było wykonywane';
										|tr = 'Veri gönderilmedi'"));
	Structure.Insert("Error",       NStr("vi = 'Không thể gửi dữ liệu';
										|ru = 'Не удалось отправить данные';
										|en = 'Could not send data'; fa = 'Could not send data';
										|it = 'Non è stato possibile inviare i dati';
										|pl = 'Nie udało się wysłać dane';
										|tr = 'Veri gönderilemiyor.'"));
	Structure.Insert("Success",        NStr("vi = 'Đã gửi thành công dữ liệu';
											|ru = 'Данные успешно отправлены';
											|en = 'Data was sent'; fa = 'Data was sent';
											|it = 'Dati inviati correttamente';
											|pl = 'Dane są wysłane pomyślnie';
											|tr = 'Veri başarıyla gönderildi'"));
	Structure.Insert("Perform",   NStr("vi = 'Đang gửi dữ liệu...';
										|ru = 'Выполняется отправка данных...';
										|en = 'Sending data…'; fa = 'Sending data…';
										|it = 'Invio dei dati in corso...';
										|pl = 'Jest wykonywane wysłanie danych...';
										|tr = 'Veri gönderiliyor...'"));
	
	Structure.Insert("Warning_ExchangeMessageAlreadyAccepted", NStr("vi = 'Đã gửi dữ liệu có cảnh báo';
																	|ru = 'Данные отправлены с предупреждениями';
																	|en = 'Data was sent with warnings'; fa = 'Data was sent with warnings';
																	|it = 'Dati inviati con dei warning';
																	|pl = 'Dane są wysłane z ostrzeżeniem';
																	|tr = 'Veriler uyarılarla gönderildi'"));
	Structure.Insert("CompletedWithWarnings",                     NStr("vi = 'Đã gửi dữ liệu có cảnh báo';
																		|ru = 'Данные отправлены с предупреждениями';
																		|en = 'Data was sent with warnings'; fa = 'Data was sent with warnings';
																		|it = 'Dati inviati con dei warning';
																		|pl = 'Dane są wysłane z ostrzeżeniem';
																		|tr = 'Veriler uyarılarla gönderildi'"));
	Structure.Insert("ErrorMessageTransport",                      NStr("vi = 'Không thể gửi dữ liệu';
																		|ru = 'Не удалось отправить данные';
																		|en = 'Could not send data'; fa = 'Could not send data';
																		|it = 'Non è stato possibile inviare i dati';
																		|pl = 'Nie udało się wysłać dane';
																		|tr = 'Veri gönderilemiyor.'"));
	
	Return Structure;
EndFunction

// Opens a form or hyperlink with a detailed description of data synchronization.
//
Procedure OpenSynchronizationDetails(RefToDetails) Export
	
	If Upper(Left(RefToDetails, 4)) = "HTTP" Then
		
		FileSystemClient.OpenURL(RefToDetails);
		
	Else
		
		OpenForm(RefToDetails);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Export service procedures and functions.

// For internal use only.
//
Procedure RetryDataExchangeMessageImportBeforeStartInteractiveHandler(Parameters, Context) Export
	
	Form = OpenForm(
		"DataProcessor.DataExchangeCreationWizard.Form.DataReSyncBeforeStart", , , , , , 
		New CallbackDescription(
			"AfterCloseFormDataResynchronizationBeforeStart", ThisObject, Parameters));
	
	If Form = Undefined Then
		AfterCloseFormDataResynchronizationBeforeStart("Continue", Parameters);
	EndIf;
	
EndProcedure

// For internal use only. Continuation of the procedure.
// InteractiveHandlerRetryDataExchangeMessageImportBeforeStart.
//
Procedure AfterCloseFormDataResynchronizationBeforeStart(Result, Parameters) Export
	
	If Result <> "Continue" Then
		Parameters.Cancel = True;
	Else
		Parameters.RetrievedClientParameters.Insert(
			"RetryDataExchangeMessageImportBeforeStart");
	EndIf;
	
	RunCallback(Parameters.ContinuationHandler);
	
EndProcedure

// For internal use only. Continuation of the procedure.
// SetupFormBeforeClose.
//
Procedure SetupFormBeforeCloseCompletion(Response, Form) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Form.Modified = False;
	Form.Close();
	
	// Clearing cached values to reset COM connections.
	RefreshReusableValues();
EndProcedure

// Opens a file selection dialog box and prompts to install 1C:Enterprise Extension.
//
// Parameters:
//     Object                - Arbitrary       - an object to set the property being selected in.
//     PropertyName           - String             - a name of the property that contains the name of the file being set in the object. Source of
//                                                  the initial value.
//     StandardProcessing  - Boolean             - the flag of standard processing, it is set to False.
//     DialogParameters      - Structure          - optional additional parameters of the file selection dialog.
//     CompletionNotification  - CallbackDescription - an optional notification that is called with the following
//                                                  parameters:
//                                 Result               - String
//                                                         - Undefined - the selected value (array of strings
//                                                                          if multiple selection is used), or
//                                                                          Undefined if nothing was selected;
//                                 AdditionalParameters - Undefined.
//
//
Procedure FileSelectionHandler(Object, Val PropertyName, StandardProcessing = False, Val DialogParameters = Undefined, CompletionNotification = Undefined) Export
	
	StandardProcessing = False;
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("Mode",                       FileDialogMode.Open);
	DefaultDialogOptions.Insert("CheckFileExist", True);
	DefaultDialogOptions.Insert("Title",                   NStr("vi = 'Hãy chọn tệp';
																|ru = 'Выберите файл';
																|en = 'Select file'; fa = 'انتخاب فایل';
																|it = 'Selezionare un file';
																|pl = 'Wybierz plik';
																|tr = 'Dosya seç'"));
	DefaultDialogOptions.Insert("MultipleChoice",          False);
	DefaultDialogOptions.Insert("Preview",     False);
	DefaultDialogOptions.Insert("FullFileName",              Object[PropertyName]);
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	Dialog = New FileDialog(DialogParameters.Mode);
	FillPropertyValues(Dialog, DialogParameters);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object",               Object);
	AdditionalParameters.Insert("PropertyName",          PropertyName);
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New CallbackDescription("FileSelectionHandlerCompletion", ThisObject, AdditionalParameters);
	
	FileSystemClient.ShowSelectionDialog(Notification, Dialog);
	
EndProcedure

// Handler of asynchronous file selection dialog (completion).
//
Procedure FileSelectionHandlerCompletion(SelectedFiles, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedFiles) Then
		Return;
	EndIf;
	
	Object      = AdditionalParameters.Object;
	PropertyName = AdditionalParameters.PropertyName;
	
	Result = Undefined;
	
	If SelectedFiles.Count() > 1 Then
		Result = SelectedFiles;
	Else
		Result = SelectedFiles[0];
		
		Object[PropertyName] = Result;
	EndIf;
	
	If Not AdditionalParameters.CompletionNotification = Undefined Then
		RunCallback(AdditionalParameters.CompletionNotification, Result);
	EndIf;
	
EndProcedure

// Sends a file to the server interactively without using 1C:Enterprise Extension.
//
// Parameters:
//     CompletionNotification - CallbackDescription - an export procedure that is called with the following
//                                                 parameters:
//                                Result               - Structure - with the following fields: Name, Storage, and ErrorDetails.
//                                AdditionalParameters - Undefined.
//
//     DialogParameters     - Structure                       - optional additional parameters of file selection
//                                                              dialog.
//     FormIdentifier   - String
//                          - UUID - a parameter for the storage.
//
Procedure SelectAndSendFileToServer(CompletionNotification, Val DialogParameters = Undefined, Val FormIdentifier = Undefined) Export
	
	DefaultDialogOptions = New Structure;
	DefaultDialogOptions.Insert("CheckFileExist", True);
	DefaultDialogOptions.Insert("Title",                   NStr("vi = 'Hãy chọn tệp';
																|ru = 'Выберите файл';
																|en = 'Select file'; fa = 'انتخاب فایل';
																|it = 'Selezionare un file';
																|pl = 'Wybierz plik';
																|tr = 'Dosya seç'"));
	DefaultDialogOptions.Insert("MultipleChoice",          False);
	DefaultDialogOptions.Insert("Preview",     False);
	
	SetDefaultStructureValues(DialogParameters, DefaultDialogOptions);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CompletionNotification", CompletionNotification);
	
	Notification = New CallbackDescription("SelectAndSendFileToServerAfterChoiceInDialogCompletion", ThisObject, AdditionalParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = FormIdentifier;
	FillPropertyValues(ImportParameters.Dialog, DialogParameters);
	
	FileSystemClient.ImportFile_(Notification, ImportParameters);

EndProcedure

// Handler of completing non-modal choice and transferring files to the server.
//
Procedure SelectAndSendFileToServerAfterChoiceInDialogCompletion(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Result  = New Structure("Name, Location, ErrorDescription");
	Result.Name      = FileThatWasPut.Name;
	Result.Location = FileThatWasPut.Location;
	
	// Notify the caller.
	RunCallback(AdditionalParameters.CompletionNotification, Result);
	
EndProcedure

// Adds fields to the target structure if they are not there.
//
// Parameters:
//     Result           - Structure - a target structure.
//     DefaultValues - Structure
//
Procedure SetDefaultStructureValues(Result, Val DefaultValues)
	
	If Result = Undefined Then
		Result = New Structure;
	EndIf;
	
	For Each KeyValue In DefaultValues Do
		PropertyName = KeyValue.Key;
		If Not Result.Property(PropertyName) Then
			Result.Insert(PropertyName, KeyValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

// Opens the form for importing conversion and registration rules as a single file.
//
Procedure ImportDataSyncRules(Val ExchangePlanName) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ExchangePlanName", ExchangePlanName);
	
	OpenForm("InformationRegister.DataExchangeRules.Form.ImportDataSyncRules", FormParameters,, ExchangePlanName);
	
EndProcedure

// Opens the event log filtered by export or import events for the specified exchange plan node.
// 
Procedure GoToDataEventLog(InfobaseNode, CommandExecuteParameters, ActionOnStringExchange) Export
	
	EventLogEvent = DataExchangeServerCall.EventLogMessageKeyByActionString(InfobaseNode, ActionOnStringExchange);
	
	FormParameters = New Structure;
	FormParameters.Insert("EventLogEvent", EventLogEvent);
	
	OpenForm("DataProcessor.EventLog.Form", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

Function DataExchangeEventLogEvent() Export
	
	Return NStr("vi = 'Trao đổi dữ liệu';
				|ru = 'Обмен данными';
				|en = 'Data exchange'; fa = 'تبادل داده';
				|it = 'Scambio di dati';
				|pl = 'Wymiana danych';
				|tr = 'Veri değişimi'", CommonClient.DefaultLanguageCode());
	
EndFunction

// Opens the form of interactive data exchange execution for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode  - ExchangePlanRef - an exchange plan node for which the form is to open;
//  Owner                - Form-an owner of the form being opened;
//  AdditionalParameters - Structure - a structure of additional opening parameters of the wizard:
//    * WizardParameters  - Structure - an arbitrary structure to be passed to the wizard form that is being opened;
//    * ClosingNotification1 - CallbackDescription - description of a notification to be called upon closing the wizard form.
//
Procedure OpenObjectsMappingWizardCommandProcessing(InfobaseNode,
		Owner, AdditionalParameters = Undefined) Export
	
	// Open the object mapping form and pass the node as the form parameter.
	// 
	FormParameters = New Structure("InfobaseNode", InfobaseNode);
	FormParameters.Insert("AdvancedExportAdditionMode", True);
	
	ClosingNotification1 = Undefined;
	
	If Not AdditionalParameters = Undefined Then
		
		If AdditionalParameters.Property("WizardParameters") Then
			For Each CurrentParameter In AdditionalParameters.WizardParameters Do
				FormParameters.Insert(CurrentParameter.Key, CurrentParameter.Value);
			EndDo;
		EndIf;
		
		AdditionalParameters.Property("ClosingNotification1", ClosingNotification1);
		
	EndIf;
	
	OpenForm("DataProcessor.InteractiveDataExchangeWizard.Form",
		FormParameters, Owner, InfobaseNode.UUID(), , , ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens a form for setting a new data synchronization.
//
Procedure OpenNewDataSynchronizationSettingForm(NewDataSynchronizationForm = "", AdditionalParameters = Undefined) Export
	
	If IsBlankString(NewDataSynchronizationForm) Then
		NewDataSynchronizationForm = "DataProcessor.DataExchangeCreationWizard.Form.NewDataSynchronization";
	EndIf;
	
	OpenForm(NewDataSynchronizationForm, AdditionalParameters);
	
EndProcedure

// Opens the form of data exchange execution scenarios for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node for which the form is to open;
//  Owner               - Form-an owner of the form being opened;
//
Procedure SetExchangeExecutionScheduleCommandProcessing(InfobaseNode, Owner) Export
	
	FormParameters = New Structure("InfobaseNode", InfobaseNode);
	
	OpenForm("Catalog.DataExchangeScenarios.Form.DataExchangesScheduleSetup", FormParameters, Owner);
	
EndProcedure

// Notifies all opened dynamic lists that data that is being displayed must be refreshed.
//
Procedure RefreshAllOpenDynamicLists() Export
	
	Types = DataExchangeServerCall.AllConfigurationReferenceTypes();
	
	For Each Type In Types Do
		
		NotifyChanged(Type);
		
	EndDo;
	
EndProcedure

// Registers a handler for opening a new form right after closing the current one.
// 
Procedure OpenFormAfterCloseCurrentOne(CurrentForm, Val FormName, Val Parameters = Undefined, Val OpeningParameters = Undefined) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormName",          FormName);
	AdditionalParameters.Insert("Parameters",         Parameters);
	AdditionalParameters.Insert("OpeningParameters", OpeningParameters);
	
	AdditionalParameters.Insert("PreviousClosingNotification",  CurrentForm.OnCloseNotifyDescription);
	
	CurrentForm.OnCloseNotifyDescription = New CallbackDescription("FormOpeningHandlerAfterCloseCurrentOne", ThisObject, AdditionalParameters);
EndProcedure

// Deferred opening
Procedure FormOpeningHandlerAfterCloseCurrentOne(Val ClosingResult, Val AdditionalParameters) Export
	
	OpeningParameters = New Structure("Owner, Uniqueness, Window, URL, OnCloseNotifyDescription, WindowOpeningMode");
	FillPropertyValues(OpeningParameters, AdditionalParameters.OpeningParameters);
	OpenForm(AdditionalParameters.FormName, AdditionalParameters.Parameters,
		OpeningParameters.Owner, OpeningParameters.Uniqueness, OpeningParameters.Window, 
		OpeningParameters.URL, OpeningParameters.OnCloseNotifyDescription, OpeningParameters.WindowOpeningMode);
	
	If AdditionalParameters.PreviousClosingNotification <> Undefined Then
		RunCallback(AdditionalParameters.PreviousClosingNotification, ClosingResult);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Local service procedures and functions.

Procedure OnCloseExchangePlanNodeSettingsForm(Form, FormAttributeName)
	
	If Not Form.CheckFilling() Then
		Return;
	EndIf;
	
	For Each FilterSettings In Form[FormAttributeName] Do
		
		If TypeOf(Form[FilterSettings.Key]) = Type("FormDataCollection") Then
			
			TabularSectionStructure = Form[FormAttributeName][FilterSettings.Key];
			
			For Each Item In TabularSectionStructure Do
				
				TabularSectionStructure[Item.Key].Clear();
				
				For Each CollectionRow In Form[FilterSettings.Key] Do
					
					TabularSectionStructure[Item.Key].Add(CollectionRow[Item.Key]);
					
				EndDo;
				
			EndDo;
			
		Else
			
			Form[FormAttributeName][FilterSettings.Key] = Form[FilterSettings.Key];
			
		EndIf;
		
	EndDo;
	
	Form.Modified = False;
	Form.Close(Form[FormAttributeName]);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
// SERVICE PROGRAM INTERFACE FOR INTERACTIVE UPLOAD ADD-ON
//

// Processing interactive addition dialog boxes.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - export settings.
//     Owner, Uniqueness, Window - parameters for opening the form window.
//
// Returns:
//     ClientApplicationForm - The opened form with the passed parameters
//
Function OpenExportAdditionFormNodeScenario(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	
	FormParameters = New Structure("ChoiceMode, CloseOnChoice", True, True);
	FormParameters.Insert("InfobaseNode", ExportAddition.InfobaseNode);
	FormParameters.Insert("FilterPeriod1",           ExportAddition.NodeScenarioFilterPeriod);
	FormParameters.Insert("Filter",                  ExportAddition.AdditionalNodeScenarioRegistration);

	Return OpenForm(ExportAddition.AdditionScenarioParameters.AdditionalOption.FilterFormName,
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive addition dialog boxes.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - export settings.
//     Owner, Uniqueness, Window - parameters for opening the form window.
//
// Returns:
//     ClientApplicationForm - The opened form with the passed parameters
//
Function OpenExportAdditionFormAllDocuments(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure;
	
	FormParameters.Insert("Title", NStr("vi = 'Thêm chứng từ để gửi';
										|ru = 'Добавление документов для отправки';
										|en = 'Add documents to send'; fa = 'Add documents to send';
										|it = 'Aggiunta di documenti per l''invio';
										|pl = 'Dodanie dokumentów do wysyłki';
										|tr = 'Gönderilecek belgeleri ekle'") );
	FormParameters.Insert("ChoiceAction", 1);
	
	FormParameters.Insert("PeriodSelection", True);
	FormParameters.Insert("DataPeriod", ExportAddition.AllDocumentsFilterPeriod);
	
	FormParameters.Insert("SettingsComposerAddress", ExportAddition.AllDocumentsComposerAddress);
	
	FormParameters.Insert("FormStorageAddress", ExportAddition.FormStorageAddress);
	
	Return OpenForm("DataProcessor.InteractiveExportChange.Form.PeriodAndFilterEdit", 
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive addition dialog boxes.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - export settings.
//     Owner, Uniqueness, Window - parameters for opening the form window.
//
// Returns:
//     ClientApplicationForm - The opened data processor "InteractiveExportChange" form with the passed parameters
//
Function OpenExportAdditionFormDetailedFilter(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure;
	
	FormParameters.Insert("ChoiceAction", 2);
	FormParameters.Insert("ObjectSettings", ExportAddition);
	
	FormParameters.Insert("OpenByScenario", True);
	Return OpenForm("DataProcessor.InteractiveExportChange.Form", 
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive addition dialog boxes.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - export settings.
//     Owner, Uniqueness, Window - parameters for opening the form window.
//
// Returns:
//     ClientApplicationForm - The opened data processor "InteractiveExportChange" form with the passed parameters
//
Function OpenExportAdditionFormDataComposition(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure;
	
	FormParameters.Insert("ObjectSettings", ExportAddition);
	If ExportAddition.ExportOption=3 Then
		FormParameters.Insert("SimplifiedMode", True);
	EndIf;
	
	Return OpenForm("DataProcessor.InteractiveExportChange.Form.ExportComposition",
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Processing interactive addition dialog boxes.
//
// Parameters:
//     ExportAddition           - Structure
//                                  - FormDataStructure - export settings.
//     Owner, Uniqueness, Window - parameters for opening the form window.
//
// Returns:
//     ClientApplicationForm - The opened data processor "InteractiveExportChange" form with the passed parameters
//
Function OpenExportAdditionFormSaveSettings(Val ExportAddition, Val Owner=Undefined, Val Uniqueness=Undefined, Val Window=Undefined) Export
	FormParameters = New Structure("CloseOnChoice, ChoiceAction", True, 3);
	
	// Composer is not passed to the form being opened.
	ExportAddition.AllDocumentsFilterComposer = Undefined;
	
	FormParameters.Insert("CurrentSettingsItemPresentation", ExportAddition.CurrentSettingsItemPresentation);
	FormParameters.Insert("Object", ExportAddition);
	
	Return OpenForm("DataProcessor.InteractiveExportChange.Form.SettingsCompositionEdit",
		FormParameters, Owner, Uniqueness, Window);
EndFunction

// Selection handler for the export addition wizard form.
// The function determines whether the source is called from the export addition and operates with the ExportAddition data.
//
// Parameters:
//     ValueSelected  - Arbitrary                    - selection result.
//     ChoiceSource     - ClientApplicationForm                - a form that made the selection.
//     ExportAddition - Structure
//                        - FormDataCollection - selection addition settings that are being changed.
//
// Returns:
//     Boolean - True if the selection is called from one of the export addition forms, otherwise it is False.
//
Function ExportAdditionChoiceProcessing(Val ValueSelected, Val ChoiceSource, ExportAddition) Export
	
	If ChoiceSource.FormName="DataProcessor.InteractiveExportChange.Form.PeriodAndFilterEdit" Then
		// Changing the "All documents" predefined filter. The action is determined by SelectedValue.
		Return ExportAdditionStandardOptionChoiceProcessing(ValueSelected, ExportAddition);
		
	ElsIf ChoiceSource.FormName="DataProcessor.InteractiveExportChange.Form.Form" Then
		// Changing the "In detail" predefined filter. The effect is determined by SelectedValue.
		Return ExportAdditionStandardOptionChoiceProcessing(ValueSelected, ExportAddition);
		
	ElsIf ChoiceSource.FormName="DataProcessor.InteractiveExportChange.Form.SettingsCompositionEdit" Then
		// Settings whose effect is determined by SelectedValue.
		Return ExportAdditionStandardOptionChoiceProcessing(ValueSelected, ExportAddition);
		
	ElsIf ChoiceSource.FormName=ExportAddition.AdditionScenarioParameters.AdditionalOption.FilterFormName Then
		// Changing settings according to the node scenario.
		Return ExportAdditionNodeScenarioChoiceProcessing(ValueSelected, ExportAddition);
		
	EndIf;
	
	Return False;
EndFunction

Procedure FillStructureData(Form)
	
	// Saving the values entered in this application.
	SettingsStructure = Form.Context.NodeFiltersSetting;
	MatchingAttributes = Form.AttributesNames;
	
	For Each SettingItem In SettingsStructure Do
		
		If MatchingAttributes.Property(SettingItem.Key) Then
			
			AttributeName = MatchingAttributes[SettingItem.Key];
			
		Else
			
			AttributeName = SettingItem.Key;
			
		EndIf;
		
		FormAttribute = Form[AttributeName];
		
		If TypeOf(FormAttribute) = Type("FormDataCollection") Then
			
			TableName = SettingItem.Key;
			
			Table = New Array;
			
			For Each Item In Form[AttributeName] Do
				
				TableRow = New Structure("Use, Presentation, RefUUID");
				
				FillPropertyValues(TableRow, Item);
				
				Table.Add(TableRow);
				
			EndDo;
			
			SettingsStructure.Insert(TableName, Table);
			
		Else
			
			SettingsStructure.Insert(SettingItem.Key, Form[AttributeName]);
			
		EndIf;
		
	EndDo;
	
	Form.Context.NodeFiltersSetting = SettingsStructure;
	
	// Saving values entered in another application.
	SettingsStructure = Form.Context.CorrespondentInfobaseNodeFilterSetup;
	MatchingAttributes = Form.AttributesNamesOfCorrespondentDatabase;
	
	For Each SettingItem In SettingsStructure Do
		
		If MatchingAttributes.Property(SettingItem.Key) Then
			
			AttributeName = MatchingAttributes[SettingItem.Key];
			
		Else
			
			AttributeName = SettingItem.Key;
			
		EndIf;
		
		FormAttribute = Form[AttributeName];
		
		If TypeOf(FormAttribute) = Type("FormDataCollection") Then
			
			TableName = SettingItem.Key;
			
			Table = New Array;
			
			For Each Item In Form[AttributeName] Do
				
				TableRow = New Structure("Use, Presentation, RefUUID");
				
				FillPropertyValues(TableRow, Item);
				
				Table.Add(TableRow);
				
			EndDo;
			
			SettingsStructure.Insert(TableName, Table);
			
		Else
			
			SettingsStructure.Insert(SettingItem.Key, Form[AttributeName]);
			
		EndIf;
		
	EndDo;
	
	Form.Context.CorrespondentInfobaseNodeFilterSetup = SettingsStructure;
	
	Form.Context.Insert("ContextDetails", Form.ContextDetails);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
// SERVICE PROCEDURES AND FUNCTIONS OF THE INTERACTIVE UPLOAD ADD-ON
//

Function ExportAdditionStandardOptionChoiceProcessing(Val ValueSelected, ExportAddition)
	
	Result = False;
	If TypeOf(ValueSelected)=Type("Structure") Then 
		
		If ValueSelected.ChoiceAction=1 Then
			// FIlter and period for all documents.
			ExportAddition.AllDocumentsFilterComposer = Undefined;
			ExportAddition.AllDocumentsComposerAddress = ValueSelected.SettingsComposerAddress;
			ExportAddition.AllDocumentsFilterPeriod      = ValueSelected.DataPeriod;
			Result = True;
			
		ElsIf ValueSelected.ChoiceAction=2 Then
			// Detailed setting.
			SelectionObject = GetFromTempStorage(ValueSelected.ObjectAddress);
			FillPropertyValues(ExportAddition, SelectionObject, , "AdditionalRegistration");
			ExportAddition.AdditionalRegistration.Clear();
			For Each String In SelectionObject.AdditionalRegistration Do
				FillPropertyValues(ExportAddition.AdditionalRegistration.Add(), String);
			EndDo;
			Result = True;
			
		ElsIf ValueSelected.ChoiceAction=3 Then
			// Settings are saved, saving the current name.
			ExportAddition.CurrentSettingsItemPresentation = ValueSelected.SettingPresentation;
			Result = True;
			
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

Function ExportAdditionNodeScenarioChoiceProcessing(Val ValueSelected, ExportAddition)
	If TypeOf(ValueSelected)<>Type("Structure") Then 
		Return False;
	EndIf;
	
	ExportAddition.NodeScenarioFilterPeriod        = ValueSelected.FilterPeriod1;
	ExportAddition.NodeScenarioFilterPresentation = ValueSelected.FilterPresentation;
	
	ExportAddition.AdditionalNodeScenarioRegistration.Clear();
	For Each RegistrationLine In ValueSelected.Filter Do
		FillPropertyValues(ExportAddition.AdditionalNodeScenarioRegistration.Add(), RegistrationLine);
	EndDo;
	
	Return True;
EndFunction

#EndRegion
