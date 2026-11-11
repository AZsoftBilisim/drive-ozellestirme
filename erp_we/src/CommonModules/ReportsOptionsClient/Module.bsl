///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens a form of the specified report. 
//
// Parameters:
//  OwnerForm - ClientApplicationForm
//                - Undefined - Form that opens the report.
//  Variant - CatalogRef.ReportsOptions
//          - CatalogRef.AdditionalReportsAndDataProcessors - Report option whose form to open. 
//            If the CatalogRef.AdditionalReportsAndDataProcessors type is passed, 
//            opens the additional report attached to the application. 
//  AdditionalParameters - Structure - For internal use only.
//
Procedure OpenReportForm(Val OwnerForm, Val Variant, Val AdditionalParameters = Undefined) Export
	Type = TypeOf(Variant);
	If Type = Type("Structure") Then
		OpeningParameters = Variant;
	ElsIf Type = Type("CatalogRef.ReportsOptions") 
		Or Type = AdditionalReportRefType() Then
		OpeningParameters = New Structure("Key", Variant);
		If AdditionalParameters <> Undefined Then
			CommonClientServer.SupplementStructure(OpeningParameters, AdditionalParameters, True);
		EndIf;
		OpenForm("Catalog.ReportsOptions.ObjectForm", OpeningParameters, Undefined, True);
		Return;
	Else
		OpeningParameters = New Structure("Ref, Report, ReportType, FullReportName, ReportName, VariantKey, MeasurementsKey");
		If TypeOf(OwnerForm) = Type("ClientApplicationForm") Then
			FillPropertyValues(OpeningParameters, OwnerForm);
		EndIf;
		FillPropertyValues(OpeningParameters, Variant);
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		CommonClientServer.SupplementStructure(OpeningParameters, AdditionalParameters, True);
	EndIf;
	
	ReportsOptionsClientServer.AddKeyToStructure(OpeningParameters, "RunMeasurements", False);
	
	OpeningParameters.ReportType = ReportsOptionsClientServer.ReportByStringType(OpeningParameters.ReportType, OpeningParameters.Report);
	If Not ValueIsFilled(OpeningParameters.ReportType) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa xác định kiểu báo cáo trong %1';
																			|ru = 'Не определен тип отчета в %1';
																			|en = 'Report type is not specified in %1'; fa = 'Report type is not specified in %1';
																			|it = 'Tipo del report non definito in %1';
																			|pl = 'Nie określono typu raportu w %1';
																			|tr = 'Rapor türü %1 belirlenmedi'"), "ReportsOptionsClient.OpenReportForm");
	EndIf;
	
	If OpeningParameters.ReportType = "BuiltIn" Or OpeningParameters.ReportType = "Extension" Then
		Kind = "Report";
		MeasurementsKey = CommonClientServer.StructureProperty(OpeningParameters, "MeasurementsKey");
		If ValueIsFilled(MeasurementsKey) Then
			ClientParameters = ClientParameters();
			If ClientParameters.RunMeasurements Then
				OpeningParameters.RunMeasurements = True;
				OpeningParameters.Insert("OperationName", MeasurementsKey + ".Opening");
			EndIf;
		EndIf;
	ElsIf OpeningParameters.ReportType = "Additional" Then
		Kind = "ExternalReport";
		If Not OpeningParameters.Property("Connected") Then
			ReportsOptionsServerCall.OnAttachReport(OpeningParameters);
		EndIf;
		If Not OpeningParameters.Connected Then
			Return;
		EndIf;
	Else
		ShowMessageBox(, NStr("vi = 'Có thể phương án báo cáo ngoài chỉ từ biểu mẫu báo cáo.';
								|ru = 'Вариант внешнего отчета можно открыть только из формы отчета.';
								|en = 'You can open external report options only from report forms.'; fa = 'You can open external report options only from report forms.';
								|it = 'La variante del report esterno può essere aperta solo dal modulo del rapporto.';
								|pl = 'Wariant raportu zewnętrznego można otworzyć tylko z formularza raportu.';
								|tr = 'Harici rapor seçeneği sadece rapor formundan açılabilir.'"));
		Return;
	EndIf;
	
	If Not ValueIsFilled(OpeningParameters.ReportName) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa xác định tên báo cáo trong %1';
																			|ru = 'Не определено имя отчета в %1';
																			|en = 'Report name is not specified in %1'; fa = 'Report name is not specified in %1';
																			|it = 'Nome del report non definito in %1';
																			|pl = 'Nie określono nazwy raportu w %1';
																			|tr = 'Rapor adı %1''de belirlenmedi'"), "ReportsOptionsClient.OpenReportForm");
	EndIf;
	
	FullReportName = CommonClientServer.StructureProperty(OpeningParameters, "FullReportName");
	
	If Not ValueIsFilled(FullReportName) Then 
		FullReportName = Kind + "." + OpeningParameters.ReportName;
	EndIf;
	
	UniqueKey = ReportsClientServer.UniqueKey(FullReportName, OpeningParameters.VariantKey);
	OpeningParameters.Insert("PrintParametersKey",        UniqueKey);
	OpeningParameters.Insert("WindowOptionsKey", UniqueKey);
	
	If OpeningParameters.RunMeasurements Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			OpeningParameters.OperationName,,
			False);
	EndIf;
	
	OpenForm(FullReportName + ".Form", OpeningParameters, Undefined, True);
	
	If OpeningParameters.RunMeasurements Then
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementID);
	EndIf;
EndProcedure

// Opens the report panel. Intended for being used from common command modules.
//
// Parameters:
//  SubsystemPath - String - Section name or a path to the subsystem for which the report panel is opened.
//                    Conforms to the following format: "[.NestedSubsystemName1][.NestedSubsystemName2][...]".
//                    Section must be described in ReportsOptionsOverridable.DefineSectionsWithReportsOptions.
//  CommandExecuteParameters - CommandExecuteParameters - Parameters of the common command handler.
//
Procedure ShowReportBar(SubsystemPath, CommandExecuteParameters) Export
	ParametersForm = New Structure("SubsystemPath, SearchInAllSections", SubsystemPath, True);
	
	WindowForm = ?(CommandExecuteParameters = Undefined, Undefined, CommandExecuteParameters.Window);
	RefForm = ?(CommandExecuteParameters = Undefined, Undefined, CommandExecuteParameters.URL);
	
	ClientParameters = ClientParameters();
	If ClientParameters.RunMeasurements Then
		ModulePerformanceMonitorClient = CommonClient.CommonModule("PerformanceMonitorClient");
		MeasurementID = ModulePerformanceMonitorClient.TimeMeasurement(
			"ReportPanel.Opening",,
			False);
		Comment = New Map;
		Comment.Insert("SubsystemPath", SubsystemPath);
		ModulePerformanceMonitorClient.SetMeasurementComment(MeasurementID, Comment);
	EndIf;
	
	OpenForm("CommonForm.ReportPanel", ParametersForm, , SubsystemPath, WindowForm, RefForm);
	
	If ClientParameters.RunMeasurements Then
		ModulePerformanceMonitorClient.StopTimeMeasurement(MeasurementID);
	EndIf;
EndProcedure

// Notifies opened report panels, list forms, and item forms about report option changes.
//
// Parameters:
//  VariantKey - String - If the report form is open, set in it the given report option.
//  Source - CatalogRef.ReportsOptions
//
Procedure UpdateOpenForms(Val VariantKey = "", Val Source = Undefined) Export
	
	FormUpdateParameters = New Structure("VariantKey");
	FormUpdateParameters.VariantKey = VariantKey;
	Notify(EventNameChangingOption(), FormUpdateParameters, Source);
	
EndProcedure

#EndRegion

#Region Internal

// See CommonClientOverridable.OnStart.
Procedure OnStart(Parameters) Export 
	
	If Not CollaborationSystem.CanUse() Then
		Return;
	EndIf;
	
	Handler = New CallbackDescription("ProcessMessageActions", ReportsOptionsClient,,
		"OnMessageActionHandlerError", ReportsOptionsClient);
	
	Try
		CollaborationSystem.AttachMessageActionHandler(Handler);
	Except
		ErrorInfo = ErrorInfo();
		EventLogClient.AddMessageForEventLog(
			NStr("vi = 'Phương án báo cáo.Lỗi kết nối hàm sự kiện thao tác thông báo';
				|ru = 'Варианты отчетов.Ошибка подключения обработчика действия сообщения';
				|en = 'Report options.An error occurred when attaching a message action handler'; fa = 'Report options.An error occurred when attaching a message action handler';
				|it = 'Varianti di report. Errore di collegamento del gestore dell''azione del messaggio';
				|pl = 'Warianty raportów.Błąd podłączenia procesora dannych czynności wiadomości';
				|tr = 'Rapor seçenekleri.Mesaj etkinlik işleyicisi bağlanırken hata oluştu'",
				CommonClient.DefaultLanguageCode()),
			"Error",
			ErrorProcessing.DetailErrorDescription(ErrorInfo));
	EndTry;
	
EndProcedure

// Opens a report option card that contains placement settings.
//
// Parameters:
//  Variant - CatalogRef.ReportsOptions - Report option reference.
//
Procedure ShowReportSettings(Variant) Export
	FormParameters = New Structure;
	FormParameters.Insert("Key", Variant);
	OpenForm("Catalog.ReportsOptions.Form.ItemForm", FormParameters);
EndProcedure

// Opens a dialog where you can set up the location of multiple report options in sections.
//
// Parameters:
//   Variants - Array - Report options to move (CatalogRef.ReportsOptions).
//   Owner - ClientApplicationForm - For locking the owner's window.
//
Procedure OpenOptionArrangeInSectionsDialog(Variants, Owner = Undefined) Export
	
	If TypeOf(Variants) <> Type("Array") Or Variants.Count() < 1 Then
		ShowMessageBox(, NStr("vi = 'Hãy chọn phương án báo cáo để sắp đặt vào các phân hệ.';
								|ru = 'Выберите варианты отчетов для размещения в разделах.';
								|en = 'Select report options for placement in sections.'; fa = 'Select report options for placement in sections.';
								|it = 'Selezionare le varianti di report per lo spostamento nelle sezioni.';
								|pl = 'Wybierz warianty raportów w celu umieszczenia w rozdziałach.';
								|tr = 'Bölümlerde konumlandırılacak rapor seçeneklerini seçin.'"));
		Return;
	EndIf;
	
	OpeningParameters = New Structure("Variants", Variants);
	OpenForm("Catalog.ReportsOptions.Form.PlacementInSections", OpeningParameters, Owner);
	
EndProcedure

#EndRegion

#Region Private

Procedure OnMessageActionHandlerError(ErrorInfo, StandardProcessing, Context) Export 
	
	StandardProcessing = False;
	
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Phương án báo cáo.Lỗi xử lý thao tác thông báo';
			|ru = 'Варианты отчетов.Ошибка обработки действия сообщения';
			|en = 'Report options.An error occurred when processing a message action'; fa = 'Report options.An error occurred when processing a message action';
			|it = 'Versioni dei report. Errore di gestione dell''azione del messaggio';
			|pl = 'Warianty raportów.Błąd przetwarzania czynności wiadomości';
			|tr = 'Rapor seçenekleri.Mesaj etkinlik işleme hatası'",
			CommonClient.DefaultLanguageCode()),
		"Error",
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndProcedure

Procedure ProcessMessageActions(Message, Action, AdditionalParameters) Export 
	
	If Action = ReportsOptionsClientServer.ApplyPassedSettingsActionName() Then 
		Notify(Action, Message.Data);
	EndIf;
	
EndProcedure

// The procedure handles an event of the SubsystemsTree attribute in editing forms.
//
// Parameters:
//   Form - ClientApplicationForm - Subsystem tree edit form, where::
//       * Items - FormAllItems - See Syntax Assistant
//   Item - FormField - Field that indicates usage.
//
Procedure SubsystemsTreeUseOnChange(Form, Item) Export
	TreeRow = Form.Items.SubsystemsTree.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	// Skip the root row
	If TreeRow.Priority = "" Then
		TreeRow.Use = 0;
		Return;
	EndIf;
	
	If TreeRow.Use = 2 Then
		TreeRow.Use = 0;
	EndIf;
	
	TreeRow.Modified = True;
EndProcedure

// The procedure handles an event of the SubsystemsTree attribute in editing forms.
//
// Parameters:
//   Form - ClientApplicationForm - Subsystem tree edit form, where::
//     * Items - FormAllItems - Collection of form items, where::
//         ** SubsystemsTree - FormTable - Hierarchical collection of subsystems where the report is displayed, where::
//              *** CurrentData - FormDataTreeItem - Data in the current subsystem tree row, where::
//                    **** Importance - String - The importance level. Valid values are: "", "Important", "See also".
//                    **** Priority - String - Code counter.
//                    **** Use - Number - Flag indicating whether the subsystem contains the report.
//   Item - FormField - Field to edit the importance flag.
//
Procedure SubsystemsTreeImportanceOnChange(Form, Item) Export
	
	SubsystemsTree = Form.Items.SubsystemsTree;
	
	TreeRow = SubsystemsTree.CurrentData;
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	// Skip the root row
	If TreeRow.Priority = "" Then
		TreeRow.Importance = "";
		Return;
	EndIf;
	
	If TreeRow.Importance <> "" Then
		TreeRow.Use = 1;
	EndIf;
	
	TreeRow.Modified = True;
EndProcedure

// See ReportsOptions.ClientParameters
Function ClientParameters()
	ClientParameters = New Structure;
	ClientParameters.Insert("RunMeasurements",
		CommonClient.SubsystemExists("StandardSubsystems.PerformanceMonitor"));
	
	Return ClientParameters;
EndFunction

Function EventNameChangingOption() Export
	Return "Change_ReportOptions";
EndFunction

Function EventNameChangingCommonSettings() Export
	Return ReportsOptionsClientServer.FullSubsystemName() + ".CommonSettingsEdit";
EndFunction

Function AdditionalReportRefType()
	If CommonClient.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
		Return Type("CatalogRef.AdditionalReportsAndDataProcessors");
	EndIf;
	
	Return Undefined;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Handlers of the report option user list

#Region ReportOptionUsersPickingParameters

// Opens a form to select users or (external) user groups.
//
// Parameters:
//   Form - ClientApplicationForm - Subsystem tree edit form, where::
//       * Items - FormAllItems - Collection of form items.
//   ExternalUsersGroupsPickup - Boolean - Flag indicating whether external user groups are picked.
//
Procedure PickReportOptionUsers(Form, PickUsersGroups = False, ExternalUsersGroupsPickup = False) Export 
	
	PickingParameters = ReportOptionUsersPickingParameters(
		Form, PickUsersGroups, ExternalUsersGroupsPickup);
	
	If ExternalUsersGroupsPickup Then 
		
		PickingFormName = "Catalog.ExternalUsersGroups.ChoiceForm";
		
	Else
		
		PickingFormName = "Catalog.Users.ChoiceForm";
		
	EndIf;
	
	OpenForm(PickingFormName, PickingParameters, Form.Items.OptionUsers);
	
EndProcedure

// The constructor of parameters to pick report option users.
//
// Parameters:
//   Form - ClientApplicationForm - Subsystem tree edit form, where::
//       * Items - FormAllItems - Collection of form items.
//   ExternalUsersGroupsPickup - Boolean - Flag indicating whether external user groups are picked.
//
// Returns:
//   Structure - Choice form open parameters, where::
//       * ChoiceMode - Boolean - Choice mode flag. See "Catalog extension" in Syntax Assistant. 
//       * CurrentRow - CatalogRef.Users
//                       - CatalogRef.UserGroups
//                       - CatalogRef.ExternalUsersGroups
//                       - Undefined - Current user or a group of internal or external users.
//       * CloseOnChoice - Boolean - Flag indicating whether the selection form must be closed. See "Catalog extension" in Syntax Assistant.
//       * MultipleChoice - Boolean - Flag indicating whether two or more rows are selected.
//       * AdvancedPick - Boolean - Flag indicating whether extended picking parameters are used.
//       * PickFormHeader - String - Title of the user selection form, considering the context.
//       * SelectedUsers - ValueList - Collection of selected users or (external) user groups.
//
Function ReportOptionUsersPickingParameters(Form, PickUsersGroups, ExternalUsersGroupsPickup = False)
	
	CurrentData = Form.Items.OptionUsers.CurrentData;
	SelectedUsers = SelectedOptionUsers(Form.OptionUsers, ExternalUsersGroupsPickup);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("CurrentRow", ?(CurrentData = Undefined, Undefined, CurrentData.Value));
	PickingParameters.Insert("CloseOnChoice", False);
	PickingParameters.Insert("MultipleChoice", True);
	PickingParameters.Insert("AdvancedPick", True);
	PickingParameters.Insert("PickFormHeader", NStr("vi = 'Lựa chọn người dùng biến thể báo cáo';
													|ru = 'Подбор пользователей варианта отчета';
													|en = 'Pick report option users'; fa = 'Pick report option users';
													|it = 'Selezione di utenti della versione del report';
													|pl = 'Wybór użytkowników wariantu raportu';
													|tr = 'Rapor seçeneğinin kullanıcı seçimi'"));
	PickingParameters.Insert("UsersGroupsSelection", PickUsersGroups);
	PickingParameters.Insert("SelectedUsers", SelectedUsers);
	
	Return PickingParameters;
	
EndFunction

Function SelectedOptionUsers(OptionUsers, ExternalUsersGroupsPickup)
	
	SelectedUsersTypes = New TypeDescription(
		"CatalogRef.UserGroups, CatalogRef.Users");
	
	If ExternalUsersGroupsPickup Then 
		SelectedUsersTypes = New TypeDescription("CatalogRef.ExternalUsersGroups");
	EndIf;
	
	SelectedUsers = New Array;
	
	For Each ListItem In OptionUsers Do 
		
		If ListItem.Check
			And SelectedUsersTypes.ContainsType(TypeOf(ListItem.Value)) Then 
			
			SelectedUsers.Add(ListItem.Value);
			
		EndIf;
		
	EndDo;
	
	If SelectedUsers.Count() = 1
		And SelectedUsers[0] = Undefined Then 
		
		If ExternalUsersGroupsPickup Then 
			SelectedUsers[0] = PredefinedValue("Catalog.ExternalUsersGroups.AllExternalUsers");
		Else
			SelectedUsers[0] = PredefinedValue("Catalog.UserGroups.AllUsers");
		EndIf;
		
	EndIf;
	
	Return SelectedUsers;
	
EndFunction

#EndRegion

#Region ReportOptionUsersChoiceProcessing

Procedure ReportOptionUsersChoiceProcessing1(Form, SelectedValues, StandardProcessing) Export 
	
	If TypeOf(SelectedValues) <> Type("Array") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	OptionUsers = Form.OptionUsers;
	
	If Not ValueIsFilled(SelectedValues) Then
		OptionUsers.Clear();
		Return;
	EndIf;
	
	CommonUserGroup = PredefinedValue("Catalog.UserGroups.AllUsers");
	CommonGroupExternalUsers = PredefinedValue("Catalog.ExternalUsersGroups.AllExternalUsers");
	
	If TypeOf(SelectedValues[0]) = Type("CatalogRef.ExternalUsersGroups") Then 
		
		PrepareListToAddExternalReportOptionUsers(
			OptionUsers, SelectedValues, CommonGroupExternalUsers);
		
	Else
		
		PrepareListToAddReportOptionUsers(
			OptionUsers, SelectedValues, CommonUserGroup);
		
	EndIf;
	
	For Each Value In SelectedValues Do 
		
		If OptionUsers.FindByValue(Value) = Undefined Then 
			OptionUsers.Add(Value,, True, ReportOptionUserPicture(Value));
		EndIf;
		
	EndDo;
	
	If OptionUsers.FindByValue(CommonUserGroup) <> Undefined
		And OptionUsers.FindByValue(CommonGroupExternalUsers) <> Undefined Then 
		
		OptionUsers.Clear();
		OptionUsers.Add(,, True, ReportOptionUserPicture());
		
	EndIf;
	
	RegisterReportOptionUsers(Form);
	
EndProcedure

Procedure PrepareListToAddReportOptionUsers(OptionUsers, SelectedValues, CommonUserGroup)
	
	If OptionUsers.FindByValue(Undefined) <> Undefined Then 
		
		OptionUsers.Clear();
		
	Else
		
		UsersTypes = New TypeDescription("CatalogRef.UserGroups, CatalogRef.Users");
		DeleteReportOptionUsersOfSpecifiedTypes(OptionUsers, UsersTypes);
		
	EndIf;
	
	If SelectedValues.Find(CommonUserGroup) = Undefined Then 
		Return;
	EndIf;
	
	SelectedValues.Clear();
	SelectedValues.Add(CommonUserGroup);
	
EndProcedure

Procedure PrepareListToAddExternalReportOptionUsers(OptionUsers, SelectedValues, CommonUserGroup)
	
	If OptionUsers.FindByValue(CommonUserGroup) <> Undefined
		Or OptionUsers.FindByValue(Undefined) <> Undefined Then 
		
		SelectedValues.Clear();
		Return;
		
	EndIf;
	
	If SelectedValues.Find(CommonUserGroup) = Undefined Then 
		Return;
	EndIf;
	
	UsersTypes = New TypeDescription("CatalogRef.ExternalUsersGroups");
	DeleteReportOptionUsersOfSpecifiedTypes(OptionUsers, UsersTypes);
	
	SelectedValues.Clear();
	SelectedValues.Add(CommonUserGroup);
	
EndProcedure

Procedure DeleteReportOptionUsersOfSpecifiedTypes(OptionUsers, UsersTypes)
	
	ElementIndex = OptionUsers.Count() - 1;
	
	While ElementIndex >= 0 Do 
		
		ListItem = OptionUsers[ElementIndex];
		
		If UsersTypes.ContainsType(TypeOf(ListItem.Value)) Then 
			
			OptionUsers.Delete(ListItem);
			
		EndIf;
		
		ElementIndex = ElementIndex - 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ReportOptionUsersOther

Function ReportOptionUserPicture(User = Undefined)
	
	If TypeOf(User) = Type("CatalogRef.Users") Then 
		
		Return PictureLib.UserState02;
		
	ElsIf TypeOf(User) = Type("CatalogRef.ExternalUsers") Then 
		
		Return PictureLib.UserState08;
		
	ElsIf TypeOf(User) = Type("CatalogRef.ExternalUsersGroups") Then 
		
		Return PictureLib.UserState10;
		
	EndIf;
	
	Return PictureLib.UserState04;
	
EndFunction

Procedure CheckTheUsersOfTheReportOption(Form) Export 
	
	Object = Form.Object;
	
	If Not Object.AuthorOnly Then 
		Return;
	EndIf;
	
	OptionUsers = Form.OptionUsers;
	OptionUsers.Clear();
	OptionUsers.Add(
		Object.Author,
		"[IsReportOptionAuthor]", True,
		ReportOptionUserPicture(Object.Author));
	
EndProcedure

// The procedure handles an event of the SubsystemsTree attribute in editing forms.
//
// Parameters:
//   Form - ClientApplicationForm - Subsystem tree edit form, where::
//       * Items - FormAllItems - Collection of form items, where::
//             ** OptionUsers - FormTable - List of report option users.
//   ResetUsageFlag - Boolean - Flag indicating that usage must be disabled.
//
Procedure RegisterReportOptionUsers(Form, ResetUsageFlag = True) Export 
	
	Items = Form.Items;
	Object = Form.Object;
	
	ClientParameters = StandardSubsystemsClient.ClientRunParameters();
	InactiveValuesColor = ClientParameters.StyleItems.InaccessibleCellTextColor;
	OptionAuthor = Object.Author;
	If TypeOf(InactiveValuesColor) = Type("ValueStorage") Then
		InactiveValuesColor = InactiveValuesColor.Get();
	EndIf;
	
	MarkedItemCount = 0;
	For Each TableRow In Form.OptionUsers Do 
		If TableRow.Value = OptionAuthor And OptionAuthor <> Undefined Then
			AuthorFlag = "[IsReportOptionAuthor]";
		Else
			AuthorFlag = "";
			MarkedItemCount = MarkedItemCount + Boolean(TableRow.Check);
		EndIf;
		If TableRow.Presentation <> AuthorFlag Then
			TableRow.Presentation = AuthorFlag;
		EndIf;
	EndDo;
	
	If ResetUsageFlag Then 
		If MarkedItemCount > 0 Then
			Object.AuthorOnly = False;
		EndIf;
		Form.Available = ?(Object.AuthorOnly, "ToAuthor", "ToAll");
	EndIf;
	
	Items.OptionUsers.TextColor = ?(Object.AuthorOnly, InactiveValuesColor, New Color);
	
EndProcedure

#EndRegion

#Region ReportOptionUpdateFromFile

Function NameOfTheEventForUpdatingReportVariantsFromFiles() Export  
	
	Return "UpdateReportOptionsFromFiles";
	
EndFunction

// Parameters:
//  ReportOptionProperties - See BaseReportOptionProperties
//  FormIdentifier - UUID
// 
Procedure UpdateReportOptionFromFiles(ReportOptionProperties, FormIdentifier) Export

	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("vi = 'Thông tin về báo cáo (*.zip)|*.zip';
											|ru = 'Сведения об отчете (*.zip)|*.zip';
											|en = 'Report information (*.zip)|*.zip'; fa = 'Report information (*.zip)|*.zip';
											|it = 'Сведения об отчете (*.zip)|*.zip';
											|pl = 'Report information (*.zip)|*.zip';
											|tr = 'Rapor hakkında bilgi kaydetme (*.zip)|*.zip'");
	ImportParameters.FormIdentifier = FormIdentifier;
	
	Handler = New CallbackDescription("UpdateReportOptionsFromFilesCompletion", ThisObject, 
		ReportOptionProperties);
	FileSystemClient.ImportFiles(Handler, ImportParameters);

EndProcedure

// Parameters:
//   FilesDetails - Array of Structure:
//     * Location - String
//     * Name - String
//   BaseReportOptionProperties - See BaseReportOptionProperties
//
Procedure UpdateReportOptionsFromFilesCompletion(FilesDetails, BaseReportOptionProperties) Export 
	
	If TypeOf(FilesDetails) <> Type("Array") Then
		Return;
	EndIf;
	
	If FilesDetails.Count() = 1 Then 
		UpdateReportOptionFromFile(FilesDetails[0], BaseReportOptionProperties);
		Return;
	EndIf;
	
	ReportsOptionsProperties = ReportsOptionsServerCall.UpdateReportOptionsFromFiles(FilesDetails);
	NotificationText2 = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã kết nhập từ tệp: %1';
			|ru = 'Загружены из файла: %1';
			|en = 'Imported from the file: %1'; fa = 'Imported from the file: %1';
			|it = 'Загружены из файла: %1';
			|pl = 'Imported from the file: %1';
			|tr = 'Şu dosyadan indirildi: %1'"), ReportsOptionsProperties.Count());
	
	ShowUserNotification(NStr("vi = 'Đã cập nhật báo cáo';
								|ru = 'Отчеты обновлены';
								|en = 'The reports are updated'; fa = 'The reports are updated';
								|it = 'Отчеты обновлены';
								|pl = 'The reports are updated';
								|tr = 'Raporlar güncellendi'"),, NotificationText2);
	Notify(NameOfTheEventForUpdatingReportVariantsFromFiles(), ReportsOptionsProperties);
	
EndProcedure

// Parameters:
//   FileDetails - Structure:
//     * Location - String
//     * Name - String
//   BaseReportOptionProperties - See BaseReportOptionProperties
//
Procedure UpdateReportOptionFromFile(FileDetails, BaseReportOptionProperties) 
	
	If FileDetails = Undefined Then
		Return;
	EndIf;
	
	If BaseReportOptionProperties = Undefined Then 
		BaseReportOptionProperties = BaseReportOptionProperties();
	EndIf;
	
	ReportOptionProperties = ReportsOptionsServerCall.UpdateReportOptionFromFile(FileDetails, 
		BaseReportOptionProperties.Ref);
	If BaseReportOptionProperties.ReportName = ReportOptionProperties.ReportName Then 
		
		UpdateOpenForms(ReportOptionProperties.VariantKey);
		ShowUserNotification(NStr("vi = 'Đã cập nhật báo cáo từ tệp';
									|ru = 'Отчет обновлен из файла';
									|en = 'The report is updated from the file'; fa = 'The report is updated from the file';
									|it = 'Отчет обновлен из файла';
									|pl = 'The report is updated from the file';
									|tr = 'Rapor dosyadan güncellendi'"), 
			GetURL(ReportOptionProperties.Ref),
			ReportOptionProperties.VariantPresentation);
		
	ElsIf BaseReportOptionProperties.VariantPresentation = ReportOptionProperties.VariantPresentation Then 
		
		OpenReportForm(Undefined, ReportOptionProperties.Ref);
		ShowUserNotification(NStr("vi = 'Đã cập nhật báo cáo từ tệp';
									|ru = 'Отчет обновлен из файла';
									|en = 'The report is updated from the file'; fa = 'The report is updated from the file';
									|it = 'Отчет обновлен из файла';
									|pl = 'The report is updated from the file';
									|tr = 'Rapor dosyadan güncellendi'"), 
			GetURL(ReportOptionProperties.Ref),
			ReportOptionProperties.VariantPresentation);
		
	Else
		
		Handler = New CallbackDescription(
			"OpenSelectedReportOptionForm", ThisObject, ReportOptionProperties.Ref);
		
		QuestionTextTemplate = NStr("vi = 'Chọn cài đặt phương án báo cáo ""%1"",
			| không khớp với ""%2"".
			|Không thể ghi đè cài đặt phương án báo cáo đã chọn.
			|
			|Tạo phương án mới của báo cáo (hoặc cập nhật cái hiện có nếu có)?';
			|ru = 'Выбраны настройки варианта отчета ""%1"",
			|которые не совпадают с ""%2"".
			|Замена настроек выбранного варианта отчета невозможна.
			|
			|Создать новый вариант отчета (или обновить существующий при наличии)?';
			|en = 'The selected settings of the ""%1"" report option
			|do not match the settings of ""%2"".
			|Cannot replace the settings of the selected report option.
			|
			|Do you want to create a new report option (or update the report option if it exists)?'; fa = 'The selected settings of the ""%1"" report option
			|do not match the settings of ""%2"".
			|Cannot replace the settings of the selected report option.
			|
			|Do you want to create a new report option (or update the report option if it exists)?';
			|it = 'Sono state selezionate le impostazioni della versione del report ""%1"". 
			| che non corrispondono a ""%2"".
			| Impossibile sostituire le impostazioni della versione selezionata del report.
			|
			|Creare una nuova versione del report (o aggiornare l''esistente se disponibile)?';
			|pl = 'Wybrano ustawienia wariantu raportu ""%1"",
			|które nie zbiegają się z ""%2"".
			|Zmiana ustawień wybranego wariantu raportu jest niemożliwe.
			|
			|Utworzyć nowy wariant raportu (lub aktualizować istniejący jeżeli on jest)?';
			|tr = '""%2"" ile uyum sağlamayan 
			| ""%1"" rapor seçeneğinin ayarları seçildi.
			|Seçilen rapor seçeneğinin ayarları değiştirilemez.
			|
			|Raporun yeni seçeneği oluşturulsun mu (yoksa mevcut ise geçerli olan yenilensin mi)?'");
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			QuestionTextTemplate,
			ReportOptionProperties.VariantPresentation,
			BaseReportOptionProperties.VariantPresentation);
		
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.YesNo,, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

// Parameters:
//   Response - DialogReturnCode
//   ReportVariant - CatalogRef.ReportsOptions
//
Procedure OpenSelectedReportOptionForm(Response, ReportVariant) Export 
	
	If Response = DialogReturnCode.Yes Then 
		OpenReportForm(Undefined, ReportVariant);
	EndIf;
	
EndProcedure

// Returns:
//   Structure:
//     * Ref - CatalogRef.ReportsOptions
//     * ReportName - String
//     * VariantPresentation - String
//
Function BaseReportOptionProperties() Export
	
	Return New Structure("Ref, ReportName, VariantPresentation");
	
EndFunction

#EndRegion

#Region UserSettingsExchange

// Opens a form to select users or user groups.
//
// Parameters:
//  SettingsDescription - Structure - Opening parameters of the choice form for selecting users or user groups, where::
//      * Settings - DataCompositionUserSettings - Settings that are exchanged.
//      * ReportVariant - CatalogRef.ReportsOptions - Reference to a report option property storage.
//      * ObjectKey - String - Settings storage dimension.
//      * SettingsKey - String - Dimension - User settings ID.
//      * Presentation - String - User settings description.
//      * VariantModified - Boolean - Flag indicating whether a report option was modified.
//
Procedure ShareUserSettings(SettingsDescription) Export 
	
	If SettingsDescription.Settings.Items.Count() = 0 Then 
		
		CommonClient.MessageToUser(NStr("vi = 'Cài đặt (do người dùng xác định) không được đặt.';
										|ru = 'Настройки (пользовательские) не установлены.';
										|en = 'The user settings are not specified.'; fa = 'The user settings are not specified.';
										|it = 'Impostazioni (personalizzate) non presenti.';
										|pl = 'Ustawienia (użytkownicze) nie są ustawione.';
										|tr = 'Ayarlar (kullanıcı) belirlenmedi.'"));
		Return;
		
	EndIf;
	
	PickingParameters = New Structure;
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("CloseOnChoice", False);
	PickingParameters.Insert("MultipleChoice", True);
	PickingParameters.Insert("AdvancedPick", True);
	PickingParameters.Insert("HideUsersWithoutMatchingIBUsers", True);
	PickingParameters.Insert("SelectedUsers", New Array);
	PickingParameters.Insert("PickFormHeader", NStr("vi = 'Chia sẻ tùy chỉnh báo cáo với người sử dụng';
													|ru = 'Поделиться настройками отчета с пользователями';
													|en = 'Share report settings with users'; fa = 'Share report settings with users';
													|it = 'Condividere le impostazioni del report con gli utenti';
													|pl = 'Udostępnij ustawienia raportu użytkownikom';
													|tr = 'Rapor ayarları kullanıcılar ile paylaşılsın'"));
	PickingParameters.Insert("PickingCompletionButtonTitle", NStr("vi = 'Chia sẻ';
																	|ru = 'Поделиться';
																	|en = 'Share'; fa = 'سهم';
																	|it = 'Condividi';
																	|pl = 'Share';
																	|tr = 'Paylaş'"));
	
	Handler = New CallbackDescription(
		"ShareUserSettingsAfterUsersChoice", ReportsOptionsClient, SettingsDescription);
	
	OpenForm("Catalog.Users.ChoiceForm", PickingParameters,,,,, Handler);
	
EndProcedure

Procedure ShareUserSettingsAfterUsersChoice(SelectedUsers, SettingsDescription) Export 
	
	If SelectedUsers = Undefined
		Or SelectedUsers.Count() = 0 Then 
		
		Return;
	EndIf;
	
	ReportsOptionsServerCall.ShareUserSettings(SelectedUsers, SettingsDescription);
	
	Warning = CommonClientServer.StructureProperty(SettingsDescription, "Warning");
	
	If ValueIsFilled(Warning) Then 
		
		ShowMessageBox(, Warning);
		Return;
		
	EndIf;
	
	Explanation = CommonClientServer.StructureProperty(SettingsDescription, "Explanation", "");
	ShowUserNotification(NStr("vi = 'Cài đặt được chuyển';
								|ru = 'Настройки переданы';
								|en = 'The settings are shared'; fa = 'The settings are shared';
								|it = 'Impostazioni condivise';
								|pl = 'Przekazano ustawienia';
								|tr = 'Ayarlar aktarıldı'"),, Explanation);
	
EndProcedure

#EndRegion

#EndRegion
