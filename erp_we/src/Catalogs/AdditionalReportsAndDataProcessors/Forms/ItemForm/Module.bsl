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
Var ClientCache;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	If ValueIsFilled(Parameters.CopyingValue) Then
		Raise NStr("vi = 'Cấm tạo mới phần tử bằng cách sao chép.';
					|ru = 'Создание нового элемента копированием запрещено.';
					|en = 'Create by copying is prohibited.'; fa = 'Create by copying is prohibited.';
					|it = 'È vietato creare un nuovo elemento copiando.';
					|pl = 'Tworzenie nowego przedmiotu przez kopiowanie jest zabronione.';
					|tr = 'Kopyalayarak yeni bir öğe oluşturmak yasaktır.'");
	EndIf;
	
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		And Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Cancel = True;
		Common.MessageToUser(NStr("vi = 'Không hỗ trợ làm việc với mẫu in.';
									|ru = 'Работа с печатными формами не поддерживается.';
									|en = 'Print forms are not supported.'; fa = 'Print forms are not supported.';
									|it = 'Il lavoro con i modelli di stampa non è supportato.';
									|pl = 'Praca z formularzami wydruku nie jest obsługiwana.';
									|tr = 'Yazdırma formları desteklenmiyor.'"));
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ItemForPlacementName", "AdditionalAttributesPage");
		AdditionalParameters.Insert("DeferredInitialization", True);
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	EndIf;
	
	// Checking if new data processors can be imported into the infobase.
	IsNew = Object.Ref.IsEmpty();
	InsertRight1 = AdditionalReportsAndDataProcessors.InsertRight1();
	If Not InsertRight1 Then
		If IsNew Then
			Raise(NStr("vi = 'Không đủ quyền truy cập để thêm báo cáo hoặc bộ xử lý bổ sung.';
						|ru = 'Недостаточно прав доступа для добавления дополнительных отчетов или обработок.';
						|en = 'Insufficient rights to add additional reports and data processors.'; fa = 'Insufficient rights to add additional reports and data processors.';
						|it = 'Permessi d''accesso insufficienti per l''aggiunta di report o elaborazioni aggiuntive.';
						|pl = 'Niewystarczające prawa dostępu do dodawania raportów dodatkowych lub przetwarzania.';
						|tr = 'Ek raporlar veya veri işlemcileri eklemek için yetersiz erişim hakları.'"),
				ErrorCategory.AccessViolation);
		EndIf;
		Items.LoadFromFile.Visible = False;
		Items.ExportToFile.Visible = False;
	EndIf;
	
	// Restrict available publication options as specified in the infobase settings.
	Items.Publication.ChoiceList.Clear();
	AvaliablePublicationKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	For Each PublicationKind In AvaliablePublicationKinds Do
		Items.Publication.ChoiceList.Add(PublicationKind);
	EndDo;
	
	// Restricting detailed information display.
	ExtendedInformationDisplay = AdditionalReportsAndDataProcessors.DisplayExtendedInformation(Object.Ref);
	Items.AdditionalInfoPage.Visible = ExtendedInformationDisplay;
	
	// Restricting data processor import from/export to a file.
	If Not AdditionalReportsAndDataProcessors.CanImportDataProcessorFromFile(Object.Ref) Then
		Items.LoadFromFile.Visible = False;
	EndIf;
	If Not AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Object.Ref) Then
		Items.ExportToFile.Visible = False;
	EndIf;
	
	KindAdditionalDataProcessor = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor;
	KindAdditionalReport     = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport;
	KindOfReport                   = Enums.AdditionalReportsAndDataProcessorsKinds.Report;
	
	ShowImportFromFileDialogOnOpen = Parameters.ShowImportFromFileDialogOnOpen;
	
	If IsNew Then
		Object.UseForObjectForm = True;
		Object.UseForListForm  = True;
		ShowImportFromFileDialogOnOpen = True;
	EndIf;
	
	If ShowImportFromFileDialogOnOpen And Not Items.LoadFromFile.Visible Then
		Raise(NStr("vi = 'Không đủ quyền để kết nhập báo cáo và bộ xử lý bổ sung.';
					|ru = 'Недостаточно прав для загрузки дополнительных отчетов и обработок.';
					|en = 'Insufficient rights to import additional reports and data processors.'; fa = 'Insufficient rights to import additional reports and data processors.';
					|it = 'Недостаточно прав для загрузки дополнительных отчетов и обработок.';
					|pl = 'Insufficient rights to import additional reports and data processors.';
					|tr = 'Ek raporları indirmek ve işlemek için yetersiz yetki.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	FillInCommands();
	
	PermissionsAddress = PutToTempStorage(
		FormAttributeToValue("Object").Permissions.Unload(),
		UUID);
	
	SetVisibilityAvailability();
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	ClientCache = New Structure;
	
	If ShowImportFromFileDialogOnOpen Then
		AttachIdleHandler("UpdateFromFile", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.AdditionalReportsAndDataProcessors.Form.PlacementInSections") Then
		
		If TypeOf(ValueSelected) <> Type("ValueList") Then
			Return;
		EndIf;
		
		Object.Sections.Clear();
		For Each ListItem In ValueSelected Do
			NewRow = Object.Sections.Add();
			NewRow.Section = ListItem.Value;
		EndDo;
		
		Modified = True;
		SetVisibilityAvailability();
		
	ElsIf Upper(ChoiceSource.FormName) = Upper("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors") Then
		
		If TypeOf(ValueSelected) <> Type("ValueList") Then
			Return;
		EndIf;
		
		ItemCommand = Object.Commands.FindByID(ClientCache.CommandRowID);
		If ItemCommand = Undefined Then
			Return;
		EndIf;
		
		FoundItems = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.Id));
		For Each TableRow In FoundItems Do
			QuickAccess.Delete(TableRow);
		EndDo;
		
		For Each ListItem In ValueSelected Do
			TableRow = QuickAccess.Add();
			TableRow.CommandID = ItemCommand.Id;
			TableRow.User = ListItem.Value;
		EndDo;
		
		ItemCommand.QuickAccessPresentation = UsersQuickAccessPresentation(ValueSelected.Count());
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectMetadataObjects" Then
		
		ImportSelectedMetadataObjects(Parameter);
		
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	EndIf
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	
	If AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Object.Ref) Then
		
		DataProcessorDataAddress = PutToTempStorage(
			CurrentObject.DataProcessorStorage.Get(),
			UUID);
		
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", CurrentObject.Ref);
	Query.Text =
	"SELECT ALLOWED
	|	RegisterData.CommandID,
	|	RegisterData.User
	|FROM
	|	InformationRegister.DataProcessorAccessUserSettings AS RegisterData
	|WHERE
	|	RegisterData.AdditionalReportOrDataProcessor = &Ref
	|	AND RegisterData.Available = TRUE
	|	AND NOT RegisterData.User.DeletionMark
	|	AND NOT RegisterData.User.Invalid";
	QuickAccess.Load(Query.Execute().Unload());
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If DataProcessorRegistration And AdditionalReportsAndDataProcessors.CanImportDataProcessorFromFile(Object.Ref) Then
		DataProcessorBinaryData = GetFromTempStorage(DataProcessorDataAddress);
		CurrentObject.DataProcessorStorage = New ValueStorage(DataProcessorBinaryData, New Deflation(9));
	EndIf;
	
	If Object.Kind = KindAdditionalDataProcessor Or Object.Kind = KindAdditionalReport Then
		CurrentObject.AdditionalProperties.Insert("RelevantCommands", Object.Commands.Unload());
	Else
		QuickAccess.Clear();
	EndIf;
	
	CurrentObject.AdditionalProperties.Insert("QuickAccess", QuickAccess.Unload());
	CurrentObject.AdditionalProperties.Insert("ReportOptionAssignment", ReportOptionAssignment);
	
	CurrentObject.Permissions.Load(GetFromTempStorage(PermissionsAddress));
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	If CurrentObject.AdditionalProperties.Property("AttachmentError") Then
		MessageText = CurrentObject.AdditionalProperties.AttachmentError;
		Common.MessageToUser(MessageText);
	EndIf;
	IsNew = False;
	If DataProcessorRegistration Then
		RefreshReusableValues();
		DataProcessorRegistration = False;
	EndIf;
	FillInCommands();
	SetVisibilityAvailability();
	
	If Object.Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff
		And Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		And Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ModulePrintManager.DisablePrintCommands(SelectedRelatedObjects().UnloadValues(), CommandsToDisable().UnloadValues());
	EndIf;
	
	StandardSubsystemsServer.NotifyAllSessionsAboutOutdatedCache(True);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AdditionalReportOptionsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeRowChange(Item, Cancel)
	Cancel = True;
	OpenOption();
EndProcedure

&AtClient
Procedure AdditionalReportOptionsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	Variant = Items.AdditionalReportOptions.CurrentData;
	If Variant = Undefined Then
		Return;
	EndIf;
	
	If Not Variant.Custom Then
		ShowMessageBox(, NStr("vi = 'Cấm đặt dấu xóa phương án báo cáo định trước.';
								|ru = 'Пометка на удаление предопределенного варианта отчета запрещена.';
								|en = 'Predefined report option cannot be marked for deletion.'; fa = 'Predefined report option cannot be marked for deletion.';
								|it = 'Contrassegnare una variante predefinita del report per la cancellazione è proibito.';
								|pl = 'Zaznaczenie do usunięcia predefiniowanego wariantu raportu jest zabronione.';
								|tr = 'Öntanımlı rapor seçeneği silinmek üzere işaretlenemez.'"));
		Return;
	EndIf;
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đặt dấu xóa ""%1""?';
																				|ru = 'Пометить ""%1"" на удаление?';
																				|en = 'Do you want to mark %1 for deletion?'; fa = 'Do you want to mark %1 for deletion?';
																				|it = 'Contrassegnare ""%1"" per cancellazione?';
																				|pl = 'Zaznaczyć ""%1"" do usunięcia?';
																				|tr = '""%1"" silinmek üzere işaretlensin mi?'"), Variant.Description);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Variant", Variant);
	Handler = New CallbackDescription("AdditionalReportOptionsBeforeDeleteRowCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
EndProcedure

&AtClient
Procedure UseForListFormOnChange(Item)
	If Not Object.UseForObjectForm And Not Object.UseForListForm Then
		Object.UseForObjectForm = True;
	EndIf;
EndProcedure

&AtClient
Procedure UseForObjectFormOnChange(Item)
	If Not Object.UseForObjectForm And Not Object.UseForListForm Then
		Object.UseForListForm = True;
	EndIf;
EndProcedure

&AtClient
Procedure DecorationEnablingSecurityProfilesLabelURLProcessing(Item, Ref, StandardProcessing)
	
	If Ref = "int://sp-on" Then
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.OpenSecurityProfileSetupDialog();
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CommandsLocationClick(Item, StandardProcessing)
	StandardProcessing = False;
	If Object.Kind = KindAdditionalReport Or Object.Kind = KindAdditionalDataProcessor Then
		// Select sections.
		Sections = New ValueList;
		For Each TableRow In Object.Sections Do
			Sections.Add(TableRow.Section);
		EndDo;
		
		FormParameters = New Structure;
		FormParameters.Insert("Sections",      Sections);
		FormParameters.Insert("DataProcessorKind", Object.Kind);
		
		OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.PlacementInSections", FormParameters, ThisObject);
	Else
		// Select metadata objects
		FormParameters = PrepareMetadataObjectsSelectionFormParameters();
		StandardSubsystemsClient.ChooseMetadataObjects(FormParameters);
	EndIf;
EndProcedure

&AtClient
Procedure OptionsCommandsPermissionsPagesOnCurrentPageChange(Item, CurrentPage)
	If CommonClient.SubsystemExists("StandardSubsystems.Properties")
		And CurrentPage.Name = "AdditionalAttributesPage"
		And Not PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectCommands

&AtClient
Procedure ObjectCommandsQuickAccessPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	ChangeQuickAccess();
EndProcedure

&AtClient
Procedure ObjectCommandsQuickAccessPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobUsageOnChange(Item)
	ChangeScheduledJob(False, True);
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	ChangeScheduledJob(True, False);
EndProcedure

&AtClient
Procedure ObjectCommandsScheduledJobPresentationClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure ObjectCommandsSetQuickAccess(Command)
	ChangeQuickAccess();
EndProcedure

&AtClient
Procedure ObjectCommandsSetSchedule(Command)
	ChangeScheduledJob(True, False);
EndProcedure

&AtClient
Procedure ObjectCommandsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	Cancel = True;
EndProcedure

&AtClient
Procedure ObjectCommandsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandSaveAndClose(Command)
	WriteAtClient(True);
EndProcedure

&AtClient
Procedure CommandWrite(Command)
	WriteAtClient(False);
EndProcedure

&AtClient
Procedure LoadFromFile(Command)
	UpdateFromFile();
EndProcedure

&AtClient
Procedure ExportToFile(Command)
	ExportingParameters = New Structure;
	ExportingParameters.Insert("IsReport", Object.Kind = KindOfReport Or Object.Kind = KindAdditionalReport);
	ExportingParameters.Insert("FileName", Object.FileName);
	ExportingParameters.Insert("DataProcessorDataAddress", DataProcessorDataAddress);
	AdditionalReportsAndDataProcessorsClient.ExportToFile(ExportingParameters);
EndProcedure

&AtClient
Procedure AdditionalReportOptionsOpen(Command)
	Variant = Items.AdditionalReportOptions.CurrentData;
	If Variant = Undefined Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn phương án báo cáo.';
								|ru = 'Выберите вариант отчета.';
								|en = 'Choose a report option.'; fa = 'Choose a report option.';
								|it = 'Selezionate la variante del report.';
								|pl = 'Wybierz wariant raportu.';
								|tr = 'Rapor seçeneğini seçin.'"));
		Return;
	EndIf;
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportOption(Object.Ref, Variant.VariantKey);
EndProcedure

&AtClient
Procedure PlaceInSections(Command)
	OptionsArray = New Array;
	For Each RowID In Items.AdditionalReportOptions.SelectedRows Do
		Variant = AdditionalReportOptions.FindByID(RowID);
		If ValueIsFilled(Variant.Ref) Then
			OptionsArray.Add(Variant.Ref);
		EndIf;
	EndDo;
	
	// Opens a dialog for assigning multiple report options to command interface sections
	If CommonClient.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.OpenOptionArrangeInSectionsDialog(OptionsArray);
	EndIf;
EndProcedure

&AtClient
Procedure SetPrintCommandVisibility(Command)
	If Modified Then
		CallbackDescription = New CallbackDescription("SetPrintCommandVisibilityCompletion", ThisObject);
		QueryText = NStr("vi = 'Để tùy chỉnh tính hiện hình của các lệnh in, hãy ghi lại bộ xử lý. Tiếp tục?';
						|ru = 'Для настройки видимости команд печати запишите обработку. Продолжить?';
						|en = 'To configure the visibility of print commands, save the data processor. Continue?'; fa = 'To configure the visibility of print commands, save the data processor. Continue?';
						|it = 'Per l''impostazione di visibilità dei comandi di stampa, registrare elaborazione. Continuare?';
						|pl = 'W celu ustawienia widoczności poleceń drukowania zapisz przetwarzanie. Kontynuować?';
						|tr = 'Yazdırma komutlarının görünürlüğünü ayarlamak için işlemeyi kaydedin. Devam edilsin mi?'");
		Buttons = New ValueList;
		Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Continue';
									|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	Else
		OpenPrintSubmenuSettingsForm();
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteCommand(Command)
	CommandsTableRow = Items.ObjectCommands.CurrentData;
	If CommandsTableRow = Undefined Then
		Return;
	EndIf;
	If Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm")
		And Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall")
		And Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		And Not CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
		Return;
	EndIf;
	
	Context = New Structure;
	Context.Insert("CommandToExecuteID", CommandsTableRow.Id);
	Handler = New CallbackDescription("ExecuteCommandAfterWriteConfirmed", ThisObject, Context);
	
	If Object.Ref.IsEmpty() Or Modified Then
		QueryText = NStr("vi = 'Để thực hiện lệnh, hãy ghi lại dữ liệu.';
						|ru = 'Для выполнения команды запишите данные.';
						|en = 'Save the data before running the command.'; fa = 'Save the data before running the command.';
						|it = 'Per l''esecuzione dei comandi registrare i dati.';
						|pl = 'Aby wykonać polecenie zapisz dane.';
						|tr = 'Komutu yürütmek için verileri yazın.'");
		Buttons = New ValueList;
		Buttons.Add("WriteAndContinue", NStr("vi = 'Ghi lại và tiếp tục';
											|ru = 'Записать и продолжить';
											|en = 'Save and continue'; fa = 'Save and continue';
											|it = 'Registrare e continuare';
											|pl = 'Zapisz i kontynuuj';
											|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);
		ShowQueryBox(Handler, QueryText, Buttons);
	Else
		RunCallback(Handler, "ContinueWithoutWriting");
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobUsage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Commands.ScheduledJobAllowed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectCommandsScheduledJobPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Commands.ScheduledJobUsage");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

#Region Client

&AtClient
Procedure WriteAtClient(CloseAfterWrite)
	
	Handler = New CallbackDescription("ContinueWriteAtClient", ThisObject, CloseAfterWrite);
	RunCallback(Handler, DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure ContinueWriteAtClient(Result, CloseAfterWrite)  Export
	
	WriteParameters = New Structure;
	WriteParameters.Insert("DataProcessorRegistration", DataProcessorRegistration);
	WriteParameters.Insert("CloseAfterWrite", CloseAfterWrite);
	
	Success = Write(WriteParameters);
	If Not Success Then
		Return;
	EndIf;
	
	If WriteParameters.DataProcessorRegistration Then
		RefreshReusableValues();
		NotificationText1 = NStr("vi = 'Để áp dụng các thay đổi trong cửa sổ mở ra, hãy đóng và mở lại cửa sổ.';
								|ru = 'Для применения изменений в открытых окнах закройте их и откройте заново.';
								|en = 'To apply the changes in open windows, close and reopen them.'; fa = 'To apply the changes in open windows, close and reopen them.';
								|it = 'Per l''applicazione delle modifiche nelle finestre aperte, chiuderle e riaprirle.';
								|pl = 'Aby zastosować zmiany w otwartych oknach dialogowych zamknij je i otwórz ponownie.';
								|tr = 'Değişiklikleri açık pencerelere uygulamak için onları kapatın ve yeniden açın.'");
		ShowUserNotification(, , NotificationText1);
	EndIf;
	WriteAtClientCompletion(WriteParameters);
	
EndProcedure

&AtClient
Procedure WriteAtClientCompletion(WriteParameters)
	If WriteParameters.CloseAfterWrite And IsOpen() Then
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFile()
	Notification = New CallbackDescription("UpdateFromFileAfterConfirm", ThisObject);
	UsersInternalClient.ShowSecurityWarning(Notification,
		UsersInternalClientServer.SecurityWarningKinds().BeforeAddExternalReportOrDataProcessor);
EndProcedure

&AtClient
Procedure UpdateFromFileAfterConfirm(Response, RegistrationParameters) Export
	If Response <> "Continue" Then
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
		Return;
	EndIf;
	
	RegistrationParameters = New Structure;
	RegistrationParameters.Insert("Success", False);
	RegistrationParameters.Insert("DataProcessorDataAddress", DataProcessorDataAddress);
	
	Handler = New CallbackDescription("UpdateFromFileAfterFileChoice", ThisObject, RegistrationParameters);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = AdditionalReportsAndDataProcessorsClientServer.SelectingAndSavingDialogFilter();
	ImportParameters.FormIdentifier = UUID;
	
	If Object.Ref.IsEmpty() Then
		ImportParameters.Dialog.FilterIndex = 0;
		ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp báo cáo hoặc bộ xử lý ngoài';
											|ru = 'Выберите файл внешнего отчета или обработки';
											|en = 'Select a file with external report or data processor'; fa = 'Select a file with external report or data processor';
											|it = 'Selezionate un file per un report o un elaborazione esterna';
											|pl = 'Wybierz plik raportu zewnętrznego lub przetwarzania';
											|tr = 'Harici rapor veya veri işlemcisi seçin'");
	ElsIf Object.Kind = KindAdditionalReport Or Object.Kind = KindOfReport Then
		ImportParameters.Dialog.FilterIndex = 1;
		ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp báo cáo ngoài';
											|ru = 'Выберите файл внешнего отчета';
											|en = 'Select an file with external report'; fa = 'Select an file with external report';
											|it = 'Selezionate un file per un report esterno';
											|pl = 'Wybierz plik raportu zewnętrznego';
											|tr = 'Harici rapor dosyası seçin'");
	Else
		ImportParameters.Dialog.FilterIndex = 2;
		ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp bộ xử lý ngoài';
											|ru = 'Выберите файл внешней обработки';
											|en = 'Select a file with external data processor'; fa = 'Select a file with external data processor';
											|it = 'Selezionate un file per l''elaborazione esterna';
											|pl = 'Wybierz plik przetwarzania zewnętrznego';
											|tr = 'Harici veri işlemcisi dosyası seçin'");
	EndIf;
	
	FileSystemClient.ImportFile_(Handler, ImportParameters, Object.FileName);
	
EndProcedure

&AtClient
Procedure UpdateFromFileAfterFileChoice(FileDetails, RegistrationParameters) Export
	If FileDetails = Undefined Then
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
		Return;
	EndIf;
	
	Keys = New Structure("FileName, IsReport, DisablePublication, DisableConflicts, Conflicting");
	CommonClientServer.SupplementStructure(RegistrationParameters, Keys, False);
	
	RegistrationParameters.DisablePublication = False;
	RegistrationParameters.DisableConflicts = False;
	RegistrationParameters.Conflicting = New ValueList;
	
	SubstringsArray = StrSplit(FileDetails.Name, GetPathSeparator(), False);
	RegistrationParameters.FileName = SubstringsArray.Get(SubstringsArray.UBound());
	FileExtention = Upper(Right(RegistrationParameters.FileName, 3));
	
	If FileExtention = "ERF" Then
		RegistrationParameters.IsReport = True;
	ElsIf FileExtention = "EPF" Then
		RegistrationParameters.IsReport = False;
	Else
		RegistrationParameters.Success = False;
		HandlerResults_1 = New CallbackDescription("UpdateFromFileCompletion", ThisObject, RegistrationParameters);
		WarningText = NStr("vi = 'Phần mở rộng tệp không tương ứng với phần mở rộng báo cáo ngoài (ERF) hoặc bộ xử lý ngoài (EPF).';
							|ru = 'Расширение файла не соответствует расширению внешнего отчета (ERF) или обработки (EPF).';
							|en = 'The file extension does not match external report extension (ERF) or external data processor extension (EPF).'; fa = 'The file extension does not match external report extension (ERF) or external data processor extension (EPF).';
							|it = 'L''estensione del file non corrisponde all''estensione del report (ERF) o dell''elaborazione (EPF) esterna.';
							|pl = 'Rozszerzenie pliku nie zgadza się z rozszerzeniem raportu zewnętrznego (ERFZ) lub przetwarzania (EPF).';
							|tr = 'Dosya uzantısı harici rapor uzantısı (ERF) veya harici veri işlemcisi uzantısı (EPF) ile uyuşmuyor.'");
		ReturnParameters1 = New Structure;
		ReturnParameters1.Insert("Handler", HandlerResults_1);
		ReturnParameters1.Insert("Result",  Undefined);
		SimpleDialogHandler = New CallbackDescription("ReturnResultAfterCloseSimpleDialog", ThisObject, ReturnParameters1);
		ShowMessageBox(SimpleDialogHandler, WarningText);
		Return;
	EndIf;
	
	RegistrationParameters.DataProcessorDataAddress = FileDetails.Location;
	
	UpdateFromFileAndMessage(RegistrationParameters);
EndProcedure

&AtClient
Procedure ReturnResultAfterCloseSimpleDialog(HandlerParameters) Export
	If TypeOf(HandlerParameters.Handler) = Type("CallbackDescription") Then
		RunCallback(HandlerParameters.Handler, HandlerParameters.Result);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileAndMessage(RegistrationParameters)

	UpdateFromFileAtServer(RegistrationParameters);
	
	If RegistrationParameters.DisableConflicts Then
		// Multiple objects are disabled, which requires dynamic list refresh.
		NotifyChanged(Type("CatalogRef.AdditionalReportsAndDataProcessors"));
	EndIf;
	
	If RegistrationParameters.Success Then
		NotificationTitle1 = ?(RegistrationParameters.IsReport, NStr("vi = 'Đã kết nhập tệp báo cáo ngoài';
																	|ru = 'Файл внешнего отчета загружен';
																	|en = 'External report file is imported'; fa = 'External report file is imported';
																	|it = 'File del report esterno esportato';
																	|pl = 'Plik raportu zewnętrznego został pobrany';
																	|tr = 'Harici rapor dosyası içe aktarıldı'"), NStr("vi = 'Đã kết nhập tệp bộ xử lý ngoài';
																														|ru = 'Файл внешней обработки загружен';
																														|en = 'External data processor file is imported'; fa = 'External data processor file is imported';
																														|it = 'File dell''elaborazione esterna esportato';
																														|pl = 'Plik przetwarzania zewnętrznego został pobrany';
																														|tr = 'Harici veri işlemcisi dosyası içe aktarıldı'"));
		NotificationRef    = ?(IsNew, "", GetURL(Object.Ref));
		NotificationText     = RegistrationParameters.FileName;
		ShowUserNotification(NotificationTitle1, NotificationRef, NotificationText);
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
	ElsIf RegistrationParameters.ObjectNameUsed Then // Checking the reason of canceling data processor import and displaying the reason to the user.
		ShowConflicts(RegistrationParameters);
	Else
		HandlerResults_1 = New CallbackDescription("UpdateFromFileCompletion", ThisObject, RegistrationParameters);
		QuestionParameters = StandardSubsystemsClient.QuestionToUserParameters();
		QuestionParameters.PromptDontAskAgain = False;
		StandardSubsystemsClient.ShowQuestionToUser(HandlerResults_1, RegistrationParameters.ErrorText, 
			QuestionDialogMode.OK, QuestionParameters);
	EndIf;
EndProcedure

&AtClient
Procedure ShowConflicts(RegistrationParameters)
	
	If RegistrationParameters.ConflictsCount > 1 Then
		If RegistrationParameters.IsReport Then
			QuestionTitle = NStr("vi = 'Xung đột khi kết nhập báo cáo ngoài';
								|ru = 'Конфликты при загрузке внешнего отчета';
								|en = 'External report import conflicts'; fa = 'External report import conflicts';
								|it = 'Conflitti durante l''esportazione del report esterno';
								|pl = 'Konflikty podczas pobierania raportu zewnętrznego';
								|tr = 'Harici rapor içe aktarılırken oluşan çakışmalar'");
			QueryText = NStr("vi = 'Tên nội bộ của báo cáo ""[Name]""
			|đã được sử dụng trong các báo cáo bổ sung hiện có ([Count]): 
			|[List].
			|
			|Chọn:
			|1. ""[Continue]"" - tải báo cáo mới ở chế độ gỡ rối.
			|2. ""[Disable]"" - tải báo cáo mới, sau khi vô hiệu hóa đăng tải tất cả báo cáo xung đột.
			|3. ""[Open]"" - hủy tải xuống và hiển thị danh sách các báo cáo xung đột.';
			|ru = 'Внутреннее имя отчета ""[Name]""
			|уже занято существующими дополнительными отчетами ([Count]): 
			|[List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новый отчет в режиме отладки.
			|2. ""[Disable]"" - загрузить новый отчет, отключив публикацию всех конфликтующих отчетов.
			|3. ""[Open]"" - отменить загрузку и показать список конфликтующих отчетов.';
			|en = 'Internal report name ""[Name]"" 
			|is already used by the following additional reports ([Count]):
			|[List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new report in debug mode.
			|2. ""[Disable]"". Disable all conflicting reports and import the new report.
			|3. ""[Open]"". Cancel the import and show the list of conflicting reports.'; fa = 'Internal report name ""[Name]"" 
			|is already used by the following additional reports ([Count]):
			|[List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new report in debug mode.
			|2. ""[Disable]"". Disable all conflicting reports and import the new report.
			|3. ""[Open]"". Cancel the import and show the list of conflicting reports.';
			|it = 'Il nome interno del report ""[Name]""
			| è già utilizzato da report aggiuntivi esistenti ([Count]): 
			|[List].
			|
			|Selezionate:
			|1. "" [Continue]""- caricare il nuovo report in modalità di debug. 
			|2. ""[Disable]""- caricare il nuovo report, disabilitando la pubblicazione di tutti i report in conflitto.
			|3. ""[Open]""- annullare l''esportazione e mostrare l''elenco di tutti i report in conflitto.';
			|pl = 'Nazwa wewnętrzna raportu ""[Name]""
			|jest już zajęta przez istniejące raporty dodatkowe ([Count]): 
			|[List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowy raport w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowy raport z wyłączeniem publikacji wszystkich konfliktujących raportów.
			|3. ""[Open]"" - anuluj pobieranie i pokaż listę konfliktujących raportów.';
			|tr = '""[Name]"" raporunun 
			|dahili adı zaten mevcut ek raporlar tarafından alınmış ([Count]): 
			|[List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir rapor indir. 
			|2. ""[Disable]"" - tüm çelişkili raporların yayınlanmasını engelleyen yeni bir rapor indirin. 
			|3. ""[Open]"" - indirmeyi iptal edin ve çakışan raporların bir listesini gösterin.'");
		Else
			QuestionTitle = NStr("vi = 'Xung đột khi kết nhập bộ xử lý ngoài';
								|ru = 'Конфликты при загрузке внешней обработки';
								|en = 'Conflicts occurred during import of external data processor'; fa = 'Conflicts occurred during import of external data processor';
								|it = 'Conflitti durante l''esportazione dell''elaborazione esterna';
								|pl = 'Konflikty podczas pobierania przetwarzania zewnętrznego';
								|tr = 'Harici veri işlemcisi içe aktarılırken çakışmalar meydana geldi'");
			QueryText = NStr("vi = 'Tên bộ xử lý nội bộ ""[Name]""
			|đã được sử dụng trong các bộ xử lý bổ sung hiện có ([Count]):
			|[List].
			|
			|Chọn:
			|1. ""[Continue]"" - tải bộ xử lý mới ở chế độ gỡ rối.
			|2. ""[Disable]"" - tải bộ xử lý mới, sau khi vô hiệu hóa việc đăng tải tất cả bộ xử lý xung đột.
			|3. ""[Open]"" - hủy tải xuống và hiển thị danh sách bộ xử lý xung đột.';
			|ru = 'Внутреннее имя обработки ""[Name]""
			|уже занято существующими дополнительными обработками ([Count]):
			|[List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новую обработку в режиме отладки.
			|2. ""[Disable]"" - загрузить новую обработку, отключив публикацию всех конфликтующих обработок.
			|3. ""[Open]"" - отменить загрузку и показать список конфликтующих обработок.';
			|en = 'Internal name of data processor ""[Name]"" 
			|is already used by the following additional data processors ([Count]):
			|[List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new data processor in the debug mode.
			|2. ""[Disable]"". Disable all conflicting data processors and import the new data processor.
			|3. ""[Open]"". Cancel the import and show the list of conflicting data processors.'; fa = 'Internal name of data processor ""[Name]"" 
			|is already used by the following additional data processors ([Count]):
			|[List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new data processor in the debug mode.
			|2. ""[Disable]"". Disable all conflicting data processors and import the new data processor.
			|3. ""[Open]"". Cancel the import and show the list of conflicting data processors.';
			|it = 'Il nome interno dell''elaborazione ""[Name]""
			| è già utilizzato da elaborazioni aggiuntive esistenti ([Count]): 
			|[List].
			|
			|Selezionate:
			|1.""[Continue]""- caricare l''elaborazione nuova in modalità di debug.
			|2.   ""[Disable]""- caricare l''elaborazione nuova, disabilitando la pubblicazione di tutti gli elaborati in conflitto.
			|3. ""[Open]"" - annullare l''esportazione e mostrare l''elenco di tutti le elaborazioni in conflitto.';
			|pl = 'Nazwa wewnętrzna przetwarzania ""[Name]""
			|jest już zajęta przez istniejące dodatkowe procedury przetwarzania ([Count]): 
			|[List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowe przetwarzanie w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowe przetwarzanie z wyłączeniem publikacji wszystkich konfliktujących procedur przetwarzania
			|3. ""[Open]"" - anuluj pobieranie i pokaż listę konfliktujących procedur przetwarzania.';
			|tr = '""[Name]"" raporunun 
			|dahili adı zaten mevcut ek veri işlemcileri tarafından alınmış ([Count]): 
			|[List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir veri işlemcisini indir. 
			|2. ""[Disable]"" - tüm çelişkili veri işlemcilerin yayınlanmasını engelleyen yeni bir veri işlemcisini indirin. 
			|3. ""[Open]"" - indirmeyi iptal edin ve çakışan veri işlemcilerin listesini gösterin.'");
		EndIf;
		DisableButtonPresentation = NStr("vi = 'Vô hiệu hóa các phần tử xung đột';
										|ru = 'Отключить конфликтующие';
										|en = 'Disable conflicting objects'; fa = 'Disable conflicting objects';
										|it = 'Disabilitare quelli in conflitto';
										|pl = 'Wyłącz konfliktujące';
										|tr = 'Çakışmayı devre dışı bırak'");
		OpenButtonPresentation = NStr("vi = 'Hủy bỏ và hiển thị danh sách';
										|ru = 'Отменить и показать список';
										|en = 'Cancel and show list'; fa = 'Cancel and show list';
										|it = 'Annullare e mostrare l''elenco';
										|pl = 'Anuluj i pokaż listę';
										|tr = 'İptal et ve listeyi göster'");
	Else
		If RegistrationParameters.IsReport Then
			QuestionTitle = NStr("vi = 'Xung đột khi kết nhập báo cáo ngoài';
								|ru = 'Конфликт при загрузке внешнего отчета';
								|en = 'External report import conflict'; fa = 'External report import conflict';
								|it = 'Conflitto durante l''esportazione di un report esterno';
								|pl = 'Konflikt podczas pobierania raportu zewnętrznego';
								|tr = 'Harici rapor içe aktarılırken oluşan çakışma'");
			QueryText = NStr("vi = 'Tên nội bộ của báo cáo ""[Name]""
			|đã được sử dụng trong báo cáo bổ sung [List].
			|
			|Chọn:
			|1. ""[Continue]"" - tải báo cáo mới ở chế độ gỡ rối.
			|2. ""[Disable]"" - tải báo cáo mới, sau khi vô hiệu hóa đăng tải báo cáo xung đột.
			|3. ""[Open]"" - mở thẻ báo cáo xung đột.';
			|ru = 'Внутреннее имя отчета ""[Name]""
			|уже занято существующим дополнительным отчетом [List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новый отчет в режиме отладки.
			|2. ""[Disable]"" - загрузить новый отчет, отключив публикацию конфликтующего отчета.
			|3. ""[Open]"" - открыть карточку конфликтующего отчета.';
			|en = 'Internal report name ""[Name]"" 
			|is already used by additional report [List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new report in debug mode.
			|2. ""[Disable]"". Disable the conflicting report and import the new report.
			|3. ""[Open]"". Open the conflicting report''s card.'; fa = 'Internal report name ""[Name]"" 
			|is already used by additional report [List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new report in debug mode.
			|2. ""[Disable]"". Disable the conflicting report and import the new report.
			|3. ""[Open]"". Open the conflicting report''s card.';
			|it = 'Il nome interno del report ""[Name]""
			| è già utilizzato da un report aggiuntivo esistente [List].
			|
			|Selezionate:
			|1.""[Continue]"" - caricare il nuovo report in modalità di debug.
			|2. ""[Disable]"" - caricare il nuovo report, disabilitando la pubblicazione del report in conflitto.
			|3. ""[Open]"" - aprire la scheda del report in conflitto.';
			|pl = 'Nazwa wewnętrzna raportu ""[Name]""
			|jest już zajęta przez istniejący raport dodatkowy [List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowy raport w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowy raport z wyłączeniem publikacji konfliktującego raportu.
			|3. ""[Open]"" - otwórz kartę konfliktującego raportu.';
			|tr = '""[Name]"" raporunun 
			|dahili adı zaten mevcut ek raporlar tarafından alınmış [List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir rapor indir. 
			|2. ""[Disable]"" - tüm çelişkili raporların yayınlanmasını engelleyen yeni bir rapor indirin. 
			|3. ""[Open]"" - çakışan raporunun kartını açın.'");
			DisableButtonPresentation = NStr("vi = 'Vô hiệu hóa báo cáo khác';
											|ru = 'Отключить другой отчет';
											|en = 'Disable another report'; fa = 'Disable another report';
											|it = 'Disabilitare altro report';
											|pl = 'Wyłącz inny raport';
											|tr = 'Diğer raporu devre dışı bırak'");
		Else
			QuestionTitle = NStr("vi = 'Xung đột khi kết nhập bộ xử lý ngoài';
								|ru = 'Конфликт при загрузке внешней обработки';
								|en = 'External data processor import conflict'; fa = 'External data processor import conflict';
								|it = 'Conflitto durante l''esportazione di un elaborazione esterna';
								|pl = 'Konflikt podczas pobierania przetwarzania zewnętrznego';
								|tr = 'Harici veri işlemcisi içe aktarılırken çakışma meydana geldi'");
			QueryText = NStr("vi = 'Tên nội bộ của bộ xử lý ""[Name]""
			|đã được dùng trong bộ xử lý bổ sung hiện có [List].
			|
			|Chọn:
			|1. ""[Continue]"" - tải bộ xử lý mới ở chế độ gỡ rối.
			|2. ""[Disable]"" - tải bộ xử lý mới, sau khi vô hiệu hóa đăng tải bộ xử lý xung đột.
			|3. ""[Open]"" - mở thẻ bộ xử lý xung đột.';
			|ru = 'Внутреннее имя обработки ""[Name]""
			|уже занято существующей дополнительной обработкой [List].
			|
			|Выберите:
			|1. ""[Continue]"" - загрузить новую обработку в режиме отладки.
			|2. ""[Disable]"" - загрузить новую обработку, отключив публикацию конфликтующей обработки.
			|3. ""[Open]"" - открыть карточку конфликтующей обработки.';
			|en = 'Internal name of data processor ""[Name]"" 
			|is already used by additional data processor [List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new data processor in debug mode.
			|2. ""[Disable]"". Disable the conflicting data processor and import the new data processor.
			|3. ""[Open]"". Open the conflicting data processor''s card.'; fa = 'Internal name of data processor ""[Name]"" 
			|is already used by additional data processor [List].
			|
			|Select one of the following:
			|1. ""[Continue]"". Import the new data processor in debug mode.
			|2. ""[Disable]"". Disable the conflicting data processor and import the new data processor.
			|3. ""[Open]"". Open the conflicting data processor''s card.';
			|it = 'Il nome interno dell''elaborazione ""[Name]""
			| è già utilizzato da un rapporto aggiuntivo esistente [List].
			|
			|Selezionate:
			|1.""[Continue]"" - caricare l''elaborazione nuova in modalità di debug.
			|2. ""[Disable]"" - caricare l''elaborazione nuova, disabilitando la pubblicazione dell''elaborazione in conflitto.
			|3. ""[Open]"" - aprire la scheda dell''elaborazione in conflitto.';
			|pl = 'Nazwa wewnętrzna przetwarzania ""[Name]""
			|jest już zajęta przez istniejące dodatkowe procedury przetwarzania[List].
			|
			|Wybierz:
			|1. ""[Continue]"" - pobierz nowe przetwarzanie w trybie debugowania.
			|2. ""[Disable]"" - pobierz nowe przetwarzanie z wyłączeniem publikacji wszystkich konfliktujących procedur przetwarzania
			|3. ""[Open]"" - otwórz kartę konfliktujących procedur przetwarzania.';
			|tr = '""[Name]"" veri işlemcisinin 
			|dahili adı zaten mevcut ek veri işlemcisi tarafından alınmış [List]. 
			|
			|Seçin: 
			|1. ""[Continue]"" - hata ayıklama modunda yeni bir veri işlemcisini indir. 
			|2. ""[Disable]"" - tüm çelişkili veri işlemcisinin yayınlanmasını engelleyen yeni bir veri işlemcisini indirin. 
			|3. ""[Open]"" - çakışan veri işlemcisinin kartını açın.'");
			DisableButtonPresentation = NStr("vi = 'Vô hiệu hóa bộ xử lý khác';
											|ru = 'Отключить другую обработку';
											|en = 'Disable another data processor'; fa = 'Disable another data processor';
											|it = 'Disabilitare un''altra elaborazione';
											|pl = 'Wyłącz inne przetwarzanie';
											|tr = 'Diğer veri işlemcisini devre dışı bırak'");
		EndIf;
		OpenButtonPresentation = NStr("vi = 'Hủy bỏ và mở ra';
										|ru = 'Отменить и открыть';
										|en = 'Cancel and open'; fa = 'Cancel and open';
										|it = 'Annullare e aprire';
										|pl = 'Anuluj i otwórz';
										|tr = 'İptal et ve aç'");
	EndIf;
	ContinueButtonPresentation = NStr("vi = 'Ở chế độ gỡ rối';
										|ru = 'В режиме отладки';
										|en = 'Debug mode'; fa = 'حالت اشکال‌زدایی';
										|it = 'In modalità di debug';
										|pl = 'W trybie debugowania';
										|tr = 'Hata ayıklama modunda'");
	QueryText = StrReplace(QueryText, "[Name]",  RegistrationParameters.ObjectName);
	QueryText = StrReplace(QueryText, "[Count]", RegistrationParameters.ConflictsCount);
	QueryText = StrReplace(QueryText, "[List]",  RegistrationParameters.LockersPresentation);
	QueryText = StrReplace(QueryText, "[Disable]",  DisableButtonPresentation);
	QueryText = StrReplace(QueryText, "[Open]",     OpenButtonPresentation);
	QueryText = StrReplace(QueryText, "[Continue]", ContinueButtonPresentation);
	
	QuestionButtons = New ValueList;
	QuestionButtons.Add("ContinueWithoutPublishing", ContinueButtonPresentation);
	QuestionButtons.Add("DisableConflictingItems",  DisableButtonPresentation);
	QuestionButtons.Add("CancelAndOpen",        OpenButtonPresentation);
	QuestionButtons.Add(DialogReturnCode.Cancel);
	
	Handler = New CallbackDescription("UpdateFromFileConflictDecision", ThisObject, RegistrationParameters);
	ShowQueryBox(Handler, QueryText, QuestionButtons, , "ContinueWithoutPublishing", QuestionTitle);
EndProcedure

&AtClient
Procedure UpdateFromFileConflictDecision(Response, RegistrationParameters) Export
	If Response = "ContinueWithoutPublishing" Then
		// Recall server (Debug mode option) and process the result.
		RegistrationParameters.DisablePublication = True;
		UpdateFromFileAndMessage(RegistrationParameters);
	ElsIf Response = "DisableConflictingItems" Then
		// Repeating server call (switching conflicting items to debug mode) and processing the result.
		RegistrationParameters.DisableConflicts = True;
		UpdateFromFileAndMessage(RegistrationParameters);
	ElsIf Response = "CancelAndOpen" Then
		// Cancel and show the conflicts.
		// The list is displayed if there is more than one conflicting item.
		ShowList = (RegistrationParameters.ConflictsCount > 1);
		If RegistrationParameters.OldObjectName = RegistrationParameters.ObjectName And Not IsNew Then
			// Or the current item has a name collision.
			// The list contains the current item and the conflicting item.
			// This allows you to review and decide which one should be disabled.
			ShowList = True;
		EndIf;
		If ShowList Then // List form with a filter by conflicting items.
			Var_FormName = "Catalog.AdditionalReportsAndDataProcessors.ListForm";
			FormTitle = NStr("vi = 'Báo cáo và bộ xử lý bổ sung với tên nội bộ ""%1""';
							|ru = 'Дополнительные отчеты и обработки с внутреннем именем ""%1""';
							|en = 'Additional reports and data processors with name ""%1""'; fa = 'Additional reports and data processors with name ""%1""';
							|it = 'Report ed elaborazioni aggiuntive con un nome interno ""%1""';
							|pl = 'Raporty dodatkowe i procedury przetwarzania z nazwą wewnętrzną ""%1""';
							|tr = 'Dahili adı ""%1"" olan ek raporlar ve veri işlemcileri'");
			FormTitle = StringFunctionsClientServer.SubstituteParametersToString(FormTitle, RegistrationParameters.ObjectName);
			ParametersForm = New Structure;
			ParametersForm.Insert("Filter", New Structure);
			ParametersForm.Filter.Insert("ObjectName", RegistrationParameters.ObjectName);
			ParametersForm.Filter.Insert("IsFolder", False);
			ParametersForm.Insert("Title", FormTitle);
			ParametersForm.Insert("Representation", "List");
		Else // Item form.
			Var_FormName = "Catalog.AdditionalReportsAndDataProcessors.ObjectForm";
			ParametersForm = New Structure;
			ParametersForm.Insert("Key", RegistrationParameters.Conflicting[0].Value);
		EndIf;
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
		OpenForm(Var_FormName, ParametersForm, Undefined, True);
	Else // Cancel.
		UpdateFromFileCompletion(Undefined, RegistrationParameters);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateFromFileCompletion(EmptyResult, RegistrationParameters) Export
	If RegistrationParameters = Undefined Or RegistrationParameters.Success = False Then
		If ShowImportFromFileDialogOnOpen And IsOpen() Then
			Close();
		EndIf;
	ElsIf RegistrationParameters.Success = True Then
		If Not IsOpen() Then
			Open();
		EndIf;
		Modified = True;
		DataProcessorRegistration = True;
		DataProcessorDataAddress = RegistrationParameters.DataProcessorDataAddress;
	EndIf;
EndProcedure

&AtClient
Procedure OpenOption()
	Variant = Items.AdditionalReportOptions.CurrentData;
	If Variant = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Variant.Ref) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Phương án báo cáo ""%1"" chưa được ghi nhận.';
																					|ru = 'Вариант отчета ""%1"" не зарегистрирован.';
																					|en = '""%1"" report option is not registered.'; fa = '""%1"" report option is not registered.';
																					|it = 'Variante del report""%1"" non registrata.';
																					|pl = 'Wariant raportu ""%1"" nie został zarejestrowany.';
																					|tr = 'Rapor seçeneği ""%1"" kayıtlı değil.'"), Variant.Description);
		ShowMessageBox(, ErrorText);
	Else
		ModuleReportsOptionsClient = CommonClient.CommonModule("ReportsOptionsClient");
		ModuleReportsOptionsClient.ShowReportSettings(Variant.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure ChangeScheduledJob(Var_ChoiceMode = False, CheckBoxChanged = False)
	
	ItemCommand = Items.ObjectCommands.CurrentData;
	If ItemCommand = Undefined Then
		Return;
	EndIf;
	
	If ItemCommand.StartupOption <> PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		And ItemCommand.StartupOption <> PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
		ErrorText = NStr("vi = 'Không thể sử dụng lệnh có phương án khởi chạy ""%1"" 
		|trong các nhiệm vụ thường kỳ.';
		|ru = 'Команда с вариантом запуска ""%1""
		|не может использоваться в регламентных заданиях.';
		|en = 'Scheduled jobs do not support commands
		|with the ""%1"" startup option.'; fa = 'Scheduled jobs do not support commands
		|with the ""%1"" startup option.';
		|it = 'Il comando con la variante d''avvio ""%1""
		|non può essere usato nelle operazioni di routine.';
		|pl = 'Polecenie z wariantem uruchomienia ""%1""
		|nie może być używane w zadaniach reglamentowanych.';
		|tr = 'Başlangıç seçeneği komutu 
		|""%1"" planlanan işlerde kullanılamaz.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, String(ItemCommand.StartupOption));
		ShowMessageBox(, ErrorText);
		If CheckBoxChanged Then
			ItemCommand.ScheduledJobUsage = Not ItemCommand.ScheduledJobUsage;
		EndIf;
		Return;
	EndIf;
	
	If CheckBoxChanged And Not ItemCommand.ScheduledJobUsage Then
		Return;
	EndIf;
	
	If ItemCommand.ScheduledJobSchedule.Count() > 0 Then
		CommandSchedule = ItemCommand.ScheduledJobSchedule.Get(0).Value;
	Else
		CommandSchedule = Undefined;
	EndIf;
	
	If TypeOf(CommandSchedule) <> Type("JobSchedule") Then
		CommandSchedule = New JobSchedule;
	EndIf;
	
	Context = New Structure;
	Context.Insert("ItemCommand", ItemCommand);
	Context.Insert("DisableFlagOnCancelEdit", CheckBoxChanged);
	Context.Insert("CommandSchedule", CommandSchedule);
	
	Handler = New CallbackDescription("BeforeEnableScheduledLaunch", ThisObject, Context);
	UsersInternalClient.ShowSecurityWarning(Handler,
		UsersInternalClientServer.SecurityWarningKinds().BeforeEnableScheduledJobOfAdditionalDataProcessor);
	
EndProcedure

&AtClient
Procedure BeforeEnableScheduledLaunch(Result, Context) Export
	If Result <> "Continue" Then
		ItemCommand = Context.ItemCommand;
		ItemCommand.ScheduledJobUsage = False;
		Return;
	EndIf;
	Handler = New CallbackDescription("AfterScheduleEditComplete", ThisObject, Context);
	
	EditSchedule1 = New ScheduledJobDialog(Context.CommandSchedule);
	EditSchedule1.Show(Handler);
EndProcedure

&AtClient
Procedure AfterScheduleEditComplete(Schedule, Context) Export
	ItemCommand = Context.ItemCommand;
	If Schedule = Undefined Then
		If Context.DisableFlagOnCancelEdit Then
			ItemCommand.ScheduledJobUsage = False;
		EndIf;
	Else
		
		If DataSeparationEnabled
			And Schedule.RepeatPeriodInDay <> 0
			And Schedule.RepeatPeriodInDay < 60 Then
			MessageText = NStr("vi = 'Không thể đặt khoảng thời gian lặp lại nhiệm vụ thường kỳ dưới 60 giây.';
								|ru = 'Не допускается установка интервала повтора регламентного задания менее 60 секунд.';
								|en = 'Setting the retry interval of the scheduled job less than 60 seconds is not allowed.'; fa = 'Setting the retry interval of the scheduled job less than 60 seconds is not allowed.';
								|it = 'Impossibile impostare un intervallo di ripetizione del compito di routine inferiore ai 60 secondi.';
								|pl = 'Niedopuszczalne jest ustawienie interwału zadania reglamentowanego mniej niż 60 sekund.';
								|tr = 'Zamanlanmış görevi tekrarlama aralığının 60 saniyenin altına ayarlanmasına izin verilmez.'");
			ShowMessageBox(, MessageText);
			Return;
		EndIf;
		
		ItemCommand.ScheduledJobSchedule.Clear();
		ItemCommand.ScheduledJobSchedule.Add(Schedule);
		If AdditionalReportsAndDataProcessorsClientServer.ScheduleSpecified(Schedule) Then
			Modified = True;
			ItemCommand.ScheduledJobUsage = True;
			ItemCommand.ScheduledJobPresentation = String(Schedule);
		Else
			ItemCommand.ScheduledJobPresentation = NStr("vi = 'Chưa điền';
														|ru = 'Не заполнено';
														|en = 'Not filled'; fa = 'Not filled';
														|it = 'Non compilato';
														|pl = 'Nie wypełnione';
														|tr = 'Boş'");
			If ItemCommand.ScheduledJobUsage Then
				ItemCommand.ScheduledJobUsage = False;
				ShowUserNotification(
					NStr("vi = 'Đã vô hiệu hóa khởi động theo lịch biểu';
						|ru = 'Запуск по расписанию отключен';
						|en = 'Scheduling is disabled'; fa = 'Scheduling is disabled';
						|it = 'Esecuzione programmata disabilitata';
						|pl = 'Uruchomienie wg harmonogramu jest wyłączone';
						|tr = 'Planlanmış başlatma devre dışı bırakıldı'"),
					,
					NStr("vi = 'Chưa điền lịch biểu';
						|ru = 'Расписание не заполнено';
						|en = 'Schedule is not filled'; fa = 'Schedule is not filled';
						|it = 'Orario non compilato';
						|pl = 'Nie wypełniono harmonogramu';
						|tr = 'Program doldurulmadı'"));
			EndIf;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ChangeQuickAccess()
	ItemCommand = Items.ObjectCommands.CurrentData;
	If ItemCommand = Undefined Then
		Return;
	EndIf;
	
	FoundItems = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.Id));
	UsersWithQuickAccess = New ValueList;
	For Each TableRow In FoundItems Do
		UsersWithQuickAccess.Add(TableRow.User);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("UsersWithQuickAccess", UsersWithQuickAccess);
	FormParameters.Insert("CommandPresentation",         ItemCommand.Presentation);
	
	ClientCache.Insert("CommandRowID", ItemCommand.GetID());
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.Form.QuickAccessToAdditionalReportsAndDataProcessors", FormParameters, ThisObject);
	
EndProcedure

// Parameters:
//   Response - DialogReturnCode
//   AdditionalParameters - Structure
//
&AtClient
Procedure AdditionalReportOptionsBeforeDeleteRowCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Variant = AdditionalParameters.Variant;
		DeleteAdditionalReportOption("ExternalReport." + Object.ObjectName, Variant.VariantKey);
		AdditionalReportOptions.Delete(Variant);
	EndIf;
EndProcedure

&AtClient
Procedure ExecuteCommandAfterWriteConfirmed(Response, Context) Export
	If Response = "WriteAndContinue" Then
		ClearMessages();
		If Not Write() Then
			Return; // Failed to write, the platform shows an error message.
		EndIf;
	ElsIf Response <> "ContinueWithoutWriting" Then
		Return;
	EndIf;
	
	If Object.Ref.IsEmpty() Or Modified Then
		Return; // Final check.
	EndIf;
	
	CommandsTableRow = Items.ObjectCommands.CurrentData;
	If CommandsTableRow = Undefined
		Or CommandsTableRow.Id <> Context.CommandToExecuteID Then
		FoundItems = Object.Commands.FindRows(New Structure("Id", Context.CommandToExecuteID));
		If FoundItems.Count() = 0 Then
			Return;
		EndIf;
		CommandsTableRow = FoundItems[0];
	EndIf;
	
	CommandToExecute = New Structure(
		"Ref, Presentation,
		|Id, StartupOption, ShouldShowUserNotification, 
		|Modifier, RelatedObjects, IsReport, Kind");
	FillPropertyValues(CommandToExecute, CommandsTableRow);
	CommandToExecute.Ref = Object.Ref;
	CommandToExecute.Kind = Object.Kind;
	CommandToExecute.IsReport = (Object.Kind = KindAdditionalReport Or Object.Kind = KindOfReport);
	
	If CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm") Then
		
		AdditionalReportsAndDataProcessorsClient.OpenDataProcessorForm(CommandToExecute, ThisObject, CommandToExecute.RelatedObjects);
		
	ElsIf CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall") Then
		
		AdditionalReportsAndDataProcessorsClient.ExecuteDataProcessorClientMethod(CommandToExecute, ThisObject, CommandToExecute.RelatedObjects);
		
	ElsIf CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
		Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
		
		StateHeader = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đang thực hiện lệnh ""%1""';
				|ru = 'Выполняется команда ""%1""';
				|en = '""%1"" command is running'; fa = '""%1"" command is running';
				|it = 'Comando in esecuzione ""%1""';
				|pl = 'Trwa wykonywanie polecenia ""%1""';
				|tr = '""%1"" komutu yürütülüyor'"),
			CommandsTableRow.Presentation);
		ShowUserNotification(StateHeader + "...", , , PictureLib.TimeConsumingOperation48);
		
		TimeConsumingOperation = StartExecuteServerCommandInBackground(CommandToExecute, UUID);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.MessageText = StateHeader;
		IdleParameters.UserNotification.Show = True;
		IdleParameters.OutputIdleWindow = True;
		
		CallbackOnCompletion = New CallbackDescription("AfterCompleteExecutingServerCommandInBackground", ThisObject, CommandToExecute);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

// Parameters:
//  Job - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure AfterCompleteExecutingServerCommandInBackground(Job, AdditionalParameters) Export
	
	If Job = Undefined Then
		Return;
	EndIf;
	
	If Job.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Job.ErrorInfo);
		Return;
	EndIf;
	
	Result = GetFromTempStorage(Job.ResultAddress);
	NotifyForms = CommonClientServer.StructureProperty(Result, "NotifyForms");
	If NotifyForms <> Undefined Then
		StandardSubsystemsClient.NotifyFormsAboutChange(NotifyForms);
	EndIf;
	
EndProcedure

#EndRegion

#Region ClientServer

&AtClientAtServerNoContext
Function UsersQuickAccessPresentation(UsersCount)
	
	If UsersCount = 0 Then
		Return NStr("vi = 'Không';
					|ru = 'Нет';
					|en = 'None'; fa = 'None';
					|it = 'Non ci sono';
					|pl = 'None';
					|tr = 'Hayır'");
	EndIf;
	
	QuickAccessPresentation = StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("vi = ';%1 người sử dụng;;%1 người sử dụng;%1 người sử dụng;%1 người sử dụng';
			|ru = ';%1 пользователь;;%1 пользователя;%1 пользователей;%1 пользователя';
			|en = ';%1 user;;;;%1 users'; fa = ';%1 user;;;;%1 users';
			|it = ';%1 utente;;%1 dell''utente;%1 degli utenti;%1 dell''utente';
			|pl = ';%1 użytkownik;;%1 użytkownika;%1 użytkowników;%1 użytkownika';
			|tr = ';%1 kullanıcı;;%1 kullanıcı;%1 kullanıcı;%1 kullanıcı'"), UsersCount);
	
	Return QuickAccessPresentation;
	
EndFunction

#EndRegion

#Region ServerCallServer

&AtServerNoContext
Function StartExecuteServerCommandInBackground(CommandToExecute, UUID)
	
	ProcedureParameters = New Structure("AdditionalDataProcessorRef, CommandID, RelatedObjects");
	ProcedureParameters.AdditionalDataProcessorRef = CommandToExecute.Ref;
	ProcedureParameters.CommandID          = CommandToExecute.Id;
	ProcedureParameters.RelatedObjects             = CommandToExecute.RelatedObjects;
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription =
		NStr("vi = 'Báo cáo và bộ xử lý bổ sung: Thực hiện phương pháp xử lý máy chủ';
			|ru = 'Дополнительные отчеты и обработки: Выполнение серверного метода обработки';
			|en = 'Additional reports and data processors: executing data processor server method.'; fa = 'Additional reports and data processors: executing data processor server method.';
			|it = 'Report ed elaborazioni aggiuntive: esecuzione del metodo di elaborazione del server';
			|pl = 'Raporty dodatkowe i przetwarzanie: Wykonywanie serwerowej metody przetwarzania';
			|tr = 'Ek raporlar ve veri işlemcileri: Sunucu işlem yöntemini yürütme'");
	StartSettings1.RefinementErrors =
		NStr("vi = 'Không thể thực hiện lệnh theo nguyên nhân:';
			|ru = 'Не удалось выполнить команду по причине:';
			|en = 'Cannot execute the command. Reason:'; fa = 'Cannot execute the command. Reason:';
			|it = 'Не удалось выполнить команду по причине:';
			|pl = 'Cannot execute the command. Reason:';
			|tr = 'İşlem şu sebeple yürütülemedi:'");
	
	Return TimeConsumingOperations.ExecuteInBackground("AdditionalReportsAndDataProcessors.ExecuteCommand",
		ProcedureParameters, StartSettings1);
	
EndFunction

&AtServer
Procedure UpdateFromFileAtServer(RegistrationParameters)
	ObjectOfCatalog = FormAttributeToValue("Object");
	SavedCommands = ObjectOfCatalog.Commands.Unload();
	RegistrationResult = AdditionalReportsAndDataProcessors.RegisterDataProcessor(ObjectOfCatalog, RegistrationParameters);
	PermissionsAddress = PutToTempStorage(ObjectOfCatalog.Permissions.Unload(), UUID);
	ValueToFormAttribute(ObjectOfCatalog, "Object");
	
	CommonClientServer.SupplementStructure(RegistrationParameters, RegistrationResult, True);
	
	If RegistrationParameters.Success Then
		FillInCommands(SavedCommands);
		If RegistrationParameters.Property("ReportOptionAssignment") Then
			ReportOptionAssignment = RegistrationParameters.ReportOptionAssignment;
		EndIf;
	ElsIf RegistrationParameters.ObjectNameUsed Then
		LockersPresentation = "";
		For Each ListItem In RegistrationParameters.Conflicting Do
			If StrLen(LockersPresentation) > 80 Then
				LockersPresentation = LockersPresentation + "... ";
				Break;
			EndIf;
			LockersPresentation = LockersPresentation
				+ ?(LockersPresentation = "", "", ", ")
				+ """" + TrimAll(ListItem.Presentation) + """";
		EndDo;
		RegistrationParameters.Insert("LockersPresentation", LockersPresentation);
		RegistrationParameters.Insert("ConflictsCount", RegistrationParameters.Conflicting.Count());
	EndIf;
	
	SetVisibilityAvailability(RegistrationParameters.Success);
EndProcedure

&AtServer
Function PrepareMetadataObjectsSelectionFormParameters()
	MetadataObjectsTable = AdditionalReportsAndDataProcessors.AttachedMetadataObjects(Object.Kind);
	If MetadataObjectsTable = Undefined Then
		Return Undefined;
	EndIf;
	
	FilterByMetadataObjects = New ValueList;
	FilterByMetadataObjects.LoadValues(MetadataObjectsTable.UnloadColumn("FullName"));
	
	SelectedMetadataObjects = New ValueList;
	RelatedObjects = New Array;
	For Each AssignmentItem In Object.Purpose Do
		If MetadataObjectsTable.Find(AssignmentItem.RelatedObject, "Ref") <> Undefined Then
			RelatedObjects.Add(AssignmentItem.RelatedObject);
		EndIf;
	EndDo;
	
	AssignmentObjectsFullNames = Common.ObjectsAttributeValue(RelatedObjects, "FullName");
	For Each KeyAndValue In AssignmentObjectsFullNames Do
		SelectedMetadataObjects.Add(KeyAndValue.Value);
	EndDo;
	
	FormParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	FormParameters.FilterByMetadataObjects = FilterByMetadataObjects;
	FormParameters.SelectedMetadataObjects = SelectedMetadataObjects;
	FormParameters.Title = NStr("vi = 'Mục đích của bộ xử lý bổ sung';
								|ru = 'Назначение дополнительной обработки';
								|en = 'Additional data processor assignment'; fa = 'تخصیص پردازشگر داده تکمیلی';
								|it = 'Назначение дополнительной обработки';
								|pl = 'Przeznaczenie dodatkowego przetwarzania';
								|tr = 'Ek veri işlemenin amacı'");
	
	Return FormParameters;
EndFunction

&AtServer
Procedure ImportSelectedMetadataObjects(Parameter)
	Object.Purpose.Clear();
	
	For Each ParameterItem In Parameter Do
		MetadataObject = Common.MetadataObjectByFullName(ParameterItem.Value);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		AssignmentRow = Object.Purpose.Add();
		AssignmentRow.RelatedObject = Common.MetadataObjectID(MetadataObject);
	EndDo;
	
	Modified = True;
	SetVisibilityAvailability();
EndProcedure

&AtServerNoContext
Procedure DeleteAdditionalReportOption(ObjectKey, VariantKey)
	SettingsStorages["ReportsVariantsStorage"].Delete(ObjectKey, VariantKey, Undefined);
EndProcedure

&AtServer
Procedure SetVisibilityAvailability(Registration = False)
	
	IsGlobalDataProcessor = (Object.Kind = KindAdditionalDataProcessor Or Object.Kind = KindAdditionalReport);
	IsReport = (Object.Kind = KindAdditionalReport Or Object.Kind = KindOfReport);
	
	If Not Registration And Not IsNew And IsReport Then
		AdditionalReportOptionsFill();
	Else
		AdditionalReportOptions.Clear();
	EndIf;
	
	OptionsCount = AdditionalReportOptions.Count();
	CommandsCount = Object.Commands.Count();
	VisibleTabsCount = 1;
	
	If Object.Kind = KindAdditionalReport And Object.UseOptionStorage Then
		VisibleTabsCount = VisibleTabsCount + 1;
		
		Items.OptionsPages.Visible = True;
		
		If Registration Or OptionsCount = 0 Then
			Items.OptionsPages.CurrentPage = Items.OptionsHideBeforeWrite;
			Items.OptionsPage.Title = NStr("vi = 'Phương án báo cáo';
											|ru = 'Варианты отчета';
											|en = 'Report options'; fa = 'گزینه‌های گزارش';
											|it = 'Versioni del report';
											|pl = 'Warianty raportu';
											|tr = 'Rapor seçeneği'");
		Else
			Items.OptionsPages.CurrentPage = Items.OptionsShow;
			Items.OptionsPage.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phương án báo cáo (%1)';
					|ru = 'Варианты отчета (%1)';
					|en = 'Report options (%1)'; fa = 'Report options (%1)';
					|it = 'Varianti del report (%1)';
					|pl = 'Warianty raportu (%1)';
					|tr = '(%1) rapor seçeneği'"),
				Format(OptionsCount, "NG="));
		EndIf;
	Else
		Items.OptionsPages.Visible = False;
	EndIf;
	
	Items.CommandPage.Visible = CommandsCount > 0;
	If CommandsCount = 0 Then
		Items.CommandPage.Title = CommandsPageName();
	Else
		VisibleTabsCount = VisibleTabsCount + 1;
		Items.CommandPage.Title = CommandsPageName() + " (" + Format(CommandsCount, "NG=") + ")";
	EndIf;
	
	Items.ExecuteCommand.Visible = False;
	If IsGlobalDataProcessor And CommandsCount > 0 Then
		For Each CommandsTableRow In Object.Commands Do
			If CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.OpeningForm")
				Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ClientMethodCall")
				Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.ServerMethodCall")
				Or CommandsTableRow.StartupOption = PredefinedValue("Enum.AdditionalDataProcessorsCallMethods.SafeModeScenario") Then
				Items.ExecuteCommand.Visible = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	SafeModeProperties = SafeModeProperties();
	SafeMode = SafeModeProperties.SafeMode;
	PermissionsCount = SafeModeProperties.PermissionsCount;
	UseSecurityProfiles = SafeModeProperties.UseSecurityProfiles;
	
	If PermissionsCount = 0 Then
		
		Items.PermissionsPage.Visible = False;
		Items.SafeModeGlobalGroup.Visible = True;
		Items.SafeModeFalseLabelDecoration.Visible = (SafeMode = False);
		Items.SafeModeTrueLabelDecoration.Visible = (SafeMode = True);
		Items.EnablingSecurityProfilesGroup.Visible = False;
		
	Else
		
		VisibleTabsCount = VisibleTabsCount + 1;
		
		Items.PermissionsPage.Visible = True;
		Items.PermissionsPage.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Cho phép (%1)';
				|ru = 'Разрешения (%1)';
				|en = 'Permissions (%1)'; fa = 'Permissions (%1)';
				|it = 'Permessi (%1)';
				|pl = 'Zezwolenia (%1)';
				|tr = 'İzinler (%1)'"),
			Format(PermissionsCount, "NG="));
		
		Items.SafeModeGlobalGroup.Visible = False;
		
		Items.PermissionCompatibilityModesPagesGroup.CurrentPage = Items.PermissionsPageVersion_2_2_2;
		
		If UseSecurityProfiles And SafeMode = True Then
			Items.SafeModeWithPermissionsPages.CurrentPage = Items.SafeModeWithPermissionsPage;
		ElsIf TypeOf(SafeMode) = Type("Boolean") Then
			Items.SafeModeWithPermissionsPages.CurrentPage = Items.UnsafeModeWithPermissionsPage;
		ElsIf TypeOf(SafeMode) = Type("String") Then
			Items.SafeModeWithPermissionsPages.CurrentPage = Items.PersonalSecurityProfilePage;
			Items.DecorationPersonalSecurityProfileLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Báo cáo hoặc bộ xử lý bổ sung sẽ được kết nối đến ứng dụng có sử dụng hồ sơ bảo mật
					|""cá nhân"" %1 mà trong đó sẽ cho phép chỉ các thao tác sau:';
					|ru = 'Дополнительный отчет или обработка будет подключаться к приложению с использованием ""персонального""
					|профиля безопасности %1, в котором будут разрешены только следующие операции:';
					|en = 'The report or data processor will be attached to the application with a custom security profile
					|%1, which allows the following actions:'; fa = 'گزارش یا پردازشگر داده با یک پروفایل امنیتی سفارشی به برنامه پیوست خواهد شد
					|%1، که اقدامات زیر را مجاز می‌کند:';
					|it = 'Дополнительный отчет или обработка будет подключаться к приложению с использованием ""персонального""
					|профиля безопасности %1, в котором будут разрешены только следующие операции:';
					|pl = 'The report or data processor will be attached to the application with a custom security profile
					|%1, which allows the following actions:';
					|tr = 'Rapor veya veri işlemcisi, sadece aşağıdaki işlemlere izin veren özel bir 
					|güvenlik profiliyle%1 uygulamaya eklenecek:'"),
				SafeMode);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '%1 không phải là chế độ kết nối chính xác cho các báo cáo và bộ xử lý bổ sung
					| yêu cầu cho phép sử dụng hồ sơ bảo mật.';
					|ru = '%1 не является корректным режимом подключения для дополнительных отчетов и обработок,
					|требующих разрешений на использование профилей безопасности.';
					|en = '%1 is not a valid mode to attach additional reports and data processors
					|that require permissions to use security profiles.'; fa = '%1 is not a valid mode to attach additional reports and data processors
					|that require permissions to use security profiles.';
					|it = '%1 non risulta il regime corretto di connessione per i report e gli elaborati aggiuntivi,
					|che necessitano di permessi per l''utilizzo di profili di sicurezza.';
					|pl = '%1 nie jest prawidłowym trybem połączenia dla dodatkowych raportów i procedur przetwarzania,
					|wymagających zezwoleń na wykorzystywanie profili bezpieczeństwa.';
					|tr = 'Güvenlik profili kullanımı için izin gerektiren ek raporlar ve veri işlemcileri için %1 doğru bir 
					|bağlantı modu değil.'"),
				SafeMode);
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
			ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
			CanSetUpSecurityProfiles = ModuleSafeModeManagerInternal.CanSetUpSecurityProfiles();
		Else
			CanSetUpSecurityProfiles = False;
		EndIf;
		
		If SafeMode = False And Not UseSecurityProfiles And CanSetUpSecurityProfiles Then
			Items.EnablingSecurityProfilesGroup.Visible = True;
		Else
			Items.EnablingSecurityProfilesGroup.Visible = False;
		EndIf;
		
		GeneratePermissionsList();
		
	EndIf;
	
	Items.OptionsCommandsPermissionsPages.PagesRepresentation = FormPagesRepresentation[
		?(VisibleTabsCount > 1, "TabsOnTop", "None")];
	
	PurposePresentation = PurposePresentation(IsGlobalDataProcessor);
	
	Items.ObjectCommandsQuickAccessPresentation.Visible       = IsGlobalDataProcessor;
	Items.ObjectCommandsSetQuickAccess.Visible           = IsGlobalDataProcessor;
	Items.ObjectCommandsScheduledJobPresentation.Visible = IsGlobalDataProcessor;
	Items.ObjectCommandsScheduledJobUsage.Visible = IsGlobalDataProcessor;
	Items.ObjectCommandsSetSchedule.Visible              = IsGlobalDataProcessor;
	
	IsPrintForm = Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm;
	Items.FormsTypes.Visible = Not IsGlobalDataProcessor And Not IsPrintForm;
	If Not Items.FormsTypes.Visible Then
		Object.UseForObjectForm = True;
		Object.UseForListForm = True;
	EndIf;
	Items.SetPrintCommandVisibility.Visible = IsPrintForm;
	Items.ObjectCommandsComment.Visible = IsPrintForm;
	
	If IsNew Then
		Title = ?(IsReport, NStr("vi = 'Báo cáo bổ sung (tạo mới)';
								|ru = 'Дополнительный отчет (создание)';
								|en = 'Additional report (Create)'; fa = 'Additional report (Create)';
								|it = 'Report aggiuntivo (creazione)';
								|pl = 'Dodatkowy raport (tworzenie)';
								|tr = 'Ek rapor (Oluştur)'"), 
			NStr("vi = 'Bộ xử lý bổ sung (tạo mới)';
				|ru = 'Дополнительная обработка (создание)';
				|en = 'Additional data processor (Create)'; fa = 'Additional data processor (Create)';
				|it = 'Elaborazione aggiuntiva (creazione)';
				|pl = 'Dodatkowe przetwarzanie (tworzenie)';
				|tr = 'Ek veri işlemcisi (Oluştur)'"));
	Else
		Title = Object.Description + " " + ?(IsReport, NStr("vi = '(Báo cáo bổ sung)';
															|ru = '(Дополнительный отчет)';
															|en = '(Additional report)'; fa = '(Additional report)';
															|it = '(report aggiuntivo)';
															|pl = '(Dodatkowy raport)';
															|tr = '(Ek rapor)'"), 
			NStr("vi = '(Bộ xử lý bổ sung)';
				|ru = '(Дополнительная обработка)';
				|en = '(Additional data processor)'; fa = '(Additional data processor)';
				|it = '(Elaborazione aggiuntiva)';
				|pl = '(Dodatkowe przetwarzanie)';
				|tr = '(Ek veri işlemcisi)'"));
	EndIf;
	
	If OptionsCount > 0 Then
		OutputTableTitle = VisibleTabsCount <= 1 And Object.Kind = KindAdditionalReport 
			And Object.UseOptionStorage;
		Items.AdditionalReportOptions.TitleLocation = 
			FormItemTitleLocation[?(OutputTableTitle, "Top", "None")];
		Items.AdditionalReportOptions.Header               = Not OutputTableTitle;
		Items.AdditionalReportOptions.HorizontalLines = Not OutputTableTitle;
	EndIf;
	
	If CommandsCount > 0 Then
		OutputTableTitle = VisibleTabsCount <= 1 And Not IsGlobalDataProcessor;
		Items.ObjectCommands.TitleLocation = FormItemTitleLocation[
			?(OutputTableTitle, "Top", "None")];
		Items.ObjectCommands.Header               = Not OutputTableTitle;
		Items.ObjectCommands.HorizontalLines = Not OutputTableTitle;
	EndIf;
	
	WindowOptionsKey = AdditionalReportsAndDataProcessors.KindToString(Object.Kind);
	
EndProcedure

&AtServer
Function SafeModeProperties()

	Result = New Structure;
	Result.Insert("SafeMode", Object.SafeMode);
	Result.Insert("PermissionsCount", SecurityProfilePermissions().Count());
	Result.Insert("UseSecurityProfiles", False);
		
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		Result.UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
	EndIf;
	
	If GetFunctionalOption("SaaSOperations") Or Result.UseSecurityProfiles Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		If Object.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
			If Result.SafeMode And Result.PermissionsCount > 0 And Result.UseSecurityProfiles Then
				Result.SafeMode = ?(IsNew, "", ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(Object.Ref));
			EndIf;
		ElsIf Result.PermissionsCount = 0 Then
			Result.SafeMode = True;
		ElsIf Result.UseSecurityProfiles Then
			Result.SafeMode = ?(IsNew, "", ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(Object.Ref));
		Else
			Result.SafeMode = False;
		EndIf;
	EndIf;
	Return Result;

EndFunction

&AtServer
Function PurposePresentation(Val IsGlobalDataProcessor)
	Result = "";
	If IsGlobalDataProcessor Then
		For Each RowSection In Object.Sections Do
			SectionPresentation = AdditionalReportsAndDataProcessors.SectionPresentation(RowSection.Section);
			If SectionPresentation = Undefined Then
				Continue;
			EndIf;
			Result = ?(IsBlankString(Result), SectionPresentation,
				Result + ", " + SectionPresentation);
		EndDo;
	Else
		For Each AssignmentRow In Object.Purpose Do
			ObjectPresentation = AdditionalReportsAndDataProcessors.MetadataObjectPresentation(AssignmentRow.RelatedObject);
			Result = ?(IsBlankString(Result), ObjectPresentation,
				Result + ", " + ObjectPresentation);
		EndDo;
	EndIf;
	If Result = "" Then
		Result = NStr("vi = 'Không xác định';
						|ru = 'Не определено';
						|en = 'Undefined'; fa = 'تعریف‌نشده';
						|it = 'Non definito';
						|pl = 'Nie określono';
						|tr = 'Tanımlanmamış'");
	EndIf;
	Return Result;
EndFunction

#EndRegion

#Region Server

&AtServer
Procedure GeneratePermissionsList()
	
	PermissionsTable = GetFromTempStorage(PermissionsAddress);// CatalogTabularSection.AdditionalReportsAndDataProcessors.Permissions
	
	Permissions = New Array();
	
	ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
	
	For Each TableRow In PermissionsTable Do
		Resolution = XDTOFactory.Create(XDTOFactory.Type(ModuleSafeModeManagerInternal.Package(), TableRow.PermissionKind));
		FillPropertyValues(Resolution, TableRow.Parameters.Get());
		Permissions.Add(Resolution);
	EndDo;
	
	Properties = ModuleSafeModeManagerInternal.PropertiesForPermissionRegister(Object.Ref);
	
	SetPrivilegedMode(True);
	PermissionsPresentation_2_2_2 = ModuleSafeModeManagerInternal.PermissionsToUseExternalResourcesPresentation(
		Properties.Type, Properties.Id, Properties.Type, Properties.Id, Permissions);
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function SecurityProfilePermissions()
	Return GetFromTempStorage(PermissionsAddress);
EndFunction

&AtServer
Procedure FillInCommands(SavedCommands = Undefined)
	
	Object.Commands.Sort("Presentation");
	
	ObjectPrintCommands = Undefined;
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm
		And Object.Purpose.Count() = 1
		And Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
		ObjectPrintCommands = ModulePrintManager.StandardObjectPrintCommands(Object.Purpose[0].RelatedObject);
	EndIf;
	
	For Each ItemCommand In Object.Commands Do
		If Object.Kind = KindAdditionalDataProcessor Or Object.Kind = KindAdditionalReport Then
			FoundItems = QuickAccess.FindRows(New Structure("CommandID", ItemCommand.Id));
			ItemCommand.QuickAccessPresentation = UsersQuickAccessPresentation(
				FoundItems.Count());
		EndIf;
		
		ItemCommand.ScheduledJobUsage = False;
		ItemCommand.ScheduledJobAllowed = False;
		
		If Object.Kind = KindAdditionalDataProcessor
			And (ItemCommand.StartupOption = Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall
			Or ItemCommand.StartupOption = Enums.AdditionalDataProcessorsCallMethods.SafeModeScenario) Then
			
			ItemCommand.ScheduledJobAllowed = True;
			
			GUIDScheduledJob = ItemCommand.GUIDScheduledJob;
			If SavedCommands <> Undefined Then
				FoundRow = SavedCommands.Find(ItemCommand.Id, "Id");
				If FoundRow <> Undefined Then
					GUIDScheduledJob = FoundRow.GUIDScheduledJob;
				EndIf;
			EndIf;
			
			If ValueIsFilled(GUIDScheduledJob) Then
				SetPrivilegedMode(True);
				ScheduledJob = ScheduledJobsServer.Job(GUIDScheduledJob);
				If ScheduledJob <> Undefined Then
					ItemCommand.GUIDScheduledJob = GUIDScheduledJob;
					ItemCommand.ScheduledJobPresentation = String(ScheduledJob.Schedule);
					ItemCommand.ScheduledJobUsage = ScheduledJob.Use;
					ItemCommand.ScheduledJobSchedule.Insert(0, ScheduledJob.Schedule);
				EndIf;
				SetPrivilegedMode(False);
			EndIf;
			If Not ValueIsFilled(ItemCommand.ScheduledJobPresentation) Then
				ItemCommand.ScheduledJobPresentation = NStr("vi = 'Chưa điền';
															|ru = 'Не заполнено';
															|en = 'Not filled'; fa = 'Not filled';
															|it = 'Non compilato';
															|pl = 'Nie wypełnione';
															|tr = 'Boş'");
			EndIf;
		ElsIf Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
			If Not IsBlankString(ItemCommand.CommandsToReplace) And ObjectPrintCommands <> Undefined Then
				CommandsToReplaceIDs = StrSplit(ItemCommand.CommandsToReplace, ",", False);
				CommandsToReplacePresentation = "";
				CommandsToReplaceCount = 0;
				Filter = New Structure("Id, SaveFormat, SkipPreview", Undefined, Undefined, False);
				For Each IDOfCommandToReplace In CommandsToReplaceIDs Do
					Filter.Id = TrimAll(IDOfCommandToReplace);
					ListOfCommandsToReplace = ObjectPrintCommands.FindRows(Filter);
					// If it is impossible to exactly determine a command to replace, replacement is not performed.
					If ListOfCommandsToReplace.Count() = 1 Then
						CommandsToReplacePresentation = CommandsToReplacePresentation + ?(IsBlankString(CommandsToReplacePresentation), "", ", ") + """" + ListOfCommandsToReplace[0].Presentation + """";
						CommandsToReplaceCount = CommandsToReplaceCount + 1;
					EndIf;
				EndDo;
				If CommandsToReplaceCount > 0 Then
					If CommandsToReplaceCount = 1 Then
						CommentTemplate = NStr("vi = 'Thay thế lệnh in chuẩn %1';
												|ru = 'Заменяет стандартную команду печати %1';
												|en = 'Replace standard print command %1'; fa = 'Replace standard print command %1';
												|it = 'Sostituisce il comando di stampa standard %1';
												|pl = 'Zamienia standardowe polecenie wydruku %1';
												|tr = 'Standart yazdırma komutu yerinde kullanılır %1'");
					Else
						CommentTemplate = NStr("vi = 'Thay thế lệnh in chuẩn: %1';
												|ru = 'Заменяет стандартные команды печати: %1';
												|en = 'Replace standard print commands: %1'; fa = 'Replace standard print commands: %1';
												|it = 'Sostituisce i comandi di stampa standard: %1';
												|pl = 'Zamienia standardowe polecenia wydruku: %1';
												|tr = 'Standart yazdırma komutu yerine kullanılır: %1'");
					EndIf;
					ItemCommand.Comment = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, CommandsToReplacePresentation);
				EndIf;
			EndIf;
		Else
			ItemCommand.ScheduledJobPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không áp dụng đối với lệnh có phương án khởi động ""%1""';
					|ru = 'Неприменимо для команд с вариантом запуска ""%1""';
					|en = 'Not applicable for commands with the ""%1"" startup option'; fa = 'Not applicable for commands with the ""%1"" startup option';
					|it = 'Non applicabile su comandi con variante d''avvio ""%1""';
					|pl = 'Nie dotyczy poleceń z wariantem uruchamiania ""%1""';
					|tr = 'Başlatma seçeneği ""%1"" olan komutlar için uygulanmaz'"),
				String(ItemCommand.StartupOption));
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure AdditionalReportOptionsFill()
	AdditionalReportOptions.Clear();
	
	Try
		ExternalObject = AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Object.Ref);
	Except
		ErrorText = NStr("vi = 'Không thể nhận danh sách phương án báo cáo do lỗi phát sinh khi kết nối báo cáo này:';
						|ru = 'Не удалось получить список вариантов отчета из-за ошибки, возникшей при подключении этого отчета:';
						|en = 'Cannot get the list of report options due to report attachment error:'; fa = 'Cannot get the list of report options due to report attachment error:';
						|it = 'Non è stato possibile ottenere l''elenco delle varianti del report a causa di un errore verificatosi durante l''attivazione del report:';
						|pl = 'Pozyskiwanie listy wariantów raportu nie powiodło się z powodu błędu, który zaistniał przy podłączeniu tego raportu:';
						|tr = 'Bu raporu bağlarken oluşan hata nedeniyle rapor seçeneklerinin bir listesi alınamıyor:'");
		MessageText = ErrorText + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Common.MessageToUser(MessageText);
		Return;
	EndTry;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		
		ReportMetadata = ExternalObject.Metadata();
		DCSchemaMetadata = ReportMetadata.MainDataCompositionSchema;// MetadataObject
		If DCSchemaMetadata <> Undefined Then
			DCSchema = ExternalObject.GetTemplate(DCSchemaMetadata.Name);
			For Each DCSettingsOption In DCSchema.SettingVariants Do
				VariantKey = DCSettingsOption.Name;
				OptionRef = ModuleReportsOptions.ReportVariant(Object.Ref, VariantKey);
				If OptionRef <> Undefined Then
					Variant = AdditionalReportOptions.Add();
					Variant.VariantKey = VariantKey;
					Variant.Description = DCSettingsOption.Presentation;
					Variant.Custom = False;
					Variant.PictureIndex = 5;
					Variant.Ref = OptionRef;
				EndIf;
			EndDo;
		Else
			VariantKey = "";
			OptionRef = ModuleReportsOptions.ReportVariant(Object.Ref, VariantKey);
			If OptionRef <> Undefined Then
				Variant = AdditionalReportOptions.Add();
				Variant.VariantKey = VariantKey;
				Variant.Description = ReportMetadata.Presentation();
				Variant.Custom = False;
				Variant.PictureIndex = 5;
				Variant.Ref = OptionRef;
			EndIf;
		EndIf;
	Else
		ModuleReportsOptions = Undefined;
	EndIf;
	
	If Object.UseOptionStorage Then
		Storage = SettingsStorages["ReportsVariantsStorage"];
		ObjectKey = Object.Ref;
		SettingsList = ModuleReportsOptions.ReportOptionsKeys(ObjectKey);
	Else
		Storage = ReportsVariantsStorage;
		ObjectKey = "ExternalReport." + Object.ObjectName;
		SettingsList = Storage.GetList(ObjectKey);
	EndIf;
	
	For Each ListItem In SettingsList Do
		Variant = AdditionalReportOptions.Add();
		Variant.VariantKey = ListItem.Value;
		Variant.Description = ListItem.Presentation;
		Variant.Custom = True;
		Variant.PictureIndex = 3;
		If ModuleReportsOptions <> Undefined Then
			Variant.Ref = ModuleReportsOptions.ReportVariant(Object.Ref, Variant.VariantKey);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Function SelectedRelatedObjects()
	Result = New ValueList;
	Result.LoadValues(Object.Purpose.Unload(, "RelatedObject").UnloadColumn("RelatedObject"));
	Return Result;
EndFunction

&AtClient
Procedure SetPrintCommandVisibilityCompletion(DialogResult, AdditionalParameters) Export
	If DialogResult <> "Continue" Then
		Return;
	EndIf;
	Write();
	OpenPrintSubmenuSettingsForm();
EndProcedure

&AtClient
Procedure OpenPrintSubmenuSettingsForm()
	ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
	ModulePrintManagerInternalClient.OpenPrintSubmenuSettingsForm(SelectedRelatedObjects());
EndProcedure

&AtServer
Function CommandsToDisable()
	Result = New ValueList;
	For Each Command In Object.Commands Do
		If Not IsBlankString(Command.CommandsToReplace) Then
			ItemsToReplaceList = StrSplit(Command.CommandsToReplace, ",", False);
			For Each CommandToReplace In ItemsToReplaceList Do
				Result.Add(CommandToReplace);
			EndDo;
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtServer
Function CommandsPageName()
	If Object.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.PrintForm Then
		Return NStr("vi = 'Lệnh in';
					|ru = 'Команды печати';
					|en = 'Form''s print commands.'; fa = 'فرمان‌های چاپ فرم.';
					|it = 'Comandi di stampa';
					|pl = 'Polecenia druku';
					|tr = 'Yazdırma komutları'");
	Else
		Return NStr("vi = 'Lệnh';
					|ru = 'Команды';
					|en = 'Commands'; fa = 'فرمان‌ها';
					|it = 'Comandi';
					|pl = 'Commands';
					|tr = 'Komutlar'");
	EndIf;
EndFunction

#EndRegion

#Region AdditionalAttributes

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillAdditionalAttributesInForm(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion