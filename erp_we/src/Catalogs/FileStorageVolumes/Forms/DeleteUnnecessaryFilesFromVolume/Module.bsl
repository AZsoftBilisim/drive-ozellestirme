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
	
	FileStorageVolume = Parameters.FileStorageVolume;
	
	FillExcessFilesTable();
	UnnecessaryFilesCount = UnnecessaryFiles.Count();
	
	DateFolder = Format(CurrentSessionDate(), "DF=yyyyMMdd") + GetPathSeparator();
	
	CopyFilesBeforeDelete                = False;
	Items.PathToFolderToCopy.Enabled = False;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationMoreClick(Item)
	
	ReportParameters = New Structure();
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", New Structure("Volume", FileStorageVolume));
	
	OpenForm("Report.VolumeIntegrityCheck.ObjectForm", ReportParameters);
	
EndProcedure

&AtClient
Procedure PathToFolderToCopyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = "";
	OpenFileDialog.Directory = PathToFolderToCopy;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = Title;
	
	Context = New Structure("OpenFileDialog", OpenFileDialog);
	
	ChoiceDialogNotificationDetails = New CallbackDescription(
		"PathToFolderToCopyStartChoiceCompletion", ThisObject, Context);
	FileSystemClient.ShowSelectionDialog(ChoiceDialogNotificationDetails, OpenFileDialog);
	
EndProcedure

&AtClient
Procedure PathToFolderToCopyOnChange(Item)
	
	PathToFolderToCopy                     = CommonClientServer.AddLastPathSeparator(PathToFolderToCopy);
	Items.FormDeleteUnnecessaryFiles.Enabled = ValueIsFilled(PathToFolderToCopy);
	
EndProcedure

&AtClient
Procedure CopyFilesBeforeDeleteOnChange(Item)
	
	If Not CopyFilesBeforeDelete Then
		PathToFolderToCopy                      = "";
		Items.PathToFolderToCopy.Enabled = False;
		Items.FormDeleteUnnecessaryFiles.Enabled  = True;
	Else
		Items.PathToFolderToCopy.Enabled = True;
		If ValueIsFilled(PathToFolderToCopy) Then
			Items.FormDeleteUnnecessaryFiles.Enabled = True;
		Else
			Items.FormDeleteUnnecessaryFiles.Enabled = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DeleteUnnecessaryFiles(Command)
	
	If UnnecessaryFilesCount = 0 Then
		ShowMessageBox(, NStr("vi = 'Không có tệp thừa nào trong quyển';
								|ru = 'Нет ни одного лишнего файла в томе';
								|en = 'The volume has no unreferenced files'; fa = 'The volume has no unreferenced files';
								|it = 'Нет ни одного лишнего файла в томе';
								|pl = 'The volume has no unreferenced files';
								|tr = 'Birimde herhangi bir fazlalık dosya yok'"));
		Return;
	EndIf;
	
	If CopyFilesBeforeDelete Then
		FileSystemClient.Attach1CEnterpriseExtension(
			New CallbackDescription("FileSystemExtensionAttachmentCompletion", ThisObject),, 
			False);
	Else
		AfterCheckWriteToDirectory(True, New Structure);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure PathToFolderToCopyStartChoiceCompletion(SelectedFiles, Context) Export
	
	OpenFileDialog = Context.OpenFileDialog;
	
	If SelectedFiles = Undefined Then
		Items.FormDeleteUnnecessaryFiles.Enabled = False;
	Else
		PathToFolderToCopy = OpenFileDialog.Directory;
		PathToFolderToCopy = CommonClientServer.AddLastPathSeparator(PathToFolderToCopy);
		Items.FormDeleteUnnecessaryFiles.Enabled = ValueIsFilled(PathToFolderToCopy);
	EndIf;

EndProcedure

&AtServer
Procedure FillExcessFilesTable()
	
	FilesTableOnHardDrive = FilesOperationsInVolumesInternal.UnnecessaryFilesInVolume();
	VolumePath = TrimAll(FilesOperationsInVolumesInternal.FullVolumePath(FileStorageVolume));
	
	FilesArray = FindFiles(VolumePath,"*", True);
	For Each File In FilesArray Do
		
		If Not File.IsFile() Then
			Continue;
		EndIf;
		
		NewRow = FilesTableOnHardDrive.Add();
		NewRow.Name              = File.Name;
		NewRow.BaseName = File.BaseName;
		NewRow.FullName        = File.FullName;
		NewRow.Path             = File.Path;
		NewRow.Extension       = File.Extension;
		NewRow.CheckStatus   = NStr("vi = 'Tệp thừa (có trong quyển, nhưng không có thông tin về chúng)';
									|ru = 'Лишние файлы (есть в томе, но сведения о них отсутствуют)';
									|en = 'Unreferenced files (files in the volume that have no entries in the application)'; fa = 'Unreferenced files (files in the volume that have no entries in the application)';
									|it = 'Лишние файлы (есть в томе, но сведения о них отсутствуют)';
									|pl = 'Unreferenced files (files in the volume that have no entries in the application)';
									|tr = 'Fazlalık dosyalar (birimde mevcut, ancak haklarında bilgi yok)'");
		NewRow.Count       = 1;
		NewRow.Volume              = FileStorageVolume;
		
	EndDo;
	
	FilesOperationsInVolumesInternal.FillInExtraFiles(FilesTableOnHardDrive, FileStorageVolume);
	FilesTableOnHardDrive.Indexes.Add("CheckStatus");
	ExcessFilesArray = FilesTableOnHardDrive.FindRows(
		New Structure("CheckStatus", NStr("vi = 'Tệp thừa (có trong quyển, nhưng không có thông tin về chúng)';
											|ru = 'Лишние файлы (есть в томе, но сведения о них отсутствуют)';
											|en = 'Unreferenced files (files in the volume that have no entries in the application)'; fa = 'Unreferenced files (files in the volume that have no entries in the application)';
											|it = 'Лишние файлы (есть в томе, но сведения о них отсутствуют)';
											|pl = 'Unreferenced files (files in the volume that have no entries in the application)';
											|tr = 'Fazlalık dosyalar (birimde mevcut, ancak haklarında bilgi yok)'")));
	
	For Each File In ExcessFilesArray Do
		NewRow = UnnecessaryFiles.Add();
		FillPropertyValues(NewRow, File);
		NewRow.RelativePath = StrReplace(NewRow.FullName, VolumePath, "");
	EndDo;
	
	UnnecessaryFiles.Sort("Name");
	
EndProcedure

&AtClient
Procedure RightToWriteToDirectory(SourceNotification)
	
	If IsBlankString(PathToFolderToCopy) Then
		RunCallback(SourceNotification, True);
		Return
	EndIf;
	
	DirectoryName = PathToFolderToCopy + "CheckAccess\";
	
	DirectoryDeletionParameters  = New Structure("SourceNotification, DirectoryName", SourceNotification, DirectoryName);
	DirectoryCreationNotification = New CallbackDescription("AfterCreateDirectory", ThisObject, DirectoryDeletionParameters, "AfterDirectoryCreationError", ThisObject);
	BeginCreatingDirectory(DirectoryCreationNotification, DirectoryName);
	
EndProcedure

&AtClient
Procedure AfterDirectoryCreationError(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	ProcessAccessRightsError(ErrorInfo, AdditionalParameters.SourceNotification);
	
EndProcedure

&AtClient
Procedure AfterCreateDirectory(Result, AdditionalParameters) Export
	
	BeginDeletingFiles(New CallbackDescription("AfterDeleteDirectory", ThisObject, AdditionalParameters, "AfterDirectoryDeletionError", ThisObject), AdditionalParameters.DirectoryName);
	
EndProcedure

&AtClient
Procedure AfterDeleteDirectory(AdditionalParameters) Export
	
	RunCallback(AdditionalParameters.SourceNotification, True);
	
EndProcedure

&AtClient
Procedure AfterDirectoryDeletionError(ErrorInfo, StandardProcessing, AdditionalParameters) Export
	
	ProcessAccessRightsError(ErrorInfo, AdditionalParameters.SourceNotification);
	
EndProcedure

&AtClient
Procedure ProcessAccessRightsError(ErrorInfo, SourceNotification)
	
	ErrorTemplate = NStr("vi = 'Thư mục không hợp lệ để sao chép.
		|Có lẽ tài khoản thay mặt
		| máy chủ 1C: Enterprise đang chạy không có quyền truy cập vào thư mục được chỉ định.
		|
		|%1';
		|ru = 'Некорректная папка для копирования.
		|Возможно учетная запись, от лица которой работает
		|сервер 1С:Предприятия, не имеет прав доступа к указанной папке.
		|
		|%1';
		|en = 'Incorrect folder for copying.
		|An account on whose behalf 1C:Enterprise server is running
		|might have no access rights to the specified folder.
		|
		|%1'; fa = 'Incorrect folder for copying.
		|An account on whose behalf 1C:Enterprise server is running
		|might have no access rights to the specified folder.
		|
		|%1';
		|it = 'Cartella errata per la copiatura. 
		|Probabilmente, l''account tramite il quale opera 
		|il server 1C:Enterprise non possiede i diritti di accesso alla cartella indicata.
		|
		|%1';
		|pl = 'Niepoprawny folder do kopiowania.
		|Możliwe, że konto od którego pracuje
		|serwer 1С:Enterprise, nie ma uprawnień dostępu do podanego folderu.
		|
		|%1';
		|tr = 'Kopyalanacak geçersiz klasör.
		|Muhtemelen bir hesap, 
		| 1C:Enterprise sunucusunun adına çalıştığı, belirtilen klasöre erişim haklarına sahip değil.
		|
		|%1'");
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	CommonClient.MessageToUser(ErrorText, , , "PathToFolderToCopy");
	
	RunCallback(SourceNotification, False);
	
EndProcedure

// Parameters:
//   ErrorsReport - SpreadsheetDocument
//   FilesArrayWithErrors - Array of see ErrorStructure
//
&AtServer
Procedure GenerateErrorsReport(ErrorsReport)

	SpreadsheetTemplate_ = Catalogs.FileStorageVolumes.GetTemplate("ReportTemplate");
	
	HeaderArea_ = SpreadsheetTemplate_.GetArea("Title");
	HeaderArea_.Parameters.LongDesc = NStr("vi = 'Tệp có vấn đề:';
											|ru = 'Проблемные файлы:';
											|en = 'Files with errors:'; fa = 'Files with errors:';
											|it = 'Проблемные файлы:';
											|pl = 'Files with errors:';
											|tr = 'Sorunlu dosyalar:'");
	ErrorsReport.Put(HeaderArea_);
	
	AreaRow = SpreadsheetTemplate_.GetArea("String");
	
	For Each FileWithError In FormAttributeToValue("FilesWithErrors") Do
		AreaRow.Parameters.Name1 = FileWithError.Name;
		AreaRow.Parameters.Error = FileWithError.Error;
		Area = ErrorsReport.Put(AreaRow);
		Area.RowHeight = 0;
		Area.AutoRowHeight = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure FileSystemExtensionAttachmentCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If Not ExtensionAttached Then
		ShowMessageBox(, NStr("vi = 'Phần mở rộng để làm việc với 1C: Enterprise chưa được cài đặt. Hành động không có sẵn.';
								|ru = 'Не установлено расширение для работы с 1С:Предприятием. Действие не доступно.';
								|en = 'Cannot perform the operation because 1C:Enterprise Extension is not installed.'; fa = 'Cannot perform the operation because 1C:Enterprise Extension is not installed.';
								|it = 'L''estensione di lavoro con 1C:Enterprise non è stata installata. Azione non disponibile.';
								|pl = 'Nie zainstalowano rozszerzenia do pracy z 1С:Enterprise. Czynność nie jest dostępna.';
								|tr = '1C:Enterprise ile çalışma uzantısı kurulu değil. Eylem mevcut değil.'"));
		Return;
	EndIf;
	
	FolderForCopying = New File(PathToFolderToCopy);
	FolderForCopying.BeginCheckingExistence(New CallbackDescription("FolderExistanceCheckCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure FolderExistanceCheckCompletion(Exists, AdditionalParameters) Export
	
	If Not Exists Then
		ShowMessageBox(, NStr("vi = 'Thư mục được chỉ định không tồn tại.';
								|ru = 'Указанная папка не существует.';
								|en = 'The specified folder does not exist.'; fa = 'The specified folder does not exist.';
								|it = 'La cartella indicata non esiste.';
								|pl = 'Podany folder nie istnieje.';
								|tr = 'Belirtilen klasör mevcut değil.'"));
	Else
		RightToWriteToDirectory(New CallbackDescription("AfterCheckWriteToDirectory", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Async Procedure AfterCheckWriteToDirectory(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	If UnnecessaryFiles.Count() = 0 Then
		Return;
	EndIf;
	
	If CopyFilesBeforeDelete Then
		
		FilesForDeletion = New Map;
	
		For Each ExtraFile In UnnecessaryFiles Do
			FilesForDeletion.Insert(ExtraFile.FullName, 
				New Structure("Name, RelativePath", ExtraFile.Name, ExtraFile.RelativePath));
		EndDo;
		
		UniqueFilenames = New Map;
		For Each FileToDelete In FilesForDeletion Do
			File = New File(FileToDelete.Value.RelativePath);
			If StrStartsWith(File.Extension, ".") Then
				Extension = File.Extension;
			ElsIf ValueIsFilled(File.Extension) Then
				Extension = "."+Extension;
			Else
				Extension = "";
			EndIf;
			
			RelativePath = File.BaseName + Extension;
					
			TargetPath = PathToFolderToCopy + DateFolder + GetPathSeparator() + RelativePath;
			If UniqueFilenames[TargetPath] = True Or Await File.ExistsAsync() Then
				RelativePath = File.BaseName + String(New UUID) + Extension;
				FileToDelete.Value.RelativePath = RelativePath;
			Else
				FileToDelete.Value.RelativePath = RelativePath;
				UniqueFilenames.Insert(TargetPath, True);
			EndIf;
		EndDo;
		
		FilesForDownloading = PrepareFilesAtServer(FilesForDeletion);
		Context = New Structure("FilesForDownloading, FilesForDeletion", FilesForDownloading, FilesForDeletion);
		AfterFilesReceivedFromServer = New CallbackDescription("AfterFilesReceivedFromServer", ThisObject, Context,
			"ErrorAfterGetFilesFromServer", ThisObject);
		BeginGetFilesFromServer(AfterFilesReceivedFromServer, FilesForDownloading, PathToFolderToCopy + DateFolder + GetPathSeparator());
		
	Else
		
		FilesForDeletion = New Array;
	
		For Each ExtraFile In UnnecessaryFiles Do
			FilesForDeletion.Add(ExtraFile.FullName);
		EndDo;
			
		DeleteVolumesFiles(FilesForDeletion);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteVolumesFiles(FilesForDeletion)
	DeletionResult = DeleteVolumesFilesOnServer(FilesForDeletion);
	NumberOfDeletedFiles = DeletionResult.Deleted;
	FilesWithErrors.Clear();
	For Each DeletionError In DeletionResult.DeletionErrors Do
		FillPropertyValues(FilesWithErrors.Add(), DeletionError);
	EndDo;
	
	AfterProcessFiles();
EndProcedure

&AtServerNoContext
Function DeleteVolumesFilesOnServer(Files)
	Return FilesOperationsInVolumesInternal.DeleteVolumesFiles(Files);
EndFunction

&AtClient
Procedure AfterFilesReceivedFromServer(ObtainedFiles, Context) Export
	FilesForDeletion = New Array;
	For Each File In Context.FilesForDeletion Do
		FilesForDeletion.Add(File.Key);
	EndDo;
		
	DeleteVolumesFiles(FilesForDeletion);
EndProcedure

&AtClient
Procedure ErrorAfterGetFilesFromServer(ErrorInfo, StandardProcessing, Context) Export
	FilesWithErrors.Clear();
	FileWithError = FilesWithErrors.Add();
	FileWithError.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	AfterProcessFiles();
EndProcedure

&AtServer
Function PrepareFilesAtServer(FilesForDeletion)
	Result = New Array;
	For Each File In FilesForDeletion Do
		BinaryData = New BinaryData(File.Key);
		Address = PutToTempStorage(BinaryData);
		FileName = File.Value.RelativePath;
		Result.Add(New TransferableFileDescription(FileName, Address))
	EndDo;
	Return Result;
EndFunction

&AtClient
Procedure AfterProcessFiles()

	If NumberOfDeletedFiles <> 0 Then
		NotificationText1 = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã xóa tệp: %1';
				|ru = 'Удалено файлов: %1';
				|en = 'Files deleted: %1'; fa = 'Files deleted: %1';
				|it = 'File cancellati: %1';
				|pl = 'Usuniętych plików: %1';
				|tr = 'Silinen dosya: %1'"),
			NumberOfDeletedFiles);
		ShowUserNotification(
			NStr("vi = 'Đã kết thúc các tệp thừa.';
				|ru = 'Завершено удаление лишних файлов.';
				|en = 'Unreferenced files are deleted.'; fa = 'Unreferenced files are deleted.';
				|it = 'Terminata la cancellazione dei file non necessari.';
				|pl = 'Zakończono usuwanie zbędnych plików.';
				|tr = 'Fazla dosya silindi.'"),,
			NotificationText1, PictureLib.DialogInformation);
	EndIf;
	
	If FilesWithErrors.Count() > 0 Then
		ErrorsReport = New SpreadsheetDocument;
		GenerateErrorsReport(ErrorsReport);
		ErrorsReport.Show(NStr("vi = 'Xóa tệp thừa từ quyển';
								|ru = 'Удаление лишних файлов из тома';
								|en = 'Delete unreferenced volume files'; fa = 'حذف فایل‌های بدون ارجاع ولوم';
								|it = 'Eliminare i file superflui dal volume';
								|pl = 'Usuwanie dodatkowych plików z woluminu';
								|tr = 'Fazla dosyaları birimden sil'"));
	EndIf;
	
	Close();
	
EndProcedure

#EndRegion