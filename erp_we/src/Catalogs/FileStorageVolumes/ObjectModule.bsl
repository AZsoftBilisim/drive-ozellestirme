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

Procedure Filling(FillingData, FillingText, StandardProcessing)

	If TypeOf(FillingData) = Type("Structure") Then
		If Not FillingData.Property("StorageVolumeType") Then
			StorageVolumeType = Enums.StorageKinds.OperationalStorage;
		EndIf;
	EndIf;

	FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		ModuleSafeModeManager   = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
		
	Else
		UseSecurityProfiles = False;
	EndIf;

	If Not AdditionalProperties.Property("SkipBasicFillingCheck") Then

		If Not ValueIsFilled(StorageVolumeType) Then
			ErrorText = NStr("ru = 'Не заполнен способ хранения файлов';
							|vi = 'Volume storage method is required';
							|en = 'Volume storage method is required'; fa = 'Volume storage method is required';
							|it = 'Volume storage method is required';
							|pl = 'Volume storage method is required';
							|tr = 'Dosya saklama yöntemi doldurulmadı'");
			Common.MessageToUser(ErrorText, , "StorageVolumeType", "Object", Cancel);
			Return
		EndIf;

		If Not ValueIsFilled(FilesStorageMethod) Then
			ErrorText = NStr("ru = 'Не заполнен способ хранения файлов';
							|vi = 'Volume storage method is required';
							|en = 'Volume storage method is required'; fa = 'Volume storage method is required';
							|it = 'Volume storage method is required';
							|pl = 'Volume storage method is required';
							|tr = 'Dosya saklama yöntemi doldurulmadı'");
			Common.MessageToUser(ErrorText, , "FilesStorageMethod", "Object", Cancel);
			Return;
		EndIf;

		If FilesStorageMethod = Enums.FileStorageOption.S3ExternalStorage
				And IsBlankString(BinaryDataStorageName) Then
			ErrorText = NStr("ru = 'Не заполнено имя хранилища двоичных данных';
							|vi = 'Name of binary data storage is required';
							|en = 'Name of binary data storage is required'; fa = 'Name of binary data storage is required';
							|it = 'Name of binary data storage is required';
							|pl = 'Name of binary data storage is required';
							|tr = 'İkili veri deposu adı doldurulmadı'");
			Common.MessageToUser(ErrorText, , "BinaryDataStorageName", "Object", Cancel);
			Return;
		EndIf;

		If Not SequenceNumberUnique(FillOrder, Ref, StorageVolumeType) Then
			ErrorText = NStr("vi = 'Trình tự điền không phải là duy nhất - trong hệ thống có quyển có trình tự như vậy';
							|ru = 'Порядок заполнения не уникален - в системе уже есть том с таким порядком';
							|en = 'The filling order is not unique. A volume with this order already exists.'; fa = 'The filling order is not unique. A volume with this order already exists.';
							|it = 'L''ordine di compilazione non è univoco: esiste già un volume nel sistema con un tale ordine';
							|pl = 'Procedura wypełniania nie jest unikalna - w systemie istnieje już wolumin z taką procedurą';
							|tr = 'Doldurma sırası benzersiz değil. Sistemde böyle bir düzene sahip disk bölümü zaten var'");
			Common.MessageToUser(ErrorText, , "FillOrder", "Object", Cancel);
		EndIf;

		If Not CheckUniquenessOfVolumePlacedInBinaryDataStorage(Ref, StorageVolumeType, FilesStorageMethod) Then
			
			ErrorText = BinaryDataStorageVolumeNonUniquenessErrorText();
					
			Common.MessageToUser(ErrorText,, "FilesStorageMethod", "Object", Cancel);
		EndIf;		
		
		If MaximumSize <> 0 Then
			CurrentSizeInBytes = 0;
			If Not Ref.IsEmpty() Then
				CurrentSizeInBytes = FilesOperationsInVolumesInternal.VolumeSize(Ref);
			EndIf;
			ActualSize = CurrentSizeInBytes / (1024 * 1024);
			
			If MaximumSize < ActualSize Then
				ErrorText = NStr("vi = 'Dung lượng tối đa của quyển nhỏ hơn dung lượng hiện tại';
								|ru = 'Максимальный размер тома меньше, чем текущий размер';
								|en = 'The volume size limit is less than the current size.'; fa = 'The volume size limit is less than the current size.';
								|it = 'Dimensione massima del volume inferiore alla dimensione corrente';
								|pl = 'Maksymalny rozmiar woluminy jest mniejszy od bieżącego rozmiaru';
								|tr = 'Disk bölümün maksimum boyutu geçerli boyuttan daha küçüktür'");
				Common.MessageToUser(ErrorText, , "MaximumSize", "Object", Cancel);
			EndIf;
		EndIf;

		If FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories Then
			If IsBlankString(FullPathWindows) And IsBlankString(FullPathLinux) Then
				ErrorText = NStr("vi = 'Chưa điền đường dẫn đầy đủ';
								|ru = 'Не заполнен полный путь';
								|en = 'The full path is required.'; fa = 'The full path is required.';
								|it = 'Percorso completo non compilato';
								|pl = 'Nie wypełniono pełnej ścieżki';
								|tr = 'Tam yol girilmedi'");
				Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
				Common.MessageToUser(ErrorText, , "FullPathLinux",   "Object", Cancel);
				Return;
			EndIf;

			PathsToVolumes = Common.ObjectAttributesValues(Ref, "FullPathLinux, FullPathWindows");
			CheckTheUniquenessOfPaths = PathsToVolumes.FullPathLinux <> FullPathLinux 
											Or PathsToVolumes.FullPathWindows <> FullPathWindows;
			If CheckTheUniquenessOfPaths Then
				CheckTheUniquenessOfThePathToTheVolumes(Cancel); 
			EndIf;
			
			If Not UseSecurityProfiles
			   And Not IsBlankString(FullPathWindows)
			   And (    Left(FullPathWindows, 2) <> "\\"
			      Or StrFind(FullPathWindows, ":") <> 0 ) Then
				
				ErrorText = NStr("vi = 'Đường dẫn đến quyển cần phải theo định dạng UNC (\\servername\resource).';
								|ru = 'Путь к тому должен быть в формате UNC (\\servername\resource).';
								|en = 'The volume path must be in the UNC format (\\servername\resource).'; fa = 'The volume path must be in the UNC format (\\servername\resource).';
								|it = 'Tale percorso deve essere in formato UNC (\servername\resource).';
								|pl = 'Ścieżka do woluminu powinna być w formacie UNC (\\servername\resource).';
								|tr = 'Disk bölümü yolu UNC formatında olmalıdır (\\servername\resource).'");
				Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
				Return;
			EndIf;
		EndIf
	EndIf;

	If Not AdditionalProperties.Property("SkipDirectoryAccessCheck") Then
		If FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories Then		
			FullPathFieldName = ?(Common.IsWindowsServer(), "FullPathWindows", "FullPathLinux");
			If Common.DataSeparationEnabled() Then
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				SeparatorValue = ?(ModuleSaaSOperations.SessionSeparatorUsage(),
					ModuleSaaSOperations.SessionSeparatorValue(), "");
			Else
				SeparatorValue = "";
			EndIf;

			FullVolumePath = StrReplace(ThisObject[FullPathFieldName], "%z", SeparatorValue);
			TestDirectoryName = FullVolumePath + "CheckAccess" + GetPathSeparator();

			Try
				CreateDirectory(TestDirectoryName);
				DeleteFiles(TestDirectoryName);
			Except
				ErrorInfo = ErrorInfo();

				If UseSecurityProfiles Then
					ErrorTemplate =
						NStr("vi = 'Đường dẫn ổ đĩa không chính xác hoặc máy chủ có ổ đĩa hiện không khả dụng.
						           |Kiểm tra đường dẫn đến thư mục được chia sẻ và tính khả dụng của máy chủ
						           |Các quyền trong cấu hình bảo mật có thể không được định cấu hình,
						           |cũng như tài khoản mà 
						           |server 1C: Enterprise đang chạy không có quyền đối với thư mục số lượng lớn.
						           |
						           |%1';
						           |ru = 'Некорректный путь к тому или сервер с томом в данный момент недоступен.
						           |Проверьте корректность пути к общей папке и доступность сервера.
						           |Возможно не настроены разрешения в профилях безопасности,
						           |или учетная запись, от лица которой работает
						           |сервер 1С:Предприятия, не имеет прав доступа к каталогу тома.
						           |
						           |%1';
						           |en = 'The volume path is invalid or the server with the volume is currently unavailable.
						           |Check if the path to the shared folder is correct and the server is available.
						           |Security profile permissions might not be configured,
						           |or an account on whose behalf
						           |1C:Enterprise server is running might have no access rights to the volume directory.
						           |
						           |%1'; fa = 'The volume path is invalid or the server with the volume is currently unavailable.
						           |Check if the path to the shared folder is correct and the server is available.
						           |Security profile permissions might not be configured,
						           |or an account on whose behalf
						           |1C:Enterprise server is running might have no access rights to the volume directory.
						           |
						           |%1';
						           |it = 'Percorso errato o server con il volume richiesto non è al momento disponibile.
						           |Si prega di verificare la correttezza del percorso alla cartella condivisa e la disponibilità del server.
						           |Potrebbero non essere configurate le autorizzazioni nei profili di sicurezza,
						           |o l''account attuale del server
						           | 1C:Enterprise non ha diritti di accesso al volume.
						           |
						           |%1';
						           |pl = 'Niepoprawna ścieżka do wolumina lub serwer w tej chwili jest niedostępny.
						           |Sprawsdź prawidłowość ścieżki do wspólnego folderu i dostępność serwera.
						           |Możliwie nie są ustawione zezwolenia w profilach bezpieczeństwa,
						           |lub konto, od którego pracuje
						           |serwer 1С:Enterprise, nie ma praw dostępu do katalogu woluminu.
						           |
						           |%1';
						           |tr = 'Birimin yolu yanlış veya birimin bulunduğu sunucu şu anda kullanılamıyor.
						           |Paylaşılan klasörün yolunun doğru olduğunu ve sunucunun kullanılabilir olduğunu kontrol edin.
						           |Güvenlik profillerindeki izinler yapılandırılmamış olabilir,
						           |veya 
						           |1C:Enterprise sunucusunun altında çalıştığı hesabın birim dizinine erişim hakları yok.
						           |
						           |%1'");
				Else
					ErrorTemplate =
						NStr("vi = 'Đường dẫn không chính xác đến ổ đĩa hoặc máy chủ có ổ đĩa hiện không khả dụng.
						           |Hãy kiểm tra đường dẫn đến thư mục chia sẻ và tính khả dụng của máy chủ.
						           |Có thể tài khoản mà máy chủ 1C: Enterprise
						           |đang chạy không có quyền truy cập vào thư mục ổ đĩa.
						           |
						           |%1';
						           |ru = 'Некорректный путь к тому или сервер с томом в данный момент недоступен.
						           |Проверьте корректность пути к общей папке и доступность сервера.
						           |Возможно учетная запись, от лица которой работает
						           |сервер 1С:Предприятия, не имеет прав доступа к каталогу тома.
						           |
						           |%1';
						           |en = 'The volume path is invalid or the server with the volume is currently unavailable.
						           |Check if the path to the shared folder is correct and the server is available.
						           |An account on whose behalf 1C:Enterprise server is running
						           |might have no access rights to the volume directory.
						           |
						           |%1'; fa = 'The volume path is invalid or the server with the volume is currently unavailable.
						           |Check if the path to the shared folder is correct and the server is available.
						           |An account on whose behalf 1C:Enterprise server is running
						           |might have no access rights to the volume directory.
						           |
						           |%1';
						           |it = 'Percorso errato o server con il volume richiesto non è al momento disponibile.
						           |Si prega di verificare la correttezza del percorso alla cartella condivisa e la disponibilità del server.
						           |L''account attuale del server
						           | 1C:Enterprise potrebbe non avere diritti di accesso al volume.
						           |
						           |%1';
						           |pl = 'Niepoprawna ścieżka do wolumina lub serwer w tej chwili jest niedostępny.
						           |Sprawsdź prawidłowość ścieżki do wspólnego folderu i dostępność serwera.
						           |Możliwie, konto, od którego pracuje
						           |serwer 1С:Enterprise, nie ma praw dostępu do katalogu woluminu.
						           |
						           |%1';
						           |tr = 'Birimin yolu yanlış veya birimin bulunduğu sunucu şu anda kullanılamıyor.
						           |Paylaşılan klasörün yolunun doğru olduğunu ve sunucunun kullanılabilir olduğunu kontrol edin.
						           |Muhtemelen bir hesap,
						           | 1C:Enterprise sunucusunun adına çalıştığı, birim dizinine erişim haklarına sahip değildir.
						           |
						           |%1'");
				EndIf;

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
				Common.MessageToUser(
					ErrorText, , FullPathFieldName, "Object", Cancel);
			EndTry;
		EndIf;
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	BinaryDataStorageManagementServer.ChangeStoredDataComposition(StorageVolumeType, FilesStorageMethod, BinaryDataStorageName)

EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DeletionMark Then
		If Not CheckUniquenessOfVolumePlacedInBinaryDataStorage(Ref, StorageVolumeType, FilesStorageMethod) Then

			ErrorText = BinaryDataStorageVolumeNonUniquenessErrorText(True);

			Raise NStr(ErrorText);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region Private

// Returns False if there is a volume of the same order.
Function SequenceNumberUnique(FillOrder, VolumeRef, StorageVolumeType)

	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(Volumes.FillOrder) AS Count
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes
	|WHERE
	|	Volumes.FillOrder = &FillOrder
	|	AND Volumes.StorageVolumeType = &StorageVolumeType
	|	AND Volumes.Ref <> &VolumeRef";

	Query.Parameters.Insert("FillOrder"		, FillOrder);
	Query.Parameters.Insert("VolumeRef"				, VolumeRef);
	Query.Parameters.Insert("StorageVolumeType"	, StorageVolumeType);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Count = 0;
	EndIf;

	Return True;

EndFunction

Procedure CheckTheUniquenessOfThePathToTheVolumes(Cancel)
	
	Query = New Query;
	Query.SetParameter("VolumeBeingChecked", Ref);

	Query.Text = 
		"SELECT
		|	FileStorageVolumes.Ref AS Ref,
		|	PRESENTATION(FileStorageVolumes.Ref) AS Presentation,
		|	FileStorageVolumes.FullPathWindows AS FullPathWindows,
		|	FileStorageVolumes.FullPathLinux AS FullPathLinux
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	NOT FileStorageVolumes.DeletionMark
		|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.FileStorageOption.NetworkDirectories)
		|	AND FileStorageVolumes.Ref <> &VolumeBeingChecked";
		
	QueryResult = Query.Execute();
	ResultTable2 = QueryResult.Unload();
	ResultTable2.Indexes.Add("FullPathLinux");
	ResultTable2.Indexes.Add("FullPathWindows");
	
	ErrorTemplate = NStr("vi = 'Đường dẫn đến quyển phải là đơn trị. Thư mục đã chỉ ra trong quyển %1.';
						|ru = 'Путь к тому должен быть уникален. Каталог указан в томе %1.';
						|en = 'The volume path must be unique. The directory is specified in the %1 volume.'; fa = 'The volume path must be unique. The directory is specified in the %1 volume.';
						|it = 'Il percorso al tomo deve essere univoco. Catalogo indicato nel tomo %1.';
						|pl = 'Ścieżka do wolumina powinna być unikalna, Katalog jest podany w woluminie %1.';
						|tr = 'Bunun yolu benzersiz olmalıdır.Birimde belirtilen dizin%1.'");
	If ValueIsFilled(FullPathLinux) Then
		For Each Volume In ResultTable2.FindRows(New Structure("FullPathLinux", FullPathLinux)) Do
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Volume.Presentation);
			Common.MessageToUser(ErrorText, , "FullPathLinux", "Object", Cancel);
		EndDo;
	EndIf;
	
	If ValueIsFilled(FullPathWindows) Then
		For Each Volume In ResultTable2.FindRows(New Structure("FullPathWindows", FullPathWindows)) Do
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Volume.Presentation);
			Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
		EndDo;
	EndIf;
EndProcedure

Function CheckUniquenessOfVolumePlacedInBinaryDataStorage(VolumeRef, StorageVolumeType, FilesStorageMethod)

	If FilesStorageMethod = Enums.FileStorageOption.NetworkDirectories Then
		Return True;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(Volumes.FilesStorageMethod) AS Count
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes
	|WHERE
	|	Volumes.StorageVolumeType = &StorageVolumeType
	|	AND Volumes.FilesStorageMethod = &FilesStorageMethod
	|	AND Volumes.Ref <> &VolumeRef
	|	AND NOT Volumes.DeletionMark";

	Query.Parameters.Insert("StorageVolumeType"	, StorageVolumeType);
	Query.Parameters.Insert("FilesStorageMethod"	, FilesStorageMethod);
	Query.Parameters.Insert("VolumeRef"				, VolumeRef);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Count = 0;
	EndIf;

EndFunction

Function BinaryDataStorageVolumeNonUniquenessErrorText(CheckOnWrite = False)
	
	If CheckOnWrite Then
		If FilesStorageMethod = Enums.FileStorageOption.S3ExternalStorage Then
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В системе уже существует том с видом %1, размещающий данные во внешнем хранилище двоичных данных (по протоколу S3) и не помеченный на удаление.';
					|vi = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol) and is not marked for deletion.';
					|en = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol) and is not marked for deletion.'; fa = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol) and is not marked for deletion.';
					|it = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol) and is not marked for deletion.';
					|pl = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol) and is not marked for deletion.';
					|tr = 'Sistemde halihazırda %1 türünde, verileri harici ikili veri deposunda (S3 protokolü ile) barındıran ve silinmek üzere işaretlenmemiş bir birim mevcuttur.'"),
				Lower(StorageVolumeType));
		ElsIf FilesStorageMethod = Enums.FileStorageOption.InInternalStorage Then
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В системе уже существует том с видом %1, размещающий данные во встроенном хранилище двоичных данных и не помеченный на удаление.';
					|vi = 'The system already has a %1 type volume that stores data in the built-in binary data storage and is not marked for deletion.';
					|en = 'The system already has a %1 type volume that stores data in the built-in binary data storage and is not marked for deletion.'; fa = 'The system already has a %1 type volume that stores data in the built-in binary data storage and is not marked for deletion.';
					|it = 'The system already has a %1 type volume that stores data in the built-in binary data storage and is not marked for deletion.';
					|pl = 'The system already has a %1 type volume that stores data in the built-in binary data storage and is not marked for deletion.';
					|tr = 'Sistemde halihazırda %1 türünde, verileri dahili ikili veri deposunda barındıran ve silinmek üzere işaretlenmemiş bir birim mevcuttur.'"),
				Lower(StorageVolumeType));
		Else
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В системе уже существует том с видом %1, размещающий данные %2 и не помеченный на удаление';
					|vi = 'The system already has a %1 type volume that stores %2 data and is not marked for deletion.';
					|en = 'The system already has a %1 type volume that stores %2 data and is not marked for deletion.'; fa = 'The system already has a %1 type volume that stores %2 data and is not marked for deletion.';
					|it = 'The system already has a %1 type volume that stores %2 data and is not marked for deletion.';
					|pl = 'The system already has a %1 type volume that stores %2 data and is not marked for deletion.';
					|tr = 'Sistemde halihazırda %1 türünde, %2 verilerini barındıran ve silinmek üzere işaretlenmemiş bir birim mevcuttur'"),
				Lower(StorageVolumeType),
				String(FilesStorageMethod));
		EndIf;
	Else
		If FilesStorageMethod = Enums.FileStorageOption.S3ExternalStorage Then
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В системе уже существует том с видом %1, размещающий данные во внешнем хранилище двоичных данных (по протоколу S3).';
					|vi = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol).';
					|en = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol).'; fa = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol).';
					|it = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol).';
					|pl = 'The system already has a %1 type volume that stores data in the external binary data storage (by S3 protocol).';
					|tr = 'Sistemde halihazırda %1 türünde, verileri harici ikili veri deposunda (S3 protokolü ile) barındıran bir birim mevcuttur.'"),
				Lower(StorageVolumeType));
		ElsIf FilesStorageMethod = Enums.FileStorageOption.InInternalStorage Then
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В системе уже существует том с видом %1, размещающий данные во встроенном хранилище двоичных данных.';
					|vi = 'The system already has a %1 type volume that stores data in the built-in binary data storage.';
					|en = 'The system already has a %1 type volume that stores data in the built-in binary data storage.'; fa = 'The system already has a %1 type volume that stores data in the built-in binary data storage.';
					|it = 'The system already has a %1 type volume that stores data in the built-in binary data storage.';
					|pl = 'The system already has a %1 type volume that stores data in the built-in binary data storage.';
					|tr = 'Sistemde halihazırda %1 türünde, verileri dahili ikili veri deposunda barındıran bir birim mevcuttur.'"),
				Lower(StorageVolumeType));
		Else
			Result = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'В системе уже существует том с видом %1, размещающий данные %2. Используйте другой том.';
					|vi = 'The system already has a volume of %1 kind containing data %2. Use another volume.';
					|en = 'The system already has a volume of %1 kind containing data %2. Use another volume.'; fa = 'The system already has a volume of %1 kind containing data %2. Use another volume.';
					|it = 'The system already has a volume of %1 kind containing data %2. Use another volume.';
					|pl = 'The system already has a volume of %1 kind containing data %2. Use another volume.';
					|tr = 'Sistemde halihazırda %1 türünde, %2 verilerini barındıran bir birim mevcuttur. Başka bir birim kullanın.'"),
				Lower(StorageVolumeType),
				String(FilesStorageMethod));
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction


#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf