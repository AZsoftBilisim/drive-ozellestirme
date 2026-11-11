///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private
	
// Returns:
//  Structure:
//   * Action - String
//   * MoveToVolume - Boolean
//   * DestinationStorageVolume - CatalogRef.FileStorageVolumes
// 
Function FileTransferOptions() Export
	Result = New Structure("Action,MoveToVolume,DestinationStorageVolume");
	Return Result;
EndFunction

// Parameters:
//  FilesToTransfer - ValueTable
//  Parameters - See FileTransferOptions
// 
// Returns:
//  Structure:
//    * FilesTransferred - Number
//    * TransferErrors - Array of See TransferError
//
Function ExecuteFileTransfer(FilesToTransfer, Parameters) Export

	TransferErrors = New Array;

	If Parameters.Action = "MoveBetweenVolumes" Then
		ActionForLog = NStr("vi = 'giữa các quyển trên server.';
							|ru = 'между томами на сервере.';
							|en = 'between volumes on a server.'; fa = 'between volumes on a server.';
							|it = 'между томами на сервере.';
							|pl = 'between volumes on a server.';
							|tr = 'sunucudaki birimler arasında.'");
	ElsIf Parameters.Action = "MoveToVolumes" Then
		ActionForLog = NStr("vi = 'vào quyển trên server.';
							|ru = 'в тома на сервере.';
							|en = 'to volume on a server.'; fa = 'to volume on a server.';
							|it = 'в тома на сервере.';
							|pl = 'to volume on a server.';
							|tr = 'sürücüdeki birimlere'")
	Else
		ActionForLog = NStr("vi = 'đến cơ sở thông tin.';
							|ru = 'в информационную базу.';
							|en = 'to the infobase.'; fa = 'to the infobase.';
							|it = 'nel database.';
							|pl = 'do bazy informacyjnej.';
							|tr = 'infobase''e'")
	EndIf;
	
	WriteLogEvent(NStr("vi = 'Tệp.Bắt đầu chuyển tệp.';
						|ru = 'Файлы.Начало переноса файлов.';
						|en = 'Files.Start moving files.'; fa = 'Files.Start moving files.';
						|it = 'File. Inizio di sposamento file.';
						|pl = 'Pliki. Rozpoczęcie przeniesienia plików.';
						|tr = 'Dosyalar. Dosyaları aktarmaya başlama.'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,,,
		NStr("vi = 'Bắt đầu chuyển tệp';
			|ru = 'Начат перенос файлов';
			|en = 'Started moving files'; fa = 'Started moving files';
			|it = 'Lo spostamento dei file iniziato';
			|pl = 'Rozpoczęto przeniesienie plików';
			|tr = 'Dosya aktarımı başladı'") + " " + ActionForLog);
	
	FilesToMoveCount = FilesToTransfer.Count();
	
	VolumeProperties = New Structure("VolumePath, MaxVolumeSize");
	VolumeProperties.Insert("CurrentVolumeSize", 0);
	If Parameters.MoveToVolume Then
		VolumeProperties.VolumePath = FilesOperationsInVolumesInternal.FullVolumePath(Parameters.DestinationStorageVolume);
		VolumeProperties.CurrentVolumeSize = FilesOperationsInVolumesInternal.VolumeSize(Parameters.DestinationStorageVolume);
		VolumeProperties.MaxVolumeSize = 1024*1024 * Common.ObjectAttributeValue(
			Parameters.DestinationStorageVolume, "MaximumSize");
	EndIf;
	
	FilesTransferred = 0;
	For Each File In FilesToTransfer Do
		TransferFile(File, VolumeProperties, Parameters, TransferErrors, FilesTransferred);
	EndDo;
	
	RecordOnCompletionText = NStr("vi = 'Đã hoàn thành chuyển tệp %1
		|Đã chuyển: %2 tệp';
		|ru = 'Завершен перенос файлов %1
		|Перенесено файлов: %2';
		|en = 'The files are moved %1
		|Total files: %2'; fa = 'The files are moved %1
		|Total files: %2';
		|it = 'Lo sposamento dei file %1
		| completato File trasferiti: %2';
		|pl = 'Zakończono przenoszenie plików %1
		|Przeniesiono plików: %2';
		|tr = 'Dosya aktarımı tamamlandı%1
		|Aktarılan dosyalar:%2'");
	
	RecordOnCompletionText = StringFunctionsClientServer.SubstituteParametersToString(
		RecordOnCompletionText, ActionForLog, Format(FilesTransferred, "NZ=0; NG="));
	
	If FilesTransferred < FilesToMoveCount Then
		RecordOnCompletionText = RecordOnCompletionText + "
			|" + NStr("vi = 'Số lượng lỗi khi chuyển: %1';
						|ru = 'Количество ошибок при переносе: %1';
						|en = 'Total errors: %1.'; fa = 'Total errors: %1.';
						|it = 'Il numero di errori durante il trasferimento: %1';
						|pl = 'Ilość błędów podczas transferu: %1';
						|tr = 'Transfer hataların sayısı: %1'");
		RecordOnCompletionText = StringFunctionsClientServer.SubstituteParametersToString(
			RecordOnCompletionText, Format(FilesToMoveCount - FilesTransferred, "NZ=0; NG="));
	EndIf;
	
	WriteLogEvent(NStr("vi = 'Tệp.Hoàn thành việc chuyển tệp.';
						|ru = 'Файлы.Завершение переноса файлов.';
						|en = 'Files.End moving files.'; fa = 'Files.End moving files.';
						|it = 'File. Completamento di spostamento dei file.';
						|pl = 'Pliki. Zakończenie przeniesienia plików.';
						|tr = 'Dosyalar. Dosya aktarımının tamamlanması.'", Common.DefaultLanguageCode()),
		EventLogLevel.Information,,, RecordOnCompletionText);
	
	Return New Structure("FilesTransferred,TransferErrors", FilesTransferred, TransferErrors);
	
EndFunction	

// Parameters:
//   File             - CatalogObject
//   VolumeProperties     - Structure
//   Parameters        - See FileTransferOptions
//   TransferErrors   - Array of See TransferError
//   FilesTransferred - Number
//
Procedure TransferFile(File, VolumeProperties, Parameters, TransferErrors, FilesTransferred)
	
	FileRef = File.Ref;
	FileProperties = Common.ObjectAttributesValues(FileRef, "Description, Extension, Size");
	
	BeginTransaction();
	Try

		Block = New DataLock;
		DataLockItem = Block.Add(FileRef.Metadata().FullName());
		DataLockItem.SetValue("Ref", FileRef);
		Block.Lock();
		
		FileObject1 = FileRef.GetObject();

		ThrowAnExceptionWhenTheVolumeSizeIsExceeded(VolumeProperties, FileObject1, Parameters);
		
		If Parameters.Action = "MoveBetweenVolumes" Then
			MoveBetweenVolumes(FileObject1, VolumeProperties, Parameters);
		ElsIf Parameters.Action = "MoveToVolumes" Then
			MoveToVolumes(FileObject1, VolumeProperties, Parameters);
		ElsIf Parameters.Action = "MoveToInfobase" Then
			MoveToInfobase(FileObject1, VolumeProperties, Parameters);
		Else
			Raise NStr("vi = 'Giao dịch không được hỗ trợ.';
						|ru = 'Неподдерживаемая операция.';
						|en = 'Unsupported operation.'; fa = 'Unsupported operation.';
						|it = 'Operazione non supportata.';
						|pl = 'Nieobsługiwana operacja.';
						|tr = 'Desteklenmeyen işlem.'");
		EndIf;
		
		FilesTransferred = FilesTransferred + 1;
		VolumeProperties.CurrentVolumeSize = VolumeProperties.CurrentVolumeSize + FileProperties.Size;
		
		CommitTransaction();

	Except
	
		RollbackTransaction();

		NameForLog = CommonClientServer.GetNameWithExtension(FileProperties.Description,
			FileProperties.Extension);
		
		Error = TransferError(FileRef, ErrorInfo());
		Error.FileName = NameForLog;
		TransferErrors.Add(Error);
		
		WriteLogEvent(NStr("vi = 'Tệp.Lỗi chuyển tệp.';
							|ru = 'Файлы.Ошибка переноса файла.';
							|en = 'Files.File moving error.'; fa = 'Files.File moving error.';
							|it = 'File. Errore di spostamento dei file.';
							|pl = 'Pliki. Błąd przenoszenia pliku.';
							|tr = 'Dosyalar. Dosya aktarım hatası.'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,, FileRef,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể chuyển tệp %1
				|%2
				|do:
				|%3"".';
				|ru = 'Не удалось перенести файл %1
				|%2
				|по причине:
				|%3"".';
				|en = 'Couldn''t move file %1
				|%2
				|due to:
				|%3"".'; fa = 'Couldn''t move file %1
				|%2
				|due to:
				|%3"".';
				|it = 'Не удалось перенести файл %1
				|%2
				|по причине:
				|%3"".';
				|pl = 'Couldn''t move file %1
				|%2
				|due to:
				|%3"".';
				|tr = '%1
				|%2
				|dosyası şu nedenle aktarılamadı:
				|%3"".'"),
				Common.SubjectString(FileRef), 
				NameForLog, Error.DetailErrorDescription));

	EndTry;
	
EndProcedure

Procedure MoveBetweenVolumes(FileObject1, VolumeProperties, Parameters)
	FileProperties = FilesOperationsInVolumesInternal.FilePropertiesInVolume();
	FillPropertyValues(FileProperties, FileObject1);
	If TypeOf(FileObject1) = Type("CatalogObject.FilesVersions") Then
		FileProperties.FileOwner = Common.ObjectAttributeValue(
		FileObject1.Owner, "FileOwner");
	EndIf;
	
	CurrentFilePath = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties);
	
	FileOnHardDrive = New File(CurrentFilePath);
	If Not FileOnHardDrive.Exists() Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không tìm thấy tệp ""%1"".';
			|ru = 'Файл ""%1"" не найден.';
			|en = 'File ""%1"" is not found.'; fa = 'File ""%1"" is not found.';
			|it = 'File ""%1"" non trovato.';
			|pl = 'Nie znaleziono pliku ""%1"".';
			|tr = '""%1"" dosya bulunmadı.'"), CurrentFilePath);
	EndIf;
	
	FileProperties.Volume = Parameters.DestinationStorageVolume;
	FileProperties.PathToFile = "";
	
	NewFilePath = FilesOperationsInVolumesInternal.FullFileNameInVolume(FileProperties, FileObject1.UniversalModificationDate);
	CopyFile(CurrentFilePath, NewFilePath);
	
	FileObject1.Volume = Parameters.DestinationStorageVolume;
	FileObject1.PathToFile = Mid(NewFilePath, StrLen(VolumeProperties.VolumePath) + 1);
	FileObject1.Write();
	
	FilesOperationsInVolumesInternal.DeleteFile(CurrentFilePath);
EndProcedure

Procedure MoveToVolumes(FileObject1, VolumeProperties, Parameters)
	FileData = FilesOperations.FileBinaryData(FileObject1.Ref);
	FileObject1.FileStorageType = Enums.FileStorageTypes.InVolumesOnHardDrive;
	FilesOperationsInVolumesInternal.AppendFile(FileObject1, FileData,
		FileObject1.UniversalModificationDate, , ?(Parameters.MoveToVolume, Parameters.DestinationStorageVolume, Undefined));
		
	If FileObject1.FileStorageType <> Enums.FileStorageTypes.InInfobase Then
		InformationRegisters.FileRepository.DeleteBinaryData(FileObject1.Ref);	
	EndIf;
	
	FileObject1.Write();
EndProcedure

Procedure MoveToInfobase(FileObject1, VolumeProperties, Parameters)

	FileData = FilesOperationsInVolumesInternal.FileData(FileObject1.Ref);

	PathToFile = FilesOperationsInVolumesInternal.FullFileNameInVolume(
					New Structure("Volume, PathToFile", FileObject1.Volume, FileObject1.PathToFile));

	FileObject1.Volume = Undefined;
	FileObject1.PathToFile = "";
	FileObject1.FileStorageType = Enums.FileStorageTypes.InInfobase;
	FileObject1.Write();	

	RecordingParametersVIB = FileArchiveManagementServer.FilledWriteParametersToInfobase(FileObject1);

	FilesOperationsInternal.WriteFileToInfobase(FileObject1.Ref, FileData, RecordingParametersVIB);

	FilesOperationsInVolumesInternal.DeleteFile(PathToFile);
EndProcedure

// Parameters:
//  FileRef - DefinedType.AttachedFile
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  Structure:
//   * FileName - String
//   * Error - String
//   * DetailErrorDescription - String
//   * Version - DefinedType.AttachedFile
//
Function TransferError(FileRef, ErrorInfo) Export

	ErrorDescription = New Structure;
	ErrorDescription.Insert("FileName","");
	ErrorDescription.Insert("Error", "");
	ErrorDescription.Insert("DetailErrorDescription", "");
	ErrorDescription.Insert("Version", FileRef);
	ErrorDescription.Error = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	ErrorDescription.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	Return ErrorDescription;

EndFunction

Procedure ThrowAnExceptionWhenTheVolumeSizeIsExceeded(Val VolumeProperties, Val FileObject1, Val Parameters)
	
	If Parameters.MoveToVolume
		And VolumeProperties.MaxVolumeSize > 0
		And VolumeProperties.CurrentVolumeSize + FileObject1.Size > VolumeProperties.MaxVolumeSize Then
		
		Raise NStr("vi = 'Vượt quá dung lượng tối đa của quyển.';
					|ru = 'Превышен максимальный размер тома.';
					|en = 'Volume size limit exceeded.'; fa = 'Volume size limit exceeded.';
					|it = 'Dimensione massima del tomo superata.';
					|pl = '""Przekroczono maksymalny rozmiar woluminu.';
					|tr = 'Maksimum hacim boyutu aşıldı.'");
	EndIf;

EndProcedure

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("ExecuteFileTransfer", True);
	
EndProcedure

#EndRegion

#EndIf