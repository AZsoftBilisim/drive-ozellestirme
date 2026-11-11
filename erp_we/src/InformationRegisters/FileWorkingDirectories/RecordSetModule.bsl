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

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.IsRecordSetDeletion(Replacing) Then
		Return;
	EndIf;
	
	If Count() = 1 Then
		FileWorkingDirectory = Get(0);
		Folder = FileWorkingDirectory.Folder;
		Path = FileWorkingDirectory.Path;
		SetWorkingDirectory(Folder, Path);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetWorkingDirectory(Val Folder, Val PathOfWorkingDirectory)

	If IsBlankString(PathOfWorkingDirectory) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	FilesFolders.Ref,
		|	FilesFolders.Description
		|FROM
		|	Catalog.FilesFolders AS FilesFolders
		|WHERE
		|	FilesFolders.Parent = &Ref";
	
	Query.SetParameter("Ref", Folder);
	
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		WorkingDirectory = CommonClientServer.AddLastPathSeparator(PathOfWorkingDirectory)
			+ Selection.Description;
		WorkingDirectory = CommonClientServer.AddLastPathSeparator(WorkingDirectory);
		FilesOperationsInternal.SaveFolderWorkingDirectory(Selection.Ref, WorkingDirectory);
	EndDo;
		
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