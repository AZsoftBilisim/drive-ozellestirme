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
Var AdditionalInformation;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsNew = Object.Ref.IsEmpty();
	
	If IsNew Then
		Parameters.ShowImportFromFileDialogOnOpen = True;
	EndIf;
	
	SetVisibilityAvailability();
	
	If Not AccessRight("Edit", Metadata.Catalogs.AddIns) Then
		
		Items.FormUpdateFromFile.Visible = False;
		Items.FormSaveAs.Visible = False;
		Items.PerformUpdateFrom1CITSPortal.Visible = False;
	
	EndIf;
	
	If Not AddInsInternal.CanImportFromPortal() Then 
		
		Items.UpdateFrom1CITSPortal.Visible = False;
		Items.PerformUpdateFrom1CITSPortal.Visible = False;
		
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.ShowImportFromFileDialogOnOpen Then
		AttachIdleHandler("ImportAddInFromFile", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// If the "Reread" command is called, delete add-in data clipboard
	If IsTempStorageURL(ComponentBinaryDataAddress) Then
		DeleteFromTempStorage(ComponentBinaryDataAddress);
	EndIf;
	
	ComponentBinaryDataAddress = Undefined;
	SetVisibilityAvailability();
	TargetPlatforms = CurrentObject.TargetPlatforms.Get();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// If there is binary add-in data to be saved, add them to AdditionalProperties.
	If IsTempStorageURL(ComponentBinaryDataAddress) Then
		ComponentBinaryData = GetFromTempStorage(ComponentBinaryDataAddress);
		CurrentObject.AdditionalProperties.Insert("ComponentBinaryData", ComponentBinaryData);
	EndIf;
	
	CurrentObject.TargetPlatforms = New ValueStorage(TargetPlatforms, New Deflation(9));
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Saved = True; // Saving means successful closing,
	Parameters.ShowImportFromFileDialogOnOpen = False; // Preventing closing form on error.
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetVisibilityAvailability();
	
	AddInsInternal.NotifyAllSessionsAboutAddInChange();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then 
		Return;
	EndIf;
	
	If Not Modified Then
		StandardProcessing = False;
		
		CloseParameter = AddInsInternalClient.AddInImportResult();
		CloseParameter.Imported1 = Saved;
		CloseParameter.Id = Object.Id;
		CloseParameter.Version = Object.Version;
		CloseParameter.Description  = Object.Description;
		CloseParameter.AdditionalInformation = AdditionalInformation;
		
		Close(CloseParameter);
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseOnChange(Item)
	
	SetVisibilityAvailability();
	
EndProcedure

&AtClient
Procedure UpdateFrom1CITSPortalOnChange(Item)
	
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateFromThePortal(Command)
	
	If Modified Then
		Notification = New CallbackDescription("AfterCloseQuestionWriteObject", ThisObject);
		ShowQueryBox(Notification, 
			NStr("vi = 'Để kiểm tra bản cập nhật, hãy ghi lại các thay đổi. Ghi lại?';
				|ru = 'Для проверки обновления запишите изменения. Записать?';
				|en = 'Before checking for updates, save the changes. Save the changes?'; fa = 'Before checking for updates, save the changes. Save the changes?';
				|it = 'Per la verifica dell''aggiornamento è necessario registrare le modifiche. Registrare?';
				|pl = 'W celu sprawdzenia aktualizacji zapisz zmiany. Zapisać?';
				|tr = 'Güncellemeyi doğrulamak için değişiklikleri kaydedin. Kayıt?'"),
			QuestionDialogMode.YesNo);
	Else 
		StartAddInUpdateFromPortal();
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateFromFile(Command)
	
	Parameters.FileThatWasPut = Undefined;
	ClearMessages();
	ImportAddInFromFile();
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	If IsTempStorageURL(ComponentBinaryDataAddress) Then
		ShowMessageBox(, NStr("vi = 'Trước khi lưu cấu phần vào tệp, hãy ghi lại phần tử danh mục.';
								|ru = 'Перед сохранением компоненты в файл запишите элемент справочника.';
								|en = 'Save the catalog item before saving the add-in.'; fa = 'Save the catalog item before saving the add-in.';
								|it = 'Перед сохранением компоненты в файл запишите элемент справочника.';
								|pl = 'Save the catalog item before saving the add-in.';
								|tr = 'Bileşenleri dosyaya kaydetmeden önce dizin öğesini kaydedin.'"));
	Else 
		ClearMessages();
		AddInsInternalClient.SaveAddInToFile(Object.Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportedClientApplications(Command)

	FormParameters = New Structure;
	FormParameters.Insert("SupportedClients", TargetPlatforms);
	
	OpenForm("CommonForm.SupportedClientApplications", FormParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region ClientLogic

&AtClient
Procedure ImportAddInFromFile()
	
	If Parameters.FileThatWasPut <> Undefined Then
		ImportAddInAfterPutFile(Parameters.FileThatWasPut, Undefined);
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ImportAddInAfterSecurityWarning", ThisObject);
	UsersInternalClient.ShowSecurityWarning(Notification,
		UsersInternalClientServer.SecurityWarningKinds().BeforeAddAddIn);
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
&AtClient
Procedure ImportAddInAfterSecurityWarning(Response, Context) Export
	
	// Response: 
	// - Continue - Attach the add-in.
	// - DialogReturnCode.Cancel - Cancel attachment.
	// - Undefined - Close the dialog.
	If Response <> "Continue" Then
		ImportAddInOnErrorDisplay();
		Return;
	EndIf;
	
	Notification = New CallbackDescription("ImportAddInAfterPutFile", ThisObject, Context);
	ImportParameters = FileSystemClient.FileImportParameters();
	
	ImportParameters.Dialog.Filter    = NStr("vi = 'Cấu phần ngoài (*.zip)|*.zip';
											|ru = 'Внешняя компонента (*.zip)|*.zip';
											|en = 'Add-in (*.zip)|*.zip'; fa = 'Add-in (*.zip)|*.zip';
											|it = 'Внешняя компонента (*.zip)|*.zip';
											|pl = 'Add-in (*.zip)|*.zip';
											|tr = 'Harici bileşen (*.zip)|*.zip'")+"|"
			+ StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	ImportParameters.Dialog.Title = NStr("vi = 'Hãy chọn tệp cấu phần ngoài';
										|ru = 'Выберите файл внешней компоненты';
										|en = 'Select an add-in file'; fa = 'Select an add-in file';
										|it = 'Selezionare il file della componente esterna';
										|pl = 'Wybierz plik komponentu zewnętrznego';
										|tr = 'Harici Bileşen Dosyasını Seçin'");
	ImportParameters.FormIdentifier = UUID;
	FileSystemClient.ImportFile_(Notification, ImportParameters, Object.FileName);

EndProcedure

// Continues the ImportAddInFromFile procedure.
&AtClient
Procedure ImportAddInAfterPutFile(FileThatWasPut, Context) Export
	
	If FileThatWasPut = Undefined Then
		ImportAddInOnErrorDisplay(NStr("vi = 'Không thể kết nhập tệp cấu phần.';
										|ru = 'Не удалось загрузить файл компоненты.';
										|en = 'Cannot import an add-in file.'; fa = 'Cannot import an add-in file.';
										|it = 'Non è stato possibile scaricare il file del componente.';
										|pl = 'Nie udało się pobrać pliku komponentu.';
										|tr = 'Bileşen dosyası yüklenemedi.'"));
		Return;
	EndIf;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("FileStorageAddress", FileThatWasPut.Location);
	ImportParameters.Insert("FileName",            FileNameOnly(FileThatWasPut.Name));
	
	Result = ImportAddInFromFileOnServer(ImportParameters);
	If Result.Imported1 And IsTempStorageURL(ComponentBinaryDataAddress)Then
		AdditionalInformation = Result.AdditionalInformation;
		Modified = True;
	Else 
		ImportAddInOnErrorDisplay(Result.ErrorDescription, Result.ErrorInfo);
	EndIf;
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
&AtClient
Procedure ImportAddInOnErrorDisplay(ErrorDescription = "", ErrorInfo = Undefined)
	
	If IsBlankString(ErrorDescription) Then 
		ImportAddInAfterErrorDisplay(Undefined);
	Else 
		Notification = New CallbackDescription("ImportAddInAfterErrorDisplay", ThisObject);
		
		StringWithWarning = NStr("vi = '%1
			|Hãy chỉ ra tệp nén zip với cấu phần ngoài.
			|Chi tiết xem <a href = ""%2"">Công nghệ tạo cấu phần ngoài</a>';
			|ru = '%1
			|Укажите zip-архив с внешней компонентой.
			|Подробнее см. <a href = ""%2"">Технология создания внешних компонент</a>';
			|en = '%1
			|Specify a ZIP archive with an add-in.
			|For more information, see <a href = ""%2"">Add-in Development Technology</a> (in Russian).'; fa = '%1
			|Specify a ZIP archive with an add-in.
			|For more information, see <a href = ""%2"">Add-in Development Technology</a> (in Russian).';
			|it = '%1
			|Укажите zip-архив с внешней компонентой.
			|Подробнее см. <a href = ""%2"">Технология создания внешних компонент</a>';
			|pl = '%1
			|Specify a ZIP archive with an add-in.
			|For more information, see <a href = ""%2"">Add-in Development Technology</a> (in Russian).';
			|tr = '%1
			|Harici bileşenlerle zip arşivini belirtin.
			|Detaylar için bkz. <a href = ""%2"">Harici bileşen oluşturma teknolojisi</a>'")
			+ ?(ErrorInfo = Undefined, "",
				Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
		StringWithWarning = StringFunctionsClient.FormattedString(StringWithWarning, ErrorDescription,
			"https://its.1c.eu/db/metod8dev/content/3221");
		
		ShowMessageBox(Notification, StringWithWarning);
	EndIf;
	
EndProcedure

// Continues the ImportAddInFromFile procedure.
&AtClient
Procedure ImportAddInAfterErrorDisplay(AdditionalParameters) Export
	
	// Opened via application interface.
	If Parameters.ShowImportFromFileDialogOnOpen Then 
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCloseQuestionWriteObject(QuestionResult, Context) Export 
	
	If QuestionResult = DialogReturnCode.Yes Then 
		Write();
		StartAddInUpdateFromPortal();
	EndIf;
	
EndProcedure

&AtClient
Procedure StartAddInUpdateFromPortal()
	
	IsNew = Object.Ref.IsEmpty();
	If IsNew Then 
		Return;
	EndIf;
	
	UnlockFormDataForEdit();
	
	AddInsToUpdate = New Array;
	AddInsToUpdate.Add(Object.Ref);
	
	Notification = New CallbackDescription("AfterUpdateAddInFromPortal", ThisObject);
	AddInsInternalClient.UpdateAddInsFromPortal(Notification, AddInsToUpdate);
	
EndProcedure

&AtClient
Procedure AfterUpdateAddInFromPortal(Result, AdditionalParameters) Export
	
	UpdateCardAfterAddInUpdateFromPortal();
	
EndProcedure

#EndRegion

#Region ServerLogic

// Server logic of the ImportAddInFromFile procedure.
&AtServer
Function ImportAddInFromFileOnServer(Val ImportParameters)
	
	If Not Users.IsFullUser(,, False) Then
		Raise(NStr("vi = 'Không đủ quyền để kết nhập cấu phần.';
					|ru = 'Недостаточно прав для загрузки компоненты.';
					|en = 'Insufficient rights to import an add-in.'; fa = 'Insufficient rights to import an add-in.';
					|it = 'Diritti insufficienti per l''importazione delle componenti.';
					|pl = 'Niewystarczająco uprawnień do załadowania komponentu.';
					|tr = 'Bileşeni indirmek için yetersiz haklar.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	ObjectOfCatalog = FormAttributeToValue("Object");
	
	BinaryData = GetFromTempStorage(ImportParameters.FileStorageAddress);
	Information = AddInsInternal.InformationOnAddInFromFile(BinaryData,, 
		Parameters.AdditionalInformationSearchParameters);
	
	Result = AddInImportResult();
	
	If Not Information.Disassembled Then 
		Result.ErrorDescription = Information.ErrorDescription;
		Result.ErrorInfo = Information.ErrorInfo;
		Return Result;
	EndIf;
	
	If ValueIsFilled(ObjectOfCatalog.Id)
		And ValueIsFilled(Information.Attributes.Id) Then 
		
		If ObjectOfCatalog.Id <> Information.Attributes.Id Then 
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể cập nhật cấu phần vì tên định danh khác nhau. 
					| Dự kiến %1, nhưng tên cấu phần ngoài được kết nhập: %2.';
					|ru = 'Невозможно обновить компоненту, т.к. различаются идентификаторы.
					|Ожидался %1, а идентификатор загружаемой внешней компоненты: %2.';
					|en = 'Cannot update the add-in as IDs are different.
					|Expected ID is %1, and ID of the add-in to be imported is %2.'; fa = 'Cannot update the add-in as IDs are different.
					|Expected ID is %1, and ID of the add-in to be imported is %2.';
					|it = 'Impossibile aggiornare la componente, poiché gli identificatori differiscono. 
					|Era atteso %1, mentre l''ID della componente esterna importabile: %2.';
					|pl = 'Niemożliwa jest aktualizacja komponentu, ponieważ różnią się identyfikatory.
					|Był oczekiwany %1, a identyfikator pobieranego zewnętrznego komponentu: %2.';
					|tr = 'Bileşen güncellenemiyor çünkü Kimlikler farklı.
					|beklenen%1,ve yüklenecek harici bileşenin kimliği: %2'"),
				ObjectOfCatalog.Id, Information.Attributes.Id);
			Return Result;
		EndIf;
		
	EndIf;
	
	FillPropertyValues(ObjectOfCatalog, Information.Attributes,, "Id"); // According to manifest data.
	TargetPlatforms = Information.Attributes.TargetPlatforms;
	
	If Not ValueIsFilled(ObjectOfCatalog.Id) Then 
		ObjectOfCatalog.Id = Information.Attributes.Id;
	EndIf;
	ObjectOfCatalog.FileName =  ImportParameters.FileName;          // Set file name.
	ComponentBinaryDataAddress = PutToTempStorage(Information.BinaryData,
		UUID);
	
	ObjectOfCatalog.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã kết nhập từ tệp %1. %2.';
			|ru = 'Загружена из файла %1. %2.';
			|en = 'Imported from file %1.%2.'; fa = 'Imported from file %1.%2.';
			|it = 'Caricata da file %1. %2.';
			|pl = 'Pobrana z pliku %1. %2.';
			|tr = 'Dosyadan yüklendi %1. %2'"),
		ObjectOfCatalog.FileName,
		CurrentSessionDate());
	
	ValueToFormAttribute(ObjectOfCatalog, "Object");
	
	Modified = True;
	SetVisibilityAvailability();
	
	Result.Imported1 = True;
	Result.AdditionalInformation = Information.AdditionalInformation;
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function AddInImportResult()
	
	Result = New Structure;
	Result.Insert("Imported1", False);
	Result.Insert("ErrorDescription", "");
	Result.Insert("ErrorInfo", Undefined);
	Result.Insert("AdditionalInformation", New Map);
	
	Return Result;
	
EndFunction

// Server logic of add-in update from the website.
&AtServer
Procedure UpdateCardAfterAddInUpdateFromPortal()
	
	Read();
	Modified = False;
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region Presentation

&AtServer
Procedure SetVisibilityAvailability()
	
	CatalogObject = FormAttributeToValue("Object");
	IsNew = Object.Ref.IsEmpty();
	
	Items.Information.Visible = ValueIsFilled(Object.ErrorDescription);
	
	// WarningDisplayOnEditParameters
	DisplayWarning = WarningOnEditRepresentation.Show;
	NotDisplayWarning = WarningOnEditRepresentation.DontShow;
	If ValueIsFilled(Object.Description) Then
		Items.Description.WarningOnEditRepresentation = DisplayWarning;
	Else
		Items.Description.WarningOnEditRepresentation = NotDisplayWarning;
	EndIf;
	If ValueIsFilled(Object.Id) Then 
		Items.Id.WarningOnEditRepresentation = DisplayWarning;
	Else 
		Items.Id.WarningOnEditRepresentation = NotDisplayWarning;
	EndIf;
	If ValueIsFilled(Object.Version) Then 
		Items.Version.WarningOnEditRepresentation = DisplayWarning;
	Else 
		Items.Version.WarningOnEditRepresentation = NotDisplayWarning;
	EndIf;
	
	// "Save to file" button availability.
	Items.FormSaveAs.Enabled = Not IsNew;
	
	// Dependence of using and automatic update.
	ComponentIsDisabled = (Object.Use = Enums.AddInUsageOptions.TurnedOff);
	Items.UpdateFrom1CITSPortal.Enabled = Not ComponentIsDisabled And CatalogObject.ThisIsTheLatestVersionComponent();
	
	Items.PerformUpdateFrom1CITSPortal.Enabled = Object.UpdateFrom1CITSPortal;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Function FileNameOnly(SelectedFileName)
	
	// It's crucial to use it on the client, as GetPathSeparator() on the server can be different.
	SubstringsArray = StrSplit(SelectedFileName, GetPathSeparator(), False);
	Return SubstringsArray.Get(SubstringsArray.UBound());
	
EndFunction

#EndRegion

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
