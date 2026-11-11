///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not HasFilesInVolumes() Then
		ShowMessageBox(, NStr("vi = 'Không có tệp trong các quyển.';
								|ru = 'Файлы в томах отсутствуют.';
								|en = 'No files in volumes.'; fa = 'No files in volumes.';
								|it = 'I file sono mancanti nei tomi.';
								|pl = 'Brak plików w woluminach.';
								|tr = 'Ciltlerde dosyalar yok.'"));
		Return;
	EndIf;
	
	OpenForm("CommonForm.SelectPathToVolumeFilesArchive", , CommandExecuteParameters.Source);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function HasFilesInVolumes()
	
	Return FilesOperationsInternal.HasFilesInVolumes();
	
EndFunction

#EndRegion
