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
	
	If Parameters.FolderForAdding = Undefined Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	FilesGroup = Parameters.FilesGroup;
	FolderForAdding = Parameters.FolderForAdding;
	FolderToAddAsString = Common.SubjectString(FolderForAdding);
	StoreVersions = FilesOperationsInternalServerCall.IsDirectoryFiles(FolderForAdding);
	Items.StoreVersions.Visible = StoreVersions;
	
	If TypeOf(Parameters.FileNamesArray) = Type("Array") Then
		For Each FilePath In Parameters.FileNamesArray Do
			MovedFile = New File(FilePath);
			NewItem = SelectedFiles.Add();
			NewItem.Path = FilePath;
			NewItem.PictureIndex = FilesOperationsInternalClientServer.IndexOfFileIcon(MovedFile.Extension);
		EndDo;
	EndIf;
	
	If Common.IsMobileClient() Then
		Title = NStr("vi = 'Kết nhập tệp từ thiết bị';
					|ru = 'Загрузка файлов с устройства';
					|en = 'Import files from device'; fa = 'Import files from device';
					|it = 'Import files from device';
					|pl = 'Import files from device';
					|tr = 'Cihazdan dosya yükleme'");
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

#Region FormTableItemsEventHandlersSelectedFiles

&AtClient
Procedure SelectedFilesBeforeAddRow(Item, Cancel, Copy)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddExecute()
	
	ClearMessages();
	
	FieldsNotFilled = False;
	
	If SelectedFiles.Count() = 0 Then
		CommonClient.MessageToUser(
			NStr("vi = 'Không có tệp để thêm.';
				|ru = 'Нет файлов для добавления.';
				|en = 'No files to add.'; fa = 'No files to add.';
				|it = 'Non ci sono file da aggiungere.';
				|pl = 'Brak plików do dodania.';
				|tr = 'Eklenecek dosyalar yok.'"), , "SelectedFiles");
		FieldsNotFilled = True;
	EndIf;
	
	If FieldsNotFilled = True Then
		Return;
	EndIf;
	
	SelectedFileValueList = New ValueList;
	For Each ListLine In SelectedFiles Do
		SelectedFileValueList.Add(ListLine.Path);
	EndDo;
	
#If WebClient Then
	
	OperationArray = New Array;
	
	For Each ListLine In SelectedFiles Do
		CallDetails = New Array;
		CallDetails.Add("PutFiles");
		
		Files = New Array;
		LongDesc = New TransferableFileDescription(ListLine.Path, "");
		Files.Add(LongDesc);
		CallDetails.Add(Files);
		
		CallDetails.Add(Undefined); // Obsolete.
		CallDetails.Add(Undefined); // Obsolete.
		CallDetails.Add(False);         // Interactively = False
		
		OperationArray.Add(CallDetails);
	EndDo;
	
	If Not RequestUserPermission(OperationArray) Then
		// User did not give a permission.
		Close();
		Return;
	EndIf;	
#EndIf	
	
	AddedFiles = New Array;
	
	HandlerParameters = New Structure;
	HandlerParameters.Insert("AddedFiles", AddedFiles);
	Handler = New CallbackDescription("AddExecuteCompletion", ThisObject, HandlerParameters);
	
	ExecutionParameters = FilesOperationsInternalClient.FilesImportParameters();
	ExecutionParameters.HandlerResults_1          = Handler;
	ExecutionParameters.Owner                      = FolderForAdding;
	ExecutionParameters.SelectedFiles                = SelectedFileValueList; 
	ExecutionParameters.Comment                   = Comment;
	ExecutionParameters.StoreVersions                 = StoreVersions;
	ExecutionParameters.DeleteFilesAfterImport     = DeleteFilesAfterImport;
	ExecutionParameters.Recursively                    = False;
	ExecutionParameters.FormIdentifier            = UUID;
	ExecutionParameters.AddedFiles              = AddedFiles;
	ExecutionParameters.Encoding                     = FileTextEncoding;
	ExecutionParameters.FilesGroup                  = FilesGroup;
	
	FilesOperationsInternalClient.ExecuteFilesImport(ExecutionParameters);
EndProcedure

&AtClient
Procedure SelectFilesExecute()
	
	Handler = New CallbackDescription("SelectFilesExecuteAfterInstallExtension", ThisObject);
	FilesOperationsInternalClient.ShowQuestionOn1CEnterpriseExtensionInstallation(Handler);
	
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

&AtClient
Procedure AddExecuteCompletion(Result, ExecutionParameters) Export
	Close();
	
	Source = Undefined;
	AddedFilesCount = Result.AddedFiles.Count();
	If AddedFilesCount > 0 Then
		Source = Result.AddedFiles[AddedFilesCount - 1].FileRef;
	EndIf;
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	FileWriteNotificationParameters.IsNew = True;
	Notify("Write_File", FileWriteNotificationParameters, Source);
EndProcedure

&AtClient
Procedure SelectFilesExecuteAfterInstallExtension(ExtensionInstalled, ExecutionParameters) Export
	If Not ExtensionInstalled Then
		Return;
	EndIf;
	
	Mode = FileDialogMode.Open;
	
	OpenFileDialog = New FileDialog(Mode);
	OpenFileDialog.FullFileName = "";
	Filter = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Tất cả tệp (%1)|%1';
																			|ru = 'Все файлы (%1)|%1';
																			|en = 'All files (%1)|%1'; fa = 'All files (%1)|%1';
																			|it = 'Все файлы (%1)|%1';
																			|pl = 'All files (%1)|%1';
																			|tr = 'Tüm dosyalar (%1)|%1'"), GetAllFilesMask());
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = True;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn tệp';
								|ru = 'Выберите файлы';
								|en = 'Select files'; fa = 'انتخاب فایل‌ها';
								|it = 'Scegliete i file';
								|pl = 'Wybierz pliki';
								|tr = 'Dosyaları seçin'");
	If OpenFileDialog.Choose() Then
		SelectedFiles.Clear();
		
		FilesArray = OpenFileDialog.SelectedFiles;
		For Each FileName In FilesArray Do
			MovedFile = New File(FileName);
			NewItem = SelectedFiles.Add();
			NewItem.Path = FileName;
			NewItem.PictureIndex = FilesOperationsInternalClientServer.IndexOfFileIcon(MovedFile.Extension);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion
