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
	
	If Not ValueIsFilled(Parameters.DirectoryOnHardDrive) Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	FilesGroup = Parameters.FilesGroup;
	Directory = Parameters.DirectoryOnHardDrive;
	FolderForAdding = Parameters.FolderForAdding;
	FolderToAddAsString = Common.SubjectString(FolderForAdding);
	DirectoriesChoice = True;
	StoreVersions = FilesOperationsInternalServerCall.IsDirectoryFiles(FolderForAdding);
	Items.StoreVersions.Visible = StoreVersions;
	
	If Common.IsMobileClient() Then
		Title = NStr("vi = 'Kết nhập thư mục từ thiết bị';
					|ru = 'Загрузка папки с устройства';
					|en = 'Import directory from device'; fa = 'Import directory from device';
					|it = 'Import directory from device';
					|pl = 'Import directory from device';
					|tr = 'Cihazdan klasör yükleme'");
		Items.DeleteAfterAdding.Title = NStr("vi = 'Xóa tệp trên thiết bị sau khi kết nhập';
											|ru = 'Удалить файлы на устройстве после загрузки';
											|en = 'Delete files from device after import completed'; fa = 'Delete files from device after import completed';
											|it = 'Delete files from device after import completed';
											|pl = 'Delete files from device after import completed';
											|tr = 'Yükleme sonrasında cihazdaki dosyaları sil'");
	EndIf;

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.FilesOperations.Form.SelectEncoding") Then
		If TypeOf(ValueSelected) <> Type("Structure") Then
			Return;
		EndIf;
		FileTextEncoding = ValueSelected.Value;
		EncodingPresentation = ValueSelected.Presentation;
		SetCodingCommandPresentation(EncodingPresentation);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SelectedDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	// Code is called only from IE or thin client, check on the web client is not required.
	Mode = FileDialogMode.ChooseDirectory;
	
	OpenFileDialog = New FileDialog(Mode);
	
	OpenFileDialog.Directory = Directory;
	OpenFileDialog.FullFileName = "";
	Filter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn thư mục';
								|ru = 'Выберите каталог';
								|en = 'Select directory'; fa = 'Select directory';
								|it = 'Scegliete la directory';
								|pl = 'Wybierz katalog';
								|tr = 'Dizini seçin'");
	If OpenFileDialog.Choose() Then
		If DirectoriesChoice = True Then 
			Directory = OpenFileDialog.Directory;
		EndIf;
	EndIf;
		
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportExecute()
	
	If IsBlankString(Directory) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chọn thư mục nào để kết nhập.';
				|ru = 'Не выбрана папка для импорта.';
				|en = 'Select a folder for import.'; fa = 'Select a folder for import.';
				|it = 'Cartella per l''importazione non selezionata.';
				|pl = 'Nie wybrano folderu do importowania.';
				|tr = 'İçe aktarım klasörü seçili değil.'"), , "Directory");
		Return;
		
	EndIf;
	
	If FolderForAdding.IsEmpty() Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy chỉ ra thư mục.';
				|ru = 'Укажите папку.';
				|en = 'Please select a folder.'; fa = 'Please select a folder.';
				|it = 'Indicate una cartella.';
				|pl = 'Wskaż folder.';
				|tr = 'Klasörü belirleyin.'"), , "FolderForAdding");
		Return;
	EndIf;
	
	SelectedFiles = New ValueList;
	SelectedFiles.Add(Directory);
	
	Handler = New CallbackDescription("ImportCompletion", ThisObject);
	
	ExecutionParameters = FilesOperationsInternalClient.FilesImportParameters();
	ExecutionParameters.HandlerResults_1          = Handler;
	ExecutionParameters.Owner                      = FolderForAdding;
	ExecutionParameters.SelectedFiles                = SelectedFiles; 
	ExecutionParameters.Comment                   = LongDesc;
	ExecutionParameters.StoreVersions                 = StoreVersions;
	ExecutionParameters.DeleteFilesAfterImport     = DeleteFilesAfterImport;
	ExecutionParameters.Recursively                    = True;
	ExecutionParameters.FormIdentifier            = UUID;
	ExecutionParameters.Encoding                     = FileTextEncoding;
	ExecutionParameters.FilesGroup                  = FilesGroup;
	FilesOperationsInternalClient.ExecuteFilesImport(ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ImportCompletion(Result, ExecutionParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	Close();
	Notify("Write_FilesFolders", New Structure, Result.FolderForAddingCurrent);
EndProcedure

&AtClient
Procedure SelectEncoding(Command)
	FormParameters = New Structure;
	FormParameters.Insert("CurrentEncoding", FileTextEncoding);
	OpenForm("DataProcessor.FilesOperations.Form.SelectEncoding", FormParameters, ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetCodingCommandPresentation(Presentation)
	
	Commands.SelectEncoding.Title = Presentation;
	
EndProcedure

#EndRegion
