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
	
	If Parameters.ExportFolder <> Undefined Then
		WhatToSave = Parameters.ExportFolder;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.DigitalSignature") Then
		ModuleDigitalSignature = Common.CommonModule("DigitalSignature");
		
		EncryptedFilesExtension =
			ModuleDigitalSignature.PersonalSettings().EncryptedFilesExtension;
	Else
		EncryptedFilesExtension = "p7m";
	EndIf;
	
	FilesStorageCatalogName       = Parameters.FilesStorageCatalogName;
	FileVersionsStorageCatalogName = Parameters.FileVersionsStorageCatalogName;
	
	If Common.IsMobileClient() Then
		Title = NStr("vi = 'Lưu thư mục vào thiết bị';
					|ru = 'Сохранение папки на устройство';
					|en = 'Save directory to device'; fa = 'ذخیره پوشه در دستگاه';
					|it = 'Save directory to device';
					|pl = 'Save directory to device';
					|tr = 'Cihazdaki klasörlerin kaydedilmesi'");
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Use the last used export directory as the "My documents" export directory.
	// 
	DirectoryToSave = FilesOperationsInternalClient.DumpDirectory();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FolderForExportOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	If Not IsBlankString(Item.EditText) Then
		FileSystemClient.OpenExplorer(Item.EditText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FolderForExportStartChoice(Item, ChoiceData, StandardProcessing)
	
	// Open the window of saving folder selection.
	StandardProcessing = False;
	SelectingFile = New FileDialog(FileDialogMode.ChooseDirectory);
	SelectingFile.Multiselect = False;
	SelectingFile.Directory = Item.EditText;
	If SelectingFile.Choose() Then
		DirectoryToSave = SelectingFile.Directory + GetPathSeparator();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveFolder()
	
	If IsBlankString(DirectoryToSave) Or DirectoryToSave = GetPathSeparator() Then
		ShowMessageBox(, NStr("vi = 'Hãy chỉ ra thư mục.';
								|ru = 'Укажите папку.';
								|en = 'Select a directory.'; fa = 'Select a directory.';
								|it = 'Indicate una cartella.';
								|pl = 'Wskaż folder.';
								|tr = 'Klasörü belirleyin.'"));
		Return;
	EndIf;
	
	If Not StrEndsWith(DirectoryToSave, GetPathSeparator()) Then
		DirectoryToSave = DirectoryToSave + GetPathSeparator();
	EndIf;
	
	// Checking if the dump directory exists. Create it if it does not.
	DumpDirectory = New File(DirectoryToSave);
	
	If Not DumpDirectory.Exists() Then
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Chưa tìm thấy thư mục ""%1"".
			           |Chọn một thư mục khác.';
			           |ru = 'Папка ""%1"" не найдена.
			           |Выберите другую папку.';
			           |en = 'Folder ""%1"" is not found.
			           |Please select another folder.'; fa = 'Folder ""%1"" is not found.
			           |Please select another folder.';
			           |it = 'Cartella ""%1"" non è stata trovata.
			           |Selezionare un''altra cartella.';
			           |pl = 'Folder ""%1"" nie został znaleziony.
			           |Wybierz inny folder.';
			           |tr = 'Klasör ""%1"" bulunamadı. 
			           | Başka klasör seçin.'"),
			DirectoryToSave));
		Return;
	EndIf;
	
	FullExportPath = DirectoryToSave + String(WhatToSave) + GetPathSeparator();
	If TransliterateFileAndFolderNames Then
		FullExportPath = StringFunctionsClient.LatinString(FullExportPath);
	EndIf;
	
	// If exported folder does not exist, create it.
	DumpDirectory = New File(FullExportPath);
	If Not DumpDirectory.Exists() Then
		ErrorText = "";
		Try
			CreateDirectory(FullExportPath);
			If Not DumpDirectory.Exists() Then
				Raise NStr("vi = 'Sau khi tạo thành công, chưa tìm thấy thư mục con.';
							|ru = 'После успешного создания подпапка не найдена.';
							|en = 'The created subfolder is not found.'; fa = 'The created subfolder is not found.';
							|it = 'Dopo la creazione riuscita, non è stata trovata una sottocartella.';
							|pl = 'Po pomyślnym utworzeniu podfolder nie znaleziono.';
							|tr = 'Başarı ile oluşturulan alt klasör bulunamadı.'");
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tạo được thư mục con ""%1"" trong thư mục ""%2"" do:
				           |%3';
				           |ru = 'Не удалось создать подкаталог ""%1"" в каталоге ""%2"" по причине:
				           |%3';
				           |en = 'Couldn''t create the subdirectory ""%1"" in the directory ""%2"". Reason:
				           |%3'; fa = 'Couldn''t create the subdirectory ""%1"" in the directory ""%2"". Reason:
				           |%3';
				           |it = 'Couldn''t create the subdirectory ""%1"" in the directory ""%2"". Reason:
				           |%3';
				           |pl = 'Couldn''t create the subdirectory ""%1"" in the directory ""%2"". Reason:
				           |%3';
				           |tr = 'Şu nedenle ""%1"" dizininde ""%2"" alt dizin oluşturulamadı: 
				           |%3'"),
				String(WhatToSave),
				DirectoryToSave,
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
		If ErrorText <> "" Then
			ShowMessageBox(, ErrorText);
			Return;
		EndIf;
	EndIf;
	
	// Receiving the list of exported files.
	GenerateFilesTree(WhatToSave);
	
	// After that start exporting
	Handler = New CallbackDescription("SaveFolderCompletion", ThisObject);
	ProcessFilesTree(Handler, FilesTree, FullExportPath, WhatToSave, Undefined);
EndProcedure

&AtClient
Procedure SaveFolderCompletion(Result, ExecutionParameters) Export
	If Result.Success = True Then
		PathToSave = DirectoryToSave;
		CommonClient.CommonSettingsStorageSave("ExportFolderName", "ExportFolderName",  PathToSave);
		
		ShowUserNotification(NStr("vi = 'Kết xuất thư mục';
									|ru = 'Экспорт папки';
									|en = 'Export folder'; fa = 'پوشه خروجی';
									|it = 'Esportazione della cartella';
									|pl = 'Eksport folderu';
									|tr = 'Klasörü dışa aktar'"),,
		             StringFunctionsClientServer.SubstituteParametersToString(
		               NStr("vi = 'Đã kết xuất thành công thư mục ""%1""
		                          | vào thư mục trên máy tính ""%2"".';
		                          |ru = 'Успешно завершен экспорт папки ""%1""
		                          |в каталог на компьютере ""%2"".';
		                          |en = 'The ""%1"" folder is exported
		                          |to the ""%2"" directory on the computer.'; fa = 'The ""%1"" folder is exported
		                          |to the ""%2"" directory on the computer.';
		                          |it = 'Успешно завершен экспорт папки ""%1""
		                          |в каталог на компьютере ""%2"".';
		                          |pl = 'The ""%1"" folder is exported
		                          |to the ""%2"" directory on the computer.';
		                          |tr = '""%1"" klasörünün ""%2"" bilgisayarındaki
		                          |dizine aktarımı başarıyla tamamlandı.'"),
		               String(WhatToSave), String(DirectoryToSave) ) );
		
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateFilesTree(Val FolderParent)
	
	Query = New Query;
	QueryText =
	"SELECT ALLOWED
	|	Files.FileOwner AS Folder,
	|	CAST(Files.FileOwner AS Catalog.FilesFolders).Description AS FolderDescription,
	|	&CurrentVersion AS CurrentVersion,
	|	Files.Description AS FullDescr,
	|	Files.Extension AS Extension,
	|	Files.Size AS Size,
	|	Files.UniversalModificationDate AS UniversalModificationDate,
	|	Files.Ref AS Ref,
	|	Files.DeletionMark AS DeletionMark,
	|	Files.Encrypted AS Encrypted
	|FROM
	|	Catalog.Files AS Files
	|WHERE
	|	Files.FileOwner IN HIERARCHY(&Ref)
	|	AND Files.DeletionMark = FALSE
	|TOTALS BY
	|	Folder HIERARCHY";
	Query.Parameters.Insert("Ref", FolderParent);
	
	If Not IsBlankString(FilesStorageCatalogName) Then
		
		QueryText = StrReplace(QueryText, "Files", FilesStorageCatalogName);
		QueryText = StrReplace(QueryText, "&CurrentVersion", FilesStorageCatalogName + ".Ref");
		QueryText = StrReplace(QueryText, "FileOwner", "Parent");
		QueryText = StrReplace(QueryText, "FilesFolders", FilesStorageCatalogName);
		
	Else
		
		CurrentVersionChoice = "CASE
		|		WHEN Files.CurrentVersion = VALUE(Catalog.FilesVersions.EmptyRef)
		|			THEN Files.Ref
		|		ELSE ISNULL(Files.CurrentVersion, VALUE(Catalog.FilesVersions.EmptyRef))
		|	END";
		
		QueryText = StrReplace(QueryText, "&CurrentVersion", CurrentVersionChoice);
		
	EndIf;
	
	Query.Text = QueryText;
	Result = Query.Execute();
	
	ExportedTable = Result.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	If TransliterateFileAndFolderNames And ExportedTable.Rows.Count() > 0 Then
		RootFolderForExport = ExportedTable.Rows[0];
		RootFolderForExport.FolderDescription = StringFunctions.LatinString(RootFolderForExport.FolderDescription);
		RootFolderForExport.FullDescr = StringFunctions.LatinString(RootFolderForExport.FullDescr);
		RootFolderForExport.Extension = StringFunctions.LatinString(RootFolderForExport.Extension);
		ChangeNamesOfFilesAndFolders(RootFolderForExport);
	EndIf;
	
	ValueToFormAttribute(ExportedTable, "FilesTree");
	
EndProcedure

// Recursive function that exports files to the computer.
//
// Parameters:
//   HandlerResults_1 - CallbackDescription
//                        - Structure
//                        - Undefined - description of the procedure that receives
//                          the method result.
//   TableOfFiles - FormDataTree
//                 - FormDataTreeItem - value tree with files to export.
//   BaseSaveDirectory - String - a row with the folder name, to which files are saved.
//                 It recreates the folder structure (as in the file tree)
//                 if necessary.
//   ParentFolder - CatalogRef.FilesFolders - items to save.
//   CommonParameters - Structure:
//       * ForAllFiles - Boolean -
//                 True if the user picks an action when overwriting the file and
//                 selects the "For all" check box. No more questions are asked.
//                 False if a question is asked every time a file in the infobase
//                 has the same name as a file on the computer.
//       * BaseAction - DialogReturnCode -
//                 When performing one action for all conflicts
//                 when writing a file (the ForAllFiles parameter is True),
//                 performs the action specified by that parameter.
//                 DialogReturnCode.Yes - Rewrite.
//                 DialogReturnCode.Ignore - Skip a file.
//                 DialogReturnCode.Abort - Cancel export.
//
&AtClient
Procedure ProcessFilesTree(HandlerResults_1, TableOfFiles, BaseSaveDirectory, ParentFolder, CommonParameters)
	
	If CommonParameters = Undefined Then
		CommonParameters = New Structure;
		CommonParameters.Insert("BaseAction", DialogReturnCode.Ignore);
		CommonParameters.Insert("ForAllFiles", False);
		CommonParameters.Insert("NotMetFolderToBeExportedYet", True);
	EndIf;
	
	ExecutionParameters = ExecutionParameters(HandlerResults_1, TableOfFiles, BaseSaveDirectory,
		ParentFolder, CommonParameters);
	
	CompletionHandler = New CallbackDescription("ProcessFilesTree2", ThisObject);
	FilesOperationsInternalClient.RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
	
	StartIterateThroughFilesTree(ExecutionParameters);
EndProcedure

// Returns:
//  Structure:
//   * HandlerResults_1 - See ProcessFilesTree.HandlerResults_1
//   * TableOfFiles - See ProcessFilesTree.TableOfFiles
//   * BaseSaveDirectory - See ProcessFilesTree.BaseSaveDirectory
//   * ParentFolder - See ProcessFilesTree.ParentFolder
//   * CommonParameters - See ProcessFilesTree.CommonParameters
//   * Result - Undefined, DialogReturnCode - is added later
//   * Success - Boolean
//   * Items - See DataProcessor.FilesOperations.
//   * UBound - Number
//   * IndexOf - Number
//   * LoopStartRequired - Boolean
//   * WritingFile - FormDataTreeItem of See DataProcessor.FilesOperations.
//
&AtClient
Function ExecutionParameters(Val HandlerResults_1, Val TableOfFiles, Val BaseSaveDirectory, Val ParentFolder, Val CommonParameters)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("HandlerResults_1", HandlerResults_1);
	ExecutionParameters.Insert("TableOfFiles", TableOfFiles);
	ExecutionParameters.Insert("BaseSaveDirectory", BaseSaveDirectory);
	ExecutionParameters.Insert("ParentFolder", ParentFolder);
	ExecutionParameters.Insert("CommonParameters", CommonParameters);
	
	// Result parameters.
	ExecutionParameters.Insert("Success", False);
	
	// Loop parameters.
	ExecutionParameters.Insert("Items", ExecutionParameters.TableOfFiles.GetItems());
	ExecutionParameters.Insert("UBound", ExecutionParameters.Items.Count()-1);
	ExecutionParameters.Insert("IndexOf",   -1);
	ExecutionParameters.Insert("LoopStartRequired", True);

	ExecutionParameters.Insert("WritingFile", Undefined);

	Return ExecutionParameters;

EndFunction

&AtClient
Procedure StartIterateThroughFilesTree(ExecutionParameters)
	If Not ExecutionParameters.LoopStartRequired Then
		Return;
	EndIf;

	If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
		Return;
	EndIf;
	
	ExecutionParameters.IndexOf = ExecutionParameters.IndexOf + 1;
	ExecutionParameters.LoopStartRequired = False;
	
	For IndexOf = ExecutionParameters.IndexOf To ExecutionParameters.UBound Do
		ExecutionParameters.WritingFile = ExecutionParameters.Items[IndexOf];
		ExecutionParameters.IndexOf = IndexOf;
		ProcessFilesTree1(ExecutionParameters);
		If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
			Return;
		EndIf;
	EndDo;
	
	ExecutionParameters.Success = True;
	FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree1(ExecutionParameters)
	If ExecutionParameters.CommonParameters.NotMetFolderToBeExportedYet = True Then
		If ExecutionParameters.WritingFile.Folder = WhatToSave Then
			ExecutionParameters.CommonParameters.NotMetFolderToBeExportedYet = False;
		EndIf;
	EndIf;
	
	If ExecutionParameters.CommonParameters.NotMetFolderToBeExportedYet = True Then
		
		CompletionHandler = New CallbackDescription("ProcessFilesTree2", ThisObject);
		FilesOperationsInternalClient.RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
		
		ProcessFilesTree(ExecutionParameters, ExecutionParameters.WritingFile, ExecutionParameters.BaseSaveDirectory, 
			ExecutionParameters.WritingFile.Folder, ExecutionParameters.CommonParameters);
		
		If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
			Return;
		EndIf;
		
		ProcessFilesTree2(ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
		Return;
	EndIf;
	
	ProcessFilesTree3(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree2(Result, ExecutionParameters) Export
	If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
		ExecutionParameters.LoopStartRequired = True;
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, False);
	EndIf;
	
	If Result.Success <> True Then
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	StartIterateThroughFilesTree(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree3(ExecutionParameters)
	ExecutionParameters.Insert("SaveFileBaseDirectory", ExecutionParameters.BaseSaveDirectory);
	If ExecutionParameters.WritingFile.Folder <> WhatToSave
		And ExecutionParameters.WritingFile.CurrentVersion = Undefined
		And ExecutionParameters.WritingFile.Folder <> ExecutionParameters.ParentFolder Then
		ExecutionParameters.SaveFileBaseDirectory = ExecutionParameters.SaveFileBaseDirectory
			+ ExecutionParameters.WritingFile.FolderDescription	+ GetPathSeparator();
	EndIf;
	
	Folder = New File(ExecutionParameters.SaveFileBaseDirectory);
	If Not Folder.Exists() Then
		CreateSubdirectory(ExecutionParameters); 
		Return;
	EndIf;
	
	ProcessFilesTree6(ExecutionParameters);
EndProcedure

&AtClient
Procedure CreateSubdirectory(ExecutionParameters)
	ErrorText = "";
	Try
		CreateDirectory(ExecutionParameters.SaveFileBaseDirectory);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể tạo thư mục ""%1"" do:
				|%2';
				|ru = 'Не удалось создать каталог ""%1"" по причине:
				|%2';
				|en = 'Cannot create the ""%1"" directory due to:
				|%2'; fa = 'Cannot create the ""%1"" directory due to:
				|%2';
				|it = 'Не удалось создать каталог ""%1"" по причине:
				|%2';
				|pl = 'Cannot create the ""%1"" directory due to:
				|%2';
				|tr = '""%1"" kataloğu şu sebeple oluşturulamadı:
				|%2'"),
			ExecutionParameters.SaveFileBaseDirectory,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	If ErrorText <> "" Then
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, True);
		Handler = New CallbackDescription("ProcessFilesTree5", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, ErrorText, QuestionDialogMode.AbortRetryIgnore, , DialogReturnCode.Retry);
		Return;
	EndIf;
	
	ProcessFilesTree6(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree5(Response, ExecutionParameters) Export
	If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
		ExecutionParameters.LoopStartRequired = True;
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, False);
	EndIf;
	
	If Response = DialogReturnCode.Abort Then
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; 
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	ElsIf Response = DialogReturnCode.Ignore Then
		ExecutionParameters.Success = True;
		ExecutionParameters.LoopStartRequired = False; 
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	// Trying to create a folder again.
	CreateSubdirectory(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree6(ExecutionParameters)

	SubordinateItems = ExecutionParameters.WritingFile.GetItems();
	If SubordinateItems.Count() > 0 Then
		
		CompletionHandler = New CallbackDescription("ProcessFilesTree7", ThisObject);
		FilesOperationsInternalClient.RegisterCompletionHandler(ExecutionParameters, CompletionHandler);
		
		ProcessFilesTree(ExecutionParameters, ExecutionParameters.WritingFile,
			ExecutionParameters.SaveFileBaseDirectory, ExecutionParameters.WritingFile.Folder,
			ExecutionParameters.CommonParameters);
		
		If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
			Return;
		EndIf;
		
		ProcessFilesTree7(ExecutionParameters.AsynchronousDialog.ResultWhenNotOpen, ExecutionParameters);
		Return;
	EndIf;
	
	ProcessFilesTree8(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree7(Result, ExecutionParameters) Export
	
	If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
		ExecutionParameters.LoopStartRequired = True;
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, False);
	EndIf;
	
	If Result.Success <> True Then
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False;
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	EndIf;
	
	// Continue processing the item.
	ProcessFilesTree8(ExecutionParameters);
	
	// Restart if the dialog was open.
	StartIterateThroughFilesTree(ExecutionParameters);
	
EndProcedure

&AtClient
Procedure ProcessFilesTree8(ExecutionParameters)
	If (ExecutionParameters.WritingFile.CurrentVersion <> Undefined
		And ExecutionParameters.WritingFile.CurrentVersion.IsEmpty()) Or ExecutionParameters.WritingFile.CurrentVersion = Undefined Then
		// This is an item of Files catalog without a file. Skip it.
		Return;
	EndIf;
	
	// Writing file to the base directory.
	ExecutionParameters.Insert("FileNameWithExtension", Undefined);
	ExecutionParameters.FileNameWithExtension = CommonClientServer.GetNameWithExtension(
		ExecutionParameters.WritingFile.FullDescr,
		ExecutionParameters.WritingFile.Extension);
		
	CommonInternalClient.ShortenFileName(ExecutionParameters.FileNameWithExtension);
	
	If ExecutionParameters.WritingFile.Encrypted Then
		ExecutionParameters.FileNameWithExtension = ExecutionParameters.FileNameWithExtension + "." + EncryptedFilesExtension;
	EndIf;
	ExecutionParameters.Insert("FullFileName", ExecutionParameters.SaveFileBaseDirectory + ExecutionParameters.FileNameWithExtension);
	
	ExecutionParameters.Insert("Result", Undefined);
	ProcessFilesTree9(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree9(ExecutionParameters)
	ExecutionParameters.Insert("FileOnHardDrive", New File(ExecutionParameters.FullFileName));
	If ExecutionParameters.FileOnHardDrive.Exists() And ExecutionParameters.FileOnHardDrive.IsDirectory() Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Thay thế tệp này
			           |""%1""
			           |có một thư mục có cùng tên.
			           |
			           |Kết xuất lại tệp này?';
			           |ru = 'Вместо файла
			           |""%1""
			           |существует папка с таким же именем.
			           |
			           |Повторить экспорт этого файла?';
			           |en = 'A file named
			           |""%1""
			           |is found instead of a folder.
			           |
			           |Do you want to download the file again?'; fa = 'A file named
			           |""%1""
			           |is found instead of a folder.
			           |
			           |Do you want to download the file again?';
			           |it = 'Al posto del file
			           |""%1""
			           |esiste già una cartella con lo stesso nome.
			           |
			           | Ripetere l''esportazione di questo file?';
			           |pl = 'Zamiast pliku
			           |""%1""
			           |istnieje folder z takim imieniem.
			           |
			           |Powtórzyć eksport tego pliku?';
			           |tr = '""%1""
			           |dosyasıyla aynı ada sahip klasör zaten var. 
			           |
			           |
			           |Dosya dışa aktarımı tekrarlansın mı?'"),
			ExecutionParameters.FullFileName);
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, True);
		Handler = New CallbackDescription("ProcessFilesTree10", ThisObject, ExecutionParameters);
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.RetryCancel, , DialogReturnCode.Cancel);
		Return;
	EndIf;
	
	// There is no file, proceed to the next step.
	ExecutionParameters.Result = DialogReturnCode.Retry;
	ProcessFilesTree11(ExecutionParameters);
EndProcedure

// Parameters:
//  Response - DialogReturnCode
//  ExecutionParameters - See ExecutionParameters
//
&AtClient
Procedure ProcessFilesTree10(Response, ExecutionParameters) Export
	If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
		ExecutionParameters.LoopStartRequired = True;
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, False);
	EndIf;
	
	If Response = DialogReturnCode.Retry Then
		// Ignore the file.
		ProcessFilesTree9(ExecutionParameters);
		Return;
	EndIf;
	
	// Continue processing the item.
	ExecutionParameters.Result = DialogReturnCode.Cancel;
	ProcessFilesTree11(ExecutionParameters);
	
	// Restart if the dialog was open.
	StartIterateThroughFilesTree(ExecutionParameters);
EndProcedure

// Parameters:
//  ExecutionParameters - See ExecutionParameters
//
&AtClient
Procedure ProcessFilesTree11(ExecutionParameters)
	If ExecutionParameters.Result = DialogReturnCode.Cancel Then
		// Ignoring the file named like a folder.
		Return;
	EndIf;
	
	ExecutionParameters.Result = DialogReturnCode.No;
	
	// Asking what to do with the current file.
	If ExecutionParameters.FileOnHardDrive.Exists() Then
		
		// If the file is for reading only and the change time is less than in the infobase, simply rewrite it.
		If  ExecutionParameters.FileOnHardDrive.GetReadOnly()
			And ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime() <= ExecutionParameters.WritingFile.UniversalModificationDate Then
			ExecutionParameters.Result = DialogReturnCode.Yes;
		Else
			If Not ExecutionParameters.CommonParameters.ForAllFiles Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong thư mục ""%1""
					           |đã có tệp ""%2""
					           |kích thước của tệp hiện có = %3 byte, ngày sửa đổi %4.
					           |kích thước của tệp đã lưu = %5 byte, ngày sửa đổi %6.
					           |
					           |Thay thế tệp hiện có bằng tệp từ kho lưu trữ tệp?';
					           |ru = 'В каталоге ""%1""
					           |существует файл ""%2""
					           |размер существующего файла = %3 байт, дата изменения %4.
					           |размер сохраняемого файла = %5 байт, дата изменения %6.
					           |
					           |Заменить существующий файл файлом из приложения?';
					           |en = 'Directory ""%1""
					           |contains file ""%2"".
					           |The existing file size is %3 bytes, last modified on %4.
					           |The stored file size is %5 bytes, last modified on %6.
					           |
					           |Do you want to overwrite the existing file with the file from the application?'; fa = 'Directory ""%1""
					           |contains file ""%2"".
					           |The existing file size is %3 bytes, last modified on %4.
					           |The stored file size is %5 bytes, last modified on %6.
					           |
					           |Do you want to overwrite the existing file with the file from the application?';
					           |it = 'Directory ""%1""
					           |contains file ""%2"".
					           |The existing file size is %3 bytes, last modified on %4.
					           |The stored file size is %5 bytes, last modified on %6.
					           |
					           |Do you want to overwrite the existing file with the file from the application?';
					           |pl = 'Directory ""%1""
					           |contains file ""%2"".
					           |The existing file size is %3 bytes, last modified on %4.
					           |The stored file size is %5 bytes, last modified on %6.
					           |
					           |Do you want to overwrite the existing file with the file from the application?';
					           |tr = 'Dizin ""%1"" zaten ""
					           | "" %3 dosyasını içermektedir, mevcut dosyanın boyutu = 
					           |bayt, değiştirme tarihi %2. %4 kaydedilmiş dosyanın boyutu =
					           | bayt, değiştirme tarihi %5. %6
					           |
					           |Varolan dosya uygulamadan bir dosya ile değiştirilsin mi?'"),
					ExecutionParameters.SaveFileBaseDirectory,
					ExecutionParameters.FileNameWithExtension,
					ExecutionParameters.FileOnHardDrive.Size(),
					ToLocalTime(ExecutionParameters.FileOnHardDrive.GetModificationUniversalTime()),
					ExecutionParameters.WritingFile.Size,
					ToLocalTime(ExecutionParameters.WritingFile.UniversalModificationDate));
				
				ParametersStructure = New Structure;
				ParametersStructure.Insert("MessageText",   MessageText);
				ParametersStructure.Insert("ApplyForAll", ExecutionParameters.CommonParameters.ForAllFiles);
				ParametersStructure.Insert("BaseAction",  String(ExecutionParameters.CommonParameters.BaseAction));
				
				FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, True);
				Handler = New CallbackDescription("ProcessFilesTree12", ThisObject, ExecutionParameters);
				
				OpenForm("DataProcessor.FilesOperations.Form.FileExists", ParametersStructure, , , , , Handler);
				Return;
			EndIf;
			
			ExecutionParameters.Result = ExecutionParameters.CommonParameters.BaseAction;
			ProcessFilesTree13(ExecutionParameters);
			Return;
		EndIf;
	EndIf;
	
	// If there is no file, do not ask.
	ExecutionParameters.Result = DialogReturnCode.Yes;
	ProcessFilesTree14(ExecutionParameters);
EndProcedure

// Parameters:
//  Result - DialogReturnCode
//  ExecutionParameters - See ExecutionParameters
//
&AtClient
Procedure ProcessFilesTree12(Result, ExecutionParameters) Export
	If FilesOperationsInternalClient.LockingFormOpen(ExecutionParameters) Then
		ExecutionParameters.LoopStartRequired = True;
		FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, False);
	EndIf;
	
	ExecutionParameters.Result = Result.ReturnCode;
	ExecutionParameters.CommonParameters.ForAllFiles = Result.ApplyForAll;
	ExecutionParameters.CommonParameters.BaseAction = ExecutionParameters.Result;
	
	// Continue processing the item.
	ProcessFilesTree13(ExecutionParameters);
	
	// Restart loop if an asynchronous dialog box was opened.
	StartIterateThroughFilesTree(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree13(ExecutionParameters)
	If ExecutionParameters.Result = DialogReturnCode.Abort Then
		// Abort export.
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Loop restart is not required.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	ElsIf ExecutionParameters.Result = DialogReturnCode.Ignore Then
		// Skip the file.
		Return;
	EndIf;
	
	// Writing file to the file system if it is possible.
	If ExecutionParameters.Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ProcessFilesTree14(ExecutionParameters);
EndProcedure

&AtClient
Procedure ProcessFilesTree14(ExecutionParameters)

	ExecutionParameters.FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	If ExecutionParameters.FileOnHardDrive.Exists() Then
		ExecutionParameters.FileOnHardDrive.SetReadOnly(False);
		
		// Always delete and then generate again.
		ErrorInfo = Undefined;
		Try
			DeleteFiles(ExecutionParameters.FullFileName);
		Except
			ErrorInfo = ErrorInfo();
		EndTry;
		
		If ErrorInfo <> Undefined Then
			ProcessFilesTree15(ErrorInfo, ExecutionParameters);
			Return;
		EndIf;
	EndIf;
	
	// Re-write the file.
	FileAddressToOpen = FilesOperationsInternalServerCall.GetURLToOpen(
		ExecutionParameters.WritingFile.CurrentVersion,
		UUID);
	
	Try
		FilesToObtain  = New Array;
		FileToPass = New TransferableFileDescription();
		ObtainedFiles  = New Array;// Array of File

		FileToPass.Location = FileAddressToOpen;
		FileToPass.Name      = ExecutionParameters.FullFileName;
		FilesToObtain.Add(FileToPass);
		
		GetFiles(FilesToObtain, ObtainedFiles, ExecutionParameters.SaveFileBaseDirectory, False);
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	If ErrorInfo <> Undefined Then
		ProcessFilesTree15(ErrorInfo, ExecutionParameters);
		Return;
	EndIf;
		
	If ObtainedFiles.Count() = 0 
		Or IsBlankString(ObtainedFiles[0].Name) Then
		// File was not received.
		Return;
	EndIf;
	
	// For the option of storing files in volumes, delete the file from the temporary storage after receiving it.
	If IsTempStorageURL(FileAddressToOpen) Then
		DeleteFromTempStorage(FileAddressToOpen);
	EndIf;
	
	ExecutionParameters.FileOnHardDrive = New File(ExecutionParameters.FullFileName);
	
	Try
		ExecutionParameters.FileOnHardDrive.SetReadOnly(True);
		// Setting the modification time as in the infobase.
		ExecutionParameters.FileOnHardDrive.SetModificationUniversalTime(
			ExecutionParameters.WritingFile.UniversalModificationDate);
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	
	If ErrorInfo <> Undefined Then
		ProcessFilesTree15(ErrorInfo, ExecutionParameters);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessFilesTree15(ErrorInfo, ExecutionParameters)
	// An error occurred when writing the file and changing its attributes.
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không thể ghi lại tệp
		           |""%1""
		           |do nguyên nhân:
		           |%2';
		           |ru = 'Не удалось записать файл
		           |""%1""
		           |по причине:
		           |%2';
		           |en = 'Cannot save the file
		           |""%1""
		           |due to:
		           |%2'; fa = 'Cannot save the file
		           |""%1""
		           |due to:
		           |%2';
		           |it = 'Не удалось записать файл
		           |""%1""
		           |по причине:
		           |%2';
		           |pl = 'Cannot save the file
		           |""%1""
		           |due to:
		           |%2';
		           |tr = '""%1""
		           |dosyası şu sebeple 
		           |kaydedilemedi:
		           |%2'"),
		ExecutionParameters.FullFileName,
		ErrorProcessing.BriefErrorDescription(ErrorInfo));
	
	FilesOperationsInternalClient.SetLockingFormFlag(ExecutionParameters, True);
	Handler = New CallbackDescription("ProcessFilesTree16", ThisObject, ExecutionParameters);
	
	ShowQueryBox(Handler, QueryText, QuestionDialogMode.AbortRetryIgnore, , DialogReturnCode.Retry);
EndProcedure

&AtClient
Procedure ProcessFilesTree16(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		// Just exit with an error.
		ExecutionParameters.Success = False;
		ExecutionParameters.LoopStartRequired = False; // Do not restart the cycle.
		// False.
		FilesOperationsInternalClient.ReturnResult(ExecutionParameters.HandlerResults_1, ExecutionParameters);
		Return;
	ElsIf Response = DialogReturnCode.Ignore Then
		// Skipping this file and proceeding to the next step.
		Return;
	EndIf;
	
	// Trying to create a folder again.
	ProcessFilesTree14(ExecutionParameters);
EndProcedure

&AtServer
Procedure ChangeNamesOfFilesAndFolders(TreeItem)
	
	For Each FileOrFolder In TreeItem.Rows Do
		FileOrFolder.FolderDescription = StringFunctions.LatinString(FileOrFolder.FolderDescription);
		FileOrFolder.FullDescr = StringFunctions.LatinString(FileOrFolder.FullDescr);
		FileOrFolder.Extension = StringFunctions.LatinString(FileOrFolder.Extension);
		ChangeNamesOfFilesAndFolders(FileOrFolder);
	EndDo;
	
EndProcedure;

#EndRegion
