///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Not AccessRight("Edit", Metadata.Catalogs.AddIns) Then
		Items.BulkAdd.Visible = False;
		Items.FormUpdateFromFile.Visible = False;
		Items.FormSaveAs.Visible = False;
		Items.UpdateFromWebsite.Visible = False;
		Items.ListContextMenuUpdateFromFile.Visible = False;
		Items.ListContextMenuSaveAs.Visible = False;
	Else
		Items.BulkAdd.Visible = Common.SeparatedDataUsageAvailable();
	EndIf;
	
	If Not AddInsInternal.CanImportFromPortal() Then
		Items.AddFromService.Visible = False;
		Items.ShouldUpdateFromWebsite.Visible = False;
		Items.UpdateFromWebsite.Visible = False;
	Else
		Items.AddFromService.Visible = AddInsInternal.CanImportFromPortalInteractively();
	EndIf;
	
	If Parameters.UseFilter <> Undefined Then
		UseFilter = Parameters.UseFilter;
		SetFilter();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.UseFilter <> Undefined Then
		UseFilter = Parameters.UseFilter;
	EndIf;
	
	SetFilter();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Items.AddFromService.Visible Then
		ModuleGetAddInsClient = CommonClient.CommonModule("GetAddInsClient");
		If EventName = ModuleGetAddInsClient.ImportNotificationEventName() Then
			Items.List.Refresh();
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFilterOnChange(Item)
	
	SetFilter();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then 
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateFromThePortal(Command)
	
	ReferencesArrray = Items.List.SelectedRows;
	
	If ReferencesArrray.Count() = 0 Then 
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AfterUpdateAddInFromPortal", ThisObject);
	AddInsInternalClient.UpdateAddInsFromPortal(Notification, ReferencesArrray);
	
EndProcedure

&AtClient
Procedure UpdateFromFile(Command)
	
	RowData = Items.List.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RowData.Ref);
	FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
	
	OpenForm("Catalog.AddIns.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	ReferencesArrray = Items.List.SelectedRows;
	
	If ReferencesArrray.Count() = 0 Then 
		Return;
	EndIf;
	
	AddInsInternalClient.SaveAddInToFile(ReferencesArrray);
	
EndProcedure

&AtClient
Procedure AddFromDirectory(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("AddAddInsFromDirectoryAfterExtensionsAttached", ThisObject);
		
	SuggestionText =  NStr("vi = 'Để kết nhập các cấu phần ngoài từ thư mục, cần có phần mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для загрузки внешних компонент из каталога требуется расширение для работы с 1С:Предприятием.';
							|en = 'To import add-ins from the directory, install 1C:Enterprise Extension.'; fa = 'To import add-ins from the directory, install 1C:Enterprise Extension.';
							|it = 'Для загрузки внешних компонент из каталога требуется расширение для работы с 1С:Предприятием.';
							|pl = 'To import add-ins from the directory, install 1C:Enterprise Extension.';
							|tr = 'Dizinden harici bileşenlerin yüklenmesi için 1C:Enterprise ile çalışacak uzantı gerekmektedir.'");
	FileSystemClient.Attach1CEnterpriseExtension(Notification, SuggestionText, False);
		
EndProcedure

&AtClient
Procedure AddFromService(Command)
	
	ModuleGetAddInsClient = CommonClient.CommonModule("GetAddInsClient");
	ModuleGetAddInsClient.UpdateAddIns();

EndProcedure

&AtClient
Procedure DeleteUnusedItems(Command)
	
	DeleteUnusedAddIns();
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure AddFromFiles(Command)
	
	ClearMessages();
	
	Notification = New CallbackDescription("AddAddInsAfterFilesPut",
		ThisObject);
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn (các) tệp cấu phần';
										|ru = 'Выберите файл(ы) компонент';
										|en = 'Select add-in files'; fa = 'Select add-in files';
										|it = 'Выберите файл(ы) компонент';
										|pl = 'Select add-in files';
										|tr = 'Bileşen dosya(lar)ını seçin'");
	ImportParameters.Dialog.Filter = NStr("vi = 'Tệp nén (*.zip) | *.zip';
											|ru = 'Архив (*.zip)|*.zip';
											|en = 'Archive (*.zip)|*.zip'; fa = 'Archive (*.zip)|*.zip';
											|it = 'Archivio (*.zip)|*.zip';
											|pl = 'Archiwum (*.zip)|*.zip';
											|tr = 'Arşiv (*.zip)|*.zip'") + "|"
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	
	ImportParameters.Dialog.Multiselect = True;
	Items.Pages_Group.CurrentPage = Items.WaitPage;
	FileSystemClient.ImportFiles(Notification, ImportParameters);
	
EndProcedure

#EndRegion

#Region Private

// Continuation of the procedure to add a catalog.

&AtClient
Procedure AddAddInsFromDirectoryAfterExtensionsAttached(Result, CreationParameters) Export
	
	If Result <> True Then
		Return;
	EndIf;
		
	Notification = New CallbackDescription("AddAddInsAfterDirectorySelected", ThisObject);
	Items.Pages_Group.CurrentPage = Items.WaitPage;
	FileSystemClient.SelectDirectory(Notification, NStr("vi = 'Hãy chọn thư mục có tệp cấu phần';
														|ru = 'Выберите каталог с файлами компонент';
														|en = 'Select a directory with add-in files'; fa = 'Select a directory with add-in files';
														|it = 'Выберите каталог с файлами компонент';
														|pl = 'Select a directory with add-in files';
														|tr = 'Bileşen dosyalarının bulunduğu dizini seçin'"));
	
EndProcedure

// Continuation of the procedure to add a catalog.

&AtClient
Async Procedure AddAddInsAfterDirectorySelected(SelectedDirectory, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedDirectory) Then
		Items.Pages_Group.CurrentPage = Items.List_Page;
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AddAddInsAfterFilesPut",
		ThisObject);
	
	DetailsOfFilesToTransfer = New Array;
	
	Files = Await FindFilesAsync(SelectedDirectory,"*.zip", True);

	For Each CurrentFile In Files Do
		If Await CurrentFile.IsDirectoryAsync() Then
			Continue;
		EndIf;
		TransferableFileDescription = New TransferableFileDescription(CurrentFile.FullName);
		DetailsOfFilesToTransfer.Add(TransferableFileDescription);
	EndDo;
	
	If DetailsOfFilesToTransfer.Count() = 0 Then
		Raise NStr("vi = 'Thư mục đã chọn không chứa tệp cấu phần.';
					|ru = 'Указанный каталог не содержит файлов компонент.';
					|en = 'The specified directory does not contain any add-in files.'; fa = 'The specified directory does not contain any add-in files.';
					|it = 'Указанный каталог не содержит файлов компонент.';
					|pl = 'The specified directory does not contain any add-in files.';
					|tr = 'Belirtilen dizin herhangi bir bileşen dosyası içermemektedir.'");
	EndIf;
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Interactively = False;
	FileSystemClient.ImportFiles(Notification, ImportParameters, DetailsOfFilesToTransfer);
		
EndProcedure

&AtClient
Procedure DownloadAddInsAfterSafetyWarning(Response, PlacedFiles) Export
	
	If Response <> "Continue" Then
		Items.Pages_Group.CurrentPage = Items.List_Page;
		Return;
	EndIf;
	
	If PlacedFiles.Count() = 1 Then
		Items.Pages_Group.CurrentPage = Items.List_Page;
		If IsFileOfService(PlacedFiles[0].Location) Then
			ModuleGetAddInsClient = CommonClient.CommonModule("GetAddInsClient");
			ModuleGetAddInsClient.UpdateAddIns(Undefined, PlacedFiles[0].FullName);
			Return;
		EndIf;
		FormParameters = New Structure;
		FormParameters.Insert("FileThatWasPut", PlacedFiles[0]);
		OpenForm("Catalog.AddIns.ObjectForm", FormParameters);
		Return;
	EndIf;
	
	Result = DownloadAddInsAtServer(PlacedFiles);
	Items.Pages_Group.CurrentPage = Items.List_Page;
	
	If Result.Count() > 0 Then
		TextDocument = New TextDocument;
		TextDocument.SetText(StrConcat(Result, Chars.LF));
		TextDocument.InsertLine(0, NStr(
			"vi = 'Không thể kết nhập cấu phần, hãy kết nhập từng tệp để điền thủ công thuộc tính cấu phần:';
			|ru = 'Не удалось загрузить компоненты, загружайте файлы по одному для заполнения свойств компонент вручную:';
			|en = 'Cannot import the add-ins. To fill add-in properties manually, import files one by one:'; fa = 'Cannot import the add-ins. To fill add-in properties manually, import files one by one:';
			|it = 'Не удалось загрузить компоненты, загружайте файлы по одному для заполнения свойств компонент вручную:';
			|pl = 'Cannot import the add-ins. To fill add-in properties manually, import files one by one:';
			|tr = 'Bileşenler yüklenemedi, bileşen özelliklerini manuel olarak doldurmak için dosyaları teker teker yükleyin:'")
			+ Chars.LF);
		TextDocument.Show(NStr("vi = 'Không thể kết nhập cấu phần';
								|ru = 'Не удалось загрузить компоненты';
								|en = 'Cannot import the add-ins'; fa = 'Cannot import the add-ins';
								|it = 'Не удалось загрузить компоненты';
								|pl = 'Cannot import the add-ins';
								|tr = 'Bileşenler yüklenemedi'"));
	EndIf;
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Function DownloadAddInsAtServer(Val PlacedFiles)
	
	ErrorsDescription = New Array;
	
	UsedAddIns = AddInsInternal.UsedAddIns();
	
	For Each ComponentFile In PlacedFiles Do

		Try
			ImportParameters = AddInsInternal.ImportParameters();
			ImportParameters.FileName = ComponentFile.FileName;
			ImportParameters.UpdateFrom1CITSPortal = False;
			ImportParameters.Data = ComponentFile.Location;
			ImportParameters.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết nhập từ tệp %1. %2.';
					|ru = 'Загружена из файла %1. %2.';
					|en = 'Imported from the %1 file. %2.'; fa = 'Imported from the %1 file. %2.';
					|it = 'Caricata da file %1. %2.';
					|pl = 'Pobrana z pliku %1. %2.';
					|tr = 'Dosyadan yüklendi %1. %2'"),
				ComponentFile.FileName,
				CurrentSessionDate());
			AddInsInternal.LoadAComponentFromBinaryData(ImportParameters, True, UsedAddIns);
		Except
			If ValueIsFilled(ComponentFile.FullName) Then
				PathToFile = ComponentFile.FullName;
			Else
				PathToFile = ComponentFile.FileName;
			EndIf;
			ErrorsDescription.Add(StringFunctionsClientServer.SubstituteParametersToString("%1: %2", PathToFile,
				ErrorProcessing.BriefErrorDescription(ErrorInfo())));
		EndTry;

	EndDo;
	
	Return ErrorsDescription;
	
EndFunction

&AtClient
Procedure AddAddInsAfterFilesPut(PlacedFiles, AdditionalParameters) Export
	
	If Not ValueIsFilled(PlacedFiles) Then
		Items.Pages_Group.CurrentPage = Items.List_Page;
		Return;
	EndIf;
	
	Notification = New CallbackDescription("DownloadAddInsAfterSafetyWarning", ThisObject, PlacedFiles);
	UsersInternalClient.ShowSecurityWarning(Notification,
		UsersInternalClientServer.SecurityWarningKinds().BeforeAddAddIn);
	
EndProcedure

&AtClient
Procedure AfterUpdateAddInFromPortal(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure

/////////////////////////////////////////////////////////
// Presentation of data on the form.

&AtServer
Procedure SetFilter()
	
	FilterParameters = New Map();
	FilterParameters.Insert("UseFilter", UseFilter);
	SetListFilter(List, FilterParameters);
	
	Items.DeleteUnusedItems.Visible = UseFilter = 3 And AccessRight("Edit", Metadata.Catalogs.AddIns);
	
EndProcedure

&AtServerNoContext
Procedure SetListFilter(List, FilterParameters)
	
	If FilterParameters["UseFilter"] = 3 Then
		IDs = AddInsInternal.SuppliedAddIns();
		CommonClientServer.SetDynamicListFilterItem(
			List, "Id", IDs, DataCompositionComparisonType.NotInList, , True);
		CommonClientServer.SetDynamicListFilterItem(
				List, "Use", Enums.AddInUsageOptions.Used, , , False);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			List, "Id", Undefined, , , False);
		If FilterParameters["UseFilter"] = 0 Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Use", , , , False);
		ElsIf FilterParameters["UseFilter"] = 1 Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Use", Enums.AddInUsageOptions.Used, , , True);
		ElsIf FilterParameters["UseFilter"] = 2 Then
			CommonClientServer.SetDynamicListFilterItem(
				List, "Use", Enums.AddInUsageOptions.TurnedOff, , , True);
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DeleteUnusedAddIns()
	
	AddInsInternal.DeleteUnusedAddIns();
	
EndProcedure

&AtServerNoContext
Function IsFileOfService(Val FileAddress)
	
	If AddInsInternal.CanImportFromPortalInteractively() Then
		
		BinaryData = GetFromTempStorage(FileAddress);
		Information = AddInsInternal.InformationOnAddInFromFile(BinaryData, False);
		
		Return Information.IsFileOfService;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Use");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AddInUsageOptions.TurnedOff;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue(
		"TextColor", Metadata.StyleItems.InaccessibleCellTextColor.Value);
	
EndProcedure

#EndRegion