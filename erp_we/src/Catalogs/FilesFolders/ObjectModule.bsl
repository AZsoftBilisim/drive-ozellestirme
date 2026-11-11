///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.SetLockBeforeWriteToFileIB(, True);
	EndIf;
	
	FieldsNames = "Description, Parent, DeletionMark";
	CurrentFolder = ?(IsNew(), New Structure(FieldsNames),
		Common.ObjectAttributesValues(Ref, FieldsNames));
	
	If Ref = PredefinedValue("Catalog.FilesFolders.Templates")
		And CurrentFolder.Parent <> Catalogs.FilesFolders.EmptyRef() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cấm di chuyển thư mục ""%1"".';
					|ru = 'Запрещено перемещать папку ""%1"".';
					|en = 'Cannot move folder ""%1"".'; fa = 'Cannot move folder ""%1"".';
					|it = 'Vietato spostare la cartella ""%1""';
					|pl = 'Przemieszczenie folderu ""%1"" jest zabronione.';
					|tr = '""%1"" klasörüne taşıma yasak.'"), CurrentFolder.Description);
	EndIf;
	
	If IsNew() Or CurrentFolder.Parent <> Parent Then
		// Check rights for the source folder.
		If Not FilesOperationsInternal.HasRight("FoldersModification", CurrentFolder.Parent) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đủ quyền để chuyển từ thư mục tệp ""%1"".';
					|ru = 'Недостаточно прав для перемещения из папки файлов ""%1"".';
					|en = 'Insufficient rights to move files from the ""%1"" folder.'; fa = 'Insufficient rights to move files from the ""%1"" folder.';
					|it = 'Permessi insufficienti per lo spostamento dalla cartella dei file ""%1"".';
					|pl = 'Niewystarczające uprawnienia do przemieszczenia z folderu plików ""%1"".';
					|tr = '""%1"" dosya klasörünü taşımak için yetkiler yetersiz.'"),
				?(ValueIsFilled(CurrentFolder.Parent), CurrentFolder.Parent, NStr("vi = 'Thư mục';
																					|ru = 'Папки';
																					|en = 'Folders'; fa = 'پوشه‌ها';
																					|it = 'Папки';
																					|pl = 'Folders';
																					|tr = 'Klasörler'")));
			Raise(MessageText, ErrorCategory.AccessViolation);
		EndIf;
		// Check rights for the destination folder.
		If Not FilesOperationsInternal.HasRight("FoldersModification", Parent) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đủ quyền để thêm thư mục con vào thư mục tệp ""%1"".';
					|ru = 'Недостаточно прав для добавления подпапок в папку файлов ""%1"".';
					|en = 'Insufficient rights to add subfolders to the ""%1"" folder.'; fa = 'Insufficient rights to add subfolders to the ""%1"" folder.';
					|it = 'Permessi insufficienti per l''aggiunta di sottocartelle nella cartella dei file ""%1"".';
					|pl = 'Niewystarczające uprawnienia do dodawania podfolderów do folderu plików ""%1"".';
					|tr = '""%1"" dosya klasörüne alt klasörleri eklemek için yetkiler yetersiz'"),
				?(ValueIsFilled(Parent), Parent, NStr("vi = 'Thư mục';
														|ru = 'Папки';
														|en = 'Folders'; fa = 'پوشه‌ها';
														|it = 'Папки';
														|pl = 'Folders';
														|tr = 'Klasörler'")));
			Raise(MessageText, ErrorCategory.AccessViolation);
		EndIf;
	EndIf;
	
	If DeletionMark And CurrentFolder.DeletionMark <> True Then
		// Check the "Deletion mark" right.
		If Not FilesOperationsInternal.HasRight("FoldersModification", Ref) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đủ quyền để thay đổi thư mục tệp ""%1"".';
					|ru = 'Недостаточно прав для изменения папки файлов ""%1"".';
					|en = 'Insufficient rights to change the ""%1"" file folder.'; fa = 'Insufficient rights to change the ""%1"" file folder.';
					|it = 'Permessi insufficienti per la modifica della cartella dei file ""%1"".';
					|pl = 'Niewystarczające uprawnienia do zmiany folderu plików ""%1"".';
					|tr = '""%1"" dosya klasörünü değiştirmek için yetkiler yetersiz.'"),
				String(Ref));
			Raise(MessageText, ErrorCategory.AccessViolation);
		EndIf;
	EndIf;
	
	If DeletionMark <> CurrentFolder.DeletionMark And Not Ref.IsEmpty() Then
		// Filter files and try to mark them for deletion.
		Query = New Query;
		Query.Text = 
			"SELECT
			|	Files.Ref,
			|	Files.BeingEditedBy
			|FROM
			|	Catalog.Files AS Files
			|WHERE
			|	Files.FileOwner = &Ref";
		
		Query.SetParameter("Ref", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			If ValueIsFilled(Selection.BeingEditedBy) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không thể xóa thư mục %1, bởi vì nó có tệp ""%2"" đang bị chiếm để soạn.';
						|ru = 'Папку %1 нельзя удалить, т.к. она содержит файл ""%2"", занятый для редактирования.';
						|en = 'Cannot delete the %1 folder as it contains the ""%2"" file that is locked for editing.'; fa = 'Cannot delete the %1 folder as it contains the ""%2"" file that is locked for editing.';
						|it = 'Impossibile cancellare la cartella %1 poiché essa contiene il file ""%2"", correntemente in corso di modifica.';
						|pl = 'Folder %1 nie może zostać usunięty, ponieważ zawiera on plik ""%2"", zajęty do edycji.';
						|tr = 'Klasör %1, düzenleme için kilitli olan ""%2"" dosyasını içerdiğinden silinemez.'"),
				    String(Ref), String(Selection.Ref));
			EndIf;

			FileObject1 = Selection.Ref.GetObject();
			FileObject1.Lock();
			FileObject1.SetDeletionMark(DeletionMark);
		EndDo;
	EndIf;
	
	AdditionalProperties.Insert("PreviousIsNew", IsNew());
	
	If Not IsNew() Then
		If Description <> CurrentFolder.Description Then // The renamed directory.
			UpdateWorkingDirWhenFolderRenamed(Ref, CurrentFolder);
		EndIf;
		
		If Parent <> CurrentFolder.Parent Then // Moved to a different directory.
			UpdateWorkingDirWhenFolderMoved(Ref, Parent, CurrentFolder);
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	WorkingDirectory = Undefined;
	If AdditionalProperties.Property("WorkingDirectory", WorkingDirectory) 
		Or AdditionalProperties.PreviousIsNew Then
		
		If WorkingDirectory = "" Then
			FilesOperationsInternal.CleanUpWorkingDirectory(Ref);
		ElsIf WorkingDirectory <> Undefined Then
			FilesOperationsInternal.SaveFolderWorkingDirectory(Ref, WorkingDirectory);
		Else
			FolderWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(Parent);
			If FolderWorkingDirectory <> "" Then
				FolderWorkingDirectory = CommonClientServer.AddLastPathSeparator(FolderWorkingDirectory) 
					+ Description + GetPathSeparator();
				FilesOperationsInternal.SaveFolderWorkingDirectory(Ref, FolderWorkingDirectory);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	CreationDate = CurrentSessionDate();
	EmployeeResponsible = Users.AuthorizedUser();
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	InvalidChars = CommonClientServer.FindProhibitedCharsInFileName(Description);
	If InvalidChars.Count() <> 0 Then
		Cancel = True;
		
		Text = NStr("vi = 'Tên gọi thư mục có ký tự bị cấm ( \ / : * ? "" < > | .. )';
					|ru = 'Наименование папки содержит запрещенные символы ( \ / : * ? "" < > | .. )';
					|en = 'The folder name contains characters that are not allowed ( \ / : * ? "" < > | .. )'; fa = 'The folder name contains characters that are not allowed ( \ / : * ? "" < > | .. )';
					|it = 'Il nome della cartella contiene simboli non permessi ( \ / : * ? "" < > | .. )';
					|pl = 'Nazwa folderu zawiera niedozwolone znaki (/: *? ”<> | ..)';
					|tr = 'Klasör adı yasaklanmış karakterler içeriyor ( /: *? ""< >| ..)'");
		Common.MessageToUser(Text, ThisObject, "Description");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure UpdateWorkingDirWhenFolderRenamed(Var_Ref, CurrentFolder)
	FolderWorkingDirectory         = FilesOperationsInternalServerCall.FolderWorkingDirectory(Var_Ref);
	FolerParentWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(CurrentFolder.Parent);
	If FolerParentWorkingDirectory <> "" Then
		
		FolerParentWorkingDirectory = CommonClientServer.AddLastPathSeparator(
			FolerParentWorkingDirectory);
		InheritedFolerWorkingDirectoryPrevious = FolerParentWorkingDirectory + CurrentFolder.Description
			+ GetPathSeparator();
			
		If InheritedFolerWorkingDirectoryPrevious = FolderWorkingDirectory Then
			NewFolderWorkingDirectory = FolerParentWorkingDirectory + Description + GetPathSeparator();
			FilesOperationsInternal.SaveFolderWorkingDirectory(Var_Ref, NewFolderWorkingDirectory);
		EndIf;
	EndIf;
EndProcedure

Procedure UpdateWorkingDirWhenFolderMoved(Var_Ref, Var_Parent, CurrentFolder)

	FolderWorkingDirectory               = FilesOperationsInternalServerCall.FolderWorkingDirectory(Var_Ref);
	FolerParentWorkingDirectory       = FilesOperationsInternalServerCall.FolderWorkingDirectory(CurrentFolder.Parent);
	NewFolderParentWorkingDirectory = FilesOperationsInternalServerCall.FolderWorkingDirectory(Var_Parent);
	
	If FolerParentWorkingDirectory <> "" Or NewFolderParentWorkingDirectory <> "" Then
		
		InheritedFolerWorkingDirectoryPrevious = FolerParentWorkingDirectory;
		If FolerParentWorkingDirectory <> "" Then
			InheritedFolerWorkingDirectoryPrevious = FolerParentWorkingDirectory + CurrentFolder.Description
				+ GetPathSeparator();
		EndIf;
		
		// Working directory is created automatically from a parent.
		If InheritedFolerWorkingDirectoryPrevious = FolderWorkingDirectory Then
			If NewFolderParentWorkingDirectory <> "" Then
				NewFolderWorkingDirectory = NewFolderParentWorkingDirectory + Description 
					+ GetPathSeparator();
				FilesOperationsInternal.SaveFolderWorkingDirectory(Var_Ref, NewFolderWorkingDirectory);
			Else
				FilesOperationsInternal.CleanUpWorkingDirectory(Var_Ref);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf